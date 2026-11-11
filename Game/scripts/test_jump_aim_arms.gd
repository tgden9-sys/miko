extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _save(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	if img != null:
		var err := img.save_png("res://" + name + ".png")
		print("SAVED_DEBUG_FRAME: ", name, " err=", err)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_test() -> void:
	print("STARTING_JUMP_AIM_ARMS_PROBE")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")

	# Settle physics for 25 frames
	for i in range(25):
		await physics_frame

	print("INITIATING JUMP (HOLDING SPACE)...")
	_key(KEY_SPACE, true)
	for i in range(8):
		await physics_frame

	print("AIRBORNE JUMP VELOCITY: ", robot.velocity.y, " Y POS: ", robot.global_position.y)
	assert(robot.velocity.y < -200.0, "Must be rising in the air!")

	print("MID-AIR STATE BEFORE AIM:")
	print("  sprite.anim: ", robot.sprite.animation, " frame: ", robot.sprite.frame, " vis: ", robot.sprite.visible)
	print("  body_layer.vis: ", robot.body_layer.visible)
	print("  arm_l_pivot.gpos: ", robot.arm_l_pivot.global_position, " vis: ", robot.arm_l_pivot.visible)
	print("  arm_r_pivot.gpos: ", robot.arm_r_pivot.global_position, " vis: ", robot.arm_r_pivot.visible)

	print("NOW INITIATING LASER IN MID-AIR (HOLDING SPACE + Q)...")
	_key(KEY_Q, true)
	for f in range(12):
		await physics_frame
		print("FRAME ", f, " (vel.y=", robot.velocity.y, ", grounded=", robot.is_on_floor(), "):")
		print("  robot.gpos: ", robot.global_position)
		print("  sprite.anim: ", robot.sprite.animation, " frame: ", robot.sprite.frame, " vis: ", robot.sprite.visible)
		print("  body_layer.anim: ", robot.body_layer.animation, " frame: ", robot.body_layer.frame, " vis: ", robot.body_layer.visible, " gpos: ", robot.body_layer.global_position)
		print("  arm_l_pivot.gpos: ", robot.arm_l_pivot.global_position, " vis: ", robot.arm_l_pivot.visible)
		print("  arm_r_pivot.gpos: ", robot.arm_r_pivot.global_position, " vis: ", robot.arm_r_pivot.visible)
		print("  arm_l.anim: ", robot.arm_l.animation, " frame: ", robot.arm_l.frame, " vis: ", robot.arm_l.visible, " pos: ", robot.arm_l.position)
		print("  arm_r.anim: ", robot.arm_r.animation, " frame: ", robot.arm_r.frame, " vis: ", robot.arm_r.visible, " pos: ", robot.arm_r.position)
		for p in robot.arm_l_parts:
			print("    arm_l part ", p.name, " vis: ", p.visible, " gpos: ", p.global_position)
		for p in robot.arm_r_parts:
			print("    arm_r part ", p.name, " vis: ", p.visible, " gpos: ", p.global_position)

	await _save("probe_jump_midair_aim")
	quit(0)
