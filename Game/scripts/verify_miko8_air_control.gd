extends SceneTree
var level:Node3D
var actor:CharacterBody3D
func _initialize()->void:call_deferred("_run")
func _ticks(n:int)->void:
	for i in range(n):await physics_frame
func _axis(v:float)->void:
	var e:=InputEventJoypadMotion.new()
	e.device=0
	e.axis=JOY_AXIS_LEFT_X
	e.axis_value=v
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func _run()->void:
	level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	actor=level.actor
	await _ticks(20)
	var result:={}
	for direction in [-1,1]:
		actor.reset_actor()
		actor.position=Vector3(0,4,0)
		actor.velocity=Vector3(5.22*direction,0,0)
		actor.facing=direction
		actor.visual.rotation.y=direction*PI/2
		actor.launched=true
		actor._state("Air")
		actor._play("JumpAir",0)
		_axis(-0.65*direction)
		await process_frame
		await _ticks(15)
		assert(actor.velocity.x*direction<0 and actor.facing==-direction)
		assert(absf(angle_difference(actor.visual.rotation.y,-direction*PI/2))<0.1)
		result["reverse_from_"+str(direction)]={"velocity_x":actor.velocity.x,"facing":actor.facing}
		_axis(0)
		await process_frame
		await _ticks(15)
		assert(absf(actor.velocity.x)<0.01,"Neutral stick drifts in air")
		result["neutral_from_"+str(direction)]=actor.velocity.x
		for i in range(120):
			await physics_frame
			if actor.landing_contact:break
		assert(actor.landing_contact)
		var x:float=actor.position.x
		await _ticks(20)
		assert(absf(actor.position.x-x)<0.02)
	var file:=FileAccess.open("res://../Builds/Validation/MIKO8/controls_v3/air_control.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("AIR_CONTROL_PASSED ",JSON.stringify(result))
	quit()
