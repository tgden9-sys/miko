extends SceneTree

func _initialize() -> void:
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	
	var fg = scene.get_node_or_null("ParallaxForeground")
	print("ParallaxForeground found:", fg != null)
	if fg != null:
		print("fg layer:", fg.layer, " visible:", fg.visible)
	
	var robot = scene.get_node("Robot")
	robot.global_position = Vector2(1800, 720)
	var camera = scene.get_node("Camera2D")
	camera.target = null
	camera.global_position = Vector2(1800, 720)
	
	for i in range(10):
		await process_frame
		
	var img: Image = root.get_texture().get_image()
	img.save_png("res://test_fg_on.png")
	
	# Now hide ParallaxForeground
	if fg != null:
		fg.visible = false
	
	for i in range(10):
		await process_frame
		
	var img2: Image = root.get_texture().get_image()
	img2.save_png("res://test_fg_off.png")
	
	print("Saved test_fg_on.png and test_fg_off.png")
	quit(0)
