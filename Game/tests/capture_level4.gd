extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/miko7_patrol_yard.tscn")
	await scene_changed
	var level: Node3D = current_scene
	level.elapsed = 10.0
	level.fade.color.a = 0.0
	level.actor.reset_actor()
	for i in range(25): await physics_frame
	paused = true
	var index := 0
	for at: Vector3 in [Vector3(8,0,0), Vector3(16,0,0), Vector3(32,3,0), Vector3(52,0,0), Vector3(73,3.8,0), Vector3(101,3,0), Vector3(121,0,0), Vector3(134,3.8,0), Vector3(168,3.35,0)]:
		level.actor.position = at
		level._camera(0.0, true)
		level._prompt()
		level.visibility_budget.refresh()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/Level4Astra/view_%02d.png" % index)
		index += 1
	print("LEVEL4_CAPTURES_COMPLETE")
	quit()
