extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func traverse(actor:Node,action:String)->Dictionary:
	var frames:=0;var rung_frames:=0;var distance:=0.;var started:=false
	var motion=actor.abilities.bpg_motion;var last_y:float=actor.position.y;var last_mode:=""
	Input.action_press(action)
	for i in range(1000):
		await physics_frame;frames+=1
		if motion.active:
			started=true
			if motion.mode in ["up","down"] and motion.mode==last_mode:
				rung_frames+=1;distance+=absf(actor.position.y-last_y)
			last_mode=motion.mode;last_y=actor.position.y
		elif started:break
	Input.action_release(action)
	var result:={"seconds":float(frames)/60.,"rung_seconds":float(rung_frames)/60.,"rung_metres":distance,"end":str(actor.position)}
	if not started or motion.active:failures+=1;push_error("Ladder traversal did not finish")
	await ticks(35)
	if not actor.is_on_floor() or actor.collision_mask!=1:failures+=1;push_error("Ladder traversal lost supported landing")
	return result
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(120)
	var actor=level.actor;var ladder=level.get_node("RooftopBridgeRoute").departure.ladder
	var motion=actor.abilities.bpg_motion;var results:={}
	for pace:float in [2.45,4.8]:
		actor.reset_actor();actor.position=Vector3(ladder.climb_x,.02,0);motion.climb_rate=pace;motion.rate=1.7 if pace<3. else 2.1;await ticks(8)
		var up:Dictionary=await traverse(actor,"miko8_up")
		if absf(actor.position.y-5.2)>.05:failures+=1;push_error("Tall ladder ascent missed roof")
		var down:Dictionary=await traverse(actor,"miko8_down")
		if actor.position.y>.05:failures+=1;push_error("Tall ladder descent missed ground")
		results[str(pace)]={"up":up,"down":down};print("LADDER_PACE rate=",pace," up=",up," down=",down)
	for direction:String in ["up","down"]:
		if results["4.8"][direction].rung_seconds>=results["2.45"][direction].rung_seconds*.65:
			failures+=1;push_error("New rung pace did not measurably improve "+direction)
	print("LADDER_PACE_","PASS" if failures==0 else "FAIL"," failures=",failures)
	FileAccess.open("res://../Builds/Validation/BridgePlatforms/ladder_pace.json",FileAccess.WRITE).store_string(JSON.stringify(results,"  "))
	quit(failures)

