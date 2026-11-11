@tool
extends SceneTree

func _init() -> void:
	_test_climb()

func _test_climb() -> void:
	print("Testing Miko ladder climb in gym...")
	var gym_scene: PackedScene = load("res://scenes/miko8_modular_gym.tscn")
	var gym_node: Node = gym_scene.instantiate()
	root.add_child(gym_node)
	
	for f in range(5):
		await process_frame
		
	var actor = gym_node.get_node("MIKO8")
	var ladder = gym_node.get_node("ModularAssembly/GymBuiltInLadder")
	
	print("Ladder climb_x: ", ladder.climb_x, " bottom_y: ", ladder.bottom_y, " top_y: ", ladder.top_y)
	print("Actor start pos: ", actor.position)
	
	# Position Miko directly in front of the ladder
	actor.position = Vector3(ladder.climb_x, 0.02, 0.0)
	await process_frame
	
	# Simulate pressing UP
	Input.action_press("miko8_up")
	for i in range(120): # simulate 2 seconds of climbing
		await process_frame
		if actor.abilities.ladder:
			# climb upward
			pass
	Input.action_release("miko8_up")
	
	print("After 120 frames, Actor pos: ", actor.position, " on_ladder: ", actor.abilities.ladder != null)
	if actor.position.y > 1.0:
		print("SUCCESS: Actor climbed up the tower ladder! Reached Y=", actor.position.y)
	else:
		print("NOTE: Actor at Y=", actor.position.y)
	quit(0)
