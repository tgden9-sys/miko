extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(20)
	var crate:RigidBody3D
	for box in get_nodes_in_group("miko8_charge_targets"):
		assert(absf(box.position.y-0.4)<0.04,"Box floor collider mismatch")
		if box.position.x>2 and box.position.x<4:crate=box
	crate.freeze=true
	Input.action_press("miko8_right")
	await ticks(120)
	assert(actor.position.x<2.43 and actor.position.x>2.2,"Capsule must stop at the box face")
	Input.action_release("miko8_right")
	actor.reset_actor()
	actor.position=Vector3(3,2,0)
	actor.velocity=Vector3.ZERO
	actor.launched=true
	actor._state("Air")
	actor._play("JumpAir",0)
	await ticks(70)
	assert(actor.is_on_floor() and absf(actor.position.y-0.8)<0.04,"Must land on the box top")
	actor.reset_actor()
	await ticks(5)
	crate.lock_in_color(Color.BLUE)
	var bolt=preload("res://scripts/miko8_spell_projectile.gd").new()
	bolt.caster=actor;bolt.power=2;bolt.velocity=Vector3(40,0,0)
	level.add_child(bolt)
	bolt.global_position=Vector3(1.5,0.85,0)
	await ticks(8)
	assert(crate.polarity==0,"Plasma radius must catch a grazing box-top hit")
	assert(not is_instance_valid(bolt))
	level._box(Vector3(1.5,1.0,0),Vector3(0.2,2.0,1.2),Color.GRAY)
	actor.abilities._refresh_target()
	assert(not is_instance_valid(actor.abilities.locked_target),"Lock assist must not see through a wall")
	print("BOX_COLLISION_PASS: settled floor contact, body stops at box face, landing on box top, swept-volume grazing plasma impact")
	quit()

