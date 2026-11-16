extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String, detail: Variant = null) -> void:
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		print("FAIL: ", message, " | Detail: ", detail)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	print("--- STARTING CRATES AND DROID VERIFICATION ---")

	# =========================================================
	# 1. VERIFY LEVEL 1 WOODEN CRATES IN LAB CUTAWAY
	# =========================================================
	var cutaway = load("res://lab_cutaway.tscn").instantiate()
	root.add_child(cutaway)
	current_scene = cutaway
	await frames(5)

	var actor = cutaway.actor
	actor.automation = true

	check(cutaway.wooden_crates.size() == 5, "Level 1 cutaway spawns exactly 5 wooden crates", cutaway.wooden_crates.size())

	# Verify dimensions and placement
	var base_crates := 0
	var stacked_crates := 0
	var max_y := 0.0
	for crate in cutaway.wooden_crates:
		check(crate != null and is_instance_valid(crate), "Crate instance is valid")
		check(crate.has_method("receive_hit"), "Crate implements receive_hit")
		check(crate.CRATE_WIDTH == 0.8 and crate.CRATE_HEIGHT == 0.8 and crate.CRATE_DEPTH == 0.8, "Crate dimensions are 0.8m x 0.8m x 0.8m")
		if crate.position.y < 0.1:
			base_crates += 1
		else:
			stacked_crates += 1
		max_y = maxf(max_y, crate.position.y + crate.CRATE_HEIGHT)

	check(base_crates == 2, "2 base crates on the floor (x=14.0 and x=14.8)", base_crates)
	check(stacked_crates == 3, "3 stacked crates forming the barricade", stacked_crates)
	check(max_y >= 3.2, "Barricade height reaches at least 3.2m, blocking corridor under 4.5m ceiling", max_y)

	# Verify smashing crates with sword
	var first_crate = cutaway.wooden_crates[0]
	check(not first_crate.broken, "First crate starts unbroken")
	first_crate.receive_hit(25, 1, 0.0)
	await frames(3)
	check(first_crate.broken, "First crate is broken after receiving sword hit")

	# Verify reset_room restores crates
	cutaway.reset_room()
	await frames(2)
	check(not first_crate.broken, "First crate is restored unbroken on reset_room()")

	# Clean up cutaway scene
	cutaway.queue_free()
	await frames(5)

	# =========================================================
	# 2. VERIFY AGILE DROID PERSISTENCE & STEP JUMP ATTACK (L2)
	# =========================================================
	var lab_run = load("res://lab_run.tscn").instantiate()
	root.add_child(lab_run)
	current_scene = lab_run
	await frames(10)

	var run_actor = lab_run.actor
	run_actor.automation = true

	# Test droid step jumping and jump attack
	var test_droid = preload("res://scripts/agile_droid.gd").new()
	test_droid.name = "TestDroid"
	test_droid.actor = run_actor
	test_droid.model_scene = lab_run.course_target_model
	test_droid.position = Vector3(20.0, 6.0, 0.0)
	test_droid.home = Vector3(20.0, 6.0, 0.0)
	lab_run.add_child(test_droid)
	await frames(5)

	# Position Miko up a step facing the droid (e.g. at x=22.0, y=7.2m — 1.2m higher)
	run_actor.position = Vector3(22.0, 7.2, 0.0)
	run_actor.velocity = Vector3.ZERO
	test_droid.position = Vector3(20.0, 6.0, 0.0)
	test_droid.velocity = Vector3.ZERO
	test_droid.mode = test_droid.Mode.APPROACH
	test_droid.facing = 1
	test_droid.jump_cooldown = 0.0
	test_droid.attack_cooldown = 0.0

	check(test_droid._sees_miko(), "Droid sees Miko up on the step (1.2m higher)")

	# Run a few physics frames to allow droid to leap up to attack
	var jumped_up := false
	var entered_windup := false
	for f in range(25):
		await physics_frame
		if test_droid.velocity.y > 4.0:
			jumped_up = true
		if test_droid.mode == test_droid.Mode.WINDUP or test_droid.mode == test_droid.Mode.SWIPE:
			entered_windup = true

	check(jumped_up, "Droid jumps upward when facing Miko up on a step", test_droid.velocity.y)
	check(entered_windup, "Droid initiates attack (jump-attack) towards Miko on the step", test_droid.mode)

	# =========================================================
	# 3. VERIFY AGILE DROID PERSISTENCE & DESCENT LEDGE DROP (L5)
	# =========================================================
	# Position droid on higher ledge and Miko below down the shaft
	test_droid.position = Vector3(73.0, 9.0, 0.0)
	test_droid.velocity = Vector3.ZERO
	test_droid.mode = test_droid.Mode.APPROACH
	test_droid.facing = -1
	test_droid.jump_cooldown = 0.0
	run_actor.position = Vector3(67.8, 6.0, 0.0) # DescentMiddle landing (3.0m below)

	check(test_droid._sees_miko(), "Droid sees Miko 3.0m down the descent shaft")
	check(test_droid.persistence_timer >= 0.0, "Droid persistence timer is initialized")

	# Move Miko temporarily behind wall / out of sight
	test_droid.persistence_timer = 3.5
	run_actor.position = Vector3(67.8, 0.0, 0.0) # 9m down
	test_droid._physics_process(0.1)
	check(test_droid.mode == test_droid.Mode.APPROACH, "Droid remains persistent in Mode.APPROACH even with Miko dropping down", test_droid.mode)
	check(test_droid.persistence_timer > 3.0, "Persistence timer keeps droid chasing instead of retreating to patrol", test_droid.persistence_timer)

	# Test ledge drop detection
	test_droid.position = Vector3(65.5, 9.0, 0.0) # at the edge of the landing
	test_droid.facing = -1
	var should_drop = test_droid._should_jump_down_ledge()
	check(should_drop, "Droid detects ledge drop ahead when Miko is below")

	lab_run.queue_free()
	await frames(5)

	print("--- VERIFICATION COMPLETE: %d failures ---" % failures)
	quit(1 if failures > 0 else 0)
