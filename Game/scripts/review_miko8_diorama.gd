extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_diorama_rescue.tscn").instantiate();root.add_child(level)
	await create_timer(4).timeout
	for x:float in [27,33,39]:
		level.actor.reset_actor();level.actor.position=Vector3(x-1.5,.02,0);level._camera(0,true)
		await create_timer(1.2).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/DioramaRescue/game_"+str(x)+("_ortho" if "--ortho" in OS.get_cmdline_user_args() else "")+".png")
	print("DIORAMA_REVIEW_DONE actual gameplay captures")
	quit()
