extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	if img != null:
		var err := img.save_png("res://" + name + ".png")
		print("SAVED_POLISH_FRAME: ", name, " err=", err)
	else:
		print("WARN: img is null for ", name)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_test() -> void:
	print("STARTING_LASER_PLASMA_POLISH_TEST")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")

	# Settle robot on ground
	for i in range(25):
		await physics_frame

	# --- TEST 1: LED Wrist Accents while Idle ---
	print("WRIST LED TEST: L_pos=", robot.wrist_pos_l, " R_pos=", robot.wrist_pos_r)
	print("L_energy=", robot.wrist_led_l.energy, " R_energy=", robot.wrist_led_r.energy)
	await _save("polish_01_idle_leds")

	# --- TEST 2: Searching Laser (Collimated & Faint) ---
	_key(KEY_Q, true) # Aim Red Laser into open air
	for i in range(25):
		await physics_frame
	
	print("SEARCHING LASER: lock_intensity=", robot.lock_intensity, 
		" beam_w=", robot.beam.width, " glow_w=", robot.beam_glow.width,
		" core_alpha=", robot.beam_core.default_color.a)
	await _save("polish_02_searching_laser")

	# --- TEST 3: Lock-On Laser Surge ---
	_key(KEY_Q, true)
	
	# Spawn a magnetic crate directly in front of the hand nozzle and freeze in place
	var crate_scene = load("res://scenes/crate.tscn")
	var crate = crate_scene.instantiate()
	crate.position = robot.global_position + Vector2(75, 0)
	crate.set_physics_process(false)
	scene.add_child(crate)
	
	robot.aim_angle_degrees = -14.0
	for i in range(25):
		_key(KEY_Q, true)
		await physics_frame

	print("LOCKED LASER SURGE: lock_intensity=", robot.lock_intensity,
		" beam_w=", robot.beam.width, " glow_w=", robot.beam_glow.width,
		" sparks_emitting=", robot.sparkles.emitting, " sparks_dir=", robot.sparkles.direction)
	await _save("polish_03_locked_laser_surge")
	_key(KEY_Q, false)

	# Clean up test crate from laser test
	crate.queue_free()
	for i in range(15):
		await physics_frame

	# Reset elevation to level horizontal aim for plasma shot
	robot.aim_angle_degrees = 0.0

	# Spawn target crate down catwalk at +320px
	var target_crate = crate_scene.instantiate()
	target_crate.position = robot.global_position + Vector2(320, 0)
	target_crate.set_physics_process(false)
	scene.add_child(target_crate)
	await physics_frame

	# --- TEST 4: High-Energy Plasma Bolt Launch & Flight ---
	# Press F until plasma spawns
	var plasma = null
	for i in range(30):
		_key(KEY_F, true)
		await physics_frame
		for child in scene.get_children():
			if "PlasmaProjectile" in child.name and not child.is_queued_for_deletion():
				plasma = child
				break
		if plasma != null:
			break
	_key(KEY_F, false)

	print("PLASMA BOLT SPAWNED: ", plasma != null)
	if plasma != null:
		print("Plasma initial pos=", plasma.position, " vel=", plasma.velocity)
	
	# Advance 2 frames for visible clearance from hands
	for i in range(2):
		await physics_frame
	await _save("polish_04_plasma_flight")

	# Advance 7 frames to capture plasma bolt mid-flight streak
	for i in range(7):
		await physics_frame
	if plasma != null:
		print("Plasma midflight pos=", plasma.position, " vel=", plasma.velocity)
	await _save("polish_05_plasma_streak")

	# Advance 10 frames until plasma impacts the crate at +320px
	for i in range(10):
		await physics_frame

	if plasma != null:
		print("PLASMA DETONATED: detonated=", plasma.detonated, " radius=", plasma.shockwave_radius)
	await _save("polish_06_plasma_detonation")

	# Clean up target crate
	target_crate.queue_free()
	for i in range(10):
		await physics_frame

	# --- TEST 5: Turn-Then-Move (No backward sliding) ---
	_key(KEY_A, true) # Turn to left
	await physics_frame
	print("TURN START: turning=", robot.turning, " vx=", robot.velocity.x, " facing=", robot.visual_facing)
	assert(robot.velocity.x > -200.0, "Robot should decelerate during initial turn instead of instantly speeding backward!")
	
	for i in range(14):
		await physics_frame
		if i == 6:
			print("TURN MIDPOINT (Frame 6): turning=", robot.turning, " vx=", robot.velocity.x, " facing=", robot.visual_facing)
			assert(absf(robot.velocity.x) < 50.0, "Velocity should remain near zero while turning!")
			await _save("polish_07_clean_turn")
		elif i == 13:
			print("TURN COMPLETED (Frame 13): turning=", robot.turning, " vx=", robot.velocity.x, " facing=", robot.visual_facing)
	
	_key(KEY_A, false)
	for i in range(20):
		await physics_frame

	print("ALL_POLISH_TESTS_COMPLETED_SUCCESSFULLY")
	quit(0)
