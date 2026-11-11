extends SceneTree
func _initialize()->void:call_deferred("_run")
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	actor.set_physics_process(false)
	actor._play("Idle",0)
	var materials:Array[ShaderMaterial]=actor.polarity_control.materials
	for pole in range(3):
		for material in materials:material.set_shader_parameter("polarity",pole)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/polarity_"+str(pole)+".png")
	print("POLARITY_PREVIEW_RENDERED ",materials.size()," material; neutral/red/blue")
	quit()
