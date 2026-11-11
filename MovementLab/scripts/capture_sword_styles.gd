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
	
	var styles_to_capture := [
		{"idx": 5, "name": "style_5_ghost_mirage.png"},
		{"idx": 6, "name": "style_6_heavy_iron.png"}
	]
	
	var out_dir := "C:/Users/tgden/.gemini/antigravity/brain/d0780195-ffa3-4f45-840a-58f36cabe197"
	
	for cap in styles_to_capture:
		actor.reset()
		actor.set_sword_style(cap.idx)
		for f in range(5):
			await physics_frame
			await process_frame
		
		actor.press("attack")
		for f in range(7):
			await physics_frame
			await process_frame
		
		RenderingServer.frame_post_draw.connect(func(): pass, CONNECT_ONE_SHOT)
		await process_frame
		await process_frame
		
		var img: Image = root.get_texture().get_image()
		var file_path: String = out_dir + "/" + str(cap.name)
		img.save_png(file_path)
		print("CAPTURED: ", cap.name)
	
	print("ALL CAPTURES COMPLETED")
	quit(0)
