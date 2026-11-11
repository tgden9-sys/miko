extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	for i in range(10):
		await physics_frame
	
	var actor = level.actor
	var skel = actor.skeleton
	var l_hand_idx = skel.find_bone("DEF-hand.L")
	var r_hand_idx = skel.find_bone("DEF-hand.R")
	var l_foot_idx = skel.find_bone("DEF-foot.L")
	var r_foot_idx = skel.find_bone("DEF-foot.R")
	
	print("Bone indices: L_hand=", l_hand_idx, " R_hand=", r_hand_idx, " L_foot=", l_foot_idx, " R_foot=", r_foot_idx)
	
	# Sample hand distance across climb clips
	var anim = actor.animation_player
	for clip_name in ["BpgMoveUpL", "BpgMoveUpR", "BpgIdleLoopL", "StockLadderUp", "StockLadderHold"]:
		if not anim.has_animation(clip_name):
			continue
		var animation = anim.get_animation(clip_name)
		anim.play(clip_name)
		anim.seek(animation.length * 0.5, true)
		for f in range(2):
			await physics_frame
		
		var l_hand_pos = skel.get_bone_global_pose(l_hand_idx).origin
		var r_hand_pos = skel.get_bone_global_pose(r_hand_idx).origin
		var hand_dist = l_hand_pos.distance_to(r_hand_pos)
		var hand_x_span = absf(l_hand_pos.x - r_hand_pos.x)
		
		var l_foot_pos = skel.get_bone_global_pose(l_foot_idx).origin
		var r_foot_pos = skel.get_bone_global_pose(r_foot_idx).origin
		var foot_x_span = absf(l_foot_pos.x - r_foot_pos.x)
		
		print("Clip: ", clip_name, " Hand X span=", hand_x_span, " Hand 3D dist=", hand_dist, " Foot X span=", foot_x_span)
	
	quit(0)
