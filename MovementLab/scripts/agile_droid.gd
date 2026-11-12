extends "res://scripts/dummy.gd"

const MAX_HEALTH := 100
const PATROL_RADIUS := 3.0
const PATROL_SPEED := 1.2
const WALK_SPEED := PATROL_SPEED
const RUN_SPEED := 3.6
const LUNGE_SPEED := 3.2
const JUMP_VELOCITY := 7.5
const SIGHT_RANGE := 7.5
const WINDUP := .85
const SWIPE := .24
const ATTACK_COOLDOWN := 0.65
enum Mode { PATROL, APPROACH, WINDUP, SWIPE, DOWN }

var skeleton: Skeleton3D
var animation: AnimationPlayer
var health := MAX_HEALTH
var mode := Mode.PATROL
var elapsed := 0.0
var facing := 1
var patrol_direction := 1
var attack_cooldown := 0.0
var current_clip := ""
var clip_names := {}
var sword: Node3D
var sword_material: StandardMaterial3D
var shadow_mesh: MeshInstance3D
var shadow_material: ShaderMaterial
var shadow_query := PhysicsRayQueryParameters3D.new()
var death_tween: Tween
var struck := false
var model_scale := 1.0
var trail_fx: Node3D
var jump_cooldown := 0.0

func _ready() -> void:
	super._ready()
	skeleton = droid.find_children("*", "Skeleton3D", true, false)[0]
	animation = droid.find_children("*", "AnimationPlayer", true, false)[0]
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in animation.get_animation_list():
		clip_names[clip.get_slice("Warden_", 1)] = clip
	_install_locomotion_clips()
	# Match the imported character mesh height before applying animation.
	var miko_mesh: MeshInstance3D = actor.model.find_children("*", "MeshInstance3D", true, false)[0]
	var enemy_mesh: MeshInstance3D = droid.find_children("*", "MeshInstance3D", true, false)[0]
	model_scale = miko_mesh.get_aabb().size.y / enemy_mesh.get_aabb().size.y
	droid.scale = Vector3.ONE * model_scale
	var collider: CollisionShape3D = get_child(0)
	collider.shape.height = miko_mesh.get_aabb().size.y
	collider.shape.radius = .35
	collider.position.y = collider.shape.height * .5
	_build_sword()
	_build_shadow()
	trail_fx = preload("res://scripts/enemy_sword_trail.gd").new()
	trail_fx.fighter = self
	add_child(trail_fx)
	var canvas := CanvasLayer.new()
	canvas.layer = 3
	add_child(canvas)
	var bar := preload("res://scripts/miko8_health_bar.gd").new()
	bar.actor = self
	bar.hostile = true
	canvas.add_child(bar)
	reset()

func _build_sword() -> void:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = "DEF-hand.R"
	skeleton.add_child(attachment)
	sword = Node3D.new()
	attachment.add_child(sword)
	var index := skeleton.get_bone_rest(skeleton.find_bone("DEF-f_index.01.R")).origin
	var pinky := skeleton.get_bone_rest(skeleton.find_bone("DEF-f_pinky.01.R")).origin
	sword.position = (index + pinky) * .43
	sword.basis = Basis(Quaternion(Vector3.RIGHT, (index - pinky).normalized()))
	sword_material = StandardMaterial3D.new()
	sword_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sword_material.albedo_color = Color("ed283b")
	for part in [
		[Vector3(.20,.05,.04), Vector3.ZERO, Color("252b34")],
		[Vector3(.04,.19,.08), Vector3(.11,0,0), Color("913348")],
		[Vector3(.88,.065,.025), Vector3(.57,0,0), Color("ed283b")],
		[Vector3(.88,.012,.027), Vector3(.57,-.033,0), Color("ffb6b8")]]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[0]
		mesh.mesh = box
		mesh.position = part[1]
		var material := sword_material.duplicate() as StandardMaterial3D
		material.albedo_color = part[2]
		mesh.material_override = material
		sword.add_child(mesh)

func _build_shadow() -> void:
	shadow_query.collision_mask = 1
	shadow_material = ShaderMaterial.new()
	shadow_material.shader = preload("res://shaders/lab_contact.gdshader")
	shadow_mesh = MeshInstance3D.new()
	shadow_mesh.top_level = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1.35, 0.95)
	shadow_mesh.mesh = quad
	shadow_mesh.material_override = shadow_material
	shadow_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow_mesh.rotation.x = -PI / 2.0
	add_child(shadow_mesh)

func _update_shadow() -> void:
	if not shadow_mesh:
		return
	if not is_visible_in_tree() or (mode == Mode.DOWN and elapsed > 5.0):
		shadow_mesh.visible = false
		return
	var foot := global_position
	shadow_query.from = foot + Vector3.UP * 0.15
	shadow_query.to = foot + Vector3.DOWN * 4.0
	shadow_query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(shadow_query)
	shadow_mesh.visible = not hit.is_empty()
	if shadow_mesh.visible:
		var surface: Vector3 = hit.position
		var height := maxf(0.0, foot.y - surface.y)
		shadow_mesh.global_position = surface + Vector3.UP * 0.02
		shadow_mesh.scale = Vector3.ONE * (1.0 + height * 0.18)
		var base_opacity: float = 0.44 * maxf(0.0, 1.0 - height / 3.0)
		if mode == Mode.DOWN and elapsed > 5.0:
			base_opacity *= maxf(0.0, 1.0 - (elapsed - 5.0) / 0.9)
		shadow_material.set_shader_parameter("opacity", base_opacity)

func reset() -> void:
	super.reset()
	if death_tween:
		death_tween.kill()
		death_tween = null
	show()
	health = MAX_HEALTH
	collision_layer = 4
	mode = Mode.PATROL
	elapsed = 0.0
	facing = 1
	patrol_direction = 1
	attack_cooldown = 0.0
	current_clip = ""
	struck = false
	body.position = Vector3.ZERO
	droid.scale = Vector3.ONE * model_scale
	droid.rotation.y = PI * .5
	if sword:
		sword.show()
	if shadow_mesh:
		shadow_mesh.visible = true
	_set_dissolve(0.0)
	if trail_fx:
		trail_fx.clear()

func _enter(next: Mode) -> void:
	mode = next
	elapsed = 0.0
	struck = false

func _physics_process(delta: float) -> void:
	_update_popups(delta)
	_update_shadow()
	if hitstop > 0:
		hitstop = maxf(0, hitstop - delta)
		return
	elapsed += delta
	stagger = maxf(0, stagger - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	jump_cooldown = maxf(0.0, jump_cooldown - delta)
	velocity.y -= 25.0 * delta
	var speed := 0.0
	if stagger <= 0.0:
		match mode:
			Mode.PATROL:
				if _sees_miko():
					facing = 1 if actor.position.x > position.x else -1
					_enter(Mode.APPROACH)
				else:
					if absf(position.x-home.x) >= PATROL_RADIUS and (position.x-home.x)*patrol_direction > 0:
						patrol_direction *= -1
					facing = patrol_direction
					speed = facing * PATROL_SPEED
			Mode.APPROACH:
				if not _sees_miko():
					_enter(Mode.PATROL)
				else:
					facing = 1 if actor.position.x > position.x else -1
					var dist_x: float = absf(actor.position.x - position.x)
					var dist_y: float = absf(actor.position.y - position.y)
					if dist_x < 1.85 and dist_y < .65:
						if attack_cooldown <= 0.0:
							_enter(Mode.WINDUP)
						else:
							speed = 0.0
					else:
						speed = facing * RUN_SPEED
						if is_on_floor() and jump_cooldown <= 0.0 and _should_jump_obstacle():
							velocity.y = JUMP_VELOCITY
							jump_cooldown = 0.55
			Mode.WINDUP:
				speed = move_toward(velocity.x, 0.0, delta * 12.0)
				if elapsed >= WINDUP:
					_enter(Mode.SWIPE)
			Mode.SWIPE:
				if elapsed < 0.14:
					speed = facing * LUNGE_SPEED
				else:
					speed = move_toward(velocity.x, 0.0, delta * 14.0)
				if elapsed >= .06 and not struck:
					struck = true
					_strike()
				if elapsed >= SWIPE:
					_enter(Mode.APPROACH)
					attack_cooldown = ATTACK_COOLDOWN

	# Turn model toward facing direction with responsive angular speed
	if mode != Mode.DOWN:
		droid.rotation.y = rotate_toward(droid.rotation.y, facing * PI * .5, delta * 14.0)

	# Damp horizontal speed while pivoting to eliminate moonwalking
	var target_yaw := facing * PI * .5
	var yaw_diff := absf(wrapf(droid.rotation.y - target_yaw, -PI, PI))
	if yaw_diff > 0.9:
		speed *= clampf(1.0 - (yaw_diff / PI), 0.0, 1.0)

	var accel := 14.0 if mode == Mode.SWIPE else 9.0
	velocity.x = move_toward(velocity.x, speed, delta * accel)
	if mode != Mode.DOWN or not is_on_floor():
		move_and_slide()
	position.z = 0.0
	if mode == Mode.DOWN and is_on_floor() and not death_tween:
		_start_death()
	_animate(delta)

func _should_jump_obstacle() -> bool:
	var space := get_world_3d().direct_space_state
	var self_rid := get_rid()
	var chest_pos := global_position + Vector3.UP * 1.55
	var chest_target := chest_pos + Vector3(float(facing) * 1.35, 0.0, 0.0)
	var chest_query := PhysicsRayQueryParameters3D.create(chest_pos, chest_target, 1, [self_rid])
	var chest_hit := space.intersect_ray(chest_query)
	# If chest/head height is blocked, it's a tall wall or double stack — cannot clear with single jump
	if not chest_hit.is_empty():
		return false
	
	# Check knee/box height directly ahead
	var knee_pos := global_position + Vector3.UP * 0.45
	var knee_target := knee_pos + Vector3(float(facing) * 1.35, 0.0, 0.0)
	var knee_query := PhysicsRayQueryParameters3D.create(knee_pos, knee_target, 1, [self_rid])
	var knee_hit := space.intersect_ray(knee_query)
	return not knee_hit.is_empty()

func _sees_miko() -> bool:
	if actor.health <= 0 or absf(actor.position.x-position.x) > SIGHT_RANGE or absf(actor.position.y-position.y) > 2.2:
		return false
	var query := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP, actor.global_position+Vector3.UP, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	# If the ray hit a single obstacle (like a crate) below 1.2m, Miko is visible above it
	if hit.collider and is_instance_valid(hit.collider) and hit.position.y < global_position.y + 1.2:
		return true
	return false

func _strike() -> void:
	var offset := actor.global_position-global_position
	if offset.x*facing < 0 or absf(offset.x) > 2.0 or absf(offset.y) > 1.1:
		return
	var query := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP, actor.global_position+Vector3.UP, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return
	if actor.receive_attack(global_position.x):
		stagger = .75
		hitstop = .075
		_enter(Mode.APPROACH)
		attack_cooldown = ATTACK_COOLDOWN

func _animate(delta: float) -> void:
	if not animation:
		return
	var clip := "Idle"
	if mode == Mode.DOWN:
		clip = "Death"
	elif mode in [Mode.WINDUP, Mode.SWIPE]:
		clip = "Slash"
	elif not is_on_floor() and mode != Mode.DOWN:
		clip = "JumpAir"
	elif absf(velocity.x) > 1.8:
		clip = "Run"
	elif absf(velocity.x) > .05:
		clip = "Walk"
	if clip != current_clip:
		animation.play(clip_names[clip], .14)
		current_clip = clip
		var anim: Animation = animation.get_animation(clip_names[clip])
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR if clip in ["Idle", "Walk", "Run", "JumpAir"] else Animation.LOOP_NONE

	# Scale locomotion advance rate to match ground speed, keeping foot plants solid
	var advance_rate := 1.0
	if clip == "Walk":
		advance_rate = clampf(absf(velocity.x) / PATROL_SPEED, 0.45, 1.8)
	elif clip == "Run":
		advance_rate = clampf(absf(velocity.x) / RUN_SPEED, 0.70, 1.45)
	elif clip == "JumpAir":
		advance_rate = 1.0
	animation.advance(delta * advance_rate)

	if mode == Mode.WINDUP:
		animation.seek(lerpf(0.0, .20, clampf(elapsed/WINDUP,0,1)), true)
	elif mode == Mode.SWIPE:
		animation.seek(lerpf(.20,.43,clampf(elapsed/SWIPE,0,1)), true)
	for material in droid_materials:
		material.set_shader_parameter("droid_warning", .7 * sin(PI*clampf((elapsed-(WINDUP-.30))/.30,0,1)) if mode == Mode.WINDUP and elapsed >= (WINDUP-.30) else 0.0)

func _install_locomotion_clips() -> void:
	if not actor or not actor.get("player"):
		return
	var actor_player: AnimationPlayer = actor.player
	var droid_path := str(animation.get_node(animation.root_node).get_path_to(skeleton))
	var lib := AnimationLibrary.new()
	for anim_name in ["MIKO8_Run", "MIKO8_JumpAir"]:
		if not actor_player.has_animation(anim_name):
			continue
		var orig: Animation = actor_player.get_animation(anim_name)
		var clone: Animation = orig.duplicate(true)
		for t in range(clone.get_track_count()):
			var p = clone.track_get_path(t)
			clone.track_set_path(t, NodePath(droid_path + ":" + str(p.get_subname(0))))
		var short_name: String = anim_name.trim_prefix("MIKO8_")
		lib.add_animation(short_name, clone)
		clip_names[short_name] = "DroidLoco/" + short_name
	animation.add_animation_library("DroidLoco", lib)

func receive_hit(amount: int, direction: int, lift: float) -> void:
	if mode == Mode.DOWN:
		return
	super.receive_hit(amount,direction,lift)
	health = maxi(0,health-amount)
	_enter(Mode.APPROACH if health > 0 else Mode.DOWN)
	if health == 0:
		collision_layer = 0
		velocity.x = direction * .6

func _start_death() -> void:
	death_tween = create_tween()
	death_tween.tween_interval(5.0)
	death_tween.tween_method(_set_dissolve,0.0,1.0,.9)
	death_tween.tween_callback(hide)

func _set_dissolve(value: float) -> void:
	for material in droid_materials:
		material.set_shader_parameter("dissolve", value)
	if sword:
		sword.visible = value < .6
	if shadow_material:
		shadow_material.set_shader_parameter("opacity", 0.44 * maxf(0.0, 1.0 - value))

