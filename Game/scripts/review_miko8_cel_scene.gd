extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func capture(name:String)->void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/CelScene/"+name+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(130)
	var far_paint:ShaderMaterial=level.layered_scenery.city_card.material_override
	var far:Texture2D=far_paint.get_shader_parameter("art")
	if far.resource_path!="res://art/cel_scene/city_far_bokeh_v1.png":failures+=1;push_error("New cel city not selected")
	level.layered_scenery.set_brightness(.55)
	if not is_equal_approx(far_paint.get_shader_parameter("brightness"),.55):failures+=1;push_error("Bokeh brightness control failed")
	level.layered_scenery.set_brightness(.50)
	for spot:Dictionary in [{"name":"start","x":5.5},{"name":"ladder","x":18.08},{"name":"courtyard","x":38.0},{"name":"workshop","x":52.0}]:
		level.actor.reset_actor();level.actor.position=Vector3(spot.x,.02,0);level._camera(0,true);await ticks(20);await capture(spot.name)
	var actor=level.actor;actor.reset_actor();actor.position=Vector3(18.08,.02,0);await ticks(5)
	Input.action_press("miko8_up");await ticks(410);Input.action_release("miko8_up");await ticks(30)
	if not actor.is_on_floor() or actor.position.y<2.7:failures+=1;push_error("Cel ladder ascent failed")
	await capture("roof")
	Input.action_press("miko8_down");await ticks(410);Input.action_release("miko8_down");await ticks(30)
	if not actor.is_on_floor() or actor.position.y>.1:failures+=1;push_error("Cel ladder descent failed")
	for target in get_nodes_in_group("miko8_charge_targets"):
		if target.has_method("lock_in_color"):
			target.lock_in_color(Color.RED)
			if target.polarity!=1:failures+=1;push_error("Cel target red failed")
			target.lock_in_color(Color.BLUE)
			if target.polarity!=2:failures+=1;push_error("Cel target blue failed")
			target.neutralize()
			if target.polarity!=0:failures+=1;push_error("Cel target reset failed")
	print("CEL_SCENE_REVIEW failures=",failures," converted=",level.get_node("CelSceneArt").converted," far=",far.resource_path)
	quit(failures)
