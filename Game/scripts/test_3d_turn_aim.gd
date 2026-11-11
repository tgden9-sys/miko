extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png("res://" + name + ".png")
	print("SAVED_3D_TURN_FRAME: ", name)

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
	print("STARTING_3D_TURN_AIM_TEST")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")
	
	for i in range(25):
		await physics_frame
	
	# Start aiming right with Red Laser (KEY_Q)
	_key(KEY_Q, true)
	for i in range(25):
		await physics_frame
	
	print("AIM_RIGHT: facing=", robot.visual_facing, " beam=", robot.current_beam_length)
	await _save("turn_test_01_aim_right")
	
	# Move mouse left heavily to trigger turn
	_mouse_move(-80.0, 0.0)
	await physics_frame
	
	print("TURN TRIGGERED: turning=", robot.turning, " anim=", robot.sprite.animation)
	
	# Step through the 25 turn frames and capture snapshots
	for i in range(25):
		if i == 6:
			print("FRAME 6: anim=", robot.body_layer.animation, " frame=", robot.body_layer.frame, " pivot=", robot.arm_l_pivot.position)
			await _save("turn_test_02_quarter_turn")
		elif i == 12:
			print("FRAME 12 (APEX): anim=", robot.body_layer.animation, " frame=", robot.body_layer.frame, " facing=", robot.visual_facing, " pivot=", robot.arm_l_pivot.position)
			await _save("turn_test_03_front_apex")
		elif i == 18:
			print("FRAME 18: anim=", robot.body_layer.animation, " frame=", robot.body_layer.frame, " pivot=", robot.arm_l_pivot.position)
			await _save("turn_test_04_three_quarter")
		await physics_frame
	
	# After turn completed
	for i in range(10):
		await physics_frame
	
	print("TURN FINISHED: turning=", robot.turning, " facing=", robot.visual_facing)
	await _save("turn_test_05_completed_left")
	
	# Extend beam to the left
	_mouse_move(-50.0, 0.0)
	for i in range(10):
		await physics_frame
	print("AIMING LEFT EXTENDED: facing=", robot.visual_facing, " beam=", robot.current_beam_length)
	await _save("turn_test_06_extended_left")
	
	_key(KEY_Q, false)
	print("3D_TURN_AIM_TEST_SUCCESSFUL")
	quit(0)
