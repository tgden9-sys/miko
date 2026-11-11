extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_file("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb", state)
	var scene = gltf.generate_scene(state)
	var mesh_inst: MeshInstance3D = scene.get_node("Mesh")
	var arrays = mesh_inst.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	
	var pos_z_count = 0
	var neg_z_count = 0
	var pos_x_count = 0
	var neg_x_count = 0
	for v in verts:
		if v.z > 0.15: pos_z_count += 1
		if v.z < -0.15: neg_z_count += 1
		if v.x > 0.15: pos_x_count += 1
		if v.x < -0.15: neg_x_count += 1
	
	print("Godot vertex distribution:")
	print("  +Z (facing camera): ", pos_z_count)
	print("  -Z (away from camera): ", neg_z_count)
	print("  +X (right): ", pos_x_count)
	print("  -X (left): ", neg_x_count)
	quit(0)
