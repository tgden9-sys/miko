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
	print("STARTING_JUMP_SPARKS_AND_VISIBLE_FIELDS_TEST")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")

	# Settle physics for 30 frames
	for i in range(30):
		await physics_frame

	# -------------------------------------------------------------
	# TEST 1: Inspect Pre-Polarized Crates & Magnetic Fields
	# -------------------------------------------------------------
	print("TEST 1: VERIFYING PRE-POLARIZED CRATES & VISIBLE MAGNETIC FIELDS...")
	var crates_node = scene.get_node("Crates")
	var crate_ground1 = crates_node.get_node("CrateGround1")
	var crate_stack_base = crates_node.get_node("CrateStackBase")
	var crate_stack_top = crates_node.get_node("CrateStackTop")
	var crate_upper_left = crates_node.get_node("CrateUpperLeft")

	print("CrateGround1 polarity: ", crate_ground1.polarity)
	print("CrateStackBase polarity: ", crate_stack_base.polarity)
	print("CrateStackTop polarity: ", crate_stack_top.polarity)
	print("CrateUpperLeft polarity: ", crate_upper_left.polarity)

	assert(crate_ground1.polarity == 1, "CrateGround1 should be Red (polarity 1)!")
	assert(crate_upper_left.polarity == 2, "CrateUpperLeft should be Blue (polarity 2)!")
	assert(crate_stack_base.polarity == 1, "CrateStackBase should be Red (polarity 1)!")
	assert(crate_stack_top.polarity == 2, "CrateStackTop should be Blue (polarity 2)!")

	# Let field orbital chevrons and pulse waves animate for 20 frames
	for i in range(20):
		await physics_frame

	await _save("field_01_visible_fields")

	# -------------------------------------------------------------
	# TEST 2: Jump Ignition & Blast Sparks
	# -------------------------------------------------------------
	print("TEST 2: TRIGGERING JUMP & VERIFYING BLAST SPARKS...")
	assert(robot.thruster_blast != null, "robot.thruster_blast must not be null!")
	assert(robot.thruster_trail != null, "robot.thruster_trail must not be null!")
	assert(robot.landing_dust != null, "robot.landing_dust must not be null!")

	# Press jump (Space)
	_key(KEY_SPACE, true)
	await physics_frame
	await physics_frame

	print("JUMP TAKEOFF STATE:")
	print("  velocity.y: ", robot.velocity.y)
	print("  is_jumping: ", robot.is_jumping)
	print("  thruster_blast.emitting: ", robot.thruster_blast.emitting)
	print("  thruster_light energy: ", robot.thruster_light.energy if robot.thruster_light else "none")

	assert(robot.velocity.y < -300.0, "Robot must have strong upward jump velocity!")
	assert(robot.thruster_blast.emitting, "ThrusterBlast particles MUST be emitting on takeoff!")
	await _save("field_02_jump_sparks")

	# Ascend through air, verify thruster trail
	for i in range(12):
		await physics_frame

	print("JUMP ASCENSION STATE:")
	print("  velocity.y: ", robot.velocity.y)
	print("  thruster_trail.emitting: ", robot.thruster_trail.emitting)
	assert(robot.thruster_trail.emitting, "ThrusterTrail particles MUST be emitting during ascent!")

	# Release jump key to allow gravity descent
	_key(KEY_SPACE, false)
	
	# Wait for descent and landing impact
	var landed: bool = false
	for i in range(70):
		await physics_frame
		if robot.is_on_floor():
			landed = true
			break

	print("LANDING IMPACT STATE:")
	print("  landed on floor: ", landed)
	print("  landing_dust.emitting: ", robot.landing_dust.emitting)
	assert(landed, "Robot must land on floor!")
	assert(robot.landing_dust.emitting, "LandingDust particles MUST be emitting on landing impact!")
	await _save("field_03_landing_dust")

	# -------------------------------------------------------------
	# TEST 3: Balanced Laser vs Target
	# -------------------------------------------------------------
	print("TEST 3: VERIFYING BALANCED LASER CONTRAST...")
	robot.aim_angle_degrees = -5.5
	robot.current_beam_length = 500.0
	for i in range(25):
		_key(KEY_Q, true)
		await physics_frame
	_key(KEY_Q, false)

	print("CONNECTED LASER STATE:")
	print("  beam_width: ", robot.beam.width)
	print("  beam_glow_width: ", robot.beam_glow.width if robot.beam_glow else "none")
	print("  lock_intensity: ", robot.lock_intensity)
	print("  is_locked: ", crate_ground1.is_locked_on)

	assert(robot.lock_intensity >= 0.85, "Lock intensity should be high when targeted!")
	assert(robot.beam.width <= 3.0, "Connected beam width must be balanced (<= 3.0px)!")
	await _save("field_04_laser_balance")

	print("ALL_JUMP_SPARKS_AND_VISIBLE_FIELDS_TESTS_PASSED_SUCCESSFULLY!")
	quit(0)
