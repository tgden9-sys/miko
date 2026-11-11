extends SceneTree
func _initialize()->void:call_deferred("_run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func capture(name:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/"+name+".png")
func hits()->int:
	var count:=0
	for target in get_nodes_in_group("miko8_spell_targets"):count+=target.hits
	return count
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	await ticks(15)
	var before:=hits()
	for mode:String in ["miko8_spell_single","miko8_spell_blue"]:
		Input.action_press(mode)
		await ticks(90)
		assert(hits()==before)
		Input.action_release(mode)
		await ticks(25)
		assert(hits()==before and get_nodes_in_group("miko8_plasma_bolts").is_empty())
	Input.action_press("miko8_spell_double")
	await ticks(100)
	await process_frame
	await RenderingServer.frame_post_draw
	var beams=actor.abilities.lasers
	assert(beams.lines.C.visible and beams.plasma_ball.visible)
	assert(not beams.lines.L.visible and not beams.lines.R.visible)
	var midpoint:Vector3=actor.abilities._plasma_origin()
	assert(beams.plasma_ball.global_position.distance_to(midpoint)<0.001)
	assert(beams.lines.C.material_override.albedo_color.a<0.55)
	assert(hits()==before)
	await capture("fine_plasma_guides")
	Input.action_release("miko8_spell_double")
	await ticks(6)
	assert(get_nodes_in_group("miko8_plasma_bolts").size()==1)
	assert(hits()==before,"Plasma must travel to its target")
	await capture("plasma_bolt_release")
	await ticks(70)
	assert(hits()==before+1,"One travelling bolt must hit once")
	assert(get_nodes_in_group("miko8_plasma_bolts").is_empty())
	print("PLASMA_GUIDES_PASS: held plasma ball between hands with one central targeting line, no guide damage, one travelling bolt on release and one collision hit")
	quit()
