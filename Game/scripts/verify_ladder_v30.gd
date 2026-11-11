extends SceneTree

var player: CharacterBody2D
var camera: Camera2D
var ladder: Area2D
var failures: Array[String] = []
var shot: int = 0

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

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
		push_error(msg)

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		return
	camera.global_position = player.global_position + Vector2(0, -18)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa_v30/%03d.png" % shot)
	shot += 1

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_v30"))
	root.size = Vector2i(800, 640)
	root.content_scale_size = Vector2i(800, 640)
	var scene: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(scene)
	scene.get_node("Crates").queue_free()
	scene.get_node("ParallaxForeground").hide()
	player = scene.get_node("Robot")
	ladder = scene.get_node("Ladders/LadderCentral")
	camera = scene.get_node("Camera2D")
	camera.set("target", null)
	camera.zoom = Vector2(3, 3)
	camera.limit_left = -100000
	camera.limit_top = -100000
	camera.limit_right = 100000
	camera.limit_bottom = 100000
	await _frames(20)
	for face in [1, -1]:
		player.set("visual_facing", face)
		player.set("facing", face)
		player.global_position = Vector2(ladder.climb_x, 830)
		player.velocity = Vector2.ZERO
		await _frames(15)
		_key(KEY_W, true)
		await _frames(35)
		for wait_frame in range(40):
			if player.get("ladder_state") == 2:
				break
			_key(KEY_W, true)
			await _frames(1)
		_check(player.get("ladder_state") == 2, "Mount did not finish")
		var low: float = 1.0
		var high: float = 0.0
		for i in range(48):
			# Reassert the held test key if the hidden capture window gains focus.
			_key(KEY_W, true)
			await _frames(1)
			var art: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
			_check(art.animation == &"ladder_idle" and art.frame == 0, "Climbing grip moved")
			_check(absf(player.velocity.y + 126.0) < 0.1, "Ascent is not 126 px/s")
			var output: float = player.get_node("ProceduralExhaust").get("output")
			if i > 15:
				low = minf(low, output)
				high = maxf(high, output)
			if i % 2 == 0:
				await _capture()
		_key(KEY_W, false)
		_check(high - low > 0.09, "Extra booster pulses are not visible in output")
		await _frames(5)
		for i in range(8):
			await _frames(2)
			_check(player.get_node("AnimatedSprite2D").frame == 0, "Holding grip wobbled")
			await _capture()
		_key(KEY_S, true)
		var release_seen: bool = false
		var release_frames: int = 0
		for i in range(240):
			await _frames(1)
			var state: int = player.get("ladder_state")
			if state == 4:
				release_seen = true
				release_frames += 1
				_check(str(player.get_node("AnimatedSprite2D").animation).begins_with("ladder_dismount_"), "Release clip missing")
			if i % 2 == 0:
				await _capture()
			if release_seen and state == 0:
				break
		_key(KEY_S, false)
		_check(release_seen, "Bottom exit snapped without release state")
		_check(release_frames >= 10, "Release finished too quickly")
		_check(player.get("ladder_state") == 0, "Release did not complete")
		for i in range(8):
			await _frames(2)
			await _capture()
		print("LADDER_V30 facing=", face, " boost_range=", low, "..", high, " release_frames=", release_frames)
	print("LADDER_V30_RESULT failures=", failures)
	quit(0 if failures.is_empty() else 1)
