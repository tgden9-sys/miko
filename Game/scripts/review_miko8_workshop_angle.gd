extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for frame in range(count):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("WORKSHOP_ANGLE_FAIL: "+message)
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(150)
	var workshop=level.get_node("ServiceBlockObstacle");var actor=level.actor
	var roof:float=workshop.to_global(Vector3(0,workshop.HEIGHT*workshop.height_scale-1.25,0)).y
	actor.reset_actor();actor.position=Vector3(50.5,.02,0);level._camera(0,true);await ticks(12)
	Input.action_press("miko8_right",.65);Input.action_press("miko8_jump")
	var peak:=0.0
	for frame in range(100):await physics_frame;peak=maxf(peak,actor.position.y)
	Input.action_release("miko8_jump");Input.action_release("miko8_right");await ticks(15)
	check(actor.position.x<54.0 and actor.is_on_floor() and peak<roof-1.,"Smaller rotated building must still block the normal jump")
	actor.reset_actor();actor.position=Vector3(50.4,.02,0);level._camera(0,true);await ticks(15)
	if not "--headless" in OS.get_cmdline_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/Workshop/angled_approach.png")
	actor.reset_actor();actor.position=Vector3(54.2,roof+.05,0);level._camera(0,true);await ticks(15)
	check(actor.is_on_floor() and absf(actor.position.y-roof)<.04,"Roof collision must follow the scaled building")
	Input.action_press("miko8_right",.35);await ticks(100);Input.action_release("miko8_right");await ticks(5)
	check(actor.is_on_floor() and actor.position.x>55.5 and absf(actor.position.y-roof)<.04,"MIKO must walk across the angled roof on the original lane")
	if not "--headless" in OS.get_cmdline_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/Workshop/angled_roof.png")
	print("WORKSHOP_ANGLE_", "PASS" if failures==0 else "FAIL", " failures=",failures," roof_y=",roof)
	quit(0 if failures==0 else 1)

