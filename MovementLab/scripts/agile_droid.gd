extends "res://scripts/dummy.gd"

const MAX_HEALTH := 100
const PATROL_RADIUS := 3.0
const PATROL_SPEED := 1.5
const SIGHT_RANGE := 5.3
const AIM_TIME := 1.25
const LOCK_TIME := .35
const RECOVERY_TIME := 1.35
const BOLT_SPEED := 14.0
const CORPSE_HOLD := 2.5
const FADE_TIME := .9
const SHOULDER := Vector2(-.27, 1.49)
const REST_MUZZLE := Vector2(-.77, .92)

enum Mode { PATROL, RETREAT, AIM, RECOVER, DOWN }

var health := MAX_HEALTH
var mode := Mode.PATROL
var elapsed := 0.0
var facing := 0
var patrol_direction := 1
var turn_pause := 0.0
var stride_phase := 0.0
var aim_weight := 0.0
var shot_direction := Vector3.LEFT
var bolt_position := Vector3.ZERO
var bolt_distance := 0.0
var bolt_depth := 0.0
var fall_direction := 1
var death_tween: Tween
var sight_line: MeshInstance3D
var muzzle_light: MeshInstance3D
var bolt: MeshInstance3D
var warning_paint: StandardMaterial3D

func _ready() -> void:
	super._ready()
	warning_paint = _glow(Color("ffc05e"))
	sight_line = _effect(warning_paint)
	muzzle_light = _effect(warning_paint)
	var charge_mesh := SphereMesh.new()
	charge_mesh.radial_segments = 8
	charge_mesh.rings = 4
	muzzle_light.mesh = charge_mesh
	bolt = _effect(_glow(Color("fff3a3")))
	var canvas := CanvasLayer.new()
	canvas.layer = 3
	add_child(canvas)
	var bar := preload("res://scripts/miko8_health_bar.gd").new()
	bar.actor = self
	bar.hostile = true
	bar.head_height = 2.124
	canvas.add_child(bar)

func _glow(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func _effect(material: StandardMaterial3D) -> MeshInstance3D:
	var effect := MeshInstance3D.new()
	effect.mesh = BoxMesh.new()
	effect.material_override = material
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effect.top_level = true
	effect.hide()
	add_child(effect)
	return effect

func reset() -> void:
	super.reset()
	if death_tween:
		death_tween.kill()
		death_tween = null
	body.position = Vector3.ZERO
	show()
	health = MAX_HEALTH
	collision_layer = 4
	mode = Mode.PATROL
	elapsed = 0.0
	patrol_direction = 1
	turn_pause = 0.0
	stride_phase = 0.0
	aim_weight = 0.0
	bolt_distance = 0.0
	_face(1)
	_set_dissolve(0.0)
	_update_materials(0.0, 0.0)
	if sight_line:
		sight_line.hide()
		muzzle_light.hide()
		bolt.hide()

func _face(direction: int) -> void:
	if direction == facing:
		return
	facing = direction
	var basis := Basis(Vector3.UP, -1.03).scaled(Vector3.ONE * 1.116)
	if facing > 0:
		basis = Basis.FLIP_X * basis
	droid.transform = Transform3D(basis, Vector3.ZERO)

func _physics_process(delta: float) -> void:
	_update_popups(delta)
	_update_bolt(delta)
	if mode == Mode.DOWN:
		if not death_tween:
			velocity.y -= 25.0 * delta
			move_and_slide()
			if is_on_floor():
				_start_fall()
		return
	if hitstop > 0.0:
		hitstop = maxf(0.0, hitstop - delta)
		return

	stagger = maxf(0.0, stagger - delta)
	elapsed += delta
	velocity.y -= 25.0 * delta
	var stride := 0.0
	var tilt := 0.0
	if stagger > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, delta * 12.0)
		tilt = sin(stagger * 36.0) * stagger * .25
	else:
		match mode:
			Mode.PATROL:
				_patrol(delta)
				stride_phase += absf(velocity.x) * delta * 8.0
				stride = sin(stride_phase) * absf(velocity.x) / PATROL_SPEED
			Mode.RETREAT:
				tilt = -facing * .16
			Mode.AIM, Mode.RECOVER:
				velocity.x = move_toward(velocity.x, 0.0, delta * 12.0)

	move_and_slide()
	position.z = 0.0
	if mode == Mode.RETREAT and is_on_floor():
		velocity.x = 0.0
		_enter(Mode.AIM)

	aim_weight = move_toward(aim_weight, 1.0 if mode == Mode.AIM or (mode == Mode.RECOVER and elapsed < .16) else 0.0, delta * 4.0)
	if mode == Mode.RECOVER and elapsed < .16:
		tilt = -facing * .12 * (1.0 - elapsed / .16)
	body.rotation.z = tilt
	var warning := 0.0
	if mode == Mode.AIM:
		warning = _update_aim()
	elif mode == Mode.RECOVER and elapsed >= RECOVERY_TIME:
		_enter(Mode.PATROL)
	_update_materials(stride, warning)

func _patrol(delta: float) -> void:
	if is_on_floor() and _can_see_miko():
		_face(1 if actor.global_position.x > global_position.x else -1)
		velocity = Vector3(-facing * 3.2, 4.8, 0.0)
		_enter(Mode.RETREAT)
		return
	if turn_pause > 0.0:
		turn_pause -= delta
		velocity.x = 0.0
		return
	if absf(position.x - home.x) >= PATROL_RADIUS and (position.x - home.x) * patrol_direction > 0:
		patrol_direction *= -1
		turn_pause = .25
		velocity.x = 0.0
		_face(patrol_direction)
		return
	if not is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, delta * 12.0)
		return
	_face(patrol_direction)
	velocity.x = patrol_direction * PATROL_SPEED

func _can_see_miko() -> bool:
	if actor.health <= 0:
		return false
	var offset := actor.global_position - global_position
	if absf(offset.x) > SIGHT_RANGE or absf(offset.y) > 1.8:
		return false
	return _trace(global_position + Vector3.UP * 1.5, actor.global_position + Vector3.UP, 1).is_empty()

func _enter(next: Mode) -> void:
	mode = next
	elapsed = 0.0
	sight_line.hide()
	muzzle_light.hide()

func _muzzle() -> Vector3:
	var point := SHOULDER + (REST_MUZZLE - SHOULDER).rotated(-aim_weight * .69)
	return droid.to_global(Vector3(point.x, point.y, .18))

func _update_aim() -> float:
	var muzzle := _muzzle()
	var origin := Vector3(muzzle.x, muzzle.y, 0.0)
	if elapsed <= AIM_TIME - LOCK_TIME:
		_face(1 if actor.global_position.x > global_position.x else -1)
		muzzle = _muzzle()
		origin = Vector3(muzzle.x, muzzle.y, 0.0)
		# A level shot at standing chest height leaves room to duck underneath.
		shot_direction = Vector3(float(facing), 0.0, 0.0)
	var end := origin + shot_direction * 11.0
	var wall := _trace(origin, end, 1)
	if not wall.is_empty():
		end = wall.position
	end.z = muzzle.z
	var charge := clampf(elapsed / AIM_TIME, 0.0, 1.0)
	var pulse := .5 + .5 * sin(elapsed * lerpf(18.0, 34.0, charge))
	warning_paint.albedo_color = Color("a7552e").lerp(Color("ffd773"), .3 + .7 * charge)
	_draw_segment(sight_line, muzzle, end, lerpf(.012, .035, charge) * (.65 + .35 * pulse))
	muzzle_light.global_position = muzzle
	muzzle_light.scale = Vector3.ONE * lerpf(.055, .16, charge) * (.7 + .3 * pulse)
	muzzle_light.show()
	if elapsed >= AIM_TIME:
		bolt_position = origin
		bolt_depth = muzzle.z
		bolt_distance = 11.0
		_enter(Mode.RECOVER)
		_draw_segment(bolt, muzzle - shot_direction * .35, muzzle, .10)
	return charge * (.45 + .55 * pulse)

func _draw_segment(effect: MeshInstance3D, start: Vector3, end: Vector3, thickness: float) -> void:
	effect.global_position = (start + end) * .5
	effect.rotation.z = atan2(end.y - start.y, end.x - start.x)
	effect.scale = Vector3(maxf(.001, start.distance_to(end)), thickness, thickness)
	effect.show()

func _trace(from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	return get_world_3d().direct_space_state.intersect_ray(query)

func _update_bolt(delta: float) -> void:
	if bolt_distance <= 0.0:
		return
	var travel := minf(bolt_distance, BOLT_SPEED * delta)
	var end := bolt_position + shot_direction * travel
	var mask := 1 if actor.state == "dash" else 3
	var contact := _trace(bolt_position, end, mask)
	if not contact.is_empty():
		if contact.collider == actor and actor.receive_attack(global_position.x):
			hitstop = .075
			stagger = .45
		bolt_distance = 0.0
	else:
		bolt_position = end
		bolt_distance -= travel
	if bolt_distance <= 0.0:
		bolt.hide()
		return
	end.z = bolt_depth
	_draw_segment(bolt, end - shot_direction * .42, end, .067)

func _update_materials(stride: float, warning: float) -> void:
	for material in droid_materials:
		material.set_shader_parameter("droid_stride", stride)
		material.set_shader_parameter("droid_aim", aim_weight)
		material.set_shader_parameter("droid_warning", warning)

func receive_hit(amount: int, direction: int, lift: float) -> void:
	if mode == Mode.DOWN:
		return
	super.receive_hit(amount, direction, lift)
	health = maxi(0, health - amount)
	_enter(Mode.RECOVER)
	if health > 0:
		return
	_enter(Mode.DOWN)
	collision_layer = 0
	fall_direction = direction
	aim_weight = 0.0
	_update_materials(0.0, 0.0)
	velocity = Vector3.ZERO
	if is_on_floor():
		_start_fall()

func _start_fall() -> void:
	death_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	death_tween.tween_method(_fall, 0.0, 1.0, .65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	death_tween.tween_interval(CORPSE_HOLD)
	death_tween.tween_method(_set_dissolve, 0.0, 1.0, FADE_TIME)
	death_tween.tween_callback(hide)

func _fall(progress: float) -> void:
	body.rotation.z = -fall_direction * progress * PI * .5
	body.position.y = .22 * progress

func _set_dissolve(value: float) -> void:
	for material in droid_materials:
		material.set_shader_parameter("dissolve", value)
