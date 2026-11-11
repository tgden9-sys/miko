extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	if img != null:
		var err := img.save_png("res://" + name + ".png")
		print("SAVED_FRAME: ", name, " err=", err)

func _run_test() -> void:
	print("STARTING_CLEAN_200PX_CREEP_AND_SURGE_TEST")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)

	var crates_node = scene.get_node("Crates")
	# Neutralize all existing crates except the two test crates
	for c in crates_node.get_children():
		c.polarity = 0 # Neutral (BROWN)
		# Move unneeded crates far away off-screen
		if c.name != "CrateGround1" and c.name != "CrateStackBase":
			c.global_position = Vector2(-2000, -2000)

	var crate_red = crates_node.get_node("CrateGround1")
	var crate_blue = crates_node.get_node("CrateStackBase")
	crate_red.polarity = 1 # Red
	crate_blue.polarity = 2 # Blue

	# -------------------------------------------------------------
	# CASE 1: Distance = 450 px (> 400 px, Circles DO NOT overlap)
	# -------------------------------------------------------------
	crate_red.global_position = Vector2(400, 856)
	crate_blue.global_position = Vector2(850, 856) # 850 - 400 = 450 px
	crate_red.velocity = Vector2.ZERO
	crate_blue.velocity = Vector2.ZERO

	for i in range(15):
		await physics_frame

	var dist1: float = crate_red.global_position.distance_to(crate_blue.global_position)
	print("CASE 1 (DIST = ", dist1, " > 400 px):")
	print("  red vel.x: ", crate_red.velocity.x, " | blue vel.x: ", crate_blue.velocity.x)
	assert(dist1 > 400.0, "Distance must be > 400 px!")
	assert(absf(crate_red.velocity.x) < 0.1, "No attraction outside 400 px!")
	assert(absf(crate_blue.velocity.x) < 0.1, "No attraction outside 400 px!")
	await _save("creep_01_outside_circles")

	# -------------------------------------------------------------
	# CASE 2: Distance = 350 px (Overlapping by 50 px, like in user image!)
	# -------------------------------------------------------------
	crate_red.global_position = Vector2(400, 856)
	crate_blue.global_position = Vector2(750, 856) # 750 - 400 = 350 px
	crate_red.velocity = Vector2.ZERO
	crate_blue.velocity = Vector2.ZERO

	print("CASE 2 (DIST = 350 px, SLOW CREEP TO SURGE):")
	
	# Observe first 25 frames (slow creep phase)
	for i in range(25):
		await physics_frame
		if i % 5 == 0:
			var d: float = crate_red.global_position.distance_to(crate_blue.global_position)
			print("  Frame ", i, " - dist: ", d, " | red vel: ", crate_red.velocity.x, " | blue vel: ", crate_blue.velocity.x)

	var speed_creep: float = absf(crate_red.velocity.x)
	print("AFTER 25 FRAMES CREEP SPEED: ", speed_creep)
	assert(speed_creep >= 2.0 and speed_creep <= 35.0, "Must be creeping slowly at outer overlap!")
	await _save("creep_02_slow_creep_in_motion")

	# Run until mutual physical latch
	var latched: bool = false
	for i in range(160):
		await physics_frame
		var cur_d: float = crate_red.global_position.distance_to(crate_blue.global_position)
		if cur_d <= 48.0:
			latched = true
			print("  LATCHED AT FRAME ", i + 25, " | final dist: ", cur_d)
			break

	assert(latched, "Crates must accelerate and latch together!")
	await _save("creep_03_accelerated_latch")

	print("ALL_CREEP_AND_SURGE_TESTS_PASSED_SUCCESSFULLY!")
	quit(0)
