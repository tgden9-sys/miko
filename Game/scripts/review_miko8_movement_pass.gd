extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;push_error(label)
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/MovementPass/"+label+".png")
func run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate();root.add_child(level);await ticks(15)
	for body in level.get_children():
		if body is RigidBody3D or body.get_script()==load("res://scripts/miko8_spell_target.gd"):body.queue_free()
	var a=level.actor;a.reset_actor();a.position=Vector3(0,.02,0);await ticks(8)
	Input.action_press("miko8_right",.65)
	var frames:=0
	for i in range(60):
		await ticks(1);frames+=1
		if a.velocity.x>=a._speed("Run")*.9:break
	check(frames<=22,"Run should reach 90 percent speed within .37 seconds")
	var run_speed:float=a.velocity.x
	await capture("run")
	Input.action_press("miko8_jump");await ticks(2)
	check(a.launched and a.velocity.y>0.,"Tight jump must take off immediately")
	check(a.velocity.x>4.5,"Running jump must retain forward pace")
	var apex:float=a.position.y;var air_distance:float=a.position.x
	for i in range(35):await ticks(1);apex=maxf(apex,a.position.y)
	await capture("jump")
	Input.action_release("miko8_jump")
	for i in range(60):
		await ticks(1)
		if a.is_on_floor():break
	check(a.is_on_floor(),"Jump must land")
	check(a.velocity.x>3.5,"Moving landing must preserve travel")
	await capture("landing")
	air_distance=a.position.x-air_distance
	Input.action_release("miko8_right");await ticks(25)
	check(absf(a.velocity.x)<.02,"Release must stop reliably")
	Input.action_press("miko8_left",.65);await ticks(50)
	check(a.facing==-1 and a.velocity.x< -4.,"Reversal must complete with leftward travel")
	Input.action_release("miko8_left");await ticks(20)
	check(apex>1.2 and apex<1.6,"Full jump height must remain suitable for existing obstacles")
	print("MOVEMENT_PASS failures=",failures," run_t90=",frames/60.," speed=",run_speed," apex=",apex," air_travel=",air_distance)
	level.queue_free();await process_frame;await process_frame;quit(failures)
