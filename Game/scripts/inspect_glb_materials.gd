@tool
extends SceneTree

func _init() -> void:
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var err := gltf.append_from_file("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb", state)
	if err == OK:
		var node: Node = gltf.generate_scene(state)
		_inspect(node, "MOD02")
		
	var state2 := GLTFState.new()
	var err2 := gltf.append_from_file("res://models/environment/modular_platform/mod04_catwalk_deck_optimized.glb", state2)
	if err2 == OK:
		var node2: Node = gltf.generate_scene(state2)
		_inspect(node2, "MOD04")
	quit(0)

func _inspect(node: Node, label: String) -> void:
	print("--- ", label, " ---")
	for child in node.get_children():
		print("Child: ", child.name, " class: ", child.get_class())
		if child is MeshInstance3D:
			print("Mesh: ", child.mesh)
			for i in range(child.mesh.get_surface_count()):
				var mat: Material = child.mesh.surface_get_material(i)
				print(" Surface ", i, " mat: ", mat)
				if mat is StandardMaterial3D:
					print("   albedo_color: ", mat.albedo_color)
					print("   albedo_texture: ", mat.albedo_texture)
					print("   roughness: ", mat.roughness)
					print("   metallic: ", mat.metallic)
					print("   normal_texture: ", mat.normal_texture)
