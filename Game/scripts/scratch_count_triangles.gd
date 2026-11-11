@tool
extends SceneTree

func _init() -> void:
	var scene = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(scene)
	var actor = scene.actor
	print("Actor model_path: ", actor.model_path)
	var actor_tris := 0
	for m in actor.find_children("*", "MeshInstance3D", true, false):
		if m.mesh:
			for s in range(m.mesh.get_surface_count()):
				var arrays = m.mesh.surface_get_arrays(s)
				if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] != null:
					actor_tris += arrays[Mesh.ARRAY_INDEX].size() / 3
				elif arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] != null:
					actor_tris += arrays[Mesh.ARRAY_VERTEX].size() / 3
	print("Actor total triangles: ", actor_tris)
	
	var total_tris := 0
	var total_meshes := 0
	for m in scene.find_children("*", "MeshInstance3D", true, false):
		total_meshes += 1
		if m.mesh:
			for s in range(m.mesh.get_surface_count()):
				var arrays = m.mesh.surface_get_arrays(s)
				if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] != null:
					total_tris += arrays[Mesh.ARRAY_INDEX].size() / 3
				elif arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] != null:
					total_tris += arrays[Mesh.ARRAY_VERTEX].size() / 3
	print("Scene total MeshInstance3D nodes: ", total_meshes, " total triangles: ", total_tris)
	quit()
