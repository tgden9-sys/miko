extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_ortho_repetition.tscn").instantiate();root.add_child(level)
	await create_timer(2).timeout
	var ground=level.get_node("OrthographicRepeatedGround")
	assert(ground.clean_style)
	assert(ground.modules.size()==10)
	for module:Node3D in ground.modules:assert(not module.has_node("PaintedFoundationFront"))
	var kit=level.get_node("BG4_MainSubstation/CelSubstationBays")
	assert(kit.find_children("Bay*","Node3D",false,false).size()==10)
	assert(level.get_node("BG4_BridgeChannel").get_child(0).name=="DarkServiceRecess")
	assert(level.get_node("BG2_SoftCity").get_child_count()==1)
	assert(level.get_node("BG3_BokehCity").get_child_count()==1)
	for x:float in [10,20,33,45,50]:
		level.actor.reset_actor();level.actor.position=Vector3(x-1.5,.02,0);level._camera(0,true)
		assert(absf(level.get_node("BG4_MainSubstation").position.x-(level.camera.position.x-10)*.3)<.001)
		assert(absf(level.bridge_channel_plane.position.x-(level.camera.position.x-33)*.18)<.001)
		await create_timer(.7).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/CelDiorama/game_view_"+str(x)+".png")
	level.actor.position.x=2;level._camera(0,true)
	assert(not kit.get_node("Bay09_transformer").get_child(0).visible,"Distant bay must be culled")
	print("CEL_TRIAL_PASS: ten native bays, no painted fronts, native recess, independent city layers, parallax and off-camera bay culling; five gameplay captures")
	quit()
