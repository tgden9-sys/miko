extends "res://scripts/miko8_tutorial.gd"
const PREVIEW_LENGTH:=60.0
var native_ground:Node3D
func _world()->void:
	var world:=WorldEnvironment.new();world.name="DioramaEnvironment"
	var env:=Environment.new();world.environment=env
	env.background_mode=Environment.BG_SKY
	var sky:=Sky.new();var atmosphere:=ShaderMaterial.new();atmosphere.shader=preload("res://shaders/diorama_sky.gdshader")
	sky.sky_material=atmosphere;env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("899cb6");env.ambient_light_energy=.20
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled=true;env.ssao_radius=.48;env.ssao_intensity=1.35;env.ssao_power=1.4;env.ssao_light_affect=.12
	env.glow_enabled=true;env.glow_intensity=.35;env.glow_bloom=0.0;env.glow_hdr_threshold=1.2
	env.fog_enabled=true;env.fog_light_color=Color("526276");env.fog_density=.0016;env.fog_sky_affect=0.0
	add_child(world)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-36,-24,0)
	key.light_color=Color("b6c9e4");key.light_energy=.45;key.shadow_enabled=true;key.light_angular_distance=1.7
	key.directional_shadow_max_distance=60;add_child(key)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-40,145,0);fill.light_color=Color("9baec8");fill.light_energy=.12;add_child(fill)
func _backgrounds()->void:
	for data:Array in [["BG2_DistantCity",.1,-39.0,173,.35],["BG3_CityWindows",.3,-24.0,392,.0]]:
		var layer:=_plane(data[0],data[1]);var city:=preload("res://scripts/miko8_diorama_city.gd").new()
		city.depth=data[2];city.seed_value=data[3];city.haze=data[4];layer.add_child(city)
	var near:=_plane("BG4_SeparateMachinery",1.0)
	for data:Array in [["machinery_left",Vector3(25,0,-5)],["machinery_right",Vector3(41,0,-5)]]:
		var cluster:Node3D=load("res://models/environment/diorama_rescue/"+data[0]+".glb").instantiate()
		cluster.name=data[0];cluster.position=data[1];near.add_child(cluster)
		for mesh:MeshInstance3D in cluster.find_children("*","MeshInstance3D",true,false):
			mesh.add_to_group("miko8_budget_visual");mesh.set_meta("budget_half_width",3.5)
			for s in range(mesh.mesh.get_surface_count()):
				var mat:=mesh.get_active_material(s) as StandardMaterial3D
				if mat:mat.vertex_color_use_as_albedo=false
	add_child(preload("res://scripts/miko8_diorama_banks.gd").new())
	for x:float in [25.0,41.0]:
		var warm:=SpotLight3D.new();warm.position=Vector3(x-1.9,4.4,-2.8)
		warm.look_at_from_position(warm.position,Vector3(x,-.1,-4.0))
		warm.light_color=Color("ffc27e");warm.light_energy=6.0;warm.spot_range=9;warm.spot_angle=54;warm.shadow_enabled=true;warm.shadow_blur=2.0;add_child(warm)
		warm.add_to_group("miko8_budget_visual");warm.set_meta("budget_half_width",6.0)
	# One sagging cable frames the open skyline without a solid background wall.
	var cable_mat:=StandardMaterial3D.new();cable_mat.albedo_color=Color("1f2931");cable_mat.roughness=.72
	var anchors:=[
		[Vector3(23.84,4.21,-5.42),Vector3(39.56,3.82,-5.46)],
		[Vector3(24.70,4.21,-5.42),Vector3(40.87,4.09,-5.55)],
		[Vector3(25.56,4.21,-5.42),Vector3(40.87,4.09,-5.37)]]
	for pair:Array in anchors:
		for i in range(24):
			var a:Vector3=pair[0].lerp(pair[1],i/24.0)-Vector3.UP*1.25*sin(i/24.0*PI)
			var b:Vector3=pair[0].lerp(pair[1],(i+1)/24.0)-Vector3.UP*1.25*sin((i+1)/24.0*PI)
			var mesh:=MeshInstance3D.new();var pipe:=CylinderMesh.new();pipe.top_radius=.024;pipe.bottom_radius=.024;pipe.height=a.distance_to(b);pipe.radial_segments=8
			mesh.mesh=pipe;mesh.position=(a+b)/2;mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized());mesh.material_override=cable_mat;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh)
func _foreground()->void:pass
func _details()->void:
	var crate:=preload("res://scripts/miko8_charge_box.gd").new();crate.name="TutorialChargeCrate";crate.position=Vector3(43,.4,0);crate.freeze=true;add_child(crate)
func _ready()->void:
	super._ready()
	var old:=get_node("PaintedGroundKit");remove_child(old);old.queue_free()
	native_ground=preload("res://scripts/miko8_ortho_repetition_ground.gd").new()
	native_ground.clean_style=true;native_ground.diorama_style=true;add_child(native_ground)
	actor.position=Vector3(28,.02,0);_camera(0,true)
	get_viewport().msaa_3d=Viewport.MSAA_2X
	var optics:=CameraAttributesPractical.new()
	optics.dof_blur_far_enabled=true;optics.dof_blur_far_distance=31;optics.dof_blur_far_transition=12;optics.dof_blur_amount=.12
	optics.dof_blur_near_enabled=true;optics.dof_blur_near_distance=20;optics.dof_blur_near_transition=4
	camera.attributes=optics
	RenderingServer.camera_attributes_set_dof_blur_bokeh_shape(RenderingServer.DOF_BOKEH_CIRCLE)
	RenderingServer.camera_attributes_set_dof_blur_quality(RenderingServer.DOF_BLUR_QUALITY_MEDIUM,false)
	title.text="MIKO   /   SUBSTATION 04";progress.text=""
	DisplayServer.window_set_title("MIKO — Miniature Diorama / Native 3D")
	visibility_budget.refresh()
	print("DIORAMA_READY: open bridge composition, native PBR machinery/city, renderer=",RenderingServer.get_current_rendering_method())
func _camera(delta:float,immediate:=false)->void:
	var goal:=clampf(actor.position.x+1.5,10,50)
	var x:float=goal if immediate else lerpf(camera.position.x,goal,1-exp(-4.5*delta))
	if "--ortho" in OS.get_cmdline_user_args():
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=11.25
	else:camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=24.6
	camera.position=Vector3(x,1.2+24*tan(deg_to_rad(19.0)),24);camera.look_at(Vector3(x,1.2,0));camera.far=160
	# Perspective supplies depth motion. An additional small far-layer offset
	# makes the skyline drift gently during side-scrolling, anchored at the bridge.
	for plane:Dictionary in parallax:plane.node.position.x=(x-33)*(1-plane.factor)*.25
	if immediate and visibility_budget:visibility_budget.refresh()
func _prompt()->void:
	instruction.text="After the last light." if actor.state.begins_with("GroundSit") else "A quiet crossing."
	detail.text="Left stick: move · A / Circle: jump · View: reset" if not Input.get_connected_joypads().is_empty() else "A / D: move · Ctrl: walk · Shift: sprint · Space: jump · R: reset"
func _physics_process(_delta:float)->void:
	if not resetting and actor.position.y< -3:_restart(true)
func _restart(wake:=false)->void:
	if resetting:return
	resetting=true;actor.set_physics_process(false)
	var tween:=create_tween();tween.tween_property(fade,"color:a",1.0,.25);await tween.finished
	actor.reset_actor();actor.position=Vector3(28,.02,0)
	if wake:actor.reactions.sit(true)
	_camera(0,true);actor.set_physics_process(true)
	tween=create_tween();tween.tween_property(fade,"color:a",0.0,.4);await tween.finished;resetting=false
