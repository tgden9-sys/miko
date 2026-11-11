extends SceneTree
const OUT:="res://../Builds/Validation/NetworkTransfer/"
func _initialize()->void:call_deferred("_run")
func _ticks(count:int)->void:
	for i in range(count):await physics_frame
func _capture(level:Node3D,label:String,close:bool)->void:
	level.set_process(false)
	level.visibility_budget.set_process(false)
	if close:
		level.camera.size=4.2
		level.camera.global_position=level.actor.global_position+Vector3(.48,1.2,0)+level.camera.global_basis.z*18.
		level.camera.set_meta("walkway_focus_x",level.actor.position.x);level.visibility_budget.refresh()
	else:level._camera(0,true)
	await _ticks(4);await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+label+".png"))
	print("CAPTURE ",label)
	level.set_process(true)
func _run()->void:
	var level:=load("res://scenes/miko8_level_02.tscn").instantiate() as Node3D
	root.add_child(level);current_scene=level
	var relay:Node3D=level.transfer_relays[0]
	level.actor.reset_actor();level.actor.position=Vector3(74.12,.02,0)
	level.elapsed=3.;level.fade.color.a=0.;level._camera(0,true)
	await _ticks(90)
	await _capture(level,"01_ready_game",false)
	await _capture(level,"02_ready_detail",true)
	if not relay.activate():push_error("REVIEW could not activate relay");quit(1);return
	while relay.stage!=relay.Stage.DEPART:await physics_frame
	relay.set_physics_process(false)
	await _capture(level,"03_contact_detail",true)
	var finger:Vector3=level.actor.skeleton.to_global(level.actor.skeleton.get_bone_global_pose(level.actor.skeleton.find_bone("DEF-f_index.03.L")).origin)
	print("CONTACT finger=",finger," glyph=",relay.effect.glyph.global_position," error=",finger.distance_to(relay.effect.glyph.global_position))
	relay.set_physics_process(true)
	while relay.dissolve<.45:await physics_frame
	relay.set_physics_process(false)
	await _capture(level,"04_departure_detail",true)
	await _capture(level,"05_departure_game",false)
	relay.set_physics_process(true)
	while current_scene==level or not is_instance_valid(current_scene):await process_frame
	var destination:Node3D=current_scene
	var arrival:Node3D=destination.transfer_relays.back()
	while arrival.dissolve>.55:await physics_frame
	arrival.set_physics_process(false)
	await _capture(destination,"06_arrival_detail",true)
	arrival.set_physics_process(true)
	while not destination.actor.ready_for_input:await physics_frame
	await _capture(destination,"07_arrived_game",false)
	print("TRANSFER_REVIEW_COMPLETE")
	quit()
