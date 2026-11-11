extends SceneTree

var failures:=0
const OUTPUT:="res://../Builds/Validation/CrateEnergy/"

func _initialize()->void:
	call_deferred("_run")

func ticks(count:int)->void:
	for frame in range(count):
		await physics_frame

func check(value:bool,label:String)->void:
	print(("PASS " if value else "FAIL ")+label)
	if not value:failures+=1

func capture(label:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT+label+".png"))

func _run()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var level:Node3D=load("res://scenes/miko8_level_02.tscn").instantiate()
	root.add_child(level)
	current_scene=level
	var crate:RigidBody3D=level.get_node("Level2Platforms/SwitchTestCrate")
	crate.freeze=true
	level.actor.reset_actor()
	level.actor.position=Vector3(12.4,.02,0)
	await ticks(90)
	level.set_process(false)
	level.visibility_budget.set_process(false)
	level.camera.size=3.4
	level.camera.global_position=Vector3(13.6,1.0,0)+level.camera.global_basis.z*18.
	level.camera.set_meta("walkway_focus_x",14.)
	level.visibility_budget.refresh()
	await capture("01_neutral")
	var bolt:Node3D=load("res://scripts/miko8_spell_projectile.gd").new()
	level.add_child(bolt)
	bolt.configure_bolt(level.actor,Vector3(13.,.55,0),Vector3(14.,0,0),"Red",1)
	await ticks(12)
	check(crate.polarity==1,"Real laser impact starts charging")
	var impact:Vector3=crate.charge_materials[0].get_shader_parameter("charge_origin")
	check(impact.x<-.2,"Charge spread starts on the struck side")
	await capture("02_spread")
	await ticks(38)
	check(crate.polarity==1 and crate.visual_energy.distance_to(Vector2(1,0))<.001,"Red settles while physics polarity is immediate")
	await capture("03_red")
	crate.charge_at(Color.BLUE,crate.global_position+Vector3(-.4,.08,.25))
	await ticks(45)
	check(crate.polarity==2 and crate.visual_energy.distance_to(Vector2(0,1))<.001,"Blue fully replaces red")
	await capture("04_blue")
	level._camera(0,true)
	await capture("05_blue_game")
	crate.neutralize()
	check(crate.polarity==0 and crate.visual_energy.y>.9,"Neutralization removes magnetic state immediately while lights drain")
	await ticks(40)
	check(crate.visual_energy.length()<.001,"Discharge completes")
	crate.lock_in_color(Color.RED)
	await ticks(8)
	crate.lock_in_color(Color.BLUE)
	await ticks(8)
	crate.neutralize()
	await ticks(45)
	check(crate.visual_energy.length()<.001,"Interrupted charges settle correctly")
	crate.lock_in_color(Color.RED)
	await ticks(8)
	crate.reset_charge_body()
	check(crate.visual_energy.length()<.001,"Reset clears charge visuals immediately")
	var heavy:RigidBody3D=load("res://scripts/miko8_heavy_cargo.gd").new()
	heavy.position=Vector3(16,.9,0)
	heavy.freeze=true
	level.add_child(heavy)
	level.get_node("CelSceneArt").convert_debris(heavy)
	heavy.charge_at(Color.BLUE,Vector3(14.9,1.,0))
	await ticks(45)
	check(heavy.visual_energy.distance_to(Vector2(0,1))<.001,"Heavy crate uses the same completed charge")
	level.camera.size=4.6
	level.camera.global_position=Vector3(16.,1.2,0)+level.camera.global_basis.z*18.
	await capture("06_heavy_blue")
	print("CRATE_ENERGY_RESULT failures=",failures)
	quit(failures)
