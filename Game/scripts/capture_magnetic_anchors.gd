extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _save(label: String) -> void:
	for i in range(3):
		await process_frame
	var path: String = "res://../Builds/Validation/magnetic_anchors_%s.png" % label
	assert(root.get_texture().get_image().save_png(path) == OK)
	print("CAPTURED ", path)

func _run() -> void:
	var level: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	var camera: Camera2D = level.get_node("Camera2D")
	camera.target = null
	camera.global_position = Vector2(2330, 790)
	camera.zoom = Vector2(2.0, 2.0)
	level.get_node("ParallaxForeground").visible = false
	var robot: CharacterBody2D = level.get_node("Robot")
	robot.global_position = Vector2(2240, 840)
	var wall: StaticBody2D = level.get_node("MagneticWallAnchor")
	var ceiling: StaticBody2D = level.get_node("MagneticCeilingAnchor")
	var wall_crate: CharacterBody2D = level.get_node("Crates/WallTestCrate")
	var ceiling_crate: CharacterBody2D = level.get_node("Crates/CeilingTestCrate")
	for crate in level.get_node("Crates").get_children():
		if crate != wall_crate and crate != ceiling_crate:
			crate.global_position = Vector2(3500, -200)
	for i in range(20):
		await physics_frame
	await _save("neutral")
	wall.lock_in_color(Color.BLUE)
	ceiling.lock_in_color(Color.BLUE)
	wall_crate.lock_in_color(Color.RED)
	ceiling_crate.lock_in_color(Color.RED)
	for i in range(120):
		await physics_frame
	await _save("charged")
	robot._fire_quick_blaster()
	for i in range(3):
		await physics_frame
	await _save("green_blaster")
	quit()
