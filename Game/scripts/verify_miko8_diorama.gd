extends SceneTree
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func run()->void:
	var level=load("res://scenes/miko8_diorama_rescue.tscn").instantiate();root.add_child(level)
	await create_timer(4.0).timeout
	assert(RenderingServer.get_current_rendering_method()=="forward_plus")
	assert(level.native_ground.diorama_style)
	assert(level.get_node("BG4_SeparateMachinery").get_child_count()==2)
	assert(level.get_node("BG4_SeparateMachinery").find_children("*","Sprite3D",true,false).is_empty())
	assert(level.camera.attributes.dof_blur_far_enabled)
	var actor=level.actor
	print("DIORAMA_START actor=",actor.position," state=",actor.state," floor=",actor.is_on_floor())
	assert(actor.is_on_floor() and actor.state.begins_with("GroundSit"))
	Input.action_press("miko8_right",.65);await create_timer(actor._duration("GroundSitExit")+.4).timeout;Input.action_release("miko8_right")
	assert(not actor.state.begins_with("GroundSit"))
	for start:float in [29.5,35.5]:
		actor.reset_actor();actor.position=Vector3(start,.02,0);await ticks(5)
		Input.action_press("miko8_right",.65);await ticks(50);Input.action_release("miko8_right");await ticks(8)
		assert(actor.position.x>start+.6 and absf(actor.position.y)<.04)
	# Crate is still a genuine solid in the gameplay lane.
	actor.reset_actor();actor.position=Vector3(40.8,.02,0);await ticks(5)
	Input.action_press("miko8_right",1.0);await ticks(100);Input.action_release("miko8_right")
	assert(actor.position.x<42.7,"The crate must block the player")
	for x:float in [27,33,39]:
		actor.reset_actor();actor.position=Vector3(x-1.5,.02,0);level._camera(0,true)
		await create_timer(2.5).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Source/Environment/DioramaRescue/game_"+str(x)+".png")
		print("DIORAMA_VIEW x=",x," fps=",Engine.get_frames_per_second()," draws=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	print("DIORAMA_PASS: Forward+, native open machinery, true DOF, wake and both bridge joins, solid crate, three normal gameplay captures")
	quit()
