extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(15)
	actor.reactions.toggle_crawl=true
	await ticks(90)
	assert(actor.state=="Crawl","Entry should complete in about 1.42s")
	Input.action_press("miko8_right",0.5)
	var start:float=actor.position.x
	await ticks(30)
	assert(actor.position.x-start>0.29 and actor.position.x-start<0.38)
	Input.action_release("miko8_right")
	actor.reactions.toggle_crawl=true
	await ticks(85)
	assert(actor.state=="Locomotion")
	actor.reactions.die(1)
	await ticks(10)
	level._request_reset()
	assert(level.resetting and actor.state=="Dead")
	await create_timer(0.1).timeout
	assert(actor.state=="Dead","Reset must not snap straight to standing")
	await create_timer(0.85).timeout
	assert(not level.resetting and actor.state=="Locomotion" and actor.is_physics_processing())
	print("CRAWL_RESET_TIMING_PASS: crawl movement and enter/exit 1.5x; .82s reset fade/pause with control restored")
	quit()

