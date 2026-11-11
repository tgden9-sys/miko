extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	for i in range(30):
		await physics_frame

	var actor = level.actor
	var jump_dropdown: OptionButton = level.jump_mode
	assert(jump_dropdown != null, "jump_mode OptionButton must exist in HUD")
	assert(actor.tight_jump == true, "tight_jump defaults to true")
	assert(jump_dropdown.selected == 0, "Dropdown should select Improved [0] initially")

	# 1. Test Key 0 (Existing Jump)
	var key_0 := InputEventKey.new()
	key_0.physical_keycode = KEY_0
	key_0.pressed = true
	Input.parse_input_event(key_0)
	await physics_frame
	key_0.pressed = false
	Input.parse_input_event(key_0)
	await physics_frame
	await physics_frame

	assert(actor.tight_jump == false, "KEY_0 should set tight_jump = false")
	assert(jump_dropdown.selected == 1, "Dropdown should update to Existing (index 1) on KEY_0")

	# Execute jump with existing timing
	var key_space := InputEventKey.new()
	key_space.physical_keycode = KEY_SPACE
	key_space.pressed = true
	Input.parse_input_event(key_space)
	await physics_frame
	key_space.pressed = false
	Input.parse_input_event(key_space)

	var orig_launch_frame := -1
	var saw_gather := false
	for frame in range(1, 35):
		if actor.state == "JumpGather":
			saw_gather = true
		if actor.launched and orig_launch_frame == -1:
			orig_launch_frame = frame
		await physics_frame

	assert(saw_gather, "Existing jump should enter JumpGather state")
	assert(orig_launch_frame >= 6, "Existing jump should delay takeoff by ~8 frames (133ms)")

	# Wait for landing
	for frame in range(60):
		if actor.is_on_floor() and actor.state in ["Locomotion", "GroundStop"]:
			break
		await physics_frame

	for frame in range(20):
		await physics_frame

	# 2. Test Key 9 (Improved Jump)
	var key_9 := InputEventKey.new()
	key_9.physical_keycode = KEY_9
	key_9.pressed = true
	Input.parse_input_event(key_9)
	await physics_frame
	key_9.pressed = false
	Input.parse_input_event(key_9)
	await physics_frame
	await physics_frame

	assert(actor.tight_jump == true, "KEY_9 should set tight_jump = true")
	assert(jump_dropdown.selected == 0, "Dropdown should update to Improved (index 0) on KEY_9")

	# Execute jump with improved timing
	key_space.pressed = true
	Input.parse_input_event(key_space)
	await physics_frame
	key_space.pressed = false
	Input.parse_input_event(key_space)

	var tight_launch_frame := -1
	for frame in range(1, 35):
		if actor.launched and tight_launch_frame == -1:
			tight_launch_frame = frame
		await physics_frame

	assert(tight_launch_frame <= 2, "Tight jump should launch within 1-2 frames")

	# Wait for landing
	for frame in range(60):
		if actor.is_on_floor() and actor.state in ["Locomotion", "GroundStop"]:
			break
		await physics_frame

	# 3. Test Dropdown UI selection
	jump_dropdown.select(1)
	level._jump_mode_changed(1)
	await physics_frame
	assert(actor.tight_jump == false, "Selecting dropdown 1 sets tight_jump = false")

	jump_dropdown.select(0)
	level._jump_mode_changed(0)
	await physics_frame
	assert(actor.tight_jump == true, "Selecting dropdown 0 sets tight_jump = true")

	# 4. Test F9 hotkey toggle
	var key_f9 := InputEventKey.new()
	key_f9.physical_keycode = KEY_F9
	key_f9.pressed = true
	level._unhandled_key_input(key_f9)
	await physics_frame
	assert(actor.tight_jump == false, "F9 should toggle tight_jump to false")
	assert(jump_dropdown.selected == 1, "Dropdown should update to index 1 on F9")

	level._unhandled_key_input(key_f9)
	await physics_frame
	assert(actor.tight_jump == true, "F9 should toggle tight_jump back to true")
	assert(jump_dropdown.selected == 0, "Dropdown should update to index 0 on second F9")

	print("VERIFY_MOCKUP_JUMP_TOGGLE_SUCCESS: All tests passed!")
	quit(0)
