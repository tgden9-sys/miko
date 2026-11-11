extends SceneTree
var failures:=0
var checked:=0
var max_source_error:=0.
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("BPG_FAIL "+message)
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/BPGLadder/"+label+".png")
func measure(actor:Node)->void:
	var motion=actor.abilities.bpg_motion
	if not motion.active or motion.elapsed/motion.duration<.25 or motion.elapsed/motion.duration>.95:return
	var data:Dictionary=motion.clip(motion.label)
	var frame:float=motion.elapsed/motion.duration*(data.frames.size()-1);var index:=mini(int(frame),data.frames.size()-2)
	for bone:String in ["hand.L","hand.R","foot.L","foot.R"]:
		var a:Array=data.effectors[index][bone];var b:Array=data.effectors[index+1][bone]
		var target:Vector3=motion.origin+motion.point(a).lerp(motion.point(b),frame-index)
		var actual:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-"+bone)).origin)
		max_source_error=maxf(max_source_error,target.distance_to(actual));checked+=1
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(150)
	var actor=level.actor;var ladder=level.climb_set.ladder
	for label:String in actor.metadata.bpg_ladder.clips:
		check(actor.clips.has(label),"All 16 source clips must be installed: "+label)
	actor.reset_actor();actor.position=Vector3(ladder.climb_x-.15,.02,0);level._camera(0,true);await ticks(8)
	Input.action_press("miko8_up")
	var captured:={};var saw_top:=false
	for i in range(900):
		await physics_frame
		var motion=actor.abilities.bpg_motion
		if motion.active:
			measure(actor)
			var key:String=motion.label+"_"+str(int(motion.elapsed/motion.duration*4))
			if not captured.has(key):captured[key]=true;await capture("game_"+key)
			if actor.state=="ClimbTopExit":saw_top=true
		elif saw_top:break
	Input.action_release("miko8_up");await ticks(12)
	print("BPG_TOP ",actor.position," state=",actor.state," grounded=",actor.is_on_floor())
	check(saw_top and actor.is_on_floor() and absf(actor.position.y-ladder.top_y)<.04,"Supplied top exit must finish on the real upper floor")
	check(actor.collision_mask==1 and actor.position.z<-.5,"Top exit must retain the source forward step onto its supported landing")
	for side:String in ["L","R"]:
		var foot:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-foot."+side)).origin)
		var ray:=PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.10,foot-Vector3.UP*.25,1)
		ray.exclude=[actor.get_rid()]
		check(not actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Each standing foot must have landing collision beneath it")
	await capture("game_top_standing")
	while actor.state=="Turn":await ticks(1)
	Input.action_press("miko8_right",.35);await ticks(45);Input.action_release("miko8_right");await ticks(8)
	print("WALK_DIAGNOSTIC ",actor.position," ",actor.state," floor=",actor.is_on_floor())
	check(actor.is_on_floor() and actor.position.x>ladder.climb_x+.5,"Walking away along the upper floor must stay supported")
	Input.action_press("miko8_down");await ticks(3);Input.action_release("miko8_down")
	check(not actor.abilities.bpg_motion.active,"Down away from the ladder must not grab")
	actor.position.x=ladder.climb_x;actor.velocity=Vector3.ZERO;await ticks(4)
	Input.action_press("miko8_down")
	var saw_entry:=false
	for i in range(900):
		await physics_frame
		var motion=actor.abilities.bpg_motion
		if motion.active:
			measure(actor)
			var key:String=motion.label+"_"+str(int(motion.elapsed/motion.duration*4))
			if not captured.has(key):captured[key]=true;await capture("game_"+key)
			if actor.state=="ClimbTopEnter":saw_entry=true
		elif saw_entry:break
	Input.action_release("miko8_down");await ticks(12)
	check(saw_entry and actor.is_on_floor() and actor.position.y<.04 and actor.collision_mask==1,"Source top entry and bottom exit must return to ground")
	print("BPG_GROUND ",actor.position," contacts=",checked," source_error_m=",max_source_error)
	check(checked>100 and max_source_error<.045,"Runtime poses and root travel must reproduce the retargeted source")
	# Hold, reverse, look, jump and reset on the actual input path.
	actor.reset_actor();actor.position=Vector3(ladder.climb_x,.02,0);await ticks(3)
	Input.action_press("miko8_up");await ticks(65);Input.action_release("miko8_up");await ticks(45)
	var held:Vector3=actor.position;await ticks(25)
	check(actor.position.distance_to(held)<.005 and actor.abilities.bpg_motion.mode=="idle","Release must settle into a supplied idle and hold")
	Input.action_press("miko8_aim_up");await ticks(8);Input.action_release("miko8_aim_up")
	Input.action_press("miko8_up");await ticks(25);Input.action_release("miko8_up")
	Input.action_press("miko8_down");await ticks(55);Input.action_release("miko8_down")
	check(actor.position.y<held.y+.3,"Reversal must select supplied descending steps")
	Input.action_press("miko8_jump");await ticks(3);Input.action_release("miko8_jump")
	check(not actor.abilities.bpg_motion.active and actor.collision_mask==1,"Jump detaches and restores collision")
	actor.reset_actor();check(actor.walk_plane_z==0 and not actor.abilities.bpg_motion.active,"Reset restores the original floor lane")
	# The second ladder review uses the same pack and a separately fitted landing.
	level.queue_free();await ticks(3)
	var review=load("res://scenes/miko8_movement_test.tscn").instantiate();root.add_child(review);await ticks(30)
	var review_actor=review.actor
	review_actor.reset_actor();review_actor.position=Vector3(18,.02,0);await ticks(5)
	Input.action_press("miko8_up");await ticks(420);Input.action_release("miko8_up");await ticks(12)
	check(review_actor.is_on_floor() and absf(review_actor.position.y-3.2)<.04 and review_actor.position.z<-.5,"The movement-review ladder must also use the supplied top exit")
	FileAccess.open("res://../Builds/Validation/BPGLadder/game_validation.json",FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"samples":checked,"max_source_error_m":max_source_error},"  "))
	print("BPG_LADDER_","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
