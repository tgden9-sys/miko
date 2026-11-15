extends StaticBody3D

const MODEL := preload("res://models/props/lab_rail_gun.glb")
const Bolt := preload("res://scripts/lab_turret_bolt.gd")
const EnemyBurst := preload("res://scripts/lab_enemy_burst.gd")
const CHARGE_AUDIO := preload("res://audio/impactMetal_heavy_001.ogg")
const FIRE_AUDIO := preload("res://audio/laser_clash.wav")
const TRACK_Y := 4.65
const TRACK_Z := -1.16
const HOME := Vector3(18.0, TRACK_Y + .222, TRACK_Z)
const LEFT_LIMIT := 11.5
const RIGHT_LIMIT := 41.5
const NOTICE_RANGE := 9.0
const FIRE_RANGE := 6.2
const SPEED := 3.75
const WINDUP := .52
const FOLLOW_UP := .24
const RELOAD := 2.1
const BOLT_SPEED := 14.5
const MUZZLE := Vector3(.388, -.60, .626)
# The GLB's neutral arm points down-right and toward the camera.
const BARREL_AXIS := Vector3(.434, -.641, .633)
const DURABILITY := 3
enum Phase { PATROL, CHARGE, SECOND_SHOT, RELOAD, BROKEN }

var target: CharacterBody3D
var phase := Phase.PATROL
var age := 0.0
var hitstop := 0.0
var hits := 0
var rail_speed := 0.0
var patrol_direction := 1.0
var model: Node3D
var carriage: MeshInstance3D
var barrel: MeshInstance3D
var materials: Array[ShaderMaterial] = []
var hurtbox: CollisionShape3D
var glow: MeshInstance3D
var glow_paint: ShaderMaterial
var sound: AudioStreamPlayer3D
var destruction: EnemyBurst
var shot_group: Node3D
var sight := PhysicsRayQueryParameters3D.new()

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	model = MODEL.instantiate()
	add_child(model)
	carriage = model.find_child("RailCarriage", true, false)
	barrel = model.find_child("RailBarrel", true, false)
	_paint(carriage)
	_paint(barrel)
	hurtbox = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.14, 1.08, 1.04)
	hurtbox.shape = box
	hurtbox.position = Vector3(0, -1.54, .57)
	add_child(hurtbox)
	var quad := QuadMesh.new()
	quad.size = Vector2(.58, .52)
	glow_paint = ShaderMaterial.new()
	glow_paint.shader = preload("res://shaders/lab_halo.gdshader")
	glow_paint.set_shader_parameter("light_color", Color("9ee5ff"))
	glow = MeshInstance3D.new()
	glow.mesh = quad
	glow.material_override = glow_paint
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.top_level = true
	add_child(glow)
	sound = AudioStreamPlayer3D.new()
	sound.max_distance = 15.0
	add_child(sound)
	shot_group = Node3D.new()
	add_child(shot_group)
	destruction = EnemyBurst.new()
	destruction.ember_color = Color("ffa160")
	add_child(destruction)
	sight.collision_mask = 1
	reset()

func _paint(part: MeshInstance3D) -> void:
	var original := part.get_active_material(0) as StandardMaterial3D
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://shaders/miko8_three_tone.gdshader")
	paint.set_shader_parameter("base_texture", original.albedo_texture)
	paint.set_shader_parameter("shadow_tone", Vector3(.59, .61, .65))
	paint.set_shader_parameter("middle_tone", Vector3(.87, .90, .94))
	paint.set_shader_parameter("light_tone", Vector3(1.13, 1.16, 1.20))
	paint.set_shader_parameter("warm_paint_tint", Vector3(.82, .87, .92))
	part.set_surface_override_material(0, paint)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	materials.append(paint)

func reset() -> void:
	position = HOME
	_enter(Phase.PATROL)
	hitstop = 0.0
	hits = 0
	rail_speed = 0.0
	patrol_direction = 1.0
	barrel.quaternion = Quaternion.IDENTITY
	model.show()
	glow.hide()
	sound.stop()
	hurtbox.set_deferred("disabled", false)
	destruction.reset()
	for bolt in shot_group.get_children():
		bolt.set_physics_process(false)
		bolt.queue_free()

func _physics_process(delta: float) -> void:
	if phase == Phase.BROKEN:
		return
	hitstop = maxf(0.0, hitstop - delta)
	for paint in materials:
		paint.set_shader_parameter("droid_warning", hitstop * 3.0)
	if hitstop > 0.0:
		return
	age += delta
	var has_target: bool = is_instance_valid(target) and target.health > 0 and not target.automation
	var nearby := has_target and absf(target.position.x - position.x) < NOTICE_RANGE
	var speed_goal := 0.0
	if phase in [Phase.PATROL, Phase.RELOAD]:
		if position.x <= LEFT_LIMIT + .05:
			patrol_direction = 1.0
		elif position.x >= RIGHT_LIMIT - .05:
			patrol_direction = -1.0
		if nearby:
			var offset := target.position.x - position.x
			var follow_distance := 2.6 if target.velocity.x >= 0.0 else -2.6
			speed_goal = clampf((offset - follow_distance) * 1.8, -SPEED, SPEED)
		else:
			speed_goal = patrol_direction * 2.0
	rail_speed = move_toward(rail_speed, speed_goal, delta * 11.0)
	position.x = clampf(position.x + rail_speed * delta, LEFT_LIMIT, RIGHT_LIMIT)
	_aim(delta, nearby)
	var can_fire := phase != Phase.RELOAD and nearby and absf(target.position.x - position.x) < FIRE_RANGE and _has_sight()
	match phase:
		Phase.PATROL:
			if can_fire:
				_enter(Phase.CHARGE)
				_play(CHARGE_AUDIO, 1.48, -18.0)
		Phase.CHARGE:
			if not can_fire:
				_enter(Phase.RELOAD)
			elif age >= WINDUP:
				_fire()
				_enter(Phase.SECOND_SHOT)
		Phase.SECOND_SHOT:
			if age >= FOLLOW_UP:
				if can_fire:
					_fire()
				_enter(Phase.RELOAD)
		Phase.RELOAD:
			if age >= RELOAD:
				_enter(Phase.PATROL)
	glow.visible = phase == Phase.CHARGE or phase == Phase.SECOND_SHOT
	if glow.visible:
		glow.global_position = _muzzle() + Vector3.BACK * .017
		var energy := lerpf(.21, 1.20, smoothstep(0.0, WINDUP, age)) if phase == Phase.CHARGE else .76 * exp(-age * 12.0)
		glow_paint.set_shader_parameter("energy", energy)

func _aim(delta: float, nearby: bool) -> void:
	var heading := BARREL_AXIS
	if nearby:
		var delta_to_target := _aim_point() - barrel.global_position
		delta_to_target.x = clampf(delta_to_target.x, -4.75, 4.75)
		heading = delta_to_target.normalized()
	var rotation := Quaternion(BARREL_AXIS.normalized(), heading.normalized())
	barrel.quaternion = barrel.quaternion.slerp(rotation, 1.0 - exp(-delta * 13.0)).normalized()

func _aim_point() -> Vector3:
	var travel := _muzzle().distance_to(target.global_position + Vector3.UP) / BOLT_SPEED
	var lead := clampf(target.velocity.x * travel * .73, -1.9, 1.9)
	return target.global_position + Vector3(lead, .89, 0.0)

func _muzzle() -> Vector3:
	return barrel.to_global(MUZZLE)

func _has_sight() -> bool:
	sight.from = _muzzle()
	sight.to = target.global_position + Vector3.UP
	return get_world_3d().direct_space_state.intersect_ray(sight).is_empty()

func _fire() -> void:
	var origin := _muzzle()
	var bolt := Bolt.new()
	bolt.top_level = true
	bolt.speed = BOLT_SPEED
	shot_group.add_child(bolt)
	bolt.launch(origin, origin.direction_to(_aim_point()), global_position)
	_play(FIRE_AUDIO, 1.12, -11.0)

func _enter(next: Phase) -> void:
	phase = next
	age = 0.0

func _play(stream: AudioStream, pitch: float, volume: float) -> void:
	sound.stream = stream
	sound.pitch_scale = pitch
	sound.volume_db = volume
	sound.play()

func get_hit_point() -> Vector3:
	return hurtbox.global_position

func receive_hit(_damage: int, direction: int, _lift: float) -> void:
	if phase == Phase.BROKEN:
		return
	hits += 1
	if hits < DURABILITY:
		hitstop = .07
		_enter(Phase.RELOAD)
		glow.hide()
		return
	_enter(Phase.BROKEN)
	hurtbox.set_deferred("disabled", true)
	glow.hide()
	sound.stop()
	destruction.explode(get_hit_point(), 0.0, direction, [carriage, barrel])
	model.hide()
