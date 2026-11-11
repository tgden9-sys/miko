extends SceneTree
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func run()->void:
	var level=load("res://scenes/miko8_tutorial.tscn").instantiate();root.add_child(level)
	var actor=level.actor
	await ticks(140)
	assert(actor.state=="GroundSitIdle" and actor.is_on_floor())
	assert(level.get_node("PaintedGroundKit").pieces.size()==4)
	var crate=level.get_node("TutorialChargeCrate")
	assert(crate.freeze and absf(crate.position.x-28)<0.01)
	Input.action_press("miko8_right",0.35)
	await ticks(145)
	assert(actor.current_clip=="Walk" and actor.head_offset.blend_weight==1)
	var crossed:=[false,false,false]
	var last_x:float=actor.position.x
	for i in range(2300):
		await physics_frame
		assert(absf(actor.position.y)<0.035,"Continuous walking deck must have no drop or raised join")
		for j in range(3):
			if last_x<float((j+1)*8) and actor.position.x>=float((j+1)*8):crossed[j]=true
		last_x=actor.position.x
		if actor.state=="WallBlocked":break
	Input.action_release("miko8_right");await ticks(20)
	assert(crossed.all(func(v):return v),"Walk across all three module boundaries and bridge without jumping")
	assert(actor.position.x>27.0 and actor.position.x<27.5,"Crate must stop walking")
	assert(not level.completed and level.phase==2)
	Input.action_press("miko8_right",0.65);actor._begin_jump()
	await ticks(100)
	Input.action_release("miko8_right");await ticks(30)
	assert(actor.position.x>29.2 and actor.is_on_floor(),"One jump must clear crate and land on the same floor")
	assert(level.completed and level.phase==3)
	await level._restart(true);await ticks(10)
	assert(actor.state=="GroundSitIdle" and level.phase==0 and not level.completed)
	assert(absf(actor.position.x-2.4)<0.01 and actor.is_on_floor())
	print("GROUND_COURSE_PASS: wake/head offset, continuous floor through three joins and bridge, real crate blocking, jump clearance, completion, reset")
	quit()
