extends SceneTree
var level: Node3D
var actor: CharacterBody3D
var report := {"turns":{},"jumps":{}}
class HeadingSampler extends Node:
	var actor:CharacterBody3D
	var enabled:=false
	var last:=0.0
	var maximum:=0.0
	func _physics_process(_delta:float)->void:
		if enabled:
			maximum=maxf(maximum,absf(angle_difference(last,actor.visual.rotation.y)))
			last=actor.visual.rotation.y
const OUT := "res://../Builds/Validation/MIKO8/controls_v3/"
func _initialize() -> void: call_deferred("_run")
func _ticks(n: int) -> void:
	for i in range(n): await physics_frame
func _axis(value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device=0
	e.axis=JOY_AXIS_LEFT_X
	e.axis_value=value
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func _button(value: bool) -> void:
	var e:=InputEventJoypadButton.new()
	e.device=0
	e.button_index=JOY_BUTTON_B
	e.pressed=value
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func _capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
func _reset() -> void:
	_axis(0)
	_button(false)
	await process_frame
	actor.reset_actor()
	await _ticks(15)
func _run() -> void:
	level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	actor=level.actor
	var heading_sampler:=HeadingSampler.new()
	heading_sampler.actor=actor
	level.add_child(heading_sampler)
	level.quarter_view=true
	await _ticks(15)
	for mode: String in ["180 Left","180 Right","90 Left x2","90 Right x2"]:
		heading_sampler.enabled=false
		await _reset()
		heading_sampler.last=actor.visual.rotation.y
		heading_sampler.maximum=0.0
		heading_sampler.enabled=true
		actor.turn_mode=mode
		_axis(-0.35)
		var max_step:=0.0
		var last_yaw:float=actor.visual.rotation.y
		var started:=false
		var finished:=false
		var shots:Dictionary={}
		for i in range(360):
			await physics_frame
			last_yaw=actor.visual.rotation.y
			if actor.state=="Turn":
				started=true
				var quarter:=int(actor.state_time*actor.turn_playback_rate/actor._duration(actor.last_turn_clip)*4)
				if not shots.has(quarter) and mode=="180 Right":
					shots[quarter]=true
					await _capture("turn_"+str(quarter))
			if started and actor.state=="Locomotion":
				finished=true
				break
		assert(finished)
		max_step=heading_sampler.maximum
		assert(max_step<deg_to_rad(26),"Turn heading snaps: "+mode+" step="+str(rad_to_deg(max_step)))
		assert(absf(angle_difference(actor.visual.rotation.y,-PI/2))<0.001)
		report.turns[mode]={"maximum_heading_step_degrees":rad_to_deg(max_step)}
	heading_sampler.enabled=false
	for dir in [1,-1]:
		for entry in [[0.0,"Idle"],[0.35,"Walk"],[0.65,"Run"],[1.0,"Sprint"]]:
			await _reset()
			actor.facing=dir
			actor.visual.rotation.y=dir*PI/2
			_axis(float(entry[0])*dir)
			await _ticks(95)
			actor.position.x=-8.0*dir
			level.follow_x=actor.position.x
			var entry_speed:=absf(actor.velocity.x)
			_button(true)
			await process_frame
			var launch_time:=-1.0
			var launch_speed:=0.0
			var contact_time:=-1.0
			var exit_time:=-1.0
			var saw_air:=false
			var started:=false
			var elapsed:=0.0
			var shots:Dictionary={}
			for i in range(240):
				await physics_frame
				elapsed+=1.0/60.0
				if i==3:_button(false)
				started=started or actor.state=="JumpGather"
				if actor.launched and launch_time<0:
					launch_time=elapsed
					launch_speed=absf(actor.velocity.x)
				if actor.state=="Air":saw_air=true
				if actor.landing_contact and contact_time<0:contact_time=elapsed
				if dir==1 and entry[1]=="Run" and not shots.has(actor.state):
					shots[actor.state]=true
					await _capture("jump_"+actor.state)
				if contact_time>0 and actor.state=="Locomotion":
					exit_time=elapsed
					break
			assert(started and saw_air and contact_time>0 and exit_time>0)
			assert(launch_time>0 and launch_time<0.25,"Late takeoff")
			assert(exit_time-contact_time<0.75,"Landing locks movement")
			if entry_speed>1:assert(launch_speed>entry_speed*0.9,"Takeoff loses momentum")
			report.jumps[entry[1]+str(dir)]={"takeoff_seconds":launch_time,"entry_speed":entry_speed,"takeoff_speed":launch_speed,"recovery_seconds":exit_time-contact_time}
	var file:=FileAccess.open(OUT+"sequence_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("MIKO8_SEQUENCES_PASSED ",JSON.stringify(report))
	quit()
