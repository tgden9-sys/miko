extends SceneTree

var level: Node3D
var actor: CharacterBody3D
var captures: Array[String] = []

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

func _jump(pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_B
	event.pressed = pressed
	Input.parse_input_event(event)

func _capture(label: String) -> void:
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://../Builds/Validation/MIKO7/v6/godot_" + label + ".png"
	assert(root.get_texture().get_image().save_png(path) == OK)
	captures.append(label)
	print("CAPTURED ", label)

func _run() -> void:
	level = load("res://scenes/miko7_movement_test.tscn").instantiate() as Node3D
	root.add_child(level)
	actor = level.actor
	await _ticks(20)
	assert(actor.ready_for_input and actor.clips.size() == 10)
	assert(actor.is_on_floor())
	assert(actor.current_clip == "Idle")
	await _capture("idle")
	_axis(0.55)
	await _ticks(45)
	assert(actor.current_clip == "Walk" and actor.position.x > 0.05)
	var walked: float = actor.position.x
	await _capture("walk")
	_axis(1.0)
	await _ticks(45)
	assert(actor.current_clip == "Sprint" and actor.position.x > walked + 0.35)
	await _capture("sprint_head_tilt")
	_jump(true)
	await _ticks(2)
	_jump(false)
	assert(actor.state == "JumpPrepare")
	var max_height := 0.0
	var took_off := false
	var air_seen := false
	var land_seen := false
	for i in range(180):
		await physics_frame
		max_height = maxf(max_height, actor.position.y)
		if not took_off and actor.position.y > 0.1:
			took_off = true
			await _capture("takeoff")
		if actor.state == "Air" and not air_seen:
			air_seen = true
			await _capture("air")
		if actor.state == "Land" and not land_seen:
			land_seen = true
			_axis(0.0)
			await _capture("land")
		if land_seen and actor.state == "Locomotion":
			break
	assert(took_off and air_seen and land_seen and max_height > 0.45)
	assert(actor.is_on_floor())
	await _ticks(20)
	_axis(-0.55)
	var turned := false
	var captured_turn := false
	for i in range(150):
		await physics_frame
		if actor.state == "Turn" and actor.state_time > 0.4 and not captured_turn:
			captured_turn = true
			await _capture("turn180")
		if actor.state == "Locomotion" and actor.facing == -1:
			turned = true
			break
	assert(turned and actor.last_turn_clip == "Turn180Right")
	_axis(0.0)
	await _ticks(25)
	var checked_turns: Array[String] = []
	for mode: String in ["180 Left", "180 Right", "90 Left x2", "90 Right x2"]:
		actor.turn_mode = mode
		var wanted: int = -actor.facing
		_axis(float(wanted) * 0.55)
		var finished := false
		for i in range(240):
			await physics_frame
			if actor.state == "Locomotion" and actor.facing == wanted:
				finished = true
				break
		assert(finished, "Turn did not finish: " + mode)
		assert(absf(angle_difference(actor.visual.rotation.y, PI * 0.5 if wanted > 0 else -PI * 0.5)) < 0.001)
		assert(absf(actor.position.z) < 0.001)
		checked_turns.append(mode)
		_axis(0.0)
		await _ticks(25)
	actor.reset_actor()
	actor.turn_mode = "Auto"
	await _ticks(5)
	assert(actor.current_clip == "Idle" and actor.is_on_floor())
	_axis(0.08)
	await _ticks(20)
	assert(actor.current_clip == "Idle" and absf(actor.velocity.x) < 0.01)
	_axis(0.0)
	# Standing jump, facing the opposite way, must also complete the full sequence.
	actor.facing = -1
	actor.visual.rotation.y = -PI * 0.5
	_jump(true)
	await _ticks(2)
	_jump(false)
	var stationary_landed := false
	for i in range(160):
		await physics_frame
		if actor.state == "Land":
			stationary_landed = true
		if stationary_landed and actor.state == "Locomotion":
			break
	assert(stationary_landed and actor.facing == -1 and actor.is_on_floor())
	# Land on a raised block, so landing follows collision rather than a fixed timer.
	actor.reset_actor()
	actor.position.x = 3.2
	await _ticks(5)
	_axis(1.0)
	_jump(true)
	await _ticks(2)
	_jump(false)
	var platform_landed := false
	for i in range(160):
		await physics_frame
		if actor.state == "Land" and actor.position.y > 0.20 and not platform_landed:
			platform_landed = true
			_axis(0.0)
			await _capture("platform_landing")
		if platform_landed and actor.state == "Locomotion":
			break
	assert(platform_landed and actor.is_on_floor())
	_axis(0.0)
	actor.reset_actor()
	await _ticks(5)
	level._toggle_pause()
	var paused_position: Vector3 = actor.position
	_axis(1.0)
	await _ticks(15)
	assert(actor.position.is_equal_approx(paused_position))
	_axis(0.0)
	level._toggle_pause()
	var result := {"clips": actor.clips.keys(), "jump_peak_m": max_height, "jump_states": actor.transition_log, "turn_modes_checked": checked_turns, "captures": captures, "standing_jump_left": stationary_landed, "raised_platform_landing": platform_landed, "deadzone_and_pause": true, "input": "Injected left-stick axis and physical B-button joypad events"}
	var report := FileAccess.open("res://../Builds/Validation/MIKO7/v6/godot_movement_validation.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(result, "  "))
	print("MIKO7_MOVEMENT_CHECK_PASSED ", JSON.stringify(result))
	quit()
