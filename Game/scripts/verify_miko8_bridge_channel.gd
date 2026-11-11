extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_ortho_repetition.tscn").instantiate();root.add_child(level)
	await create_timer(3).timeout
	var channel=level.bridge_channel_plane.get_child(0)
	var art=channel.get_node("ChannelArtwork")
	assert(art.global_position.z < -1.4)
	for x:float in [28,33,38]:
		level.actor.reset_actor();level.actor.position=Vector3(x-1.5,0.02,0);level._camera(0,true)
		assert(absf(level.bridge_channel_plane.position.x-(level.camera.position.x-33)*0.18)<0.001)
		assert(art.global_position.x-6 < 30 and art.global_position.x+6 > 36)
		assert(art.global_basis.z.dot(level.camera.global_basis.z)>0.999)
		var top=level.camera.unproject_position(art.to_global(Vector3(0,3,0)))
		var deck=level.camera.unproject_position(Vector3(33,0,-1.4))
		assert(top.y>=deck.y,"Channel artwork must stay below the rear deck edge")
		await create_timer(0.7).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/OrthographicJoinTest/channel_view_"+str(x)+".png")
	print("BRIDGE_CHANNEL_PASS: below deck, behind bridge, overscanned coverage, anchored parallax; three normal camera captures")
	quit()
