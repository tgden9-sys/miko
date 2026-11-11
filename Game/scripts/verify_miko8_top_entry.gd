extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func capture(name:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/top_entry_"+name+".png")
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	actor.position=Vector3(19.1,3.21,0)
	level.follow_x=19.1
	await ticks(10)
	Input.action_press("miko8_down")
	await ticks(10)
	assert(actor.state=="ClimbAlign" and actor.current_clip=="Walk")
	assert(absf(actor.position.y-3.2)<0.04)
	await capture("walking")
	for i in range(90):
		await physics_frame
		if actor.state=="ClimbTopEnter":break
	assert(actor.state=="ClimbTopEnter")
	assert(absf(actor.position.x-18.0)<0.001)
	await capture("grab")
	await ticks(15)
	assert(absf(actor.position.x-18.0)<0.001)
	await capture("descending")
	await ticks(25)
	assert(actor.state=="ClimbHold" and actor.current_clip=="StockLadderDown")
	Input.action_release("miko8_down")
	print("TOP_ENTRY_NO_SLIDE_PASS: walk along level platform first, centre before climb pose, descend vertically with continuous down animation")
	quit()
