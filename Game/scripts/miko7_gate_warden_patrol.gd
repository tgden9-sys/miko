extends CharacterBody3D

const WARDEN := preload("res://models/enemies/gate_warden/gate_warden.glb")
const WALK := &"Warden_Walk"
const IDLE := &"Warden_Idle"
const TURN := &"Warden_Turn180Right"
const DEATH := &"Warden_Death"
const PAUSES: Array[StringName] = [&"Warden_LookAround", &"Warden_FoldArms"]
const TURN_TIME := 1.12
const WIND_UP := 0.60
const BURST_SPACING := 0.29
const RECOVERY := 1.40
const ALERT_MEMORY := 3.0
const ALERT_REACH_BONUS := 3.0
const RETURN_FIRE_REACH := 17.0
const MAX_HEALTH := 150
const BOLT_DAMAGE := 25
const CORPSE_HOLD := 2.5
const FADE_TIME := 0.9

enum State { WALK, PAUSE, TURN, ALERT, DOWN }

@export var patrol_distance := 6.0
@export var walk_speed := 0.96
@export var alert_radius := 8.0
@export var starts_facing_left := false
var state := State.WALK
var animation: AnimationPlayer
var model: Node3D
var skeleton: Skeleton3D
var start_x: float
var target_x: float
var direction := 1
var elapsed := 0.0
var pause_length := 0.0
var pause_index := 0
var pause_clip: StringName
var turn_start: float
var health := MAX_HEALTH
var aim_target := Vector3.ZERO
var aim_weight := 0.0
var muzzle_position := Vector3.ZERO
var recoil := 0.0
var shot_time := 0.0
var shots_left := 0
var alert_memory := 0.0
var return_fire_time := 0.0
var interrupted_state := State.WALK
var hitbox: CollisionShape3D
var ring: MeshInstance3D
var ring_material: ShaderMaterial
static var ring_geometry: ArrayMesh
var down_tween: Tween
var death_materials: Array[ShaderMaterial] = []
var death_fade := 0.0
var boot_shadows: Array[MeshInstance3D] = []
var feet: Array[int] = []
var player: CharacterBody3D

func _ready() -> void:
	add_to_group("miko8_budget_actor")
	set_meta("budget_activity_margin", 11.0)
	start_x = position.x
	model = WARDEN.instantiate()
	add_child(model)
	animation = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	for clip in [WALK, IDLE]:
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var pose := preload("res://scripts/miko7_warden_blaster_pose.gd").new()
	pose.guard = self
	skeleton.add_child(pose)

	hitbox = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.83
	capsule.radius = 0.29
	hitbox.shape = capsule
	hitbox.position.y = capsule.height * 0.5
	add_child(hitbox)
	_add_ring()
	_add_shadows()
	_add_health_bar()
	reset_patrol()

func set_camera_active(active: bool) -> void:
	set_physics_process(active or state == State.ALERT)
	animation.active = active
	visible = active and death_fade < 1.0

func reset_patrol() -> void:
	if down_tween and down_tween.is_valid():
		down_tween.kill()
	_set_death_fade(0.0)
	position.x = start_x
	direction = -1 if starts_facing_left else 1
	target_x = start_x + patrol_distance * direction
	model.position = Vector3.ZERO
	model.rotation = Vector3(0, direction * PI * 0.5, 0)
	health = MAX_HEALTH
	elapsed = 0.0
	shots_left = 0
	alert_memory = 0.0
	return_fire_time = 0.0
	aim_weight = 0.0
	recoil = 0.0
	pause_index = 0
	state = State.WALK
	hitbox.set_deferred("disabled", false)
	ring.show()
	ring_material.set_shader_parameter("alerted", 0.0)
	ring_material.set_shader_parameter("facing", float(direction))
	show()
	animation.play(WALK, 0.0)
	animation.seek(0.0, true)
	animation.speed_scale = 1.0

func _resolve_player() -> bool:
	if is_instance_valid(player):
		return true
	var p_node := get_parent()
	if p_node and "actor" in p_node and is_instance_valid(p_node.actor):
		player = p_node.actor
		return true
	if is_inside_tree():
		var group_actor := get_tree().get_first_node_in_group("miko8_magnetic_suit") as CharacterBody3D
		if is_instance_valid(group_actor):
			player = group_actor
			return true
	return false

func _is_resetting() -> bool:
	var p_node := get_parent()
	if p_node and "resetting" in p_node:
		return bool(p_node.resetting)
	return false

func _physics_process(delta: float) -> void:
	if state == State.DOWN:
		return
	if not _resolve_player():
		return
	if _is_resetting() or not player.ready_for_input or player.health <= 0:
		return
	var detected := state != State.TURN and _sees_player(alert_radius)
	return_fire_time = maxf(0.0, return_fire_time - delta)
	alert_memory = ALERT_MEMORY if detected else maxf(0.0, alert_memory - delta)
	var can_engage := detected
	if not can_engage and state != State.TURN:
		if return_fire_time > 0.0:
			can_engage = _sees_player(RETURN_FIRE_REACH)
		elif state == State.ALERT and alert_memory > 0.0:
			can_engage = _sees_player(alert_radius + ALERT_REACH_BONUS)
	var weapon_raised := state == State.ALERT and shots_left > 0
	aim_weight = move_toward(aim_weight, 1.0 if weapon_raised else 0.0, delta * 4.0)
	recoil = move_toward(recoil, 0.0, delta * 5.0)
	ring_material.set_shader_parameter("alerted", maxf(aim_weight, .55 if alert_memory > 0.0 else 0.0))
	if state != State.ALERT and can_engage:
		interrupted_state = state
		state = State.ALERT
		animation.speed_scale = 1.0
		animation.play(IDLE, 0.16)
		_begin_burst()
	if state == State.ALERT:
		shot_time -= delta
		if shot_time > 0.0: return
		if shots_left > 0:
			_fire()
			shots_left -= 1
			shot_time = BURST_SPACING if shots_left > 0 else RECOVERY
			return
		if can_engage:
			_begin_burst()
			return
		if alert_memory > 0.0: return
		state = interrupted_state
		elapsed = 0.0
		animation.play(pause_clip if state == State.PAUSE else WALK, 0.18)
	elapsed += delta
	match state:
		State.WALK:
			var distance := absf(target_x - position.x)
			var pace := minf(lerpf(0.45, 1.0, smoothstep(0.0, 0.32, elapsed)),
				lerpf(0.45, 1.0, smoothstep(0.0, 0.30, distance)))
			position.x = move_toward(position.x, target_x, walk_speed * pace * delta)
			animation.speed_scale = pace
			if is_equal_approx(position.x, target_x):
				position.x = target_x
				pause_clip = PAUSES[pause_index]
				pause_index = (pause_index + 1) % PAUSES.size()
				pause_length = animation.get_animation(pause_clip).length
				animation.speed_scale = 1.0
				animation.play(pause_clip, 0.22)
				elapsed = 0.0
				state = State.PAUSE
		State.PAUSE:
			if elapsed >= pause_length:
				elapsed = 0.0
				turn_start = model.rotation.y
				animation.play(TURN, 0.20, animation.get_animation(TURN).length / TURN_TIME)
				state = State.TURN
		State.TURN:
			model.rotation.y = turn_start - PI * smoothstep(0.0, TURN_TIME, elapsed)
			if elapsed >= TURN_TIME:
				direction *= -1
				model.rotation.y = direction * PI * 0.5
				ring_material.set_shader_parameter("facing", float(direction))
				var outbound := -1 if starts_facing_left else 1
				target_x = start_x + patrol_distance * outbound if direction == outbound else start_x
				animation.play(WALK, 0.17)
				elapsed = 0.0
				state = State.WALK

func _sees_player(reach: float) -> bool:
	if not _resolve_player() or not player.ready_for_input or player.health <= 0 or _is_resetting():
		return false
	if player.state.begins_with("Climb"): return false
	var target := _player_aim_point()
	var center := global_position + Vector3.UP * 1.36
	var offset := target - center
	if offset.x * direction <= 0.15 or offset.length_squared() > reach * reach:
		return false
	var query := PhysicsRayQueryParameters3D.create(center, target, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == player

func _begin_burst() -> void:
	aim_target = _player_aim_point()
	shots_left = 2
	shot_time = WIND_UP

func _player_aim_point() -> Vector3:
	var center := player.body_collision.global_position as Vector3
	return center + Vector3.UP * (.1 if player.crouch_motion.low_collider else .36)

func _fire() -> void:
	if not _resolve_player() or player.health <= 0 or not player.ready_for_input or _is_resetting(): return
	var origin := muzzle_position
	var aim := (aim_target - origin).normalized()
	var pool: Node = player.abilities.projectile_pool
	pool.spawn_bolt(self, origin + aim * 0.03, aim * 9.8, "Warden", 1)
	pool.spawn_impact(origin, Color("ffa138"))
	recoil = 1.0

func receive_combat_bolt() -> void:
	if state == State.DOWN or _is_resetting():
		return
	health = maxi(0, health - BOLT_DAMAGE)
	if health > 0:
		return_fire_time = ALERT_MEMORY
		alert_memory = ALERT_MEMORY
		return
	state = State.DOWN
	hitbox.set_deferred("disabled", true)
	ring.hide()
	aim_weight = 0.0
	animation.speed_scale = 1.0
	animation.play(DEATH, 0.12)
	_prepare_death_materials()
	down_tween = create_tween()
	down_tween.tween_interval(animation.get_animation(DEATH).length + CORPSE_HOLD)
	down_tween.tween_method(_set_death_fade, 0.0, 1.0, FADE_TIME)
	down_tween.tween_callback(hide)

func _prepare_death_materials() -> void:
	if not death_materials.is_empty():
		return
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var paint := mesh.get_active_material(surface) as ShaderMaterial
			if paint == null:
				continue
			var local_paint := paint.duplicate() as ShaderMaterial
			mesh.set_surface_override_material(surface, local_paint)
			death_materials.append(local_paint)

func _set_death_fade(value: float) -> void:
	death_fade = value
	for paint in death_materials:
		paint.set_shader_parameter("dissolve", value)

func _add_ring() -> void:
	if not ring_geometry:
		# Only submit the thin perimeter. An 8 m alert radius can cover the
		# whole viewport if drawn as a transparent quad.
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(160):
			var a := Vector2.from_angle(TAU * i / 160.0)
			var b := Vector2.from_angle(TAU * (i + 1) / 160.0)
			var inner_a := a * .975
			var inner_b := b * .975
			var outer_a := a * 1.01
			var outer_b := b * 1.01
			for point: Vector2 in [inner_a, outer_a, outer_b, inner_a, outer_b, inner_b]:
				surface.set_uv(point * .5 + Vector2(.5, .5))
				surface.add_vertex(Vector3(point.x, point.y, 0))
		ring_geometry = surface.commit()
	ring_material = ShaderMaterial.new()
	ring_material.shader = preload("res://shaders/miko7_warden_alert_ring.gdshader")
	ring = MeshInstance3D.new()
	ring.mesh = ring_geometry
	ring.scale = Vector3(alert_radius, alert_radius, 1.0)
	ring.material_override = ring_material
	ring.position = Vector3(0.0, 0.94, -0.45)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)

func _add_health_bar() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 3
	add_child(canvas)
	var bar := preload("res://scripts/miko8_health_bar.gd").new()
	bar.actor = self
	bar.hostile = true
	canvas.add_child(bar)

func _add_shadows() -> void:
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0, 0, 0, 0.62), Color.TRANSPARENT])
	var texture := GradientTexture2D.new()
	texture.gradient = fade
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	for side in ["L", "R"]:
		feet.append(skeleton.find_bone("DEF-foot." + side))
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_texture = texture
		var plane := PlaneMesh.new()
		plane.size = Vector2(0.52, 0.34)
		var patch := MeshInstance3D.new()
		patch.mesh = plane
		patch.material_override = material
		patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(patch)
		boot_shadows.append(patch)

func _process(_delta: float) -> void:
	if not visible:
		return
	for i in range(feet.size()):
		var foot := skeleton.to_global(skeleton.get_bone_global_pose(feet[i]).origin)
		var patch := boot_shadows[i]
		patch.global_position = Vector3(foot.x, global_position.y + 0.012, foot.z)
		var lift := smoothstep(0.14, 0.42, foot.y - global_position.y)
		(patch.material_override as StandardMaterial3D).albedo_color.a = lerpf(0.93, 0.16, lift) * (1.0 - death_fade)
