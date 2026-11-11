extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TESTING LADDER CLIMB WITH FOREGROUND VISIBLE AT X=1680 ---")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	
	var fg = scene.get_node("ParallaxForeground")
	print("ParallaxForeground visible: ", fg.visible)
	assert(fg.visible == true, "Foreground must be visible!")
	
	var robot = scene.get_node("Robot")
	var camera = scene.get_node("Camera2D")
	camera.target = null
	
	# Position at ladder (X=1680)
	var ladder = scene.get_node("Ladders/LadderCentral")
	print("Ladder position: ", ladder.global_position)
	assert(ladder.global_position.x == 1680, "Ladder should be at X=1680!")
	
	camera.global_position = Vector2(1680, 720)
	robot.global_position = Vector2(1680, 750)
	robot.ladder_state = 2 # CLIMBING
	robot.active_ladder = ladder
	
	for i in range(15):
		await physics_frame
	for i in range(3):
		await process_frame
		
	var img: Image = root.get_texture().get_image()
	var out_path = "res://ladder_climber_verified_x1680.png"
	img.save_png(out_path)
	print("Saved ", out_path)
	
	quit(0)
