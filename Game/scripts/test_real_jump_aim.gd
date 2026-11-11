extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_test() -> void:
	print("STARTING_REAL_JUMP_AIM_INVESTIGATION")
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")

	# Settle physics for 15 frames
	for i in range(15):
		await physics_frame

	print("INITIATING JUMP (HOLDING SPACE)...")
	_key(KEY_SPACE, true)
	await physics_frame
	await physics_frame

	print("AIRBORNE JUMP VELOCITY: ", robot.velocity.y)
	assert(robot.velocity.y < -300.0, "Must be jumping!")

	# Rise for 5 frames while holding Space
	for i in range(5):
		await physics_frame

	print("MID-AIR STATE BEFORE AIM:")
	print("  pos: ", robot.global_position, " vel.y: ", robot.velocity.y)
	print("  is_on_floor: ", robot.is_on_floor())
	print("  sprite.anim: ", robot.sprite.animation, " frame: ", robot.sprite.frame)

	print("NOW INITIATING LASER IN MID-AIR (HOLDING SPACE + Q)...")
	_key(KEY_Q, true)
	for f in range(15):
		await physics_frame
		print("FRAME ", f, " (vel.y=", robot.velocity.y, ", grounded=", robot.is_on_floor(), "):")
		print("  robot.gpos: ", robot.global_position)
		print("  sprite.anim: ", robot.sprite.animation, " frame: ", robot.sprite.frame, " vis: ", robot.sprite.visible)
		print("  body_layer.anim: ", robot.body_layer.animation, " frame: ", robot.body_layer.frame, " vis: ", robot.body_layer.visible)
		print("  arm_l_pivot.gpos: ", robot.arm_l_pivot.global_position, " rot: ", robot.arm_l_pivot.rotation, " vis: ", robot.arm_l_pivot.visible)
		print("  arm_r_pivot.gpos: ", robot.arm_r_pivot.global_position, " rot: ", robot.arm_r_pivot.rotation, " vis: ", robot.arm_r_pivot.visible)
		print("  arm_l.anim: ", robot.arm_l.animation, " frame: ", robot.arm_l.frame, " vis: ", robot.arm_l.visible)
		print("  arm_r.anim: ", robot.arm_r.animation, " frame: ", robot.arm_r.frame, " vis: ", robot.arm_r.visible)
		for p in robot.arm_l_parts:
			print("    arm_l part ", p.name, " vis: ", p.visible, " gpos: ", p.global_position, " anim: ", p.animation, " frame: ", p.frame)
		for p in robot.arm_r_parts:
			print("    arm_r part ", p.name, " vis: ", p.visible, " gpos: ", p.global_position)

	var img: Image = root.get_texture().get_image()
	if img != null:
		img.save_png("res://real_jump_aim_debug.png")
		print("SAVED REAL JUMP AIM DEBUG SCREENSHOT")

	quit(0)
