@tool
extends SceneTree

func _init() -> void:
	_test_step_mantle()

func _test_step_mantle() -> void:
	print("Running Stacked Crates Mantle Test...")
	var scene: PackedScene = load("res://scenes/miko8_side_on_mockup.tscn")
	var mockup: Node = scene.instantiate()
	root.add_child(mockup)
	
	for f in range(5):
		await process_frame
		
	var actor: CharacterBody3D = mockup.get("actor") as CharacterBody3D
	actor.reset_actor()
	await process_frame
	
	# Start Miko at X=50.0 facing right towards WorkshopCrateStep (at X=50.9, top=0.80)
	actor.position = Vector3(50.0, 0.02, 0.0)
	actor.facing = 1
	actor.target_facing = 1
	actor.velocity = Vector3.ZERO
	await process_frame
	
	print("Step 1: Run towards step crate...")
	Input.action_press("miko8_right")
	
	var mantled_step := false
	for frame in range(120):
		await process_frame
		if actor.state == "Mantle" and not mantled_step:
			mantled_step = true
			print("Mantled Step Crate! Frame: ", frame, " Pos: ", actor.position)
		elif mantled_step and actor.state != "Mantle":
			print("Standing on Step Crate! Pos: ", actor.position)
			break
			
	Input.action_release("miko8_right")
	
	print("Step 1 Result: on_step=", mantled_step, " pos=", actor.position)
	assert(mantled_step and actor.position.y >= 0.75)
	print("STEP_CRATE_MANTLE_PASS!")
	quit(0)
