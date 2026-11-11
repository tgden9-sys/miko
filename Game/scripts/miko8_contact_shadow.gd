extends Node3D
var actor:CharacterBody3D
var patch:MeshInstance3D
var material:StandardMaterial3D
var transfer_visibility:=1.0
var bone_foot_l:=-1;var bone_foot_r:=-1;var bones_cached:=false
func _cache_bones()->void:
	if not actor or not actor.skeleton:return
	bone_foot_l=actor.skeleton.find_bone("DEF-foot.L");bone_foot_r=actor.skeleton.find_bone("DEF-foot.R")
	bones_cached=true
func _ready()->void:
	patch=MeshInstance3D.new()
	patch.top_level=true
	var plane:=PlaneMesh.new()
	plane.size=Vector2(0.9,0.65)
	patch.mesh=plane
	var gradient:=Gradient.new()
	gradient.set_color(0,Color(0,0,0,0.38))
	gradient.set_color(1,Color(0,0,0,0))
	var texture:=GradientTexture2D.new()
	texture.gradient=gradient
	texture.width=64;texture.height=64
	texture.fill=GradientTexture2D.FILL_RADIAL
	texture.fill_from=Vector2(0.5,0.5)
	texture.fill_to=Vector2(1.0,0.5)
	material=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture=texture
	patch.material_override=material
	patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(patch)
func _physics_process(_delta:float)->void:
	if transfer_visibility<=0.001 or actor.state.begins_with("Climb") or actor.state=="Clip review":patch.visible=false;return
	var query:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*0.15,actor.global_position-Vector3.UP*6,1)
	query.exclude=[actor.get_rid()]
	var hit:=actor.get_world_3d().direct_space_state.intersect_ray(query)
	patch.visible=not hit.is_empty()
	if hit.is_empty():return
	patch.global_position=hit.position+Vector3.UP*0.008
	var lowest:=INF
	for side:String in ["L","R"]:
		if not bones_cached:_cache_bones()
		var foot:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(bone_foot_l if side=="L" else bone_foot_r).origin)
		lowest=minf(lowest,foot.y-0.10)
	var height:=maxf(0,lowest-hit.position.y)
	material.albedo_color=Color(1,1,1,transfer_visibility/(1+height*2.5))
	patch.scale=Vector3.ONE*(1+height*0.3)

