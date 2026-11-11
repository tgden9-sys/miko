extends SceneTree
func _initialize()->void:call_deferred("run")
func shot(label:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Source/Environment/SideOnMockup/"+label+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level)
	await create_timer(3).timeout
	for x:float in [7,24,32,42,51,62]:
		level.actor.reset_actor();level.actor.position=Vector3(x,.02,0);level._camera(0,true)
		await create_timer(.8).timeout;await shot("extended_"+str(x))
	level.actor.reset_actor();level.actor.position=Vector3(42,.02,0);level._camera(0,true)
	await create_timer(.8).timeout
	level.actor.set_physics_process(false);level.scene_presence.set_process(false);level.scene_presence.set_physics_process(false);level.set_process(false)
	await shot("atmosphere_on")
	level.atmosphere_toggle.button_pressed=false
	await process_frame;await process_frame;await shot("atmosphere_off")
	# Check contact effects during actual input-driven travel and landing.
	level.atmosphere_toggle.button_pressed=true
	level.set_process(true);level.scene_presence.set_process(true);level.scene_presence.set_physics_process(true)
	level.actor.reset_actor();level.actor.position=Vector3(34,.02,0);level.actor.set_physics_process(true);level._camera(0,true)
	Input.action_press("miko8_right",.65)
	var maximum_foot_dust:=0;var captured_run:=false
	for frame in range(100):
		await physics_frame
		var active:=0
		for particle:Dictionary in level.scene_presence.sparks:
			if particle.age<particle.life and particle.kind==3.0:active+=1
		maximum_foot_dust=maxi(maximum_foot_dust,active)
		if active>0 and not captured_run:
			await shot("grounded_run");captured_run=true
	Input.action_press("miko8_jump");await create_timer(.12).timeout;Input.action_release("miko8_jump")
	var airborne:=false;var landed:=false
	for frame in range(160):
		await physics_frame
		if not level.actor.is_on_floor():airborne=true
		elif airborne:
			await shot("grounded_landing");landed=true;break
	Input.action_release("miko8_right")
	print("CONTACT_EFFECTS_REVIEW run_dust_peak=",maximum_foot_dust," airborne=",airborne," landed=",landed)
	print("EXTENDED_REVIEW_DONE length=",level.MOCKUP_LENGTH," city_split=",level.layered_scenery.city_layers_active)
	quit()
