extends CharacterBody3D

const MODEL := preload("res://models/props/lab_armored_hover_boss.glb")
const Actor := preload("res://scripts/actor.gd")
const HALO := preload("res://shaders/lab_halo.gdshader")
const BEAM_Y := 1.47
const BEAM_HALF_HEIGHT := .065
const HOME_X := 30.6
const LEFT_LIMIT := 18.8
const RIGHT_LIMIT := 32.5
const CHARGE_TIME := 1.04
const FIRE_TIME := .28
const RECOVERY_TIME := .64
const LASER_DAMAGE := Actor.MAX_HEALTH / 2

enum Phase { PATROL, CHARGE, FIRE, RECOVER }

var target: Actor
var left_wall := 0.0
var right_wall := 36.0
var phase := Phase.PATROL
var age := 0.0
var fire_delay := 2.9
var travel_direction := -1.0
var aim_direction := -1.0
var speed := 0.0
var beam_hit := false

var droid: Node3D
var idle_player: AnimationPlayer
var pitch: Node3D
var muzzle: Node3D
var pitch_rest: Vector3
var emission: MeshInstance3D
var beam: MeshInstance3D
var beam_paint: ShaderMaterial
var beam_spill: MeshInstance3D
var wall_glow: MeshInstance3D
var wash_paint: ShaderMaterial
var wake_paint: ShaderMaterial
var sparks: GPUParticles3D
var muzzle_light: OmniLight3D
var charge_sound: AudioStreamPlayer3D
var fire_sound: AudioStreamPlayer3D

func _ready() -> void:
	name = "ArmoredHoverBoss"
	process_physics_priority = 10
	_build_collision()
	droid = MODEL.instantiate() as Node3D
	add_child(droid)
	idle_player = droid.find_child("AnimationPlayer", true, false) as AnimationPlayer
	idle_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	idle_player.get_animation("HoverIdle").loop_mode = Animation.LOOP_LINEAR
	pitch = droid.find_child("Cannon_Front_Pitch", true, false) as Node3D
	muzzle = droid.find_child("Cannon_Front_Muzzle", true, false) as Node3D
	pitch_rest = pitch.position
	_build_effects()
	reset()

func reset() -> void:
	position = Vector3(HOME_X, 0, -.15)
	droid.rotation_degrees.y = -52.0
	phase = Phase.PATROL
	age = 0.0
	fire_delay = 2.9
	speed = 0.0
	travel_direction = -1.0
	aim_direction = -1.0
	beam_hit = false
	charge_sound.stop()
	fire_sound.stop()
	sparks.emitting = false
	idle_player.stop()
	idle_player.play("HoverIdle")
	_update_cannon(0.0)
	_draw_shot(0.0, 0.0)

func _physics_process(delta: float) -> void:
	var engaged := is_instance_valid(target) and not target.automation and target.health > 0
	if not engaged:
		if phase != Phase.PATROL:
			phase = Phase.PATROL
			age = 0.0
			fire_delay = 1.3
			charge_sound.stop()
			fire_sound.stop()
			sparks.emitting = false
		_update_cannon(delta)
		_draw_shot(0.0, 0.0)
		return

	age += delta
	_update_patrol(delta)
	match phase:
		Phase.PATROL:
			if target.global_position.x >= left_wall + 7.5:
				fire_delay -= delta
			var offset := target.global_position.x - global_position.x
			if absf(offset) > .9:
				aim_direction = signf(offset)
			var heading := deg_to_rad(52.0) * aim_direction
			droid.rotation.y = move_toward(droid.rotation.y, heading, delta * 3.8)
			if fire_delay <= 0.0 and absf(offset) >= 3.0 and absf(offset) <= 24.0 and is_equal_approx(droid.rotation.y, heading):
				_enter(Phase.CHARGE)
				charge_sound.play()
		Phase.CHARGE:
			if age >= CHARGE_TIME:
				_enter(Phase.FIRE)
				beam_hit = false
				fire_sound.play()
				sparks.position = Vector3(_wall_x() - global_position.x, BEAM_Y, to_local(muzzle.global_position).z + .13)
				sparks.process_material.direction = Vector3(-aim_direction, .32, .25)
				sparks.restart()
				sparks.emitting = true
		Phase.FIRE:
			if age >= FIRE_TIME:
				_enter(Phase.RECOVER)
		Phase.RECOVER:
			if age >= RECOVERY_TIME:
				_enter(Phase.PATROL)
				fire_delay = 2.1

	_update_cannon(delta)
	var charge := 0.0
	var power := 0.0
	match phase:
		Phase.CHARGE:
			charge = smoothstep(0.0, CHARGE_TIME, age)
		Phase.FIRE:
			charge = 1.0
			power = 1.0 - .36 * smoothstep(.065, FIRE_TIME, age)
			_check_beam_hit()
		Phase.RECOVER:
			charge = .32 * (1.0 - smoothstep(0.0, .23, age))
			power = .64 * (1.0 - smoothstep(0.0, .09, age))
	_draw_shot(charge, power)

func _enter(next: Phase) -> void:
	phase = next
	age = 0.0

func _update_patrol(delta: float) -> void:
	var goal := 0.0
	if phase in [Phase.PATROL, Phase.RECOVER] and target.global_position.x >= left_wall + 5.5:
		if position.x <= LEFT_LIMIT + .07:
			travel_direction = 1.0
		elif position.x >= RIGHT_LIMIT - .07:
			travel_direction = -1.0
		var remaining := RIGHT_LIMIT - position.x if travel_direction > 0 else position.x - LEFT_LIMIT
		goal = travel_direction * clampf(remaining * 3.2, .6, 3.4)
		if phase == Phase.RECOVER:
			goal *= smoothstep(.13, RECOVERY_TIME, age)
	speed = move_toward(speed, goal, delta * 12.0)
	var next_x := clampf(position.x + speed * delta, LEFT_LIMIT, RIGHT_LIMIT)
	if not is_equal_approx(next_x, position.x):
		var collision := move_and_collide(Vector3(next_x - position.x, 0, 0))
		if collision and collision.get_collider() == target:
			# Sweep Miko against the rest of the room before advancing the hull.
			var push := Vector3(collision.get_remainder().x, 0, 0)
			target.move_and_collide(push)
			move_and_collide(push)
	wash_paint.set_shader_parameter("drift", speed / 3.4)
	wake_paint.set_shader_parameter("drift", speed / 3.4)

func _update_cannon(delta: float) -> void:
	idle_player.advance(delta)
	pitch.position = pitch_rest
	var raised := 0.0
	match phase:
		Phase.CHARGE:
			raised = smoothstep(0.0, .49, age)
		Phase.FIRE:
			raised = 1.0
		Phase.RECOVER:
			raised = 1.0 - smoothstep(.12, .54, age)
	pitch.rotation.x = -.13 * raised
	# The idle chassis bobs independently of the beam height.
	pitch.global_position += Vector3.UP * (BEAM_Y - muzzle.global_position.y) * raised

func _wall_x() -> float:
	return left_wall + .19 if aim_direction < 0.0 else right_wall - .19

func _check_beam_hit() -> void:
	if beam_hit or target.invulnerable > 0.0 or target.state == "dash":
		return
	var feet := target.global_position.y
	var head := feet + (target.crouch_shape.height if target.crouched else target.stand_shape.height)
	var origin := muzzle.global_position.x
	var x := target.global_position.x
	if x < minf(origin, _wall_x()) - .25 or x > maxf(origin, _wall_x()) + .25:
		return
	if feet <= BEAM_Y + BEAM_HALF_HEIGHT and head >= BEAM_Y - BEAM_HALF_HEIGHT:
		beam_hit = true
		target.receive_attack(global_position.x, LASER_DAMAGE)

func _build_collision() -> void:
	collision_layer = 1
	collision_mask = 2
	# Keep a small gap under the hover skirt and step the profile in at the crown.
	_add_hull_box(.77, Vector3(2.20, .94, 1.68))
	_add_hull_box(1.73, Vector3(2.72, 1.12, 1.76))
	_add_hull_box(2.47, Vector3(1.77, .59, 1.50))

func _add_hull_box(height: float, size: Vector3) -> void:
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	collider.position.y = height
	add_child(collider)

func _build_effects() -> void:
	var shadow := ShaderMaterial.new()
	shadow.shader = preload("res://shaders/lab_contact.gdshader")
	shadow.set_shader_parameter("opacity", .64)
	_quad(Vector3(0, .021, 0), Vector2(4.35, 2.9), shadow).rotation.x = -PI * .5
	wash_paint = ShaderMaterial.new()
	wash_paint.shader = preload("res://shaders/lab_boss_floor_wash.gdshader")
	_quad(Vector3(0, .029, 0), Vector2(6.3, 3.1), wash_paint).rotation.x = -PI * .5
	wake_paint = wash_paint.duplicate() as ShaderMaterial
	wake_paint.set_shader_parameter("wake", true)
	_quad(Vector3(0, .31, .67), Vector2(6.0, .61), wake_paint)
	beam_paint = ShaderMaterial.new()
	beam_paint.shader = preload("res://shaders/lab_boss_laser.gdshader")
	beam = _quad(Vector3.ZERO, Vector2.ONE, beam_paint)
	beam_spill = _halo(Color("ff2748"), Vector2.ONE)
	beam_spill.rotation.x = -PI * .5
	emission = _halo(Color("ff2941"), Vector2(1.22, 1.05))
	wall_glow = _halo(Color("ff4761"), Vector2(1.45, 1.62))
	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color("ff3551")
	muzzle_light.omni_range = 3.4
	add_child(muzzle_light)
	_build_sparks()
	charge_sound = _audio(preload("res://audio/droid_laser_swing.wav"), .72, -15.0)
	fire_sound = _audio(preload("res://audio/laser_clash.wav"), .66, -7.0)

func _draw_shot(charge: float, power: float) -> void:
	var tip := to_local(muzzle.global_position)
	emission.visible = charge > .015
	muzzle_light.visible = emission.visible
	if emission.visible:
		emission.position = tip + Vector3(aim_direction * .025, 0, .20)
		_set_glow(emission, charge * (.9 + .1 * sin(age * 45.0)) + power * .85)
		muzzle_light.position = emission.position
		muzzle_light.light_energy = charge * 1.6 + power * 2.6
	beam.visible = power > .006
	beam_spill.visible = beam.visible
	wall_glow.visible = beam.visible
	if not beam.visible:
		return
	var end := _wall_x() - global_position.x
	var span := absf(end-tip.x)
	beam.position = Vector3((end + tip.x) * .5, BEAM_Y, tip.z)
	beam.scale.x = span
	beam_paint.set_shader_parameter("span", span)
	beam_paint.set_shader_parameter("power", power)
	beam_paint.set_shader_parameter("direction", aim_direction)
	beam_spill.position = Vector3(beam.position.x, .037, tip.z * .55)
	beam_spill.scale = Vector3(span * 1.37, 2.6, 1.0)
	_set_glow(beam_spill, power * .44)
	wall_glow.position = Vector3(end, BEAM_Y, tip.z + .12)
	_set_glow(wall_glow, power * 1.12)

func _quad(at: Vector3, size: Vector2, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	mesh.mesh = quad
	mesh.position = at
	mesh.material_override = paint
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh

func _halo(tint: Color, size: Vector2) -> MeshInstance3D:
	var paint := ShaderMaterial.new()
	paint.shader = HALO
	paint.set_shader_parameter("light_color", tint)
	return _quad(Vector3.ZERO, size, paint)

func _set_glow(mesh: MeshInstance3D, energy: float) -> void:
	mesh.material_override.set_shader_parameter("energy", energy)

func _build_sparks() -> void:
	sparks = GPUParticles3D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = 20
	sparks.lifetime = .40
	sparks.explosiveness = .85
	var motion := ParticleProcessMaterial.new()
	motion.spread = 37.0
	motion.initial_velocity_min = 2.7
	motion.initial_velocity_max = 7.0
	motion.gravity = Vector3.DOWN * 9.3
	motion.scale_min = .42
	motion.scale_max = 1.0
	sparks.process_material = motion
	var chip := BoxMesh.new()
	chip.size = Vector3(.14, .023, .023)
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = Color("ffb09e")
	chip.material = paint
	sparks.draw_pass_1 = chip
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)

func _audio(stream: AudioStream, pitch_scale: float, volume: float) -> AudioStreamPlayer3D:
	var audio := AudioStreamPlayer3D.new()
	audio.stream = stream
	audio.pitch_scale = pitch_scale
	audio.volume_db = volume
	audio.unit_size = 10.0
	audio.max_distance = 38.0
	add_child(audio)
	return audio
