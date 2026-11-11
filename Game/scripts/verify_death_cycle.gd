extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var robot: CharacterBody2D = level.get_node("Robot")
	var art: AnimatedSprite2D = robot.get_node("AnimatedSprite2D")
	assert(art.sprite_frames.get_frame_count(&"death") == 20)
	for index in range(20):
		assert(art.sprite_frames.get_frame_texture(&"death", index) != null, "Missing rendered death frame")
	assert(art.sprite_frames.get_frame_count(&"death_fall") == 8)
	assert(art.sprite_frames.get_frame_count(&"death_impact") == 12)
	for i in range(8):
		await physics_frame
	robot.die()
	assert(robot.get("reaction_state") == 1)
	assert(art.animation == &"death_fall")
	assert(not robot.get_node("ThrusterLight").enabled)
	assert(not robot.get_node("WristLedL").enabled)
	assert(not robot.get_node("WristLedR").enabled)
	assert(not robot.get_node("ProceduralExhaust").get("powered"))
	assert(robot.get_node("DeathSparks").emitting)
	assert(robot.get_node("DeathSmoke").emitting)
	for i in range(75):
		await physics_frame
	assert(robot.get("reaction_state") == 1, "Death pose did not hold")
	assert(art.animation == &"death_impact", "Landing tumble did not play")
	assert(not robot.get_node("DeathSmoke").emitting, "Smoke should taper off")
	for i in range(55):
		await physics_frame
	assert(robot.get("reaction_state") == 0, "Death did not reset")
	assert(robot.get_node("ProceduralExhaust").get("powered"))
	assert(robot.global_position.distance_to(robot.get("reaction_origin")) < 16.0)
	print("DEATH_CYCLE_OK")
	quit()
