extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var scene=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(scene)
	for i in range(15):await physics_frame
	scene.actor.reset_actor();scene.actor.position=Vector3(27,2.8,0);scene.elapsed=10.;scene.fade.color.a=0.;scene.set_process(false)
	var pickup=get_first_node_in_group("miko8_canisters")
	assert(pickup.model.scale.is_equal_approx(Vector3.ONE*.24));assert(absf(pickup.model.rotation.z-PI/2.)<.001)
	var low:=10.;var high:=0.
	for i in range(180):pickup._process(1./60.);low=minf(low,pickup.display.position.y);high=maxf(high,pickup.display.position.y)
	assert(low>=.074 and high<=.166 and high-low>.08)
	if DisplayServer.get_name()!="headless":
		for layer:CanvasLayer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
		scene.camera.size=1.6;scene.camera.position=Vector3(29,3.8,4);scene.camera.look_at(Vector3(30,2.95,0))
		await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://../Builds/Validation/Level2Props/hover_canister.png")
	pickup._collect(scene.actor);assert(not pickup.display.visible and not pickup.shadow.visible)
	pickup.reset_collectible();assert(pickup.display.visible and pickup.shadow.visible and not pickup.is_collected)
	print("HOVER_CANISTER_PASS upright=true half_size=true hover=",low,"..",high," collection_reset=true");quit()
