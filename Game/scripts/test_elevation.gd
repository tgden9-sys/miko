extends SceneTree

func _initialize() -> void:
	call_deferred("_run_elevation_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png("res://" + name + ".png")
	print("SAVED_ELEVATION_FRAME: ", name)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_elevation_test() -> void:
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")
	
	# Hold KEY_Q down
	_key(KEY_Q, true)
	for i in range(30):
		await physics_frame
	
	print("AIM RAISED: progress=", robot.aim_l_progress)
	
	# 1. Aim Horizontal (0 deg)
	robot.aim_angle_degrees = 0.0
	for i in range(5):
		await physics_frame
	print("ARM PIVOT AT 0 DEG: ", robot.arm_l_pivot.rotation)
	await _save("test_aim_horizontal_0deg")
	
	# 2. Aim High Diagonal (+60 deg)
	robot.aim_angle_degrees = 60.0
	for i in range(5):
		await physics_frame
	print("ARM PIVOT AT +60 DEG: ", robot.arm_l_pivot.rotation)
	await _save("test_aim_up_60deg")
	
	# 3. Aim Straight Up (+88 deg)
	robot.aim_angle_degrees = 88.0
	for i in range(5):
		await physics_frame
	print("ARM PIVOT AT +88 DEG: ", robot.arm_l_pivot.rotation)
	await _save("test_aim_straight_up_88deg")
	
	# 4. Aim Downward (-60 deg)
	robot.aim_angle_degrees = -60.0
	for i in range(5):
		await physics_frame
	print("ARM PIVOT AT -60 DEG: ", robot.arm_l_pivot.rotation)
	await _save("test_aim_down_60deg")
	
	# 5. Aim Straight Down (-88 deg)
	robot.aim_angle_degrees = -88.0
	for i in range(5):
		await physics_frame
	print("ARM PIVOT AT -88 DEG: ", robot.arm_l_pivot.rotation)
	await _save("test_aim_straight_down_88deg")
	
	_key(KEY_Q, false)
	print("ELEVATION_TEST_COMPLETE")
	quit(0)
