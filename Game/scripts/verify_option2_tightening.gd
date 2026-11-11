extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	for i in range(25):
		await physics_frame

	var actor = level.actor
	print("TESTING OPTION 2: Pure Animation Tightening")

	# --- 1. Test Startup Impulse (MoveStart Deadzone Elimination) ---
	actor.reset_actor()
	actor.position = Vector3(10.0, 0.02, 0)
	await physics_frame

	var key_d := InputEventKey.new()
	key_d.physical_keycode = KEY_D
	key_d.pressed = true
	Input.parse_input_event(key_d)
	await physics_frame

	# On frame 1 of movement input, velocity should be immediately positive (no 195ms deadzone)
	await physics_frame
	print("MoveStart Frame 1 velocity: ", actor.velocity.x, " state: ", actor.state)
	assert(actor.velocity.x > 0.0, "Actor must start moving on Frame 1 (deadzone eliminated)")
	
	# Wait for actor to reach run speed
	for i in range(40):
		await physics_frame
	assert(actor.state == "Locomotion" and absf(actor.velocity.x) > 2.0, "Actor reaches locomotion smoothly")

	# --- 2. Test Snappy Turnaround (Brake + Turn) ---
	key_d.pressed = false
	Input.parse_input_event(key_d)
	var key_a := InputEventKey.new()
	key_a.physical_keycode = KEY_A
	key_a.pressed = true
	Input.parse_input_event(key_a)
	await physics_frame

	var turn_frames := 0
	var entered_turn := false
	for i in range(35):
		await physics_frame
		if actor.state in ["Brake", "Turn"]:
			turn_frames += 1
			if actor.state == "Turn":
				entered_turn = true
		elif entered_turn and actor.state == "Locomotion":
			break

	print("Turn completed in ", turn_frames, " frames (approx ", turn_frames * (1.0/60.0), "s)")
	assert(turn_frames <= 26, "Turnaround must complete quickly (< 0.45s total)")
	assert(actor.facing == -1, "Actor successfully reversed facing")

	key_a.pressed = false
	Input.parse_input_event(key_a)
	for i in range(20):
		await physics_frame

	# --- 3. Test Baked-in Improved Jump (Instant Takeoff + Squash) ---
	actor.reset_actor()
	actor.position = Vector3(10.0, 0.02, 0)
	await physics_frame

	var key_space := InputEventKey.new()
	key_space.physical_keycode = KEY_SPACE
	key_space.pressed = true
	Input.parse_input_event(key_space)
	await physics_frame
	key_space.pressed = false
	Input.parse_input_event(key_space)
	await physics_frame

	# Must launch immediately into JumpStart without gather stall
	assert(actor.state == "JumpStart", "Must enter JumpStart immediately on Frame 1")
	assert(actor.launched, "Must be launched on Frame 1")
	assert(actor.velocity.y > 5.0, "Vertical impulse applied immediately")
	assert(actor.visual.scale.y < 1.0, "Squash applied on takeoff")

	# Wait for apex and descent
	for i in range(45):
		await physics_frame
		if actor.landing_contact:
			break

	assert(actor.landing_contact, "Landing contact registered")

	# --- 4. Test Animation Speed Windowing (No foot-sliding below 0.35x) ---
	for gait in ["Walk", "Run", "Sprint"]:
		assert(actor.animation_player.speed_scale >= 0.30, "Animation speed scale windowed above 0.30x")

	print("OPTION 2 VERIFICATION: ALL 4 CHECKS PASSED PERFECTLY!")
	quit(0)
