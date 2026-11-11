extends SceneTree
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func report(actor:Node,label:String)->void:
	var a=actor.abilities;var origin:Vector3=a._single_origin();var hit:Dictionary=a._laser_hit(origin)
	print("AIM ",label," state=",actor.state," fired=",a.spell_fired," mode=",a.laser_mode," origin=",origin," pitch=",a.aim_elevation," visible=",a.lasers.lines.L.visible," start=",a.lasers.starts.get("L")," end=",a.lasers.ends.get("L")," hit=",hit.get("collider")," path=",hit.collider.get_path() if hit.has("collider") else "none"," length=",origin.distance_to(hit.position) if hit.has("position") else 24.)
func run()->void:
	var level=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(level);await ticks(20)
	var actor=level.actor;actor.reset_actor();actor.position=Vector3(16,.02,0);actor.facing=-1;actor.target_facing=-1;actor.visual.rotation.y=-PI/2.;await ticks(10)
	for action in ["miko8_spell_single","miko8_spell_blue","miko8_spell_single"]:
		Input.action_press(action);await ticks(35)
		var crate=level.get_node("Level2Platforms/SwitchTestCrate")
		for i in range(8):
			var origin:Vector3=actor.abilities._single_origin();actor.abilities.aim_elevation=atan2(crate.position.y+.15-origin.y,absf(crate.position.x-origin.x));actor.abilities.target_aim_elevation=actor.abilities.aim_elevation;await ticks(3)
		report(actor,"hold");await process_frame;await RenderingServer.frame_post_draw
		if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://../Builds/Validation/Level2Props/aim_"+action+"_"+str(actor.abilities.shots_fired)+".png")
		Input.action_release(action);await ticks(10);report(actor,"after fire");await ticks(35);report(actor,"idle")
		print("CRATE_POLE ",crate.polarity)
	level.free();await ticks(3)
	level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(20);actor=level.actor
	for x in [17.,18.,19.,23.,25.,29.,30.,31.,51.,53.]:
		actor.reset_actor();actor.position=Vector3(x,.02,0);actor.facing=-1;actor.target_facing=-1;actor.visual.rotation.y=-PI/2.;await ticks(8)
		Input.action_press("miko8_spell_single");await ticks(35);report(actor,"wall x="+str(x));Input.action_release("miko8_spell_single");await ticks(35)
	quit()
