extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_tutorial.tscn").instantiate()
	root.add_child(level)
	await create_timer(2.5).timeout
	var presence=level.scene_presence
	presence.set_process(false)
	print("AIR_INSTANCE ",presence.air.get_instance_transform(0)," color=",presence.air.get_instance_color(0))
	for debug:bool in [true,false]:
		presence.air.mesh.material.set_shader_parameter("debug_view",debug)
		for i in range(presence.motes.size()):
			var mote:Dictionary=presence.motes[i]
			presence.air.set_instance_transform(i,Transform3D(level.camera.global_basis.scaled(Vector3.ONE*0.18),mote.p))
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/art_revision/air_probe_"+str(debug)+".png")
	quit()
