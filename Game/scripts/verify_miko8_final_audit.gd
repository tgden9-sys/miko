extends SceneTree
func _initialize()->void:call_deferred("_run")
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	actor.set_physics_process(false)
	level.paused=true
	var ui:=CanvasLayer.new()
	root.add_child(ui)
	var caption:=Label.new()
	caption.position=Vector2(455,710)
	caption.add_theme_font_size_override("font_size",24)
	ui.add_child(caption)
	var atlas:=Image.create(1320,ceili(actor.clips.size()/6.0)*300,false,Image.FORMAT_RGB8)
	atlas.fill(Color("13191f"))
	var count:=0
	for clip:String in actor.clips:
		actor._state("Clip review")
		actor.current_clip=""
		actor._play(clip,0)
		for phase in [0.0,0.25,0.5,0.75,0.99]:
			actor.animation_player.seek(actor._duration(clip)*phase,true)
			await process_frame
			await RenderingServer.frame_post_draw
			for bone in range(actor.skeleton.get_bone_count()):assert(actor.skeleton.get_bone_global_pose(bone).is_finite(),clip)
		caption.text=clip
		actor.animation_player.seek(actor._duration(clip)*0.4,true)
		await process_frame
		await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image()
		var tile:=image.get_region(Rect2i(435,80,450,700))
		tile.resize(220,300,Image.INTERPOLATE_LANCZOS)
		tile.convert(Image.FORMAT_RGB8)
		atlas.blit_rect(tile,Rect2i(0,0,220,300),Vector2i((count%6)*220,(count/6)*300))
		count+=1
	atlas.save_png("res://../Builds/Validation/MIKO8/ladder_candidates/all_animation_audit.png")
	actor.reset_actor()
	actor.set_physics_process(true)
	await process_frame
	# stale left/down aim must not steer a new right-facing plasma entry.
	actor.abilities.aim_engaged=true
	actor.abilities.aim_facing=-1
	actor.abilities.aim_elevation=-0.7
	actor.abilities.target_aim_elevation=-0.7
	actor.facing=1
	Input.action_press("miko8_spell_double")
	for i in range(3):await physics_frame
	assert(actor.abilities.laser_mode=="Plasma")
	assert(actor.abilities.aim_facing==1 and absf(actor.abilities.aim_elevation)<0.001)
	Input.action_release("miko8_spell_double")
	var clear:=PhysicsRayQueryParameters3D.create(Vector3(18.29,3.5,-0.33),Vector3(18.29,2.9,-0.33),1)
	assert(actor.get_world_3d().direct_space_state.intersect_ray(clear).is_empty(),"Platform still intersects ladder rail clearance")
	print("ALL_ANIMATION_AUDIT_PASS ",count," clips, five sampled phases each; plasma entry centred; platform clears rails")
	quit()

