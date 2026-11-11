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
	print("STARTING_GROUND_CREEP_TEST")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)

	var crates_node = scene.get_node("Crates")
	# Temporarily hide or move the default crates so only our two test crates interact
	for c in crates_node.get_children():
		c.global_position = Vector2(-2000, -2000)

	var crate_blue = crates_node.get_node("CrateUpperRight2") # Blue (polarity 2)
	var crate_red = crates_node.get_node("CrateUpperRight1") # Red (polarity 1)

	# Position them exactly where the user had them on the ground platform (Y = 856)
	# User image had Blue on left, Red on right, separated by ~350 px
	crate_blue.global_position = Vector2(1050, 856)
	crate_red.global_position = Vector2(1400, 856) # 1400 - 1050 = 350 px (Mutual overlap 50 px)
	crate_blue.velocity = Vector2.ZERO
	crate_red.velocity = Vector2.ZERO

	# Move player safely away so player doesn't push crates
	var player = scene.get_node("Robot")
	player.global_position = Vector2(500, 856)

	# Camera framed exactly on the two crates and the background elevator column
	var camera = scene.get_node("Camera2D")
	camera.target = null
	camera.global_position = Vector2(1225, 780)

	print("INITIAL DISTANCE = 350 px (Overlap = 50 px, Single Field = 200 px, Overlap Range = 400 px):")
	var latched: bool = false
	for i in range(260):
		await process_frame
		var cur_d: float = crate_blue.global_position.distance_to(crate_red.global_position)
		if i % 20 == 0 or i < 15:
			print("  Frame ", i, " - dist: ", cur_d, " | blue vel: ", crate_blue.velocity.x, " | red vel: ", crate_red.velocity.x)
		if i == 15:
			await _save("ground_creep_01_slow")
		if cur_d <= 74.0:
			latched = true
			print("  LATCHED AT FRAME ", i, " | final dist: ", cur_d)
			for _k in range(8):
				await process_frame
			break

	assert(latched, "Crates must accelerate and latch together!")
	await _save("ground_creep_02_latched")

	print("ALL_GROUND_CREEP_TESTS_PASSED_SUCCESSFULLY!")
	quit(0)
