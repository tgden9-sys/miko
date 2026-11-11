extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _axis(v: float) -> void:
	var e:=InputEventJoypadMotion.new()
	e.device=0
	e.axis=JOY_AXIS_LEFT_X
	e.axis_value=v
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func _run() -> void:
	var level:Node3D=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor:CharacterBody3D=level.actor
	for i in range(20):await physics_frame
	_axis(-0.35)
	for i in range(40):
		await physics_frame
		if actor.state=="Turn":break
	for i in range(3):await physics_frame
	assert(actor.state=="Turn")
	var last:float=actor.visual.rotation.y
	var e:=InputEventJoypadButton.new()
	e.device=0
	e.button_index=JOY_BUTTON_B
	e.pressed=true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await process_frame
	_axis(0)
	var max_step:=0.0
	var air:=false
	var contact:=false
	for i in range(180):
		await physics_frame
		max_step=maxf(max_step,absf(angle_difference(last,actor.visual.rotation.y)))
		last=actor.visual.rotation.y
		air=air or actor.state=="Air"
		contact=contact or actor.landing_contact
		if contact and actor.state=="Locomotion":break
	assert(air and contact and max_step<deg_to_rad(16))
	print("TURN_JUMP_INTERRUPT_PASSED max heading step degrees=",rad_to_deg(max_step))
	quit()

