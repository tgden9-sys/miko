extends Node
## Ground attacks play full-body source tracks. Air attacks keep the jump pose.
const CONTACT_START := [7.0 / 30.0, 7.0 / 30.0, 14.0 / 30.0]
const CONTACT_END := [8.0 / 30.0, 10.0 / 30.0, 17.0 / 30.0]
const CLIPS := ["SwordA", "SwordB", "SwordC"]
const BLADE_EXTEND_TIME := .075
const BLADE_RETRACT_TIME := .22
var actor: CharacterBody3D
var data: Dictionary
var pose_clip := "SwordA"
var pose_time := 0.0
var pose_weight := 0.0
var swing := -1
var ground_attack := false
var elapsed := 0.0
var combo_window := 0.0
var next_swing := 0
var struck: Array = []
var guarding := false
var energy := 100.0
var broken := 0.0
var lit := 0.0
var shield_flash := 0.0
var sword: Node3D
var blade: Node3D
var blade_extension := 0.0
var trail: ImmediateMesh
var trail_edges: Array[Vector3] = []
var trail_sample_time := -1.0
var shield: MeshInstance3D
var shield_paint: StandardMaterial3D
var status: Label

func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://models/miko8/MIKO8_Combat.json"))
	_install_ground_clips()
	var modifier := preload("res://scripts/miko8_sword_pose.gd").new()
	modifier.combat = self
	actor.skeleton.add_child(modifier)
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = "DEF-hand.R"
	actor.skeleton.add_child(attachment)
	sword = Node3D.new()
	attachment.add_child(sword)
	# Locate the grip between the curled fingers. The hand's local X axis
	# points across the palm surface normal, almost perpendicular to the grip.
	var index: Vector3 = actor.skeleton.get_bone_rest(actor.skeleton.find_bone("DEF-f_index.01.R")).origin
	var pinky: Vector3 = actor.skeleton.get_bone_rest(actor.skeleton.find_bone("DEF-f_pinky.01.R")).origin
	var grip_axis := (index - pinky).normalized()
	sword.position = (index + pinky) * .43
	sword.basis = Basis(Quaternion(Vector3.RIGHT, grip_axis))
	_add_blade(sword, .025, .22, Color("293b37"), 0.0, 0.0)
	blade = Node3D.new()
	blade.position.x = .11
	sword.add_child(blade)
	_add_blade(blade, .045, .92, Color("39ed71"), .46, 2.0)
	_add_blade(blade, .018, .94, Color("d9ffe1"), .47, 3.0)
	trail = ImmediateMesh.new()
	var ribbon := MeshInstance3D.new()
	ribbon.mesh = trail
	ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ribbon.top_level = true
	var ribbon_paint := StandardMaterial3D.new()
	ribbon_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ribbon_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ribbon_paint.vertex_color_use_as_albedo = true
	ribbon_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	ribbon_paint.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ribbon.material_override = ribbon_paint
	actor.add_child(ribbon)
	ribbon.global_transform = Transform3D.IDENTITY
	shield = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = .75
	mesh.height = 1.5
	shield.mesh = mesh
	shield.scale = Vector3(.13, 1.0, .8)
	shield_paint = StandardMaterial3D.new()
	shield_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shield_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shield.material_override = shield_paint
	actor.add_child(shield)
	actor.skeleton.skeleton_updated.connect(_update_trail)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	status = Label.new()
	status.position = Vector2(38, 218)
	status.add_theme_font_size_override("font_size", 20)
	canvas.add_child(status)
	reset()

func _install_ground_clips() -> void:
	var library := AnimationLibrary.new()
	var player: AnimationPlayer = actor.animation_player
	var skeleton_path := str(player.get_node(player.root_node).get_path_to(actor.skeleton))
	for label: String in CLIPS:
		var clip: Dictionary = data.clips[label]
		var animation := Animation.new()
		animation.length = clip.duration
		for bone: String in clip.frames[0]:
			var position_track := animation.add_track(Animation.TYPE_POSITION_3D)
			var rotation_track := animation.add_track(Animation.TYPE_ROTATION_3D)
			var path := NodePath(skeleton_path + ":" + bone)
			animation.track_set_path(position_track, path)
			animation.track_set_path(rotation_track, path)
			for frame in range(clip.frames.size()):
				var sample: Dictionary = clip.frames[frame][bone]
				var time := frame / 30.0
				animation.position_track_insert_key(position_track, time, Vector3(sample.p[0], sample.p[1], sample.p[2]))
				animation.rotation_track_insert_key(rotation_track, time, Quaternion(sample.q[0], sample.q[1], sample.q[2], sample.q[3]).normalized())
		library.add_animation(label, animation)
		actor.clips[label] = "Sword/" + label
		actor.metadata.clips[label] = {"duration": clip.duration, "loop": false}
	player.add_animation_library("Sword", library)

func _add_blade(parent: Node3D, radius: float, length: float, tint: Color, offset: float, emission: float) -> void:
	var part := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	part.mesh = mesh
	part.rotation.z = -PI * .5
	part.position.x = offset
	var paint := StandardMaterial3D.new()
	paint.albedo_color = tint
	if emission > 0.0: paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emission == 2.0:
		paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		paint.albedo_color.a = .32
	paint.emission_enabled = emission > 0.0
	paint.emission = tint
	paint.emission_energy_multiplier = emission
	part.material_override = paint
	parent.add_child(part)

func _process(delta: float) -> void:
	if status: status.visible = available()
	var ignited := available() and lit > 0.0 and not guarding
	var duration := BLADE_EXTEND_TIME if ignited else BLADE_RETRACT_TIME
	blade_extension = move_toward(blade_extension, 1.0 if ignited else 0.0, delta / duration)
	_visuals()

func reset() -> void:
	swing = -1
	ground_attack = false
	next_swing = 0
	combo_window = 0.0
	guarding = false
	energy = 100.0
	broken = 0.0
	lit = 0.0
	blade_extension = 0.0
	pose_weight = 0.0
	trail_edges.clear()
	trail.clear_surfaces()
	struck.clear()
	_visuals()

func available() -> bool:
	return actor.ready_for_input and actor.health > 0 and actor.is_physics_processing() and not actor.movement_only and actor.abilities.destructive_weapons_enabled and actor.state in actor.abilities.QUICK_FIRE_STATES

func tick(delta: float, axis: float) -> bool:
	broken = maxf(0.0, broken - delta)
	lit = maxf(0.0, lit - delta)
	shield_flash = maxf(0.0, shield_flash - delta)
	combo_window = maxf(0.0, combo_window - delta)
	guarding = available() and Input.is_action_pressed("miko8_spell_double") and broken <= 0.0 and energy > 0.0
	if not available(): swing = -1
	if ground_attack and actor.current_clip not in CLIPS: swing = -1
	if guarding:
		swing = -1 # Guard cancels attacks immediately; no simultaneous damage.
		lit = 0.0
		energy = maxf(0.0, energy - delta * 9.0)
		if energy <= 0.0: _break_guard()
	else:
		energy = minf(100.0, energy + delta * (26.0 if broken <= 0.0 else 8.0))
	if available() and not guarding and broken <= 0.0 and swing < 0 and Input.is_action_pressed("miko8_quick_blaster"):
		swing = next_swing if combo_window > 0.0 else 0
		elapsed = 0.0
		trail_edges.clear()
		trail_sample_time = -1.0
		struck.clear()
		lit = 2.4
		ground_attack = actor.is_on_floor() and actor.jump_buffer <= 0.0 and not actor.crouch_motion.low_collider
		if ground_attack:
			if absf(axis) > .12: actor.facing = 1 if axis > 0.0 else -1
			actor.target_facing = actor.facing
			actor.turn_queue.clear()
			actor.model.position = Vector3.ZERO
			actor.visual.rotation.y = actor.facing * PI * .5
			actor.animation_player.speed_scale = 1.0
			actor._play(CLIPS[swing], .065)
			pose_weight = 0.0
	var playing_ground_attack := ground_attack and swing >= 0
	if ground_attack and not playing_ground_attack:
		ground_attack = false
		if actor.current_clip in CLIPS: actor._resume_locomotion(axis)
	if swing >= 0:
		elapsed += delta
		pose_clip = CLIPS[swing]
		pose_time = elapsed
		if elapsed >= CONTACT_START[swing] and elapsed <= CONTACT_END[swing]: _strike()
		if elapsed >= float(data.clips[pose_clip].duration):
			next_swing = (swing + 1) % 3
			combo_window = .32
			lit = combo_window
			swing = -1
	elif guarding:
		pose_clip = "ShieldHit" if shield_flash > 0.0 else "ShieldIdle"
		pose_time = fmod(pose_time + delta, float(data.clips[pose_clip].duration))
	elif broken > .65:
		pose_clip = "ShieldBreak"
		pose_time = (1.1 - broken) * float(data.clips.ShieldBreak.duration) / .45
	var active_pose := not playing_ground_attack and available() and (swing >= 0 or guarding or broken > .65)
	pose_weight = move_toward(pose_weight, 1.0 if active_pose else 0.0, delta * 18.0)
	status.visible = available()
	status.text = "L2 / G  SABRE    R2 / F  SHIELD  %d%%%s" % [int(energy), "  RECHARGING" if broken > 0.0 else ""]
	_visuals()
	if playing_ground_attack:
		# The clip contains its own weight shift and step. Running the gait
		# underneath it would drag the planted feet across the floor.
		actor.velocity = Vector3(0, -.1, 0)
		actor.move_and_slide()
		actor.animation_player.advance(delta)
	return playing_ground_attack

func _strike() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.65, 2.1, .95)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = actor.global_position + Vector3(actor.facing * .9, .95, 0)
	query.collision_mask = 5
	query.exclude = [actor.get_rid()]
	for hit: Dictionary in actor.get_world_3d().direct_space_state.intersect_shape(query, 24):
		var target: Node3D = hit.collider
		if struck.has(target): continue
		var point := target.global_position + Vector3.UP * .9
		var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * .9, point, 1, [actor.get_rid()])
		var obstruction := actor.get_world_3d().direct_space_state.intersect_ray(ray)
		if not obstruction.is_empty() and obstruction.collider != target: continue
		if target.has_method("receive_sword_hit"):
			target.receive_sword_hit(60 if swing == 2 else 45, actor.facing)
		elif target.has_method("receive_combat_bolt"):
			target.receive_combat_bolt()
		elif target.has_method("receive_blaster"):
			target.receive_blaster(1, point, Vector3(actor.facing, 0, 0))
		else: continue
		struck.append(target)
		actor.abilities.projectile_pool.spawn_impact(point, Color("5dff91"))

func block_bolt(direction: Vector3) -> bool:
	if not guarding or not available() or direction.x * actor.facing >= -.1: return false
	energy = maxf(0.0, energy - 24.0)
	shield_flash = .16
	actor.abilities.projectile_pool.spawn_impact(actor.global_position + Vector3(actor.facing * .5, 1.0, 0), Color("87fff0"))
	if energy <= 0.0: _break_guard()
	return true

func _break_guard() -> void:
	guarding = false
	broken = 1.1
	pose_time = 0.0

func _visuals() -> void:
	if not sword: return
	sword.visible = actor.abilities.destructive_weapons_enabled and not actor.movement_only
	blade.visible = blade_extension > .001
	blade.scale.x = maxf(.001, blade_extension)
	shield.visible = guarding and available()
	shield.position = Vector3(actor.facing * .48, 1.0, 0)
	shield_paint.albedo_color = Color(.25, 1.0, .8, .6 if shield_flash > 0.0 else .22)



func _update_trail() -> void:
	if not available() or swing < 0 or not sword.visible or elapsed > CONTACT_END[swing] + .075:
		if not trail_edges.is_empty():
			trail_edges.clear()
			trail.clear_surfaces()
		return
	if elapsed < CONTACT_START[swing] - .065 or elapsed == trail_sample_time: return
	trail_sample_time = elapsed
	trail_edges.append(sword.to_global(Vector3(.28, 0, 0)))
	trail_edges.append(sword.to_global(Vector3(1.04, 0, 0)))
	if trail_edges.size() > 10:
		trail_edges.pop_front()
		trail_edges.pop_front()
	trail.clear_surfaces()
	if trail_edges.size() < 4: return
	trail.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(0, trail_edges.size(), 2):
		var opacity := .32 * float(i) / float(trail_edges.size() - 2)
		trail.surface_set_color(Color(.13, 1.0, .31, opacity * .2))
		trail.surface_add_vertex(trail_edges[i])
		trail.surface_set_color(Color(.36, 1.0, .49, opacity))
		trail.surface_add_vertex(trail_edges[i + 1])
	trail.surface_end()
