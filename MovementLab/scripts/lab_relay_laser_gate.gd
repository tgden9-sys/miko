extends Node3D

const Kit := preload("res://scripts/lab_art_kit.gd")
const HEIGHT := 5.5
const LOWER_LENS := .25
const UPPER_LENS := HEIGHT-.28
var metal_tint := Color.WHITE
var barrier: CollisionShape3D
var beam: MeshInstance3D
var paint: ShaderMaterial
var signal_lamps: ShaderMaterial
var lens_glow: ShaderMaterial
var spill: ShaderMaterial
var fade: Tween
var wants_power := true
var powered := true
var beam_power := 1.0

func _ready() -> void:
	var blocker := StaticBody3D.new()
	add_child(blocker)
	barrier = CollisionShape3D.new()
	var volume := BoxShape3D.new()
	volume.size = Vector3(.19,HEIGHT,4)
	barrier.shape = volume
	barrier.position.y = HEIGHT*.5
	blocker.add_child(barrier)

	paint = ShaderMaterial.new()
	paint.shader = preload("res://shaders/lab_relay_laser.gdshader")
	var quad := QuadMesh.new()
	quad.size = Vector2(1.36,UPPER_LENS-LOWER_LENS)
	beam = MeshInstance3D.new()
	beam.mesh = quad
	beam.position = Vector3(0,(UPPER_LENS+LOWER_LENS)*.5,.38)
	beam.material_override = paint
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)
	signal_lamps = ShaderMaterial.new()
	signal_lamps.shader = preload("res://shaders/lab_service_lamp.gdshader")
	signal_lamps.set_shader_parameter("tint",Color("ff4865"))
	var kit := Kit.new(self,Kit.bulkhead_paint())
	lens_glow = _make_glow(Color("ff426c"),.66)
	spill = _make_glow(Color("ff2149"),.32)
	kit.quad(Vector3(0,.012,-.02),Vector2(2.6,2.1),spill,Vector3(-PI*.5,0,0))
	kit.quad(Vector3(0,HEIGHT-.012,-.02),Vector2(2.5,2.1),spill,Vector3(PI*.5,0,0))
	for side: float in [-1.0,1.0]:
		var y := .14 if side > 0 else HEIGHT-.16
		kit.plate(Vector3(0,y,.24),Vector3(.69,.28,.66),Color("33434a")*metal_tint)
		kit.plate(Vector3(0,y,.591),Vector3(.53,.18,.065),Color("172328")*metal_tint)
		kit.cylinder(Vector3(0,y+side*.096,.38),Vector3(.32,.105,.32),Color("677479")*metal_tint)
		kit.cylinder(Vector3(0,y+side*.148,.38),Vector3(.19,.025,.19),Color("1a2428")*metal_tint)
		for x: float in [-.26,.26]:
			kit.cylinder(Vector3(x,y,.632),Vector3(.055,.024,.055),Color("85918a"),Vector3(PI*.5,0,0))
		kit.quad(Vector3(0,y,.634),Vector2(.24,.032),signal_lamps)
		var lens_y := LOWER_LENS if side > 0 else UPPER_LENS
		kit.quad(Vector3(0,lens_y,.439),Vector2(.72,.54),lens_glow)
	kit.finish()

func _make_glow(tint: Color, energy: float) -> ShaderMaterial:
	var glow := ShaderMaterial.new()
	glow.shader = preload("res://shaders/lab_halo.gdshader")
	glow.set_shader_parameter("light_color",tint)
	glow.set_shader_parameter("energy",energy)
	glow.set_shader_parameter("flicker",.14)
	return glow

func set_powered(enabled: bool) -> void:
	wants_power = enabled
	if not enabled:
		_apply_power(false)

func _physics_process(_delta: float) -> void:
	if not wants_power or powered:
		return
	var miko: Node3D = get_parent().actor
	if not is_instance_valid(miko) or absf(miko.global_position.x-global_position.x) > .48:
		_apply_power(true)

func _apply_power(enabled: bool) -> void:
	if enabled == powered:
		return
	powered = enabled
	barrier.set_deferred("disabled",not enabled)
	signal_lamps.set_shader_parameter("tint",Color("ff4865") if enabled else Color("a8f6cc"))
	if fade:
		fade.kill()
	fade = create_tween()
	fade.tween_method(_set_beam_strength,beam_power,1.0 if enabled else 0.0,.14)

func _set_beam_strength(value: float) -> void:
	beam_power = value
	paint.set_shader_parameter("power",value)
	lens_glow.set_shader_parameter("energy",.66*value)
	spill.set_shader_parameter("energy",.32*value)
