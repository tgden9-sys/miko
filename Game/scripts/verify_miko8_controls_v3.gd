extends SceneTree
var level:Node3D
var actor:CharacterBody3D
var report:={}
const OUT:="res://../Builds/Validation/MIKO8/controls_v3/"
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
func _jump(v:bool)->void:
	var e:=InputEventJoypadButton.new()
	e.device=0
	e.button_index=JOY_BUTTON_B
	e.pressed=v
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func _reset()->void:
	_axis(0)
	_jump(false)
	await process_frame
	actor.reset_actor()
	actor.position.x=-5
	level.follow_x=-5
	await _ticks(15)
func _capture(label:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
func _run()->void:
	level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	actor=level.actor
	await _ticks(15)
	for dir in [-1,1,-1]:
		_axis(float(dir)*0.65)
		var elapsed:=0.0
		for i in range(60):
			await physics_frame
			elapsed+=1.0/60.0
			if actor.facing==dir and actor.velocity.x*dir>0.3:break
		assert(actor.facing==dir and actor.velocity.x*dir>0.3 and elapsed<0.8)
		report["direction_"+str(dir)]=elapsed
	# Change the request halfway through a turn: the latest stick direction wins.
	_axis(0.65)
	for i in range(60):
		await physics_frame
		if actor.state=="Turn":break
	await _ticks(5)
	_axis(-0.65)
	await _ticks(40)
	assert(actor.facing==-1 and actor.velocity.x<0)
	report.turn_cancel=true
	for gait in [[0.65,"Run"],[1.0,"Sprint"]]:
		await _reset()
		_axis(gait[0])
		await _ticks(95)
		var start:float=actor.position.x
		_axis(0)
		await _ticks(30)
		var slide:float=actor.position.x-start
		assert(absf(actor.velocity.x)<0.01 and slide<1.2)
		report[gait[1]+"_stopping_distance"]=slide
	await _reset()
	_axis(1.0)
	await _ticks(95)
	actor.position.x=-5
	_jump(true)
	await process_frame
	await _ticks(4)
	_jump(false)
	for i in range(60):
		await physics_frame
		if actor.state=="Air":break
	_axis(0)
	for i in range(120):
		await physics_frame
		if actor.landing_contact:break
	assert(actor.landing_contact)
	var touch_x:float=actor.position.x
	await _ticks(30)
	var landing_slide:float=absf(actor.position.x-touch_x)
	assert(landing_slide<0.15 and absf(actor.velocity.x)<0.01)
	report.landing_slide_m=landing_slide
	# One post-animation correction must remain 30 degrees across all clips and a paused pose.
	actor.set_physics_process(false)
	var head_data:={}
	for label:String in actor.clips:
		actor.current_clip=""
		actor._play(label,0)
		actor.animation_player.seek(actor._duration(label)*0.4,true)
		await process_frame
		await process_frame
		assert(absf(rad_to_deg(actor.head_offset.applied_angle)-30.0)<0.01)
		if not label.begins_with("Climb"): assert(actor.head_offset.elevation_change>20.0,"Head offset points down in "+label)
		head_data[label]=actor.head_offset.elevation_change
		if label in ["Walk","Sprint","JumpAir"]:await _capture("head_"+label)
	var frozen:Quaternion=actor.head_offset.last_before
	for i in range(30):await process_frame
	assert(frozen.angle_to(actor.head_offset.last_before)<0.001,"Head correction accumulates")
	report.head_lift_degrees=head_data
	level._toggle_game_size()
	assert(level.game_size and level.camera.size>20)
	await _capture("game_size")
	level._toggle_game_size()
	assert(not level.game_size and is_equal_approx(level.camera.size,4.0))
	report.game_size_toggle=true
	var file:=FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("MIKO8_CONTROLS_V3_PASSED ",JSON.stringify(report))
	quit()
