extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(15)
	# Approach the floating target, each step/platform face and both end barriers.
	for item in [[10.0,8.3,1],[12.0,10.6,1],[22.0,20.6,1],[-12.0,-10.4,-1],[35.0,33.0,1],[-35.0,-33.0,-1]]:
		actor.reset_actor()
		actor.position.x=item[1]
		actor.facing=item[2]
		actor.visual.rotation.y=item[2]*PI/2
		await ticks(8)
		var action:String="miko8_right" if item[2]>0 else "miko8_left"
		Input.action_press(action)
		await ticks(100)
		assert(actor.state=="WallBlocked" and actor.current_clip=="Idle","Does not stop at solid object "+str(item[0]))
		var position_value:Vector3=actor.position
		await ticks(20)
		assert(actor.position.distance_to(position_value)<0.002,"Continues moving through solid")
		Input.action_release(action)
	actor.reset_actor()
	await ticks(10)
	for pole in range(3):
		actor.polarity_control.set_polarity(pole)
	print("ALL_SOLIDS_PASS: target sphere, raised steps, platform sides, both end barriers stop movement and running; neutral/red/blue suit states set")
	quit()

