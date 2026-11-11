extends SceneTree
const LIB=preload("res://scripts/miko8_facade_library.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	assert(LIB.validate_sequence(),"Adjacent pipe colours and sockets must match, including bridge terminations")
	for i in range(LIB.IDS.size()):
		assert(ResourceLoader.exists("res://art/tutorial/facade_library/"+LIB.IDS[i]+".png"))
		var material:=LIB.material(i)
		assert(material.get_shader_parameter("art") is Texture2D)
		assert(LIB.UPPER[i].x+LIB.UPPER[i].y<LIB.LOWER[i].x-LIB.LOWER[i].y)
	var level=load("res://scenes/miko8_ortho_repetition.tscn").instantiate();root.add_child(level)
	await create_timer(3).timeout
	var ground=level.get_node("OrthographicRepeatedGround")
	var used:Dictionary={}
	for i in range(10):
		if i==5:
			assert(not ground.modules[i].has_node("PaintedFoundationFront"));continue
		var face=ground.modules[i].get_node("PaintedFoundationFront")
		assert(face.get_meta("facade_id")==LIB.SEQUENCE[i])
		used[face.get_meta("facade_id")]=true
	assert(used.size()==9)
	# Inspect the two complete runs at the normal game camera.
	for x:float in [6,15,24,42,51,57]:
		level.actor.reset_actor();level.actor.position=Vector3(x,0.02,0);level._camera(0,true)
		await create_timer(0.5).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/OrthographicJoinTest/facade_run_"+str(x)+".png")
	level.set_process(false)
	level.camera.size=36;level.camera.position=Vector3(30,15,32);level.camera.look_at(Vector3(30,0.5,0))
	level.visibility_budget.refresh();await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Source/Environment/OrthographicJoinTest/facade_library_overview.png")
	print("FACADE_LIBRARY_PASS: ten assets, nine distinct installed fronts, colour/port continuity, bridge terminations, unchanged 5/1/4 structure")
	quit()
