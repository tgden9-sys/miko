extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TESTING JUMP SHADOW AND UNOBSTRUCTED LADDER ---")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	
	var robot = scene.get_node("Robot")
	var shadow = robot.get_node("Shadow")
	var camera = scene.get_node("Camera2D")
	camera.target = null
	
	# Spawn robot on ground at X = 1500
	robot.global_position = Vector2(1500, 820)
	robot.velocity = Vector2.ZERO
	camera.global_position = Vector2(1500, 750)
	
	# Settle onto floor
	for i in range(20):
		await physics_frame
		
	print("GROUND SETTLED:")
	print("  robot pos_y: ", robot.global_position.y, " on_floor: ", robot.is_on_floor())
	print("  shadow pos_y: ", shadow.global_position.y, " visible: ", shadow.visible)
	
	# Trigger real jump
	robot.coyote_timer = 0.1
	robot.jump_buffer_timer = 0.1
	await physics_frame
	print("  Frame 1 of jump vel_y: ", robot.velocity.y, " robot pos_y: ", robot.global_position.y)
	await physics_frame
	print("  Frame 2 of jump vel_y: ", robot.velocity.y, " robot pos_y: ", robot.global_position.y)
	
	for i in range(12):
		await physics_frame
		
	print("MIDAIR PEAK (Frame 14):")
	print("  robot pos_y: ", robot.global_position.y, " (high in air)")
	print("  shadow pos_y: ", shadow.global_position.y, " (MUST STAY AT FLOOR ~878!)")
	print("  shadow scale: ", shadow.scale, " alpha: ", shadow.modulate.a)
	
	assert(absf(shadow.global_position.y - 878.0) < 5.0, "Shadow did NOT stay on ground!")
	assert(robot.global_position.y < 780.0, "Robot did not ascend into air!")
	print("SUCCESS: Shadow stayed firmly on the ground at floor level (878) while robot jumped into the air!")
	
	for i in range(2):
		await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png("res://jump_shadow_verified.png")
	print("Saved jump_shadow_verified.png")
	
	# Now focus on ladder climbing at X = 1800
	camera.global_position = Vector2(1800, 720)
	robot.global_position = Vector2(1800, 750)
	robot.ladder_state = 2 # CLIMBING
	robot.active_ladder = scene.get_node("Ladders/LadderCentral")
	for i in range(10):
		await physics_frame
	for i in range(2):
		await process_frame
	var img_lad: Image = root.get_texture().get_image()
	img_lad.save_png("res://ladder_clean_unobstructed.png")
	print("Saved ladder_clean_unobstructed.png")
	
	print("--- ALL TESTS COMPLETED CLEANLY! ---")
	quit(0)
