extends Node3D
var lines:Dictionary={}
var ends:Dictionary={}
var glows:Dictionary={}
var plasma_ball:Node3D
var hand_orbs:Dictionary={}
var mote_nodes:Dictionary={}
var starts:Dictionary={}
var elapsed:=0.0
func _ready()->void:
	for side:String in ["L","R","C"]:
		var line:=MeshInstance3D.new()
		line.mesh=ImmediateMesh.new()
		line.top_level=true;line.extra_cull_margin=.1
		var material:=StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.disable_receive_shadows=true
		# Aim guides are overlays: painted scenery must not depth-occlude them.
		# The world ray still clips their endpoints against real obstacles.
		material.no_depth_test=true;material.render_priority=30
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		material.albedo_color=Color("ff3038") if side=="L" else Color("309cff")
		line.material_override=material
		line.visible=false
		add_child(line)
		lines[side]=line
		line.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var glow:=MeshInstance3D.new()
		glow.mesh=ImmediateMesh.new();glow.extra_cull_margin=.1
		var glow_material:=material.duplicate() as StandardMaterial3D
		glow_material.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
		glow_material.render_priority=29
		glow.material_override=glow_material
		glow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		line.add_child(glow)
		glows[side]=glow
	for mode:String in ["Plasma","Red","Blue"]:
		var orb:=preload("res://scripts/miko8_energy_orb.gd").new()
		orb.mode=mode;orb.radius=.22 if mode=="Plasma" else .105;add_child(orb)
		orb.visible=false;hand_orbs[mode]=orb
	plasma_ball=hand_orbs.Plasma
	for side:String in ["L","R","C"]:
		var motes:Array[MeshInstance3D]=[]
		for index in range(7):
			var mote:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.022;sphere.height=.044
			sphere.radial_segments=6;sphere.rings=3;mote.mesh=sphere
			var paint:=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;paint.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
			paint.no_depth_test=true;paint.render_priority=31
			mote.material_override=paint;mote.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mote);mote.visible=false;motes.append(mote)
		mote_nodes[side]=motes
func draw_beam(side:String,from:Vector3,to:Vector3,plasma:=false,blue:=false)->void:
	var line:MeshInstance3D=lines[side]
	var tint:=Color("b36aff") if plasma else Color("309cff") if blue or side=="R" else Color("ff3038")
	tint.a=0.72
	line.material_override.albedo_color=tint
	var halo_tint:=tint
	halo_tint.a=0.12
	glows[side].material_override.albedo_color=halo_tint
	var difference:=to-from
	if difference.length()<0.001:line.visible=false;return
	line.visible=true
	# Rebuild a camera-facing ribbon from this frame's endpoints. The former
	# 7mm cylinder became subpixel at gameplay zoom and could vanish on reuse.
	# A fresh mesh also avoids carrying a scaled transform between shots.
	line.global_transform=Transform3D(Basis.IDENTITY,from)
	var camera:=get_viewport().get_camera_3d()
	var facing:Vector3=camera.global_basis.z if camera else Vector3.BACK
	var across:Vector3=difference.normalized().cross(facing).normalized()
	if across.length_squared()<.1:across=Vector3.RIGHT
	var pixel:float=camera.size/maxf(get_viewport().get_visible_rect().size.y,1.) if camera else .015
	if camera and camera.projection==Camera3D.PROJECTION_PERSPECTIVE:
		var depth:float=maxf(.1,(from-camera.global_position).dot(-camera.global_basis.z))
		pixel=2.*depth*tan(deg_to_rad(camera.fov)*.5)/maxf(get_viewport().get_visible_rect().size.y,1.)
	_ribbon(line.mesh,difference,across*pixel*.75)
	_ribbon(glows[side].mesh,difference,across*pixel*2.2)
	ends[side]=to
	starts[side]=from
func _ribbon(mesh:ImmediateMesh,difference:Vector3,half_width:Vector3)->void:
	mesh.clear_surfaces();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex:Vector3 in [-half_width,half_width,difference+half_width,-half_width,difference+half_width,difference-half_width]:mesh.surface_add_vertex(vertex)
	mesh.surface_end()
func hold_charge(origin:Vector3,mode:String)->void:
	var orb:Node3D=hand_orbs[mode];orb.visible=true;orb.global_position=origin
func hold_plasma(origin:Vector3)->void:
	hold_charge(origin,"Plasma")
func hide_beams()->void:
	for orb:Node3D in hand_orbs.values():orb.visible=false
	for line:MeshInstance3D in lines.values():line.visible=false
	starts.clear();ends.clear()
func _process(delta:float)->void:
	elapsed+=delta
	for side:String in mote_nodes:
		var active:bool=lines[side].visible and starts.has(side)
		for index in range(mote_nodes[side].size()):
			var mote:MeshInstance3D=mote_nodes[side][index]
			mote.visible=active
			if not active:continue
			var from:Vector3=starts[side];var to:Vector3=ends[side]
			var length:float=from.distance_to(to)
			var travel:=fmod(elapsed*7.2+index*1.9,14.5)
			mote.visible=travel>.2 and travel<length
			mote.global_position=from.direction_to(to)*travel+from
			var pulse:float=0.65+0.35*sin(elapsed*18.0+index*1.2)
			var col:Color=lines[side].material_override.albedo_color.lerp(Color.WHITE,0.45)
			col.a=pulse
			mote.material_override.albedo_color=col
