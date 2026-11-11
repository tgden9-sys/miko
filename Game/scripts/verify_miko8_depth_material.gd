extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_tutorial.tscn").instantiate()
	root.add_child(level)
	await create_timer(2).timeout
	var far=level.parallax[1].node.get_child(0)
	print("FAR_MATERIAL ",far.material_override," mist=",far.material_override.get_shader_parameter("mist"))
	far.material_override.set_shader_parameter("mist",1.0)
	far.material_override.set_shader_parameter("mist_color",Color(1,0,0))
	level.parallax[2].node.visible=false
	level.parallax[3].node.visible=false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/art_revision/depth_material_probe.png")
	quit()
