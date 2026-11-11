@tool
extends SceneTree

func _init() -> void:
	_test_ledge_detect()

func _test_ledge_detect() -> void:
	print("Testing ledge detection in mockup scene...")
	var scene: PackedScene = load("res://scenes/miko8_side_on_mockup.tscn")
	var mockup: Node = scene.instantiate()
	root.add_child(mockup)
	
	for f in range(5):
		await process_frame
		
	var actor: CharacterBody3D = mockup.get("actor") as CharacterBody3D
	var space: PhysicsDirectSpaceState3D = actor.get_world_3d().direct_space_state
	
	# Test near WorkshopCrateStep at X=50.9, top is at Y=0.80
	# Put Miko at X=50.2, Y=0.0 facing right (+1)
	actor.position = Vector3(50.2, 0.02, 0.0)
	actor.facing = 1
	await process_frame
	
	# Ray 1: forward wall ray
	var wall_from: Vector3 = actor.global_position + Vector3(0, 0.6, 0)
	var wall_to: Vector3 = wall_from + Vector3(float(actor.facing) * 0.7, 0, 0)
	var q_wall := PhysicsRayQueryParameters3D.create(wall_from, wall_to)
	q_wall.exclude = [actor.get_rid()]
	var wall_hit: Dictionary = space.intersect_ray(q_wall)
	print("Wall hit: ", not wall_hit.is_empty())
	if not wall_hit.is_empty():
		print("  collider: ", wall_hit.collider.name, " pos: ", wall_hit.position, " normal: ", wall_hit.normal)
		# Ray 2: down from above
		var ledge_from: Vector3 = Vector3(wall_hit.position.x + float(actor.facing) * 0.25, actor.global_position.y + 2.0, 0.0)
		var ledge_to: Vector3 = Vector3(wall_hit.position.x + float(actor.facing) * 0.25, actor.global_position.y + 0.2, 0.0)
		var q_ledge := PhysicsRayQueryParameters3D.create(ledge_from, ledge_to)
		q_ledge.exclude = [actor.get_rid()]
		var ledge_hit: Dictionary = space.intersect_ray(q_ledge)
		print("Ledge hit: ", not ledge_hit.is_empty())
		if not ledge_hit.is_empty():
			print("  ledge pos: ", ledge_hit.position, " normal: ", ledge_hit.normal)
			var rel_h: float = ledge_hit.position.y - actor.global_position.y
			print("  rel_h: ", rel_h)
	quit(0)
