extends SceneTree

var failures:=0

func _initialize()->void:
	call_deferred("_run")

func ticks(count:int)->void:
	for frame in range(count):
		await physics_frame

func check(condition:bool,message:String)->void:
	print(("PASS " if condition else "FAIL ")+message)
	if not condition:failures+=1

func _run()->void:
	var level:Node3D=load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	current_scene=level
	var actor:CharacterBody3D=level.actor
	var ability:Node=actor.abilities
	var launcher:Area3D=level.get_node("NewYardProps/Loader/ChargeTarget")
	var crate:RigidBody3D
	for target in get_nodes_in_group("miko8_charge_targets"):
		if target.name=="TutorialChargeCrate":crate=target;break
	# Use a straight stretch of floor so backing away isn't blocked by a building.
	crate.position=Vector3(9.,.4,0)
	actor.reset_actor()
	actor.position=Vector3(crate.position.x-.75,.02,0)
	await ticks(20)
	var crate_start:=crate.position
	actor.reactions.toggle_crawl=true
	await ticks(20)
	check(not actor.reactions.crouched and not actor.state.begins_with("Crawl"),"Crawl entry is rejected next to a crate")
	check(absf(crate.position.x-crate_start.x)<.005,"Rejected crawl does not move the crate")
	Input.action_press("miko8_left",.35)
	await ticks(55)
	Input.action_release("miko8_left")
	await ticks(25)
	check(actor.reactions._can_crawl(),"Walking back clears the crawl footprint at %s"%actor.position)
	actor.reactions.toggle_crawl=true
	await ticks(ceili(actor._duration("CrawlEnter")/actor.reactions.CRAWL_RATE*60.)+5)
	check(actor.state=="Crawl" and actor.reactions.crouched,"Crawl works after walking back into clear space")
	check(absf(crate.position.x-crate_start.x)<.005,"Backing away and crawling leaves the crate in place")
	Input.action_press("miko8_right",.35)
	await ticks(90)
	Input.action_release("miko8_right")
	check(absf(crate.position.x-crate_start.x)<.005,"Crawling into the crate stops Miko without pushing it")

	for side:int in [1,-1]:
		for action:String in ["miko8_spell_single","miko8_spell_blue","miko8_spell_double"]:
			actor.reset_actor()
			actor.position=launcher.global_position+Vector3(-side*1.5,-launcher.global_position.y+.02,0)
			actor.facing=side
			actor.target_facing=side
			actor.visual.rotation.y=side*PI*.5
			launcher.lock_in_color(Color.RED if action=="miko8_spell_double" else Color.BLUE if action=="miko8_spell_single" else Color.RED)
			await ticks(10)
			Input.action_press(action)
			await ticks(55)
			var is_plasma:=action=="miko8_spell_double"
			var channel:="C" if is_plasma else "L"
			for frame in range(12):
				var muzzle:Vector3=ability._plasma_origin() if is_plasma else ability._single_origin()
				var offset:=launcher.global_position-muzzle
				ability.aim_elevation=atan2(offset.y,absf(offset.x))
				ability.target_aim_elevation=ability.aim_elevation
				await ticks(1)
			var ray_length:=0.
			if ability.lasers.starts.has(channel) and ability.lasers.ends.has(channel):
				var start:Vector3=ability.lasers.starts[channel]
				var finish:Vector3=ability.lasers.ends[channel]
				ray_length=start.distance_to(finish)
			check(ability.lasers.lines[channel].visible and ray_length>.08,"%s guide reads from side %d (%.2f m)"%[ability.laser_mode,side,ray_length])
			Input.action_release(action)
			await ticks(55)
			var expected:=0 if is_plasma else 1 if action=="miko8_spell_single" else 2
			check(launcher.polarity==expected,"%s hits the launcher from side %d"%[ability.laser_mode,side])

	actor.reset_actor()
	actor.position=launcher.launch_center()+Vector3.UP*.02
	launcher.lock_in_color(Color.RED)
	await ticks(10)
	Input.action_press("miko8_spell_double")
	await ticks(60)
	var start:Vector3=ability.lasers.starts.get("C",Vector3.ZERO)
	var finish:Vector3=ability.lasers.ends.get("C",Vector3.ZERO)
	check(ability.lasers.lines.C.visible and start.distance_to(finish)>1.,"Plasma guide leaves the launcher when Miko stands inside")
	Input.action_release("miko8_spell_double")
	await ticks(35)
	check(launcher.polarity==1,"Shot from inside does not collide with the launcher's invisible volume")
	print("LAUNCHER_CRAWL_RESULT failures=",failures)
	quit(failures)
