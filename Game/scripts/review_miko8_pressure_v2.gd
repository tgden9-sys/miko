extends SceneTree
var scene:Node3D
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func capture(label:String)->void:
	scene.fade.color.a=0.;scene.instruction.get_parent().get_parent().hide()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/Level2Props/"+label+".png")
func run()->void:
	DisplayServer.window_move_to_foreground();OS.low_processor_usage_mode=false
	scene=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(scene);await ticks(15);scene.elapsed=10.;scene.fade.color.a=0.
	var actor=scene.actor;var crate=scene.get_node("Level2Platforms/SwitchTestCrate");actor.reset_actor();actor.position=Vector3(10.3,.02,0);await ticks(30);scene._camera(0,true)
	await capture("pressure_v2_game_ready")
	actor.position=Vector3(12,.20,0);await ticks(45);scene._camera(0,true);await capture("pressure_v2_game_pressed")
	actor.position=Vector3(10.3,.02,0);actor.hide();actor.set_physics_process(false);await ticks(30);scene.set_process(false)
	for layer:CanvasLayer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	scene.camera.size=1.9;scene.camera.global_position=Vector3(10.2,2.4,4.);scene.camera.look_at(Vector3(12,.03,0));await ticks(8)
	await capture("pressure_v2_asset_ready")
	crate.position=Vector3(12,.51,0);crate.linear_velocity=Vector3.ZERO;crate.sleeping=false;await ticks(60);await capture("pressure_v2_asset_pressed")
	print("PRESSURE_V2_VISUAL_DONE");quit()
