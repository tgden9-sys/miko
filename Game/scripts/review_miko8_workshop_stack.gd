extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for frame in range(count):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("WORKSHOP_STACK_FAIL: "+message)
func capture(label:String)->void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/Workshop/"+label+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(150)
	var actor=level.actor;var upper=level.get_node("WorkshopCrateUpper")
	actor.reset_actor();actor.position=Vector3(50.4,.02,0);level._camera(0,true);await ticks(15)
	await capture("crate_stack_approach")
	Input.action_press("miko8_right",.65);Input.action_press("miko8_jump")
	var peak:=0.0;var landed_on_stack:=false
	for frame in range(110):
		await physics_frame;peak=maxf(peak,actor.position.y)
		if actor.is_on_floor() and actor.position.y>1.55:landed_on_stack=true
	Input.action_release("miko8_jump");Input.action_release("miko8_right");await ticks(10)
	print("STACK_DIRECT_JUMP peak=",peak," stack_top=1.6 landed_on_stack=",landed_on_stack)
	check(peak>1.2 and peak<1.6 and not landed_on_stack,"Current unassisted jump must accurately report the stack as too tall")
	# Check collision support independently of the unavailable ledge-grab mechanic.
	actor.reset_actor();actor.position=Vector3(51.8,1.70,0);await ticks(30)
	check(actor.is_on_floor() and absf(actor.position.y-1.6)<.04,"Stack must support MIKO at its exact 1.6m top")
	await capture("crate_stack_supported")
	Input.action_press("miko8_right",.65);Input.action_press("miko8_jump")
	var assisted_peak:=1.6
	for frame in range(110):await physics_frame;assisted_peak=maxf(assisted_peak,actor.position.y)
	Input.action_release("miko8_jump");Input.action_release("miko8_right");await ticks(10)
	var workshop=level.get_node("ServiceBlockObstacle")
	var roof:float=workshop.to_global(Vector3(0,workshop.HEIGHT*workshop.height_scale-1.25,0)).y
	print("STACK_TO_ROOF peak=",assisted_peak," roof=",roof," reached_roof=",actor.position.y>roof-.05)
	check(assisted_peak<roof and actor.position.x<52.68,"Current jump from stack must report the remaining roof gap")
	print("WORKSHOP_STACK_", "PASS" if failures==0 else "FAIL", " failures=",failures)
	quit(0 if failures==0 else 1)

