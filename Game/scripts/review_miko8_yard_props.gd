extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level)
	await create_timer(3).timeout
	level.actor.reset_actor();level.actor.position=Vector3(9.6,.02,0);level._camera(0,true)
	await create_timer(.8).timeout
	for prop_name:String in ["WoodenCrate","Loader"]:
		var prop:Node3D=level.get_node("NewYardProps/"+prop_name)
		assert(prop.find_children("*","MeshInstance3D",true,false).size()>0)
		assert(prop.find_children("*","CollisionShape3D",true,false).size()>0)
	# Cross the loader using actual walking input in both directions.
	for direction:float in [1.0,-1.0]:
		var action:String="miko8_right" if direction>0 else "miko8_left"
		Input.action_press(action,.35)
		for frame in range(280):
			await physics_frame
			assert(absf(level.actor.position.z)<.01,"Loader must preserve the walking lane")
			assert(absf(level.actor.position.y)<.06,"Crossing the loader must stay level with the paving")
		Input.action_release(action)
		assert(level.actor.position.x>13.4 if direction>0 else level.actor.position.x<10.0,"MIKO must walk completely through the loader")
		print("LOADER_WALK_THROUGH direction=",direction," position=",level.actor.position)
	level.actor.reset_actor();level.actor.position=Vector3(9.3,.02,0);level._camera(0,true)
	await create_timer(.5).timeout
	var target=level.get_node("NewYardProps/Loader/ChargeTarget")
	assert(target.paints.size()>0,"Loader must have colour-changing materials")
	var wooden=level.get_node("NewYardProps/WoodenCrate")
	assert(wooden.get_child(1).shape.size.is_equal_approx(Vector3(.8,.8,.8)),"Crate collider must match the metal crate")
	for state:int in [0,1,2]:
		if state>0:
			var action:String="miko8_spell_single" if state==1 else "miko8_spell_blue"
			Input.action_press(action)
			for frame in range(100):await physics_frame
			assert(level.actor.abilities.locked_target==target,"Existing spell controls must target the loader")
			Input.action_release(action)
			for frame in range(25):await physics_frame
		assert(target.polarity==state,"Loader must commit the selected colour")
		if not "--headless" in OS.get_cmdline_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../Builds/Validation/NewProps/loader_state_"+str(state)+".png")
	target.neutralize();assert(target.polarity==0)
	target.lock_in_color(Color.RED);target.charge_remaining=.01
	for frame in range(3):await physics_frame
	assert(target.polarity==0,"Expired charge must return to green")
	if not "--headless" in OS.get_cmdline_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/NewProps/in_scene.png")
	print("YARD_PROPS_OK: walk-through, 0.8m crates, input-driven red/blue targeting, green neutral and expiry")
	quit()
