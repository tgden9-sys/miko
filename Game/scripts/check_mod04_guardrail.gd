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
		var high_y_pos_z := 0
		var high_y_neg_z := 0
		for v in range(mdt.get_vertex_count()):
			var pos := mdt.get_vertex(v)
			if pos.y > 0.6: # Guardrail vertices
				if pos.z > 0:
					high_y_pos_z += 1
				else:
					high_y_neg_z += 1
		print("MOD04 Guardrail vertices at +Z: ", high_y_pos_z, ", at -Z: ", high_y_neg_z)
	quit(0)
