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
	assert(root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO7/v6/godot_" + label + ".png") == OK)

func _run() -> void:
	var level: Node3D = load("res://scenes/miko7_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor: CharacterBody3D = level.actor
	actor.position.x = -3.4
	level.follow_x = -3.4
	await _ticks(15)
	_axis(1.0)
	await _ticks(60)
	assert(actor.current_clip == "Sprint" and absf(actor.velocity.x - 2.2) < 0.001)
	var skeleton: Skeleton3D = actor.pose_skeleton
	var head := skeleton.find_bone("DEF-head")
	var feet := {"L": skeleton.find_bone("DEF-foot.L"), "R": skeleton.find_bone("DEF-foot.R")}
	var maximum := -INF
	var minimum := INF
	var slip := 0.0
	var pairs := 0
	var previous: Dictionary = {}
	for frame in range(120):
		await physics_frame
		var y: float = (skeleton.global_transform * skeleton.get_bone_global_pose(head).origin).y
		maximum = maxf(maximum, y)
		minimum = minf(minimum, y)
		var phase: float = actor.animation_player.current_animation_position / 0.6
		for side: String in ["L", "R"]:
			var p := fposmod(phase + (0.0 if side == "L" else 0.5), 1.0)
			var contact := p > 0.30 * 0.22 and p < 0.30 * 0.65
			var point: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(feet[side]).origin
			if contact and previous.has(side) and bool(previous[side]["contact"]):
				slip = maxf(slip, absf(point.x - float(previous[side]["x"])))
				pairs += 1
			previous[side] = {"x": point.x, "contact": contact}
	assert(maximum - minimum < 0.025, "Sprint bounce: " + str(maximum - minimum))
	assert(pairs > 10 and slip < 0.003, "Sprint plant slip: " + str([pairs, slip]))
	await _save("sprint_side")
	level.quarter_view = true
	await _ticks(10)
	await _save("sprint_quarter")
	_axis(0.0)
	await _ticks(50)
	assert(actor.current_clip == "Idle" and actor.is_on_floor())
	_axis(-1.0)
	var reversed := false
	for i in range(200):
		await physics_frame
		if actor.facing == -1 and actor.state == "Locomotion" and actor.current_clip == "Sprint" and absf(actor.velocity.x) > 2.1:
			reversed = true
			break
	assert(reversed)
	var result := {"speed_m_s": 2.2, "head_bounce_m": maximum - minimum, "contact_pairs": pairs, "maximum_planted_foot_world_slip_per_tick_m": slip, "stop_and_reversal": reversed}
	var file := FileAccess.open("res://../Builds/Validation/MIKO7/v6/godot_sprint_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	print("MIKO7_SPRINT_V6_PASSED ", JSON.stringify(result))
	quit()
