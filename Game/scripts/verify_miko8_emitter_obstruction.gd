extends SceneTree
func _initialize()->void:call_deferred("_run")
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	for i in range(10):await physics_frame
	actor.position.x=34.6
	actor.abilities.posed_hands={"L":Vector3(35.1,1.1,0),"R":Vector3(35.1,1.3,0)}
	actor.abilities.aim_facing=1;actor.abilities.aim_engaged=true
	assert(actor.abilities._hand_origin("L").x<34.9,"Hand emitter should not spawn through barrier")
	assert(actor.abilities._plasma_origin().x<34.8,"Plasma ball should remain on player side of barrier")
	var target=get_nodes_in_group("miko8_spell_targets")[1]
	var before:int=target.hits
	var bolt=preload("res://scripts/miko8_spell_projectile.gd").new()
	bolt.caster=actor;bolt.power=2;bolt.velocity=Vector3(18,0,0)
	level.add_child(bolt)
	bolt.global_position=Vector3(8,1.25,0)
	for i in range(12):await physics_frame
	assert(target.hits==before+1)
	print("EMITTER_OBSTRUCTION_PASS: wall-clipped hand and plasma origins, solid sphere target registers one bolt hit")
	quit()
