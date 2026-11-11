extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var robot: CharacterBody2D = level.get_node("Robot")
	var art: AnimatedSprite2D = robot.get_node("AnimatedSprite2D")
	robot.global_position = Vector2(620.0, 420.0)
	robot.velocity = Vector2(0.0, -120.0)
	var start_y: float = robot.global_position.y
	robot.die()
	assert(art.animation == &"death_fall")
	assert(robot.velocity.y == -120.0, "Death erased airborne momentum")
	for i in range(20):
		await physics_frame
	assert(robot.get("reaction_state") == 1, "Death reset before landing")
	assert(robot.global_position.y > start_y + 15.0, "MIKO did not fall")
	assert(not robot.is_on_floor(), "Midair test started too close to the floor")
	assert(art.animation == &"death_fall", "Tumble started before landing")
	var landed: bool = false
	for i in range(100):
		await physics_frame
		if robot.get("death_landed"):
			landed = true
			break
	assert(landed, "MIKO never reached the floor")
	assert(robot.is_on_floor(), "Tumble began before floor contact")
	assert(art.animation == &"death_impact")
	for i in range(85):
		await physics_frame
	assert(robot.get("reaction_state") == 1, "Death pose did not hold after landing")
	for i in range(25):
		await physics_frame
	assert(robot.get("reaction_state") == 0, "Midair death did not reset")
	print("MIDAIR_DEATH_OK")
	quit()
