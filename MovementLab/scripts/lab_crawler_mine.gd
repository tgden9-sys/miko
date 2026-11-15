extends Node3D

const Kit := preload("res://scripts/lab_art_kit.gd")
const FALL_TIME := .36
const ARM_TIME := .18
const FUSE := .40
const LIVE_TIME := 2.8
const DETECTION_RANGE := 1.47
const BLAST_RANGE := 1.66
enum Stage { STOWED, FALLING, ARMING, LIVE, FUSE_LIT, BURST }

var target: CharacterBody3D
var stage := Stage.STOWED
var age := 0.0
var socket: Vector3
var deck: Vector3
var casing: Node3D
var spill: ShaderMaterial
var burst: MeshInstance3D
var burst_paint: ShaderMaterial
var speaker: AudioStreamPlayer3D
var ping: AudioStream
var crack: AudioStream

func _ready() -> void:
	top_level = true
	casing = Node3D.new()
	add_child(casing)
	var kit := Kit.new(casing)
	kit.cylinder(Vector3(0, .045, 0), Vector3(.39, .087, .39), Color("302d2d"))
	kit.cylinder(Vector3(0, .091, 0), Vector3(.285, .045, .285), Color("7a582b"))
	kit.cylinder(Vector3(0, .118, 0), Vector3(.164, .036, .164), Color("bb4526"), Vector3.ZERO, true)
	kit.plate(Vector3(0, .044, .165), Vector3(.19, .076, .094), Color("4d4640"))
	kit.plate(Vector3(0, .044, -.165), Vector3(.19, .076, .094), Color("4d4640"))
	kit.finish()
	spill = ShaderMaterial.new()
	spill.shader = preload("res://shaders/lab_halo.gdshader")
	spill.set_shader_parameter("light_color", Color("ff702b"))
	kit.quad(Vector3(0, .015, 0), Vector2(BLAST_RANGE * 2.0, 1.05), spill, Vector3(-PI * .5, 0, 0))
	burst_paint = ShaderMaterial.new()
	burst_paint.shader = preload("res://shaders/ground_impact.gdshader")
	burst_paint.set_shader_parameter("metal_landing", true)
	var quad := QuadMesh.new()
	quad.size = Vector2(3.6, 1.18)
	burst = MeshInstance3D.new()
	burst.mesh = quad
	burst.position = Vector3(0, quad.size.y * .4, .45)
	burst.material_override = burst_paint
	burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(burst)
	speaker = AudioStreamPlayer3D.new()
	speaker.max_distance = 14.0
	add_child(speaker)
	ping = AudioStreamOggVorbis.load_from_file("res://audio/impactMetal_heavy_001.ogg")
	crack = AudioStreamOggVorbis.load_from_file("res://audio/impact_heavy.ogg")
	reset()

func is_live() -> bool:
	return stage != Stage.STOWED

func reset() -> void:
	stage = Stage.STOWED
	age = 0.0
	hide()
	set_physics_process(false)
	speaker.stop()

func release(from: Vector3, landing: Vector3) -> void:
	socket = from
	deck = landing
	global_position = socket
	_enter(Stage.FALLING)
	casing.rotation.z = 0.0
	casing.show()
	burst.hide()
	spill.set_shader_parameter("energy", 0.0)
	show()
	set_physics_process(true)

func _enter(next: Stage) -> void:
	stage = next
	age = 0.0

func _physics_process(delta: float) -> void:
	age += delta
	match stage:
		Stage.FALLING:
			var progress := minf(age / FALL_TIME, 1.0)
			global_position = socket.lerp(deck, progress)
			global_position.y += 1.45 * progress * (1.0 - progress)
			casing.rotation.z = -signf(deck.x - socket.x) * TAU * progress
			if progress >= 1.0:
				_enter(Stage.ARMING)
				_play(ping, 1.5, -18.0)
		Stage.ARMING:
			if age >= ARM_TIME:
				_enter(Stage.LIVE)
		Stage.LIVE:
			spill.set_shader_parameter("energy", .19 + .11 * sin(age * 8.0))
			if _within(DETECTION_RANGE, .55) or age >= LIVE_TIME:
				_enter(Stage.FUSE_LIT)
				_play(ping, 2.0, -13.0)
		Stage.FUSE_LIT:
			spill.set_shader_parameter("energy", .43 + .63 * pow(.5 + .5 * sin(age * 51.0), 2.0))
			if age >= FUSE:
				_detonate()
		Stage.BURST:
			burst_paint.set_shader_parameter("age", age)
			spill.set_shader_parameter("energy", maxf(0.0, 1.0 - age * 7.0))
			if age >= .44:
				reset()

func _within(radius: float, height: float) -> bool:
	return is_instance_valid(target) and target.health > 0 \
		and absf(target.global_position.x - global_position.x) < radius \
		and absf(target.global_position.y - global_position.y) < height

func _detonate() -> void:
	_enter(Stage.BURST)
	casing.hide()
	burst_paint.set_shader_parameter("age", 0.0)
	burst.show()
	_play(crack, 1.05, -7.5)
	if _within(BLAST_RANGE, .67):
		target.receive_attack(global_position.x)

func _play(stream: AudioStream, pitch: float, volume: float) -> void:
	speaker.stream = stream
	speaker.pitch_scale = pitch
	speaker.volume_db = volume
	speaker.play()
