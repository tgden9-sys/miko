extends Node3D
## Layered moving air with 3-tier Ghibli sunlit bokeh & volumetric lamp motes.
var camera:Camera3D
var effects_enabled:=true
var room_length:=64.0
var scenery_parallax_factor:=.95
var elapsed:=0.0
var dust:MultiMesh
var dust_node:MultiMeshInstance3D
var floating_air:MultiMesh
var floating_node:MultiMeshInstance3D
var floating_points:Array[Dictionary]=[]
var cards:Array[Dictionary]=[]
var yard_life:Node3D
var enable_yard_life:=true
var mote_intensity:=1.0
const DUST_TOTAL_COUNT:=24
const FLOATING_COUNT:=48
const LAMPS:Array[Vector3]=[
	Vector3(1.1,2.6,-1.5),Vector3(28.0,3.9,-1.3),Vector3(58.1,2.9,-1.5)
]

func _ready()->void:
	name="SideOnAtmosphere";process_priority=1
	dust_node=_batch("WarmWorklightDust",DUST_TOTAL_COUNT);dust=dust_node.multimesh
	floating_node=_batch("DriftingNearAir",FLOATING_COUNT);floating_air=floating_node.multimesh
	var rng:=RandomNumberGenerator.new();rng.seed=640129
	# 3-Tier Layered Parallax:
	# Tier 0 (0..7): Foreground Lens Bokeh (Z: 5.5 to 11.5) - large out-of-focus golden discs
	# Tier 1 (8..31): Midground Sunlit Dust (Z: -0.3 to 1.8) - dancing motes flaring near lamps
	# Tier 2 (32..47): Deep Background Haze (Z: -1.2 to -4.0) - small distant atmospheric specks
	for i in range(FLOATING_COUNT):
		var tier:int=0 if i<8 else (1 if i<32 else 2)
		var p:Vector3
		var size:float
		var alpha:float
		var speed:float
		var base_col:Color
		match tier:
			0:
				p=Vector3(rng.randf_range(0,room_length),rng.randf_range(0.5,7.5),rng.randf_range(5.5,11.5))
				size=rng.randf_range(0.38,0.68)
				alpha=rng.randf_range(0.32,0.52)
				speed=rng.randf_range(0.12,0.22)
				base_col=Color(1.0,0.88,0.68)
			1:
				p=Vector3(rng.randf_range(0,room_length),rng.randf_range(0.2,7.0),rng.randf_range(-0.3,1.8))
				size=rng.randf_range(0.09,0.18)
				alpha=rng.randf_range(0.50,0.85)
				speed=rng.randf_range(0.05,0.12)
				base_col=Color(1.0,0.82,0.50)
			_:
				p=Vector3(rng.randf_range(0,room_length),rng.randf_range(0.8,8.5),rng.randf_range(-1.2,-4.0))
				size=rng.randf_range(0.045,0.085)
				alpha=rng.randf_range(0.25,0.45)
				speed=rng.randf_range(0.03,0.06)
				base_col=Color(0.95,0.85,0.65)
		floating_points.append({
			"p":p,"phase":rng.randf_range(0,TAU),"size":size,"alpha":alpha,
			"speed":speed,"tier":tier,"base_col":base_col
		})
	for i in range(LAMPS.size()):
		var haze:=ShaderMaterial.new();haze.shader=preload("res://shaders/miko8_side_on_lamp_haze.gdshader")
		haze.set_shader_parameter("opacity",.40);haze.set_shader_parameter("phase",float(i)*1.7)
		_card("WorkLampHaze",LAMPS[i],Vector2(1.65,2.9),haze,-.5,.95)
		var glow:=ShaderMaterial.new();glow.shader=preload("res://shaders/miko8_yard_lamp_glow.gdshader")
		glow.set_shader_parameter("opacity",.24)
		_card("WorkLampGlow",LAMPS[i]+Vector3(0,0,.02),Vector2(1.1,.85),glow,0.,.95)
	for i in range(4):
		var mist:=ShaderMaterial.new();mist.shader=preload("res://shaders/miko8_side_on_floor_haze.gdshader")
		mist.set_shader_parameter("opacity",.38);mist.set_shader_parameter("phase",float(i)*2.1)
		_card("LowDriftingHaze",Vector3(8.0+16.0*i,.02,.40),Vector2(18,1.7),mist,.5,1.0)
	for i in range(3):
		var mist:=ShaderMaterial.new();mist.shader=preload("res://shaders/miko8_side_on_floor_haze.gdshader")
		mist.set_shader_parameter("opacity",.17);mist.set_shader_parameter("phase",float(i)*2.9)
		_card("RearDriftingHaze",Vector3(12.+22.*i,3.7,-3.1),Vector2(24.,3.4),mist,.5,.76)
	if enable_yard_life:
		yard_life=preload("res://scripts/miko8_yard_life.gd").new();yard_life.camera=camera;yard_life.actor=get_parent().actor;add_child(yard_life)
	set_effects_enabled(effects_enabled);_update_effects()

func set_mote_intensity(factor:float)->void:
	mote_intensity=clampf(factor,0.0,2.0)
	if is_instance_valid(floating_node) and floating_node.material_override:
		floating_node.material_override.set_shader_parameter("master_opacity",mote_intensity)
	elif is_instance_valid(floating_air) and floating_air.mesh and floating_air.mesh.surface_get_material(0):
		var mat:=floating_air.mesh.surface_get_material(0) as ShaderMaterial
		if mat:mat.set_shader_parameter("master_opacity",mote_intensity)
	if is_instance_valid(dust_node) and dust_node.material_override:
		dust_node.material_override.set_shader_parameter("master_opacity",mote_intensity)
	elif is_instance_valid(dust) and dust.mesh and dust.mesh.surface_get_material(0):
		var mat:=dust.mesh.surface_get_material(0) as ShaderMaterial
		if mat:mat.set_shader_parameter("master_opacity",mote_intensity)

func _batch(label:String,count:int)->MultiMeshInstance3D:
	var node:=MultiMeshInstance3D.new();node.name=label
	var mesh:=MultiMesh.new();mesh.transform_format=MultiMesh.TRANSFORM_3D;mesh.use_colors=true
	var quad:=QuadMesh.new();quad.size=Vector2.ONE
	var material:=ShaderMaterial.new();material.shader=preload("res://shaders/miko8_side_on_dust.gdshader")
	material.set_shader_parameter("master_opacity",mote_intensity)
	quad.material=material;mesh.mesh=quad;mesh.instance_count=count
	mesh.custom_aabb=AABB(Vector3(-4,-1,-6),Vector3(room_length+8,14,20))
	node.multimesh=mesh;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)
	return node

func _card(label:String,anchor:Vector3,size:Vector2,material:Material,offset:float,factor:float)->void:
	var node:=MeshInstance3D.new();node.name=label;var quad:=QuadMesh.new();quad.size=size;quad.material=material
	node.mesh=quad;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)
	cards.append({"node":node,"anchor":anchor,"size":size,"offset":offset,"factor":factor})

func set_effects_enabled(enabled:bool)->void:
	effects_enabled=enabled;visible=enabled;set_process(enabled)
	if is_instance_valid(yard_life):yard_life.set_effects_enabled(enabled)
	if enabled and is_inside_tree():_update_effects()

func _process(delta:float)->void:
	elapsed+=minf(delta,.1);_update_effects()

func _update_effects()->void:
	if not effects_enabled:return
	if not is_instance_valid(camera):camera=get_viewport().get_camera_3d()
	if not camera:return
	var facing:=camera.global_basis
	var viewport_size:=camera.get_viewport().get_visible_rect().size
	var half:=camera.size*viewport_size.x/maxf(1,viewport_size.y)*.5
	var camera_x:float=camera.get_meta("walkway_focus_x",camera.global_position.x)
	for record:Dictionary in cards:
		var anchor:Vector3=record.anchor+Vector3((camera_x-16.0)*(1.0-record.factor),0,0)
		record.node.visible=absf(anchor.x-camera_x)<half+record.size.x*.5+1
		record.node.global_transform=Transform3D(facing,anchor+facing.y*record.size.y*record.offset)
	# 1. Warm worklight dust circulating directly under lamps (40 instances)
	var count:=0
	var dust_per_lamp:int=DUST_TOTAL_COUNT/maxi(1,LAMPS.size())
	for lamp in range(LAMPS.size()):
		var anchor:=LAMPS[lamp]+Vector3((camera_x-16.0)*.05,0,0)
		var this_lamp_dust:int=dust_per_lamp+(1 if lamp<DUST_TOTAL_COUNT%LAMPS.size() else 0)
		if absf(anchor.x-camera_x)>half+1:continue
		for i in range(this_lamp_dust):
			var seed:=float(lamp*14+i)
			var phase:=fposmod(float(i)/float(this_lamp_dust)+seed*.037+elapsed*(.023+fmod(seed,3)*.003),1)
			var fade:=smoothstep(0,.12,phase)*(1-smoothstep(.82,1,phase))
			var point:=anchor+facing.y*(-2.0+phase*1.95)+facing.x*sin(seed*2.39+elapsed*.17)*.42
			point.z+=.12
			var size:=.042+fmod(seed*.619,1)*.032
			var b:=Basis(facing.x*size, facing.y*size, facing.z*size)
			dust.set_instance_transform(count,Transform3D(b,point))
			dust.set_instance_color(count,Color(1.0,0.84,0.58,(.42+fmod(seed*.31,1)*.26)*fade*mote_intensity));count+=1
	dust.visible_instance_count=count
	# 2. 3-Tier Layered Parallax Sunlit Motes (96 instances)
	count=0
	for i in range(floating_points.size()):
		var particle:Dictionary=floating_points[i]
		var margin:float=3.8 if particle.tier==0 else 1.2
		var px:float=fposmod(particle.p.x+elapsed*particle.speed,room_length)
		if absf(px-camera_x)>half+margin:continue
		var p:Vector3=Vector3(px, particle.p.y, particle.p.z)
		var y_bob:float
		match particle.tier:
			0:
				y_bob=sin(elapsed*0.16+particle.phase)*0.22
			1:
				y_bob=sin(elapsed*0.32+particle.phase)*0.16+cos(elapsed*0.20+particle.phase*2.0)*0.06
			_:
				y_bob=sin(elapsed*0.12+particle.phase)*0.08
		p.y+=y_bob
		var lamp_flare:=1.0
		if particle.tier==1:
			for lamp_pos:Vector3 in LAMPS:
				var d:=Vector2(p.x-lamp_pos.x,p.y-lamp_pos.y).length()
				if d<3.4:
					lamp_flare=maxf(lamp_flare,1.0+(1.0-d/3.4)*1.6)
		var fade:float=.65+.35*sin(elapsed*.25+particle.phase)
		var col:Color=particle.base_col
		col.a=clampf(particle.alpha*fade*mote_intensity*lamp_flare,0.0,1.0)
		var s:float=particle.size
		var fb:=Basis(facing.x*s, facing.y*s, facing.z*s)
		floating_air.set_instance_transform(count,Transform3D(fb,p))
		floating_air.set_instance_color(count,col)
		count+=1
	floating_air.visible_instance_count=count
