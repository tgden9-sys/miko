@tool
extends SceneTree

func _init() -> void:
	var mockup_scene: PackedScene = load("res://scenes/miko8_side_on_mockup.tscn")
	var mockup = mockup_scene.instantiate()
	root.add_child(mockup)
	for f in range(10): await physics_frame

	var actor = mockup.get("actor") as CharacterBody3D
	actor.reset_actor()
	# Approach from the open right side: crate is at x=24.38, top y=0.80.
	# Place Miko at x=25.5, face left (-1) towards crate.
	actor.position = Vector3(25.5, 0.02, 0)
	actor.facing = -1
	actor.target_facing = -1
	for f in range(5): await physics_frame

	print("Initial actor pos: ", actor.position, " floor: ", actor.is_on_floor())

	Input.action_press("miko8_left", 0.65)
	await physics_frame
	await physics_frame
	Input.action_press("miko8_jump")

	var reached_crate_top := false
	for f in range(40):
		await physics_frame
		if f == 12: Input.action_release("miko8_jump")
		if actor.is_on_floor() and actor.position.y >= 0.78 and actor.position.x >= 24.0 and actor.position.x <= 24.8:
			reached_crate_top = true
			print("Actor landed on crate top from right at frame ", f, " pos: ", actor.position, " state: ", actor.state)
			break

	Input.action_release("miko8_left")
	Input.action_release("miko8_jump")
	assert(reached_crate_top, "Actor must naturally jump onto the crate without mantle animation")
	print("NATURAL CRATE JUMP VERIFIED CLEANLY FROM OPEN APPROACH!")
	mockup.free()
	quit(0)
