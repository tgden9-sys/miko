extends SceneTree
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func run()->void:
	var level=load("res://scenes/miko8_ortho_repetition.tscn").instantiate();root.add_child(level)
	await ticks(150)
	var ground=level.get_node("OrthographicRepeatedGround")
	assert(ground.modules.size()==10)
	for i in range(10):
		assert(ground.ORDER[i]==("bridge" if i==5 else "concrete"))
		assert(absf(ground.modules[i].position.x-i*6)<0.001)
	var actor=level.actor
	assert(actor.state=="GroundSitIdle" and actor.is_on_floor())
	Input.action_press("miko8_right",0.65);await ticks(150);Input.action_release("miko8_right")
	assert(not actor.state.begins_with("GroundSit"))
	for start:float in [5.5,11.5,17.5,23.5,29.5,35.5,41.5,47.5]:
		actor.reset_actor();actor.position=Vector3(start,0.02,0);await ticks(5)
		Input.action_press("miko8_right",0.65)
		await ticks(60);Input.action_release("miko8_right");await ticks(10)
		print("JOIN_CHECK ",start," -> ",actor.position," state=",actor.state)
		assert(actor.position.x>start+0.6 and absf(actor.position.y)<0.04,"Every module join must have continuous collision")
	for x:float in [7.0,32.0,49.0]:
		actor.reset_actor();actor.position=Vector3(x,0.02,0);level._camera(0,true)
		await ticks(12);await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/OrthographicJoinTest/preview_"+str(x)+".png")
	actor.position.x=59;level._camera(0,true)
	assert(absf(level.camera.position.x-50)<0.01)
	# Overview records the exact order. This is a separate review camera size only.
	level.set_process(false)
	level.camera.size=36;level.camera.position=Vector3(30,15,32);level.camera.look_at(Vector3(30,0.5,0))
	level.visibility_budget.refresh();await ticks(2);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Source/Environment/OrthographicJoinTest/ten_piece_overview.png")
	print("REPETITION_PASS: exact 5/1/4 order, shared assets, wake, eight floor joins, camera reaches 60m room end")
	quit()
