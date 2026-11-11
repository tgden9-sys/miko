extends Node3D
## Shared cutout foliage + two instanced grating draws. No collision or AI.
var foliage:StandardMaterial3D
var foliage_variants:Array[StandardMaterial3D]=[]
var painted_facades:=false
var clean_style:=false
## A material/lens finish on the existing bridge; keeps the original geometry.
var enhanced_finish:=true
var bridge_enabled:=true
func _ready()->void:
	name="SurfaceDetailLayers"
	foliage=StandardMaterial3D.new()
	foliage.albedo_texture=preload("res://art/tutorial/ortho_materials/trailing_ivy.png")
	foliage.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	foliage.alpha_scissor_threshold=0.38
	foliage.cull_mode=BaseMaterial3D.CULL_DISABLED
	foliage.roughness=0.95
	foliage.albedo_color=Color(0.84,0.90,0.78)
	foliage.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	foliage_variants.append(foliage)
	for file:String in ["ivy_sparse.png","moss_short.png"]:
		var variant:=foliage.duplicate() as StandardMaterial3D
		variant.albedo_texture=load("res://art/tutorial/ortho_materials/"+file)
		foliage_variants.append(variant)
	for i in range(10):
		if i==5 and bridge_enabled:continue
		# Leave service boxes and lights legible; clusters inhabit selected joints.
		_ivy(i*6+0.55+float(i%3)*0.08,0.88,1.35,i%2==1,i%3)
		_ivy(i*6+4.45-float(i%2)*0.12,1.05,1.65,i%3==1,(i+1)%3)
		if not painted_facades:
			_lamp_pool(Vector3(i*6+0.9,-1.0,2.05),0.75,1.65)
			_lamp_pool(Vector3(i*6+4.2,-1.0,2.05),0.75,1.65)
	if bridge_enabled:
		var bridge_energy:=0.62 if enhanced_finish else 0.9
		var bridge_radius:=1.6 if enhanced_finish else 1.8
		_lamp_pool(Vector3(30.4,-0.45,1.85),bridge_energy,bridge_radius)
		_lamp_pool(Vector3(35.6,-0.45,1.85),bridge_energy,bridge_radius)
		_ivy(30.05,0.44,1.20,true,1)
		_ivy(35.95,0.42,1.05,false,2)
		_grating()
		_bridge_trim()
	if enhanced_finish and not clean_style:
		if bridge_enabled:_bridge_structure_finish()
		_lamp_lenses()

func _lamp_pool(at:Vector3,energy:float,radius:float)->void:
	var light:=OmniLight3D.new();light.position=at
	light.light_color=Color("ffb263");light.light_energy=energy
	light.omni_range=radius;light.omni_attenuation=1.8 if enhanced_finish else 1.5;light.shadow_enabled=false
	add_child(light);light.add_to_group("miko8_budget_visual");light.set_meta("budget_half_width",radius)

func _ivy(x:float,width:float,height:float,flip:bool,variant:=0)->void:
	if clean_style:return
	if variant==2:height=0.48;width*=1.2
	var plant:=MeshInstance3D.new();var q:=QuadMesh.new();q.size=Vector2(width,height)
	plant.mesh=q;plant.position=Vector3(x,0.10-height/2,1.76)
	if flip:plant.scale.x=-1
	plant.material_override=foliage_variants[variant]
	plant.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Keep the cutout's true bounds, including its offset in front of the deck.
	add_child(plant)

func _grating()->void:
	var steel:Material
	if enhanced_finish and not clean_style:
		steel=_steel_finish(Color("60615f"),0.26,0.86)
	else:
		var original:=StandardMaterial3D.new()
		original.albedo_color=Color("b4aa93");original.metallic=0.55;original.roughness=0.65
		if not clean_style:original.albedo_texture=preload("res://art/tutorial/ortho_materials/painted_steel.png")
		original.uv1_triplanar=true;original.uv1_world_triplanar=true
		original.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		steel=original
	var cross:=BoxMesh.new();cross.size=Vector3(0.012,0.012,2.69)
	cross.material=steel
	_batch(cross,108,Vector3(30.04,0.035,0),Vector3(0.055,0,0))
	var lengthwise:=BoxMesh.new();lengthwise.size=Vector3(5.94,0.012,0.012)
	lengthwise.material=steel
	_batch(lengthwise,49,Vector3(33,0.037,-1.32),Vector3(0,0,0.055))

func _bridge_trim()->void:
	var edge:=StandardMaterial3D.new();edge.albedo_color=Color("796f5b")
	edge.metallic=0.65;edge.roughness=0.58
	if enhanced_finish and not clean_style:
		edge.albedo_color=Color("646762");edge.metallic=0.38;edge.roughness=0.79
		edge.metallic_specular=0.28
	var fastener:=edge
	if enhanced_finish and not clean_style:
		fastener=edge.duplicate() as StandardMaterial3D
		fastener.albedo_color=Color("908776");fastener.metallic=0.52;fastener.roughness=0.68
	var paint:=StandardMaterial3D.new();paint.albedo_color=Color("333d43")
	paint.metallic=0.5;paint.roughness=0.82
	for z:float in [-1.36,1.36]:_box(Vector3(33,0.034,z),Vector3(5.94,0.022,0.045),edge)
	for x:float in [30.04,31.5,33,34.5,35.96]:
		_box(Vector3(x,0.035,0),Vector3(0.045,0.018,2.69),edge)
	var bolt:=CylinderMesh.new();bolt.top_radius=0.022;bolt.bottom_radius=0.022
	bolt.height=0.014;bolt.radial_segments=6;bolt.rings=1;bolt.material=fastener
	_batch(bolt,12,Vector3(30.18,0.052,1.25),Vector3(0.51,0,0))
	_batch(bolt,12,Vector3(30.18,0.052,-1.25),Vector3(0.51,0,0))
	for x:float in [31,33,35]:
		_box(Vector3(x,-1.04,1.355),Vector3(0.29,0.20,0.022),paint)
		for offset:Vector2 in [Vector2(-0.075,0.035),Vector2(0.075,0.035),Vector2(0,-0.055)]:
			var head:=MeshInstance3D.new();head.mesh=bolt
			head.position=Vector3(x+offset.x,-1.04+offset.y,1.377)
			head.rotation.x=PI/2;head.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(head);head.add_to_group("miko8_budget_visual");head.set_meta("budget_half_width",0.04)

func _steel_finish(tint:Color,metal:float,rough:float,vertex_detail:=false)->ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/miko8_bridge_steel.gdshader")
	material.set_shader_parameter("base_color",tint)
	material.set_shader_parameter("metal",metal)
	material.set_shader_parameter("roughness",rough)
	material.set_shader_parameter("use_vertex_detail",vertex_detail)
	material.set_shader_parameter("wear",preload("res://art/tutorial/ortho_materials/painted_steel.png"))
	return material

func _bridge_structure_finish()->void:
	# Only the existing sixth bridge module. Concrete, painted fronts and rails
	# on other modules retain their accepted materials and placement.
	var bridge:=get_parent().get_node_or_null("06_bridge")
	if not bridge:return
	var materials:Dictionary={}
	for mesh:MeshInstance3D in bridge.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original:=mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if not original or original.emission_enabled:continue
			if original.metallic<=0.3:continue
			if not materials.has(original):
				var label:=original.resource_name.to_lower()
				if "bolt" in label:
					var fastener:=original.duplicate() as StandardMaterial3D
					fastener.vertex_color_use_as_albedo=false
					fastener.albedo_color=Color("908776")
					fastener.metallic=0.52;fastener.roughness=0.68
					materials[original]=fastener
				else:
					var tint:=Color("444646")
					if "rust" in label:tint=Color("514d47")
					materials[original]=_steel_finish(tint,0.34,0.83,true)
			mesh.set_surface_override_material(surface,materials[original])

func _lamp_lenses()->void:
	# Thin real lenses sit inside the existing head fronts. No halo cards or
	# extra lights: their illumination is supplied by the existing lamp pools.
	var glass:=StandardMaterial3D.new()
	glass.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.albedo_color=Color("ffbb71");glass.roughness=0.72
	glass.emission_enabled=true;glass.emission=Color("ffad55")
	glass.emission_energy_multiplier=0.45
	for i in range(11):
		# The exported head's front plane is Z=-.35, Y=2.48..2.62.
		# Keep the lens clear of that lip in the elevated orthographic view.
		_box(Vector3(float(i)*6.0,2.565,-0.295),Vector3(0.37,0.055,0.018),glass)
	if bridge_enabled:
		for x:float in [30.4,35.6]:
			_box(Vector3(x,-0.49,1.488),Vector3(0.21,0.045,0.012),glass)

func _box(at:Vector3,size:Vector3,material:Material)->void:
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size;box.material=material
	mesh.mesh=box;mesh.position=at;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh);mesh.add_to_group("miko8_budget_visual");mesh.set_meta("budget_half_width",size.x/2)

func _batch(mesh:Mesh,count:int,start:Vector3,step:Vector3)->void:
	var node:=MultiMeshInstance3D.new();var instances:=MultiMesh.new()
	instances.transform_format=MultiMesh.TRANSFORM_3D;instances.mesh=mesh
	instances.instance_count=count
	for i in range(count):instances.set_instance_transform(i,Transform3D(Basis.IDENTITY,start+step*i))
	node.multimesh=instances;node.position=Vector3(33,0,0)
	# Keep instance transforms local so the budget centre is the actual bridge.
	for i in range(count):instances.set_instance_transform(i,Transform3D(Basis.IDENTITY,start+step*i-Vector3(33,0,0)))
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node);node.add_to_group("miko8_budget_visual");node.set_meta("budget_half_width",3.0)
