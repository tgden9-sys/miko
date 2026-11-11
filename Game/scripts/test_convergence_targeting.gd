extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	if img != null:
		var err := img.save_png("res://" + name + ".png")
		print("SAVED_CONVERGENCE_FRAME: ", name, " err=", err)
	else:
		print("WARN: img is null for ", name)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_test() -> void:
	print("STARTING_CONVERGENCE_TARGETING_TEST")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")

	# Settle robot on catwalk
	for i in range(25):
		await physics_frame

	# Spawn new 2D metal crate in front of robot at +260px
	var crate_scene = load("res://scenes/crate.tscn")
	var crate = crate_scene.instantiate()
	crate.position = robot.global_position + Vector2(260, 0)
	crate.set_physics_process(false)
	scene.add_child(crate)
	await physics_frame

	print("CRATE INITIAL STATE: polarity=", crate.polarity, " texture=", crate.sprite.texture.resource_path)
	assert("crate_neutral.png" in crate.sprite.texture.resource_path or "crate.png" in crate.sprite.texture.resource_path, "Crate should use 2D metal texture")

	# --- TEST 1: Hold F -> Dual Convergence Laser & Violet Holographic Reticle ---
	# Set slight downward aim elevation to point right at the crate center
	robot.aim_angle_degrees = -3.5
	for i in range(20):
		_key(KEY_F, true)
		await physics_frame

	print("PLASMA AIMING: progress=", robot.plasma_progress, 
		" beam_l_vis=", robot.beam.visible, " beam_r_vis=", robot.beam_r.visible if robot.beam_r else false,
		" reticle_vis=", robot.plasma_reticle.visible if robot.plasma_reticle else false,
		" reticle_pos=", robot.plasma_reticle.position if robot.plasma_reticle else Vector2.ZERO,
		" reticle_locked=", robot.plasma_reticle.is_locked_on if robot.plasma_reticle else false,
		" crate_locked=", crate.is_locked_on)

	assert(robot.beam.visible, "Left beam must be visible during plasma aim")
	assert(robot.beam_r != null and robot.beam_r.visible, "Right beam must be visible for dual convergence")
	assert(robot.plasma_reticle != null and robot.plasma_reticle.visible, "Plasma reticle must be visible at convergence point")
	assert(crate.is_locked_on, "Crate should detect lock-on from convergence beam")

	await _save("convergence_01_targeting_crate")

	# --- TEST 2: Crate Polarity Visuals (Red and Blue Artwork) ---
	print("TESTING CRATE RED POLARITY...")
	crate.lock_in_color(Color(1.0, 0.2, 0.25))
	for i in range(5):
		await physics_frame
	print("CRATE RED: polarity=", crate.polarity, " texture=", crate.sprite.texture.resource_path)
	assert("crate_red.png" in crate.sprite.texture.resource_path, "Crate texture should switch to crate_red.png")
	await _save("convergence_02_crate_red")

	print("TESTING CRATE BLUE POLARITY...")
	crate.lock_in_color(Color(0.2, 0.7, 1.0))
	for i in range(5):
		await physics_frame
	print("CRATE BLUE: polarity=", crate.polarity, " texture=", crate.sprite.texture.resource_path)
	assert("crate_blue.png" in crate.sprite.texture.resource_path, "Crate texture should switch to crate_blue.png")
	await _save("convergence_03_crate_blue")

	# Re-lock onto blue crate
	for i in range(10):
		_key(KEY_F, true)
		await physics_frame

	# --- TEST 3: Release F -> Launch Plasma Bolt into Reticle ---
	_key(KEY_F, false) # Release to fire!
	await physics_frame
	print("PLASMA RELEASE: fired=", robot.plasma_fired)

	# Capture bolt in flight towards crate
	for i in range(3):
		await physics_frame
	await _save("convergence_04_plasma_release")

	# --- TEST 4: Post-Impact & No Lingering Purple Hue on Mica ---
	# Wait for plasma to impact crate and for flash timer (0.14s = ~9 frames) to expire
	for i in range(30):
		await physics_frame

	print("POST-FIRE CHECK: muzzle_enabled=", robot.muzzle_light.enabled, 
		" muzzle_energy=", robot.muzzle_light.energy,
		" flash_timer=", robot.plasma_flash_timer)
	assert(not robot.muzzle_light.enabled or robot.muzzle_light.energy <= 0.05, "Muzzle light MUST be disabled after firing!")

	await _save("convergence_05_mica_clean_idle")

	print("ALL_CONVERGENCE_AND_POLARITY_TESTS_PASSED_SUCCESSFULLY")
	quit(0)
