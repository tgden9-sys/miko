extends SceneTree
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func capture(name:String)->void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/ArchitectureIntegration/"+name+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(120)
	var finish=level.get_node("ArchitectureIntegration")
	for place:Dictionary in [{"name":"ladder","x":18.08},{"name":"workshop","x":53.0}]:
		level.actor.reset_actor();level.actor.position=Vector3(place.x,.02,0);level._camera(0,true);await ticks(15)
		finish.set_enabled(false);await ticks(10);await capture(place.name+"_before")
		finish.set_enabled(true);await ticks(10);await capture(place.name+"_after")
	print("ARCHITECTURE_REVIEW_READY")
	quit()
