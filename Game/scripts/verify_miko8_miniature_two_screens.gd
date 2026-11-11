extends SceneTree
## Run with --script and optionally -- --capture-dir=<absolute directory>.
## Rendered captures need an ordinary OpenGL renderer, not --headless.
const TWO_SCREEN_LEVEL = preload("res://scripts/miko8_miniature_two_screens.gd")
var failures := 0
var capture_dir := ""

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("MINIATURE_TWO_SCREENS_FAIL: " + message)

func ticks(count: int) -> void:
	for frame in range(count):
		await physics_frame

func capture(label: String) -> void:
	if capture_dir.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(capture_dir.path_join(label + ".png"))
	check(result == OK, "Could not save capture: " + label)

func run() -> void:
	var scene := load("res://scenes/miko8_miniature_two_screens.tscn") as PackedScene
	var level: TWO_SCREEN_LEVEL = scene.instantiate() as TWO_SCREEN_LEVEL
	root.add_child(level)
	await create_timer(2.0).timeout
	var actor: CharacterBody3D = level.actor
	var camera: Camera3D = level.camera
	var screen_width: float = level.SCREEN_WIDTH
	var total_width: float = level.TOTAL_WIDTH
	var viewport_height: float = root.get_visible_rect().size.y
	check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Camera must remain orthographic")
	check(absf(total_width - 53.333333) < 0.001, "The level must span two 26.6667m screens")
	check(absf(11.25 / camera.size - 0.75) < 0.001, "MIKO projection must remain 25% smaller")
	check(absf(camera.unproject_position(Vector3(screen_width / 2.0, 0, 0)).y / viewport_height - 2.0 / 3.0) < 0.001, "Physical feet must stay at 720/1080")
	check(level.has_node("InvisibleGameplayFloor") and not level.has_node("PaintedGroundKit"), "Only the invisible continuous floor should provide ground")
	var floor_body := level.get_node("InvisibleGameplayFloor") as StaticBody3D
	var floor_collision := floor_body.get_child(0) as CollisionShape3D
	var floor_shape := floor_collision.shape as BoxShape3D
	check(absf(floor_shape.size.x - total_width) < 0.001, "Floor collision must cover the complete two-screen span")
	check(absf(floor_body.position.x - total_width / 2.0) < 0.001, "Continuous floor must be centred on both screens")
	var crate := level.get_node("TutorialChargeCrate") as RigidBody3D
	check(absf(crate.position.x - 40.0) < 0.001, "The crate must be on the second screen at 40m")
	var stage_a: MeshInstance3D = level.stage
	var stage_b: MeshInstance3D = level.stage_b
	var anchor_a := stage_a.global_transform
	var anchor_b := stage_b.global_transform
	check(absf((anchor_b.origin - anchor_a.origin).x - screen_width) < 0.001, "Stage cards must meet at one screen width")
	var stage_top := camera.unproject_position(stage_a.to_global(Vector3(0, level.SCENE_HEIGHT / 2.0, 0)))
	check(absf(stage_top.y / viewport_height + level.ART_FOOT_ROW - 2.0 / 3.0) < 0.001, "Painted floor must align with the physical floor")
	check(actor.is_on_floor() and actor.state.begins_with("GroundSit"), "MIKO must start seated on the physical floor")
	check(absf(camera.position.x - screen_width / 2.0) < 0.001, "Initial camera must show the complete first screen")
	await capture("two_screens_first")
	actor.reset_actor()
	actor.position = Vector3(screen_width, 0.02, 0)
	var expected_eased_x := lerpf(screen_width / 2.0, screen_width + level.CAMERA_LOOK_AHEAD, 1.0 - exp(-level.CAMERA_FOLLOW_RATE * 0.1))
	level._camera(0.1)
	check(absf(camera.position.x - expected_eased_x) < 0.001, "Camera must ease toward its lookahead target")
	level._camera(0, true)
	await ticks(5)
	check(absf(camera.position.x - screen_width - level.CAMERA_LOOK_AHEAD) < 0.001, "Middle camera must follow with 3m lookahead")
	check(stage_a.global_transform.is_equal_approx(anchor_a) and stage_b.global_transform.is_equal_approx(anchor_b), "Stage cards must remain fixed as the camera crosses the join")
	await capture("two_screens_join")
	actor.reset_actor()
	actor.position = Vector3(total_width - 1.0, 0.02, 0)
	level._camera(0, true)
	await ticks(5)
	check(absf(camera.position.x - (total_width - screen_width / 2.0)) < 0.001, "End camera must clamp to the second screen")
	check(stage_a.global_transform.is_equal_approx(anchor_a) and stage_b.global_transform.is_equal_approx(anchor_b), "End camera must not relocate either stage card")
	var city: MeshInstance3D = level.city
	var expected_city_x: float = level.city_anchor.origin.x + (camera.position.x - screen_width / 2.0) * 0.85
	check(absf(city.global_position.x - expected_city_x) < 0.001, "City must have 15% natural parallax")
	await capture("two_screens_end")
	# Walk through the same collision surface in both directions without jumping.
	for direction: float in [1.0, -1.0]:
		actor.reset_actor()
		actor.position = Vector3(screen_width - direction * 1.2, 0.02, 0)
		await ticks(5)
		var action := "miko8_right" if direction > 0 else "miko8_left"
		Input.action_press(action, 0.35)
		var crossed := false
		var stayed_grounded := true
		for frame in range(480):
			await physics_frame
			stayed_grounded = stayed_grounded and actor.position.y > -0.05 and actor.position.y < 0.1
			if (actor.position.x - screen_width) * direction > 1.0:
				crossed = true
				break
		Input.action_release(action)
		check(crossed and stayed_grounded, "MIKO must walk through the seam in direction " + str(direction))
	check(stage_a.global_transform.is_equal_approx(anchor_a) and stage_b.global_transform.is_equal_approx(anchor_b), "Walking must not change stage transforms")
	await level._restart(true)
	check(absf(actor.position.x - level.START_X) < 0.01, "Reset must restore the first-screen start")
	check(absf(camera.position.x - screen_width / 2.0) < 0.001, "Reset must restore the first-screen camera")
	check(stage_a.global_transform.is_equal_approx(anchor_a) and stage_b.global_transform.is_equal_approx(anchor_b), "Reset must preserve world stage anchors")
	if failures == 0:
		print("MINIATURE_TWO_SCREENS_PASS: 53.333m floor, 25% smaller MIKO, feet 720/1080, fixed adjoining art cards, both seam directions, camera start/middle/end, 15% city parallax")
	quit(0 if failures == 0 else 1)
