extends SceneTree

var out_dir := "C:/Users/tgden/.gemini/antigravity/brain/d0780195-ffa3-4f45-840a-58f36cabe197/"

func _initialize() -> void:
	call_deferred("run")

func shot(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := out_dir + label + ".png"
	img.save_png(path)
	print("SAVED: ", path)

func run() -> void:
	var lab = (load("res://lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	lab.actor.automation = true
	
	for i in range(15):
		await process_frame
	
	# Position Miko on the left so he dashes right towards the center
	lab.actor.position = Vector3(-3.0, 0.04, 0.0)
	lab.actor.velocity = Vector3.ZERO
	lab.actor.facing = 1
	lab.camera.position = Vector3(-1.4, 1.25, 18.0)
	lab.camera.size = 4.2
	
	# Trigger dash
	lab.actor.press("dash")
	
	# Advance 5 physics frames (mid-dash, ~frame 5)
	for i in range(5):
		await physics_frame
	await shot("dash_ghosts_mid_dash")
	
	# Advance another 4 physics frames (near dash completion, ~frame 9)
	for i in range(4):
		await physics_frame
	await shot("dash_ghosts_late_dash")
	
	# Advance 4 more frames (just after dash ends, ghosts fading out)
	for i in range(4):
		await physics_frame
	await shot("dash_ghosts_fading")
	
	print("DASH CAPTURES FINISHED")
	quit()
