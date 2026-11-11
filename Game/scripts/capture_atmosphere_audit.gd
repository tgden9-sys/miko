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
	for i in range(80):
		await physics_frame
	await _save("atmosphere_current_start")
	var camera: Camera2D = level.get_node("Camera2D")
	camera.target = null
	camera.global_position = Vector2(1920, 760)
	for i in range(30):
		await physics_frame
	await _save("atmosphere_current_middle")
	level.get_node("ParallaxForeground").visible = false
	await _save("atmosphere_without_foreground")
	quit()
