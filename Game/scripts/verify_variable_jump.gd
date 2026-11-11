extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor = level.actor
	for i in range(20):
		await physics_frame

	print("TESTING VARIABLE JUMP HEIGHT")

	# Test 1: Short Tap Jump
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	await physics_frame
	await physics_frame
	# Release early (at frame 2, during ascent)
	key.pressed = false
	Input.parse_input_event(key)

	var tap_peak := 0.0
	for i in range(40):
		await physics_frame
		tap_peak = maxf(tap_peak, actor.position.y)
		if actor.landing_contact:
			break

	print("Short tap peak height: ", tap_peak)
	assert(tap_peak > 0.30 and tap_peak < 0.85, "Short tap jump should produce a nimble hop between 0.30m and 0.85m")

	# Wait for actor to fully land and settle
	for i in range(30):
		await physics_frame

	# Test 2: Full Hold Jump
	actor.position = Vector3(0, 0.03, 0)
	actor.velocity = Vector3.ZERO
	await physics_frame

	key.pressed = true
	Input.parse_input_event(key)

	var hold_peak := 0.0
	for i in range(40):
		await physics_frame
		hold_peak = maxf(hold_peak, actor.position.y)
		if actor.velocity.y < 0.0:
			break

	key.pressed = false
	Input.parse_input_event(key)

	print("Full hold peak height: ", hold_peak)
	assert(hold_peak > 1.20 and hold_peak < 1.45, "Full hold jump should reach standard peak between 1.20m and 1.45m")
	assert(hold_peak > tap_peak + 0.40, "Hold jump must be significantly higher than tap jump")

	print("VARIABLE JUMP TEST PASSED! Short tap: ", tap_peak, "m, Full hold: ", hold_peak, "m")
	quit(0)
