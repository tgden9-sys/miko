extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level)
	await create_timer(3).timeout
	for x:float in [2.4,13,21,27]:
		level.actor.reset_actor();level.actor.position=Vector3(x,.02,0);level._camera(0,true)
		await create_timer(.6).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/SideOnMockup/side_on_"+str(x)+".png")
	level.actor.position.x=13;level._game_size_changed(1)
	await create_timer(.6).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Source/Environment/SideOnMockup/earlier_angle.png")
	print("SIDE_ON_REVIEW_DONE");quit()
