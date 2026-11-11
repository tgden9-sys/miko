extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;push_error(label)
func capture(level:Node,label:String)->void:
	if DisplayServer.get_name()=="headless":return
	level.fade.color.a=0.;level.set_process(false)
	level.camera.size=10.;level.camera.global_position=Vector3(66.5,5.5,15);level.camera.look_at(Vector3(70.,2.8,0))
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://../Builds/Validation/Overhang/"+label+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(25)
	level.actor.reset_actor();level.actor.position=Vector3(67.1,.02,0);level._camera(0,true)
	var bay=level.get_node("OverhangLoadingBay");var pad=bay.get_node("CeilingMagPad");var cargo=bay.get_node("HeavyCargo")
	check(cargo.mass>=20. and not cargo.suit_movable,"Cargo must resist suit magnetism")
	check(pad.mount_mode==1 and cargo.polarity==0,"Neutral heavy cargo and ceiling pad ready")
	# Check the visible underside, roof, supporting wall and extended open bay.
	for x:float in [67.,68.5,70.5]:
		var ray:=PhysicsRayQueryParameters3D.create(Vector3(x,2.5,-.6),Vector3(x,5.,-.6),1)
		var hit=level.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit.position.y>4.3 and hit.position.y<4.5,"Ceiling must span the extended bay at 4.4m")
	await capture(level,"neutral")
	var red=load("res://scripts/miko8_spell_projectile.gd").new();red.mode="Red";red.velocity=Vector3(14,0,0);level.add_child(red);red.position=Vector3(67.7,1.1,0);await ticks(12)
	check(cargo.polarity==1,"Actual red bolt must charge heavy cargo")
	level.actor.polarity_control.set_polarity(2,true)
	var start:Vector3=cargo.position;await ticks(30);check(cargo.position.distance_to(start)<.06,"Suit must not pull heavy cargo")
	level.actor.polarity_control.set_polarity(0,true)
	var blue=load("res://scripts/miko8_spell_projectile.gd").new();blue.mode="Blue";blue.velocity=Vector3(0,14,0);level.add_child(blue);blue.position=Vector3(69.2,3.6,0);await ticks(8)
	check(pad.polarity==2,"Actual blue bolt must charge downward-facing pad")
	for i in range(300):await ticks(1)
	var lifted_y:float=cargo.position.y
	check(lifted_y>2.85 and lifted_y<3.3,"Ceiling pad must lift and hold cargo below it")
	check(lifted_y-.9>1.95,"Raised cargo must leave MIKO headroom underneath")
	await capture(level,"lifted")
	cargo.neutralize();await ticks(18);check(cargo.position.y<lifted_y-.12,"Neutralising raised cargo must release it to gravity")
	await ticks(110);check(cargo.position.y<1.05 and cargo.position.y>.85,"Cargo must land back on paving")
	# Lift again, then verify neutralising the pad also releases the load.
	cargo.lock_in_color(Color.RED);await ticks(280);check(cargo.position.y>2.85,"Cargo must recharge and lift again")
	pad.neutralize();await ticks(35);check(cargo.position.y<2.6,"Neutralising pad must release charged cargo")
	print("OVERHANG_BAY_PASS failures=",failures," held_y=",lifted_y)
	level.queue_free();await process_frame;await process_frame;quit(failures)
