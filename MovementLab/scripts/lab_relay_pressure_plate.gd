extends Node3D

const Kit := preload("res://scripts/lab_art_kit.gd")
var laser: Node3D
var crate: RigidBody3D
var tread: Node3D
var indicator: ShaderMaterial
var activated := false
var travel: Tween
var click: AudioStreamPlayer3D

func _ready() -> void:
	var base := Kit.new(self,Kit.bulkhead_paint())
	base.box(Vector3(0,.020,0),Vector3(1.52,.04,1.38),Color("465458"))
	base.finish()
	tread = Node3D.new()
	add_child(tread)
	var kit := Kit.new(tread,Kit.bulkhead_paint())
	kit.box(Vector3(0,.071,0),Vector3(1.33,.066,1.18),Color("667678"))
	for index in 5:
		kit.box(Vector3((index-2)*.21,.111,0),Vector3(.056,.014,.85),Color("263539"))
	indicator = ShaderMaterial.new()
	indicator.shader = preload("res://shaders/lab_service_lamp.gdshader")
	indicator.set_shader_parameter("tint",Color("f4b269"))
	kit.quad(Vector3(0,.071,.602),Vector2(.62,.035),indicator)
	kit.finish()
	click = AudioStreamPlayer3D.new()
	click.stream = preload("res://audio/impactMetal_heavy_001.ogg")
	click.volume_db = -12.0
	add_child(click)

func _physics_process(_delta: float) -> void:
	var offset := crate.global_position-global_position
	var bottom: float = offset.y-crate.crate_size.y*.5
	var seated := absf(offset.x) <= (.43 if activated else .32) and absf(offset.z) < .24 and absf(bottom) < .09
	if seated == activated:
		return
	activated = seated
	indicator.set_shader_parameter("tint",Color("a8f6cc") if seated else Color("f4b269"))
	if travel:
		travel.kill()
	travel = create_tween()
	travel.tween_property(tread,"position:y",-.046 if seated else 0.0,.12)
	if seated:
		click.play()
	laser.set_powered(not seated)
