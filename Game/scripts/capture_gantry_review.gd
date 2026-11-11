extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	for i in range(30):
		await physics_frame
	
	var actor = level.actor
	actor.reset_actor()
	# Position Miko right by the gantry ladder
	actor.position = Vector3(25.67, 0.02, 0.0)
	actor.facing = 1
	level._camera(0.0, true)
	for i in range(20):
		await physics_frame
		await process_frame
	await RenderingServer.frame_post_draw
	
	var img = root.get_texture().get_image()
	var out_path = "res://qa_gantry_ground_approach.png"
	img.save_png(out_path)
	print("CAPTURED_GROUND: ", out_path)
	
	# Position Miko on top of the catwalk deck
	actor.position = Vector3(27.0, 3.62, 0.0)
	actor.velocity = Vector3.ZERO
	actor._state("Locomotion")
	actor._play("Idle", 0.08)
	level._camera(0.0, true)
	for i in range(20):
		await physics_frame
		await process_frame
	await RenderingServer.frame_post_draw
	
	img = root.get_texture().get_image()
	out_path = "res://qa_gantry_deck_stand.png"
	img.save_png(out_path)
	print("CAPTURED_DECK: ", out_path)
	quit(0)
