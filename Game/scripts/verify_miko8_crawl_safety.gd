extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(15)
	var event:=InputEventJoypadButton.new()
	event.device=0;event.button_index=JOY_BUTTON_LEFT_STICK;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events()
	await ticks(int(actor._duration("CrawlEnter")*60)+10)
	event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
	assert(actor.state=="Crawl")
	var roof:=StaticBody3D.new()
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(3,0.2,2)
	collision.shape=shape
	roof.add_child(collision)
	roof.position=actor.position+Vector3(0,0.9,0)
	level.add_child(roof)
	await ticks(3)
	assert(not actor.reactions._can_stand())
	actor.reactions.toggle_crawl=true
	await ticks(5)
	assert(actor.state=="Crawl" and actor.reactions.crouched)
	roof.queue_free()
	await ticks(3)
	assert(actor.reactions._can_stand())
	actor.reactions.toggle_crawl=true
	await ticks(int(actor._duration("CrawlExit")*60)+10)
	assert(actor.state=="Locomotion" and actor.body_collision.rotation.is_zero_approx())
	assert(absf(actor.body_collision.shape.height-1.8)<0.001)
	actor.reactions.take_hit("HitKnockback")
	await ticks(70)
	assert(actor.state=="HitDown")
	var time:float=actor.animation_player.current_animation_position
	await ticks(20)
	assert(actor.state=="HitDown" and absf(actor.animation_player.current_animation_position-time)<0.001)
	actor.reset_actor()
	assert(actor.head_offset.active and actor.animation_player.speed_scale==1)
	print("CRAWL_SAFETY_PASS: real L3 input, low collider, overhead stand rejection, clear stand/collider restore, knockdown final-pose hold, reset")
	quit()
