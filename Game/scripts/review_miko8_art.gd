extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_tutorial.tscn").instantiate()
	root.add_child(level)
	await create_timer(3).timeout
	for x:float in [8.0,17.7,29.0]:
		level.actor.reset_actor()
		level.actor.position=Vector3(x,0.02,0)
		level._camera(0,true)
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/art_revision/room_"+str(x)+".png")
	print("ART_ROOM_CAPTURED")
	quit()
