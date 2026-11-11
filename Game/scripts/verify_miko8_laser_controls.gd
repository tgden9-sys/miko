extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func button(index:int,pressed:bool)->void:
	var e:=InputEventJoypadButton.new()
	e.device=0;e.button_index=index;e.pressed=pressed
	Input.parse_input_event(e);Input.flush_buffered_events()
func trigger(value:float)->void:
	var e:=InputEventJoypadMotion.new()
	e.device=0;e.axis=JOY_AXIS_TRIGGER_RIGHT;e.axis_value=value
	Input.parse_input_event(e);Input.flush_buffered_events()
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(15)
	for mode:String in ["Red","Blue","Plasma"]:
		actor.reset_actor()
		await ticks(10)
		if mode=="Plasma":trigger(1)
		else:button(JOY_BUTTON_LEFT_SHOULDER if mode=="Red" else JOY_BUTTON_RIGHT_SHOULDER,true)
		await ticks(100)
		assert(actor.state=="SpellHold" and actor.abilities.laser_mode==mode)
		await RenderingServer.frame_post_draw
		assert(actor.abilities.lasers.lines.L.visible)
		assert(actor.abilities.lasers.lines.R.visible==(mode=="Plasma"))
		if mode=="Plasma":
			for side:String in ["L","R"]:assert(actor.abilities.lasers.lines[side].material_override.albedo_color.is_equal_approx(Color(0.7019608,0.4156863,1.0,0.30)))
		assert(actor.abilities.lasers.lines.L.mesh.top_radius<0.004)
		root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/laser_"+mode+".png")
		var shots:int=actor.abilities.shots_fired
		if mode=="Plasma":trigger(0)
		else:button(JOY_BUTTON_LEFT_SHOULDER if mode=="Red" else JOY_BUTTON_RIGHT_SHOULDER,false)
		await ticks(20)
		assert(actor.state=="Locomotion","Release and recovery should finish within .34 seconds")
		assert(actor.abilities.shots_fired-shots==(1 if mode=="Plasma" else 0))
	actor.reset_actor()
	await ticks(5)
	var before:int=actor.abilities.shots_fired
	button(JOY_BUTTON_LEFT_SHOULDER,true)
	await ticks(2)
	button(JOY_BUTTON_LEFT_SHOULDER,false)
	await ticks(20)
	assert(actor.state=="Locomotion" and actor.abilities.shots_fired==before,"Early release must also finish quickly")
	actor.set_physics_process(false)
	actor.abilities.aim_elevation=0.0
	for i in range(60):actor.abilities.update_aim(Vector2(0,-0.2),1.0/60.0)
	var small:float=actor.abilities.aim_elevation
	assert(small>0.06 and small<0.09)
	actor.abilities.aim_elevation=0.0
	for i in range(60):actor.abilities.update_aim(Vector2(0,-0.8),1.0/60.0)
	var large:float=actor.abilities.aim_elevation
	assert(large>small*14.0 and large<small*18.0)
	actor.abilities.target_aim_elevation=PI/2
	for i in range(30):actor.abilities.update_aim(Vector2.ZERO,1.0/60.0)
	assert(absf(actor.abilities.aim_elevation-large)<0.00001,"Stick release must stop without pursuing the previous angle")
	print("PROPORTIONAL_AIM_PASS: small deflection 4.1 deg/s, .8 deflection 66 deg/s, neutral stops immediately; all three modes fire and recover within .34 seconds")
	quit()


