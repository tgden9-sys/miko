extends CharacterBody3D

const Kit := preload("res://scripts/lab_art_kit.gd")
const Tracks := preload("res://scripts/lab_crawler_tracks.gd")
const Mine := preload("res://scripts/lab_crawler_mine.gd")
const EnemyBurst := preload("res://scripts/lab_enemy_burst.gd")
const SPEED := 2.65
const ACCELERATION := 16.0
const TURN_TIME := .34
const DROP_TIME := .65
const RELEASE_TIME := .34
const MINE_THROW_RANGE := 3.85
const MINE_MIN_X := 11.1
const MINE_MAX_X := 21.6
const DURABILITY := 2

var target: CharacterBody3D
var patrol_min := 15.4
var patrol_max := 20.35
var home: Vector3
var facing := -1.0
var turn_left := 0.0
var drop_age := -1.0
var cooldown := 0.0
var hits := 0
var hitstop := 0.0
var rig: Node3D
var tracks: Tracks
var chassis: MeshInstance3D
var hatch: MeshInstance3D
var hatch_lamp: ShaderMaterial
var paint: ShaderMaterial
var hurtbox: CollisionShape3D
var mine: Node3D
var audio: AudioStreamPlayer3D
var latch_sound: AudioStream
var destruction: EnemyBurst

func _ready() -> void:
	home = position
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = .18
	hurtbox = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.57, .83, .92)
	hurtbox.shape = box
	hurtbox.position.y = .43
	add_child(hurtbox)
	rig = (load("res://models/props/lab_mine_crawler.glb") as PackedScene).instantiate()
	add_child(rig)
	chassis = rig.find_child("CrawlerChassis", true, false) as MeshInstance3D
	hatch = rig.find_child("CrawlerHatch", true, false) as MeshInstance3D
	paint = ShaderMaterial.new()
	paint.shader = preload("res://shaders/miko8_three_tone.gdshader")
	for part in [chassis, hatch]:
		for surface in range(part.mesh.get_surface_count()):
			var baked := part.get_active_material(surface) as StandardMaterial3D
			if baked and baked.albedo_texture:
				paint.set_shader_parameter("base_texture", baked.albedo_texture)
				part.set_surface_override_material(surface, paint)
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	paint.set_shader_parameter("warm_paint_tint", Vector3(.54, .67, .86))
	paint.set_shader_parameter("shadow_tone", Vector3(.60, .62, .70))
	paint.set_shader_parameter("middle_tone", Vector3(.82, .87, .96))
	paint.set_shader_parameter("light_tone", Vector3(1.01, 1.05, 1.16))
	paint.set_shader_parameter("transition_width", .11)
	_build_hatch_lamp()
	var contact := ShaderMaterial.new()
	contact.shader = preload("res://shaders/lab_contact.gdshader")
	contact.set_shader_parameter("opacity", .54)
	var kit := Kit.new(rig)
	kit.quad(Vector3(0, .016, 0), Vector2(2.0, 1.34), contact, Vector3(-PI * .5, 0, 0))
	tracks = Tracks.new()
	rig.add_child(tracks)
	mine = Mine.new()
	mine.target = target
	add_child(mine)
	audio = AudioStreamPlayer3D.new()
	audio.max_distance = 12.0
	add_child(audio)
	latch_sound = AudioStreamOggVorbis.load_from_file("res://audio/impactPlate_heavy_000.ogg")
	destruction = EnemyBurst.new()
	destruction.ember_color = Color("ff7640")
	add_child(destruction)
	reset()

func _build_hatch_lamp() -> void:
	var kit := Kit.new(hatch)
	var lens := Vector3(.076, -.252, 0)
	var normal := Vector3(.96, .28, 0)
	var rotation := Vector3(0, 0, -.41 * PI)
	kit.cylinder(lens, Vector3(.108, .035, .108), Color("282229"), rotation)
	kit.cylinder(lens + normal * .023, Vector3(.066, .018, .066), Color("bf3d24"), rotation, true)
	kit.finish()
	hatch_lamp = ShaderMaterial.new()
	hatch_lamp.shader = preload("res://shaders/lab_halo.gdshader")
	hatch_lamp.set_shader_parameter("light_color", Color("ff5229"))
	kit.quad(lens + normal * .038, Vector2(.32, .30), hatch_lamp, Vector3(0, PI * .5, 0))

func reset() -> void:
	destruction.reset()
	position = home
	velocity = Vector3.ZERO
	facing = -1.0
	turn_left = 0.0
	drop_age = -1.0
	cooldown = 1.2
	hits = 0
	hitstop = 0.0
	rig.position = Vector3.ZERO
	rig.rotation = Vector3.ZERO
	rig.show()
	hatch.rotation.z = 0.0
	hatch_lamp.set_shader_parameter("energy", .12)
	paint.set_shader_parameter("droid_warning", 0.0)
	hurtbox.set_deferred("disabled", false)
	tracks.reset()
	mine.reset()
	audio.stop()

func _physics_process(delta: float) -> void:
	if hits >= DURABILITY:
		return
	hitstop = maxf(hitstop - delta, 0.0)
	paint.set_shader_parameter("droid_warning", hitstop * 5.1)
	if hitstop > 0.0:
		return
	cooldown = maxf(cooldown - delta, 0.0)
	if turn_left > 0.0:
		turn_left = maxf(0.0, turn_left - delta)
		rig.rotation.y = rotate_toward(rig.rotation.y, PI if facing > 0 else 0.0, PI * delta / TURN_TIME)
	elif drop_age >= 0.0:
		_update_drop(delta)
	elif (position.x <= patrol_min and facing < 0.0) or (position.x >= patrol_max and facing > 0.0):
		facing = -facing
		turn_left = TURN_TIME
	elif cooldown == 0.0 and not mine.is_live() and _target_nearby() and is_on_floor():
		_prime_mine()
	var goal_speed := 0.0 if drop_age >= 0.0 or turn_left > 0.0 else facing * SPEED
	velocity.x = move_toward(velocity.x, goal_speed, delta * ACCELERATION)
	velocity.y -= 24.0 * delta
	var before := position.x
	move_and_slide()
	tracks.roll((position.x - before) * cos(rig.rotation.y))

func _target_nearby() -> bool:
	return is_instance_valid(target) and target.health > 0 \
		and absf(target.position.y - position.y) < 1.1 and absf(target.position.x - position.x) < 5.7

func _predicted_target_x() -> float:
	return target.global_position.x + clampf(target.velocity.x * .42, -3.0, 3.0)

func _prime_mine() -> void:
	drop_age = 0.0
	_play(latch_sound, 1.45, -12.0)
	# Turn the hatch toward the player's approach before opening it.
	if (_predicted_target_x() - global_position.x) * facing > .25:
		facing = -facing
		turn_left = TURN_TIME

func _update_drop(delta: float) -> void:
	var previous := drop_age
	drop_age += delta
	hatch.rotation.z = 1.22 * smoothstep(.10, RELEASE_TIME, drop_age) * (1.0 - smoothstep(.41, DROP_TIME, drop_age))
	hatch_lamp.set_shader_parameter("energy", .22 + .62 * pow(.5 + .5 * sin(drop_age * 45.0), 2.0))
	if previous < RELEASE_TIME and drop_age >= RELEASE_TIME:
		var rear := rig.global_basis.x
		var socket := global_position + rear * .82 + Vector3.UP * .43
		var aim_x := _predicted_target_x() if _target_nearby() else global_position.x + rear.x * 1.6
		var reach := clampf((aim_x - global_position.x) * rear.x, 1.22, MINE_THROW_RANGE)
		var deck := global_position + rear * reach + Vector3.UP * .012
		deck.x = clampf(deck.x, MINE_MIN_X, MINE_MAX_X)
		mine.release(socket, deck)
		_play(latch_sound, .95, -10.0)
	if drop_age >= DROP_TIME:
		drop_age = -1.0
		cooldown = .95
		hatch_lamp.set_shader_parameter("energy", .12)

func _play(stream: AudioStream, pitch: float, volume: float) -> void:
	audio.stream = stream
	audio.pitch_scale = pitch
	audio.volume_db = volume
	audio.play()

func get_hit_point() -> Vector3:
	return global_position + Vector3.UP * .48

func receive_hit(_damage: int, direction: int, _lift: float) -> void:
	if hits >= DURABILITY:
		return
	hits += 1
	hitstop = .065
	if hits < DURABILITY:
		return
	hurtbox.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	audio.stop()
	paint.set_shader_parameter("droid_warning", 0.0)
	var parts: Array[MeshInstance3D] = [chassis, hatch]
	for axle in tracks.wheels:
		parts.append(axle.get_child(0) as MeshInstance3D)
	destruction.explode(global_position + Vector3.UP * .49, home.y - .035, direction, parts)
	rig.hide()
