extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png("res://" + name + ".png")
	print("SAVED_TEST_FRAME: ", name)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _mouse_move(dx: float, dy: float) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = Vector2(dx, dy)
	Input.parse_input_event(event)

func _run_test() -> void:
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")
	
	for i in range(25):
		await physics_frame
	
	# TEST 1: RED LASER (Left Arm) Turn
	print("--- TEST 1: RED LASER TURN ---")
	_key(KEY_Q, true)
	for i in range(25):
		await physics_frame
	print("RED INITIAL: facing=", robot.visual_facing, " beam_len=", robot.current_beam_length)
	await _save("test_red_facing_right")
	
	# Shrink beam past the robot to the left
	_mouse_move(-80.0, 0.0)
	for i in range(10):
		await physics_frame
	print("RED AFTER MOUSE LEFT: facing=", robot.visual_facing, " beam_len=", robot.current_beam_length)
	await _save("test_red_turned_left")
	
	# Grow beam more to the left
	_mouse_move(-40.0, 0.0)
	for i in range(10):
		await physics_frame
	print("RED EXTENDED LEFT: facing=", robot.visual_facing, " beam_len=", robot.current_beam_length)
	await _save("test_red_extended_left")
	_key(KEY_Q, false)
	
	for i in range(30):
		await physics_frame
		
	# TEST 2: BLUE LASER (Right Arm) Turn
	print("--- TEST 2: BLUE LASER TURN ---")
	# First face right again
	robot.visual_facing = 1
	robot.facing = 1
	for i in range(10):
		await physics_frame
		
	_key(KEY_E, true)
	for i in range(25):
		await physics_frame
	print("BLUE INITIAL: facing=", robot.visual_facing, " beam_len=", robot.current_beam_length)
	await _save("test_blue_facing_right")
	
	# Shrink beam past robot to the left
	_mouse_move(-80.0, 0.0)
	for i in range(10):
		await physics_frame
	print("BLUE AFTER MOUSE LEFT: facing=", robot.visual_facing, " beam_len=", robot.current_beam_length)
	await _save("test_blue_turned_left")
	_key(KEY_E, false)
	
	print("AIM_TURN_TESTS_COMPLETED_SUCCESSFULLY")
	quit(0)
