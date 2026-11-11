extends SceneTree
var failures:=0
var results:Array[String]=[]
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func check(ok:bool,label:String)->void:
	results.append(("PASS " if ok else "FAIL ")+label)
	if not ok:failures+=1;push_error(label)
func walk_to(actor:CharacterBody3D,x:float)->void:
	var right:bool=x>actor.position.x;var action:="miko8_right" if right else "miko8_left"
	Input.action_press(action,.35)
	for i in range(600):
		await physics_frame
		if (right and actor.position.x>=x) or (not right and actor.position.x<=x):break
	Input.action_release(action);await ticks(15)
func jump_to(actor:CharacterBody3D,x:float,height:float)->void:
	Input.action_press("miko8_jump");Input.action_press("miko8_right",.65);var landed:=false
	for i in range(100):
		await physics_frame
		if actor.position.x>=x-.08:Input.action_release("miko8_right")
		if i>14 and actor.is_on_floor() and actor.position.y>=height-.07:landed=true;break
	Input.action_release("miko8_jump");Input.action_release("miko8_right");await ticks(18)
	check(landed,"Natural jump reaches %.2f m step/landing"%height)
func run()->void:
	var scene=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(scene);await ticks(20)
	var actor=scene.actor;var switch=get_first_node_in_group("miko8_pressure_switches")
	actor.reset_actor();actor.position=Vector3(10.4,.02,0);await ticks(8);await walk_to(actor,12.)
	check(absf(actor.position.x-12.)<.15 and actor.is_on_floor() and actor.position.y<.12,"MIKO walks onto enlarged switch from left without jumping")
	check(switch.pressed and switch.travel>=switch.BUTTON_TRAVEL-.002 and switch.glow_strength>.9,"Loaded switch depresses and activates purple field")
	await walk_to(actor,13.5);await ticks(20);check(not switch.pressed and switch.glow_strength<.01,"Switch and purple glow release after walking off")
	await walk_to(actor,12.);check(switch.pressed,"MIKO can walk onto switch from right")
	actor.reset_actor();actor.position=Vector3(10.3,.02,0);await ticks(10)
	var crate=scene.get_node("Level2Platforms/SwitchTestCrate");crate.position=Vector3(14,.4,0);crate.linear_velocity=Vector3.ZERO;crate.sleeping=false
	actor.polarity_control.set_polarity(1,true);crate.lock_in_color(Color.BLUE)
	await ticks(240)
	print("DRAG_DIAGNOSTIC actor=",actor.position," crate=",crate.position," velocity=",crate.linear_velocity," polarity=",crate.polarity," suit=",actor.suit_polarity," sleeping=",crate.sleeping)
	check(absf(crate.position.x-12.)<.4 and crate.position.y<.46,"Opposite suit charge drags grounded crate onto switch across its approach")
	check(switch.pressed and switch.glow_strength>.9,"Dragged crate holds switch and purple effect active")
	check(absf(actor.position.x-10.3)<.05,"Dragging crate does not pull MIKO towards stationary switch")
	actor.position=Vector3(16,.02,0);actor.velocity=Vector3.ZERO;await ticks(240)
	check(crate.position.x>13.6 and crate.position.y<.45,"Crate can be dragged off the depressed plate across its inner edge")
	check(not switch.pressed,"Dragging the crate away releases the switch")
	actor.polarity_control.set_polarity(0,true);crate.neutralize();crate.position=Vector3(14,.4,0);crate.linear_velocity=Vector3.ZERO;crate.sleeping=false;await ticks(35)
	check(not switch.pressed,"Removing dragged crate releases switch")
	var props=scene.get_node("Level2Platforms")
	for i in range(2):
		check(props.has_node("BottomSolid%d"%i) and props.has_node("TopOpen%d"%i),"Solid lower / open upper stack %d exists"%i)
		var x:float=25.+5.*i;var space=scene.get_world_3d().direct_space_state
		var ray:=PhysicsRayQueryParameters3D.create(Vector3(x,6,0),Vector3(x,0,0),1);ray.exclude=[actor.get_rid()];var hit:Dictionary=space.intersect_ray(ray)
		check(not hit.is_empty() and absf(hit.position.y-5.26)<.05,"Upper deck %d supports at 5.26 m"%i)
		ray.from=Vector3(x,4.5,0);var middle:Dictionary=space.intersect_ray(ray)
		check(not middle.is_empty() and absf(middle.position.y-2.63)<.05,"Middle deck %d supports at 2.63 m"%i)
	var passage:=PhysicsRayQueryParameters3D.create(Vector3(22,3.6,0),Vector3(33,3.6,0),1);passage.exclude=[actor.get_rid()]
	check(scene.get_world_3d().direct_space_state.intersect_ray(passage).is_empty(),"Both upper open frames leave the middle-storey passage clear")
	actor.reset_actor();actor.position=Vector3(19,.02,0);await ticks(8)
	await jump_to(actor,20.,.8);await jump_to(actor,21.05,1.6);await jump_to(actor,22.9,2.63)
	await walk_to(actor,30.)
	check(actor.position.x>29.9 and actor.is_on_floor() and absf(actor.position.y-2.63)<.08,"MIKO crosses the joined middle decks beneath the open frames")
	check(get_first_node_in_group("miko8_canisters").is_collected,"Middle-storey canister remains collectible")
	actor.reset_actor();actor.position=Vector3(8,.02,0);await ticks(8);scene._camera(0,true)
	var ground_camera_y:float=scene.camera.position.y
	Input.action_press("miko8_down");await ticks(65)
	check(actor.state=="Crouch" and actor.current_clip=="CrouchIdle","Down enters supplied crouch and holds its final pose")
	check(absf(actor.body_collision.shape.height-1.2)<.01,"Crouch uses a smaller capsule")
	check(absf(scene.camera.position.y-ground_camera_y)<.01,"Holding Down at ground level cannot pan below the level")
	var old_x:float=actor.position.x;Input.action_press("miko8_right",.65);await ticks(65);Input.action_release("miko8_right")
	check(actor.current_clip=="CrouchForward" and actor.position.x>old_x+.65,"Supplied forward loop moves MIKO while crouched")
	Input.action_release("miko8_down");await ticks(55)
	check(not actor.state.begins_with("Crouch") and absf(actor.body_collision.shape.height-1.8)<.01,"Release plays exit and restores standing capsule")
	actor.reset_actor();actor.position=Vector3(8,.02,0);await ticks(8);Input.action_press("miko8_down");await ticks(60)
	var overhead:=StaticBody3D.new();var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(4,.2,1.8);collision.shape=box;overhead.add_child(collision);overhead.position=Vector3(8,1.55,0);scene.add_child(overhead);await ticks(3)
	Input.action_release("miko8_down");await ticks(45)
	check(actor.state=="Crouch" and actor.crouch_motion.low_collider,"Releasing Down under low headroom keeps MIKO crouched")
	Input.action_press("miko8_right",.65);await ticks(240);Input.action_release("miko8_right");await ticks(40)
	check(actor.position.x>10.3 and not actor.state.begins_with("Crouch"),"MIKO creeps clear and then stands safely")
	overhead.queue_free();await ticks(3)
	actor.reset_actor();actor.position=Vector3(25,5.5,0);await ticks(40);scene._camera(0,true);var high_camera_y:float=scene.camera.position.y
	Input.action_press("miko8_down");await ticks(100)
	var drop:float=high_camera_y-scene.camera.position.y
	check(drop>.9 and drop<1.6,"Held Down eases camera lower from a higher floor")
	var ground_pixel:Vector2=scene.camera.unproject_position(Vector3(actor.position.x,0,0));var viewport_height:float=root.get_visible_rect().size.y
	check(ground_pixel.y>=0 and ground_pixel.y<viewport_height,"Looking down reveals ground without exposing the lower boundary")
	Input.action_release("miko8_down");await ticks(70);check(absf(scene.camera.position.y-high_camera_y)<.08,"Releasing Down returns camera smoothly")
	scene.free();await ticks(3)
	scene=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(scene);await ticks(20);actor=scene.actor
	var ladder=scene.climb_set.ladder;actor.reset_actor();actor.position=Vector3(ladder.climb_x,.02,0);scene._camera(0,true);await ticks(8)
	Input.action_press("miko8_up");var exit_seen:=false
	for i in range(520):
		await physics_frame
		if actor.state=="ClimbTopExit":exit_seen=true
		if exit_seen and actor.is_on_floor() and not actor.state.begins_with("Climb"):break
	Input.action_release("miko8_up");await ticks(30)
	check(exit_seen and actor.is_on_floor() and scene.camera_floor_y<.02,"One-storey ladder keeps the low camera framing")
	ground_pixel=scene.camera.unproject_position(Vector3(actor.position.x,0,0));check(ground_pixel.y<root.get_visible_rect().size.y,"Ground remains visible from first ladder landing")
	actor.position.x=ladder.climb_x;actor.velocity=Vector3.ZERO;await ticks(5);Input.action_press("miko8_down");await ticks(5)
	check(actor.state.begins_with("Climb"),"Down at the ladder landing descends instead of crouching")
	Input.action_release("miko8_down");actor.reset_actor();ladder=scene.get_node("RooftopBridgeRoute").departure.ladder;actor.position=Vector3(ladder.climb_x,.02,0);scene._camera(0,true);await ticks(8)
	Input.action_press("miko8_up");exit_seen=false
	for i in range(700):
		await physics_frame
		if actor.state=="ClimbTopExit":exit_seen=true
		if exit_seen and actor.is_on_floor() and not actor.state.begins_with("Climb"):break
	Input.action_release("miko8_up");await ticks(30)
	check(exit_seen and actor.is_on_floor() and scene.camera_floor_y>1.5,"Camera still follows the taller ladder to its upper floor")
	var data:={"failures":failures,"checks":results};FileAccess.open("res://../Builds/Validation/Level2Props/walkon_stack_crouch.json",FileAccess.WRITE).store_string(JSON.stringify(data,"  "));print(JSON.stringify(data,"  "));quit(0 if failures==0 else 1)
