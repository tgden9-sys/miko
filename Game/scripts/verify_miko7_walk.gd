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

func _save(label: String) -> void:
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO7/v5/godot_walk_" + label + ".png") == OK)

func _run() -> void:
	var level: Node3D = load("res://scenes/miko7_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor: CharacterBody3D = level.actor
	actor.walk_only = true
	await _ticks(20)
	_axis(1.0)
	await _ticks(90)
	assert(actor.current_clip == "Walk")
	assert(absf(actor.velocity.x - float(actor.metadata["clips"]["Walk"]["nominal_speed"])) < 0.001)
	var skeleton: Skeleton3D = actor.visual.find_children("*", "Skeleton3D", true, false)[0]
	var head := skeleton.find_bone("DEF-head")
	var hips := skeleton.find_bone("DEF-hips")
	var feet := {"L": skeleton.find_bone("DEF-foot.L"), "R": skeleton.find_bone("DEF-foot.R")}
	var max_head := -INF
	var min_head := INF
	var max_hip := -INF
	var min_hip := INF
	var max_plant_slip := 0.0
	var contact_pairs := 0
	var previous: Dictionary = {}
	for i in range(180):
		await physics_frame
		var head_y: float = (skeleton.global_transform * skeleton.get_bone_global_pose(head).origin).y
		var hip_y: float = (skeleton.global_transform * skeleton.get_bone_global_pose(hips).origin).y
		max_head = maxf(max_head, head_y)
		min_head = minf(min_head, head_y)
		max_hip = maxf(max_hip, hip_y)
		min_hip = minf(min_hip, hip_y)
		var phase: float = actor.animation_player.current_animation_position / float(actor.metadata["clips"]["Walk"]["duration"])
		for side: String in ["L", "R"]:
			var p := fposmod(phase + (0.0 if side == "L" else 0.5), 1.0)
			var stance: float = actor.metadata["clips"]["Walk"]["stance_fraction"]
			var planted := p > stance * 0.15 and p < stance * 0.78
			var position: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(feet[side]).origin
			if planted and previous.has(side) and bool(previous[side]["planted"]):
				max_plant_slip = maxf(max_plant_slip, absf(position.x - float(previous[side]["x"])))
				contact_pairs += 1
			previous[side] = {"x": position.x, "planted": planted}
	assert(contact_pairs > 30)
	assert(max_head - min_head < 0.009)
	assert(max_hip - min_hip < 0.004)
	assert(max_plant_slip < 0.002, "Plant slips by " + str(max_plant_slip))
	await _save("side")
	level.quarter_view = true
	await _ticks(15)
	await _save("quarter")
	_axis(-1.0)
	var reversed := false
	for i in range(180):
		await physics_frame
		if actor.facing == -1 and actor.state == "Locomotion" and actor.current_clip == "Walk":
			reversed = true
			break
	assert(reversed)
	await _ticks(30)
	assert(actor.current_clip == "Walk")
	_axis(0.0)
	await _ticks(40)
	assert(actor.current_clip == "Idle")
	var result := {"head_vertical_range_m": max_head - min_head, "hip_vertical_range_m": max_hip - min_hip, "maximum_planted_foot_world_slip_per_frame_m": max_plant_slip, "contact_pairs": contact_pairs, "walk_speed_m_s": actor.WALK_SPEED, "walk_only_full_stick": true, "reversal_and_stop": reversed}
	var report := FileAccess.open("res://../Builds/Validation/MIKO7/v5/godot_walk_validation.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(result, "  "))
	print("MIKO7_WALK_CHECK_PASSED ", JSON.stringify(result))
	quit()
