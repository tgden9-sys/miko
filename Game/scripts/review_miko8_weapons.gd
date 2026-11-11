extends SceneTree
var failures:=0
const OUT:="res://../Builds/Validation/Weapons/"
func _initialize()->void:call_deferred("_run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func check(ok:bool,label:String)->void:
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:failures+=1
func capture(label:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+label+".png"))
func _run()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var level:Node3D=load("res://scenes/miko8_level_02.tscn").instantiate()
	root.add_child(level);current_scene=level
	var actor:CharacterBody3D=level.actor
	actor.reset_actor();actor.position=Vector3(71.,.02,0)
	await ticks(90)
	level.set_process(false);level.visibility_budget.set_process(false)
	level.camera.size=4.5
	level.camera.global_position=Vector3(72.3,1.15,0)+level.camera.global_basis.z*18.
	level.camera.set_meta("walkway_focus_x",72.3);level.visibility_budget.refresh()
	var ability:Node=actor.abilities
	Input.action_press("miko8_spell_double")
	await ticks(65)
	check(ability.lasers.plasma_ball.visible,"R2 plasma charges between hands")
	await capture("01_plasma_hold")
	level._camera(0,true)
	await capture("01b_plasma_game")
	level.camera.size=4.5
	level.camera.global_position=Vector3(72.3,1.15,0)+level.camera.global_basis.z*18.
	var before:int=ability.shots_fired
	Input.action_release("miko8_spell_double")
	await ticks(7)
	check(ability.shots_fired==before+1,"Releasing plasma fires once")
	await capture("02_plasma_flight")
	var impact:Node3D=ability.projectile_pool.spawn_impact(Vector3(73.,.8,0),Color("b366ff"))
	await ticks(4)
	check(impact.nova.visible,"Plasma impact has a dedicated expanding flash")
	await capture("03_plasma_impact")
	await ticks(140)
	before=ability.shots_fired
	var trigger:=InputEventJoypadMotion.new()
	trigger.device=0;trigger.axis=JOY_AXIS_TRIGGER_LEFT;trigger.axis_value=1.
	Input.parse_input_event(trigger)
	Input.action_press("miko8_right",.35)
	var start_x:=actor.position.x
	await ticks(8)
	check(ability.shots_fired==before+1 and ability.laser_mode=="Green","L2 launches a quick green shot")
	await capture("04_green_flight")
	await ticks(16)
	check(ability.shots_fired==before+1,"Second shot waits half a second")
	await ticks(12)
	check(ability.shots_fired==before+2,"Holding L2 fires the second bolt")
	await ticks(30)
	check(ability.shots_fired==before+3,"Held fire keeps its half-second cadence")
	check(actor.position.x>start_x+.7 and actor.current_clip=="Walk" and ability.quick_pose_weight>.99,"Walking gait continues with the firing arm held up")
	trigger=InputEventJoypadMotion.new()
	trigger.device=0;trigger.axis=JOY_AXIS_TRIGGER_LEFT;trigger.axis_value=0.
	Input.parse_input_event(trigger)
	Input.action_release("miko8_right")
	await ticks(40)
	check(ability.shots_fired==before+3 and ability.quick_pose_weight==0.,"Releasing L2 stops shots and lowers the arm")
	Input.action_press("miko8_quick_blaster")
	await ticks(8)
	Input.action_release("miko8_quick_blaster")
	check(ability.shots_fired==before+4,"Keyboard fire shares the held blaster")
	await ticks(30)
	var crate:Node3D=level.get_node("Level2Platforms/SwitchTestCrate")
	crate.freeze=true;crate.lock_in_color(Color.RED)
	var pool:Node=ability.projectile_pool
	var bolt:Node3D=pool.spawn_bolt(actor,crate.global_position+Vector3(-1.,0,0),Vector3(19.4,0,0),"Green",1)
	await ticks(30)
	check(crate.polarity==1,"Green bolts do not recolour or neutralise magnetic crates")
	pool.spawn_bolt(actor,crate.global_position+Vector3(-1.,0,0),Vector3(18.,0,0),"Plasma",2)
	await ticks(30)
	check(crate.polarity==0,"Plasma still neutralises crates on actual collision")
	var target:Area3D=load("res://scripts/miko8_spell_target.gd").new()
	target.position=Vector3(74.,1.,0)
	level.add_child(target)
	pool.spawn_bolt(actor,Vector3(72.5,1.,0),Vector3(19.4,0,0),"Green",1)
	await ticks(30)
	check(target.hits==1,"A quick bolt hits a damage receiver exactly once")
	target.queue_free()
	bolt=pool.spawn_bolt(actor,Vector3(72.,1.,0),Vector3(18.,0,0),"Plasma",2)
	check(bolt.orb.visible and bolt.orb.corona.visible and bolt.wake.visible,"Reusing a green projectile restores plasma visuals")
	pool.recycle_bolt(bolt)
	bolt=pool.spawn_bolt(actor,Vector3(72.,1.,0),Vector3(14.,0,0),"Blue",1)
	check(bolt.orb.visible and not bolt.orb.corona.visible and not bolt.wake.visible,"Reusing plasma restores the blue charge shot")
	pool.recycle_bolt(bolt)
	# Exercise the real breakable model and collision with each weapon.
	var props:Node3D=load("res://scripts/miko8_yard_props.gd").new()
	level.add_child(props)
	var wood:StaticBody3D=props._prop("WoodenCrate","res://models/props/wooden_crate.glb",Vector3(74.,0,0),Vector3(.8,.8,.8))
	level.get_node("CelSceneArt").convert_debris(wood)
	for mode:String in ["Red","Blue"]:
		pool.spawn_bolt(actor,Vector3(72.5,.4,0),Vector3(19.4,0,0),mode,1)
		await ticks(30)
		check(not wood.broken,mode+" charging shot leaves wood intact")
	pool.spawn_bolt(actor,Vector3(72.5,.4,0),Vector3(19.4,0,0),"Green",1)
	await ticks(9)
	check(wood.broken and wood.collision_layer==0,"Green bolt destroys wood and removes its collision")
	var debris:Array[Node]=get_nodes_in_group("miko8_crate_debris")
	check(debris.size()==1,"One green impact creates one breakup")
	if not debris.is_empty():
		check(debris[0].energy_tint.g>debris[0].energy_tint.b,"Green destruction uses a green impact flash")
		check(debris[0].pieces.size()==12,"Green destruction uses the textured wooden fragments")
	await capture("05_green_destruction")
	wood.receive_blaster(1,wood.global_position,Vector3.RIGHT)
	check(get_nodes_in_group("miko8_crate_debris").size()==1,"Repeated hits cannot break the same crate twice")
	wood.reset_crate()
	await ticks(2)
	check(not wood.broken and wood.collision_layer==1,"Reset restores the wooden crate")
	pool.spawn_bolt(actor,Vector3(72.5,.4,0),Vector3(18.,0,0),"Plasma",2)
	await ticks(12)
	check(wood.broken,"Plasma still destroys the reset crate")
	await ticks(250)
	check(get_nodes_in_group("miko8_crate_debris").is_empty(),"Destruction debris cleans up")
	print("WEAPON_REVIEW_RESULT failures=",failures)
	quit(failures)
