extends SceneTree
var failures:=0
var checks:Array[String]=[]
var jumps:Array[Dictionary]=[]
var scene:Node3D
var actor:CharacterBody3D
var course:Node3D

func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func check(ok:bool,label:String)->void:
	checks.append(("PASS " if ok else "FAIL ")+label)
	if not ok:failures+=1;push_error(label)
func release()->void:
	for action:String in ["miko8_left","miko8_right","miko8_up","miko8_down","miko8_jump"]:Input.action_release(action)
func walk_to(x:float)->void:
	var sign_x:=signf(x-actor.position.x)
	var action:="miko8_right" if sign_x>0 else "miko8_left"
	Input.action_press(action,.40)
	for i in range(300):
		await physics_frame
		if (x-actor.position.x)*sign_x<absf(actor.velocity.x)*absf(actor.velocity.x)/76.+.025:break
	Input.action_release(action);await ticks(20)
func climb(tower:Node3D)->void:
	release();actor.reset_actor();actor.position=Vector3(tower.position.x-.8,.02,0)
	await ticks(10);await walk_to(tower.position.x)
	check(actor.is_on_floor() and actor.position.y<.06 and absf(actor.position.x-tower.position.x)<.12,"Ground approach to "+tower.name+" needs no jump")
	Input.action_press("miko8_up");var exited:=false
	for i in range(850):
		await physics_frame
		if actor.state=="ClimbTopExit":exited=true
		if exited and not actor.abilities.bpg_motion.active:break
	Input.action_release("miko8_up");await ticks(45)
	check(exited and actor.is_on_floor() and absf(actor.position.y-tower.deck_height)<.035,"Native ladder exit is supported on "+tower.name)
	check(absf(actor.position.z-tower.WALK_Z)<.035,"Upper walking lane aligns on "+tower.name)
func descend(tower:Node3D)->void:
	await walk_to(tower.position.x);Input.action_press("miko8_down");var entered:=false
	for i in range(850):
		await physics_frame
		if actor.abilities.bpg_motion.active:entered=true
		if entered and not actor.abilities.bpg_motion.active:break
	Input.action_release("miko8_down");await ticks(45)
	check(entered and actor.is_on_floor() and actor.position.y<.06 and absf(actor.position.z)<.035,"Native ladder descent reaches ground on "+tower.name)
func jump_to(from:Node3D,to:Node3D)->void:
	var sign_x:=signf(to.position.x-from.position.x)
	var action:="miko8_right" if sign_x>0 else "miko8_left"
	await walk_to(from.position.x+sign_x*.50)
	var start:Vector3=actor.position;var airborne:=false;var landed:=false;var peak:=actor.position.y
	Input.action_press(action,.65);Input.action_press("miko8_jump")
	for i in range(150):
		await physics_frame;peak=maxf(peak,actor.position.y)
		if (to.position.x-actor.position.x)*sign_x<.23:Input.action_release(action)
		if actor.position.y>start.y+.12:airborne=true
		if airborne and actor.is_on_floor():
			landed=absf(actor.position.y-to.deck_height)<.05 and absf(actor.position.x-to.position.x)<1.0
			break
	release();await ticks(18)
	jumps.append({"from":from.name,"to":to.name,"start":str(start),"end":str(actor.position),"peak_y":peak,"landed":landed})
	check(landed and actor.is_on_floor() and absf(actor.position.y-to.deck_height)<.05,"Normal jump "+from.name+" -> "+to.name)
	check(absf(actor.position.z-to.WALK_Z)<.035,"Depth lane retained for "+from.name+" -> "+to.name)

func run()->void:
	scene=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(scene);await ticks(25)
	actor=scene.actor;course=scene.get_node("PlatformTowerCourse")
	check(course.towers.size()==5,"Five towers lead to the finish stack")
	check(scene.has_node("Level2Platforms/BottomSolid0") and scene.has_node("Level2Platforms/TopOpen1"),"Existing platform stacks retained")
	check(get_nodes_in_group("miko8_pressure_switches").size()==1 and get_nodes_in_group("miko8_canisters").size()==1,"Existing switch and canister retained")
	check(get_nodes_in_group("miko8_ladders").size()==1,"Only the first tower exposes ladder interaction")
	var cap_size:=Vector3.ZERO;var ladder_width:=0.
	for tower:Node3D in course.towers:
		var cap:=tower.model.find_child("MatchedDeck",true,false) as MeshInstance3D
		var ladder_mesh:=tower.model.find_child("ClimbLadder",true,false) as MeshInstance3D
		check(cap!=null and ladder_mesh!=null,"Shared manufactured cap and ladder exist on "+tower.name)
		if cap_size==Vector3.ZERO:cap_size=cap.get_aabb().size;ladder_width=ladder_mesh.get_aabb().size.x
		check(absf(cap.get_aabb().size.x-cap_size.x)<.001 and absf(cap.get_aabb().size.z-cap_size.z)<.001,"Visible cap width/depth match on "+tower.name)
		check(absf(ladder_mesh.get_aabb().size.x-ladder_width)<.001,"Ladder width matches on "+tower.name)
		check(ladder_mesh.visible==tower.front_ladder and (not tower.reverse_face or absf(tower.model.rotation.y-PI)<.001),"End ladder / reversed middle orientation correct on "+tower.name)
		var x:float=tower.position.x
		for sample_x:float in [x-.65,x,x+.65]:
			var query:=PhysicsRayQueryParameters3D.create(Vector3(sample_x,tower.deck_height+1.,tower.WALK_Z),Vector3(sample_x,tower.deck_height-1.,tower.WALK_Z),1)
			query.exclude=[actor.get_rid()]
			var hit:Dictionary=actor.get_world_3d().direct_space_state.intersect_ray(query)
			check(not hit.is_empty() and absf(hit.position.y-tower.deck_height)<.015,"Flat landing support "+tower.name+" x=%.2f"%sample_x)
		if tower.front_ladder:
			await climb(tower);await descend(tower)
		else:
			actor.reset_actor();actor.position=Vector3(x,.02,0);await ticks(8)
			Input.action_press("miko8_up");await ticks(8);Input.action_release("miko8_up")
			check(not actor.state.begins_with("Climb"),"No invisible ladder grab at "+tower.name)
	await climb(course.towers[0])
	for i in range(4):await jump_to(course.towers[i],course.towers[i+1])
	for i in range(4,0,-1):await jump_to(course.towers[i],course.towers[i-1])
	await descend(course.towers[0])
	for takeoff:float in [51.6,52.48]:
		actor.reset_actor()
		actor.position=Vector3(takeoff,3.57,-.81807)
		actor.walk_plane_z=-.81807
		actor.walk_plane_floor_y=3.55
		await ticks(12)
		Input.action_press("miko8_right")
		Input.action_press("miko8_jump")
		var reached:=false
		for i in range(95):
			await physics_frame
			if actor.is_on_floor() and absf(actor.position.y-2.63)<.05 and actor.position.x>54.8:
				reached=true
				break
		release()
		print("FINISH_JUMP ",takeoff," ",reached," ",actor.position)
		check(reached==(takeoff>52.),"Finish jump timing at X %.2f"%takeoff)
	# A missed gap must fall to the real ground and restore its depth lane.
	actor.reset_actor();actor.position=Vector3(41.4,2.9,-.81807);actor.walk_plane_z=-.81807;actor.walk_plane_floor_y=2.8
	await ticks(150)
	check(actor.is_on_floor() and actor.position.y<.06 and absf(actor.position.z)<.035,"Missed jump falls safely to ground lane")
	actor.reset_actor();actor.position=Vector3(45.8,4.32,-.81807);actor.walk_plane_z=-.81807;actor.walk_plane_floor_y=4.3
	await ticks(12);scene._camera(0,true)
	var head:=actor.position+Vector3.UP*1.8
	var pixel:Vector2=scene.camera.unproject_position(head)
	check(pixel.y>0 and pixel.y<root.get_visible_rect().size.y,"Camera keeps MIKO in frame on highest deck")
	release()
	var data:={"failures":failures,"checks":checks,"jumps":jumps}
	FileAccess.open("res://../Builds/Validation/TowerArtRevision/course_checks.json",FileAccess.WRITE).store_string(JSON.stringify(data,"  "))
	print("PLATFORM_TOWER_COURSE_CHECKS ",JSON.stringify(data))
	actor=null;course=null;scene.free();scene=null;await ticks(3)
	quit(0 if failures==0 else 1)
