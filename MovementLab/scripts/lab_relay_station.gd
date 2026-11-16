extends Node3D

const Kit := preload("res://scripts/lab_art_kit.gd")
const CORE := preload("res://models/props/lab_relay_core.glb")
const CLICK := preload("res://audio/impactMetal_heavy_001.ogg")
const SHUTTER_SOUND := preload("res://audio/impactPlate_heavy_000.ogg")
const PROGRESS := &"maintenance_relay_progress"
const SOCKET := Vector3(44.32, 8.55, -.74)
const DOCKED_CORE := SOCKET + Vector3(-.25, 0, .05)
enum State { CRADLED, HELD, INSTALLED }

var actor: CharacterBody3D
var shutter: Node3D
var pickup := Vector3(10.65,.56,-.75)
var core: Node3D
var status_lamp: ShaderMaterial
var sound: AudioStreamPlayer3D
var state := State.CRADLED
var age := 0.0

func _ready() -> void:
	if shutter:
		_build_adapter()
	else:
		_build_cradle()
	core = CORE.instantiate()
	add_child(core)
	core.position = pickup
	var halo := ShaderMaterial.new()
	halo.shader = preload("res://shaders/lab_halo.gdshader")
	halo.set_shader_parameter("light_color", Color("ffdc99"))
	halo.set_shader_parameter("energy", .24)
	Kit.new(core).quad(Vector3(0, -.01, .138), Vector2(.66, .17), halo)
	sound = AudioStreamPlayer3D.new()
	sound.max_distance = 13.0
	add_child(sound)
	state = get_tree().get_meta(PROGRESS, State.CRADLED)
	core.visible = not shutter and state == State.CRADLED
	if shutter and state == State.INSTALLED:
		core.position = DOCKED_CORE
		core.show()
		_power_socket(false)

func _physics_process(delta: float) -> void:
	if not shutter and state == State.CRADLED:
		age += delta
		core.position.y = pickup.y + sin(age * 2.8) * .025
		core.rotation.y = sin(age * 1.47) * .12
	if not is_instance_valid(actor) or actor.automation or actor.health <= 0:
		return
	if not shutter and state == State.CRADLED and _reachable(pickup, .67):
		_set_progress(State.HELD)
		core.hide()
		_play(CLICK, pickup, 1.75, -12.0)
	elif shutter and state == State.HELD and _reachable(SOCKET, 1.10):
		_insert_core()

func _reachable(at: Vector3, distance: float) -> bool:
	var offset := actor.global_position + Vector3.UP * .62 - at
	return absf(offset.x) < distance and absf(offset.y) < .44

func _set_progress(value: State) -> void:
	state = value
	get_tree().set_meta(PROGRESS, value)

func _insert_core() -> void:
	_set_progress(State.INSTALLED)
	core.position = DOCKED_CORE + Vector3(-.46, .06, .10)
	core.rotation.y = -.32
	core.show()
	var dock := create_tween().set_parallel(true)
	dock.tween_property(core, "position", DOCKED_CORE, .33).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	dock.tween_property(core, "rotation:y", 0.0, .29)
	dock.chain().tween_callback(func() -> void: _power_socket(true))

func _power_socket(animated: bool) -> void:
	status_lamp.set_shader_parameter("tint", Color("bbf3d5"))
	status_lamp.set_shader_parameter("lamp_power", 1.0)
	if animated:
		_play(CLICK, SOCKET, 1.31, -9.0)
		var lift := create_tween()
		lift.tween_interval(.16)
		lift.tween_callback(func() -> void:
			shutter.unlock_service_shutter(true)
			_play(SHUTTER_SOUND, shutter.global_position + Vector3.UP, .79, -13.0))
	else:
		shutter.unlock_service_shutter(false)

func _play(stream: AudioStream, at: Vector3, pitch: float, volume: float) -> void:
	sound.global_position = at
	sound.stream = stream
	sound.pitch_scale = pitch
	sound.volume_db = volume
	sound.play()

func _build_cradle() -> void:
	var kit := Kit.new(self, Kit.bulkhead_paint())
	var base := pickup - Vector3.UP * .56
	kit.plate(base + Vector3(0, .065, 0), Vector3(1.04, .13, .55), Color("3c4949"))
	kit.plate(base + Vector3(0, .20, -.06), Vector3(.70, .32, .37), Color("435254"))
	kit.box(base + Vector3(0, .382, 0), Vector3(.67, .05, .35), Color("182527"))
	for flank in [-1.0, 1.0]:
		kit.plate(base + Vector3(flank * .39, .425, -.02), Vector3(.16, .23, .43), Color("9b802f"))
	kit.finish()

func _build_adapter() -> void:
	var kit := Kit.new(self, Kit.bulkhead_paint())
	# A dark receiver behind a two-sided guide. Only the keyed end disappears.
	kit.plate(SOCKET + Vector3(.33, -.58, -.27), Vector3(.23, .93, .27), Color("364143"))
	kit.plate(SOCKET + Vector3(.33, -1.015, -.27), Vector3(.38, .07, .41), Color("3d4949"))
	kit.plate(SOCKET + Vector3(.02, 0, -.25), Vector3(1.25, .69, .28), Color("3d4848"))
	kit.box(SOCKET + Vector3(-.10, 0, -.09), Vector3(.91, .41, .095), Color("151d1e"))
	for side in [-1.0, 1.0]:
		kit.plate(SOCKET + Vector3(.045, side * .226, .012), Vector3(.69, .082, .30), Color("b18c30"))
	kit.plate(SOCKET + Vector3(.30, 0, .018), Vector3(.18, .42, .32), Color("596263"))
	kit.box(SOCKET + Vector3(.88, 0, -.245), Vector3(1.08, .075, .11), Color("172123"))
	kit.box(SOCKET + Vector3(.98, -.22, -.245), Vector3(.065, .43, .11), Color("263437"))
	kit.plate(SOCKET + Vector3(.21, .34, -.058), Vector3(.28, .09, .08), Color("283637"))
	status_lamp = ShaderMaterial.new()
	status_lamp.shader = preload("res://shaders/lab_service_lamp.gdshader")
	status_lamp.set_shader_parameter("tint", Color("d28c44"))
	status_lamp.set_shader_parameter("lamp_power", .63)
	kit.quad(SOCKET + Vector3(.21, .34, -.012), Vector2(.20, .035), status_lamp)
	kit.finish()

