extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for frame in range(count):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("CRATE_BREAK_FAIL: "+message)
func capture(label:String)->void:
	if "--headless" in OS.get_cmdline_args():return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/CrateBreak/"+label+".png")
func aim(actor:Node)->void:
	actor.abilities.aim_elevation=-.42;actor.abilities.target_aim_elevation=-.42
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(150)
	var actor=level.actor;var crate=level.get_node("NewYardProps/WoodenCrate")
	actor.reset_actor();actor.position=Vector3(2.8,.02,0);level._camera(0,true);await ticks(12)
	# Colour shots can strike the wood but never destroy it.
	Input.action_press("miko8_spell_single");await ticks(95);aim(actor);await ticks(8)
	Input.action_release("miko8_spell_single");await ticks(45)
	check(not crate.broken and crate.collision_layer==1,"Red shot must leave wooden crate intact")
	Input.action_press("miko8_spell_double");await ticks(95);aim(actor);await ticks(8)
	check(not crate.broken,"Holding plasma must not destroy the crate")
	await capture("plasma_aimed")
	Input.action_release("miko8_spell_double")
	var hit:=false
	for frame in range(80):
		await physics_frame
		if crate.broken:hit=true;break
	check(hit,"Actual released plasma must hit and destroy the wooden crate")
	await ticks(7);await capture("impact")
	var debris=get_nodes_in_group("miko8_crate_debris")
	check(debris.size()==1,"One hit must create exactly one breakup effect")
	if not debris.is_empty():
		check(debris[0].pieces.size()==12,"Breakup must use twelve textured pieces of the supplied model")
		check(debris[0].find_children("*","CollisionObject3D",true,false).is_empty(),"Cosmetic debris must not block the player")
	check(crate.collision_layer==0,"Broken crate must stop blocking movement")
	check(not crate.get_child(0).visible,"Intact crate mesh must disappear")
	await ticks(18);await capture("debris")
	Input.action_press("miko8_right",.65);await ticks(100);Input.action_release("miko8_right");await ticks(8)
	check(actor.position.x>6.5 and actor.is_on_floor(),"MIKO must walk through the destroyed crate's old position")
	await ticks(180)
	check(get_nodes_in_group("miko8_crate_debris").is_empty(),"Fragments, dust and audio must clean up")
	level._restart();await ticks(65)
	check(not crate.broken and crate.collision_layer==1 and crate.get_child(0).visible,"Reset must restore the crate and its collision")
	print("CRATE_BREAK_", "PASS" if failures==0 else "FAIL", " failures=",failures)
	quit(0 if failures==0 else 1)
