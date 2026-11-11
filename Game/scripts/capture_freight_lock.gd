extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	var robot: CharacterBody2D = level.get_node("Robot")
	var fixture: Area2D = level.get_node("MagneticDrainFixture")
	var camera: Camera2D = level.get_node("Camera2D")
	camera.target = null
	camera.global_position = Vector2(750.0, 830.0)
	camera.zoom = Vector2(2.0, 2.0)
	robot.global_position = Vector2(750.0, 830.0)
	robot.velocity = Vector2.ZERO
	for pole in [0, 1, 2]:
		fixture.polarity = pole
		fixture._update_appearance()
		robot.set_suit_polarity(pole)
		for i in range(5):
			await process_frame
		var image: Image = root.get_texture().get_image()
		var path: String = "res://../Builds/Validation/freight_lock_%s.png" % ["neutral", "red", "blue"][pole]
		image.save_png(path)
		print(path)
	quit()
