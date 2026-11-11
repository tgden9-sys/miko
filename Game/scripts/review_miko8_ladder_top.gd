extends SceneTree
var failures:=0
var samples:=0
var max_hand_error:=0.0
var max_foot_error:=0.0
var supported_plants:=0
var unsupported_plants:=0
var data:Dictionary
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for frame in range(count):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("LADDER_TOP_FAIL: "+message)
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/LadderTransitions/"+label+".png")
func contact_sample(actor:Node,ladder:Node3D)->void:
	var motion=actor.abilities.top_motion
	if not motion.active:return
	var clip:Dictionary=data.clips[motion.label]
	var phase:float=motion.elapsed/motion.duration
	if phase<.15 or phase>.95:return
	var floating:float=phase*(clip.contacts.size()-1)
	var frame:int=mini(int(floating),clip.contacts.size()-2)
	var sample:Dictionary=clip.contacts[frame]
	for key:String in sample.active:
		if not sample.active[key]:continue
		var parts:=key.split("_");var bone:String="DEF-"+parts[0]+"."+parts[1]
		var expected:Array=sample.targets[key]
		var next:Array=clip.contacts[frame+1].targets[key]
		var target:=Vector3(ladder.climb_x,ladder.top_y,0)+Vector3(expected[0],expected[1],expected[2]).lerp(Vector3(next[0],next[1],next[2]),floating-frame)
		var actual:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone(bone)).origin)
		var error:=actual.distance_to(target)
		if key.begins_with("hand"):max_hand_error=maxf(max_hand_error,error)
		else:max_foot_error=maxf(max_foot_error,error)
		if key.begins_with("foot") and target.y>ladder.top_y+.05:
			var query:=PhysicsRayQueryParameters3D.create(actual+Vector3.UP*.08,actual-Vector3.UP*.25,1)
			query.exclude=[actor.get_rid()]
			var hit:Dictionary=actor.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty():unsupported_plants+=1
			else:supported_plants+=1
		samples+=1
func run()->void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://models/miko8/MIKO8_LadderTop.json"))
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(150)
	var actor=level.actor;var ladder=level.climb_set.ladder
	actor.reset_actor();actor.position=Vector3(ladder.climb_x-.2,.02,0);level._camera(0,true);await ticks(10)
	Input.action_press("miko8_up")
	await ticks(2)
	check(actor.state=="ClimbHold" and actor.current_clip=="StockLadderUp","Bottom grab must still begin climbing immediately")
	var out_frames:=0;var last_sample:=-1
	for frame in range(420):
		await physics_frame
		if actor.state=="ClimbTopExit":
			out_frames+=1;contact_sample(actor,ladder)
			var index:int=mini(5,int(actor.abilities.top_motion.elapsed/actor.abilities.top_motion.duration*6))
			if index!=last_sample:last_sample=index;await capture("game_out_"+str(index))
		if out_frames>0 and not actor.state.begins_with("Climb"):break
	Input.action_release("miko8_up");await ticks(15)
	print("LADDER_TOP_EXIT ",actor.position," state=",actor.state," grounded=",actor.is_on_floor())
	check(out_frames>25,"Exit must play a real authored transition")
	check(actor.is_on_floor() and absf(actor.position.y-ladder.top_y)<.04 and absf(actor.position.z)<.015,"Exit must hand off to grounded walking on the original lane")
	check(actor.position.x>=ladder.climb_x+.65 and actor.collision_mask==1,"Exit must finish on the supported main landing with collision restored")
	Input.action_press("miko8_right",.35);await ticks(45);Input.action_release("miko8_right");await ticks(8)
	check(actor.is_on_floor() and actor.position.x>19.4,"MIKO must walk normally away from the ladder")
	Input.action_press("miko8_down");await ticks(5);Input.action_release("miko8_down")
	check(not actor.state.begins_with("Climb"),"Down away from the entry mark must not grab the ladder")
	# Start descending at the standard top entry mark, using the actual input.
	actor.reset_actor();actor.position=Vector3(ladder.get_meta("top_entry_x"),ladder.top_y+.01,0);await ticks(8)
	Input.action_press("miko8_down")
	var in_frames:=0;last_sample=-1
	for frame in range(420):
		await physics_frame
		if actor.state=="ClimbTopEnter":
			in_frames+=1;contact_sample(actor,ladder)
			var index:int=mini(5,int(actor.abilities.top_motion.elapsed/actor.abilities.top_motion.duration*6))
			if index!=last_sample:last_sample=index;await capture("game_in_"+str(index))
		if in_frames>0 and actor.state=="ClimbHold":break
	Input.action_release("miko8_down");await ticks(12)
	check(in_frames>25 and actor.state=="ClimbHold","Down near the marked landing must play the return transition then hold the ladder")
	var held:Vector3=actor.position;await ticks(15)
	check(actor.position.distance_to(held)<.001,"Released descent input must hold the rung")
	Input.action_press("miko8_down")
	for frame in range(300):
		await physics_frame
		if not actor.state.begins_with("Climb"):break
	Input.action_release("miko8_down");await ticks(15)
	check(actor.is_on_floor() and absf(actor.position.y)<.04 and actor.collision_mask==1,"Descent must restore grounded movement at the bottom")
	print("LADDER_CONTACTS samples=",samples," max_hand_m=",max_hand_error," max_foot_m=",max_foot_error)
	check(samples>50 and max_hand_error<.04 and max_foot_error<.04,"Planted hand/foot contacts must stay within 4cm in the real game rig")
	check(supported_plants>20 and unsupported_plants==0,"Every planted roof foot must have actual landing collision beneath it")
	# Reset and jump must safely interrupt either committed top transition.
	actor.reset_actor();actor.position=Vector3(ladder.climb_x,ladder.top_y-.96,0)
	Input.action_press("miko8_up");await ticks(12);Input.action_release("miko8_up")
	check(actor.abilities.top_motion.active,"Reset interruption test must reach the exit clip")
	actor.reset_actor();await ticks(2)
	check(not actor.abilities.top_motion.active and actor.collision_mask==1 and actor.model.position.is_zero_approx(),"Reset during the clip must clear motion and restore collision")
	actor.reset_actor();actor.position=Vector3(ladder.get_meta("top_entry_x"),ladder.top_y+.01,0);await ticks(8)
	Input.action_press("miko8_down");await ticks(18);Input.action_release("miko8_down")
	Input.action_press("miko8_jump");await ticks(3);Input.action_release("miko8_jump")
	check(not actor.abilities.top_motion.active and actor.collision_mask==1 and actor.state=="Air","Jump must detach cleanly during ladder entry")
	# Approaching from the right should also turn toward the rails and descend.
	actor.reset_actor();actor.position=Vector3(ladder.get_meta("top_entry_x"),ladder.top_y+.01,0)
	actor.facing=-1;actor.target_facing=-1;actor.visual.rotation.y=-PI/2;await ticks(8)
	Input.action_press("miko8_down");await ticks(110);Input.action_release("miko8_down")
	check(actor.state=="ClimbHold" and not actor.abilities.top_motion.active and absf(angle_difference(actor.visual.rotation.y,PI))<.01,"Entry from a left-facing approach must finish aligned to the ladder")
	level.layered_scenery.set_brightness(.5)
	check(is_equal_approx(level.layered_scenery.city_card.material_override.albedo_color.r,.5),"Scenery brightness must still apply to the distant city")
	for record:Dictionary in level.layered_scenery.flat_art:
		check(is_equal_approx(record.mesh.material_override.albedo_color.r,.5),"Scenery brightness must still apply to the nearby yard")
	level.layered_scenery.set_brightness(.7)
	actor.reset_actor()
	var report:={"failures":failures,"samples":samples,"max_hand_error_m":max_hand_error,"max_foot_error_m":max_foot_error,"out_frames":out_frames,"in_frames":in_frames,"supported_roof_plants":supported_plants,"unsupported_roof_plants":unsupported_plants}
	FileAccess.open("res://../Builds/Validation/LadderTransitions/game_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("LADDER_TOP_", "PASS" if failures==0 else "FAIL", " report=",report)
	quit(0 if failures==0 else 1)
