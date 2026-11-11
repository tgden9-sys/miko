extends SceneTree
# Legacy filename retained; the energy-wake trial has been removed.
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("CITY_ART_FAIL "+message)
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/CelScene/"+label+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(100)
	var actor=level.actor;var art=level.get_node("CelSceneArt")
	var suit_shader:Shader=actor.polarity_control.graphic_materials[0].shader
	check(not level.has_node("MikoEnergyWake"),"Retired energy wake must not load")
	actor.reset_actor();actor.position=Vector3(28,.02,0);level._camera(0,true);await ticks(10)
	check(art.far_paint.get_shader_parameter("art").resource_path=="res://art/cel_scene/city_far_bokeh_v1.png","New generated city must be the default")
	await capture("city_new")
	art.set_city_style(1);await ticks(3)
	check(art.far_paint.get_shader_parameter("art").resource_path=="res://art/tutorial/side_on_mockup/city_far.png","Previous city must remain available")
	await capture("city_previous");art.set_city_style(0)
	level.layered_scenery.set_brightness(.55)
	check(is_equal_approx(art.far_paint.get_shader_parameter("brightness"),.55),"City brightness must still work")
	level.layered_scenery.set_brightness(.50)
	check(actor.polarity_control.graphic_materials[0].shader==suit_shader,"Keep MIKO shader unchanged")
	print("CITY_ART_","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(failures)
