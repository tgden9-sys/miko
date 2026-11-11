extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for frame in range(count):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("CRATE_STEPS_FAIL: "+message)
func jump_to(actor:Node,target_x:float,target_y:float,strength:=.35,rim_allowance:=0.0)->bool:
	Input.action_press("miko8_jump");Input.action_press("miko8_right",strength)
	var released:=false
	for frame in range(150):
		await physics_frame
		if not released and actor.position.x>=target_x:
			Input.action_release("miko8_right");released=true
		if frame>20 and actor.is_on_floor():
			Input.action_release("miko8_jump");Input.action_release("miko8_right")
			await ticks(8)
			return absf(actor.position.y-target_y)<.04 or (rim_allowance>0. and actor.position.y>=target_y and actor.position.y<=target_y+rim_allowance)
	Input.action_release("miko8_jump");Input.action_release("miko8_right");return false
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(150)
	var actor=level.actor
	actor.reset_actor();actor.position=Vector3(49.9,.02,0);level._camera(0,true);await ticks(15)
	check(await jump_to(actor,50.9,.8),"First input-driven jump must land on the single crate")
	print("CRATE_STEP_LANDED ",actor.position)
	check(await jump_to(actor,51.8,1.6),"Second input-driven jump must land on the double stack")
	print("CRATE_STACK_LANDED ",actor.position)
	# Walk fully onto the stack before jumping the final gap to the roof.
	Input.action_press("miko8_right",.35)
	for frame in range(70):
		await physics_frame
		if actor.position.x>=51.85:break
	Input.action_release("miko8_right");await ticks(8)
	var workshop=level.get_node("ServiceBlockObstacle")
	var roof:float=workshop.to_global(Vector3(0,workshop.HEIGHT*workshop.height_scale-1.25,0)).y
	check(await jump_to(actor,53.15,roof,.65,.16),"Jump from the stack must reach the roof or its real raised rim")
	print("WORKSHOP_RIM_LANDED ",actor.position," inner_roof=",roof)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/Workshop/roof_rim_landing.png")
	Input.action_press("miko8_right",.35);await ticks(70);Input.action_release("miko8_right");await ticks(12)
	check(actor.is_on_floor() and actor.position.x>53.2 and absf(actor.position.y-roof)<.04,"MIKO must walk off the entry rim onto the lower roof surface")
	# Ray-check side bars, front/back bars and all four higher corner caps.
	for sample:Vector3 in [Vector3(-2.935,4.122,0),Vector3(2.935,4.122,0),Vector3(0,4.120,-1.33),Vector3(0,4.120,1.33),Vector3(-2.97,4.187,-1.34),Vector3(-2.97,4.187,1.34),Vector3(2.97,4.187,-1.34),Vector3(2.97,4.187,1.34)]:
		var point:Vector3=workshop.to_global(Vector3(sample.x,(sample.y-workshop.BASE_SINK)*workshop.height_scale-1.25,sample.z))
		var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.5,point-Vector3.UP*.4,1)
		query.exclude=[actor.get_rid()]
		var hit:Dictionary=level.get_world_3d().direct_space_state.intersect_ray(query)
		check(hit.get("collider")==workshop and absf(hit.get("position",Vector3.ZERO).y-point.y)<.015,"Each raised rim/corner collider must match its mesh-measured top")
	# The exit lip is now solid too; walking must stop there until he hops it.
	Input.action_press("miko8_right",.35);await ticks(300);Input.action_release("miko8_right");await ticks(8)
	check(actor.is_on_floor() and actor.position.x<57.7 and actor.position.y>roof-.04,"Opposite raised edge must stop walking rather than be passed through")
	check(await jump_to(actor,59.0,0.,.65),"A normal hop must clear the exit rim and land on the yard")
	print("WORKSHOP_RIM_EXIT ",actor.position)
	actor.reset_actor();actor.position=Vector3(54.2,roof+.05,0);level._camera(0,true);await ticks(15)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/Workshop/crate_steps_top.png")
	actor.reset_actor();actor.position=Vector3(49.5,.02,0);level._camera(0,true);await ticks(15)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/Workshop/crate_steps_approach.png")
	print("CRATE_STEPS_", "PASS" if failures==0 else "FAIL", " failures=",failures)
	quit(0 if failures==0 else 1)
