extends Node3D
const ORDER:=["concrete","concrete","concrete","concrete","concrete","bridge","concrete","concrete","concrete","concrete"]
const MODULE_LENGTH:=6.0
const SERVICE_VARIANTS:=[0,1,2,0,1,-1,2,0,1,2]
const USE_PAINTED_FACADES:=true
const FACADE_LIBRARY=preload("res://scripts/miko8_facade_library.gd")
const MINIATURE_FACADE=preload("res://scripts/miko8_miniature_facade.gd")
var modules:Array[Node3D]=[]
var material_cache:Dictionary={}
var clean_style:=false
var diorama_style:=false
var enhanced_finish:=true
var enhanced_paving:=false
var miniature_facades:=false
var continuous_yard:=false
var room_length:=60.0
var module_order:Array[String]=[]
func _ready()->void:
	name="OrthographicRepeatedGround"
	module_order.assign(ORDER)
	if continuous_yard:module_order[5]="concrete"
	if continuous_yard and not is_equal_approx(room_length,60.0):
		module_order.resize(ceili(room_length/MODULE_LENGTH));module_order.fill("concrete")
	var assets:Dictionary={}
	for kind in ["concrete","concrete_clean","bridge","connector"]:
		assets[kind]=load("res://models/environment/ortho_test/"+kind+".glb")
	for i in range(module_order.size()):
		var service_variant:int=SERVICE_VARIANTS[i%SERVICE_VARIANTS.size()]
		var type:String=module_order[i] if clean_style else ("concrete_clean" if module_order[i]=="concrete" and (USE_PAINTED_FACADES or service_variant>0) else module_order[i])
		var module:Node3D=assets[type].instantiate()
		module.name="%02d_%s" % [i+1,module_order[i]];module.position.x=i*MODULE_LENGTH;add_child(module)
		module.add_to_group("miko8_budget_visual");module.set_meta("budget_half_width",MODULE_LENGTH*0.5+4.0)
		_prepare(module,3.0,module_order[i]=="bridge");modules.append(module)
		if module_order[i]=="concrete" and USE_PAINTED_FACADES and not clean_style:_facade(module,i)
		if service_variant>0 and not USE_PAINTED_FACADES and not clean_style:
			var services:=preload("res://scripts/miko8_service_bay.gd").new()
			services.variant=service_variant-1;module.add_child(services)
		if module_order[i]=="bridge":
			for mesh:MeshInstance3D in module.find_children("*","MeshInstance3D",true,false):
				mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for i in range(module_order.size()+1):
		var connector:Node3D=assets.connector.instantiate();connector.position.x=i*MODULE_LENGTH;add_child(connector)
		connector.set_meta("ortho_connector",true)
		connector.add_to_group("miko8_budget_visual");connector.set_meta("budget_half_width",2.0)
		_prepare(connector,0.5)
		var light:=OmniLight3D.new();light.position=Vector3(i*MODULE_LENGTH,2.1,-0.55)
		light.light_color=Color("ffbd79");light.light_energy=1.4 if clean_style else 2.5;light.omni_range=4.2;light.shadow_enabled=false;add_child(light)
		light.add_to_group("miko8_budget_visual");light.set_meta("budget_half_width",4.2)
		if clean_style:_post_lens(float(i)*MODULE_LENGTH)
	var floor:=StaticBody3D.new();floor.name="Continuous60mFloor" if is_equal_approx(room_length,60.0) else "ContinuousRoomFloor"
	var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(room_length,0.5,2.8)
	collision.shape=box;floor.position=Vector3(room_length*.5,-0.25,0);floor.add_child(collision);add_child(floor)
	floor.add_to_group("tutorial_solids")
	for x:float in [-0.25,room_length+.25]:
		var stop:=StaticBody3D.new();stop.position=Vector3(x,2,0)
		var shape:=CollisionShape3D.new();var wall:=BoxShape3D.new();wall.size=Vector3(0.5,5,4)
		shape.shape=wall;stop.add_child(shape);add_child(stop)
	print("REPETITION_GROUND_READY order=",module_order)
	var details:=preload("res://scripts/miko8_ortho_surface_details.gd").new()
	details.painted_facades=USE_PAINTED_FACADES and not clean_style;details.clean_style=clean_style
	details.enhanced_finish=enhanced_finish;details.bridge_enabled=not continuous_yard;add_child(details)

func _post_lens(x:float)->void:
	var lens:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.37,.055,.025)
	lens.mesh=box;lens.position=Vector3(x,2.52,-.338)
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color("ffd098");lens.material_override=mat;lens.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lens);lens.add_to_group("miko8_budget_visual");lens.set_meta("budget_half_width",.3)
	var halo:=MeshInstance3D.new();var q:=QuadMesh.new();q.size=Vector2(.8,.5);halo.mesh=q
	halo.position=Vector3(x,2.52,-.31)
	var glow:=ShaderMaterial.new();glow.shader=preload("res://shaders/miko_practical_halo.gdshader")
	glow.set_shader_parameter("strength",.16);halo.material_override=glow
	halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(halo)
	halo.add_to_group("miko8_budget_visual");halo.set_meta("budget_half_width",.5)

func _facade(module:Node3D,slot:int)->void:
	var face:=MeshInstance3D.new();face.name="PaintedFoundationFront"
	var quad:=QuadMesh.new();quad.size=Vector2(6,2)
	face.mesh=quad;face.position=Vector3(3,-1.25,1.505)
	var miniature_material:ShaderMaterial=MINIATURE_FACADE.material() if miniature_facades else null
	if miniature_material:
		face.material_override=miniature_material
		face.set_meta("facade_id",MINIATURE_FACADE.ID)
		face.set_meta("miniature_facade",true)
	else:
		var index:int=FACADE_LIBRARY.SEQUENCE[slot%FACADE_LIBRARY.SEQUENCE.size()]
		if index<0:index=9
		face.material_override=FACADE_LIBRARY.material(index);face.set_meta("facade_id",index)
	face.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	module.add_child(face);face.add_to_group("miko8_budget_visual");face.set_meta("budget_half_width",3.0)

func _prepare(instance:Node3D,half:float,baked_detail:=false)->void:
	for mesh:MeshInstance3D in instance.find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.add_to_group("miko8_budget_visual");mesh.set_meta("budget_half_width",half)
		# Bounds in each GLB use a 0..6 module origin, not its visual centre.
		mesh.set_meta("budget_half_width",half+3.0)
		for surface in range(mesh.mesh.get_surface_count()):
			var original:=mesh.get_active_material(surface) as StandardMaterial3D
			if not original:continue
			if enhanced_paving and "paving" in original.resource_name.to_lower():
				var paving_key:="paving_"+str(original.get_instance_id())
				if not material_cache.has(paving_key):
					var paving:=ShaderMaterial.new();paving.shader=preload("res://shaders/miko8_restored_paving.gdshader")
					paving.set_shader_parameter("grain",preload("res://art/tutorial/ortho_materials/concrete.png"));material_cache[paving_key]=paving
				mesh.set_surface_override_material(surface,material_cache[paving_key]);continue
			if diorama_style:
				mesh.set_surface_override_material(surface,preload("res://scripts/miko8_diorama_materials.gd").convert(original,baked_detail))
				mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				continue
			if clean_style:
				mesh.set_surface_override_material(surface,preload("res://scripts/miko8_cel_materials.gd").convert(original,baked_detail))
				continue
			var key:=original
			if original.emission_enabled:
				var glass:=original.duplicate() as StandardMaterial3D
				glass.vertex_color_use_as_albedo=false
				glass.emission=Color("ffb75c");glass.emission_energy_multiplier=0.8
				mesh.set_surface_override_material(surface,glass)
				continue
			var label:=original.resource_name.to_lower()
			if "moss" in label or "ivy" in label or "joints" in label:continue
			if "bolt edges" in label:
				var fastener:=original.duplicate() as StandardMaterial3D
				fastener.vertex_color_use_as_albedo=false
				fastener.roughness=0.52;fastener.metallic=0.7
				mesh.set_surface_override_material(surface,fastener)
				continue
			if not material_cache.has(key):
				var material:=ShaderMaterial.new();material.shader=preload("res://shaders/ortho_preview_wear.gdshader")
				material.set_shader_parameter("base_color",original.albedo_color)
				material.set_shader_parameter("metal",original.metallic)
				material.set_shader_parameter("use_vertex_detail",baked_detail)
				var is_metal:=original.metallic>0.3
				material.set_shader_parameter("wear",load("res://art/tutorial/ortho_materials/"+("painted_steel.png" if is_metal else "concrete.png")))
				material.set_shader_parameter("texture_scale",0.65 if is_metal else 0.5)
				material.set_shader_parameter("bump_strength",0.0005 if is_metal else 0.001)
				material_cache[key]=material
			mesh.set_surface_override_material(surface,material_cache[key])
