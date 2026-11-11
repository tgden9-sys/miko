extends SceneTree
## Continuous route driven by ordinary input. No teleports, health overrides,
## or movement overrides after spawn. --geometry isolates traversal from combat.
const OUT := "res://../Builds/Validation/Level4Astra/"
var level: Node3D
var actor: CharacterBody3D
var elapsed := 0.0
var failures := 0
var geometry := false
var recovery := false
var shooting := false
var rendered := false
var previous_health := 100
var combat_target: CharacterBody3D

func _initialize() -> void:
	geometry = "--geometry" in OS.get_cmdline_user_args()
	recovery = "--recovery" in OS.get_cmdline_user_args()
	rendered = DisplayServer.get_name() != "headless"
	call_deferred("run")

func tick() -> void:
	if shooting: aim_at_guard()
	await physics_frame
	elapsed += 1.0 / 60.0
	if actor.health != previous_health:
		print("HEALTH ", actor.health, " at=", actor.position, " t=", snappedf(elapsed,.01))
		previous_health = actor.health

func ticks(n: int) -> void:
	for i in range(n): await tick()

func check(ok: bool, label: String) -> bool:
	print("PASS " if ok else "FAIL ", label, " at=", actor.position if is_instance_valid(actor) else Vector3.ZERO, " t=", snappedf(elapsed,.01))
	if not ok: failures += 1
	return ok

func until(condition: Callable, label: String, limit := 900) -> bool:
	for i in range(limit):
		if condition.call(): return check(true, label)
		if actor.health <= 0:
			check(false, label + " / player died")
			await capture("failure")
			quit(1)
			return false
		await tick()
	check(false, label + " / " + actor.state)
	await capture("failure")
	quit(1)
	return false

func move_to(x: float, speed := .65) -> bool:
	var right := x > actor.position.x
	var action := "miko8_right" if right else "miko8_left"
	Input.action_press(action, speed)
	var ok := await until(func(): return actor.position.x >= x if right else actor.position.x <= x, "move %.2f" % x)
	Input.action_release(action)
	await ticks(10)
	return ok

func leap(edge: float, target: float, height: float) -> bool:
	Input.action_press("miko8_right", .65)
	if not await until(func(): return actor.position.x >= edge, "takeoff %.2f" % edge): return false
	Input.action_press("miko8_jump")
	if not await until(func(): return actor.position.x >= target, "air reaches %.2f" % target, 150): return false
	Input.action_release("miko8_right")
	Input.action_release("miko8_jump")
	return await until(func(): return actor.is_on_floor() and absf(actor.position.y - height) < .13, "land %.2f" % height, 160)

func ladder(label: String, up := true) -> bool:
	var access: Node3D = level.tutorial_course.get_node(label)
	var point: Vector3 = access.motion_origin() if up else access.top_entry_position()
	if up and point.x - actor.position.x > 1.5:
		if not await move_to(point.x - .85): return false
	if not await move_to(point.x, .35): return false
	var action := "miko8_up" if up else "miko8_down"
	Input.action_press(action)
	if not await until(func(): return actor.abilities.bpg_motion.active, "mount " + label, 140): return false
	if not await until(func(): return not actor.abilities.bpg_motion.active, "exit " + label, 700): return false
	Input.action_release(action)
	await ticks(18)
	var expected: float = access.top_y if up else access.bottom_y
	return check(actor.is_on_floor() and absf(actor.position.y - expected) < .13, "stable " + label)

func fire(on: bool) -> void:
	shooting = on and not geometry
	if shooting: Input.action_press("miko8_quick_blaster")
	else:
		Input.action_release("miko8_quick_blaster")
		for action in ["miko8_aim_left", "miko8_aim_right", "miko8_aim_up", "miko8_aim_down"]: Input.action_release(action)

func aim_at_guard() -> void:
	# A controller-stick aim, aimed at a visible nearby opponent ahead.
	for action in ["miko8_aim_left", "miko8_aim_right", "miko8_aim_up", "miko8_aim_down"]: Input.action_release(action)
	var target: CharacterBody3D
	var distance := 12.0
	for guard in get_nodes_in_group("level4_wardens"):
		var delta: Vector3 = guard.position - actor.position
		if guard.health <= 0 or delta.x * actor.facing < .1 or delta.length() > distance: continue
		target = guard
		distance = delta.length()
	if is_instance_valid(combat_target) and combat_target.health > 0: target = combat_target
	if not target: return
	var origin: Vector3 = actor.abilities._quick_origin()
	var offset: Vector3 = target.global_position + Vector3.UP * 1.05 - origin
	var direction := Vector2(offset.x, -offset.y).normalized()
	Input.action_press("miko8_aim_right" if direction.x > 0 else "miko8_aim_left", absf(direction.x))
	Input.action_press("miko8_aim_up" if direction.y < 0 else "miko8_aim_down", absf(direction.y))

func fight(label: String) -> bool:
	if geometry: return true
	var guard: CharacterBody3D = level.get_node(label)
	if guard.health <= 0: return check(true, "defeated " + label)
	combat_target = guard
	var wanted := 1 if guard.position.x > actor.position.x else -1
	if wanted != actor.facing:
		var turn_action := "miko8_right" if wanted > 0 else "miko8_left"
		Input.action_press(turn_action, .35)
		await ticks(24)
		Input.action_release(turn_action)
	fire(true)
	Input.action_press("miko8_jump")
	var ok := await until(func(): return guard.health <= 0, "defeated " + label, 280)
	Input.action_release("miko8_jump")
	fire(false)
	combat_target = null
	await ticks(20)
	return ok

func capture(label: String) -> void:
	if not rendered: return
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.save_png(OUT + label + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	change_scene_to_file("res://scenes/miko7_patrol_yard.tscn")
	await scene_changed
	level = current_scene
	actor = level.actor
	level.elapsed = 10.0
	actor.reset_actor()
	actor.position = level._restart_position()
	if geometry:
		for guard in get_nodes_in_group("level4_wardens"): guard.restore_defeated()
	await ticks(12)
	check(is_equal_approx(level.camera.size, 15.0), "normal 15 m camera")
	check(actor.GRAVITY == 14.0 and actor.JUMP_VELOCITY == 6.0, "established player physics")
	await capture("01_approach")
	if not await leap(8.65, 9.8, .8): return
	fire(true)
	if not await leap(10.0, 11.4, 1.6): return
	if not await leap(11.65, 14.0, 0.0): return
	if not await fight("GateWarden"): return
	await capture("02_inspection")
	if not await ladder("InspectionRoofWestAccess"): return
	fire(true)
	if not await leap(33.65, 35.9, 3.6): return
	if not await fight("SwitchWarden"): return
	await capture("03_rooftops")
	fire(true)
	if not await move_to(47.0): return
	if not await fight("LoadingWarden"): return
	if not await move_to(56.0): return
	check(level.tutorial_course.checkpoint_index == 0 and actor.health == 100, "first checkpoint heals")
	if not await ladder("FreightWestWestAccess"): return
	if not await leap(66.55, 68.95, 3.0): return
	fire(true)
	if not await leap(71.5, 74.2, 3.0): return
	if not await leap(76.65, 78.9, 3.6): return
	if not await fight("FreightWarden"): return
	await capture("04_freight")
	if not await move_to(91.0): return
	if not await ladder("IntakeRoofWestAccess"): return
	fire(true)
	if not await move_to(106.2): return
	if not await fight("IntakeWarden"): return
	if not await move_to(117.0): return
	Input.action_press("miko8_down")
	await ticks(30)
	if not await move_to(121.0): return
	await capture("05_cooling")
	Input.action_release("miko8_down")
	await ticks(30)
	if not await move_to(124.0): return
	check(level.tutorial_course.checkpoint_index == 1 and actor.health == 100, "second checkpoint heals")
	if not await ladder("DispatchWestWestAccess"): return
	fire(true)
	if not await move_to(127.5): return
	if not await fight("DispatchWarden"): return
	fire(true)
	if not await leap(134.55, 136.95, 4.15): return
	if not await fight("BridgeWarden"): return
	await capture("06_dispatch")
	if not await move_to(149.0): return
	if not await leap(150.0, 152.7, 0.0): return
	if not await ladder("RelayWestWestAccess"): return
	fire(true)
	if not await leap(163.55, 165.95, 3.35): return
	if not await fight("RelayWarden"): return
	await ticks(100)
	if not await move_to(175.4): return
	check(level.tutorial_course.canister.is_collected, "power cell collected")
	await capture("07_cell")
	if not await move_to(177.0): return
	await ticks(40)
	var relay: Node = level.transfer_relays[0]
	check(relay.can_activate(), "exit accessible with power cell")
	if relay.can_activate():
		var event := InputEventKey.new()
		event.physical_keycode = KEY_T
		event.pressed = true
		Input.parse_input_event(event)
		for i in range(300): await physics_frame
		check(current_scene.scene_file_path.ends_with("miko7_title_screen.tscn"), "exit transfers to safe network")
	print("LEVEL4_ROUTE_RESULT failures=", failures, " geometry=", geometry, " seconds=", snappedf(elapsed,.01))
	quit(failures)
