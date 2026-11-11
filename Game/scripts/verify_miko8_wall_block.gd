extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	for side:int in [-1,1]:
		actor.reset_actor()
		actor.position.x=side*33.0
		actor.facing=side
		actor.visual.rotation.y=side*PI/2
		level.follow_x=actor.position.x
		var action:String="miko8_left" if side<0 else "miko8_right"
		await ticks(10)
		Input.action_press(action)
		await ticks(120)
		assert(actor.state=="WallBlocked" and actor.current_clip=="Idle")
		assert(absf(actor.position.x)<34.64 and absf(actor.position.x)>34.5,"Body must remain outside the end barrier")
		var x:float=actor.position.x
		await ticks(30)
		assert(absf(actor.position.x-x)<0.001)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/wall_blocked_"+str(side)+".png")
		Input.action_release(action)
		Input.action_press("miko8_right" if side<0 else "miko8_left")
		await ticks(50)
		assert(absf(actor.position.x)<absf(x)-0.2,"Must be able to turn and move away")
		Input.action_release("miko8_right" if side<0 else "miko8_left")
	print("END_BARRIER_COLLISION_PASS: full-speed approach both directions, capsule clear of barrier, idle instead of running through wall, no continued motion, turn and retreat")
	quit()
