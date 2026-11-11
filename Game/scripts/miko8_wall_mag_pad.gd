extends StaticBody3D
## A fixed field source: only movable blocks receive forces from it.
const FIELD_RANGE:=200.*1.9/96.
const INTERACTION_RANGE:=FIELD_RANGE*2.
var polarity:=0
var charge_remaining:=0.0
var breakaway_remaining:=0.0
var is_locked_on:=false
var lock_color:=Color.WHITE
var paints:Array[ShaderMaterial]=[]
@export_enum("Wall", "Ceiling") var mount_mode:=0
var edge_indicator:StandardMaterial3D
var held_body:WeakRef
func _ready()->void:
	add_to_group("miko8_charge_targets");add_to_group("miko8_fixed_magnets")
	collision_layer=5;collision_mask=1
	var model:Node3D=preload("res://models/props/mag_pad/mag_pad.glb").instantiate();model.name="MagPadModel"
	model.rotation.z=-PI/2;model.scale=Vector3.ONE*.62;model.position.x=.03;add_child(model)
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var source:=mesh.get_active_material(i) as StandardMaterial3D
			if not source:continue
			var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_loader.gdshader")
			paint.set_shader_parameter("base_texture",source.albedo_texture);paint.set_shader_parameter("base_color",source.albedo_color)
			paint.set_shader_parameter("metallic_factor",0.);paint.set_shader_parameter("roughness_factor",.95)
			mesh.set_surface_override_material(i,paint);paints.append(paint)
	var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.4,1.18,1.18);collider.shape=shape;collider.position.x=.17;add_child(collider)
	# The back plate sits against the wall, with a dark gasket and four anchors.
	_part(Vector3(.005,0,0),Vector3(.045,1.30,1.30),Color("292c2d"))
	for y:float in [-.56,.56]:
		for z:float in [-.56,.56]:_part(Vector3(.04,y,z),Vector3(.065,.075,.075),Color("938b71"))
	if mount_mode==1:
		var strip:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.4,.09,.055);strip.mesh=box;add_child(strip);strip.top_level=true;strip.global_basis=Basis.IDENTITY;strip.global_position=global_position+Vector3(0,-.04,1.15)
		edge_indicator=StandardMaterial3D.new();edge_indicator.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;strip.material_override=edge_indicator;strip.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_update_color()
func _part(at:Vector3,size:Vector3,color:Color)->void:
	var visual:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size;visual.mesh=box;visual.position=at
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.95;visual.material_override=material;add_child(visual)
func set_locked_on(active:bool,_point:Vector3,color:Color)->void:
	is_locked_on=active;lock_color=color
	for paint in paints:paint.set_shader_parameter("targeting",1. if active else 0.);paint.set_shader_parameter("target_color",color)
	if active and polarity!=0:charge_remaining=15.
func lock_in_color(color:Color)->void:
	polarity=1 if color.r>color.b else 2;charge_remaining=15.;set_locked_on(false,Vector3.ZERO,color);_update_color()
func neutralize()->void:
	if held_body and is_instance_valid(held_body.get_ref()):held_body.get_ref().sleeping=false
	held_body=null
	polarity=0;charge_remaining=0.;set_locked_on(false,Vector3.ZERO,Color.WHITE);_update_color()
func _update_color()->void:
	for paint in paints:paint.set_shader_parameter("polarity",polarity)
	if edge_indicator:edge_indicator.albedo_color=Color("ff434e") if polarity==1 else Color("389cff") if polarity==2 else Color("7ebc69")
func can_reach_block(body:Node3D)->bool:
	if mount_mode!=1:return true
	var offset:Vector3=global_position-body.global_position
	return absf(offset.x)<.8 and absf(offset.z)<.6 and offset.y>0. and offset.y<INTERACTION_RANGE
func apply_lift(body:RigidBody3D)->void:
	if polarity==0 or body.polarity==0 or not can_reach_block(body):return
	if polarity==body.polarity:
		body.apply_central_force(Vector3.DOWN*body.mass*12.);return
	held_body=weakref(body)
	var half_height:float=body.get_meta("magnetic_half_height",.4)
	var target_y:float=global_position.y-.37-half_height-.025
	var speed:float=clampf((target_y-body.global_position.y)*2.,-1.,1.2)
	var force:float=clampf(9.8+(speed-body.linear_velocity.y)*8.,0.,24.)
	body.apply_central_force(Vector3.UP*body.mass*force)
func _physics_process(delta:float)->void:
	if polarity==0:return
	charge_remaining=maxf(0.,charge_remaining-delta)
	if charge_remaining<=0.:neutralize()
