extends SceneTree
var scene:Node3D
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func capture(label:String)->void:
	scene.fade.color.a=0.;scene.instruction.get_parent().get_parent().hide();scene.visibility_budget.refresh()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/Level2Props/"+label+".png")
func run()->void:
	DisplayServer.window_move_to_foreground();OS.low_processor_usage_mode=false
	scene=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(scene);await ticks(12);scene.elapsed=10.
	var actor=scene.actor;actor.reset_actor();actor.position=Vector3(12,.12,0);await ticks(45);scene._camera(0,true);await capture("switch_walkon_purple")
	actor.reset_actor();actor.position=Vector3(8,.02,0);await ticks(8);Input.action_press("miko8_down");await ticks(60);await capture("crouch_hold")
	print("CROUCH_HEAD_HEIGHT ",actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-head")).origin).y)
	Input.action_press("miko8_right",.65);await ticks(24);await capture("crouch_forward");Input.action_release("miko8_right");Input.action_release("miko8_down");await ticks(50)
	actor.reset_actor();actor.position=Vector3(26,.02,0);await ticks(12);scene._camera(0,true);await capture("two_storey_stack")
	actor.position=Vector3(26,2.8,0);await ticks(35);scene._camera(0,true);await capture("stack_middle_storey")
	actor.position=Vector3(26,5.45,0);await ticks(35);scene._camera(0,true);await capture("stack_upper_normal_camera")
	Input.action_press("miko8_down");await ticks(100);await capture("stack_upper_look_down");Input.action_release("miko8_down")
	scene.free();await ticks(3)
	scene=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(scene);await ticks(15);scene.elapsed=10.;actor=scene.actor
	actor.reset_actor();actor.position=Vector3(6,.02,0);await ticks(8);scene._camera(0,true);await capture("ground_no_banner")
	actor.position=Vector3(19,2.85,-.81807);actor.walk_plane_z=-.81807;await ticks(12);scene._camera(0,true);await capture("first_landing_ground_visible")
	print("SWITCH_STACK_CROUCH_VISUAL_REVIEW_DONE");quit()
