@tool
extends SceneTree

func _init() -> void:
	print("Checking GLB loading in Godot...")
	var tower_scene: PackedScene = load("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb")
	if tower_scene:
		print("Loaded tower scene successfully:", tower_scene)
		var tower_inst: Node = tower_scene.instantiate()
		print("Instantiated tower root:", tower_inst.name, "Class:", tower_inst.get_class())
		_print_children(tower_inst, 1)
	else:
		print("ERROR: Failed to load tower PackedScene!")
		
	var catwalk_scene: PackedScene = load("res://models/environment/modular_platform/mod04_catwalk_deck_optimized.glb")
	if catwalk_scene:
		print("Loaded catwalk scene successfully:", catwalk_scene)
		var catwalk_inst: Node = catwalk_scene.instantiate()
		print("Instantiated catwalk root:", catwalk_inst.name, "Class:", catwalk_inst.get_class())
		_print_children(catwalk_inst, 1)
	else:
		print("ERROR: Failed to load catwalk PackedScene!")
	quit(0)

func _print_children(node: Node, indent: int) -> void:
	var prefix := "  ".repeat(indent)
	for child in node.get_children():
		print(prefix, child.name, " (", child.get_class(), ")")
		if child is VisualInstance3D:
			var aabb: AABB = child.get_aabb() if child is GeometryInstance3D else AABB()
			print(prefix, "  AABB: pos=", aabb.position, " size=", aabb.size)
			if child is MeshInstance3D and child.mesh:
				print(prefix, "  Mesh faces: ", child.mesh.get_faces().size() / 3)
				for i in range(child.mesh.get_surface_count()):
					var mat = child.get_surface_override_material(i)
					if not mat:
						mat = child.mesh.surface_get_material(i)
					print(prefix, "  Surface ", i, " mat: ", mat)
		_print_children(child, indent + 1)
