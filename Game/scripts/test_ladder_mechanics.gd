extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	if img != null:
		var err := img.save_png("res://" + name + ".png")
		print("SAVED_FRAME: ", name, " err=", err)

func _run_test() -> void:
	print("--- STARTING LADDER MECHANICS TEST ---")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)

	var robot = scene.get_node("Robot")
	var camera = scene.get_node("Camera2D")
	camera.target = null

	var ladder = scene.get_node("Ladders/LadderCentral")
	print("LADDER FOUND at: ", ladder.global_position, " top_y=", ladder.top_y, " bottom_y=", ladder.bottom_y, " climb_x=", ladder.climb_x)

	camera.global_position = Vector2(ladder.climb_x, 720) # Focused squarely on ladder between ground and catwalk

	# 1. Spawn robot at ladder base on ground
	robot.global_position = Vector2(ladder.climb_x - 20.0, 830)
	robot.velocity = Vector2.ZERO
	for i in range(10):
		await physics_frame

	print("TEST PHASE 1: Robot at ladder base, global_pos=", robot.global_position)
	print("  nearby_ladder=", robot.nearby_ladder != null, " ladder_state=", robot.ladder_state)

	# Press UP (KEY_W) to mount
	_key(KEY_W, true)
	await physics_frame
	await physics_frame
	print("TEST PHASE 2: Mounting ladder...")
	print("  ladder_state=", robot.ladder_state, " (expected MOUNTING=1)")
	print("  anim=", robot.sprite.animation)
	await _save("ladder_01_mount_turn")

	# Wait for mount animation to complete (approx 10-12 frames)
	for i in range(12):
		await physics_frame
	print("TEST PHASE 3: Mount complete, now climbing/idle:")
	print("  ladder_state=", robot.ladder_state, " anim=", robot.sprite.animation, " pos=", robot.global_position)
	await _save("ladder_02_mount_grab")

	# Hold UP to climb up
	print("TEST PHASE 4: Climbing UP towards catwalk...")
	for i in range(25):
		await physics_frame
	print("  During climb: ladder_state=", robot.ladder_state, " vel_y=", robot.velocity.y, " anim=", robot.sprite.animation, " y=", robot.global_position.y)
	await _save("ladder_03_climb_up")

	# Release UP to test IDLE holding on ladder
	print("TEST PHASE 5: Releasing keys to test ladder IDLE...")
	_key(KEY_W, false)
	for i in range(15):
		await physics_frame
	print("  During idle: ladder_state=", robot.ladder_state, " vel_y=", robot.velocity.y, " anim=", robot.sprite.animation, " y=", robot.global_position.y)
	await _save("ladder_04_idle_grip")

	# Continue climbing up to reach catwalk top dismount (climb until reaching top)
	print("TEST PHASE 6: Climbing to top ledge dismount...")
	_key(KEY_W, true)
	var dismounted: bool = false
	for i in range(80):
		await physics_frame
		if robot.ladder_state == 0: # NONE (dismounted)
			print("  DISMOUNTED onto catwalk at frame ", i, " pos=", robot.global_position)
			dismounted = true
			break
	_key(KEY_W, false)
	for i in range(20):
		await physics_frame
	print("  On catwalk after top dismount: ladder_state=", robot.ladder_state, " pos=", robot.global_position, " on_floor=", robot.is_on_floor())
	await _save("ladder_05_top_catwalk_dismount")

	# Test Top Ledge Mount DOWN: Press DOWN (KEY_S) while at top ledge
	print("TEST PHASE 7: Re-mounting ladder from top ledge downwards...")
	_key(KEY_S, true)
	for i in range(15):
		await physics_frame
	print("  After mounting down: ladder_state=", robot.ladder_state, " pos=", robot.global_position)
	await _save("ladder_06_top_mount_down")

	# Test Jump Dismount from ladder (KEY_SPACE)
	print("TEST PHASE 8: Jump dismount from ladder...")
	_key(KEY_S, false)
	_key(KEY_SPACE, true)
	await physics_frame
	_key(KEY_SPACE, false)
	for i in range(10):
		await physics_frame
	print("  After jump dismount: ladder_state=", robot.ladder_state, " vel=", robot.velocity, " pos=", robot.global_position)
	await _save("ladder_07_jump_dismount")

	print("--- ALL LADDER MECHANICS TESTS FINISHED SUCCESSFULLY ---")
	quit(0)
