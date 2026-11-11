@tool
extends SceneTree

func _init() -> void:
	_test_mantle_simulation()

func _test_mantle_simulation() -> void:
	print("Running Crate Mantling Simulation Test...")
	var scene: PackedScene = load("res://scenes/miko8_side_on_mockup.tscn")
	var mockup: Node = scene.instantiate()
	root.add_child(mockup)
	
	for f in range(5):
		await process_frame
		
	var actor: CharacterBody3D = mockup.get("actor") as CharacterBody3D
	actor.reset_actor()
	await process_frame
	
	# Start Miko at X=23.3 (crate edge is at X=23.987)
	actor.position = Vector3(23.3, 0.02, 0.0)
	actor.facing = 1
	actor.target_facing = 1
	actor.velocity = Vector3.ZERO
	await process_frame
	
	print("Start: Pos=", actor.position, " State=", actor.state)
	
	# 1. Run toward crate for 10 frames
	Input.action_press("miko8_right")
	for f in range(10):
		await process_frame
		
	print("After 10 frames run: Pos=", actor.position, " State=", actor.state)
	
	# 2. Press Jump to jump towards / into crate
	Input.action_press("miko8_jump")
	
	var entered_mantle := false
	var max_y := 0.0
	
	for frame in range(120):
		await process_frame
		max_y = maxf(max_y, actor.position.y)
		if actor.state == "Mantle":
			if not entered_mantle:
				entered_mantle = true
				print("Frame ", frame, ": ENTERED MANTLE! Pos=", actor.position, " Clip=", actor.current_clip)
		elif entered_mantle and actor.state != "Mantle":
			print("Frame ", frame, ": FINISHED MANTLE! Pos=", actor.position, " State=", actor.state, " on_floor=", actor.is_on_floor())
			break
			
	Input.action_release("miko8_right")
	Input.action_release("miko8_jump")
	
	print("Final Pos: ", actor.position, " State: ", actor.state, " Max Y: ", max_y, " on_floor: ", actor.is_on_floor())
	
	if entered_mantle and actor.position.y >= 0.75:
		print("CRATE_MANTLE_PASS: Successfully detected crate ledge, vaulted with Climb animation, and landed on top of crate at Y=", actor.position.y)
		quit(0)
	else:
		print("FAILED: entered_mantle=", entered_mantle, " final_y=", actor.position.y)
		quit(1)
