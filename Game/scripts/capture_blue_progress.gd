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
	var image: Image = root.get_texture().get_image()
	print("CAPTURE ", name, " ", image.save_png("res://" + name + ".png"))

func _capture() -> void:
	var demo: Node = load("res://scenes/demo.tscn").instantiate()
	root.add_child(demo)
	var player: Node = demo.get_node("Robot")
	for i in range(45):
		await physics_frame
	_key(KEY_A, true)
	for i in range(38):
		await physics_frame
	_key(KEY_A, false)
	player.position.x = 550.0
	for i in range(20):
		await physics_frame
	_key(KEY_E, true)
	while player.aim_r_progress < 3.0 / 11.0:
		await physics_frame
	print("PROGRESS 3 ", player.aim_r_progress)
	await _save("qa_blue_03")
	while player.aim_r_progress < 6.0 / 11.0:
		await physics_frame
	print("PROGRESS 6 ", player.aim_r_progress)
	await _save("qa_blue_06")
	while player.aim_r_progress < 0.999:
		await physics_frame
	print("PROGRESS 11 ", player.aim_r_progress)
	await _save("qa_blue_11")
	_key(KEY_E, false)
	quit(0)
