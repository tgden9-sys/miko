extends SceneTree


func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	var viewport_width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var viewport_height: int = int(ProjectSettings.get_setting("display/window/size/viewport_height"))
	print("VIEWPORT ", viewport_width, "x", viewport_height)
	if viewport_width != 1920 or viewport_height != 1080:
		push_error("Demo viewport is not 1920 x 1080")
		quit(1)
		return
	var frames: SpriteFrames = load("res://sprites/robot_frames.tres")
	if frames == null:
		push_error("SpriteFrames did not load")
		quit(1)
		return
	for name in [&"idle", &"move", &"jump", &"dash",
		&"move_start", &"move_stop", &"land",
		&"aim_left_arm", &"aim_right_arm",
		&"idle_left", &"move_left", &"jump_left", &"dash_left",
		&"move_start_left", &"move_stop_left", &"land_left",
		&"aim_left_arm_left", &"aim_right_arm_left",
		&"turn_to_left", &"turn_to_right"]:
		var count: int = frames.get_frame_count(name)
		print("CLIP ", name, " ", count)
		if count == 0 or frames.get_frame_texture(name, 0) == null:
			push_error("Missing frames for " + str(name))
			quit(1)
			return
	for arm in ["left_arm", "right_arm"]:
		for view in ["", "_left"]:
			for degrees in range(2, 41, 2):
				for direction in ["up", "down"]:
					var angle_name: StringName = StringName("aim_" + arm + view + "_" + direction + str(degrees))
					if not frames.has_animation(angle_name) or frames.get_frame_count(angle_name) != 1:
						push_error("Missing arm elevation " + str(angle_name))
						quit(1)
						return
	var demo: PackedScene = load("res://scenes/demo.tscn")
	if demo == null:
		push_error("Demo scene did not load")
		quit(1)
		return
	var instance: Node = demo.instantiate()
	root.add_child(instance)
	await process_frame
	var player: CharacterBody2D = instance.get_node("Robot")
	var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	var beam: Line2D = player.get_node("AimBeam")
	print("DEMO_READY player=", player.position, " animation=", sprite.animation)
	if not sprite.scale.is_equal_approx(Vector2(0.364, 0.364)):
		push_error("Robot sprite is not 70% of the previous size")
		quit(1)
		return
	var hitbox: CollisionShape2D = player.get_node("CollisionShape2D")
	var rectangle: RectangleShape2D = hitbox.shape as RectangleShape2D
	if rectangle == null or not rectangle.size.is_equal_approx(Vector2(40.6, 65.8)):
		push_error("Collision shape did not scale with sprite")
		quit(1)
		return
	for tick in range(45):
		await physics_frame
	if not player.is_on_floor():
		push_error("Player did not settle on demo floor")
		quit(1)
		return
	var start_x: float = player.position.x
	var move_press := InputEventKey.new()
	move_press.keycode = KEY_D
	move_press.pressed = true
	Input.parse_input_event(move_press)
	for tick in range(8):
		await physics_frame
	print("MOVE_TEST delta_x=", player.position.x - start_x, " animation=", sprite.animation)
	if player.position.x - start_x < 35.0:
		push_error("Move input is slower than the requested speed")
		quit(1)
		return
	if sprite.animation != &"move_start":
		push_error("Movement anticipation clip did not start")
		quit(1)
		return
	var move_release := InputEventKey.new()
	move_release.keycode = KEY_D
	move_release.pressed = false
	Input.parse_input_event(move_release)
	await physics_frame
	await physics_frame
	print("STOP_TEST animation=", sprite.animation)
	if sprite.animation != &"move_stop":
		push_error("Movement braking clip did not start")
		quit(1)
		return
	var jump_press := InputEventKey.new()
	jump_press.keycode = KEY_SPACE
	jump_press.pressed = true
	Input.parse_input_event(jump_press)
	await physics_frame
	await physics_frame
	print("JUMP_TEST velocity_y=", player.velocity.y, " animation=", sprite.animation)
	if player.velocity.y >= 0.0:
		push_error("Jump input did not launch player")
		quit(1)
		return
	var dash_press := InputEventKey.new()
	dash_press.keycode = KEY_X
	dash_press.pressed = true
	Input.parse_input_event(dash_press)
	await physics_frame
	await physics_frame
	print("DASH_TEST velocity_x=", player.velocity.x, " animation=", sprite.animation)
	if player.velocity.x < 750.0:
		push_error("Dash input did not accelerate player")
		quit(1)
		return
	var dash_release := InputEventKey.new()
	dash_release.keycode = KEY_X
	dash_release.pressed = false
	Input.parse_input_event(dash_release)
	var jump_release := InputEventKey.new()
	jump_release.keycode = KEY_SPACE
	jump_release.pressed = false
	Input.parse_input_event(jump_release)
	var left_press := InputEventKey.new()
	left_press.keycode = KEY_A
	left_press.pressed = true
	Input.parse_input_event(left_press)
	await physics_frame
	await physics_frame
	print("TURN_LEFT_START animation=", sprite.animation)
	if sprite.animation != &"turn_to_left":
		push_error("Left turn clip was not triggered")
		quit(1)
		return
	for tick in range(48):
		await physics_frame
	print("TURN_LEFT_TEST facing=", player.get("visual_facing"),
		" animation=", sprite.animation, " flip_h=", sprite.flip_h)
	if player.get("visual_facing") != -1 or sprite.flip_h:
		push_error("Real left turn did not complete")
		quit(1)
		return
	var left_release := InputEventKey.new()
	left_release.keycode = KEY_A
	left_release.pressed = false
	Input.parse_input_event(left_release)
	var right_press := InputEventKey.new()
	right_press.keycode = KEY_D
	right_press.pressed = true
	Input.parse_input_event(right_press)
	await physics_frame
	await physics_frame
	print("TURN_RIGHT_START animation=", sprite.animation)
	if sprite.animation != &"turn_to_right":
		push_error("Right turn clip was not triggered")
		quit(1)
		return
	for tick in range(48):
		await physics_frame
	print("TURN_RIGHT_TEST facing=", player.get("visual_facing"),
		" animation=", sprite.animation, " flip_h=", sprite.flip_h)
	if player.get("visual_facing") != 1 or sprite.flip_h:
		push_error("Real right turn did not complete")
		quit(1)
		return
	var right_release := InputEventKey.new()
	right_release.keycode = KEY_D
	right_release.pressed = false
	Input.parse_input_event(right_release)
	for tick in range(25):
		await physics_frame
	var landing_jump := InputEventKey.new()
	landing_jump.keycode = KEY_SPACE
	landing_jump.pressed = true
	Input.parse_input_event(landing_jump)
	await physics_frame
	await physics_frame
	var landing_jump_release := InputEventKey.new()
	landing_jump_release.keycode = KEY_SPACE
	landing_jump_release.pressed = false
	Input.parse_input_event(landing_jump_release)
	var saw_landing: bool = false
	for tick in range(95):
		await physics_frame
		if sprite.animation == &"land":
			saw_landing = true
			break
	print("LAND_TEST saw_landing=", saw_landing, " animation=", sprite.animation)
	if not saw_landing:
		push_error("Landing recovery clip did not play")
		quit(1)
		return
	var aim_move_press := InputEventKey.new()
	aim_move_press.keycode = KEY_D
	aim_move_press.pressed = true
	Input.parse_input_event(aim_move_press)
	for tick in range(4):
		await physics_frame
	var left_aim_press := InputEventKey.new()
	left_aim_press.keycode = KEY_Q
	left_aim_press.pressed = true
	Input.parse_input_event(left_aim_press)
	await physics_frame
	await physics_frame
	print("LEFT_AIM_TEST animation=", sprite.animation, " velocity_x=", player.velocity.x)
	if sprite.animation != &"aim_left_arm" or absf(player.velocity.x) > 0.01:
		push_error("Left-arm aim did not stop and raise the arm")
		quit(1)
		return
	var aim_move_release := InputEventKey.new()
	aim_move_release.keycode = KEY_D
	aim_move_release.pressed = false
	Input.parse_input_event(aim_move_release)
	for tick in range(35):
		await physics_frame
	if sprite.frame != 11:
		push_error("Left-arm firing pose did not hold")
		quit(1)
		return
	if not beam.visible or beam.default_color.r < 0.9:
		push_error("Red hand beam did not appear at the raised pose")
		quit(1)
		return
	var up_press := InputEventKey.new()
	up_press.keycode = KEY_UP
	up_press.pressed = true
	Input.parse_input_event(up_press)
	for tick in range(18):
		await physics_frame
	print("RED_UP_TEST angle=", player.get("aim_angle_degrees"), " animation=", sprite.animation)
	if player.get("aim_angle_degrees") <= 0.0 or beam.points[1].y >= beam.points[0].y or not str(sprite.animation).contains("_up"):
		push_error("Up did not raise both the red arm and beam")
		quit(1)
		return
	var up_release := InputEventKey.new()
	up_release.keycode = KEY_UP
	up_release.pressed = false
	Input.parse_input_event(up_release)
	var down_press := InputEventKey.new()
	down_press.keycode = KEY_DOWN
	down_press.pressed = true
	Input.parse_input_event(down_press)
	for tick in range(54):
		await physics_frame
	print("RED_DOWN_TEST angle=", player.get("aim_angle_degrees"), " animation=", sprite.animation)
	if player.get("aim_angle_degrees") >= 0.0 or beam.points[1].y <= beam.points[0].y or not str(sprite.animation).contains("_down"):
		push_error("Down did not lower both the red arm and beam")
		quit(1)
		return
	var down_release := InputEventKey.new()
	down_release.keycode = KEY_DOWN
	down_release.pressed = false
	Input.parse_input_event(down_release)
	var left_aim_release := InputEventKey.new()
	left_aim_release.keycode = KEY_Q
	left_aim_release.pressed = false
	Input.parse_input_event(left_aim_release)
	await physics_frame
	await physics_frame
	print("LEFT_LOWER_TEST animation=", sprite.animation, " lowering=", player.get("aim_lowering"))
	if not player.get("aim_lowering"):
		push_error("Left arm did not begin lowering")
		quit(1)
		return
	if beam.visible:
		push_error("Red beam remained after Q release")
		quit(1)
		return
	for tick in range(35):
		await physics_frame
	if player.get("aim_side") != &"":
		push_error("Left arm did not finish lowering")
		quit(1)
		return
	var right_aim_press := InputEventKey.new()
	right_aim_press.keycode = KEY_E
	right_aim_press.pressed = true
	Input.parse_input_event(right_aim_press)
	await physics_frame
	await physics_frame
	print("RIGHT_AIM_TEST animation=", sprite.animation, " velocity_x=", player.velocity.x)
	if sprite.animation != &"aim_right_arm" or absf(player.velocity.x) > 0.01:
		push_error("Right-arm aim did not stop and raise the arm")
		quit(1)
		return
	for tick in range(35):
		await physics_frame
	if not beam.visible or beam.default_color.b < 0.9:
		push_error("Blue hand beam did not appear at the raised pose")
		quit(1)
		return
	var right_aim_release := InputEventKey.new()
	right_aim_release.keycode = KEY_E
	right_aim_release.pressed = false
	Input.parse_input_event(right_aim_release)
	quit(0)
