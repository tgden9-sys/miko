extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_ortho_repetition.tscn").instantiate();root.add_child(level)
	await create_timer(3).timeout
	for x:float in [7,32,49]:
		level.actor.reset_actor();level.actor.position=Vector3(x,0.02,0);level._camera(0,true)
		await create_timer(1.0).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/OrthographicJoinTest/textured_"+str(x)+".png")
	level.set_process(false)
	level.actor.position=Vector3(32.5,0.02,0)
	level.camera.size=5.5;level.camera.position=Vector3(33,7,16)
	level.camera.look_at(Vector3(33,0.1,0));level.visibility_budget.refresh()
	await create_timer(0.5).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Source/Environment/OrthographicJoinTest/bridge_godot_detail.png")
	print("TEXTURED_PREVIEW_CAPTURED")
	quit()
