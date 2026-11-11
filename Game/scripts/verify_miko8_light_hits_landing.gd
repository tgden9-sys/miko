extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func capture(name:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/reactions/"+name+".png")
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	assert(actor.clips.size()==48)
	for box in get_nodes_in_group("miko8_charge_targets"):box.queue_free()
	for target in get_nodes_in_group("miko8_spell_targets"):target.queue_free()
	await ticks(15)
	for label:String in ["HitHead","HitShoulderLeft","HitStomach"]:
		actor.reset_actor()
		actor.reactions.take_hit(label)
		assert(actor.state=="HitReact")
		await ticks(int(actor._duration(label)*60*0.4))
		await capture(label+"_reaction")
		await ticks(int(actor._duration(label)*60)+10)
		assert(actor.state=="Locomotion" and actor.current_clip=="Idle")
		assert(actor.head_offset.active)
	for strength:float in [0.65,1.0]:
		actor.reset_actor()
		Input.action_press("miko8_right",strength)
		await ticks(80)
		actor._begin_jump()
		for i in range(120):
			await physics_frame
			if actor.landing_contact:break
		assert(actor.landing_contact and actor.state=="Locomotion")
		var incoming:float=absf(actor.velocity.x)
		assert(incoming>2.5 and incoming<3.2)
		assert(actor.current_clip in ["Run","Sprint"])
		await capture("moving_landing_"+str(strength))
		await ticks(8)
		assert(absf(actor.velocity.x)>incoming and absf(actor.velocity.x)<=actor._speed(actor.current_clip))
		assert(actor.state!="MoveStart")
		Input.action_release("miko8_right")
		await ticks(40)
	print("LIGHT_HITS_AND_LANDING_PASS: all three light reactions recover to idle; moving landing retains capped incoming momentum, blends into gait and accelerates without restarting standing push-off")
	quit()

