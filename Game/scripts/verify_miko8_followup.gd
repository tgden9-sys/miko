extends SceneTree
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func run()->void:
	var level=load("res://scenes/miko8_tutorial.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(140)
	assert(actor.state=="GroundSitIdle" and actor.head_offset.blend_weight==0)
	Input.action_press("miko8_right",0.35)
	var before:=0.0
	var saw_exit:=false
	var max_step:=0.0
	for i in range(200):
		await physics_frame
		if actor.state=="GroundSitExit":
			saw_exit=true
			var weight:float=actor.head_offset.blend_weight
			assert(weight+0.00001>=before)
			max_step=maxf(max_step,weight-before)
			before=weight
		elif saw_exit:break
	assert(saw_exit and before>0.99 and max_step<0.03)
	assert(actor.head_offset.blend_weight==1 and actor.head_offset.active)
	Input.action_release("miko8_right")
	await ticks(35)
	# Native frustum culling is supplemented by an explicit visual/activity budget.
	var dummy:=MeshInstance3D.new()
	var box:=BoxMesh.new();box.size=Vector3.ONE
	dummy.mesh=box;dummy.position=Vector3(100,1,0)
	dummy.add_to_group("miko8_budget_visual")
	dummy.set_meta("budget_half_width",0.5)
	level.add_child(dummy)
	level.visibility_budget.refresh()
	assert(not dummy.visible)
	dummy.position.x=10
	level.visibility_budget.refresh()
	assert(dummy.visible)
	var future_enemy:=Node3D.new()
	future_enemy.position=Vector3(100,1,0)
	level.add_child(future_enemy)
	future_enemy.add_to_group("miko8_budget_actor")
	level.visibility_budget.refresh()
	assert(future_enemy.process_mode==Node.PROCESS_MODE_DISABLED and not future_enemy.visible)
	future_enemy.position.x=10
	level.visibility_budget.refresh()
	assert(future_enemy.process_mode==Node.PROCESS_MODE_INHERIT and future_enemy.visible)
	assert(level.scene_presence.air.visible_instance_count>10 and level.scene_presence.air.visible_instance_count<level.scene_presence.AIR_COUNT)
	var crate=level.get_node("TutorialChargeCrate")
	assert(crate.charge_materials.size()>0)
	crate.position.x=100
	level.visibility_budget.refresh()
	assert(not crate.camera_active)
	crate.lock_in_color(Color.RED)
	var charge:float=crate.charge_remaining
	await ticks(65)
	assert(crate.charge_remaining<charge-0.8,"Offscreen charge expiry must keep ticking")
	crate.neutralize()
	crate.position.x=28
	actor.position=Vector3(29.3,0.02,0)
	level._camera(0,true)
	level.visibility_budget.refresh()
	assert(crate.camera_active and crate.display_root.visible)
	# The non-tileable picture's ends never enter a legal camera view.
	var viewport:Vector2=level.camera.get_viewport().get_visible_rect().size
	var half_width:float=level.camera.size*viewport.x/viewport.y/2
	for player_x:float in [2.4,16.0,29.3]:
		actor.position.x=player_x
		level._camera(0,true)
		for card:MeshInstance3D in level.parallax[4].node.get_children():
			assert(card.global_position.x-card.mesh.size.x/2<level.camera.global_position.x-half_width-0.2)
			assert(card.global_position.x+card.mesh.size.x/2>level.camera.global_position.x+half_width+0.2)
	print("FOLLOWUP_PASS: smooth seated head lift max weight step=",max_step,"; offscreen visuals/AI opt-in, charge expiry, air compaction, real crate, continuous foreground")
	quit()

