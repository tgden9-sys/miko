extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	
	var fg = scene.get_node("ParallaxForeground")
	fg.visible = true
	
	var robot = scene.get_node("Robot")
	var camera = scene.get_node("Camera2D")
	camera.target = null
	
	var ladder = scene.get_node("Ladders/LadderCentral")
	var col = scene.get_node("WorldEnvironmentGeometry/Columns/ColLadder")
	
	# Test positions across the middle catwalk (catwalk extends X=1600 to X=2240)
	var test_positions = [1680, 2020, 2080]
	
	for test_x in test_positions:
		ladder.global_position.x = test_x
		if col:
			col.global_position.x = test_x
		robot.global_position = Vector2(test_x, 740)
		camera.global_position = Vector2(test_x, 720)
		
		# Let parallax update
		for i in range(5):
			await process_frame
			
		var img: Image = root.get_texture().get_image()
		var out_path = "res://ladder_test_x_%d.png" % test_x
		img.save_png(out_path)
		print("Saved screenshot at X=%d to %s" % [test_x, out_path])
		
	quit(0)
