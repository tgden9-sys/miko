extends RefCounted
static var shared:ShaderMaterial
static func material()->ShaderMaterial:
	if shared:return shared
	shared=ShaderMaterial.new();shared.shader=preload("res://shaders/miko8_shared_concrete.gdshader")
	shared.set_shader_parameter("grain",preload("res://art/tutorial/facade_library/miniature_concrete_repeat_v1.png"))
	return shared
static func apply_to(root:Node3D)->void:
	for visual:MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		if visual.name=="LadderBacking":visual.material_override=material()
		if not visual.mesh:continue
		for surface in range(visual.mesh.get_surface_count()):
			var original:=visual.mesh.surface_get_material(surface) as StandardMaterial3D
			if not original:continue
			var label:=original.resource_name.to_lower()
			if "concrete" in label or "coping" in label:visual.set_surface_override_material(surface,material())
