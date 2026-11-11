extends SceneTree
var level:Node3D
var report:Dictionary={"tests":[]}
var running:=false
func _initialize()->void:call_deferred("run")
func _process(_delta:float)->bool:
	if running and level and level.actor.position.x>13:
		level.actor.position.x=2
		level.previous_x=2
		level._camera(0,true)
	return false
func run()->void:
	DisplayServer.window_set_size(Vector2i(1920,1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	OS.low_processor_usage_mode=false
	var final_pass:bool="--final" in OS.get_cmdline_user_args()
	var variants:Array=["original","optimized"] if final_pass else ["original","optimized","original_repeat","optimized_repeat"]
	for variant:String in variants:
		level=load("res://scenes/miko8_tutorial.tscn").instantiate()
		level.use_game_lod=variant.begins_with("optimized")
		root.add_child(level)
		level.actor.reset_actor()
		level.actor.position=Vector3(8,0.02,0)
		level.previous_x=8
		level._camera(0,true)
		await create_timer(20 if final_pass else 5).timeout
		if variant in ["original","optimized"]:
			for pose:String in ["Idle","Run","JumpAir","GroundSitIdle"]:
				level.actor.set_physics_process(false)
				level.actor.head_offset.active=pose!="GroundSitIdle"
				level.actor._play(pose,0)
				level.actor.animation_player.seek(level.actor._duration(pose)*0.4,true)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/reactions/lod_"+variant+"_"+pose+".png")
			level.actor.head_offset.active=true
			level.actor.set_physics_process(true)
			level.actor.reset_actor()
			level.actor.position=Vector3(8,0.02,0)
		await sample(variant+"_idle")
		Input.action_press("miko8_right",0.65)
		running=true
		await create_timer(2).timeout
		await sample(variant+"_running")
		running=false
		Input.action_release("miko8_right")
		report["adapter"]=RenderingServer.get_video_adapter_name()
		report["window"]=str(DisplayServer.window_get_size())
		report["render_target"]=str(root.get_texture().get_size())
		level.queue_free()
		await process_frame
		await process_frame
	var file:=FileAccess.open("res://../Builds/Validation/MIKO8/reactions/fps_1080_final.json" if final_pass else "res://../Builds/Validation/MIKO8/reactions/fps_1080_lod.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("LOD_BENCHMARK_COMPLETE")
	quit()
func sample(mode:String)->void:
	await create_timer(2).timeout
	var frames:Array[float]=[]
	var primitive_sum:=0.0
	var start:=Time.get_ticks_usec()
	var previous:=start
	while Time.get_ticks_usec()-start<8000000:
		await process_frame
		var now:=Time.get_ticks_usec()
		frames.append(float(now-previous)/1000.0)
		previous=now
		primitive_sum+=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var seconds:=float(Time.get_ticks_usec()-start)/1000000.0
	frames.sort()
	var result:Dictionary={"mode":mode,"fps":frames.size()/seconds,"median_ms":frames[frames.size()/2],"p95_ms":frames[int(frames.size()*0.95)],"p99_ms":frames[int(frames.size()*0.99)],"primitives_per_frame":primitive_sum/frames.size()}
	report.tests.append(result)
	print("LOD_FPS ",JSON.stringify(result))
