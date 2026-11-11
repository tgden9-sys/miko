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
		var min_pt := Vector3(999, 999, 999)
		var max_pt := Vector3(-999, -999, -999)
		for v in range(mdt.get_vertex_count()):
			var pos := mdt.get_vertex(v)
			min_pt.x = minf(min_pt.x, pos.x)
			min_pt.y = minf(min_pt.y, pos.y)
			min_pt.z = minf(min_pt.z, pos.z)
			max_pt.x = maxf(max_pt.x, pos.x)
			max_pt.y = maxf(max_pt.y, pos.y)
			max_pt.z = maxf(max_pt.z, pos.z)
		print("MOD02 Bounds Min: ", min_pt, " Max: ", max_pt)
	quit(0)
