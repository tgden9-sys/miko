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
	print("STARTING_CATWALK_CREEP_TEST")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)

	var crates_node = scene.get_node("Crates")
	var crate_red = crates_node.get_node("CrateUpperRight1") # Red (polarity 1)
	var crate_blue = crates_node.get_node("CrateUpperRight2") # Blue (polarity 2)

	# Position them on catwalk at Y = 588 with distance = 350 px (Overlapping by 50 px)
	crate_red.global_position = Vector2(2900, 588)
	crate_blue.global_position = Vector2(3250, 588) # 3250 - 2900 = 350 px
	crate_red.velocity = Vector2.ZERO
	crate_blue.velocity = Vector2.ZERO

	# Camera focused squarely on catwalk action
	var camera = scene.get_node("Camera2D")
	camera.target = null
	camera.global_position = Vector2(3075, 540)

	print("INITIAL CATWALK DISTANCE = 350 px:")
	var latched: bool = false
	for i in range(260):
		await process_frame
		var cur_d: float = crate_red.global_position.distance_to(crate_blue.global_position)
		if i % 30 == 0:
			print("  Frame ", i, " - dist: ", cur_d, " | red vel: ", crate_red.velocity.x, " | blue vel: ", crate_blue.velocity.x)
		if i == 20:
			await _save("catwalk_creep_01_slow")
		if cur_d <= 74.0:
			latched = true
			print("  LATCHED AT FRAME ", i, " | final dist: ", cur_d)
			for _k in range(8):
				await process_frame
			break

	assert(latched, "Crates must accelerate and latch together!")
	await _save("catwalk_creep_02_latched")

	print("ALL_CATWALK_CREEP_TESTS_PASSED_SUCCESSFULLY!")
	quit(0)
