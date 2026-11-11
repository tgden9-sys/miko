extends SceneTree

func _initialize() -> void:
	call_deferred("_run_captures")

func _save(filename: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	var path: String = "res://" + filename + ".png"
	var err: Error = img.save_png(path)
	print("SAVED_SCREENSHOT ", filename, " (err=", err, ")")

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_captures() -> void:
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")
	
	# Frame 1: Initial idle pose on ground platform
	for i in range(30):
		await physics_frame
	await _save("city_scene_overview")
	
	# Frame 2: Run right towards center, demonstrating parallax camera scroll
	_key(KEY_D, true)
	for i in range(50):
		await physics_frame
	_key(KEY_D, false)
	for i in range(15):
		await physics_frame
	await _save("city_scene_mid_run")
	
	# Frame 3: Aim red laser towards the upper structures
	_key(KEY_Q, true)
	for i in range(30):
		await physics_frame
	await _save("city_scene_aiming")
	_key(KEY_Q, false)
	
	print("ALL_CAPTURES_COMPLETED")
	quit(0)
