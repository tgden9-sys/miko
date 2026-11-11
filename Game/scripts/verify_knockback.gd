extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	await process_frame
	for i in range(8):
		await physics_frame
	var robot: CharacterBody2D = level.get_node("Robot")
	var art: AnimatedSprite2D = robot.get_node("AnimatedSprite2D")
	assert(art.sprite_frames.get_frame_count(&"knockback") == 18)
	for index in range(18):
		assert(art.sprite_frames.get_frame_texture(&"knockback", index) != null, "Missing rig render")
	var start_x: float = robot.global_position.x
	var start_y: float = robot.global_position.y
	robot.take_damage(Vector2(-270.0, 0.0))
	assert(robot.get("reaction_state") == 2)
	assert(art.animation == &"knockback")
	assert(art.modulate == Color.WHITE)
	assert(robot.get_node("ProceduralExhaust").get("powered"))
	for i in range(10):
		await physics_frame
	assert(robot.global_position.y >= start_y - 2.0, "Knockback lifted MIKO off the floor")
	for i in range(48):
		await physics_frame
	assert(robot.get("reaction_state") == 0, "Knockback did not recover")
	assert(robot.global_position.x < start_x - 10.0, "Knockback did not move MIKO backward")
	robot.set("facing", -1)
	robot.set("visual_facing", -1)
	robot.take_damage(Vector2(270.0, 0.0))
	assert(art.flip_h, "Opposite knockback was not mirrored")
	for i in range(58):
		await physics_frame
	assert(robot.get("reaction_state") == 0)
	print("KNOCKBACK_OK")
	quit()
