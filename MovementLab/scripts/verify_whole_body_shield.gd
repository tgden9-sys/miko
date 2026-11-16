extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String, detail: Variant = null) -> void:
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		print("FAIL: ", message, " | Detail: ", detail)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	print("--- STARTING WHOLE BODY SHIELD VERIFICATION ---")
	var lab = load("res://lab_cutaway.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	var actor = lab.actor
	actor.automation = true
	await frames(10)

	check(actor.electric_shield_enabled, "Electric shield is enabled in cutaway lab")
	check(actor.electric_guard != null, "Electric guard instance exists")

	# 1. Test Shield Activation & Placement
	actor.automation = false # allow Input actions
	Input.action_press("shield")
	await frames(5)

	check(actor.state == "shield", "Actor enters 'shield' state on shield press", actor.state)
	check(actor.electric_guard.visible, "Shield visual is visible when active")
	check(actor.electric_guard.blocks_bolts, "Shield blocks bolts when active")
	check(is_equal_approx(actor.electric_guard.position.x, 0.0), "Shield is centered on X (whole-body), not offset", actor.electric_guard.position)
	check(actor.electric_guard.position.y > 0.8, "Shield is centered vertically around torso", actor.electric_guard.position)

	# 2. Test Stance unaffected (Locomotion & Idle)
	check(actor.pose_name.ends_with("SwordIdle") or actor.pose_name == "", "Actor preserves normal idle pose while shielded", actor.pose_name)

	# Test movement under shield
	actor.command_axis = 1.0
	# Simulate axis input in InputMap
	Input.action_press("right")
	await frames(15)
	check(actor.velocity.x > 3.0, "Actor runs at normal SPEED while shielded, not clamped to walk", actor.velocity.x)
	check(not actor.pose_name.ends_with("ShieldWalk"), "Actor does NOT use ShieldWalk; uses normal run/sprint locomotion", actor.pose_name)
	Input.action_release("right")
	actor.command_axis = 0.0
	await frames(15)

	# 3. Test Attack cancels shield
	Input.action_press("attack")
	await frames(3)
	Input.action_release("attack")
	check(actor.state == "attack", "Attacking immediately cancels shield and enters 'attack'", actor.state)
	check(not actor.electric_guard.visible, "Shield disappears immediately upon attack")
	await frames(25) # wait for attack to finish

	# 4. Test Jump cancels shield
	Input.action_press("shield")
	await frames(5)
	check(actor.state == "shield", "Shield re-engages when standing")
	Input.action_press("jump")
	await frames(3)
	Input.action_release("jump")
	check(actor.velocity.y > 5.0, "Actor jumps upwards", actor.velocity.y)
	check(actor.state == "move", "Jump immediately cancels shield to 'move'", actor.state)
	check(not actor.electric_guard.visible, "Shield disappears immediately upon jump")

	# Wait until landed
	for i in range(60):
		await frames(1)
		if actor.is_on_floor():
			break

	# 5. Test Omnidirectional Absorption (Front and Back)
	Input.action_press("shield")
	await frames(5)
	check(actor.state == "shield", "Shield active for absorption test")
	var initial_hits = actor.shield_hits

	# Attack from behind
	var from_behind = actor.global_position.x - float(actor.facing) * 2.0
	var absorbed_back = actor._absorb_with_shield(from_behind, Vector3(from_behind, 1.0, 0.0))
	check(absorbed_back, "Shield absorbs attack from BEHIND (whole body protection)")
	check(actor.shield_hits == initial_hits - 1, "Shield hit count decremented from behind attack", actor.shield_hits)

	# Attack from front
	var from_front = actor.global_position.x + float(actor.facing) * 2.0
	var absorbed_front = actor._absorb_with_shield(from_front, Vector3(from_front, 1.0, 0.0))
	check(absorbed_front, "Shield absorbs attack from FRONT")
	check(actor.shield_hits == initial_hits - 2, "Shield hit count decremented from front attack", actor.shield_hits)

	Input.action_release("shield")
	await frames(5)
	check(not actor.electric_guard.visible, "Shield disappears when button released")

	# 6. Test 4-Second Cooldown When Shield is Depleted
	Input.action_press("shield")
	await frames(5)
	check(actor.state == "shield", "Shield active before depletion test")
	actor.shield_hits = 1
	var absorbed_last = actor._absorb_with_shield(actor.global_position.x + 1.0)
	check(absorbed_last, "Final hit absorbed by shield")
	check(actor.shield_hits == 0, "Shield hits reduced to 0 (depleted)", actor.shield_hits)
	check(actor.state == "move", "Depleted shield forces state to 'move'", actor.state)
	check(is_equal_approx(actor.shield_recharge_time, 4.0), "Depleted shield sets 4-second recharge cooldown", actor.shield_recharge_time)

	# While depleted, shield button cannot raise shield
	Input.action_press("shield")
	await frames(10)
	check(actor.state != "shield", "Cannot raise shield during depleted cooldown", actor.state)
	check(not actor.electric_guard.visible, "Shield remains invisible during cooldown")

	# Advance 3.5 seconds: should still be on cooldown
	for f in range(210): # 210 frames at 60Hz = 3.5s
		actor._update_shield_state(true, 1.0 / 60.0)
	check(actor.shield_hits == 0, "Shield still depleted at 3.5s", actor.shield_hits)
	check(actor.shield_recharge_time > 0.0 and actor.shield_recharge_time <= 0.6, "Recharge time ticking down around 0.5s remaining", actor.shield_recharge_time)

	# Advance remaining 0.6 seconds (total > 4.0s): should be fully recharged
	for f in range(40): # 40 frames at 60Hz = 0.66s
		actor._update_shield_state(true, 1.0 / 60.0)
	check(actor.shield_hits == actor.SHIELD_CAPACITY, "Shield fully restored to 3 hits after 4.0 seconds", actor.shield_hits)
	Input.action_release("shield")

	print("--- VERIFICATION COMPLETE: %d failures ---" % failures)
	quit(1 if failures > 0 else 0)
