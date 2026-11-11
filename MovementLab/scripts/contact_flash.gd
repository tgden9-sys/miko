extends MeshInstance3D

var age := 0.0
var duration := 0.14
var heavy := false
var direction := 1
var paint: ShaderMaterial

func _ready() -> void:
	var quad := QuadMesh.new()
	var flash_size: float = 2.0 if heavy else 1.4
	quad.size = Vector2(flash_size, flash_size)
	mesh = quad
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	paint = ShaderMaterial.new()
	paint.shader = preload("res://shaders/contact_flash.gdshader")
	var color := Vector3(0.95, 0.85, 0.65) if heavy else Vector3(0.88, 0.92, 0.96)
	paint.set_shader_parameter("flash_color", color)
	material_override = paint

func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		queue_free()
		return
	if paint:
		paint.set_shader_parameter("progress", clampf(age / duration, 0.0, 1.0))
