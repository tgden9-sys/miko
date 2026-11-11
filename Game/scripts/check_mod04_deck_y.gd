@tool
extends SceneTree

func _init() -> void:
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var err := gltf.append_from_file("res://models/environment/modular_platform/mod04_catwalk_deck_optimized.glb", state)
	if err == OK:
		var node: Node = gltf.generate_scene(state)
		var mesh_inst: MeshInstance3D = node.get_child(0) as MeshInstance3D
		var m: Mesh = mesh_inst.mesh
		var mdt := MeshDataTool.new()
		mdt.create_from_surface(m, 0)
		var min_y := 999.0
		var max_y := -999.0
		var y_vals: Array[float] = []
		for v in range(mdt.get_vertex_count()):
			var pos := mdt.get_vertex(v)
			min_y = minf(min_y, pos.y)
			max_y = maxf(max_y, pos.y)
			y_vals.append(pos.y)
		y_vals.sort()
		print("MOD04 Min Y: ", min_y, " Max Y: ", max_y)
		print("25th percentile Y: ", y_vals[int(y_vals.size() * 0.25)])
		print("50th percentile Y: ", y_vals[int(y_vals.size() * 0.50)])
		print("75th percentile Y: ", y_vals[int(y_vals.size() * 0.75)])
	quit(0)
