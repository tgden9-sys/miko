extends SceneTree

var player: Node2D
var camera: Camera2D
var ladder: Area2D
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _key(code: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = down
	Input.parse_input_event(e)

func _frames(n: int) -> void:
	for i in range(n):
		await physics_frame

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa_v29/" + name + ".png")

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
		push_error(msg)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_v29/ladder_frames"))
	var scene: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(scene)
	scene.get_node("Crates").queue_free()
	player = scene.get_node("Robot")
	camera = scene.get_node("Camera2D")
	ladder = scene.get_node("Ladders/LadderCentral")
	camera.set("target", null)
	camera.zoom = Vector2(2.8, 2.8)
	camera.limit_left = -100000
	camera.limit_top = -100000
	camera.limit_right = 100000
	camera.limit_bottom = 100000
	scene.get_node("ParallaxForeground").hide()
	await _frames(20)
	player.global_position = Vector2(ladder.climb_x, 830)
	player.set("velocity", Vector2.ZERO)
	camera.global_position = Vector2(ladder.climb_x, 730)
	await _frames(20)
	_key(KEY_W, true)
	await _frames(38)
	_check(player.get("ladder_state") != 0, "Mount failed")
	_key(KEY_W, false)
	await _frames(4)
	await _capture("ladder_hold")
	_key(KEY_W, true)
	var start_y: float = player.position.y
	for i in range(60):
		await _frames(2)
		await _capture("ladder_frames/%03d" % i)
	_key(KEY_W, false)
	_check(player.position.y < start_y - 120, "Climb did not advance")
	await _capture("ladder_ascending")
	await _frames(4)
	_key(KEY_S, true)
	await _frames(30)
	_key(KEY_S, false)
	await _frames(3)
	await _capture("ladder_descending_hold")
	_key(KEY_W, true)
	await _frames(160)
	_key(KEY_W, false)
	_check(player.get("ladder_state") == 0, "Top dismount failed")
	await _capture("ladder_top_dismount")
	# Re-mount from the ledge and then jump off.
	player.global_position = Vector2(ladder.climb_x, ladder.top_y - 18)
	player.set("velocity", Vector2.ZERO)
	await _frames(3)
	_key(KEY_S, true)
	await _frames(40)
	_key(KEY_S, false)
	_check(player.get("ladder_state") != 0, "Top mount down failed")
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(player.get("ladder_state") == 0, "Jump off failed")
	print("LADDER_RESULT failures=", failures)
	quit(0 if failures.is_empty() else 1)
