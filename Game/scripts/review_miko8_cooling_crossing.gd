extends SceneTree
var level:Node3D
var failures:Array[String]=[]
const OUT:="res://../Builds/Validation/CoolingCrossing/"
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func check(ok:bool,label:String)->void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures.append(label)
func capture(label:String,detail:=false)->void:
	if DisplayServer.get_name()=="headless":return
	level.set_process(false);level.visibility_budget.set_process(false)
	level._camera(0,true)
	if detail:
		level.camera.size=7.3;level.camera.global_position=Vector3(66.,1.6,0)+level.camera.global_basis.z*18.
	level.camera.set_meta("walkway_focus_x",66.);level.visibility_budget.refresh()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+label+".png"))
	level.set_process(true)
func run()->void:
	level=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(level);current_scene=level
	await ticks(15);level.elapsed=10.;level.fade.color.a=0.
	check(level.find_child("CoolingStationWalls",true,false)!=null,"custom station building is present")
	check(level.get_node("NearBuildingDistrict").find_child("Building08",true,false)==null,"original facade removed from station plot")
	level.instruction.get_parent().get_parent().hide()
	var actor=level.actor;actor.reset_actor();actor.position=Vector3(63.5,.02,0);await ticks(20)
	Input.action_press("miko8_right",.65);await ticks(120);Input.action_release("miko8_right")
	check(actor.position.x<64.90 and actor.position.x>64.20,"standing movement blocked at duct")
	print("BLOCKED ",actor.position)
	await capture("01_approach",true)
	Input.action_press("miko8_down");await ticks(80);Input.action_press("miko8_right",.65)
	var timeout:=0
	while actor.position.x<66. and timeout<600:await ticks(1);timeout+=1
	Input.action_release("miko8_right");await ticks(10)
	check(actor.position.x>65.8,"crouch reaches underneath")
	print("CROUCH_HEAD ",actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-head")).origin))
	await capture("02_underneath",true);await capture("03_gameplay")
	Input.action_release("miko8_down");await ticks(75)
	check(actor.state.begins_with("Crouch") and actor.crouch_motion.low_collider,"releasing Down under duct keeps Miko crouched")
	Input.action_press("miko8_right",.65);timeout=0
	while actor.position.x<68.2 and timeout<600:await ticks(1);timeout+=1
	Input.action_release("miko8_right");await ticks(100)
	check(actor.position.x>68. and not actor.crouch_motion.low_collider,"exit restores standing without snagging")
	# Return through the same passage to verify both entrances.
	Input.action_press("miko8_down");await ticks(80);Input.action_press("miko8_left",.65);timeout=0
	while actor.position.x>63.8 and timeout<900:await ticks(1);timeout+=1
	Input.action_release("miko8_left");Input.action_release("miko8_down");await ticks(100)
	check(actor.position.x<64. and not actor.crouch_motion.low_collider,"return passage and standing exit")
	print("COOLING_CROSSING_REVIEW_DONE failures=",failures)
	quit(0 if failures.is_empty() else 1)
