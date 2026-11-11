extends "res://tests/verify_level4_route.gd"
## Isolated failure/recovery checks complement the continuous combat route.
func run() -> void:
	geometry = true
	change_scene_to_file("res://scenes/miko7_patrol_yard.tscn")
	await scene_changed
	level = current_scene
	actor = level.actor
	level.elapsed = 10.0
	actor.reset_actor()
	actor.position = Vector3(2.4, .02, 0)
	# Simulate every patrol for six seconds, including off-camera guards.
	var samples: Dictionary = {}
	for guard in get_nodes_in_group("level4_wardens"):
		guard.set_meta("budget_always_simulate", true)
		samples[guard.name] = [guard.position.x, guard.position.x]
	for i in range(360):
		await tick()
		for guard in get_nodes_in_group("level4_wardens"):
			samples[guard.name][0] = minf(samples[guard.name][0], guard.position.x)
			samples[guard.name][1] = maxf(samples[guard.name][1], guard.position.x)
	for guard in get_nodes_in_group("level4_wardens"):
		check(guard.is_on_floor() and absf(guard.position.y - guard.home.y) < .04, str(guard.name) + " grounded")
		check(guard.position.x >= guard.patrol_left and guard.position.x <= guard.patrol_right, str(guard.name) + " within safe patrol")
		check(samples[guard.name][1] - samples[guard.name][0] > .8, str(guard.name) + " patrol moves")
	# Fire a real continuous stream down the first roof. The shutter, rather
	# than enemy immunity, prevents damage before entering the encounter.
	actor.reset_actor()
	actor.position = Vector3(29.0, 3.02, 0)
	await ticks(10)
	Input.action_press("miko8_quick_blaster")
	await ticks(120)
	Input.action_release("miko8_quick_blaster")
	var screened: Node = level.get_node("SwitchWarden")
	check(screened.health == screened.MAX_HEALTH, "roof shutter blocks ranged player fire")
	check(screened.shots_fired == 0, "roof shutter blocks warden sight and fire")
	if not await move_to(32.1): return
	check(level.tutorial_course.approach_shutters[0].opened, "shutter opens before the roof gap")
	for guard in get_nodes_in_group("level4_wardens"):
		guard.restore_defeated()
	await ticks(120)
	# Intentionally walk into each gap, land on its floor, and climb onward.
	for data: Array in [[33.7,3.0,34.8,"SwitchRoofWestAccess"], [66.7,3.0,67.8,"FreightMiddleWestAccess"], [76.7,3.0,77.8,"FreightEastWestAccess"], [134.7,3.8,135.8,"DispatchEastWestAccess"], [163.7,3.0,164.8,"RelayEastWestAccess"]]:
		actor.reset_actor()
		actor.position = Vector3(data[0], data[1] + .02, 0)
		await ticks(8)
		if not await move_to(data[2], .35): return
		if not await until(func(): return actor.is_on_floor() and actor.position.y < .1, "missed gap lands safely", 180): return
		if not await ladder(data[3]): return
	# Both side accesses on every solid roof: descend to ground, remount,
	# return to roof. This includes the narrow service slots between roofs.
	for roof: Array in level.tutorial_course.ROOFS:
		for side: String in ["WestAccess", "EastAccess"]:
			var access: Node3D = level.tutorial_course.get_node(roof[0] + side)
			actor.reset_actor()
			actor.position = access.top_entry_position() + Vector3.UP * .02
			await ticks(8)
			if not await ladder(roof[0] + side, false): return
			if not await ladder(roof[0] + side, true): return
	# Checkpoints: reset after death, retain earlier defeats, restore later
	# opponents to their original roof height, reset gates and power cell.
	for index in range(2):
		var course: Node3D = level.tutorial_course
		course.checkpoint_index = index - 1
		course.activate_checkpoint()
		var future: Node = level.get_node("RelayWarden")
		course.saved_defeats.erase(future.name)
		future.position.y = -8.0
		course.canister.is_collected = true
		actor.reactions.die()
		if index == 0:
			await level._restart(false)
		else:
			# Exercise the real death timer as well as the manual reset path.
			await ticks(210)
		await ticks(20)
		check(actor.health == 100 and actor.is_on_floor() and absf(actor.position.x - course.CHECKPOINTS[index]) < .1, "checkpoint %d respawn" % (index + 1))
		check(level.get_node("GateWarden").health == 0, "earlier defeats retained")
		check(future.health == future.MAX_HEALTH and absf(future.position.y - future.home.y) < .05, "later warden restores original height")
		check(not course.canister.is_collected, "power cell reset")
		check(not course.locks[1].gate.opened, "final lock restored")
		future.restore_defeated()
	print("LEVEL4_SAFETY_RESULT failures=", failures)
	quit(failures)
