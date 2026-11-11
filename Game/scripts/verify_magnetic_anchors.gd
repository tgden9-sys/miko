extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	var wall: StaticBody2D = level.get_node("MagneticWallAnchor")
	var ceiling: StaticBody2D = level.get_node("MagneticCeilingAnchor")
	var wall_crate: CharacterBody2D = level.get_node("Crates/WallTestCrate")
	var ceiling_crate: CharacterBody2D = level.get_node("Crates/CeilingTestCrate")
	for crate in level.get_node("Crates").get_children():
		if crate != wall_crate and crate != ceiling_crate:
			crate.global_position = Vector2(3500, -200)
	assert(wall.polarity == wall.Polarity.NEUTRAL and ceiling.polarity == ceiling.Polarity.NEUTRAL, "Fixtures must start neutral")
	wall.lock_in_color(Color.BLUE)
	ceiling.lock_in_color(Color.BLUE)
	wall_crate.lock_in_color(Color.RED)
	ceiling_crate.lock_in_color(Color.RED)
	var wall_start: float = wall_crate.global_position.x
	var ceiling_start: float = ceiling_crate.global_position.y
	for i in range(125):
		await physics_frame
	assert(wall_crate.global_position.x > wall_start + 70.0, "Wall failed to attract the opposite crate")
	assert(ceiling_crate.global_position.y < ceiling_start - 75.0, "Ceiling failed to lift the opposite crate")
	assert(absf(wall_crate.global_position.x - wall.magnetic_contact_center(wall_crate).x) < 35.0, "Wall crate did not reach the face")
	assert(absf(ceiling_crate.global_position.y - ceiling.magnetic_contact_center(ceiling_crate).y) < 35.0, "Ceiling crate did not settle below the face")
	var wall_attract_x: float = wall_crate.global_position.x
	var ceiling_attract_y: float = ceiling_crate.global_position.y
	wall.lock_in_color(Color.RED)
	ceiling.lock_in_color(Color.RED)
	for i in range(35):
		await physics_frame
	assert(wall_crate.global_position.x < wall_attract_x - 20.0, "Wall failed to repel matching crate")
	assert(ceiling_crate.global_position.y > ceiling_attract_y + 20.0, "Ceiling failed to repel matching crate")
	wall_crate.global_position = Vector2(3500, -200)
	ceiling_crate.global_position = Vector2(3500, -200)
	await physics_frame
	var wall_ray := PhysicsRayQueryParameters2D.create(wall.global_position + Vector2(-180, 0), wall.global_position, 1)
	var ceiling_ray := PhysicsRayQueryParameters2D.create(ceiling.global_position + Vector2(0, 130), ceiling.global_position, 1)
	assert(level.get_world_2d().direct_space_state.intersect_ray(wall_ray).get("collider") == wall, "Wall is not targetable by the laser")
	assert(level.get_world_2d().direct_space_state.intersect_ray(ceiling_ray).get("collider") == ceiling, "Ceiling is not targetable by the laser")
	print("MAGNETIC_ANCHORS_OK")
	quit()
