extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png("res://" + name + ".png")
	print("SAVED_ATTACHMENT_FRAME: ", name)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_test() -> void:
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")
	
	for i in range(25):
		await physics_frame
	
	# 1. Aim Red (Left Arm shooting, Right Arm resting at side)
	_key(KEY_Q, true)
	for i in range(25):
		await physics_frame
	print("RED AIMING: ArmL_pivot=", robot.arm_l_pivot.position, " ArmR_pivot=", robot.arm_r_pivot.position)
	print("ArmL visible=", robot.arm_l.visible, " ArmR visible=", robot.arm_r.visible)
	await _save("arm_attach_red_aim_right")
	_key(KEY_Q, false)
	
	for i in range(25):
		await physics_frame
		
	# 2. Aim Blue (Right Arm shooting, Left Arm resting at side)
	_key(KEY_E, true)
	for i in range(25):
		await physics_frame
	print("BLUE AIMING: ArmL_pivot=", robot.arm_l_pivot.position, " ArmR_pivot=", robot.arm_r_pivot.position)
	print("ArmL visible=", robot.arm_l.visible, " ArmR visible=", robot.arm_r.visible)
	await _save("arm_attach_blue_aim_right")
	_key(KEY_E, false)
	
	print("ATTACHMENT_TEST_FINISHED")
	quit(0)
