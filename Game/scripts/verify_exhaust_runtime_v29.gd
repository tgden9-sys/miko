extends SceneTree

var failures: Array[String] = []
var player: Node2D
var camera: Camera2D

func _initialize() -> void:
	call_deferred("_run")

func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		if is_instance_valid(player):
			var exhaust: Node2D = player.get_node_or_null("ProceduralExhaust")
			_check(exhaust != null and exhaust.visible, "Missing nozzle attachment")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _capture(name: String) -> void:
	camera.global_position = player.global_position + Vector2(0, -25)
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	var result: Error = image.save_png("res://qa_v29/runtime/" + name + ".png")
	_check(result == OK, "Could not save " + name)
	print("CAPTURE ", name)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_v29/runtime"))
	var packed: PackedScene = load("res://scenes/industrial_city.tscn")
	var scene: Node2D = packed.instantiate()
	root.add_child(scene)
	# Keep the animation inspection corridor clear. The original city scene and
	# magnetic crates remain unchanged; this harness isolates character motion.
	var crates: Node = scene.get_node_or_null("Crates")
	if crates: crates.queue_free()
	player = scene.get_node("Robot")
	camera = scene.get_node("Camera2D")
	camera.set("target", null)
	camera.zoom = Vector2(2.5, 2.5)
	var foreground: Node = scene.get_node_or_null("ParallaxForeground")
	if foreground: foreground.set("visible", false)
	await _frames(30)
	player.global_position = Vector2(1200, 830)
	player.set("velocity", Vector2.ZERO)
	await _frames(25)
	await _capture("01_idle_right")
	_key(KEY_Q, true)
	await _frames(30)
	_check(player.get_node("ArmLPivot/Forearm").visible, "Red laser forearm missing")
	_check(player.get_node("AimBeam").visible, "Red laser beam missing")
	await _capture("02_red_right")
	_key(KEY_Q, false)
	_key(KEY_E, true)
	await _frames(8)
	await _capture("03_swap_right")
	await _frames(22)
	_check(player.get_node("ArmRPivot/Forearm").visible, "Blue laser forearm missing")
	await _capture("04_blue_right")
	player.set("aim_angle_degrees", 55.0)
	await _frames(3)
	await _capture("05_blue_up")
	player.set("aim_angle_degrees", 0.0)
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(-200, 0)
	Input.parse_input_event(mouse)
	await _frames(35)
	_check(player.get("visual_facing") == -1, "Aiming turn did not finish left")
	_check(player.get_node("BodyLayer").animation == &"body_blue_turn", "Blue aim lacks matching torso turn")
	await _capture("06_blue_left")
	var before: float = player.position.x
	_key(KEY_A, true)
	await _frames(18)
	_key(KEY_A, false)
	print("AIM_MOVE_DISPLACEMENT ", player.position.x - before)
	_check(player.position.x < before - 40.0, "Movement while aiming failed")
	await _capture("07_blue_left_moving")
	_key(KEY_E, false)
	_key(KEY_Q, true)
	await _frames(6)
	await _capture("08_swap_left_early")
	await _frames(6)
	await _capture("09_swap_left_middle")
	await _frames(18)
	await _capture("10_red_left")
	_key(KEY_Q, false)
	await _frames(28)
	var grounded_y: float = player.position.y
	_key(KEY_SPACE, true)
	await _frames(8)
	_check(player.position.y < grounded_y - 35.0, "Jump did not leave the ground")
	_key(KEY_Q, true)
	await _frames(12)
	_check(player.position.y < grounded_y - 50.0, "Airborne aim did not stay airborne")
	_check(player.get_node("ArmLPivot/Forearm").visible, "Aiming arm disappeared in jump")
	print("AIRBORNE_AIM height=", grounded_y - player.position.y, " velocity=", player.get("velocity"))
	await _capture("11_jump_aim")
	_key(KEY_SPACE, false)
	_key(KEY_Q, false)
	await _frames(100)
	_key(KEY_F, true)
	await _frames(30)
	_check(player.get("plasma_progress") > 0.9, "Both-arm plasma raise failed")
	await _capture("12_plasma_left")
	var children_before: int = scene.get_child_count()
	_key(KEY_F, false)
	await _frames(2)
	_check(scene.get_child_count() > children_before, "Release did not spawn plasma projectile")
	await _capture("13_plasma_release")
	await _frames(45)
	var ladder: Area2D = scene.get_node("Ladders/LadderCentral")
	player.global_position = Vector2(ladder.get("climb_x"), 830)
	player.set("velocity", Vector2.ZERO)
	await _frames(25)
	_key(KEY_W, true)
	await _frames(50)
	_check(player.get("ladder_state") != 0, "Ladder mount or climb failed")
	await _capture("14_ladder_climbing_exhaust")
	_check(player.get_node("ProceduralExhaust").get("output") > 0.75, "Ladder boost is too weak")
	_key(KEY_W, false)
	await _frames(5)
	await _capture("15_ladder_hold")
	_key(KEY_SPACE, true)
	await _frames(4)
	_check(player.get("ladder_state") == 0, "Ladder jump-off failed")
	await _capture("16_ladder_jump")
	_key(KEY_SPACE, false)
	print("NECKERCHIEF_V28_RUNTIME_CHECK ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures)
	quit(0 if failures.is_empty() else 1)
