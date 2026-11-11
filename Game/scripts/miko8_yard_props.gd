extends Node3D
@export var build_demo:=true
## Textured prop study in the first screen of the side-on yard.
func _ready()->void:
	if not build_demo:return
	name="NewYardProps"
	var base:=preload("res://scripts/miko8_charge_base.gd").new()
	base.name="FixedChargeBase";base.position=Vector3(5.8,.4,0);add_child(base)
	add_launcher(Vector3(11.8,-.12,0))

func add_launcher(at:Vector3)->StaticBody3D:
	var loader:=_prop("Loader","res://models/props/loader.glb",at,Vector3.ZERO)
	loader.scale=Vector3(.8,.8,.56)
	# Pillars flank the single walking lane in depth. Sink the deck flush with
	# the paving, so crossing it never needs a jump or a controller step-up.
	_box(loader,Vector3(0,.075,0),Vector3(2.2,.15,3.95))
	for z:float in [-1.37,1.37]:
		_box(loader,Vector3(0,.98,z),Vector3(.55,1.74,.60))
	var target:=preload("res://scripts/miko8_loader_charge.gd").new()
	target.position=Vector3(0,.9,0);loader.add_child(target)
	return loader

func _prop(label:String,path:String,at:Vector3,collision_size:Vector3)->StaticBody3D:
	var body:=StaticBody3D.new();body.name=label;body.position=at
	if label=="WoodenCrate":body.set_script(preload("res://scripts/miko8_breakable_crate.gd"))
	body.collision_layer=1;body.collision_mask=1;add_child(body)
	var model:Node3D=load(path).instantiate();body.add_child(model)
	if label=="WoodenCrate":
		var bounds:=AABB();var first:=true
		for visual:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			var box:AABB=(model.global_transform.affine_inverse()*visual.global_transform)*visual.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
		model.scale=Vector3(.8,.8,.8)/bounds.size
	model.add_to_group("miko8_budget_visual");model.set_meta("budget_half_width",2.2)
	if collision_size!=Vector3.ZERO:_box(body,Vector3(0,collision_size.y*.5,0),collision_size)
	var patch:=MeshInstance3D.new();var plane:=PlaneMesh.new()
	plane.size=Vector2(2.2,3.8) if label=="Loader" else Vector2(.94,.94)
	patch.mesh=plane;patch.position.y=.16 if label=="Loader" else .008
	var gradient:=Gradient.new();gradient.set_color(0,Color(0,0,0,.35));gradient.set_color(1,Color(0,0,0,0))
	var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.width=64;texture.height=64
	texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.albedo_texture=texture
	patch.material_override=material;patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;body.add_child(patch)
	return body

func _box(body:StaticBody3D,at:Vector3,size:Vector3)->void:
	var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size
	collider.shape=shape;collider.position=at;body.add_child(collider)
