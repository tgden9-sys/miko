extends SceneTree
func _initialize() -> void: call_deferred("run")
func sample(label: String) -> void:
	await create_timer(1.5).timeout
	var before := Time.get_ticks_usec()
	var end := before + 3000000
	var frames: Array[float] = []
	while Time.get_ticks_usec() < end:
		await process_frame
		var now := Time.get_ticks_usec()
		frames.append((now - before) / 1000.0)
		before = now
	frames.sort()
	print("LEVEL4_PERF ", label, " fps=", frames.size() / 3.0, " p95_ms=", frames[int(frames.size() * .95)], " draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), " physics_ms=", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)

func run() -> void:
	OS.low_processor_usage_mode = false
	for data: Array in [["res://scenes/miko8_level_03.tscn",32.,0.], ["res://scenes/miko7_patrol_yard.tscn",32.,3.], ["res://scenes/miko7_patrol_yard.tscn",132.,3.8]]:
		change_scene_to_file(data[0])
		await scene_changed
		var level: Node3D = current_scene
		level.elapsed = 10.0
		if level.tutorial_director:
			level.tutorial_director.next_lesson = level.tutorial_director.lessons.size()
		level.actor.reset_actor()
		level.actor.position = Vector3(data[1], data[2] + .02, 0)
		level.actor.ready_for_input = false
		level._camera(0.0, true)
		await sample("level=%d x=%d" % [level.level_index, int(data[1])])
	quit()
