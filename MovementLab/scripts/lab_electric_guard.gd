extends Node3D

const CLASH := preload("res://audio/laser_clash.wav")
const PROJECTILE_LAYER := 8
const PROJECTILE_GROUP := &"miko_electric_guard"

var actor: CharacterBody3D
var field: MeshInstance3D
var paint: ShaderMaterial
var audio: AudioStreamPlayer3D
var raised := false
var strength := 0.0
var hit_age := 1.0
var bolt_shape: CollisionShape3D
var blocks_bolts := false

func _ready() -> void:
	name = "ElectricShield"
	paint = ShaderMaterial.new()
	paint.shader = preload("res://shaders/lab_electric_guard.gdshader")
	var surface := QuadMesh.new()
	surface.size = Vector2(1.24, 2.11)
	field = MeshInstance3D.new()
	field.mesh = surface
	field.material_override = paint
	field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(field)
	var interception := Area3D.new()
	interception.collision_layer = PROJECTILE_LAYER
	interception.collision_mask = 0
	interception.monitoring = false
	interception.add_to_group(PROJECTILE_GROUP)
	add_child(interception)
	bolt_shape = CollisionShape3D.new()
	var plate := BoxShape3D.new()
	plate.size = Vector3(.16, 1.39, .72)
	bolt_shape.shape = plate
	bolt_shape.disabled = true
	interception.add_child(bolt_shape)
	audio = AudioStreamPlayer3D.new()
	audio.stream = CLASH
	audio.volume_db = -13.0
	add_child(audio)
	reset()

func reset() -> void:
	raised = false
	strength = 0.0
	hit_age = 1.0
	paint.set_shader_parameter("strength", 0.0)
	audio.stop()
	_set_bolt_interception(false)
	hide()
	set_process(false)

func set_guard(active: bool, facing: int, cells: int) -> void:
	raised = active
	_set_bolt_interception(active)
	if active:
		position = Vector3(facing * .82, .99, .36)
		bolt_shape.position = Vector3(facing * .29, 0.0, -.36)
		paint.set_shader_parameter("direction_sign", float(facing))
		paint.set_shader_parameter("cells", float(cells))
		show()
		set_process(true)

func _set_bolt_interception(active: bool) -> void:
	if active != blocks_bolts:
		blocks_bolts = active
		bolt_shape.set_deferred("disabled", not active)

func intercept_bolt(from_x: float, contact: Vector3) -> bool:
	return blocks_bolts and actor._absorb_with_shield(from_x, contact)

func absorb(cells_left: int, contact: Vector3) -> void:
	hit_age = 0.0
	strength = 1.0
	raised = cells_left > 0
	paint.set_shader_parameter("cells", float(cells_left))
	var impact_height := clampf((contact.y - global_position.y) / .88, -.78, .78) if contact.is_finite() else 0.0
	paint.set_shader_parameter("impact_height", impact_height)
	audio.pitch_scale = .91 if cells_left == 0 else 1.08 + .08 * cells_left
	audio.play()

func _process(delta: float) -> void:
	hit_age += delta
	strength = move_toward(strength, 1.0 if raised else 0.0, delta * (10.0 if raised else 4.0))
	paint.set_shader_parameter("strength", strength)
	paint.set_shader_parameter("hit_age", hit_age)
	if not raised and strength <= 0:
		hide()
		set_process(false)
