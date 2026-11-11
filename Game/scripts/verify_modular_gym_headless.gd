@tool
extends SceneTree

func _init() -> void:
	_run_check()

func _run_check() -> void:
	print("Verifying Modular Gym scene...")
	var gym_scene: PackedScene = load("res://scenes/miko8_modular_gym.tscn")
	if not gym_scene:
		print("FAILED to load miko8_modular_gym.tscn")
		quit(1)
		return
	var gym_node: Node = gym_scene.instantiate()
	root.add_child(gym_node)
	
	# Wait for ready and a couple frames
	for f in range(5):
		await process_frame
		
	print("Gym initialized!")
	
	# Check platform root children
	var platform: Node = gym_node.get_node_or_null("ModularAssembly")
	if platform:
		print("ModularAssembly exists with ", platform.get_child_count(), " children:")
		for c in platform.get_children():
			print("  Child: ", c.name, " (", c.get_class(), ") pos=", c.position, " scale=", c.scale)
	else:
		print("ERROR: ModularAssembly not found!")
		quit(1)
		return
		
	# Check actor
	var actor: Node = gym_node.get_node_or_null("MIKO8")
	if actor:
		print("MIKO8 actor exists! Pos=", actor.position)
	else:
		print("ERROR: MIKO8 actor not found!")
		quit(1)
		return

	print("Modular Gym test PASSED with 0 errors!")
	quit(0)
