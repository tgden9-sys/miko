extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_ortho_repetition.tscn").instantiate();root.add_child(level)
	await create_timer(3).timeout
	for x:float in [10,20,33,45,50]:
		level.actor.reset_actor();level.actor.position=Vector3(x-1.5,0.02,0);level._camera(0,true)
		await create_timer(0.5).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/OrthographicJoinTest/main_backdrop_"+str(x)+".png")
	print("MAIN_BACKDROP_REVIEW: five normal-camera captures saved")
	quit()
