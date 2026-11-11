@tool
extends SceneTree

func _init() -> void:
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var err := gltf.append_from_file("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb", state)
	if err == OK:
		var scene: Node = gltf.generate_scene(state)
		var mesh_inst: MeshInstance3D = scene.get_child(0) as MeshInstance3D
		var dup: MeshInstance3D = mesh_inst.duplicate()
		print("Duplicated mesh instance successfully: ", dup, " mesh: ", dup.mesh)
	quit(0)
