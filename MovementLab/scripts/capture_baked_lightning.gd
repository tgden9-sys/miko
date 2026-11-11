extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var lab_scene := load("res://lab.tscn") as PackedScene
	var lab := lab_scene.instantiate()
	root.add_child(lab)
	current_scene = lab
	var actor = lab.actor
	actor.automation = true
	
	var out_dir := "C:/Users/tgden/.gemini/antigravity/brain/d0780195-ffa3-4f45-840a-58f36cabe197"
	
	# Verify that sword_style is 2 out of the box (Option 3: High-Voltage Lightning)
	print("INITIAL SWORD STYLE: ", actor.sword_style, " (Name: ", actor.SWORD_STYLES[actor.sword_style].name, ")")
	
	for f in range(5):
		await physics_frame
		await process_frame
	
	actor.press("attack")
	for f in range(8):
		await physics_frame
		await process_frame
	
	RenderingServer.frame_post_draw.connect(func(): pass, CONNECT_ONE_SHOT)
	await process_frame
	await process_frame
	
	var img: Image = root.get_texture().get_image()
	var file_path: String = out_dir + "/baked_high_voltage_lightning_normal.png"
	img.save_png(file_path)
	print("CAPTURED: baked_high_voltage_lightning_normal.png")
	
	# Now let's capture the finisher hit (3rd strike of combo) which has the golden high-voltage electricity!
	actor.reset()
	for f in range(5):
		await physics_frame
		await process_frame
	
	# Strike 1
	actor.press("attack")
	for f in range(14):
		await physics_frame
		await process_frame
	# Strike 2
	actor.press("attack")
	for f in range(14):
		await physics_frame
		await process_frame
	# Strike 3 (Finisher)
	actor.press("attack")
	for f in range(9):
		await physics_frame
		await process_frame
	
	RenderingServer.frame_post_draw.connect(func(): pass, CONNECT_ONE_SHOT)
	await process_frame
	await process_frame
	
	var img_finisher: Image = root.get_texture().get_image()
	var file_path_finisher: String = out_dir + "/baked_high_voltage_lightning_finisher.png"
	img_finisher.save_png(file_path_finisher)
	print("CAPTURED: baked_high_voltage_lightning_finisher.png")
	
	quit(0)
