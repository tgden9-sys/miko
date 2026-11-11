extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	for offset in [-0.5,0.5]:
		level._go_to_ladder()
		actor.position.x+=offset
		await ticks(4)
		Input.action_press("miko8_up")
		await ticks(10)
		assert(actor.state=="ClimbAlign" and actor.current_clip=="Walk")
		assert(absf(actor.position.x-18.0)>0.1)
		await ticks(46)
		assert(absf(actor.position.x-18.0)<0.001)
		assert(actor.current_clip=="StockLadderUp")
		var y:float=actor.position.y
		await ticks(20)
		var rise:float=actor.position.y-y
		assert(rise>0.33 and rise<0.41,"Climb travel should be about 1.1 m/s")
		Input.action_release("miko8_up")
		await ticks(4)
		Input.action_press("miko8_down")
		var before:float=actor.position.y
		await ticks(20)
		assert(before-actor.position.y>0.33)
		Input.action_release("miko8_down")
		actor.reset_actor()
	var ladder:Node3D=get_nodes_in_group("miko8_ladders")[0]
	assert(absf(ladder.top_y-3.2)<0.001)
	assert(ladder.above_platform>=1.4)
	print("FAST_LADDER_ALIGNMENT_PASS: approaches from both sides finish walking before climb; up/down 3x; rails extend 1.5m above unchanged platform height")
	quit()
