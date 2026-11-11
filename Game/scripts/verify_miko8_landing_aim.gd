extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(15)
	for axis:float in [0.35,0.65,1.0]:
		actor.reset_actor()
		Input.action_press("miko8_right",axis)
		await ticks(15)
		actor._begin_jump()
		for i in range(120):
			await physics_frame
			if actor.landing_contact:break
		assert(actor.landing_contact)
		var contact:float=actor.position.x
		var elapsed:=0.0
		while actor.current_clip=="JumpLand" and elapsed<0.3:
			await physics_frame
			elapsed+=1.0/60.0
			if actor.current_clip=="JumpLand":assert(absf(actor.position.x-contact)<0.005,"Travels while landing pose is planted")
		assert(elapsed<0.09 and actor.current_clip in ["Walk","Run","Sprint","SprintEnter"])
		Input.action_release("miko8_right")
	for action:String in ["miko8_spell_single","miko8_spell_blue","miko8_spell_double"]:
		for direction:int in [-1,1]:
			actor.reset_actor()
			actor.facing=direction
			actor.visual.rotation.y=direction*PI/2
			actor.abilities.aim_facing=-direction
			actor.abilities.aim_engaged=true
			actor.abilities.aim_elevation=-0.7
			await ticks(5)
			Input.action_press(action)
			await ticks(3)
			assert(actor.abilities.aim_facing==direction and absf(actor.abilities.aim_elevation)<0.001)
			Input.action_release(action)
			await ticks(25)
	print("LANDING_AND_AIM_PASS: no planted-pose travel, moving recovery under .09s for walk/run/sprint; red/blue/plasma centred on facing in both directions")
	quit()
