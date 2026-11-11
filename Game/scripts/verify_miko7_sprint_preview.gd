extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _capture(label: String) -> void:
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://../Builds/Validation/MIKO7/godot/" + label + ".png"
	assert(root.get_texture().get_image().save_png(path) == OK)
	print("CAPTURED ", path)

func _run() -> void:
	var scene: Control = load("res://scenes/miko7_sprint_preview.tscn").instantiate()
	root.add_child(scene)
	for i in range(8):
		await process_frame
	assert(scene.ready_for_review)
	assert(scene.animation.length > 0.59 and scene.animation.length < 0.7)
	var sprint_count := 0
	for name: StringName in scene.player.get_animation_list():
		if String(name).to_lower().contains("sprint"):
			sprint_count += 1
	assert(sprint_count == 1)
	scene.paused = true
	scene._apply_speed()
	var skeleton: Skeleton3D = scene.stage.find_children("*", "Skeleton3D", true, false)[0]
	var bone := skeleton.find_bone("DEF-shin.L")
	assert(bone >= 0)
	scene.player.seek(0.0, true)
	await _capture("side_frame_01")
	var initial_pose := skeleton.get_bone_global_pose(bone)
	scene.player.seek(2.0 / 30.0, true)
	await _capture("side_frame_03")
	var next_pose := skeleton.get_bone_global_pose(bone)
	assert(not initial_pose.is_equal_approx(next_pose))
	scene.player.seek(scene.animation.length, true)
	for i in range(3):
		await process_frame
	assert(initial_pose.is_equal_approx(skeleton.get_bone_global_pose(bone)))
	scene._set_angle("Three-quarter")
	scene.player.seek(10.0 / 30.0, true)
	await _capture("three_quarter")
	scene._toggle_scale()
	await _capture("game_scale")
	assert(scene.camera.size > 2.0)
	scene._toggle_scale()
	scene._set_angle("Side")
	scene.player.seek(0.0, true)
	scene._step(1)
	assert(abs(scene.player.current_animation_position - 1.0 / 30.0) < 0.001)
	scene._toggle_pause()
	assert(not scene.paused and scene.player.speed_scale > 0)
	print("MIKO7_GODOT_CHECK_PASSED duration=", scene.animation.length, " bones=", skeleton.get_bone_count())
	quit()
