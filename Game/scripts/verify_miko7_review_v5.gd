extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func _axis(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)

func _capture(label: String) -> void:
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO7/v5/godot_" + label + ".png") == OK)

func _gaze(actor: CharacterBody3D) -> float:
	var skeleton: Skeleton3D = actor.pose_skeleton
	var i := skeleton.find_bone("DEF-head")
	var direction := skeleton.global_transform.basis * skeleton.get_bone_global_pose(i).basis * skeleton.get_bone_global_rest(i).basis.inverse() * Vector3.BACK
	return rad_to_deg(asin(clampf(direction.normalized().y, -1.0, 1.0)))

func _run() -> void:
	var level: Node3D = load("res://scenes/miko7_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor: CharacterBody3D = level.actor
	actor.walk_only = true
	await _ticks(15)
	var skeleton: Skeleton3D = actor.pose_skeleton
	var gaze_min := INF
	var gaze_max := -INF
	var maximum_entry_snap := 0.0
	var maximum_attachment_error := 0.0
	var cases: Array[Dictionary] = []
	for case_index in range(6):
		_axis(0.0)
		await _ticks(4)
		actor.reset_actor()
		var facing := 1 if case_index < 4 else -1
		actor.facing = facing
		actor.visual.rotation.y = PI * 0.5 if facing > 0 else -PI * 0.5
		await _ticks(8)
		_axis(float(facing))
		await _ticks(30)
		assert(actor.state == "Locomotion" and actor.current_clip == "Walk")
		var phase: float = [0.05, 0.30, 0.55, 0.80, 0.15, 0.65][case_index]
		actor.animation_player.seek(phase * 0.8, true)
		var before: Array[Transform3D] = []
		for i in range(skeleton.get_bone_count()):
			before.append(skeleton.get_bone_global_pose(i))
		actor._begin_jump()
		assert(actor.state == "JumpPrepare")
		for i in range(skeleton.get_bone_count()):
			var after := skeleton.get_bone_global_pose(i)
			maximum_entry_snap = maxf(maximum_entry_snap, before[i].origin.distance_to(after.origin))
		assert(maximum_entry_snap < 0.0001, "Jump entry snaps: " + str(maximum_entry_snap))
		var air := false
		var landed := false
		var capture_prepare := false
		var capture_air := false
		var peak := 0.0
		for frame in range(180):
			await physics_frame
			peak = maxf(peak, actor.position.y)
			var gaze := _gaze(actor)
			gaze_min = minf(gaze_min, gaze)
			gaze_max = maxf(gaze_max, gaze)
			if actor.state == "JumpPrepare":
				for side: String in ["L", "R"]:
					for part: String in ["shin", "foot"]:
						var i := skeleton.find_bone("DEF-" + part + "." + side)
						maximum_attachment_error = maxf(maximum_attachment_error, absf(skeleton.get_bone_pose_position(i).length() - skeleton.get_bone_rest(i).origin.length()))
				if case_index == 0 and actor.state_time > 0.05 and not capture_prepare:
					capture_prepare = true
					await _capture("jump_prepare")
			if actor.state == "Air":
				air = true
				if case_index == 0 and not capture_air:
					capture_air = true
					await _capture("jump_air_gaze")
			if actor.state == "Land":
				landed = true
			if landed and actor.state == "Locomotion":
				break
		assert(air and landed and actor.is_on_floor() and peak > 0.45)
		cases.append({"walk_phase": phase, "facing": facing, "peak_m": peak})
	assert(maximum_attachment_error < 0.0001)
	# The calibrated model's intrinsic face angle is about 15 degrees below its reference axis.
	assert(gaze_min > 5.0 and gaze_max < 26.0, "Gaze range: " + str([gaze_min, gaze_max]))
	_axis(0.0)
	await _ticks(4)
	actor.reset_actor()
	await _ticks(10)
	_axis(1.0)
	await _ticks(80)
	await _capture("brisk_walk_gaze")
	print("REVIEW_FINAL_STATE ", actor.state, " clip=", actor.current_clip, " speed=", actor.velocity, " position=", actor.position, " stick=", actor.stick, " walk_only=", actor.walk_only)
	assert(absf(actor.velocity.x - 0.72) < 0.001, "Final speed: " + str(actor.velocity))
	var report := {"jump_cases": cases, "maximum_entry_snap_m": maximum_entry_snap, "maximum_leg_attachment_error_m": maximum_attachment_error, "gaze_reference_min_degrees": gaze_min, "gaze_reference_max_degrees": gaze_max, "walk_speed_m_s": actor.velocity.x}
	var file := FileAccess.open("res://../Builds/Validation/MIKO7/v5/godot_review_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("MIKO7_REVIEW_V5_PASSED ", JSON.stringify(report))
	quit()
