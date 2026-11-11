extends SceneTree

func _initialize() -> void:
	call_deferred("_validate")

func _validate() -> void:
	print("STARTING_CITY_VALIDATION")
	var scene_res = load("res://scenes/industrial_city.tscn")
	if scene_res == null:
		push_error("FAILED TO LOAD industrial_city.tscn")
		quit(1)
		return
	var scene = scene_res.instantiate()
	if scene == null:
		push_error("FAILED TO INSTANTIATE industrial_city.tscn")
		quit(1)
		return
	root.add_child(scene)
	
	# Verify components
	var bg = scene.get_node_or_null("ParallaxBackground")
	assert(bg != null, "Missing ParallaxBackground")
	assert(bg.get_child_count() == 4, "Expected 4 background parallax layers")
	
	var fg = scene.get_node_or_null("ParallaxForeground")
	assert(fg != null, "Missing ParallaxForeground")
	assert(fg.get_child_count() == 1, "Expected 1 foreground parallax layer")
	assert(fg.visible, "Foreground artwork was hidden")
	var foreground_air: CPUParticles2D = scene.get_node("ForegroundAir")
	assert(foreground_air.emitting and foreground_air.texture != null, "Foreground air effect is missing")
	var floor_mist: CPUParticles2D = scene.get_node("MistParticles")
	assert(floor_mist.emitting and floor_mist.texture != null, "Floor mist is missing its soft texture")
	
	var robot = scene.get_node_or_null("Robot")
	assert(robot != null, "Missing Robot")
	
	var camera = scene.get_node_or_null("Camera2D")
	assert(camera != null, "Missing Camera2D")
	
	# Step a few physics frames
	for i in range(15):
		await physics_frame
	
	print("ROBOT_INITIAL_POS: ", robot.global_position)
	print("CAMERA_POS: ", camera.global_position)
	print("VALIDATION_SUCCESS_CITY_SCENE")
	quit(0)
