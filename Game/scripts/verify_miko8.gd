extends SceneTree

var level: Node3D
var actor: CharacterBody3D
var report := {"native_clips": {}, "turns": [], "controller": {}, "captures": []}

func _initialize() -> void: call_deferred("_run")

func _ticks(n: int) -> void:
	for i in range(n): await physics_frame

func _axis(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _jump(value: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_B
	event.pressed = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/godot_" + label + ".png") == OK)
	report.captures.append(label)

func _reset() -> void:
	_axis(0.0)
	await _ticks(3)
	actor.reset_actor()
	actor.position.x = -4.0
	level.follow_x = -4.0
	await _ticks(6)
	for i in range(30):
		if actor.is_on_floor(): break
		await physics_frame
	assert(actor.is_on_floor(), "Reset did not settle onto the floor")

func _run() -> void:
	level = load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	actor = level.actor
	await _ticks(15)
	assert(actor.clips.size() >= 13 and actor.is_on_floor())
	actor.set_physics_process(false)
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../Builds/Validation/MIKO8/engine_reference.json"))
	for label: String in actor.clips:
		if not reference.has(label): continue # Added abilities have their own source-trajectory checks.
		actor.current_clip = ""
		actor._play(label, 0.0)
		var duration: float = actor._duration(label)
		var bones: Dictionary = {}
		var source_error := 0.0
		for f in range(reference[label].size()):
			# Loop endpoints play as frame zero in Godot; compare the authored samples before that wrap.
			if bool(actor.metadata.clips[label].loop) and f == reference[label].size() - 1: continue
			actor.animation_player.seek(float(f) / 30.0, true)
			for bone: String in reference[label][f]:
				var index: int = actor.skeleton.find_bone(bone)
				assert(index >= 0, "Missing exported bone " + bone)
				var p: Array = reference[label][f][bone]
				var expected := Vector3(p[0],p[1],p[2])
				source_error = maxf(source_error,actor.skeleton.get_bone_global_pose(index).origin.distance_to(expected))
		assert(source_error < 0.0002, label + " differs from Blender by " + str(source_error))
		var max_length_error := 0.0
		for sample in [0.0, 0.25, 0.5, 0.75, 0.999, 0.0, 0.5, 0.0]:
			actor.animation_player.seek(duration * sample, true)
			for i in range(actor.skeleton.get_bone_count()):
				var pose: Transform3D = actor.skeleton.get_bone_global_pose(i)
				assert(pose.is_finite(), label + " invalid bone transform")
				assert(pose.origin.length() < 5.0, label + " detached bone")
				for axis in [pose.basis.x, pose.basis.y, pose.basis.z]: max_length_error = maxf(max_length_error, absf(axis.length() - 1.0))
				var key := str(sample) + "/" + str(i)
				if bones.has(key): assert(pose.is_equal_approx(bones[key]), label + " depends on seek history")
				bones[key] = pose
		assert(max_length_error < 0.001, label + " has scale distortion")
		actor.animation_player.seek(duration * 0.4, true)
		await _capture(label)
		report.native_clips[label] = {"duration": duration, "unit_scale_error": max_length_error, "blender_joint_position_error": source_error}
	actor.set_physics_process(true)
	await _reset()
	_axis(0.10)
	await _ticks(12)
	assert(actor.current_clip == "Idle" and absf(actor.velocity.x) < 0.01)
	for item in [[0.35,"Walk"],[0.65,"Run"],[1.0,"Sprint"]]:
		await _reset()
		_axis(item[0])
		await _ticks(95)
		assert(actor.current_clip == item[1], "Wrong gait: " + actor.current_clip)
		var expected: float = actor._speed(item[1])
		assert(absf(actor.velocity.x - expected) < 0.02)
		assert(is_equal_approx(actor.animation_player.speed_scale, 1.0))
		report.controller[item[1]] = {"speed": actor.velocity.x, "source_rate": actor.animation_player.speed_scale}
		await _capture("play_" + item[1])
	_axis(0.0)
	await _ticks(120)
	assert(actor.current_clip == "Idle" and absf(actor.velocity.x) < 0.01)
	for mode: String in ["180 Left", "180 Right", "90 Left x2", "90 Right x2"]:
		await _reset()
		actor.turn_mode = mode
		_axis(-0.35)
		var complete := false
		for i in range(330):
			await physics_frame
			if actor.facing == -1 and actor.state == "Locomotion":
				complete = true
				break
		assert(complete, "Turn failed: " + mode)
		assert(absf(angle_difference(actor.visual.rotation.y, -PI/2)) < 0.001)
		report.turns.append(mode)
	for direction in [1,-1]:
		await _reset()
		actor.facing = direction
		actor.visual.rotation.y = direction * PI/2
		_jump(true)
		await process_frame
		await _ticks(3)
		_jump(false)
		print("JUMP_INPUT ",direction," state=",actor.state," floor=",actor.is_on_floor()," coyote=",actor.coyote," button=",Input.is_action_pressed("miko8_jump"))
		assert(actor.state in ["JumpGather", "JumpStart"], "B jump failed, state=" + actor.state)
		var peak := 0.0
		var air := false
		var landed := false
		for i in range(300):
			await physics_frame
			peak = maxf(peak,actor.position.y)
			air = air or actor.state == "Air"
			landed = landed or actor.state == "Land"
			if landed and actor.state == "Locomotion": break
		assert(air and landed and actor.is_on_floor() and peak > 0.8)
		report.controller["jump_" + str(direction)] = {"peak": peak, "landed": landed}
	var file := FileAccess.open("res://../Builds/Validation/MIKO8/godot_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("MIKO8_CHECK_PASSED ",JSON.stringify(report))
	quit()
