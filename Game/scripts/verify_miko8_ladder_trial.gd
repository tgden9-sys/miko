extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene = load("res://scenes/miko8_ladder_trial.tscn").instantiate()
	root.add_child(scene)
	scene.playing = false
	for n in ["root","DEF-spine.001","DEF-head","DEF-upper_arm.L"]:
		print("ENGINE_REST ",n," ",scene.rig.get_bone_rest(scene.rig.find_bone(n)))
	for i in range(4):
		scene.clock = float(scene.data.duration)*i/4.0
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/vanilla_phase_"+str(i)+".png")
		for n in scene.indices:
			var tr: Transform3D = scene.rig.get_bone_global_pose(scene.indices[n])
			assert(tr.is_finite(),"Nonfinite bone "+n)
		print("PHASE ",i," feet=",scene.rig.get_bone_global_pose(scene.rig.find_bone("DEF-foot.L")).origin," hand=",scene.rig.get_bone_global_pose(scene.rig.find_bone("DEF-hand.L")).origin)
	print("LADDER_TRIAL_CAPTURE_PASS")
	quit()

