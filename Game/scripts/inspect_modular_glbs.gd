extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _load_glb(path: String) -> Node3D:
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var err := gltf.append_from_file(path, state)
	if err != OK:
		return null
	return gltf.generate_scene(state)

func _inspect_node(node: Node, depth: int = 0) -> void:
	var indent := "  ".repeat(depth)
	var info := indent + "- " + node.name + " (" + node.get_class() + ")"
	if node is Node3D:
		info += " pos=" + str(node.position) + " rot=" + str(node.rotation_degrees) + " scale=" + str(node.scale)
	if node is MeshInstance3D and node.mesh:
		var aabb: AABB = node.mesh.get_aabb()
		var arrays: Array = node.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var tri_count := indices.size() / 3 if not indices.is_empty() else vertices.size() / 3
		info += "\n" + indent + "  [Mesh] AABB_min=" + str(aabb.position) + " AABB_max=" + str(aabb.position + aabb.size) + " AABB_size=" + str(aabb.size) + " Vertices=" + str(vertices.size()) + " Triangles=" + str(tri_count)
	print(info)
	for child in node.get_children():
		_inspect_node(child, depth + 1)

func _run() -> void:
	print("=== INSPECTING OPTIMIZED MOD02 ===")
	var mod02 = _load_glb("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb")
	if mod02: _inspect_node(mod02)
	print("\n=== INSPECTING OPTIMIZED MOD04 ===")
	var mod04 = _load_glb("res://models/environment/modular_platform/mod04_catwalk_deck_optimized.glb")
	if mod04: _inspect_node(mod04)
	quit(0)
