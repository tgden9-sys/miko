extends SceneTree

const OUT_DIR = "C:/Users/tgden/.gemini/antigravity/brain/1c29dfd7-0e66-4a09-8260-77a4036487b7/option4_ingame"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- STARTING OPTION 4 IN-GAME RIGOROUS VERIFICATION ---")
	DirAccess.make_dir_absolute(OUT_DIR)
	
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	
	var robot = scene.get_node("Robot")
	var camera = scene.get_node("Camera2D")
	camera.target = null # Manual camera control for crisp framing
	
	print("Instantiated scene with Robot at: ", robot.global_position)
	
	# Helper capture function
	var capture = func(filename: String):
		var img: Image = root.get_texture().get_image()
		var p = OUT_DIR + "/" + filename
		img.save_png(p)
		print("Saved capture: ", p)
	
	# =========================================================================
	# STEP 1: Idle facing right (Default state on ground)
	# =========================================================================
	robot.global_position = Vector2(960, 830)
	robot.velocity = Vector2.ZERO
	camera.global_position = Vector2(960, 800)
	camera.zoom = Vector2(1.5, 1.5) # Zoom in for clear detail
	
	for i in range(20):
		await physics_frame
	for i in range(5):
		await process_frame
		
	capture.call("option4_01_idle_right.png")
	
	# =========================================================================
	# STEP 2: Running right (Mid-stride)
	# =========================================================================
	robot.velocity = Vector2(340, 0)
	var anim_sprite = robot.get_node("AnimatedSprite2D")
	anim_sprite.play("move")
	anim_sprite.frame = 4
	camera.global_position = robot.global_position + Vector2(0, -30)
	
	for i in range(10):
		await physics_frame
	for i in range(3):
		await process_frame
		
	capture.call("option4_02_running_right.png")
	
	# =========================================================================
	# STEP 3: Jump Apex (Thruster burst)
	# =========================================================================
	robot.global_position = Vector2(960, 680) # Airborne
	robot.velocity = Vector2(100, -50)
	anim_sprite.play("jump")
	anim_sprite.frame = 5
	camera.global_position = Vector2(960, 720)
	
	for i in range(10):
		await physics_frame
	for i in range(3):
		await process_frame
		
	capture.call("option4_03_jump_apex.png")
	
	# =========================================================================
	# STEP 4: Running left (Showing LEFT ARM - Confirming 100% Symmetrical Steel Blue!)
	# =========================================================================
	robot.global_position = Vector2(1200, 830)
	robot.velocity = Vector2(-340, 0)
	robot.facing = -1
	robot.visual_facing = -1
	anim_sprite.play("move_left")
	anim_sprite.frame = 4
	camera.global_position = robot.global_position + Vector2(0, -30)
	
	for i in range(10):
		await physics_frame
	for i in range(3):
		await process_frame
		
	capture.call("option4_04_running_left_symmetrical.png")
	
	# =========================================================================
	# STEP 5: 3D Turn Animation (Mid-turn showing cybernetic back and nozzle)
	# =========================================================================
	robot.global_position = Vector2(1100, 830)
	robot.velocity = Vector2.ZERO
	anim_sprite.play("turn_to_left")
	anim_sprite.frame = 12 # Exact half-way frame: back turned to camera
	camera.global_position = robot.global_position + Vector2(0, -30)
	
	for i in range(10):
		await physics_frame
	for i in range(3):
		await process_frame
		
	capture.call("option4_05_turn_animation.png")
	
	# =========================================================================
	# STEP 6: Ladder Climb at X=1680 (Central Ladder, unobstructed view of back)
	# =========================================================================
	var ladder = scene.get_node("Ladders/LadderCentral")
	var fg = scene.get_node_or_null("ParallaxForeground")
	if fg != null:
		fg.visible = false
	camera.zoom = Vector2(1.5, 1.5) # Match 1.5 zoom of all other panels
	robot.global_position = Vector2(1680, 750)
	camera.global_position = robot.global_position + Vector2(0, -30)
	robot.velocity = Vector2.ZERO
	robot.ladder_state = robot.LadderState.CLIMBING
	robot.active_ladder = ladder
	anim_sprite.play("ladder_climb")
	anim_sprite.frame = 6
	
	for i in range(20):
		await physics_frame
	for i in range(5):
		await process_frame
		
	capture.call("option4_06_ladder_climb.png")
	
	print("--- ALL OPTION 4 IN-GAME CAPTURES COMPLETED SUCCESSFULLY ---")
	quit(0)
