@tool
extends SceneTree

func _init() -> void:
	_test_climb_full()

func _test_climb_full() -> void:
	print("Testing full Miko ladder climb to top of catwalk...")
	var gym_scene: PackedScene = load("res://scenes/miko8_modular_gym.tscn")
	var gym_node: Node = gym_scene.instantiate()
	root.add_child(gym_node)
	
	for f in range(5):
		await process_frame
		
	var actor = gym_node.get_node("MIKO8")
	var ladder = gym_node.get_node("ModularAssembly/GymBuiltInLadder")
	
	# Position Miko at ladder base
	actor.position = Vector3(ladder.climb_x, 0.02, 0.0)
	await process_frame
	
	Input.action_press("miko8_up")
	for i in range(350):
		await process_frame
		if i % 60 == 0:
			print("Frame ", i, " Actor pos: ", actor.position, " on_ladder: ", actor.abilities.ladder != null)
	Input.action_release("miko8_up")
	
	print("Final Actor pos: ", actor.position, " on_ladder: ", actor.abilities.ladder != null, " on_floor: ", actor.is_on_floor())
	if actor.position.y >= 3.2:
		print("SUCCESS: Actor reached the catwalk summit! Final Y=", actor.position.y)
	else:
		print("Actor ended at Y=", actor.position.y)
	quit(0)
