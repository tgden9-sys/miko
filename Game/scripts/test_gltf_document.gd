@tool
extends SceneTree

func _init() -> void:
	print("Testing GLTFDocument loading...")
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var err := gltf.append_from_file("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb", state)
	print("append_from_file mod02 err: ", err)
	if err == OK:
		var node: Node = gltf.generate_scene(state)
		print("Generated scene successfully for mod02! Node: ", node.name, " class: ", node.get_class())
		for child in node.get_children():
			print("  Child: ", child.name, " class: ", child.get_class())
			if child is VisualInstance3D:
				var aabb: AABB = child.get_aabb() if child is GeometryInstance3D else AABB()
				print("    AABB: pos=", aabb.position, " size=", aabb.size)
	else:
		print("ERROR append_from_file failed for mod02: ", err)
		
	var state2 := GLTFState.new()
	var err2 := gltf.append_from_file("res://models/environment/modular_platform/mod04_catwalk_deck_optimized.glb", state2)
	print("append_from_file mod04 err: ", err2)
	if err2 == OK:
		var node2: Node = gltf.generate_scene(state2)
		print("Generated scene successfully for mod04! Node: ", node2.name, " class: ", node2.get_class())
		for child in node2.get_children():
			print("  Child: ", child.name, " class: ", child.get_class())
			if child is VisualInstance3D:
				var aabb: AABB = child.get_aabb() if child is GeometryInstance3D else AABB()
				print("    AABB: pos=", aabb.position, " size=", aabb.size)
	else:
		print("ERROR append_from_file failed for mod04: ", err2)
	quit(0)
