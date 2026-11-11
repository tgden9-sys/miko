extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func capture(name:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/push_off_"+name+".png")
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	for box in get_nodes_in_group("miko8_charge_targets"):box.queue_free()
	await ticks(15)
	for strength:float in [0.65,1.0]:
		actor.reset_actor()
		level.follow_x=0.0
		Input.action_press("miko8_right",strength)
		await ticks(3)
		assert(actor.state=="MoveStart" and actor.current_clip=="SprintEnter")
		var first:float=actor.position.x
		var time:float=actor.animation_player.current_animation_position
		await ticks(6)
		assert(absf(actor.position.x-first)<0.002,"World travel precedes the weight shift")
		assert(actor.animation_player.current_animation_position>time+0.08,"Push-off animation must progress while the foot is planted")
		await capture("plant_"+str(strength))
		await ticks(13)
		assert(actor.position.x>first+0.02 and actor.animation_player.speed_scale==1.0)
		await capture("push_"+str(strength))
		await ticks(35)
		assert(actor.state=="Locomotion" and actor.current_clip==("Run" if strength<0.88 else "Sprint"))
		Input.action_release("miko8_right")
		await ticks(40)
	actor.reset_actor()
	Input.action_press("miko8_right",0.65)
	actor._begin_jump()
	for i in range(120):
		await physics_frame
		if actor.landing_contact:break
	for i in range(10):
		await physics_frame
		if actor.state=="MoveStart":break
	assert(actor.state=="Locomotion" and actor.current_clip=="Run" and absf(actor.velocity.x)>2.5)
	Input.action_release("miko8_right")
	print("PUSH_OFF_PASS: planted weight-shift before world travel, authored start runs normally, gradual travel then run/sprint loop, moving landing carries momentum into run")
	quit()
