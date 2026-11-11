extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run_test() -> void:
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")

	for i in range(30):
		await physics_frame

	print("BEFORE JUMP:")
	print("  on_floor: ", robot.is_on_floor())
	print("  coyote: ", robot.coyote_timer)
	print("  aim_side: ", robot.aim_side)
	print("  aim_l_prog: ", robot.aim_l_progress)
	print("  aim_r_prog: ", robot.aim_r_progress)

	_key(KEY_SPACE, true)
	await physics_frame
	print("FRAME 1 OF JUMP:")
	print("  vel.y: ", robot.velocity.y)
	await physics_frame
	print("FRAME 2 OF JUMP:")
	print("  vel.y: ", robot.velocity.y)

	quit(0)
