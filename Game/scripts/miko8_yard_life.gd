extends Node3D
## Source-anchored steam, beacons and small electrical events. Hardware stays
## visible with Atmosphere off; particles, animation and local audio stop.
var camera:Camera3D
var actor:CharacterBody3D
var level:Node3D
var enabled:=true
var elapsed:=0.0
var hardware:Node3D
var steam:MultiMesh
var flecks:MultiMesh
var arc_mesh:=ImmediateMesh.new()
var vents:Array[Dictionary]=[]
var beacons:Array[Dictionary]=[]
var terminals:Array[Dictionary]=[]
var sounds:Array[AudioStreamPlayer3D]=[]
var listener:AudioListener3D
var hiss:AudioStreamWAV
var crackle:AudioStreamWAV
var release_count:=0
var arc_count:=0
func _ready()->void:
	name="YardLife";process_priority=2;level=get_parent().get_parent()
	hardware=Node3D.new();hardware.name="AtmosphereHardware";level.add_child(hardware)
	hiss=_sound(false);crackle=_sound(true)
	listener=AudioListener3D.new();listener.name="YardSoundListener";listener.position.y=1.;actor.add_child(listener);listener.make_current()
	steam=_batch("VentSteamPuffs",40,preload("res://shaders/miko8_yard_steam.gdshader"))
	flecks=_batch("TerminalSparks",16,preload("res://shaders/tutorial_air.gdshader"))
	var arc:=MeshInstance3D.new();arc.name="TerminalArcs";arc.mesh=arc_mesh
	var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_yard_arc.gdshader");arc.material_override=paint
	arc.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(arc)
	var sites:Array[Vector3]=[Vector3(9.2,0.,-1.25),Vector3(22.7,2.83364,-1.1),Vector3(34.9,5.2,-1.15),Vector3(45.8,5.2,-1.15),Vector3(56.3,2.83364,-.9)]
	for i in range(sites.size()):_vent(sites[i],i)
	for i in range(3):_beacon([Vector3(23.6,2.83364,-.95),Vector3(35.7,5.2,-1.),Vector3(49.3,5.2,-1.)][i],i)
	_terminal(Vector3(10.2,0.,-1.2),0);_terminal(Vector3(34.15,5.2,-1.1),1)
	_update()
func _cylinder(at:Vector3,radius:float,height:float,paint:Material)->MeshInstance3D:
	var node:=MeshInstance3D.new();var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=height;mesh.radial_segments=12
	node.mesh=mesh;node.material_override=paint;node.position=at;node.layers=4;hardware.add_child(node);return node
func _vent(base:Vector3,index:int)->void:
	_hardware_part("exhaust_outlet",base)
	var sound:=_player(base+Vector3.UP*.35,hiss,-16.)
	vents.append({"source":base+Vector3.UP*.36,"period":8.0+float(index%3)*.7,"phase":float(index)*1.9,"last":0,"sound":sound})
func _beacon(base:Vector3,index:int)->void:
	_hardware_part("beacon_housing",base)
	var lens:=StandardMaterial3D.new();lens.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;lens.albedo_color=Color("be7934")
	_cylinder(base+Vector3.UP*.17,.095,.18,lens)
	var glow:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(.95,.85);glow.mesh=quad
	var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_yard_lamp_glow.gdshader");glow.material_override=paint;glow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(glow)
	beacons.append({"source":base+Vector3.UP*.18,"phase":float(index)*2.1,"lens":lens,"glow":glow,"paint":paint})
func _terminal(base:Vector3,index:int)->void:
	_hardware_part("service_terminal",base)
	terminals.append({"source":base+Vector3(0,.86,.025),"period":10.7+float(index)*1.6,"phase":float(index)*4.2+.8,"last":0,"sound":_player(base,crackle,-19.)})
func _hardware_part(asset:String,base:Vector3)->void:
	var model:Node3D=load("res://models/environment/yard_life/"+asset+".glb").instantiate();model.position=base;hardware.add_child(model)
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		mesh.layers=4
		for i in range(mesh.mesh.get_surface_count()):
			var paint:=mesh.get_active_material(i) as StandardMaterial3D
			if paint:paint.vertex_color_use_as_albedo=true
func _batch(label:String,count:int,shader:Shader)->MultiMesh:
	var node:=MultiMeshInstance3D.new();node.name=label
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true;batch.use_custom_data=true
	var quad:=QuadMesh.new();quad.size=Vector2.ONE;var paint:=ShaderMaterial.new();paint.shader=shader;quad.material=paint
	batch.mesh=quad;batch.instance_count=count;batch.visible_instance_count=0;batch.custom_aabb=AABB(Vector3(-4,-2,-5),Vector3(72,15,10));node.multimesh=batch
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node);return batch
func _player(at:Vector3,stream:AudioStreamWAV,db:float)->AudioStreamPlayer3D:
	var sound:=AudioStreamPlayer3D.new();sound.stream=stream;sound.position=at;sound.volume_db=db;sound.unit_size=3.;sound.max_distance=14.
	sound.set_meta("base_volume_db",db);hardware.add_child(sound);sounds.append(sound);return sound
func _sound(electric:bool)->AudioStreamWAV:
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050
	var length:=.18 if electric else .65;var data:=PackedByteArray();var count:=int(length*22050.);data.resize(count*2)
	var rng:=RandomNumberGenerator.new();rng.seed=819 if electric else 1741
	var low:=0.
	for i in range(count):
		var t:=float(i)/22050.;var noise:=rng.randf_range(-1.,1.);low=lerpf(low,noise,.18)
		var envelope:=exp(-t*26.) if electric else sin(PI*t/length)*exp(-t*.9)
		var sample:float=(noise-low*.7)*envelope*(.5 if electric else .25)
		data.encode_s16(i*2,int(clampf(sample,-1.,1.)*24000.))
	stream.data=data;return stream
func _muted()->bool:return level.ambience_muted
func set_effects_enabled(value:bool)->void:
	enabled=value;visible=value;set_process(value)
	if not value:
		for sound in sounds:sound.stop()
		for beacon:Dictionary in beacons:beacon.lens.albedo_color=Color("6d4a28")
	elif is_inside_tree():_update()
func _process(delta:float)->void:
	elapsed+=minf(delta,.1);_update()
func _update()->void:
	if not enabled or not camera:return
	var facing:=camera.global_basis;var camera_x:float=camera.get_meta("walkway_focus_x",camera.global_position.x)
	var half:float=camera.size*camera.get_viewport().get_visible_rect().size.x/camera.get_viewport().get_visible_rect().size.y*.5
	var muted:=_muted()
	for sound in sounds:
		sound.volume_db=-80. if muted else float(sound.get_meta("base_volume_db"))
		sound.stream_paused=muted
	var count:=0
	for vent:Dictionary in vents:
		var cycle:=int((elapsed+float(vent.phase))/float(vent.period))
		if cycle>int(vent.last):
			vent.last=cycle;release_count+=1
			if not muted and actor.global_position.distance_to(vent.source)<12.:vent.sound.play()
		if absf(float(vent.source.x)-camera_x)>half+3.:continue
		var phase:=fposmod(elapsed+float(vent.phase),float(vent.period))
		for i in range(8):
			var age:=phase-float(i)*.23
			if age<0. or age>3.5:continue
			var seed:float=float(i)*1.37+float(vent.phase)
			var point:Vector3=vent.source+Vector3(age*.13+sin(seed+age)*.10,age*.57,0.)
			var size:=.26+age*.30
			var fade:=smoothstep(0.,.18,age)*(1.-smoothstep(2.0,3.5,age))
			steam.set_instance_transform(count,Transform3D(facing.scaled(Vector3(size,size*1.12,size)),point))
			steam.set_instance_color(count,Color(.96,.98,1.,fade*.30));steam.set_instance_custom_data(count,Color(age/3.5,fposmod(seed,1.),0,0));count+=1
	steam.visible_instance_count=count
	for beacon:Dictionary in beacons:
		var pulse:=.60+.40*pow(.5+.5*sin(elapsed*1.8+float(beacon.phase)),3.)
		beacon.lens.albedo_color=Color(1.,.53,.13)*pulse
		beacon.glow.global_transform=Transform3D(facing,beacon.source)
		beacon.glow.visible=absf(float(beacon.source.x)-camera_x)<half+1.
		beacon.paint.set_shader_parameter("opacity",.28*pulse)
	arc_mesh.clear_surfaces();count=0;var drawing:=false
	for terminal:Dictionary in terminals:
		var phase:=fposmod(elapsed+float(terminal.phase),float(terminal.period))
		var cycle:=int((elapsed+float(terminal.phase))/float(terminal.period))
		if cycle>int(terminal.last):
			terminal.last=cycle;arc_count+=1
			if not muted and actor.global_position.distance_to(terminal.source)<12.:terminal.sound.play()
		if absf(float(terminal.source.x)-camera_x)>half+1.:continue
		if phase<.095 or (phase>.19 and phase<.24):
			if not drawing:arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES);drawing=true
			for segment in range(6):
				var a:Vector3=_arc_point(terminal.source,segment)
				var b:Vector3=_arc_point(terminal.source,segment+1)
				_segment(a,b,.055,Color(.25,.56,1.,.22),facing.z);_segment(a,b,.013,Color(.78,.93,1.,.95),facing.z)
		var age:=phase-.095
		if age<0. or age>.48:continue
		for i in range(8):
			var velocity:=Vector3(sin(float(i)*2.37)*.85,.35+sin(float(i)*1.31)*.22,.02)
			var point:Vector3=terminal.source+velocity*age+Vector3.DOWN*age*age*1.5
			flecks.set_instance_transform(count,Transform3D(facing.scaled(Vector3.ONE*(.035+float(i%3)*.012)),point))
			flecks.set_instance_color(count,Color(.68,.84,1.,.85*(1.-age/.48)));flecks.set_instance_custom_data(count,Color(float(i)*.1,2.,0,0));count+=1
	if drawing:arc_mesh.surface_end()
	flecks.visible_instance_count=count
func _arc_point(source:Vector3,index:int)->Vector3:
	var y:=0. if index==0 or index==6 else sin(float(index)*2.3+elapsed*177.)*.035
	return source+Vector3(-.18+float(index)*.06,y,0.)
func _segment(a:Vector3,b:Vector3,width:float,tint:Color,back:Vector3)->void:
	var side:Vector3=(b-a).cross(back).normalized()*width*.5
	arc_mesh.surface_set_color(tint)
	for point:Vector3 in [a-side,b-side,a+side,a+side,b-side,b+side]:arc_mesh.surface_add_vertex(point)
