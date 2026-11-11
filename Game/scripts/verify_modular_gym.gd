extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var gym = load("res://scenes/miko8_modular_gym.tscn").instantiate()
	root.add_child(gym)
	for i in range(20):
		await physics_frame
	
	print("=== VERIFYING MODULAR TESTING GYM ===")
	assert(is_instance_valid(gym.actor), "Actor must exist in Gym")
	assert(is_instance_valid(gym.platform_root), "Platform root must exist")
	assert(is_instance_valid(gym.deck_body), "Walkable deck body must exist")
	assert(is_instance_valid(gym.ladder_node), "Built-in ladder must exist")
	
	var actor = gym.actor
	var abilities = actor.abilities
	
	# 1. Mount Built-in Tower Ladder
	actor.reset_actor()
	actor.position = Vector3(0.0, 0.02, gym.tower_depth * 0.5 + 0.05)
	for i in range(5):
		await physics_frame
	
	var ladder = abilities._near_ladder()
	print("Gym ladder detected: ", ladder.name if ladder else "null")
	assert(ladder == gym.ladder_node, "Miko must detect built-in ladder")
	
	# 2. Climb up to the catwalk summit
	abilities._mount(ladder, false)
	assert(actor.state.begins_with("Climb"), "Miko should mount into Climb state")
	
	for i in range(150):
		await physics_frame
		abilities._climb_tick(1.0 / 60.0, 1.0)
		if actor.position.y >= gym.tower_height - 0.15:
			break
	
	print("Miko climbed to height: ", actor.position.y)
	assert(actor.position.y >= gym.tower_height - 0.25, "Miko must reach top of the tower")
	
	# 3. Step onto the Catwalk Deck
	actor.collision_mask = 1
	actor.position = Vector3(0.0, gym.tower_height + 0.02, 0.0)
	actor.velocity = Vector3.ZERO
	actor._state("Locomotion")
	actor._play("Idle", 0.08)
	for i in range(15):
		await physics_frame
	
	print("Grounded on catwalk: ", actor.is_on_floor(), " height: ", actor.position.y)
	assert(actor.is_on_floor(), "Miko must stand firmly on the catwalk deck")
	assert(absf(actor.position.y - gym.tower_height) < 0.05, "Miko should stand at deck height")
	
	# 4. Walk across the Catwalk
	Input.action_press("miko8_right", 0.65)
	for i in range(25):
		await physics_frame
	Input.action_release("miko8_right")
	
	print("Walked to X=", actor.position.x, " still grounded: ", actor.is_on_floor())
	assert(actor.is_on_floor(), "Miko must stay grounded across catwalk deck")
	assert(actor.position.x > 0.35, "Miko should smoothly traverse the catwalk")
	
	print("=== MODULAR TESTING GYM VERIFICATION: ALL PASS! ===")
	quit(0)
