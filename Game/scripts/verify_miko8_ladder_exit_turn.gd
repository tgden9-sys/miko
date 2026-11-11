extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("EXIT_TURN_FAIL "+message)
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(120)
	var actor=level.actor;var ladder=level.climb_set.ladder
	for direction:int in [-1,0,1]:
		actor.reset_actor();actor.position=Vector3(ladder.climb_x,1.5,-.14)
		actor.abilities._mount(ladder,false)
		var motion=actor.abilities.bpg_motion
		motion.alignment=Vector3.ZERO
		motion.play("BpgUpExitR","top_out",Vector3(ladder.climb_x,ladder.top_y+.01-motion.last("BpgUpExitR").y,0))
		var action:="miko8_left" if direction<0 else "miko8_right"
		if direction!=0:Input.action_press(action,.35)
		var turn_frames:=0;var max_step:=0.;var previous:float=PI;var saw_turn:=false
		for i in range(250):
			await physics_frame
			if motion.active:previous=actor.visual.rotation.y;continue
			max_step=maxf(max_step,absf(angle_difference(previous,actor.visual.rotation.y)))
			previous=actor.visual.rotation.y
			if actor.state=="Turn":
				saw_turn=true;turn_frames+=1
				check(actor.current_clip==("Turn90Left" if direction<0 else "Turn90Right"),"Exit must play the selected quarter-turn bone animation")
				check(absf(actor.animation_player.current_animation_position-actor.state_time*actor.turn_playback_rate)<.002,"Turn footwork and visible heading must advance on the same clock")
				check(absf(actor.position.x-ladder.climb_x)<.01,"Feet must turn in place before walking")
			elif saw_turn:break
		if direction!=0:Input.action_release(action)
		check(saw_turn and turn_frames>=15,"Exit must include a visible short animated turn")
		check(absf(angle_difference(actor.visual.rotation.y,(-1 if direction<0 else 1)*PI/2))<.01,"Turn must finish facing the selected walking direction")
		check(max_step<deg_to_rad(22),"Heading must progress continuously without a 90-degree snap")
		check(actor.is_on_floor() and actor.collision_mask==1,"Turn must retain grounded landing collision")
		print("EXIT_TURN direction=",direction," frames=",turn_frames," max_heading_step_deg=",rad_to_deg(max_step))
	print("EXIT_TURN_","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
