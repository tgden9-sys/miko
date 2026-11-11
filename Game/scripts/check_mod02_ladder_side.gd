@tool
extends SceneTree

func _init() -> void:
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var err := gltf.append_from_file("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb", state)
	if err == OK:
		var node: Node = gltf.generate_scene(state)
		var mesh_inst: MeshInstance3D = node.get_child(0) as MeshInstance3D
		var m: Mesh = mesh_inst.mesh
		var mdt := MeshDataTool.new()
		mdt.create_from_surface(m, 0)
		var pos_z_count := 0
		var neg_z_count := 0
		for v in range(mdt.get_vertex_count()):
			var pos := mdt.get_vertex(v)
			if pos.z > 0.25:
				pos_z_count += 1
			elif pos.z < -0.25:
				neg_z_count += 1
		print("MOD02 vertices with z > 0.25: ", pos_z_count, ", z < -0.25: ", neg_z_count)
	quit(0)
