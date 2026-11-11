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
	await ticks(15)
	actor.set_physics_process(false)
	for label:String in ["HitKnockback","HitKnockbackRM","Death1","Death2","CrawlEnter","CrawlIdle","CrawlForward","CrawlExit"]:
		actor._state("Clip review")
		actor.current_clip=""
		actor._play(label,0)
		for phase in [0.0,0.25,0.5,0.75,0.99]:
			actor.animation_player.seek(actor._duration(label)*phase,true)
			await process_frame
			await RenderingServer.frame_post_draw
			for i in range(actor.skeleton.get_bone_count()):assert(actor.skeleton.get_bone_global_pose(i).is_finite(),label)
		actor.animation_player.seek(actor._duration(label)*0.65,true)
		await capture(label)
	actor.reset_actor()
	actor.set_physics_process(true)
	await ticks(10)
	actor.reactions.take_hit("HitKnockback")
	assert(actor.state=="HitReact")
	await ticks(int(actor._duration("HitKnockback")*60)+10)
	assert(actor.state=="HitDown")
	actor.reset_actor()
	actor.reactions.toggle_crawl=true
	await ticks(int(actor._duration("CrawlEnter")*60)+10)
	assert(actor.state=="Crawl" and actor.reactions.crouched)
	var start:float=actor.position.x
	Input.action_press("miko8_right",0.5)
	await ticks(40)
	assert(actor.position.x>start+0.1 and actor.current_clip=="CrawlForward")
	Input.action_release("miko8_right")
	await ticks(5)
	assert(actor.current_clip=="CrawlIdle")
	await capture("crawl_gameplay")
	actor.reactions.toggle_crawl=true
	await ticks(int(actor._duration("CrawlExit")*60)+10)
	assert(actor.state=="Locomotion" and not actor.reactions.crouched)
	for variant:int in [1,2]:
		actor.reset_actor()
		actor.reactions.die(variant)
		await ticks(int(actor._duration("Death"+str(variant))*60)+30)
		assert(actor.state=="Dead")
		await capture("death_gameplay_"+str(variant))
	actor.reset_actor()
	assert(actor.state=="Locomotion" and actor.head_offset.active)
	print("REACTION_LIBRARY_PASS: eight clips sampled, hit holds knocked-down pose, crawl enter/move/idle/exit and collider restoration, both deaths hold, reset restores control")
	quit()
