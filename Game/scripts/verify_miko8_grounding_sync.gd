extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	for box in get_nodes_in_group("miko8_charge_targets"):box.queue_free()
	await ticks(15)
	Input.action_press("miko8_right",0.65)
	await ticks(4)
	assert(actor.state=="MoveStart" and actor.current_clip=="SprintEnter" and absf(actor.velocity.x)<0.01)
	await ticks(45)
	assert(absf(actor.animation_player.speed_scale-1.0)<0.02)
	Input.action_release("miko8_right")
	await ticks(2)
	assert(actor.state=="GroundStop" and actor.current_clip=="Run")
	assert(actor.animation_player.speed_scale<1.0)
	await ticks(25)
	assert(actor.state=="Locomotion" and actor.current_clip=="Idle" and absf(actor.velocity.x)<0.01)
	assert(actor.animation_player.speed_scale==1.0)
	actor.reset_actor()
	level.follow_x=0.0
	await ticks(5)
	for pole in range(3):
		actor.polarity_control.set_polarity(pole)
		assert(actor.polarity_control.materials[0].get_shader_parameter("polarity")==pole)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/visible_suit_glow_"+str(pole)+".png")
	print("GROUNDING_SYNC_PASS: gait rate follows acceleration; deceleration retains moving gait until stopped; rate resets; neutral/red/blue suit colours rendered")
	quit()

