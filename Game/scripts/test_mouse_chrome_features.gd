extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	if img != null:
		var err := img.save_png("res://" + name + ".png")
		print("SAVED_CHROME_FRAME: ", name, " err=", err)
	else:
		print("WARN: img is null for ", name)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _mouse_button(button_index: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = pressed
	Input.parse_input_event(event)

func _mouse_motion(rel: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = rel
	Input.parse_input_event(event)
	root.push_input(event)

func _run_test() -> void:
	print("STARTING_MOUSE_CHROME_FEATURES_TEST")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")

	# Settle robot and crates on platforms
	for i in range(30):
		await physics_frame

	var crates: Array[Node] = get_nodes_in_group("crates")
	print("CRATES IN SCENE COUNT: ", crates.size())
	assert(crates.size() >= 7, "Industrial city level must have crates placed!")

	# --- TEST 1: Red Laser Aiming + Red Targeting Reticle + Full-Body Red Crate Glow ---
	for i in range(25):
		_key(KEY_Q, true)
		await physics_frame
	
	print("RED LASER AIMING: beam_vis=", robot.beam.visible, 
		" reticle_vis=", robot.plasma_reticle.visible if robot.plasma_reticle else false,
		" reticle_col=", robot.plasma_reticle.reticle_color if robot.plasma_reticle else Color.BLACK)
	assert(robot.beam.visible, "Red laser must be visible")
	assert(robot.plasma_reticle.visible, "Reticle must be visible for Red laser")
	assert(robot.plasma_reticle.reticle_color.r > 0.8, "Reticle color must be Red for Red laser")

	var crate_g1 = scene.get_node_or_null("Crates/CrateGround1")
	if crate_g1:
		print("CRATE_G1 TARGET CHECK: locked=", crate_g1.is_locked_on, " modulate=", crate_g1.sprite.modulate)
	
	await _save("chrome_01_red_laser_reticle_target")
	_key(KEY_Q, false)
	for i in range(15):
		await physics_frame

	# --- TEST 2: Blue Laser Aiming + Blue Targeting Reticle + Full-Body Blue Crate Glow ---
	for i in range(25):
		_key(KEY_E, true)
		await physics_frame

	print("BLUE LASER AIMING: beam_vis=", robot.beam.visible, 
		" reticle_vis=", robot.plasma_reticle.visible if robot.plasma_reticle else false,
		" reticle_col=", robot.plasma_reticle.reticle_color if robot.plasma_reticle else Color.BLACK)
	assert(robot.beam.visible, "Blue laser must be visible")
	assert(robot.plasma_reticle.visible, "Reticle must be visible for Blue laser")
	assert(robot.plasma_reticle.reticle_color.b > 0.8, "Reticle color must be Blue for Blue laser")
	
	await _save("chrome_02_blue_laser_reticle_target")
	_key(KEY_E, false)
	for i in range(15):
		await physics_frame

	# --- TEST 3: Mouse Pitch Motion Aiming Up/Down ---
	for i in range(20):
		_key(KEY_F, true) # Start plasma aim
		await physics_frame
	
	var initial_angle: float = robot.aim_angle_degrees
	print("MOUSE PITCH TEST - Initial Angle: ", initial_angle)

	# Move mouse UP (-Y relative delta)
	_mouse_motion(Vector2(0, -60.0))
	await physics_frame
	print("After Mouse UP delta: angle=", robot.aim_angle_degrees)
	assert(robot.aim_angle_degrees > initial_angle, "Mouse moving UP must increase aim elevation!")

	# Move mouse DOWN (+Y relative delta)
	_mouse_motion(Vector2(0, 100.0))
	await physics_frame
	print("After Mouse DOWN delta: angle=", robot.aim_angle_degrees)
	assert(robot.aim_angle_degrees < initial_angle, "Mouse moving DOWN must decrease aim elevation!")
	_key(KEY_F, false)
	for i in range(15):
		await physics_frame

	# --- TEST 4: Dual Mouse Buttons Together Trigger Plasma Stance & Fire ---
	print("TESTING DUAL MOUSE BUTTONS (LEFT + RIGHT TOGETHER)...")
	for i in range(25):
		_mouse_button(MOUSE_BUTTON_LEFT, true)
		_mouse_button(MOUSE_BUTTON_RIGHT, true)
		await physics_frame

	print("DUAL MOUSE AIMING: progress=", robot.plasma_progress, 
		" plasma_aiming=", robot.plasma_aiming,
		" dual_lasers=", robot.beam.visible and robot.beam_r.visible)
	assert(robot.plasma_aiming, "Both mouse buttons together must activate plasma aiming!")
	assert(robot.beam.visible and robot.beam_r.visible, "Both convergence lasers must be visible!")
	await _save("chrome_03_dual_mouse_plasma_convergence")

	# Release one mouse button -> Releases plasma bolt!
	_mouse_button(MOUSE_BUTTON_LEFT, false)
	await physics_frame
	print("RELEASED ONE MOUSE BUTTON -> Fired: ", robot.plasma_fired)
	_mouse_button(MOUSE_BUTTON_RIGHT, false)

	# Step frames to capture plasma bolt flight & city scene overview
	for i in range(6):
		await physics_frame
	await _save("chrome_04_city_crates_overview")

	for i in range(25):
		await physics_frame

	print("ALL_MOUSE_CHROME_FEATURES_TESTS_PASSED_SUCCESSFULLY")
	quit(0)
