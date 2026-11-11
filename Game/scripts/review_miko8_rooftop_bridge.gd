extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("BRIDGE_FAIL "+message)
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/BridgePlatforms/"+label+".png")
func walk_to(actor:Node,x:float)->void:
	var action:="miko8_right" if x>actor.position.x else "miko8_left"
	Input.action_press(action,.62)
	for i in range(1200):
		await physics_frame
		var stop_distance:float=actor.velocity.x*actor.velocity.x/56.+absf(actor.velocity.x)/60.
		if absf(actor.position.x-x)<maxf(.065,stop_distance):break
	Input.action_release(action);await ticks(20)
	check(absf(actor.position.x-x)<.65,"Must reach rooftop waypoint "+str(x)+" actual="+str(actor.position))
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(150)
	var actor=level.actor;var route=level.get_node("RooftopBridgeRoute");var ladder=route.departure.ladder
	check(not level.has_node("MikoEnergyWake"),"Motion trail must be removed")
	check(actor.polarity_control.graphic_materials[0].shader.resource_path=="res://shaders/miko8_three_tone.gdshader","Keep approved MIKO shading")
	check(route.sections.size()==3 and is_equal_approx(ladder.top_y,5.2),"Three bridge sections and taller ladder must be installed")
	var painted_parts:=0
	for mesh:MeshInstance3D in ladder.find_children("*","MeshInstance3D",true,false):
		var material=mesh.get_active_material(0)
		if material is ShaderMaterial and material.get_shader_parameter("use_vertex_color"):painted_parts+=1
	check(painted_parts>20,"Reusable ladder modules must retain their painted steel vertex palette")
	var gaps:=0
	for i in range(185):
		var x:=30.8+float(i)*.1
		var ray:=PhysicsRayQueryParameters3D.create(Vector3(x,5.9,-.81807),Vector3(x,4.8,-.81807),1)
		ray.exclude=[actor.get_rid()]
		var hit=actor.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() or absf(hit.position.y-5.2)>.08:gaps+=1
	check(gaps==0,"Roof/bridge collision must be continuous; gaps="+str(gaps))
	for wall:Dictionary in [{"x":36.2,"direction":-1.},{"x":43.1,"direction":1.}]:
		for z:float in [-.81807-.52,-.81807+.52]:
			for y:float in [2.53,4.73]:
				var ray:=PhysicsRayQueryParameters3D.create(Vector3(wall.x-wall.direction*.30,y,z),Vector3(wall.x+wall.direction*.30,y,z),1)
				ray.exclude=[actor.get_rid()]
				var hit=actor.get_world_3d().direct_space_state.intersect_ray(ray)
				check(not hit.is_empty() and absf(hit.position.x-wall.x)<.10,"Bridge receiver must meet solid wall at "+str(Vector3(wall.x,y,z)))
	if "--visual-only" in OS.get_cmdline_user_args():
		actor.reset_actor();actor.position=Vector3(39.8,5.22,-.81807);actor.walk_plane_z=-.81807;actor.walk_plane_floor_y=5.2
		level._camera(0,true);await ticks(20);await capture("bridge_overview")
		actor.reset_actor();actor.position=Vector3(18.3,.02,0);level._camera(0,true);await ticks(15);await capture("industrial_ladder_original")
		print("BRIDGE_VISUAL_READY failures=",failures," ladder_painted_parts=",painted_parts);quit(failures);return
	actor.reset_actor();actor.position=Vector3(ladder.climb_x-.15,.02,0);level._camera(0,true);await ticks(10)
	await capture("tall_ladder_ground")
	Input.action_press("miko8_up");await ticks(680);Input.action_release("miko8_up");await ticks(35)
	check(actor.is_on_floor() and absf(actor.position.y-5.2)<.05 and actor.position.z<-.5,"Tall ladder must exit onto supported roof")
	await capture("tall_ladder_roof")
	await walk_to(actor,39.8)
	check(actor.is_on_floor() and absf(actor.position.y-5.2)<.06,"Middle bridge deck must support MIKO")
	await capture("bridge_overview")
	await walk_to(actor,48.2)
	check(actor.is_on_floor() and absf(actor.position.y-5.2)<.06,"Walk from bridge onto arrival roof")
	await capture("arrival_roof")
	await walk_to(actor,ladder.climb_x)
	print("BRIDGE_RETURN_PRE_DESCEND ",actor.position," ",actor.state," mode=",actor.abilities.bpg_motion.mode)
	Input.action_press("miko8_down");await ticks(900);Input.action_release("miko8_down");await ticks(35)
	print("BRIDGE_RETURN_POST_DESCEND ",actor.position," ",actor.state," mode=",actor.abilities.bpg_motion.mode," active=",actor.abilities.bpg_motion.active)
	check(actor.is_on_floor() and actor.position.y<.05 and actor.collision_mask==1,"Return across bridge and descend tall ladder")
	# Original ladder still uses the accepted source motions and roof height.
	actor.reset_actor();actor.position=Vector3(18.3,.02,0);level._camera(0,true);await ticks(8)
	await capture("industrial_ladder_original")
	Input.action_press("miko8_up");await ticks(410);Input.action_release("miko8_up");await ticks(35)
	check(actor.is_on_floor() and absf(actor.position.y-2.83364)<.05,"Original ladder remains climbable")
	print("ROOFTOP_BRIDGE_","PASS" if failures==0 else "FAIL"," failures=",failures," collision_gaps=",gaps," ladder_painted_parts=",painted_parts)
	quit(failures)
