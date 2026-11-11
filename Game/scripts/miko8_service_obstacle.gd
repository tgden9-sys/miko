extends StaticBody3D
## Reusable Trellis workshop. Pivot sits at the target's 1.25m aim height.
const WIDTH:=6.4
const BASE_SINK:=.025
const HEIGHT:=3.947-BASE_SINK
const DEPTH:=3.0
@export var chargeable:=true
@export_range(.5,1.5) var height_scale:=1.0
var polarity:=0
var charge_remaining:=0.0
var is_locked_on:=false
var charge_materials:Array[ShaderMaterial]=[]
var indicator:StandardMaterial3D
var status_light:OmniLight3D
func _ready()->void:
	collision_layer=1;collision_mask=1;add_to_group("tutorial_solids")
	if chargeable:add_to_group("miko8_charge_targets")
	var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(WIDTH,HEIGHT*height_scale,DEPTH)
	collider.shape=shape;collider.position=Vector3(0,HEIGHT*height_scale*.5-1.25,0);add_child(collider)
	_roof_rim_collision()
	var model:Node3D=preload("res://models/environment/workshop/workshop.glb").instantiate()
	model.name="WorkshopModel";model.scale.y=height_scale;model.position.y=-1.25-BASE_SINK*height_scale;add_child(model)
	model.add_to_group("miko8_budget_visual");model.set_meta("budget_half_width",WIDTH*.5)
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		mesh.layers=4 # Architecture gets neutral courtyard lighting, rather than blue suit light.
		for surface in range(mesh.mesh.get_surface_count()):
			var original:=mesh.get_active_material(surface) as StandardMaterial3D
			if not original:continue
			var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_loader.gdshader")
			paint.set_shader_parameter("base_texture",original.albedo_texture);paint.set_shader_parameter("base_color",original.albedo_color)
			if original.normal_texture:paint.set_shader_parameter("normal_texture",original.normal_texture)
			if original.metallic_texture:paint.set_shader_parameter("metal_rough_texture",original.metallic_texture)
			paint.set_shader_parameter("metallic_factor",original.metallic);paint.set_shader_parameter("roughness_factor",original.roughness)
			paint.set_shader_parameter("normal_scale",original.normal_scale)
			paint.set_shader_parameter("grounding_amount",.32)
			mesh.set_surface_override_material(surface,paint);charge_materials.append(paint)
	# The source's green side receiver is hidden in a strictly side-on view.
	# A small front repeater makes its state readable from the gameplay camera.
	var mount:=StandardMaterial3D.new();mount.albedo_color=Color("343b3b");mount.metallic=.4;mount.roughness=.8
	indicator=StandardMaterial3D.new();indicator.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	if chargeable:
		_box("ReceiverRepeater",Vector3(-2.73,1.30,1.515),Vector3(.13,.34,.045),mount)
		_box("ReceiverStatusStrip",Vector3(-2.73,1.30,1.543),Vector3(.028,.23,.012),indicator)
	for at:Vector3 in [Vector3(-2.27,3.35,1.7),Vector3(1.22,3.87,1.7)]:
		var lamp:=OmniLight3D.new();lamp.position=Vector3(at.x,at.y*height_scale-1.25,at.z)
		lamp.light_color=Color("ffc37d");lamp.light_energy=.5;lamp.omni_range=2.2;lamp.shadow_enabled=false;add_child(lamp)
	status_light=OmniLight3D.new();status_light.position=Vector3(-2.73,1.3*height_scale-1.25,1.7)
	status_light.omni_range=1.;status_light.light_energy=.12 if chargeable else 0.;status_light.shadow_enabled=false;add_child(status_light)
	_update_indicator()
	_contact_footprint()
func _roof_rim_collision()->void:
	# Dimensions/top heights are ray-measured from the supplied mesh.
	# All pieces follow the same vertical scaling/sink as the visible roof.
	for side:float in [-1.,1.]:
		_rim_piece("SideRoofRim",Vector2(side*2.935,0),Vector2(.39,2.46),4.122,.03)
		_rim_piece("FrontBackRoofRim",Vector2(0,side*1.33),Vector2(5.50,.20),4.120,.025)
		for end:float in [-1.,1.]:
			_rim_piece("RoofCornerCap",Vector2(side*2.97,end*1.34),Vector2(.42,.28),4.187,.025)
func _rim_piece(label:String,centre:Vector2,size:Vector2,source_top:float,bevel:float)->void:
	var vertices:=PackedVector3Array()
	var top:float=source_top-BASE_SINK
	for corner:Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
		var outer:=centre+corner*size*.5
		var inset:=centre+corner*(size*.5-Vector2.ONE*bevel)
		vertices.append(Vector3(outer.x,HEIGHT*height_scale-1.25,outer.y))
		vertices.append(Vector3(outer.x,(top-bevel)*height_scale-1.25,outer.y))
		vertices.append(Vector3(inset.x,top*height_scale-1.25,inset.y))
	var shape:=ConvexPolygonShape3D.new();shape.points=vertices
	var collider:=CollisionShape3D.new();collider.name=label;collider.shape=shape;add_child(collider)
func _contact_footprint()->void:
	# Tight contact shading follows the actual rectangular building footprint,
	# with a soft short falloff onto the paving rather than an oval blob.
	var patch:=MeshInstance3D.new();patch.name="BuildingContactShadow"
	var plane:=PlaneMesh.new();plane.size=Vector2(WIDTH+1.2,DEPTH+1.2);patch.mesh=plane
	var material:=ShaderMaterial.new();material.shader=preload("res://shaders/miko8_building_contact.gdshader")
	material.set_shader_parameter("footprint",Vector2(WIDTH,DEPTH));material.set_shader_parameter("plane_size",plane.size)
	patch.material_override=material;patch.position=Vector3(0,-1.25+.008,0)
	patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(patch)
	patch.add_to_group("miko8_budget_visual");patch.set_meta("budget_half_width",(WIDTH+1.2)*.5)
func _box(label:String,at:Vector3,size:Vector3,material:Material)->void:
	var visual:=MeshInstance3D.new();visual.name=label;var mesh:=BoxMesh.new();mesh.size=Vector3(size.x,size.y*height_scale,size.z)
	visual.mesh=mesh;visual.material_override=material;visual.position=Vector3(at.x,at.y*height_scale-1.25,at.z);add_child(visual)
func set_locked_on(active:bool,_point:Vector3,_color:Color)->void:
	is_locked_on=active
	if active and polarity!=0:charge_remaining=15.0
	_update_indicator()
func lock_in_color(color:Color)->void:
	if not chargeable:return
	polarity=1 if color.r>color.b else 2;charge_remaining=15.0;is_locked_on=false;_update_indicator()
func neutralize()->void:
	polarity=0;charge_remaining=0.0;_update_indicator()
func _update_indicator()->void:
	for paint in charge_materials:
		paint.set_shader_parameter("polarity",polarity)
		paint.set_shader_parameter("targeting",1.0 if is_locked_on else 0.0)
		paint.set_shader_parameter("target_color",Color("ff394d") if polarity==1 else Color("369fff") if polarity==2 else Color("57b890"))
	var color:=Color("ff394d") if polarity==1 else Color("369fff") if polarity==2 else Color("57b890")
	indicator.albedo_color=color;status_light.light_color=color
func _physics_process(delta:float)->void:
	if polarity==0:return
	charge_remaining-=delta
	if charge_remaining<=0:neutralize()
