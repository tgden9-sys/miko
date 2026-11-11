extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for frame in range(count):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("GENTLE_CAMERA_FAIL: "+message)
func capture(label:String)->void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/Workshop/"+label+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(150)
	var workshop=level.get_node("ServiceBlockObstacle")
	check(workshop.rotation.is_zero_approx(),"Workshop must stay aligned with the walkway")
	check(workshop.scale.is_equal_approx(Vector3.ONE*.85),"Building must retain the smaller size")
	for angle:float in [0.,6.,8.,10.]:
		level.oblique_angle_degrees=angle;level._game_size_changed(0)
		for x:float in [2.4,21.,33.,50.4,61.]:
			level.actor.reset_actor();level.actor.position=Vector3(x,.02,0);level._camera(0,true);await ticks(8)
			var focus:float=level.camera.get_meta("walkway_focus_x")
			var row:float=level.camera.unproject_position(Vector3(focus,0,0)).y/1080.
			check(absf(row-.80)<.001,"Camera yaw must preserve the floor row at its focus")
			for offset:float in [-10.,10.]:
				var edge_row:float=level.camera.unproject_position(Vector3(focus+offset,0,0)).y/1080.
				check(absf(edge_row-row)<.00001,"The entire walkway must stay horizontal on screen")
			for record:Dictionary in level.layered_scenery.flat_art:
				check(record.mesh.global_basis.is_equal_approx(Basis.IDENTITY),"Yard art must share the walkway's world orientation")
			if angle==8. or x==50.4:await capture("camera_"+str(int(angle))+"_at_"+str(x))
	level.oblique_angle_degrees=8.
	for index in range(3):
		level._game_size_changed(index);await ticks(3)
		check(level.camera.global_basis.z.dot(Vector3(0,sin(deg_to_rad(6.)),cos(deg_to_rad(6.))))>.9999 if index==1 else true,"Straight comparison must remove horizontal yaw")
	level._game_size_changed(0)
	# The new view must retain normal single-plane traversal and direct ladder entry.
	level.actor.reset_actor();level.actor.position=Vector3(17.95,.02,0);await ticks(5)
	Input.action_press("miko8_up");await ticks(3);Input.action_release("miko8_up")
	check(level.actor.state=="ClimbHold" and absf(level.actor.position.z)<.001,"Gentle camera must preserve immediate ladder input and the movement lane")
	print("GENTLE_CAMERA_", "PASS" if failures==0 else "FAIL", " failures=",failures)
	quit(0 if failures==0 else 1)
