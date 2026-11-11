extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;push_error(label)
func capture(level:Node,label:String)->void:
	if DisplayServer.get_name()=="headless":return
	level.fade.color.a=0.;level.set_process(false);level.camera.size=5.0;level.camera.global_position=Vector3(48.2,3.4,7.5);level.camera.look_at(Vector3(52.,1.6,0))
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://../Builds/Validation/MagPad/"+label+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(30)
	var pad=level.get_node("WallMagPad");var actor=level.actor;var box=level.get_node("TutorialChargeCrate")
	check(pad.polarity==0 and pad.paints.size()>0,"Pad starts green and has live charge materials")
	actor.reset_actor();actor.position=Vector3(49.0,.02,0);actor.facing=1;actor.visual.rotation.y=PI/2;box.position=Vector3(28.7,.5,0);await ticks(10)
	await capture(level,"green")
	for name:String in ["WorkshopCrateStep","WorkshopCrateLower","WorkshopCrateUpper"]:
		var other=level.get_node(name);other.freeze=true;other.position=Vector3(35.,.5,-4.)
	await ticks(3)

	var red=load("res://scripts/miko8_spell_projectile.gd").new();red.mode="Red";red.velocity=Vector3(14,0,0);level.add_child(red);red.position=Vector3(51.,.65,0);await ticks(20)
	check(pad.polarity==1,"Released red shot must charge the wall pad")
	await capture(level,"red")
	var fixed:Vector3=pad.position
	actor.position=Vector3(49,.02,0);actor.polarity_control.set_polarity(0,true)
	box.position=Vector3(50.8,.5,0);box.linear_velocity=Vector3.ZERO;box.lock_in_color(Color.BLUE)
	var start:float=box.position.x;await ticks(25);check(box.position.x>start+.03,"Opposite block must move toward wall pad")
	box.freeze=true;box.position=Vector3(51.4,.5,0);box.linear_velocity=Vector3.ZERO;await ticks(2);box.freeze=false;box.set_camera_active(true);box.lock_in_color(Color.RED);start=box.position.x;await ticks(40)
	print("PAD_REPEL start=",start," end=",box.position.x," active=",box.camera_active)
	check(box.position.x<start-.03,"Matching block must move away from wall pad")
	check(pad.position.is_equal_approx(fixed),"Pad must stay attached to wall")
	box.neutralize();box.freeze=true;box.position=Vector3(29,.5,0);box.linear_velocity=Vector3.ZERO
	actor.reset_actor();actor.position=Vector3(49.0,.02,0);await ticks(12)
	var actor_start:float=actor.position.x;actor.polarity_control.set_polarity(2,true);await ticks(20)
	print("PAD_SUIT_CHECK start=",actor_start," end=",actor.position.x," state=",actor.state)
	check(absf(actor.position.x-actor_start)<.01,"Pad must not pull MIKO")
	pad.lock_in_color(Color.BLUE);await capture(level,"blue")
	pad.charge_remaining=.01;await ticks(3);check(pad.polarity==0,"Expired charge returns pad to green")
	pad.lock_in_color(Color.RED)
	var bolt=load("res://scripts/miko8_spell_projectile.gd").new();bolt.mode="Plasma";bolt.velocity=Vector3(18,0,0);level.add_child(bolt);bolt.position=Vector3(51.,.65,0);await ticks(15)
	check(pad.polarity==0,"Plasma must discharge pad back to green")
	print("WALL_MAG_PAD_PASS failures=",failures)
	level.queue_free();await process_frame;await process_frame;quit(failures)


