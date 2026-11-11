extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_test() -> void:
	print("STARTING_VARIABLE_JUMP_TEST")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")

	# Settle on floor
	for i in range(25):
		await physics_frame
	
	var floor_y: float = robot.global_position.y

	# Test 1: Full Jump (Hold Space)
	_key(KEY_SPACE, true)
	await physics_frame
	await physics_frame
	var min_y_full: float = floor_y
	while not robot.is_on_floor() or robot.velocity.y < 0.0:
		if robot.global_position.y < min_y_full:
			min_y_full = robot.global_position.y
		await physics_frame
	_key(KEY_SPACE, false)
	var full_jump_height: float = floor_y - min_y_full

	# Settle on floor
	for i in range(25):
		await physics_frame

	# Test 2: Short Hop (Tap Space for 3 frames then release)
	_key(KEY_SPACE, true)
	await physics_frame
	await physics_frame
	await physics_frame
	_key(KEY_SPACE, false)

	var min_y_short: float = floor_y
	while not robot.is_on_floor() or robot.velocity.y < 0.0:
		if robot.global_position.y < min_y_short:
			min_y_short = robot.global_position.y
		await physics_frame
	var short_jump_height: float = floor_y - min_y_short

	print("FULL_JUMP_HEIGHT: ", full_jump_height, " px")
	print("SHORT_JUMP_HEIGHT: ", short_jump_height, " px")
	print("RATIO: ", short_jump_height / full_jump_height)

	assert(short_jump_height < full_jump_height * 0.7, "Short jump should be significantly lower than full jump")
	print("VARIABLE_JUMP_TEST_PASSED_SUCCESSFULLY")
	quit(0)
