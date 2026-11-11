extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var scene=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(scene)
	for i in range(20):await physics_frame
	var actor=scene.actor;actor.reset_actor();actor.position=Vector3(10.3,.02,0);var crate=scene.get_node("Level2Platforms/SwitchTestCrate")
	crate.position=Vector3(14,.4,0);crate.linear_velocity=Vector3.ZERO;crate.sleeping=false;actor.polarity_control.set_polarity(1,true);crate.lock_in_color(Color.BLUE)
	for i in range(300):
		await physics_frame
		if i%30==0:print("DRAG i=",i," actor=",actor.position," crate=",crate.position," vel=",crate.linear_velocity," pole=",crate.polarity," active=",crate.camera_active," process=",crate.is_physics_processing()," sleeping=",crate.sleeping," pressed=",get_first_node_in_group("miko8_pressure_switches").pressed)
	quit()
