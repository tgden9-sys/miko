extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	if img != null:
		var err := img.save_png("res://" + name + ".png")
		print("SAVED_SHOWCASE_FRAME: ", name, " err=", err)
	else:
		print("WARN: img is null for ", name)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_test() -> void:
	print("STARTING_LASER_SUBTLETY_AND_FRICTION_TEST")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")

	# Settle physics for 25 frames
	for i in range(25):
		await physics_frame

	# -------------------------------------------------------------
	# TEST 1: Open Air / Searching State vs Lock-on Surge
	# -------------------------------------------------------------
	print("TEST 1: VERIFYING SEARCHING LASER SUBTLETY...")
	# Aim upwards into open air (away from crates)
	robot.aim_angle_degrees = 55.0
	for i in range(25):
		_key(KEY_Q, true) # Raise left arm (Red laser)
		await physics_frame

	print("SEARCHING STATE (AIMING INTO SKY):")
	print("  beam_width: ", robot.beam.width)
	print("  beam_core_vis: ", robot.beam_core.visible if robot.beam_core else "none")
	print("  lock_intensity: ", robot.lock_intensity)
	print("  muzzle_energy: ", robot.muzzle_light.energy if robot.muzzle_light else "none")
	var reticle_light = robot.plasma_reticle.get_node_or_null("ReticleLight")
	print("  reticle_light_enabled: ", reticle_light.enabled if reticle_light else "none")

	assert(robot.lock_intensity <= 0.15, "Searching laser in open air must have near-zero lock intensity!")
	assert(robot.beam.width <= 1.5, "Searching laser must be a razor-thin guide wire (<= 1.5px)!")
	assert(robot.beam_core == null or not robot.beam_core.visible, "Hot white core must be hidden during search!")
	assert(reticle_light == null or not reticle_light.enabled, "Reticle point light must be OFF in search standby!")
	await _save("subtle_01_searching_laser_thin")

	# Now aim slightly down (-5.5 deg) directly at CrateGround1 on the floor
	robot.aim_angle_degrees = -5.5
	robot.current_beam_length = 500.0
	for i in range(25):
		_key(KEY_Q, true)
		await physics_frame

	print("LOCKED-ON STATE (AIMING DIRECTLY AT CRATE):")
	print("  beam_width: ", robot.beam.width)
	print("  beam_core_vis: ", robot.beam_core.visible if robot.beam_core else "none")
	print("  lock_intensity: ", robot.lock_intensity)
	print("  is_locked_on: ", robot.locked_target != null)
	print("  muzzle_energy: ", robot.muzzle_light.energy if robot.muzzle_light else "none")
	print("  reticle_light_enabled: ", reticle_light.enabled if reticle_light else "none")

	assert(robot.lock_intensity >= 0.85, "Laser locked onto crate must surge to high lock intensity!")
	assert(robot.beam.width >= 3.8, "Locked laser beam must widen into full power!")
	assert(robot.beam_core != null and robot.beam_core.visible, "Hot white core must flare when locked!")
	assert(reticle_light != null and reticle_light.enabled, "Reticle point light must flare when locked!")
	await _save("subtle_02_locked_on_laser_surge")
	_key(KEY_Q, false)
	for i in range(15):
		await physics_frame

	# -------------------------------------------------------------
	# TEST 2: Crate Magnetism Range (280px) & Field Extent
	# -------------------------------------------------------------
	print("TEST 2: VERIFYING EXTENDED RANGE & SUBTLE FIELD...")
	var crates_node = scene.get_node("Crates")
	var crate_g1 = crates_node.get_node("CrateGround1")
	assert(crate_g1.MAGNET_RANGE >= 280.0, "Crate MAGNET_RANGE must be at least 280px!")

	# Polarize CrateGround1 to RED
	crate_g1.lock_in_color(Color(1.0, 0.2, 0.25))
	assert(crate_g1.polarity == crate_g1.Polarity.RED, "Crate must be polarized to RED!")

	# Place a dynamic test crate 220px to the right of CrateGround1 on the floor
	var crate_scene = load("res://scenes/crate.tscn")
	var crate2 = crate_scene.instantiate()
	crate2.position = crate_g1.position + Vector2(220.0, 0.0)
	crates_node.add_child(crate2)
	for i in range(5):
		await physics_frame

	# Polarize crate2 to BLUE (Opposite polarity -> Attraction with friction)
	crate2.lock_in_color(Color(0.2, 0.75, 1.0))
	assert(crate2.polarity == crate2.Polarity.BLUE, "Crate 2 must be polarized to BLUE!")

	await _save("subtle_03_magnetic_field_extent_and_flux")

	# -------------------------------------------------------------
	# TEST 3: Friction & Distance-Based Acceleration Physics
	# -------------------------------------------------------------
	print("TEST 3: VERIFYING FRICTION & ACCELERATION (START SLOW -> SURGE CLOSE)...")
	var speeds_c1: Array[float] = []
	var speeds_c2: Array[float] = []
	var distances: Array[float] = []

	for step in range(45):
		await physics_frame
		var d = crate_g1.global_position.distance_to(crate2.global_position)
		distances.append(d)
		speeds_c1.append(abs(crate_g1.velocity.x))
		speeds_c2.append(abs(crate2.velocity.x))

	print("MAGNETIC MOTION PROGRESSION:")
	print("  Early Frame (step 5):  dist=", distances[5], " speed_c1=", speeds_c1[5], " speed_c2=", speeds_c2[5])
	print("  Mid Frame (step 20):   dist=", distances[20], " speed_c1=", speeds_c1[20], " speed_c2=", speeds_c2[20])
	print("  Late Frame (step 35):  dist=", distances[35], " speed_c1=", speeds_c1[35], " speed_c2=", speeds_c2[35])

	# Physics assertions:
	# 1. Objects start slowly due to static friction
	assert(speeds_c1[3] < 120.0 and speeds_c2[3] < 120.0, "Crates must start slowly overcoming static friction!")
	# 2. Objects pick up speed as they get moving and closer
	assert(speeds_c1[25] > speeds_c1[3] or speeds_c2[25] > speeds_c2[3], "Crates must accelerate as distance decreases!")
	# 3. Crates draw together into latching proximity
	assert(distances[-1] < distances[0], "Crates must close the distance toward each other!")

	await _save("subtle_04_crates_latched_after_acceleration")

	print("ALL_LASER_SUBTLETY_AND_FRICTION_TESTS_PASSED_SUCCESSFULLY")
	quit(0)
