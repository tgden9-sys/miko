@tool
extends SceneTree

func _init() -> void:
	_test_mantle_execution()

func _test_mantle_execution() -> void:
	print("Testing Mantle Execution on Crate...")
	var scene: PackedScene = load("res://scenes/miko8_side_on_mockup.tscn")
	var mockup: Node = scene.instantiate()
	root.add_child(mockup)
	
	for f in range(5):
		await process_frame
		
	var actor: CharacterBody3D = mockup.get("actor") as CharacterBody3D
	
	# Position Miko right in front of TutorialChargeCrate (crate is at X=24.0, top is Y=0.80)
	actor.position = Vector3(23.2, 0.02, 0.0)
	actor.facing = 1
	actor.target_facing = 1
	await process_frame
	
	print("Actor start position: ", actor.position)
	# Check if actor has mantle check
	if actor.has_method("_check_mantle"):
		var can_mantle = actor._check_mantle()
		print("Can mantle crate from X=23.2? ", can_mantle)
	else:
		print("Actor does not have _check_mantle yet (expected before implementation)")
	quit(0)
