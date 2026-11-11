extends RefCounted
static var cache:Dictionary={}
static func convert(original:StandardMaterial3D,ao:=false)->Material:
	var key:=str(original.get_instance_id())+str(ao)
	if cache.has(key):return cache[key]
	var label:=original.resource_name.to_lower()
	if original.emission_enabled:
		var glow:=original.duplicate() as StandardMaterial3D
		glow.vertex_color_use_as_albedo=false
		glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color=Color("ffc078") if "lamp" in label else Color("77cbd0")
		glow.emission_energy_multiplier=0.15;cache[key]=glow;return glow
	var col:=original.albedo_color
	if "concrete" in label:col=Color("74818e")
	elif "paving" in label:col=Color("88939c")
	elif "coping" in label:col=Color("a3abb0")
	elif "oxidised" in label:col=Color("344656")
	elif "railing" in label:col=Color("4b5963")
	elif "bolt" in label:col=Color("929b9f")
	elif "joint" in label:col=Color("25313f")
	elif "moss" in label or "ivy" in label:col=Color("3b5c51")
	elif "warning" in label:col=Color("bb874b")
	elif "slate" in label:col=Color("435c70")
	elif "pale concrete" in label:col=Color("6b7880")
	elif "dark steel" in label:col=Color("203141")
	elif "edge metal" in label:col=Color("647986")
	elif "ceramic" in label:col=Color("253c4d")
	elif "amber" in label:col=Color("a77c42")
	var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/miko_cel_surface.gdshader")
	mat.set_shader_parameter("base_color",col)
	mat.set_shader_parameter("metal",original.metallic)
	mat.set_shader_parameter("vertex_ao",ao)
	cache[key]=mat;return mat
