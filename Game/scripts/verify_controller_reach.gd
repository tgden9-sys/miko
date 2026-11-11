extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var robot: CharacterBody2D = level.get_node("Robot")
	var pad_button := InputEventJoypadButton.new()
	pad_button.pressed = true
	pad_button.button_index = JOY_BUTTON_Y
	robot._unhandled_input(pad_button)
	assert(robot.suit_polarity == 1, "Y did not select red suit polarity")
	robot._unhandled_input(pad_button)
	assert(robot.suit_polarity == 0, "Y did not turn red suit polarity off")
	pad_button.button_index = JOY_BUTTON_X
	robot._unhandled_input(pad_button)
	assert(robot.suit_polarity == 2, "X did not select blue suit polarity")
	robot._unhandled_input(pad_button)
	assert(robot.suit_polarity == 0, "X did not turn blue suit polarity off")
	robot.current_beam_length = robot.CONTROLLER_START_REACH
	robot._apply_controller_aim(Vector2(0.1, 0.1), 1.0 / 60.0)
	assert(is_equal_approx(robot.current_beam_length, 55.0), "Aim drift bypassed dead zone")
	robot._apply_controller_aim(Vector2(1.0, 0.0), 1.0 / 60.0)
	assert(robot.current_beam_length > 55.0 and robot.current_beam_length < 70.0, "Reach jumped too far in one frame")
	var extended: float = robot.current_beam_length
	robot._apply_controller_aim(Vector2(-1.0, 0.0), 1.0 / 60.0)
	assert(robot.current_beam_length < extended, "Reverse stick did not retract reach")
	robot._apply_controller_aim(Vector2(0.0, -1.0), 1.0 / 60.0)
	assert(robot.aim_angle_degrees > 0.0 and robot.aim_angle_degrees < 4.0, "Vertical aim moved too fast")
	var elevation: float = robot.aim_angle_degrees
	robot._apply_controller_aim(Vector2(1.0, 0.0), 1.0 / 60.0)
	assert(is_equal_approx(robot.aim_angle_degrees, elevation), "Reach adjustment changed elevation")
	assert(robot.visual_facing == 1, "Reach adjustment turned MIKO")
	robot.current_beam_length = robot.MIN_BEAM_LENGTH
	for i in range(20):
		robot._apply_controller_aim(Vector2(-1.0, 0.0), 1.0 / 60.0)
	assert(robot.turning, "Holding past minimum reach did not start a turn")
	assert(robot.sprite.animation == &"turn_to_left", "Controller skipped the turn animation")
	robot._on_animation_finished()
	assert(robot.visual_facing == -1 and not robot.turning, "Controller turn did not complete")
	robot.current_beam_length = robot.CONTROLLER_START_REACH
	robot.controller_aim_mode = 1
	for i in range(240):
		robot._apply_controller_aim(Vector2(-1.0, 0.0), 1.0 / 60.0)
	assert(robot.current_beam_length > 1300.0, "Controller cannot reach the mouse laser range")
	robot.current_beam_length = 120.0
	robot.plasma_controller_armed = true
	var count_before: int = level.get_child_count()
	robot._fire_plasma()
	assert(level.get_child_count() == count_before + 1, "Plasma did not spawn")
	var bolt: Area2D = level.get_child(level.get_child_count() - 1)
	assert(bolt.life > 1.0, "Controller aim distance shortened the plasma bolt's flight")
	print("CONTROLLER_REACH_OK")
	quit()
