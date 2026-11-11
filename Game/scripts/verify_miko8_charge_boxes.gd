extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(20)
	Input.action_press("miko8_spell_single")
	await ticks(100)
	var box=actor.abilities.locked_target
	assert(is_instance_valid(box) and box.position.x>0 and box.is_locked_on)
	assert(box.polarity==0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/box_lock.png")
	Input.action_release("miko8_spell_single")
	await ticks(25)
	assert(box.polarity==1 and not box.is_locked_on)
	Input.action_press("miko8_spell_blue")
	await ticks(100)
	assert(actor.abilities.locked_target==box)
	Input.action_release("miko8_spell_blue")
	await ticks(25)
	assert(box.polarity==2)
	box.freeze=true
	box.position.x=7.0
	await ticks(3)
	Input.action_press("miko8_spell_single")
	await ticks(95)
	assert(not is_instance_valid(actor.abilities.locked_target),"Targets outside 200px reach must not lock")
	Input.action_release("miko8_spell_single")
	await ticks(25)
	box.position=Vector3(3,0.42,0)
	box.neutralize()
	await ticks(3)
	box.lock_in_color(Color.BLUE)
	box.freeze=false
	actor.polarity_control.set_polarity(1)
	var start:float=box.position.x
	await ticks(40)
	print("ATTRACT ",start," -> ",box.position.x," velocity ",box.linear_velocity," pole ",box.polarity," suit ",actor.suit_polarity)
	assert(box.position.x<start-0.02,"Opposite suit polarity should attract")
	actor.polarity_control.set_polarity(2)
	start=box.position.x
	box.linear_velocity=Vector3.ZERO
	await ticks(40)
	print("REPEL ",start," -> ",box.position.x," velocity ",box.linear_velocity," pole ",box.polarity," suit ",actor.suit_polarity)
	assert(box.position.x>start+0.02,"Matching suit polarity should repel")
	actor.polarity_control.set_polarity(0)
	box.neutralize()
	assert(box.polarity==0)
	print("CHARGE_BOX_PASS: 200px-equivalent visible forward lock, release red/blue charge, out-of-range rejection, opposite attraction, matching repulsion, neutralization")
	quit()

