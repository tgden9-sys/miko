extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_miniature_2d.tscn").instantiate();root.add_child(level)
	await create_timer(3).timeout
	for x:float in [4,13.333333,21.333333]:
		level.actor.reset_actor();level.actor.position=Vector3(x,.02,0)
		await create_timer(.7).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/Miniature2D/game_"+str(x)+".png")
		print("MINIATURE_2D_VIEW x=",x," foot=",level.camera.unproject_position(Vector3(x,0,0))," fps=",Engine.get_frames_per_second())
	quit()
