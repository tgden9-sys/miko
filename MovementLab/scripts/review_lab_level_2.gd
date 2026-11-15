extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for scene_path in ["res://lab_run.tscn","res://lab_level_2.tscn"]:
		var level = load(scene_path).instantiate()
		root.add_child(level)
		current_scene = level
		level.actor.automation = true
		for i in range(60): await process_frame
		var samples: Array[float] = []
		for i in range(180):
			var start := Time.get_ticks_usec()
			await process_frame
			samples.append((Time.get_ticks_usec()-start)/1000.0)
		samples.sort()
		print("RENDER_BENCH ",scene_path," median_ms=",samples[90]," p95_ms=",samples[171]," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		if scene_path.contains("level_2"):
			for point in [Vector3(4,0,0),Vector3(30,0,0),Vector3(5,10,0),Vector3(12,12,0),Vector3(48,12,0),Vector3(60,6,0),Vector3(72,0,0),Vector3(76,2,0),Vector3(82,4,0),Vector3(98.5,2,0),Vector3(107,0,0),Vector3(126,4,0),Vector3(105,6,0)]:
				level.actor.position = point
				level.actor.velocity = Vector3.ZERO
				level.actor.set_physics_process(false)
				level._update_camera(10.0)
				for i in range(8): await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("C:/Users/tgden/Desktop/MIKO/Builds/relay-polish-%d-%d.png" % [int(point.x),int(point.y)])
		level.queue_free()
		await process_frame
	quit()

