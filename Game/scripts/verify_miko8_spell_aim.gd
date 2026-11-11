extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(15)
	Input.action_press("miko8_spell_double")
	await ticks(100)
	assert(actor.state=="SpellHold")
	for item in [[Vector2(1,1),"right_down"],[Vector2(1,0),"right"],[Vector2(0,-1),"vertical"],[Vector2(-1,-1),"left_up"],[Vector2(-1,1),"left_down"]]:
		for entry in [[JOY_AXIS_RIGHT_X,item[0].x],[JOY_AXIS_RIGHT_Y,item[0].y]]:
			var motion:=InputEventJoypadMotion.new()
			motion.device=0
			motion.axis=entry[0]
			motion.axis_value=entry[1]
			Input.parse_input_event(motion)
		Input.flush_buffered_events()
		await ticks(75)
		await process_frame
		await RenderingServer.frame_post_draw
		var direction:Vector3=actor.abilities.aim_direction()
		assert(direction.is_finite())
		assert(actor.facing==actor.abilities.aim_facing)
		for side:String in ["L","R"]:
			var hand:Vector3=actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-hand."+side)).origin
			var fore:Vector3=actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-forearm."+side)).origin
			var arm:Vector3=actor.abilities.posed_directions[side]
			print(item[1],side," alignment=",arm.dot(direction))
			assert(arm.dot(direction)>0.98,"Arm does not follow aim")
			assert(actor.abilities.lasers.lines[side].visible)
			if item[1].ends_with("down"):assert(absf(actor.abilities.lasers.ends.C.y)<0.05,"Downward laser misses floor")
		root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/aim_"+item[1]+".png")
	Input.action_release("miko8_spell_double")
	await ticks(120)
	assert(actor.abilities.shots_fired==1)
	assert(actor.state=="Locomotion")
	await ticks(10)
	assert(not actor.abilities.lasers.lines.L.visible)
	print("AIM_SWEEP_PASS: both arms, 45deg down each side, vertical, automatic turn, floor clipping, release fire, cleanup")
	quit()


