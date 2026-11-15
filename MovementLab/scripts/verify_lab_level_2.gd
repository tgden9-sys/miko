extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print("PASS " if ok else "FAIL ",message)
	if not ok: failures += 1
func run() -> void:
	var level = load("res://lab_level_2.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var actor = level.actor
	actor.automation = true
	for i in range(20): await physics_frame
	check(level.dummy == null and level.extra_droids.is_empty() and level.wave_droids.is_empty(),"Level 2 has no droids")
	check(get_nodes_in_group("miko8_charge_targets").is_empty(),"Level 2 has no charge blocks")
	var starting_fov: float = level.camera.fov
	Input.action_press("zoom")
	await process_frame
	await process_frame
	Input.action_release("zoom")
	check(not level.zoomed and is_equal_approx(level.camera.fov,starting_fov),"Close view input leaves Level 2 at normal scale")
	var steady_fov := true
	# Drive the real controller over every rise, return, puzzle gap and descent.
	var route := [
		Vector3(30,0,0), Vector3(34,2,0), Vector3(39,4,0), Vector3(32,6,0),
		Vector3(27,6,0), Vector3(21,6,0), Vector3(15,6,0), Vector3(10,8,0),
		Vector3(5,10,0), Vector3(12,12,0), Vector3(29,12,0), Vector3(35,12,0),
		Vector3(48,12,0), Vector3(55,9,0), Vector3(60,6,0), Vector3(65,3,0),
		Vector3(70,0,0), Vector3(76,2,0), Vector3(81,4,0), Vector3(84,4,0),
		Vector3(90,4,0), Vector3(94,4,0), Vector3(98.5,2,0), Vector3(104,0,0),
		Vector3(117,0,0), Vector3(121,2,0), Vector3(126,4,0), Vector3(119,6,0),
		Vector3(105,6,0),
	]
	for target in route:
		var reached := false
		var jumped := false
		var doubled := false
		var origin: Vector3 = actor.position
		for tick in range(240):
			var dx: float = target.x-actor.position.x
			actor.command_axis = signf(dx) if absf(dx) > .18 else 0.0
			actor.command_held = true
			var needs_jump: bool = target.y > origin.y+.5 or (absf(target.y-origin.y)<.5 and ((origin.x < 24 and target.x > 24) or (origin.x > 24 and target.x < 24) or (origin.x < 32 and target.x > 32 and target.y>11) or (origin.x < 87 and target.x > 87)))
			if not jumped and actor.is_on_floor() and needs_jump:
				actor.buffers.jump = .14
				jumped = true
			elif jumped and not doubled and actor.velocity.y < .7 and not actor.is_on_floor():
				actor.buffers.jump = .14
				doubled = true
			await physics_frame
			steady_fov = steady_fov and is_equal_approx(level.camera.fov,starting_fov)
			if absf(dx)<.45 and absf(actor.position.y-target.y)<.15 and actor.is_on_floor():
				reached = true
				break
		check(reached,"route %s -> %s (actual %s)" % [origin,target,actor.position])
		if not reached: break
	check(steady_fov,"Level 2 camera scale stays fixed across the full route")
	actor.command_axis = 0
	for i in range(3): await physics_frame
	check(level.completed,"Outbound relay completes level")
	check(level.route_checkpoint == level.STOPS.size()-1,"Final mezzanine checkpoint reached")
	level.reset_room()
	check(actor.position.distance_to(level.STOPS.back()) < .1,"Reset returns to final checkpoint")
	level.queue_free()
	await process_frame
	var first = load("res://lab_run.tscn").instantiate()
	root.add_child(first)
	current_scene = first
	first.actor.automation = true
	first.actor.position = Vector3(90,.04,0)
	# Keep combat out of this isolated scene-transition test.
	first.wave_spawn_total = 8
	first.wave_active = true
	for d in first.extra_droids: d.set_physics_process(false)
	first.dummy.set_physics_process(false)
	for tick in range(160):
		await physics_frame
		if current_scene != first: break
	check(current_scene != first and current_scene.scene_file_path == "res://lab_level_2.tscn","Level 1 relay changes scene to Level 2")
	print("LEVEL2_VERIFICATION failures=",failures)
	quit(1 if failures else 0)


