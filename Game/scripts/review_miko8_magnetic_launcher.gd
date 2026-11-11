extends SceneTree
var failures:=0
var level:Node3D
var actor:CharacterBody3D
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("LAUNCHER_FAIL "+message)
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	level.set_process(false)
	var saved:Transform3D=level.camera.global_transform
	var saved_size:float=level.camera.size
	level.camera.size=3.5;level.camera.global_position=actor.position+Vector3(3.6,2.4,6.5);level.camera.look_at(actor.position+Vector3(0,.9,0))
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/Launcher/"+label+".png")
	level.camera.global_transform=saved;level.camera.size=saved_size;level.set_process(true)
func key(code:Key)->void:
	var e:=InputEventKey.new();e.physical_keycode=code;e.pressed=true;Input.parse_input_event(e)
	await ticks(2);e=InputEventKey.new();e.physical_keycode=code;e.pressed=false;Input.parse_input_event(e);await ticks(2)
func wait_state(wanted:String,limit:=180)->void:
	for i in range(limit):
		if actor.state==wanted:return
		await ticks(1)
	check(false,"Timed out waiting for "+wanted+"; state="+actor.state)
func run()->void:
	level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(20)
	actor=level.actor;actor.reset_actor();actor.position=Vector3(8.,.02,0);await ticks(10)
	await key(KEY_1);check(actor.suit_polarity==1,"1 selects red suit")
	await key(KEY_2);check(actor.suit_polarity==2,"2 selects blue suit")
	await key(KEY_0);check(actor.suit_polarity==0,"0 selects neutral suit")
	actor.position=Vector3(9.4,.02,0);actor.facing=1;actor.visual.rotation.y=PI/2
	Input.action_press("miko8_spell_single");await ticks(80);Input.action_release("miko8_spell_single");await ticks(35)
	check(level.get_node("NewYardProps/Loader/ChargeTarget").polarity==1,"Released red bolt must charge launcher")
	actor.reset_actor()
	var base=level.get_node("NewYardProps/FixedChargeBase")
	var original:Vector3=base.position
	base.lock_in_color(Color.RED);actor.position=Vector3(7.1,.02,0);actor.polarity_control.set_polarity(2);await ticks(25)
	check(absf(actor.position.x-7.1)<.01,"Fixed opposite base must not pull MIKO")
	actor.polarity_control.set_polarity(1);actor.velocity=Vector3.ZERO;var repel_start:float=actor.position.x;await ticks(20)
	check(absf(actor.position.x-repel_start)<.01,"Fixed matching base must not repel MIKO")
	check(base.freeze and base.position.is_equal_approx(original),"Bolted base must remain anchored")
	base.neutralize();actor.reset_actor();actor.position=Vector3(22.,.02,0);await ticks(10)
	var box=level.get_node("TutorialChargeCrate");check(not box.freeze,"Metal crate physics enabled")
	box.position=Vector3(24.6,.42,0);box.lock_in_color(Color.BLUE);actor.polarity_control.set_polarity(1)
	var start:float=box.position.x;await ticks(20);check(box.position.x<start-.03,"Opposite suit attracts free crate")
	box.linear_velocity=Vector3.ZERO;actor.polarity_control.set_polarity(2);start=box.position.x;await ticks(20)
	check(box.position.x>start+.03,"Matching suit repels free crate")
	box.reset_charge_body();actor.reset_actor();actor.position=Vector3(9.,.02,0);await ticks(10)
	actor._begin_jump();var normal_apex:=0.
	for i in range(100):await ticks(1);normal_apex=maxf(normal_apex,actor.position.y)
	var launcher=level.get_node("NewYardProps/Loader/ChargeTarget")
	actor.reset_actor();actor.position=Vector3(11.35,.02,0);launcher.lock_in_color(Color.RED);actor.polarity_control.set_polarity(2)
	await ticks(25);check(absf(actor.position.x-11.35)<.01,"Launcher must not draw MIKO in from nearby")
	Input.action_press("miko8_right",.5)
	for i in range(90):
		await ticks(1)
		if actor.state=="LauncherAttach":break
	Input.action_release("miko8_right")
	await wait_state("LauncherHold")
	check(absf(actor.position.x-launcher.launch_center().x)<.07,"Brace must engage only while walking through the middle")
	check(actor.is_on_floor(),"Braced feet must remain grounded")
	await capture("brace_right")
	var grip_error:=0.
	for modifier in actor.skeleton.get_children():
		if modifier.get_script()==load("res://scripts/miko8_launcher_pose.gd"):grip_error=modifier.maximum_hand_error
	check(grip_error<.045,"Hands must reach both cap targets: error="+str(grip_error))
	await key(KEY_1);await wait_state("Air",60)
	var boosted_apex:=actor.position.y;await capture("launch_right")
	for i in range(100):await ticks(1);boosted_apex=maxf(boosted_apex,actor.position.y)
	check(boosted_apex/normal_apex>2.65 and boosted_apex/normal_apex<2.95,"Launch apex must be 40% higher (2.8x normal height)")
	check(actor.launcher_motion.launch_count==1,"Matching charge launches exactly once")
	await ticks(45);check(actor.launcher_motion.launch_count==1,"No repeat launch on landing")
	actor.reset_actor();actor.position=Vector3(12.25,.02,0);actor.facing=-1;actor.visual.rotation.y=-PI/2;launcher.lock_in_color(Color.BLUE);actor.polarity_control.set_polarity(1)
	Input.action_press("miko8_left",.5)
	for i in range(90):
		await ticks(1)
		if actor.state=="LauncherAttach":break
	Input.action_release("miko8_left")
	await wait_state("LauncherHold");await capture("brace_left")
	for modifier in actor.skeleton.get_children():
		if modifier.get_script()==load("res://scripts/miko8_launcher_pose.gd"):check(modifier.maximum_hand_error<.045,"Left-facing hands must reach both caps")
	Input.action_press("miko8_left",.5);await ticks(25);Input.action_release("miko8_left")
	check(not actor.state.begins_with("Launcher"),"Movement must let MIKO walk away from brace")
	actor.reset_actor();actor.position=launcher.launch_center()+Vector3(0,.02,0);launcher.lock_in_color(Color.BLUE);actor.polarity_control.set_polarity(1);await wait_state("LauncherHold")
	await key(KEY_0);await ticks(20);check(not actor.state.begins_with("Launcher"),"Neutral detaches without launch")
	actor.reset_actor();actor.position=launcher.launch_center()+Vector3(0,.02,0);launcher.lock_in_color(Color.RED);actor.polarity_control.set_polarity(2);await wait_state("LauncherHold")
	Input.action_press("miko8_jump");await ticks(2);Input.action_release("miko8_jump");await ticks(12)
	check(not actor.state.begins_with("Launcher"),"Jump cancels the hold")
	actor.reset_actor();check(actor.launcher_motion.phase=="" and actor.suit_polarity==0,"Reset clears grip and suit")
	print("MAGNETIC_LAUNCHER_","PASS" if failures==0 else "FAIL"," failures=",failures," normal_apex=",normal_apex," boosted_apex=",boosted_apex," grip_error=",grip_error)
	level.queue_free();await process_frame;await process_frame
	quit(failures)
