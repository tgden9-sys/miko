extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func capture(label:String)->void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/LadderSkin/"+label+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(120)
	var actor=level.actor;var ladder=level.climb_set.ladder
	actor.reset_actor();actor.position=Vector3(18.08,.02,0);level._camera(0,true);await ticks(20)
	await capture("front_ground")
	Input.action_press("miko8_up")
	var seen_exit:=false
	for i in range(600):
		await physics_frame
		if actor.state=="ClimbTopExit":seen_exit=true
		if seen_exit and actor.state=="Locomotion":break
	Input.action_release("miko8_up");await ticks(10)
	if not actor.is_on_floor() or absf(actor.position.y-ladder.top_y)>.04:failures+=1;push_error("SKIN_REVIEW: ladder roof handoff failed")
	await capture("roof_standing")
	Input.action_press("miko8_right",.35);await ticks(55);Input.action_release("miko8_right");await ticks(10)
	if not actor.is_on_floor():failures+=1;push_error("SKIN_REVIEW: roof walking failed")
	await capture("roof_walk")
	print("LADDER_SKIN_REVIEW failures=",failures," roof_y=",actor.position.y)
	quit(failures)
