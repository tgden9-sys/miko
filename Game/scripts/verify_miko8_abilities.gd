extends SceneTree
var level:Node3D
var actor:CharacterBody3D
var report:={"clips":{},"spells":{},"ladder":{}}
const OUT:="res://../Builds/Validation/MIKO8/actions_v4/"
func _initialize()->void:call_deferred("_run")
func _ticks(n:int)->void:
	for i in range(n):await physics_frame
func _motion(axis:int,value:float)->void:
	var e:=InputEventJoypadMotion.new()
	e.device=0
	e.axis=axis
	e.axis_value=value
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func _jump(pressed:bool)->void:
	var e:=InputEventJoypadButton.new()
	e.device=0
	e.button_index=JOY_BUTTON_B
	e.pressed=pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func _capture(label:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
func _run()->void:
	level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	actor=level.actor
	await _ticks(20)
	assert(actor.clips.size()==48,"Expected source, stock ladder and reaction/crawl clips")
	actor.set_physics_process(false)
	for label:String in actor.clips:
		if not(label.begins_with("Spell") or label.begins_with("Climb")):continue
		actor.current_clip=""
		actor._play(label,0)
		var data:Dictionary=actor.metadata.clips[label]
		var error:=0.0
		for f in range(data.hands.size()):
			if data.loop and f==data.hands.size()-1:continue
			actor.animation_player.seek(float(f)/30.0,true)
			for pair in [["hand","hands"],["foot","feet"]]:
				for side:String in ["L","R"]:
					var v:Array=data[pair[1]][f][side]
					var actual:Vector3=actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-"+pair[0]+"."+side)).origin
					error=maxf(error,actual.distance_to(Vector3(v[0],v[1],v[2])))
		assert(error<0.0002,label+" import differs from source: "+str(error))
		report.clips[label]=error
	actor.set_physics_process(true)
	for kind:String in ["Single","Double"]:
		for facing in [1,-1]:
			actor.reset_actor()
			actor.facing=facing
			actor.visual.rotation.y=facing*PI/2
			await _ticks(15)
			var trigger:=JOY_AXIS_TRIGGER_LEFT if kind=="Single" else JOY_AXIS_TRIGGER_RIGHT
			var start_shots:int=actor.abilities.shots_fired
			var hits_before:=0
			for target:Node in get_nodes_in_group("miko8_spell_targets"):hits_before+=target.hits
			if kind=="Single":
				var shoulder:=InputEventJoypadButton.new()
				shoulder.device=0;shoulder.button_index=JOY_BUTTON_LEFT_SHOULDER;shoulder.pressed=true
				Input.parse_input_event(shoulder);Input.flush_buffered_events()
			else:_motion(trigger,1)
			await process_frame
			await _ticks(60)
			assert(actor.state=="SpellHold")
			assert(actor.abilities.shots_fired==start_shots,"Fired before release")
			await _capture("spell_"+kind+str(facing)+"_hold")
			if kind=="Single":
				var shoulder:=InputEventJoypadButton.new()
				shoulder.device=0;shoulder.button_index=JOY_BUTTON_LEFT_SHOULDER;shoulder.pressed=false
				Input.parse_input_event(shoulder);Input.flush_buffered_events()
			else:_motion(trigger,0)
			await process_frame
			var shot_seen:=false
			for i in range(180):
				await physics_frame
				if actor.abilities.shots_fired>start_shots and not shot_seen:
					shot_seen=true
					await _capture("spell_"+kind+str(facing)+"_fire")
				if shot_seen and actor.state=="Locomotion":break
			await _ticks(60)
			var hits_after:=0
			for target:Node in get_nodes_in_group("miko8_spell_targets"):hits_after+=target.hits
			var expected:=0 if kind=="Single" else 1
			assert(actor.abilities.shots_fired-start_shots==expected)
			assert(hits_after-hits_before==expected,"Spell misses target or wrong hand")
			report.spells[kind+str(facing)]={"bolts":expected,"hits":hits_after-hits_before}
	level._go_to_ladder()
	await _ticks(15)
	_motion(JOY_AXIS_LEFT_Y,-1)
	await process_frame
	await _ticks(45)
	assert(actor.state=="ClimbHold")
	await _capture("ladder_up")
	_motion(JOY_AXIS_LEFT_Y,0)
	await process_frame
	await _ticks(5)
	var hold_y:float=actor.position.y
	await _ticks(20)
	assert(absf(actor.position.y-hold_y)<0.001 and actor.animation_player.speed_scale==0.0)
	await _capture("ladder_hold")
	_motion(JOY_AXIS_LEFT_Y,1)
	await process_frame
	await _ticks(8)
	assert(actor.position.y<hold_y)
	_motion(JOY_AXIS_LEFT_Y,-1)
	await process_frame
	for i in range(550):
		await physics_frame
		if actor.state=="ClimbTopExit":
			await _capture("ladder_pull_up")
			break
	for i in range(120):
		await physics_frame
		if not actor.state.begins_with("Climb"):break
	_motion(JOY_AXIS_LEFT_Y,0)
	await _ticks(10)
	assert(actor.state=="Locomotion" and absf(actor.position.y-3.2)<0.05)
	assert(actor.collision_mask==1 and actor.is_on_floor())
	await _capture("ladder_top")
	report.ladder.top_exit=actor.position.y
	_motion(JOY_AXIS_LEFT_Y,1)
	await process_frame
	for i in range(180):
		await physics_frame
		if actor.state=="ClimbHold":break
	assert(actor.state=="ClimbHold")
	await _capture("ladder_down")
	_motion(JOY_AXIS_LEFT_Y,0)
	_jump(true)
	await process_frame
	await _ticks(3)
	_jump(false)
	assert(actor.state=="Air" and actor.velocity.y>0 and actor.collision_mask==1)
	await _capture("ladder_jump_off")
	report.ladder.jump_off=true
	for i in range(240):
		await physics_frame
		if actor.landing_contact:break
	assert(actor.landing_contact)
	level._go_to_ladder()
	await _ticks(15)
	_motion(JOY_AXIS_LEFT_Y,-1)
	await process_frame
	await _ticks(55)
	_motion(JOY_AXIS_LEFT_Y,1)
	await process_frame
	for i in range(180):
		await physics_frame
		if actor.state=="Locomotion":break
	_motion(JOY_AXIS_LEFT_Y,0)
	assert(actor.state=="Locomotion" and actor.position.y<0.05 and actor.collision_mask==1)
	report.ladder.bottom_exit=true
	var file:=FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("MIKO8_ABILITIES_PASSED ",JSON.stringify(report))
	quit()



