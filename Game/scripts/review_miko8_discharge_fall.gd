extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;push_error(label)
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(20)
	var box=level.get_node("TutorialChargeCrate");var pad=level.get_node("WallMagPad")
	level.actor.reset_actor();level.actor.position=Vector3(49,.02,0)
	for name:String in ["WorkshopCrateStep","WorkshopCrateLower","WorkshopCrateUpper"]:
		var other=level.get_node(name);other.freeze=true;other.position=Vector3(35,.5,-4)
	pad.lock_in_color(Color.RED);box.freeze=true;box.position=Vector3(51.,.5,0);await ticks(2);box.freeze=false;box.set_camera_active(true);box.lock_in_color(Color.BLUE)
	var start_x:float=box.position.x;var max_y:float=box.position.y
	for i in range(35):await ticks(1);max_y=maxf(max_y,box.position.y)
	check(box.position.x>start_x+.03,"Low wall pad must pull block horizontally")
	check(max_y<.57,"Pad must not lift floor block")
	box.freeze=true;box.position=Vector3(26,3.,0);box.linear_velocity=Vector3.ZERO;box.gravity_scale=0.;box.constant_force=Vector3(0,28,0);box.lock_in_color(Color.BLUE);box.set_locked_on(true,Vector3.ZERO,Color.BLUE);await ticks(2);box.freeze=false;box.sleeping=true
	box.neutralize();check(box.polarity==0 and box.charge_remaining==0. and box.breakaway_remaining==0. and not box.is_locked_on and not box.marker.visible,"Discharge clears all active magnetic state")
	check(box.gravity_scale==1. and box.constant_force==Vector3.ZERO and not box.sleeping,"Discharge restores gravity and wakes raised block")
	await ticks(25);check(box.position.y<2.5 and box.linear_velocity.y<0.,"Neutral raised block must fall")
	await ticks(100);check(box.position.y<.6 and box.position.y>.35,"Neutral block must settle on ground")
	print("DISCHARGE_FALL_PASS failures=",failures," floor_max_y=",max_y," landed_y=",box.position.y)
	level.queue_free();await process_frame;await process_frame;quit(failures)
