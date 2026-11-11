extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;push_error(label)
func walk_to(actor:Node,x:float)->void:
	Input.action_press("miko8_right",.6)
	for i in range(300):
		await ticks(1)
		if actor.position.x>=x-actor.velocity.x*actor.velocity.x/76.-.04:break
	Input.action_release("miko8_right");await ticks(20)
func capture(level:Node,label:String)->void:
	if DisplayServer.get_name()=="headless":return
	level.elapsed=maxf(level.elapsed,3.);level.fade.color.a=0.;level._camera(0,true);await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/ThreeLevels/"+label+".png")
func run()->void:
	for index in range(1,4):
		var path:String="res://scenes/miko8_side_on_mockup.tscn" if index==1 else "res://scenes/miko8_level_0%d.tscn"%index
		var level=load(path).instantiate();root.add_child(level);await ticks(20)
		var actor=level.actor;actor.reset_actor();actor.position=Vector3(25.3,.02,0);await ticks(5);level._prompt()
		check("25.3" in level.coordinate_label.text,"HUD must show live X coordinate")
		check(level.level_selector.item_count==3 and level.level_selector.selected==index-1,"Three selectable levels")
		if index>1:
			check(get_nodes_in_group("miko8_ladders").is_empty() and get_nodes_in_group("miko8_charge_targets").is_empty(),"New levels must have no tutorial obstacles")
			for x:int in range(1,80,4):
				var ray:=PhysicsRayQueryParameters3D.create(Vector3(x,2.,0),Vector3(x,-.5,0),1);ray.exclude=[actor.get_rid()]
				var hit=actor.get_world_3d().direct_space_state.intersect_ray(ray);check(not hit.is_empty() and absf(hit.position.y)<.15,"Empty level needs continuous flat ground")
			await capture(level,"level_%d"%index)
		else:
			var crate=level.get_node("TutorialChargeCrate");crate.freeze=true;crate.position=Vector3(26,.4,0)
			for facing:int in [1,-1]:
				actor.reset_actor();actor.position=Vector3(26.-facing*.7,.02,0);actor.facing=facing;actor.visual.rotation.y=facing*PI/2;await ticks(4)
				Input.action_press("miko8_right" if facing==1 else "miko8_left",.35);Input.action_press("miko8_jump");await ticks(2)
				check(actor.state=="Mantle" and actor.current_clip=="ClimbLedge","Jump against crate must use existing climb animation")
				Input.action_release("miko8_right");Input.action_release("miko8_left");Input.action_release("miko8_jump");await ticks(18)
				if DisplayServer.get_name()!="headless":
					level.set_process(false);level.camera.size=4.;level.camera.position=actor.position+Vector3(1.3,1.5,8);level.camera.look_at(actor.position+Vector3(0,.8,0));await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://../Builds/Validation/ThreeLevels/mantle_%d.png"%facing);level.set_process(true)
				await ticks(32)
				check(actor.is_on_floor() and actor.position.y>.75 and actor.position.y<.95,"Mantle must land on crate in either direction")
			var metre=level.get_node("OneMetreMantleCrate");metre.freeze=true
			actor.reset_actor();actor.position=Vector3(26.8,.02,0);await ticks(4)
			Input.action_press("miko8_right",.35);Input.action_press("miko8_jump");await ticks(2);check(actor.state=="Mantle","One metre crate must also support mantle")
			Input.action_release("miko8_right");Input.action_release("miko8_jump");await ticks(50);check(actor.is_on_floor() and actor.position.y>.95 and actor.position.y<1.15,"One metre mantle must land on its actual top")
			crate.reset_charge_body();actor.reset_actor();actor.position=Vector3(8.,.02,0);await ticks(5)
			Input.action_press("miko8_up")
			for i in range(350):
				await ticks(1)
				if actor.position.y>3.4 and not actor.abilities.bpg_motion.active:break
			Input.action_release("miko8_up");await ticks(30)
			check(actor.is_on_floor() and actor.position.y>3.4,"Tower ladder must exit onto deck")
			await capture(level,"tower_route")
			await walk_to(actor,10.9)
			check(actor.is_on_floor() and actor.position.y>3.4,"First catwalk must be walkable")
			Input.action_press("miko8_right",.6);Input.action_press("miko8_jump");await ticks(40);Input.action_release("miko8_jump")
			for i in range(70):
				await ticks(1)
				if actor.is_on_floor():break
			Input.action_release("miko8_right");await ticks(15)
			check(actor.position.x>12.4 and actor.position.y>3.4 and actor.is_on_floor(),"Jump must clear catwalk gap and land on second section")
			await walk_to(actor,15.6);Input.action_press("miko8_down")
			for i in range(350):
				await ticks(1)
				if actor.position.y<.05 and not actor.abilities.bpg_motion.active:break
			Input.action_release("miko8_down");await ticks(20)
			check(actor.is_on_floor() and actor.position.y<.1,"Second tower must return MIKO to ground")
		level.queue_free();await process_frame;await process_frame
	print("THREE_LEVELS_PASS failures=",failures);quit(failures)
