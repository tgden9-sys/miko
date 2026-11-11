extends SceneTree
var scene:Node3D
var actor:CharacterBody3D
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func capture(label:String,close:=false,tower_x:=40.,focus_y:=1.7)->void:
	scene.elapsed=10.;scene.fade.color.a=0.;scene.instruction.get_parent().get_parent().hide();scene._camera(0,true)
	if close:
		scene.camera.size=6.5
		var target:=Vector3(tower_x,focus_y,-.65)
		scene.camera.position=target+scene.camera.basis.z*(18./scene.camera.basis.z.z)
	else:
		scene.camera.position+=scene.camera.basis.x*(46.8-float(scene.camera.get_meta("walkway_focus_x")))
		scene.camera.set_meta("walkway_focus_x",46.8)
	scene.visibility_budget.refresh();scene.set_process(false)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/TowerArtRevision/"+label+".png")
	scene.set_process(true)
func run()->void:
	DisplayServer.window_move_to_foreground();OS.low_processor_usage_mode=false
	scene=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(scene);await ticks(20);actor=scene.actor
	actor.reset_actor();actor.position=Vector3(40.,.02,0);await ticks(15)
	await capture("course_overview")
	if "--finish-only" in OS.get_cmdline_user_args():
		await capture("finish_end_close",true,40.,1.7)
		actor.reset_actor();actor.position=Vector3(45.8,4.32,-.81807);actor.walk_plane_z=-.81807;actor.walk_plane_floor_y=4.3
		await ticks(15);await capture("finish_reversed_close",true,47.25,3.)
		print("TOWER_FINISH_REVIEW_DONE");quit();return
	await capture("small_ground_access",true,40.,1.65)
	Input.action_press("miko8_up")
	for i in range(600):
		await physics_frame
		if actor.abilities.bpg_motion.active and actor.position.y>.85:break
	Input.action_release("miko8_up");await ticks(8);await capture("small_climbing",true,40.,1.9)
	Input.action_press("miko8_up")
	for i in range(700):
		await physics_frame
		if actor.state=="ClimbTopExit":break
	await ticks(10);await capture("small_top_exit",true,40.,2.25)
	for i in range(200):
		await physics_frame
		if not actor.abilities.bpg_motion.active:break
	Input.action_release("miko8_up");await ticks(45);await capture("small_top_standing",true,40.,2.25)
	actor.reset_actor();actor.position=Vector3(45.8,4.32,-.81807);actor.walk_plane_z=-.81807;actor.walk_plane_floor_y=4.3
	await ticks(30);await capture("large_top_standing",true,45.8,3.1)
	await capture("matched_rear_faces",true,47.25,3.)
	actor.reset_actor();actor.position=Vector3(55.6,2.65,-.81807);actor.walk_plane_z=-.81807;actor.walk_plane_floor_y=2.63
	await ticks(15);await capture("finish_stack",true,55.8,2.6)
	print("PLATFORM_TOWER_VISUAL_REVIEW_DONE");quit()
