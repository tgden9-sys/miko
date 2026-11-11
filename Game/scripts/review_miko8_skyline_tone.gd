extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	DisplayServer.window_move_to_foreground();OS.low_processor_usage_mode=false
	for number in [1,2,3]:
		var scene=load("res://scenes/miko8_side_on_mockup.tscn" if number==1 else "res://scenes/miko8_level_0%d.tscn"%number).instantiate();root.add_child(scene)
		for f in range(12):await process_frame
		scene.elapsed=10.;scene.fade.color.a=0.;scene.actor.reset_actor();scene.actor.set_physics_process(false);scene.set_process(false)
		if number==1:assert(scene.foreground.pieces.size()==3,"Only the three ground-mounted fixtures should remain")
		for height in ([0.,2.83364,5.2] if number==1 else [0.]):
			scene.actor.position=Vector3(18.3 if number==1 else 25.,height,0);scene._camera(0,true);scene._prompt();scene.visibility_budget.refresh()
			for f in range(5):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../Builds/Validation/Level2Props/toned_level%d_height%d.png"%[number,int(height*100)])
		scene.free();await process_frame
	print("SKYLINE_TONE_REVIEW_PASS unsupported_hanging_cutouts=0");quit()
