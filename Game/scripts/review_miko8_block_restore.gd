extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;push_error(label)
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(20)
	var actor=level.actor;actor.reset_actor();actor.position=Vector3(40,.02,0)
	var a=level.get_node("TutorialChargeCrate");var b=level.get_node("WorkshopCrateStep")
	a.position=Vector3(23,.5,0);b.position=Vector3(29,.5,0);a.lock_in_color(Color.RED);b.lock_in_color(Color.BLUE)
	await ticks(30);check(a.position.x>23.01 and b.position.x<28.99,"Fields must couple beyond the old 4m limit")
	a.position=Vector3(24,.5,0);b.position=Vector3(24.85,.5,0);a.linear_velocity=Vector3.ZERO;b.linear_velocity=Vector3.ZERO;b.lock_in_color(Color.RED)
	await ticks(3);check(a.repulsion_count>0 and b.repulsion_count>0,"Close matching poles must kick apart")
	check(a.breakaway_remaining>1.8 and b.breakaway_remaining>1.8,"Repulsion must provide breakaway time")
	b.lock_in_color(Color.BLUE);check(a.breakaway_remaining>0.,"Recolour must not cancel breakaway")
	a.neutralize();check(a.polarity==0 and a.breakaway_remaining==0.,"Discharge must clear field and breakaway")
	a.freeze=true;b.freeze=true;a.position=Vector3(23,.5,0);b.position=Vector3(28,.5,0);a.lock_in_color(Color.RED);b.lock_in_color(Color.BLUE);a.breakaway_remaining=0.;b.breakaway_remaining=0.
	actor.position=Vector3(25,.02,0);level._camera(0,true);level.visibility_budget.refresh();a.set_camera_active(true);b.set_camera_active(true);await ticks(20)
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		check(level.get_node("BlockMagneticFields").get_child(0).link_count>0,"Visible field links must render")
		root.get_texture().get_image().save_png("res://../Builds/Validation/Launcher/restored_fields.png")
	actor.reset_actor();actor.position=Vector3(18.3,.02,0);await ticks(8);Input.action_press("miko8_up");await ticks(60);Input.action_release("miko8_up")
	var modifier=actor.skeleton.get_children().filter(func(n):return n.get_script()==load("res://scripts/miko8_ladder_foot_forward.gd"))[0]
	check(modifier.maximum_yaw_error<.01,"Climbing toes must point straight into the ladder")
	check(modifier.modification_count>0,"Foot correction must execute in the engine skeleton callback")
	if DisplayServer.get_name()!="headless":
		level.set_process(false);level.camera.size=3.5;level.camera.global_position=actor.position+Vector3(1,1,8);level.camera.look_at(actor.position+Vector3(0,1,0))
		await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://../Builds/Validation/Launcher/restored_feet.png")
	print("BLOCK_RESTORE_PASS failures=",failures," foot_yaw=",modifier.maximum_yaw_error," corrections=",modifier.modification_count)
	level.queue_free();await process_frame;await process_frame;quit(failures)
