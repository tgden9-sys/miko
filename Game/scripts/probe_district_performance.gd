extends SceneTree
var scene:Node3D
func _initialize()->void:call_deferred("run")
func sample(label:String)->void:
	await create_timer(2.).timeout
	var start:=Time.get_ticks_msec();var frames:=0
	while Time.get_ticks_msec()-start<2000:await process_frame;frames+=1
	print("PERF ",label," fps=",frames*.5," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," objects=",Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)," process_ms=",Performance.get_monitor(Performance.TIME_PROCESS)*1000.," physics_ms=",Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.)
func run()->void:
	DisplayServer.window_move_to_foreground();OS.low_processor_usage_mode=false
	scene=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(scene);scene.elapsed=10.;scene.actor.reset_actor();scene.actor.position=Vector3(25,.02,0)
	await sample("full")
	scene.get_node("Level2Platforms").hide();await sample("no_props")
	scene.layered_scenery.city_mid_card.hide();await sample("no_mid")
	scene.get_node("NearBuildingDistrict").hide();await sample("no_district")
	scene.free();await process_frame
	scene=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(scene);scene.elapsed=10.;scene.actor.reset_actor();scene.actor.position=Vector3(25,.02,0)
	await sample("existing_level1")
	quit()
