extends SceneTree
var level:Node3D
var actor:CharacterBody3D
var meshes:Array[MeshInstance3D]=[]
var report:Dictionary={"tests":[]}
func _initialize()->void:call_deferred("run")
func run()->void:
	DisplayServer.window_set_size(Vector2i(1920,1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	OS.low_processor_usage_mode=false
	level=load("res://scenes/miko8_tutorial.tscn").instantiate()
	root.add_child(level)
	actor=level.actor
	actor.reset_actor()
	actor.position=Vector3(8,0.02,0)
	level.phase=2
	for child in actor.model.find_children("*","MeshInstance3D",true,false):meshes.append(child)
	await create_timer(3.0).timeout
	report["window"]=str(DisplayServer.window_get_size())
	report["render_target"]=str(root.get_texture().get_size())
	report["viewport"]=str(root.get_visible_rect().size)
	report["refresh_hz"]=DisplayServer.screen_get_refresh_rate()
	report["adapter"]=RenderingServer.get_video_adapter_name()
	report["mesh_data"]=[]
	for mesh in meshes:
		var triangles:=0
		for i in range(mesh.mesh.get_surface_count()):triangles+=mesh.mesh.surface_get_array_index_len(i)/3
		var properties:Array=[]
		for property:Dictionary in mesh.mesh.get_property_list():
			if "surface" in str(property.name):properties.append(property.name)
		report.mesh_data.append({"name":str(mesh.name),"base_triangles":triangles,"lod_bias":mesh.lod_bias,"surface_properties":properties})
	for mode:String in ["original","render_hidden","bias_025","bias_010","original_repeat"]:
		actor.model.visible=mode!="render_hidden"
		for mesh in meshes:mesh.lod_bias=0.25 if mode=="bias_025" else 0.10 if mode=="bias_010" else 1.0
		await sample(mode)
	actor.model.visible=true
	for mesh in meshes:mesh.lod_bias=1.0
	var file:=FileAccess.open("res://../Builds/Validation/MIKO8/reactions/fps_1080_baseline.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("BENCHMARK_COMPLETE ",JSON.stringify(report))
	quit()
func sample(mode:String)->void:
	level.instruction.text="1080p performance check: "+mode
	await create_timer(1.0).timeout
	var frames:Array[float]=[]
	var primitives:Array[float]=[]
	var begin:=Time.get_ticks_usec()
	var previous:=begin
	while Time.get_ticks_usec()-begin<6000000:
		await process_frame
		var now:=Time.get_ticks_usec()
		frames.append(float(now-previous)/1000.0)
		previous=now
		primitives.append(float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)))
	var duration:=float(Time.get_ticks_usec()-begin)/1000000.0
	frames.sort()
	var sum_prims:=0.0
	for value in primitives:sum_prims+=value
	var result:Dictionary={"mode":mode,"frames":frames.size(),"seconds":duration,"average_fps":frames.size()/duration,"median_ms":frames[frames.size()/2],"p95_ms":frames[int(frames.size()*0.95)],"p99_ms":frames[int(frames.size()*0.99)],"primitives_per_frame":sum_prims/primitives.size()}
	report.tests.append(result)
	print("FPS_SAMPLE ",JSON.stringify(result))
