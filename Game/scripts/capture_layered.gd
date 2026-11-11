extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func _save(name: String) -> void:
	await process_frame
	var img: Image = root.get_texture().get_image()
	var target := "res://" + name + ".png"
	var err := img.save_png(target)
	print("CAPTURE ", name, " ", img.get_size(), " ", err)

func _capture() -> void:
	var demo: Node = load("res://scenes/demo.tscn").instantiate()
	root.add_child(demo)
	var player: Node = demo.get_node("Robot")
	for i in range(45):
		await physics_frame
	_key(KEY_Q, true)
	for i in range(30):
		await physics_frame
	await _save("qa_right_red")
	_key(KEY_Q, false)
	for i in range(30):
		await physics_frame
	_key(KEY_A, true)
	for i in range(38):
		await physics_frame
	_key(KEY_A, false)
	player.position.x = 550.0 # Clear space for inspecting the left-facing arms.
	_key(KEY_Q, true)
	for i in range(30):
		await physics_frame
	print("QA left arm L/R z=",player.get_node("ArmLPivot").z_index,
		"/",player.get_node("ArmRPivot").z_index,
		" L scale=",player.get_node("ArmLPivot/ArmL").scale)
	await _save("qa_left_red")
	_key(KEY_Q, false)
	_key(KEY_E, true)
	for i in range(30):
		await physics_frame
	await _save("qa_left_blue")
	_key(KEY_E, false)
	quit(0)

