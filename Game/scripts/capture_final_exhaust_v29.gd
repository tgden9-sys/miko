extends SceneTree

var player: Node2D
var camera: Camera2D
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

func _capture_frames(n: int) -> void:
	for i in range(n):
		await _frames(2)
		camera.global_position = player.global_position + Vector2(0, -20)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://qa_v29/final_motion/%03d.png" % shot)
		shot += 1

func _run() -> void:
	root.size = Vector2i(960, 640)
	root.content_scale_size = Vector2i(960, 640)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_v29/final_motion"))
	var scene: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(scene)
	scene.get_node("Crates").queue_free()
	scene.get_node("ParallaxForeground").hide()
	player = scene.get_node("Robot")
	camera = scene.get_node("Camera2D")
	camera.set("target", null)
	camera.zoom = Vector2(3, 3)
	camera.limit_left = -100000
	camera.limit_top = -100000
	camera.limit_right = 100000
	camera.limit_bottom = 100000
	await _frames(20)
	player.global_position = Vector2(1200, 830)
	await _frames(25)
	await _capture_frames(15)
	_key(KEY_SPACE, true)
	await _capture_frames(11)
	_key(KEY_SPACE, false)
	await _capture_frames(19)
	var ladder: Area2D = scene.get_node("Ladders/LadderCentral")
	player.global_position = Vector2(ladder.climb_x, 830)
	player.set("velocity", Vector2.ZERO)
	await _frames(20)
	_key(KEY_W, true)
	await _frames(35)
	await _capture_frames(40)
	_key(KEY_W, false)
	await _capture_frames(15)
	print("FINAL_EXHAUST_MOTION frames=", shot)
	quit()
