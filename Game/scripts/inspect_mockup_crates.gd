@tool
extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/miko8_side_on_mockup.tscn")
	var mockup: Node = scene.instantiate()
	root.add_child(mockup)
	await process_frame
	for crate in mockup.find_children("*", "CollisionObject3D", true, false):
		if "crate" in crate.name.to_lower():
			print("Crate: ", crate.name, " class: ", crate.get_class(), " pos: ", crate.global_position, " layer: ", crate.collision_layer)
			for col in crate.find_children("*", "CollisionShape3D", true, false):
				print("  shape: ", col.shape, " pos: ", col.position)
				if col.shape is BoxShape3D:
					print("    box size: ", col.shape.size)
	quit(0)
