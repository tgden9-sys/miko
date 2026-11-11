extends SceneTree
func _initialize()->void:call_deferred("_run")
func _motion(axis:int,value:float)->void:
	var e:=InputEventJoypadMotion.new()
	e.device=0
	e.axis=axis
	e.axis_value=value
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func _run()->void:
	var level:Node3D=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor:CharacterBody3D=level.actor
	var menu:OptionButton=level.review_menu
	var fitted:int=actor.clips.keys().find("ClimbUp")+1
	menu.select(fitted)
	menu.item_selected.emit(fitted)
	assert(actor.ladder_pose.preview_enabled)
	var original:=-1
	for i in range(1,menu.item_count):
		var data:Dictionary=menu.get_item_metadata(i)
		if data.clip=="ClimbUp" and data.wall:original=i
	assert(original>0)
	menu.select(original)
	menu.item_selected.emit(original)
	assert(not actor.ladder_pose.preview_enabled)
	menu.select(0)
	menu.item_selected.emit(0)
	for i in range(20):await physics_frame
	var count:int=actor.abilities.shots_fired
	_motion(JOY_AXIS_TRIGGER_LEFT,1)
	await process_frame
	for i in range(8):await physics_frame
	assert(actor.state=="SpellEnter")
	var jump:=InputEventJoypadButton.new()
	jump.device=0
	jump.button_index=JOY_BUTTON_B
	jump.pressed=true
	Input.parse_input_event(jump)
	Input.flush_buffered_events()
	await process_frame
	for i in range(3):await physics_frame
	assert(actor.state in ["JumpGather","JumpStart"])
	_motion(JOY_AXIS_TRIGGER_LEFT,0)
	jump.pressed=false
	Input.parse_input_event(jump)
	Input.flush_buffered_events()
	for i in range(180):
		await physics_frame
		if actor.landing_contact and actor.state=="Locomotion":break
	assert(actor.state=="Locomotion" and actor.abilities.shots_fired==count)
	level._go_to_ladder()
	_motion(JOY_AXIS_LEFT_Y,-1)
	await process_frame
	for i in range(45):await physics_frame
	assert(actor.state=="ClimbHold" and actor.collision_mask==0)
	_motion(JOY_AXIS_LEFT_Y,0)
	actor.reset_actor()
	await create_timer(0.2).timeout
	assert(actor.collision_mask==1 and actor.model.position.is_zero_approx() and actor.ladder_pose.influence<0.001)
	print("ABILITY_SAFETY_PASSED preview variants, cast cancellation, ladder reset")
	quit()
