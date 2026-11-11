extends RefCounted
static var cache:Dictionary={}
static func convert(original:StandardMaterial3D,ao:=false)->Material:
	var key:=str(original.get_instance_id())+str(ao)
	if cache.has(key):return cache[key]
	var label:=original.resource_name.to_lower()
	if original.emission_enabled:
		var lamp:=original.duplicate() as StandardMaterial3D
		lamp.vertex_color_use_as_albedo=false;lamp.albedo_color=Color("e0a968")
		lamp.emission=Color("ffbe74");lamp.emission_energy_multiplier=1.2
		cache[key]=lamp;return lamp
	var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/diorama_surface.gdshader")
	var metallic:=0.0;var col:=Color("767777");var strength:=.65;var scale_value:=1.0
	if "paving" in label:col=Color("827f75");strength=.5;scale_value=.8
	elif "coping" in label:col=Color("9a9485");strength=.46
	elif "steel" in label or "railing" in label:col=Color("394450");metallic=.52;strength=.25;scale_value=.9
	elif "bolt" in label:col=Color("9b9688");metallic=.72;strength=.12
	elif "joint" in label:col=Color("232a30");strength=.08
	elif "moss" in label or "ivy" in label:col=Color("48513b");strength=.12
	elif "paint" in label:col=Color("aa8551");strength=.17
	mat.set_shader_parameter("paint_color",col)
	mat.set_shader_parameter("grain",load("res://art/tutorial/ortho_materials/"+("painted_steel.png" if metallic>.3 else "concrete.png")))
	mat.set_shader_parameter("metal",metallic);mat.set_shader_parameter("texture_strength",strength)
	mat.set_shader_parameter("texture_scale",scale_value);mat.set_shader_parameter("vertex_ao",ao)
	mat.set_shader_parameter("trim_rear_rail",ao)
	cache[key]=mat;return mat
