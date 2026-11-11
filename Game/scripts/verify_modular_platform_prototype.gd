extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	for i in range(25):
		await physics_frame

	print("=== TESTING MODULAR FREESTANDING PLATFORM PROTOTYPE ===")
	var assembly = level.find_child("ModularFreestandingGantry", true, false)
	assert(is_instance_valid(assembly), "ModularFreestandingGantry must exist in mockup scene")
	for i in range(5):
		await physics_frame

	assert(assembly.pillars.size() == 4, "Must have 4 column units forming the two 3.6m pillars")
	assert(is_instance_valid(assembly.catwalk_model), "Catwalk mesh must instantiate cleanly")
	assert(is_instance_valid(assembly.deck_body), "Walkable deck body must exist")
	assert(is_instance_valid(assembly.ladder), "Ladder interaction must exist")

	var actor = level.actor

	# 1. Test ladder mounting at the gantry base
	var ladder_x = assembly.ladder.position.x
	actor.reset_actor()
	actor.position = Vector3(ladder_x, 0.02, 0.0)
	actor.facing = 1
	for i in range(5):
		await physics_frame

	var abilities = actor.abilities
	var nearby_ladder = abilities._near_ladder()
	print("Nearby ladder at X=", ladder_x, ": ", nearby_ladder.name if nearby_ladder else "null")
	assert(nearby_ladder == assembly.ladder, "Miko must detect modular gantry ladder")

	# 2. Test Miko climbing to the 3.6m catwalk deck
	abilities._mount(assembly.ladder, false)
	assert(actor.state.begins_with("Climb"), "Miko should mount into Climb state")

	# Climb up
	for i in range(160):
		await physics_frame
		abilities._climb_tick(1.0 / 60.0, 1.0)
		if actor.position.y >= 3.50:
			break

	print("Miko climbed to height: ", actor.position.y)
	assert(actor.position.y >= 3.40, "Miko must climb to 3.6m gantry catwalk level")

	# 3. Test Miko standing on the elevated catwalk deck
	actor.collision_mask = 1
	actor.position = Vector3(assembly.gantry_x, assembly.gantry_height + 0.02, 0.0)
	actor.velocity = Vector3.ZERO
	actor._state("Locomotion")
	actor._play("Idle", 0.08)
	for i in range(15):
		await physics_frame

	print("Grounded on gantry catwalk: ", actor.is_on_floor(), " height: ", actor.position.y)
	assert(actor.is_on_floor(), "Miko must be firmly grounded on the 3.6m catwalk deck")
	assert(absf(actor.position.y - 3.60) < 0.05, "Miko should stand at Y=3.60m on the gantry catwalk")

	# 4. Test Miko walking along the elevated gantry catwalk
	Input.action_press("miko8_right", 0.65)
	for i in range(25):
		await physics_frame
	Input.action_release("miko8_right")

	print("Walked to X=", actor.position.x, " still grounded: ", actor.is_on_floor())
	assert(actor.is_on_floor(), "Miko must remain grounded while walking on the gantry deck")
	assert(actor.position.x > assembly.gantry_x + 0.3, "Miko should smoothly traverse across the gantry catwalk")

	print("=== ALL MODULAR PLATFORM PROTOTYPE TESTS PASSED! ===")
	quit(0)
