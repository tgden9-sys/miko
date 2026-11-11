extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("THREE_TONE_FAIL "+message)
func capture(name:String)->void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/ThreeTone/"+name+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(140)
	var actor=level.actor;var control=actor.polarity_control
	check(control.three_tone_enabled,"The yard must start in three-tone mode")
	actor.reset_actor();actor.position=Vector3(18.08,.02,0);level._camera(0,true);await ticks(15)
	actor.set_physics_process(false)
	for pose:Dictionary in [{"name":"idle","clip":"Idle","phase":.3},{"name":"walk","clip":"Walk","phase":.32},{"name":"run","clip":"Run","phase":.20}]:
		actor.current_clip="";actor._play(pose.clip,0.);actor.animation_player.seek(actor._duration(pose.clip)*pose.phase,true)
		await ticks(2)
		var hand:Transform3D=actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-hand.R"))
		for graphic:bool in [false,true]:
			level.miko_style.select(0 if graphic else 1);level._miko_style_changed(0 if graphic else 1);await ticks(3)
			await capture(pose.name+("_three_tone" if graphic else "_original"))
			check(actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-hand.R")).is_equal_approx(hand),"Changing shading must leave the pose unchanged")
			for index in range(control.materials.size()):
				check(control.graphic_materials[index].get_shader_parameter("base_texture")==control.original_materials[index].get_shader_parameter("base_texture"),"The original scratch/paint texture must be shared")
	for pole:int in [1,2,0]:
		control.set_polarity(pole);control.set_three_tone(false);control.set_three_tone(true)
		for paint:ShaderMaterial in control.materials:check(paint.get_shader_parameter("polarity")==pole,"Polarity must survive a shading toggle")
	var event:=InputEventKey.new();event.physical_keycode=KEY_F8;event.pressed=true
	level._unhandled_key_input(event);check(not control.three_tone_enabled,"F8 must select original shading")
	level._unhandled_key_input(event);check(control.three_tone_enabled,"F8 must restore three-tone shading")
	# Fixed close-up comparisons use exactly the same idle pose and camera.
	level.set_process(false);level.set_physics_process(false)
	actor.current_clip="";actor._play("Idle",0.);actor.animation_player.seek(.3,true)
	level.camera.size=3.5
	level.camera.position=actor.position+Vector3.UP*.95+level.camera.basis.z*18.
	for graphic:bool in [false,true]:
		level.miko_style.select(0 if graphic else 1);level._miko_style_changed(0 if graphic else 1);await ticks(3)
		await capture("detail_three_tone" if graphic else "detail_original")
	actor.set_physics_process(true)
	Input.action_press("miko8_left",.35);await ticks(80);Input.action_release("miko8_left");await ticks(20)
	check(actor.position.x<17.5 and actor.is_on_floor(),"MIKO must still turn, walk and stop")
	print("THREE_TONE_","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(failures)
