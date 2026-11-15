extends CharacterBody3D

const EnemyBurst := preload("res://scripts/lab_enemy_burst.gd")
const Bolt := preload("res://scripts/lab_turret_bolt.gd")
const SWIPE := preload("res://audio/droid_laser_swing.wav")
const METAL_STEP := preload("res://audio/impactMetal_heavy_001.ogg")
const LASER_SHOT := preload("res://audio/laser_clash.wav")
const WALK_SPEED := 1.85
const WALK_CLIP_SPEED := 1.17*.86
const AIR_SPEED := 3.7
const GRAVITY := 25.0
const JUMP_SPEED := 8.4
const WINDUP := .13
const LANDING := .15
const VIEW_ANGLE := PI*.41
const MODEL_SCALE := .86
const LUNGE_LENGTH := 1.48 * MODEL_SCALE
const LUNGE_TIME := 32.0 / 30.0
const LEAP_WINDUP := .32
const LEAP_SPEED := 7.4
const DIVE_START := .22
const LEAP_RECOVERY := .46
const LASER_MIN_RANGE := 4.35
const LASER_RANGE := 13.0
const LASER_LOCK_TIME := .77
const LASER_CHARGE_TIME := 1.0
const LASER_COOLDOWN := 3.2
const PLASMA_SPEED := 23.0
const DURABILITY := 3
enum State {
	PATROL, LUNGE, LEAP_WINDUP, LEAP_AIR, RECOVER, RECOIL, BROKEN,
	LASER_CHARGE, LASER_RECOVERY,
}

@export var home := Vector3(11.25, 1.04, -.64)
@export var left_turn := 4.1
@export var right_turn := 19.1
@export var initial_facing := 1.0
@export var thermal_steps := true

var target: CharacterBody3D
var visual: Node3D
var animation: AnimationPlayer
var skeleton: Skeleton3D
var wrist: int
var elbow: int
var collider: CollisionShape3D
var paint: ShaderMaterial
var audio: AudioStreamPlayer3D
var destruction: EnemyBurst
var streak: ImmediateMesh
var streak_material: StandardMaterial3D
var streak_points: Array[Vector3] = []
var shadow: MeshInstance3D
var shadow_paint: ShaderMaterial
var floor_ray := PhysicsRayQueryParameters3D.new()
var facing := 1.0
var windup_time := 0.0
var ground_pause := 0.0
var airborne := false
var state := State.PATROL
var age := 0.0
var cooldown := 0.0
var hitstop := 0.0
var hits := 0
var playing_speed := 1.0
var attempted_hit := false
var head: int
var eye_offset: Vector3
var eye_glow: MeshInstance3D
var eye_paint: ShaderMaterial
var beam: MeshInstance3D
var beam_paint: ShaderMaterial
var laser_origin := Vector3.ZERO
var laser_direction := Vector3.ZERO
var laser_cooldown := 0.0
var laser_ray := PhysicsRayQueryParameters3D.new()
var plasma: Node3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = .22
	collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .23
	capsule.height = 1.63
	collider.shape = capsule
	collider.position.y = capsule.height*.5
	add_child(collider)
	var model := load("res://models/RedScout.glb") as PackedScene
	visual = model.instantiate() as Node3D
	visual.scale = Vector3.ONE * MODEL_SCALE
	add_child(visual)
	animation = visual.find_children("*","AnimationPlayer",true,false)[0]
	skeleton = visual.find_children("*", "Skeleton3D", true, false)[0]
	wrist = skeleton.find_bone("DEF-hand.R")
	elbow = skeleton.find_bone("DEF-forearm.R")
	head = skeleton.find_bone("DEF-head")
	# The visor is baked into the head mesh. Anchor its light to the skinned head.
	eye_offset = skeleton.get_bone_global_rest(head).affine_inverse() * Vector3(0, 1.735, .19)
	for label in ["Idle","Walk","Run","JumpAir"]:
		animation.get_animation("Scout_"+label).loop_mode = Animation.LOOP_LINEAR
	var mesh: MeshInstance3D = visual.find_children("*","MeshInstance3D",true,false)[0]
	var original := mesh.get_active_material(0) as StandardMaterial3D
	paint = ShaderMaterial.new()
	paint.shader = preload("res://shaders/miko8_three_tone.gdshader")
	paint.set_shader_parameter("base_texture",original.albedo_texture)
	paint.set_shader_parameter("shadow_tone",Vector3(.56,.53,.55))
	paint.set_shader_parameter("middle_tone",Vector3(.93,.85,.81))
	paint.set_shader_parameter("light_tone",Vector3(1.26,1.13,1.03))
	paint.set_shader_parameter("transition_width",.08)
	mesh.set_surface_override_material(0,paint)
	_build_shadow()
	_build_attack_effects()
	_build_laser()
	destruction = EnemyBurst.new()
	destruction.ember_color = Color("ff5d43")
	add_child(destruction)
	reset()

func reset() -> void:
	position = home
	velocity = Vector3.ZERO
	facing = initial_facing
	windup_time = 0
	ground_pause = 0.0
	airborne = false
	_enter(State.PATROL)
	cooldown = .65
	laser_cooldown = 0.0
	hits = 0
	hitstop = 0.0
	playing_speed = 1.0
	visual.show()
	collider.set_deferred("disabled", false)
	paint.set_shader_parameter("droid_warning", 0.0)
	destruction.reset()
	audio.stop()
	_clear_streak()
	_hide_laser()
	if is_instance_valid(plasma):
		plasma.set_physics_process(false)
		plasma.queue_free()
	visual.rotation.y = facing * VIEW_ANGLE
	animation.speed_scale = 1
	animation.play("Scout_Idle")

func _physics_process(delta: float) -> void:
	if state == State.BROKEN:
		return
	hitstop = maxf(0.0, hitstop - delta)
	paint.set_shader_parameter("droid_warning", hitstop * 3.2)
	if hitstop > 0.0:
		animation.speed_scale = 0.0
		return
	animation.speed_scale = playing_speed
	cooldown = maxf(0.0, cooldown - delta)
	laser_cooldown = maxf(0.0, laser_cooldown - delta)
	if state == State.PATROL:
		_try_attack()
	var previous_age := age
	age += delta
	var attack_active := false
	var result_before_move := state
	match state:
		State.PATROL:
			_patrol(delta)
		State.LUNGE:
			# The model's ankle paths were authored against this exact travel curve.
			velocity.x = facing * (_lunge_travel(age) - _lunge_travel(previous_age)) / delta
			attack_active = age >= .405 and age <= .59
			if previous_age < .385 and age >= .385:
				_play_audio(SWIPE, 1.12, -11.0)
			if age >= LUNGE_TIME:
				_resume_patrol(.60)
		State.LEAP_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, delta * 30.0)
			if age >= LEAP_WINDUP:
				_launch_strike()
		State.LEAP_AIR:
			velocity.y -= GRAVITY * delta
			if previous_age < DIVE_START and age >= DIVE_START:
				_play("Dive", 1.15)
				_play_audio(SWIPE, .86, -11.0)
			attack_active = age >= DIVE_START + .105 and velocity.y < -1.1
		State.RECOVER, State.RECOIL:
			velocity.x = move_toward(velocity.x, 0.0, delta * 26.0)
			if not is_on_floor():
				velocity.y -= GRAVITY * delta
			if age >= (LEAP_RECOVERY if state == State.RECOVER else .39):
				_resume_patrol(.55)
		State.LASER_CHARGE, State.LASER_RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, delta * 28.0)
			if not is_on_floor():
				velocity.y -= GRAVITY * delta
	var strikes := state in [State.LUNGE, State.LEAP_WINDUP, State.LEAP_AIR]
	var lane := -.14 if strikes or state == State.RECOVER else home.z
	velocity.z = (move_toward(position.z, lane, delta * 2.45) - position.z) / delta
	var previous_x := global_position.x
	move_and_slide()
	visual.rotation.y = rotate_toward(visual.rotation.y, facing * VIEW_ANGLE, delta * 14.0)
	if attack_active and not attempted_hit:
		_try_hit(previous_x, result_before_move == State.LEAP_AIR)
	if state == State.LEAP_AIR and is_on_floor() and velocity.y <= 0.0:
		velocity.x = 0.0
		_enter(State.RECOVER)
		_play("JumpLand", 1.35, .17)
		_play_audio(METAL_STEP, 1.17, -15.0)
	_update_streak(attack_active and state in [State.LUNGE, State.LEAP_AIR])
	if state in [State.LASER_CHARGE, State.LASER_RECOVERY]:
		_update_laser()
	_update_shadow()

func _patrol(delta: float) -> void:
	var grounded := is_on_floor()
	if grounded:
		if airborne:
			airborne = false
			ground_pause = LANDING
			_play("JumpLand",1.7,.17)
		if ground_pause > 0:
			ground_pause = maxf(0,ground_pause-delta)
			velocity.x = move_toward(velocity.x,0,delta*29)
		elif windup_time > 0:
			windup_time = maxf(0,windup_time-delta)
			velocity.x = move_toward(velocity.x,0,delta*26)
			if windup_time == 0:
				velocity.y = JUMP_SPEED
				velocity.x = AIR_SPEED*facing
				airborne = true
				_play("JumpAir",1.0,.08)
		elif _at_step():
			windup_time = WINDUP
			_play("JumpStart",1.4,.15)
		else:
			if position.x >= right_turn:
				facing = -1
			elif position.x <= left_turn:
				facing = 1
			velocity.x = move_toward(velocity.x,facing*WALK_SPEED,delta*13)
			_play("Walk",maxf(.45,absf(velocity.x)/WALK_CLIP_SPEED))
	else:
		velocity.y -= GRAVITY*delta
		if not airborne:
			airborne = true
			_play("JumpAir",1.0,.38)

func _enter(next: State) -> void:
	state = next
	age = 0.0
	attempted_hit = false

func _resume_patrol(delay: float) -> void:
	_enter(State.PATROL)
	cooldown = delay
	ground_pause = 0.0
	windup_time = 0.0
	airborne = not is_on_floor()
	if airborne:
		_play("JumpAir", 1.0, .38)

func _try_attack() -> void:
	if cooldown > 0.0 or not is_on_floor() or ground_pause > 0.0 or windup_time > 0.0:
		return
	if not is_instance_valid(target) or target.health <= 0 or target.automation:
		return
	var offset := target.global_position - global_position
	var distance := absf(offset.x)
	if distance > LASER_MIN_RANGE:
		_try_laser(offset, distance)
		return
	if target.position.x < left_turn - .6 or target.position.x > right_turn + .6:
		return
	if distance < .15 or absf(offset.y) > 1.15:
		return
	var direction := signf(offset.x)
	if distance <= 2.15 and absf(offset.y) < .52 and _flat_lunge(direction):
		facing = direction
		_enter(State.LUNGE)
		_play("Lunge", 1.0)
		_play_audio(METAL_STEP, 1.48, -19.0)
	elif distance > 1.45:
		facing = direction
		_enter(State.LEAP_WINDUP)
		_play("JumpStart", .92, .07)
		_play_audio(METAL_STEP, 1.35, -18.0)

func _try_laser(offset: Vector3, distance: float) -> void:
	var direction := signf(offset.x)
	if laser_cooldown > 0.0 or distance > LASER_RANGE - .45 or absf(offset.y) > 2.1:
		return
	if target.velocity.x * direction < 1.25:
		return
	var from := global_position + Vector3.UP * 1.47
	if not _laser_trace(from, _laser_aim(), 1).is_empty():
		return
	facing = direction
	laser_direction = Vector3.ZERO
	_enter(State.LASER_CHARGE)
	_play("Idle", .30)
	_play_audio(METAL_STEP, 1.75, -19.0)

func _laser_aim() -> Vector3:
	var travel := absf(target.global_position.x - global_position.x) / PLASMA_SPEED
	var lead := clampf(target.velocity.x * travel * .70, -1.65, 1.65)
	return target.global_position + Vector3(lead, 1.34, 0)

func _laser_trace(from: Vector3, to: Vector3, mask: int) -> Dictionary:
	laser_ray.from = from
	laser_ray.to = to
	laser_ray.collision_mask = mask
	return get_world_3d().direct_space_state.intersect_ray(laser_ray)

func _update_laser() -> void:
	match state:
		State.LASER_CHARGE:
			if not is_on_floor() or not is_instance_valid(target) or target.health <= 0 or target.automation:
				_hide_laser()
				_resume_patrol(.55)
				return
			var eye := skeleton.to_global(skeleton.get_bone_global_pose(head) * eye_offset)
			var power := smoothstep(0.0, LASER_CHARGE_TIME, age)
			_show_eye(eye, lerpf(.14, .87, power))
			if age <= LASER_LOCK_TIME or laser_direction == Vector3.ZERO:
				laser_origin = eye
				laser_direction = eye.direction_to(_laser_aim())
			else:
				playing_speed = 0.0
				animation.speed_scale = 0.0
			_draw_laser(lerpf(.32, .76, power))
			if age >= LASER_CHARGE_TIME:
				_fire_plasma()
				beam.hide()
				_enter(State.LASER_RECOVERY)
				laser_cooldown = LASER_COOLDOWN
				_play_audio(LASER_SHOT, 1.42, -10.0)
		State.LASER_RECOVERY:
			if age < .12:
				_show_eye(laser_origin, 1.0 - smoothstep(0.0, .12, age))
			else:
				eye_glow.hide()
			if age >= .36:
				_resume_patrol(.35)

func _fire_plasma() -> void:
	var bolt := Bolt.new()
	bolt.name = "ScoutPlasmaBolt"
	bolt.red_plasma = true
	bolt.speed = PLASMA_SPEED
	bolt.lifetime = LASER_RANGE / PLASMA_SPEED
	bolt.top_level = true
	add_child(bolt)
	bolt.launch(laser_origin, laser_direction, global_position)
	plasma = bolt

func _draw_laser(power: float) -> void:
	var limit := laser_origin + laser_direction * LASER_RANGE
	var end: Vector3 = _laser_trace(laser_origin, limit, 1).get("position", limit)
	var span := end - laser_origin
	if span.length_squared() < .0001:
		beam.hide()
		return
	var along := span.normalized()
	var camera := get_viewport().get_camera_3d()
	var normal := camera.global_basis.z if camera else Vector3.BACK
	var side := normal.cross(along).normalized()
	beam.global_transform = Transform3D(Basis(span, side * .30, along.cross(side)), laser_origin + span * .5)
	beam_paint.set_shader_parameter("power", power)
	beam.show()

func _show_eye(point: Vector3, power: float) -> void:
	eye_glow.global_position = point + Vector3.BACK * .025
	eye_paint.set_shader_parameter("energy", power)
	eye_glow.show()

func _hide_laser() -> void:
	beam.hide()
	eye_glow.hide()

func _lunge_travel(time: float) -> float:
	return LUNGE_LENGTH * smoothstep(8.0/30.0, 22.0/30.0, time)

func _deck_at(x: float) -> Dictionary:
	var from := Vector3(x, global_position.y + 1.8, -.14)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 3.8, 1)
	return get_world_3d().direct_space_state.intersect_ray(query)

func _flat_lunge(direction: float) -> bool:
	var end := global_position.x + direction * (LUNGE_LENGTH + .31)
	if end < left_turn - .65 or end > right_turn + .65:
		return false
	for fraction in [.34, .68, 1.0]:
		var floor_hit := _deck_at(lerpf(global_position.x, end, fraction))
		if floor_hit.is_empty() or absf(floor_hit.position.y - global_position.y) > .12:
			return false
	return true

func _launch_strike() -> void:
	# Lead Miko slightly, then keep this trajectory even if he changes direction.
	var lead := clampf(target.velocity.x * .12, -.65, .65)
	var reach := clampf((target.global_position.x + lead - global_position.x) * facing - .42, .75, 4.30)
	var landing_x := clampf(global_position.x + facing * reach, left_turn, right_turn)
	var floor_hit := _deck_at(landing_x)
	var rise := 0.0 if floor_hit.is_empty() else float(floor_hit.position.y) - global_position.y
	var time := (LEAP_SPEED + sqrt(maxf(1.0, LEAP_SPEED * LEAP_SPEED - 2.0 * GRAVITY * rise))) / GRAVITY
	velocity.x = (landing_x - global_position.x) / time
	velocity.y = LEAP_SPEED
	_enter(State.LEAP_AIR)
	_play("JumpAir", 1.0, .08)

func _try_hit(previous_x: float, diving: bool) -> void:
	if not is_instance_valid(target) or target.health <= 0 or target.automation:
		return
	var offset := target.global_position - global_position
	var relative_x := offset.x * facing
	var back := -.22 - absf(global_position.x - previous_x)
	var reach := .79 if diving else .90
	if relative_x < back or relative_x > reach or absf(offset.z) > .64:
		return
	if offset.y < (-1.20 if diving else -.60) or offset.y > (.50 if diving else .84):
		return
	var contact_height := .64 if diving else .91
	var from := global_position + Vector3(0.0, contact_height, 0.0)
	var to := target.global_position + Vector3.UP * (.48 if target.crouched else .88)
	if not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1)).is_empty():
		return
	attempted_hit = true
	if target.receive_attack(global_position.x - facing * .12):
		_stagger(.11)

func get_hit_point() -> Vector3:
	return global_position + Vector3.UP * .90

func receive_hit(_damage: int, direction: int, _lift: float) -> void:
	if state == State.BROKEN:
		return
	hits += 1
	if hits < DURABILITY:
		facing = -signf(direction)
		_stagger(.065)
		return
	_enter(State.BROKEN)
	velocity = Vector3.ZERO
	collider.set_deferred("disabled", true)
	shadow.hide()
	_clear_streak()
	_hide_laser()
	visual.hide()
	audio.stop()
	var deck := _deck_at(global_position.x)
	var floor_height := global_position.y if deck.is_empty() else float(deck.position.y)
	destruction.explode(get_hit_point(), floor_height, direction, [])

func _stagger(pause: float) -> void:
	if state == State.LASER_CHARGE:
		laser_cooldown = LASER_COOLDOWN
		audio.stop()
	_enter(State.RECOIL)
	velocity.x = -facing * 1.55
	hitstop = pause
	_play("Recoil", 1.0)
	animation.advance(0.0)
	_clear_streak()
	_hide_laser()

func _at_step() -> bool:
	if not thermal_steps:
		return false
	if facing > 0:
		return (position.y < .12 and absf(position.x-6.65) < .08) or (absf(position.y-.5) < .12 and absf(position.x-9.22) < .08)
	return (position.y < .12 and absf(position.x-16.32) < .08) or (absf(position.y-.5) < .12 and absf(position.x-13.76) < .08)

func _play(label: String, speed: float, start := 0.0) -> void:
	var clip := "Scout_"+label
	playing_speed = speed
	if animation.current_animation == clip:
		animation.speed_scale = speed
		return
	animation.speed_scale = speed
	animation.play(clip,.09)
	if start > 0:
		animation.seek(start)

func _play_audio(stream: AudioStream, pitch: float, volume: float) -> void:
	audio.stream = stream
	audio.pitch_scale = pitch
	audio.volume_db = volume
	audio.play()

func _build_attack_effects() -> void:
	audio = AudioStreamPlayer3D.new()
	audio.max_distance = 12.0
	add_child(audio)
	streak = ImmediateMesh.new()
	streak_material = StandardMaterial3D.new()
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	streak_material.vertex_color_use_as_albedo = true
	streak_material.vertex_color_is_srgb = true
	var ribbon := MeshInstance3D.new()
	ribbon.mesh = streak
	ribbon.top_level = true
	ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ribbon)
	ribbon.global_transform = Transform3D.IDENTITY

func _build_laser() -> void:
	laser_ray.hit_from_inside = true
	beam_paint = ShaderMaterial.new()
	beam_paint.shader = preload("res://shaders/lab_scout_beam.gdshader")
	beam = _laser_quad(Vector2.ONE, beam_paint)
	eye_paint = ShaderMaterial.new()
	eye_paint.shader = preload("res://shaders/lab_halo.gdshader")
	eye_paint.set_shader_parameter("light_color", Color("ff4f43"))
	eye_glow = _laser_quad(Vector2(.41, .22), eye_paint)

func _laser_quad(size: Vector2, material: ShaderMaterial) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.top_level = true
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _update_streak(active: bool) -> void:
	if not active and streak_points.is_empty():
		return
	streak.clear_surfaces()
	if active:
		var hand := skeleton.to_global(skeleton.get_bone_global_pose(wrist).origin)
		var forearm := skeleton.to_global(skeleton.get_bone_global_pose(elbow).origin)
		streak_points.append(hand + (hand - forearm).normalized() * .09 + Vector3.BACK * .10)
		if streak_points.size() > 5:
			streak_points.pop_front()
	else:
		streak_points.pop_front()
	if streak_points.size() < 2:
		return
	streak.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, streak_material)
	for i in streak_points.size():
		var before := streak_points[maxi(0, i - 1)]
		var after := streak_points[mini(streak_points.size() - 1, i + 1)]
		var movement := after - before
		var t := float(i) / float(streak_points.size() - 1)
		var edge := Vector3(-movement.y, movement.x, 0.0).normalized() * lerpf(.008, .074, t)
		var heat := Color("fb4938").lerp(Color("ffd4b1"), t)
		heat.a = t * .72
		streak.surface_set_color(heat)
		streak.surface_add_vertex(streak_points[i] + edge)
		heat.a *= .16
		streak.surface_set_color(heat)
		streak.surface_add_vertex(streak_points[i] - edge)
	streak.surface_end()

func _clear_streak() -> void:
	streak_points.clear()
	streak.clear_surfaces()

func _build_shadow() -> void:
	floor_ray.collision_mask = 1
	shadow_paint = ShaderMaterial.new()
	shadow_paint.shader = preload("res://shaders/lab_contact.gdshader")
	shadow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(.92,.72)
	shadow.mesh = quad
	shadow.material_override = shadow_paint
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.top_level = true
	shadow.rotation.x = -PI*.5
	add_child(shadow)

func _update_shadow() -> void:
	floor_ray.from = global_position+Vector3.UP*.10
	floor_ray.to = global_position+Vector3.DOWN*3.0
	var hit := get_world_3d().direct_space_state.intersect_ray(floor_ray)
	shadow.visible = not hit.is_empty()
	if shadow.visible:
		shadow.global_position = hit.position+Vector3.UP*.024
		shadow_paint.set_shader_parameter("opacity",.43*clampf(1.0-(global_position.y-hit.position.y)/2.5,0,1))
