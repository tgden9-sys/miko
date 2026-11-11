extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(15)
	Input.action_press("miko8_spell_single")
	await ticks(100)
	assert(actor.state=="SpellHold")
	var elapsed:float=actor.state_time
	Input.action_press("miko8_spell_blue")
	Input.action_release("miko8_spell_single")
	await ticks(3)
	assert(actor.state=="SpellHold" and actor.current_clip=="SpellSingleIdle")
	assert(actor.state_time>elapsed and actor.abilities.laser_mode=="Blue")
	Input.action_release("miko8_spell_blue")
	await ticks(2)
	Input.action_press("miko8_spell_single")
	await ticks(3)
	assert(actor.state=="SpellHold" and actor.abilities.laser_mode=="Red")
	assert(actor.current_clip=="SpellSingleIdle")
	Input.action_release("miko8_spell_single")
	await ticks(25)
	assert(actor.state=="Locomotion")
	print("SEAMLESS_TARGET_COLOR_PASS: live red/blue colour swap preserves pose/clip; brief button handover resumes hold without enter; normal release still exits")
	quit()
