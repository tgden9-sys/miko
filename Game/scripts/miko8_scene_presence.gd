extends Node3D
## Two instanced draws: drifting air and short-lived foot/ion particles.
var actor:CharacterBody3D
var camera:Camera3D
var rng:=RandomNumberGenerator.new()
var air:MultiMesh
var local:MultiMesh
var motes:Array[Dictionary]=[]
var sparks:Array[Dictionary]=[]
var shadows:Array[MeshInstance3D]=[]
var previous_height:=[1.0,1.0]
var air_time:=0.0
var ion_time:=0.0
var elapsed:=0.0
const AIR_COUNT:=48
const LOCAL_COUNT:=24
var room_length:=32.0
var foot_dust_strength:=1.0
var ambient_air_enabled := true
var skid_dust_time:=0.0
var wall_dust_triggered:=false
var bone_foot_l:=-1;var bone_foot_r:=-1;var bone_toe_l:=-1;var bone_toe_r:=-1;var bone_spine:=-1;var bones_cached:=false
func _cache_bones()->void:
	if not actor or not actor.skeleton:return
	bone_foot_l=actor.skeleton.find_bone("DEF-foot.L");bone_foot_r=actor.skeleton.find_bone("DEF-foot.R")
	bone_toe_l=actor.skeleton.find_bone("DEF-toe.L");bone_toe_r=actor.skeleton.find_bone("DEF-toe.R")
	bone_spine=actor.skeleton.find_bone("DEF-spine.003");bones_cached=true
func set_room_length(length:float)->void:
	var old_length:=room_length;room_length=maxf(length,1.0)
	for mote:Dictionary in motes:mote.p.x=(mote.p.x+2.0)/(old_length+4.0)*(room_length+4.0)-2.0
	for instances:MultiMesh in [air,local]:
		if instances:instances.custom_aabb=AABB(Vector3(-5,-3,-5),Vector3(room_length+12,15,13))

func _ready()->void:
	rng.seed=2841
	air=_batch(AIR_COUNT)
	local=_batch(LOCAL_COUNT)
	for i in range(AIR_COUNT):
		var close:=i>=(AIR_COUNT - 5)
		motes.append({"p":Vector3(rng.randf_range(-2,34),rng.randf_range(0.3,8.7),rng.randf_range(2.5,4.5) if close else rng.randf_range(-1.1,1.8)),"speed":rng.randf_range(0.025,0.09),"size":rng.randf_range(0.065,0.13) if close else rng.randf_range(0.055,0.115),"alpha":rng.randf_range(0.10,0.20) if close else rng.randf_range(0.55,0.90),"phase":rng.randf(),"age":rng.randf_range(0,20),"life":rng.randf_range(24,40),"kind":1.0 if close else 0.0})
	for i in range(LOCAL_COUNT):
		sparks.append({"age":1.0,"life":0.0,"zeroed":true})
		local.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
	for i in range(2):
		var patch:=MeshInstance3D.new()
		var plane:=PlaneMesh.new()
		plane.size=Vector2(0.40,0.28)
		patch.mesh=plane
		var gradient:=Gradient.new()
		gradient.set_color(0,Color(0.012,0.016,0.023,0.60))
		gradient.set_color(1,Color(0.012,0.016,0.023,0))
		var texture:=GradientTexture2D.new()
		texture.gradient=gradient;texture.width=64;texture.height=64
		texture.fill=GradientTexture2D.FILL_RADIAL
		texture.fill_from=Vector2(0.5,0.5);texture.fill_to=Vector2(1,0.5)
		var m:=StandardMaterial3D.new()
		m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture=texture
		patch.material_override=m
		patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(patch)
		shadows.append(patch)

func _batch(count:int)->MultiMesh:
	var node:=MultiMeshInstance3D.new()
	var mesh:=MultiMesh.new()
	mesh.transform_format=MultiMesh.TRANSFORM_3D
	mesh.use_colors=true;mesh.use_custom_data=true
	var quad:=QuadMesh.new();quad.size=Vector2.ONE
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/tutorial_air.gdshader")
	quad.material=material
	mesh.mesh=quad
	mesh.instance_count=count
	mesh.custom_aabb=AABB(Vector3(-5,-3,-5),Vector3(44,15,13))
	node.multimesh=mesh
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return mesh

func _floor(point:Vector3)->Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.2,point-Vector3.UP*2.5,1)
	query.exclude=[actor.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func _emit(point:Vector3,velocity:Vector3,size:float,life:float,color:Color,kind:float)->void:
	for i in range(sparks.size()):
		if sparks[i].age>=sparks[i].life:
			var local_point:=to_local(point)
			sparks[i]={"p":local_point,"v":global_basis.inverse()*velocity,"size":size,"age":0.0,"life":life,"color":color,"kind":kind,"phase":rng.randf(),"floor":local_point.y-0.01,"zeroed":false}
			return

func _foot_dust(point:Vector3,count:int)->void:
	for i in range(roundi(count*foot_dust_strength)):
		_emit(point+Vector3(rng.randf_range(-0.10,0.10),0.018,rng.randf_range(-0.09,0.09)),Vector3(-actor.velocity.x*0.025+rng.randf_range(-0.08,0.08),rng.randf_range(0.04,0.12),0),rng.randf_range(0.055,0.10)*foot_dust_strength,rng.randf_range(0.35,0.65),Color(0.65,0.63,0.58,0.42),3.0)

func _physics_process(delta:float)->void:
	if not actor or not actor.ready_for_input:return
	if not bones_cached:_cache_bones()
	var grounded:=actor.is_on_floor()
	if not grounded:air_time+=delta
	elif air_time>0:
		if air_time>0.2:
			var hit:=_floor(actor.global_position)
			if not hit.is_empty():_foot_dust(hit.position,12)
		air_time=0
	var moving: bool = absf(actor.velocity.x) > 0.05 or absf(actor.velocity.y) > 0.05 or not grounded or not shadows[0].visible
	if moving:
		for i in range(2):
			var side:="L" if i==0 else "R"
			var foot:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(bone_foot_l if i==0 else bone_foot_r).origin)
			var toe:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(bone_toe_l if i==0 else bone_toe_r).origin)
			var point:=foot.lerp(toe,0.5)
			var hit:=_floor(point)
			shadows[i].visible=not hit.is_empty() and not actor.state.begins_with("Climb")
			if hit.is_empty():continue
			var height:=maxf(0,foot.y-0.10-hit.position.y)
			shadows[i].global_position=hit.position+Vector3.UP*0.011
			var alpha:=clampf(1-height/0.22,0,1)
			(shadows[i].material_override as StandardMaterial3D).albedo_color=Color(1,1,1,alpha)
			if grounded and absf(actor.velocity.x)>0.6 and previous_height[i]>0.065 and height<0.045:
				_foot_dust(hit.position,4)
			previous_height[i]=height
	# Skid and turn dust
	if grounded and actor.state in ["Brake","Turn"]:
		if actor.state=="Brake" and absf(actor.velocity.x)>0.35:
			skid_dust_time-=delta
			if skid_dust_time<=0:
				skid_dust_time=0.06
				var hit:=_floor(actor.global_position+Vector3(actor.facing*0.14,0,0))
				if not hit.is_empty():_foot_dust(hit.position,3)
		elif actor.state=="Turn" and actor.state_time<0.05:
			var hit:=_floor(actor.global_position)
			if not hit.is_empty():_foot_dust(hit.position,2)
	# Wall contact dust
	if actor.state=="WallBlocked":
		if not wall_dust_triggered:
			wall_dust_triggered=true
			var wall_point:=actor.global_position+Vector3(actor.facing*0.28,0.85,0)
			_emit(wall_point,Vector3(-actor.facing*0.12+rng.randf_range(-0.04,0.04),rng.randf_range(0.02,0.08),rng.randf_range(-0.05,0.05)),0.065,0.40,Color(0.70,0.67,0.62,0.48),3.0)
	else:
		wall_dust_triggered=false
	ion_time-=delta
	if ion_time<=0 and actor.state in ["Locomotion","MoveStart","GroundStop"]:
		ion_time=rng.randf_range(0.25,0.55)
		var point:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(bone_spine).origin)
		point+=Vector3(-actor.facing*0.14+rng.randf_range(-0.05,0.05),rng.randf_range(-0.05,0.10),0.12)
		var color:=Color(0.59,0.84,0.67,0.46) if actor.suit_polarity==0 else Color(0.9,0.56,0.54,0.46) if actor.suit_polarity==1 else Color(0.57,0.70,0.92,0.46)
		_emit(point,Vector3(-actor.facing*0.03,0.10,0),rng.randf_range(0.035,0.055),0.7,color,2.0)

func _process(delta:float)->void:
	if not camera:return
	elapsed+=delta
	var facing:=global_basis.inverse()*camera.global_basis
	var viewport:=camera.get_viewport().get_visible_rect().size
	var half_width:float=camera.size*viewport.x/maxf(viewport.y,1)*0.5
	var camera_x:=to_local(camera.global_position).x
	var visible_count:=0
	for i in range(motes.size() if ambient_air_enabled else 0):
		var m:Dictionary=motes[i]
		m.age+=delta
		m.p.x+=delta*(m.speed+sin(elapsed*0.32+m.phase*6.28)*0.025)
		m.p.y+=delta*(0.02+sin(elapsed*0.24+m.phase*6.28)*0.025)
		if m.p.x>room_length+2:m.p.x=-2
		if m.p.y>8.8:m.p.y=0.3
		if m.age>m.life:m.age=0.0
		if absf(m.p.x-camera_x)>half_width+1.5:continue
		var fade:=minf(1,minf(m.age,m.life-m.age)/2.0)
		air.set_instance_transform(visible_count,Transform3D(facing.scaled(Vector3.ONE*m.size),m.p))
		air.set_instance_color(visible_count,Color(1.0,0.88,0.65,m.alpha*fade))
		air.set_instance_custom_data(visible_count,Color(m.phase,m.kind,0,0))
		visible_count+=1
	air.visible_instance_count=visible_count
	for i in range(sparks.size()):
		var p:Dictionary=sparks[i]
		if p.age>=p.life:
			if not p.get("zeroed", false):
				local.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
				p["zeroed"] = true
			continue
		p.age+=delta
		p.p+=p.v*delta
		if p.kind>2.5:
			p.v.y-=delta*0.10
			p.p.y=maxf(p.p.y,p.floor)
		var t:float=p.age/p.life
		var size:float=p.size*(1+t*1.2 if p.kind>2.5 else 1)
		local.set_instance_transform(i,Transform3D(facing.scaled(Vector3.ONE*size),p.p))
		var color:Color=p.color
		color.a*=maxf(0,1-t)
		local.set_instance_color(i,color)
		local.set_instance_custom_data(i,Color(p.phase,p.kind,0,0))
