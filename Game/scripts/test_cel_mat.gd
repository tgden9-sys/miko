@tool
extends SceneTree

func _init() -> void:
	print("Testing GLTFDocument + Cel Shader...")
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var err := gltf.append_from_file("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb", state)
	if err != OK:
		print("FAILED to load mod02")
		quit(1)
		return
	var tower: Node = gltf.generate_scene(state)
	var tower_mesh_inst: MeshInstance3D = tower.get_child(0) as MeshInstance3D
	var orig_mat: Material = tower_mesh_inst.mesh.surface_get_material(0)
	var tex: Texture2D = null
	if orig_mat is StandardMaterial3D:
		tex = (orig_mat as StandardMaterial3D).albedo_texture
	print("Tower albedo texture:", tex)
	
	var cel_mat := ShaderMaterial.new()
	cel_mat.shader = load("res://shaders/miko8_modular_cel_prop.gdshader")
	cel_mat.set_shader_parameter("use_texture", true)
	cel_mat.set_shader_parameter("base_color", Color(1.0, 1.0, 1.0, 1.0))
	cel_mat.set_shader_parameter("base_texture", tex)
	tower_mesh_inst.material_override = cel_mat
	print("Successfully applied cel shader to tower mesh override!")
	quit(0)
