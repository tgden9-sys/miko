extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	for number in [1,2,3]:
		var scene=load("res://scenes/miko8_side_on_mockup.tscn" if number==1 else "res://scenes/miko8_level_0%d.tscn"%number).instantiate();root.add_child(scene)
		for f in range(12):await process_frame
		scene.elapsed=10.;scene.fade.color.a=0.;scene.actor.reset_actor();scene.actor.set_physics_process(false);scene.set_process(false)
		for x in ([8.,12.,25.,44.,50.,72.] if number==2 else [8.,25.,50.,72.]):
			scene.actor.position=Vector3(x,0,0);scene._camera(0,true);scene._prompt();scene.visibility_budget.refresh()
			for f in range(5):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../Builds/Validation/Level2Props/level%d_x%d.png"%[number,int(x)])
		scene.actor.position=Vector3(50,5.2,0);scene._camera(0,true);scene._prompt();scene.visibility_budget.refresh()
		for f in range(5):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/Level2Props/level%d_elevated.png"%number)
		scene.free();await process_frame
	quit()
