@tool
extends SceneTree

func _init() -> void:
	_test_ledge_algo()

func _test_ledge_algo() -> void:
	print("Testing Downward-First Ledge Algorithm at Airborne Pos...")
	var scene: PackedScene = load("res://scenes/miko8_side_on_mockup.tscn")
	var mockup: Node = scene.instantiate()
	root.add_child(mockup)
	
	for f in range(5):
		await process_frame
		
	var actor: CharacterBody3D = mockup.get("actor") as CharacterBody3D
	actor.reset_actor()
	var space = actor.get_world_3d().direct_space_state
	
	# Test: Miko in air at X=23.704, Y=0.7455
	actor.position = Vector3(23.704, 0.7455, 0.0)
	actor.facing = 1
	await process_frame
	
	var f: float = float(actor.facing)
	# Downward ray cast forward (0.35m to 0.55m ahead of Miko)
	var ledge_down_from: Vector3 = Vector3(actor.global_position.x + f * 0.40, actor.global_position.y + 1.2, 0.0)
	var ledge_down_to: Vector3 = Vector3(actor.global_position.x + f * 0.40, actor.global_position.y - 0.5, 0.0)
	var q_down := PhysicsRayQueryParameters3D.create(ledge_down_from, ledge_down_to)
	q_down.exclude = [actor.get_rid()]
	var down_hit: Dictionary = space.intersect_ray(q_down)
	print("Down hit: ", not down_hit.is_empty())
	if not down_hit.is_empty():
		print("  down pos: ", down_hit.position, " normal: ", down_hit.normal, " collider: ", down_hit.collider.name)
		var ledge_y: float = down_hit.position.y
		# Wall ray 10cm below ledge surface
		var wall_from: Vector3 = Vector3(actor.global_position.x, ledge_y - 0.10, 0.0)
		var wall_to: Vector3 = Vector3(actor.global_position.x + f * 0.75, ledge_y - 0.10, 0.0)
		var q_wall := PhysicsRayQueryParameters3D.create(wall_from, wall_to)
		q_wall.exclude = [actor.get_rid()]
		var wall_hit: Dictionary = space.intersect_ray(q_wall)
		print("Wall hit: ", not wall_hit.is_empty())
		if not wall_hit.is_empty():
			print("  wall pos: ", wall_hit.position, " normal: ", wall_hit.normal)
			var rel_h: float = ledge_y - actor.global_position.y
			print("  rel_h: ", rel_h)
	quit(0)
