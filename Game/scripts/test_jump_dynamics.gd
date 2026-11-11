extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	if img != null:
		var err := img.save_png("res://" + name + ".png")
		print("SAVED_JUMP_FRAME: ", name, " err=", err)
	else:
		print("WARN: img is null for ", name)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_test() -> void:
	print("STARTING_JUMP_DYNAMICS_TEST_OPEN_AREA")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")
	var camera = scene.get_node("Camera2D")

	# Move robot to clear open catwalk area at x = 620.0
	robot.position.x = 620.0
	robot.position.y = 800.0

	# Settle robot on ground
	for i in range(30):
		await physics_frame

	print("INITIAL_GROUNDED: on_floor=", robot.is_on_floor(), " pos=", robot.global_position, " scale=", robot.sprite.scale)

	# 1. Trigger Jump
	_key(KEY_SPACE, true)
	await physics_frame
	await physics_frame
	print("LAUNCH_FRAME: vy=", robot.velocity.y, " squash=", robot.squash_stretch, " is_jumping=", robot.is_jumping, " camera_impulse=", camera.impulse_offset)
	await _save("jump_test_01_launch")

	# 2. Mid Ascent with Thruster Trail
	for i in range(10):
		await physics_frame
	print("ASCENT_FRAME: vy=", robot.velocity.y, " squash=", robot.squash_stretch, " thruster_trail=", robot.thruster_trail.emitting)
	await _save("jump_test_02_ascent")

	# 3. Apex Hang (wait until near peak vy approx 0)
	while robot.velocity.y < -35.0:
		await physics_frame

	print("APEX_FRAME: vy=", robot.velocity.y, " pos_y=", robot.global_position.y, " squash=", robot.squash_stretch)
	await _save("jump_test_03_apex")

	_key(KEY_SPACE, false)

	# 4. Fast Descent
	while robot.velocity.y < 280.0 and not robot.is_on_floor():
		await physics_frame

	print("DESCENT_FRAME: vy=", robot.velocity.y, " squash=", robot.squash_stretch)
	await _save("jump_test_04_descent")

	# 5. Landing Impact
	while not robot.is_on_floor():
		await physics_frame

	print("LANDING_FRAME: vy=", robot.velocity.y, " on_floor=", robot.is_on_floor(), " squash=", robot.squash_stretch, " camera_impulse=", camera.impulse_offset)
	await _save("jump_test_05_landing")

	# 6. Settle Recovery (spring recovery after 12 frames)
	for i in range(12):
		await physics_frame

	print("RECOVERY_FRAME: squash=", robot.squash_stretch, " scale=", robot.sprite.scale)
	await _save("jump_test_06_recovered")

	print("JUMP_DYNAMICS_TEST_SUCCESSFUL")
	quit(0)
