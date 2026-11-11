extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_ortho_repetition.tscn").instantiate();root.add_child(level)
	await create_timer(3).timeout
	var suffix:="_baseline" if "--restored-baseline" in OS.get_cmdline_user_args() else "_enhanced"
	if level._continuous_yard():suffix+="_yard"
	if level.view_height>12.0:suffix+="_wide"
	for x:float in [6,24,33,42,54]:
		level.actor.reset_actor();level.actor.position=Vector3(x,.02,0);level._camera(0,true)
		await create_timer(.7).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/RestoredHybrid/view_"+str(x)+suffix+".png")
	print("RESTORED_REVIEW_DONE ",suffix)
	quit()
