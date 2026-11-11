extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _save(name: String) -> void:
	for i in range(3):
		await process_frame
	var path: String = "res://../Builds/Validation/%s.png" % name
	assert(root.get_texture().get_image().save_png(path) == OK)
	print("CAPTURED ", path)

func _run() -> void:
	var level: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	var robot: CharacterBody2D = level.get_node("Robot")
	var camera: Camera2D = level.get_node("Camera2D")
	camera.target = null
	camera.global_position = Vector2(740, 800)
	camera.zoom = Vector2(2.0, 2.0)
	var crate: CharacterBody2D = level.get_node("Crates/CrateGround1")
	for other in level.get_node("Crates").get_children():
		if other != crate:
			other.global_position = Vector2(3000, 100)
	level.get_node("MagneticDrainFixture").global_position = Vector2(3000, 878)
	crate.global_position = Vector2(780, 856)
	var key := InputEventKey.new()
	key.keycode = KEY_Q
	key.pressed = true
	Input.parse_input_event(key)
	for i in range(42):
		await physics_frame
	await _save("laser_assist_locked")
	crate.global_position = Vector2(3000, 100)
	for i in range(3):
		await physics_frame
	await _save("laser_assist_open_air")
	key.pressed = false
	Input.parse_input_event(key)
	quit()
