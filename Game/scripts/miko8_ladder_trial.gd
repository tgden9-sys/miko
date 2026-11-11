extends Node3D
var rig: Skeleton3D
var data: Dictionary
var clock := 0.0
var playing := true
var quarter := true
var camera: Camera3D
var subject: Node3D
var indices: Dictionary = {}
var head: SkeletonModifier3D
var label: Label
func _ready() -> void:
	DisplayServer.window_set_title("MIKO — VanillaLoop ladder trial")
	data = JSON.parse_string(FileAccess.get_file_as_string("res://models/miko8/VanillaLoop_Ladder_Trial.json"))
	subject = load("res://models/miko8/MIKO8_Native.glb").instantiate()
	add_child(subject)
	rig = subject.find_children("*", "Skeleton3D", true, false)[0]
	var player: AnimationPlayer = subject.find_children("*", "AnimationPlayer", true, false)[0]
	player.stop()
	player.active = false
	for bone: String in data.frames[0]: indices[bone] = rig.find_bone(bone)
	head = preload("res://scripts/miko8_head_offset.gd").new()
	rig.add_child(head)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("15202b")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 0.7
	env.environment = e
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-35,0)
	light.light_energy = 1.6
	add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.6
	add_child(camera)
	for x in [-0.24,0.24]: _box(Vector3(x,1.65,0.44),Vector3(0.045,4,0.045),Color("71818a"))
	for i in range(-2,16): _box(Vector3(0,i*float(data.rise)*0.5,0.44),Vector3(0.52,0.035,0.04),Color("93a3a8"))
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := VBoxContainer.new()
	panel.position = Vector2(18,16)
	ui.add_child(panel)
	label = Label.new()
	label.text = "MIKO · stock VanillaLoop ladder loop\nSource timing · no ladder IK · global head lift 30°"
	panel.add_child(label)
	var pause := Button.new()
	pause.text = "Pause / resume"
	pause.pressed.connect(func(): playing = not playing)
	panel.add_child(pause)
	var view := Button.new()
	view.text = "Front / side view"
	view.pressed.connect(func(): quarter = not quarter)
	panel.add_child(view)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.001
	slider.custom_minimum_size.x = 250
	slider.value_changed.connect(func(v: float): playing = false; clock = v*float(data.duration))
	panel.add_child(slider)
	_apply(0.0)
	print("VANILLALOOP_TRIAL_READY duration=",data.duration," bones=",indices.size())
func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material
	add_child(instance)
func _process(delta: float) -> void:
	if playing: clock += delta
	_apply(fposmod(clock,float(data.duration))/float(data.duration))
func _apply(phase: float) -> void:
	var f: float = phase*(data.frames.size()-1)
	var a: Dictionary = data.frames[int(f)]
	var b: Dictionary = data.frames[mini(int(f)+1,data.frames.size()-1)]
	for bone: String in indices:
		var index: int = indices[bone]
		if index < 0: continue
		var pa: Array = a[bone].p
		var pb: Array = b[bone].p
		var qa: Array = a[bone].q
		var qb: Array = b[bone].q
		rig.set_bone_pose_position(index,Vector3(pa[0],pa[1],pa[2]).lerp(Vector3(pb[0],pb[1],pb[2]),f-floorf(f)))
		rig.set_bone_pose_rotation(index,Quaternion(qa[0],qa[1],qa[2],qa[3]).slerp(Quaternion(qb[0],qb[1],qb[2],qb[3]),f-floorf(f)))
	subject.position.y = phase*float(data.rise)
	camera.position = Vector3(2.8,1.35+subject.position.y,3.4) if quarter else Vector3(3.8,1.2+subject.position.y,0.0)
	camera.look_at(Vector3(0,0.95+subject.position.y,0))

