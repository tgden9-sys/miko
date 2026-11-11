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
	for axis:float in [0.65,1.0]:
		actor.reset_actor()
		Input.action_press("miko8_right",axis)
		actor._begin_jump()
		for i in range(130):
			await physics_frame
			if actor.landing_contact:break
		assert(actor.landing_contact)
		for i in range(10):
			await physics_frame
			if actor.state=="MoveStart":break
		var gait:String=actor.start_gait
		assert(gait in ["Run","Sprint"])
		var initial:float=absf(actor.velocity.x)
		assert(initial>=0 and initial<0.5,"Landing must not restore full speed")
		assert(actor.current_clip=="SprintEnter" and actor.animation_player.speed_scale==1.0)
		await ticks(25)
		assert(absf(actor.velocity.x)>initial+1.0 and absf(actor.velocity.x)<actor._speed(gait)*0.7)
		await ticks(45)
		assert(absf(absf(actor.velocity.x)-actor._speed(gait))<0.05)
		Input.action_release("miko8_right")
		await ticks(35)
	for child in actor.get_children():assert(not child is Sprite3D and not child is OmniLight3D,"Body glow must be removed")
	assert(not actor.polarity_control.materials[0].shader.code.contains("EMISSION ="))
	print("LANDING_ACCELERATION_PASS: low-speed gait starts, progressive travel and playback, full speed reached later; body halo, local light and emission removed")
	quit()
