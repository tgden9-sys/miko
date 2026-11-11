extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var robot: CharacterBody2D = level.get_node("Robot")
	var crates: Node = level.get_node("Crates")
	var block: CharacterBody2D = crates.get_node("CrateGround1")
	for c in crates.get_children():
		c.neutralize()
		if c != block:
			c.global_position = Vector2(3000.0, 100.0)
	robot.global_position = Vector2(620.0, 840.0)
	block.global_position = Vector2(850.0, 856.0)
	block.polarity = 1
	block.charge_remaining = 100.0
	robot.set_suit_polarity(1)
	assert(robot.suit_polarity == 1)
	assert(robot.eye_materials[0].get_shader_parameter("polarity") == 1)
	var robot_x: float = robot.global_position.x
	var start_x: float = block.global_position.x
	for i in range(30):
		await physics_frame
		assert(robot.get("squash_stretch").distance_to(Vector2.ONE) < 0.001, "Matching polarity squashed MIKO")
		assert(robot.sprite.scale.distance_to(robot.BASE_SPRITE_SCALE) < 0.001, "Magnetic force changed MIKO's rendered scale")
	assert(block.global_position.x > start_x + 5.0, "Matching red poles did not repel the block")
	assert(absf(robot.global_position.x - robot_x) < 1.0, "Matching crate pushed MIKO with its magnetic field")
	robot.set_suit_polarity(2)
	assert(robot.eye_materials[0].get_shader_parameter("polarity") == 2)
	start_x = block.global_position.x
	block.velocity = Vector2.ZERO
	for i in range(30):
		await physics_frame
	assert(block.global_position.x < start_x - 5.0, "Opposite poles did not attract the block")
	assert(absf(robot.global_position.x - robot_x) < 1.0, "Opposite crate pulled MIKO toward it")
	for i in range(150):
		await physics_frame
	var gap: float = absf(block.global_position.x - robot.global_position.x)
	assert(gap >= 72.0 and gap <= 130.0, "Attracted crate did not settle at a walkable gap: %s" % gap)
	robot.global_position.x -= 70.0
	for i in range(90):
		await physics_frame
	var following_gap: float = absf(block.global_position.x - robot.global_position.x)
	assert(following_gap >= 72.0 and following_gap <= 130.0, "Crate did not follow MIKO at a gap: %s" % following_gap)
	robot.set_suit_polarity(0)
	assert(robot.eye_materials[0].get_shader_parameter("polarity") == 0)
	robot.polarity_enabled = false
	robot.set_suit_polarity(1)
	assert(robot.suit_polarity == 0, "Disabled suit accepted a polarity change")
	print("SUIT_POLARITY_OK")
	quit()
