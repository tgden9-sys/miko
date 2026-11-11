extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1200, 675)
	root.content_scale_size = Vector2i(1200, 675)
	var scene: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(scene)
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.set("target", null)
	camera.global_position = Vector2(1200, 750)
	camera.zoom = Vector2(1.3, 1.3)
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../Previews/courier_stack_in_game.png")
	var error := root.get_texture().get_image().save_png(path)
	print("COURIER CAPTURE ", path, " error=", error)
	quit(0 if error == OK else 1)
