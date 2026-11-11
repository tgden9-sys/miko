extends SceneTree
func _initialize()->void:call_deferred("_run")
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	for i in range(15):await physics_frame
	Input.action_press("miko8_right")
	actor.velocity.x=actor._speed("Sprint")
	var start:Vector3=actor.position
	actor._begin_jump()
	var peak:=0.0
	var airborne:=false
	for i in range(100):
		await physics_frame
		peak=maxf(peak,actor.position.y-start.y)
		if actor.launched and not actor.is_on_floor():airborne=true
		if airborne and actor.landing_contact:break
	var reach:float=actor.position.x-start.x
	assert(airborne and actor.landing_contact)
	assert(reach<3.5 and reach>1.8)
	assert(peak>1.20 and peak<1.45)
	Input.action_release("miko8_right")
	print("SHORTER_JUMP_PASS range=",reach," height=",peak,"; full sprint capped at 3m/s in air")
	quit()
