extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func capture(name:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/demo_"+name+".png")
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	level._go_to_ladder()
	var actor=level.actor
	actor.facing=-1
	actor.visual.rotation.y=-PI/2
	await ticks(10)
	Input.action_press("miko8_up")
	await ticks(70)
	assert(actor.current_clip=="StockLadderUp")
	await capture("up")
	Input.action_release("miko8_up")
	await ticks(5)
	var held:float=actor.position.y
	var phase:float=actor.animation_player.current_animation_position
	var held_head:Quaternion=actor.skeleton.get_bone_pose_rotation(actor.skeleton.find_bone("DEF-head"))
	await ticks(25)
	assert(absf(actor.position.y-held)<0.001)
	assert(held_head.angle_to(actor.skeleton.get_bone_pose_rotation(actor.skeleton.find_bone("DEF-head")))<0.01)
	assert(absf(actor.animation_player.current_animation_position-phase)<0.001)
	Input.action_press("miko8_down")
	await ticks(10)
	assert(actor.position.y<held)
	Input.action_release("miko8_down")
	Input.action_press("miko8_up")
	for i in range(500):
		await physics_frame
		if actor.state=="ClimbTopExit":break
	assert(actor.state=="ClimbTopExit")
	await ticks(14)
	await capture("top_early")
	await ticks(20)
	await capture("top_middle")
	await ticks(20)
	await capture("top_late")
	await ticks(40)
	Input.action_release("miko8_up")
	assert(actor.state=="Locomotion")
	assert(actor.facing==1)
	assert(actor.is_on_floor() and actor.collision_mask==1)
	assert(absf(actor.position.y-3.2)<0.05)
	await capture("top_standing")
	Input.action_press("miko8_down")
	await ticks(100)
	assert(actor.state=="ClimbHold")
	Input.action_release("miko8_down")
	await ticks(5)
	actor.abilities._jump_off(0)
	assert(actor.animation_player.speed_scale==1.0 and actor.collision_mask==1)
	level._go_to_ladder()
	await ticks(10)
	Input.action_press("miko8_up")
	await ticks(65)
	Input.action_release("miko8_up")
	Input.action_press("miko8_down")
	for i in range(240):
		await physics_frame
		if actor.state=="Locomotion":break
	Input.action_release("miko8_down")
	assert(actor.state=="Locomotion" and actor.position.y<0.05)
	assert(actor.animation_player.speed_scale==1.0)
	print("STOCK_LADDER_DEMO_PASS: up, hold, reverse, top clearance, grounded exit, top mount, jump off, bottom exit")
	quit()

