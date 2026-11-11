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
	var actor = lab.actor
	actor.automation = true
	
	for i in range(15):
		await process_frame
	
	lab.zoomed = true
	lab.camera.size = 3.8
	
	# -----------------------------------------------------------------
	# 1. SPRINT LEAN (Athletic Forward Torso Banking)
	# -----------------------------------------------------------------
	lab.reset_room()
	actor.position = Vector3(-3.0, 0.04, 0)
	actor.command_axis = 1.0
	for i in range(16):
		await physics_frame
	lab.camera.position = Vector3(actor.position.x, 1.25, 18.0)
	await shot("pop_sprint_lean")
	
	# -----------------------------------------------------------------
	# 2. HARD BRAKE / SKID PITCH (Torso Pitch-Back)
	# -----------------------------------------------------------------
	actor.command_axis = -1.0
	for i in range(4):
		await physics_frame
	lab.camera.position = Vector3(actor.position.x, 1.25, 18.0)
	await shot("pop_brake_skid")
	
	# -----------------------------------------------------------------
	# 3. TURNAROUND PIVOT (Smooth Rotational Pivot Toward Camera)
	# -----------------------------------------------------------------
	lab.reset_room()
	actor.position = Vector3(0, 0.04, 0)
	actor.facing = 1
	actor.visual.rotation.y = PI * 0.5
	actor.command_axis = -1.0
	for i in range(3):
		await physics_frame
	lab.camera.position = Vector3(0, 1.25, 18.0)
	await shot("pop_turnaround_pivot")
	
	# -----------------------------------------------------------------
	# 4. AIRBORNE ASCENT (JumpAir Tuck)
	# -----------------------------------------------------------------
	lab.reset_room()
	actor.position = Vector3(0, 0.04, 0)
	actor.command_held = true
	actor.press("jump")
	for i in range(12):
		await physics_frame
	lab.camera.position = Vector3(actor.position.x, actor.position.y + 0.6, 18.0)
	await shot("pop_airborne_ascent")
	
	# -----------------------------------------------------------------
	# 5. AIRBORNE APEX FLOAT (AirIdle Hover)
	# -----------------------------------------------------------------
	for i in range(14):
		await physics_frame
	lab.camera.position = Vector3(actor.position.x, actor.position.y + 0.6, 18.0)
	await shot("pop_airborne_apex")
	
	# -----------------------------------------------------------------
	# 6. RUNNING LANDING COMPRESSION (Knee Shock Absorber)
	# -----------------------------------------------------------------
	lab.reset_room()
	actor.position = Vector3(0, 1.4, 0)
	actor.velocity = Vector3(5.0, -3.5, 0)
	actor.command_axis = 1.0
	for f in range(20):
		await physics_frame
		if actor.is_on_floor():
			break
	for f in range(2):
		await physics_frame
	lab.camera.position = Vector3(actor.position.x, 1.15, 18.0)
	await shot("pop_running_landing")
	
	# -----------------------------------------------------------------
	# 7. COMBAT STEP-IN LUNGE (SwordC Heavy Finisher Anchor)
	# -----------------------------------------------------------------
	lab.reset_room()
	actor.position = Vector3(-1.0, 0.04, 0)
	actor.command_axis = 0.0
	actor.press("attack")
	for i in range(12): await physics_frame
	actor.press("attack")
	for i in range(12): await physics_frame
	actor.press("attack") # Queues SwordC
	for i in range(7): await physics_frame
	lab.camera.position = Vector3(actor.position.x + 0.25, 1.25, 18.0)
	await shot("pop_combat_lunge")

	print("ALL_POP_CAPTURES_COMPLETE")
	quit()
