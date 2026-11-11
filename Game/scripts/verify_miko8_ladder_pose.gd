extends SceneTree
const OUT:="res://../Builds/Validation/MIKO8/actions_v4/"
func _initialize()->void:call_deferred("_run")
func _run()->void:
	var level:Node3D=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor:CharacterBody3D=level.actor
	level._go_to_ladder()
	actor.set_physics_process(false)
	actor._state("ClimbHold")
	actor.visual.rotation.y=PI
	actor.position.y=0.6
	actor.ladder_pose.influence=1.0
	var result:={}
	for label:String in ["ClimbIdle","ClimbUp","ClimbDown"]:
		actor.current_clip=""
		actor._play(label,0)
		var widest:=0.0
		var attachment:=0.0
		for phase in [0.0,0.25,0.5,0.75]:
			actor.animation_player.seek(actor._duration(label)*phase,true)
			await process_frame
			await RenderingServer.frame_post_draw
			widest=maxf(widest,actor.ladder_pose.last_knee_width)
			attachment=maxf(attachment,actor.ladder_pose.maximum_attachment_error)
			assert(actor.ladder_pose.last_knee_width<0.35,"Knees remain splayed")
			assert(absf(actor.ladder_pose.last_foot_width-0.23)<0.04,"Foot spacing drifts")
			assert(absf(actor.ladder_pose.last_hand_width-0.51)<0.06,"Hands miss ladder rails")
			assert(attachment<0.001,"IK detaches joints")
			if phase==0.25:
				root.get_texture().get_image().save_png(OUT+"narrow_"+label+".png")
		result[label]={"maximum_knee_spacing":widest,"attachment_error":attachment}
	actor._state("Locomotion")
	await create_timer(0.2).timeout
	assert(actor.ladder_pose.influence<0.001,"Ladder correction persists outside climbing")
	var file:=FileAccess.open(OUT+"ladder_pose_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("NARROW_LADDER_POSE_PASSED ",JSON.stringify(result))
	quit()
