extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error("YARD_LIFE_FAIL "+message)
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/Atmosphere/"+label+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level);await ticks(120)
	var actor=level.actor;var air=level.atmosphere;var life=air.yard_life
	var far:ShaderMaterial=level.layered_scenery.city_card.material_override
	check(is_equal_approx(level.layered_scenery.brightness,.5) and is_equal_approx(far.get_shader_parameter("brightness"),.5),"Scenery default must be 50 percent")
	check(level.game_size.get_parent().find_child("SceneryBrightness",true,false).value==50.,"Slider must match saved default")
	check(life.vents.size()==5 and life.beacons.size()==3 and life.terminals.size()==2,"Environmental sources must be installed")
	check(life.hardware.find_children("*","CollisionObject3D",true,false).is_empty(),"Atmosphere hardware must not obstruct the route")
	check(not level.has_node("MikoEnergyWake") and actor.polarity_control.graphic_materials[0].shader.resource_path=="res://shaders/miko8_three_tone.gdshader","Preserve MIKO shading and no trails")
	actor.reset_actor();actor.position=Vector3(18.3,.02,0);level._camera(0,true);await ticks(10)
	life.elapsed=2.;life._update();await capture("yard_life_ground")
	level.atmosphere_toggle.button_pressed=false;await ticks(3)
	var clock:float=life.elapsed;await ticks(12)
	check(not air.visible and not life.is_processing() and is_equal_approx(life.elapsed,clock),"Atmosphere toggle must pause and hide effects")
	check(life.hardware.visible,"Physical fixtures must remain with atmosphere off")
	for sound:AudioStreamPlayer3D in life.sounds:check(not sound.playing,"Toggle must stop local sound")
	await capture("yard_life_off")
	level.atmosphere_toggle.button_pressed=true;await ticks(5)
	check(air.visible and life.is_processing(),"Effects must resume")
	actor.reset_actor();actor.position=Vector3(37.3,5.22,-.81807);actor.walk_plane_z=-.81807;actor.walk_plane_floor_y=5.2;level._camera(0,true);await ticks(15)
	life.elapsed=3.5;life._update();check(life.steam.visible_instance_count>0,"Vent puffs must be visible")
	await capture("yard_life_bridge")
	var previous:Color=life.beacons[0].lens.albedo_color;life.elapsed+=.75;life._update()
	check(previous!=life.beacons[0].lens.albedo_color,"Beacon lens must animate")
	var unit:Dictionary=life.terminals[1];life.elapsed=float(unit.period)-float(unit.phase)+.04;life._update()
	check(life.arc_mesh.get_surface_count()==1,"Local electrical arc must render during its event")
	life.elapsed+=.22;life._update();check(life.flecks.visible_instance_count>0,"Arc must shed brief sparks")
	life.sounds[0].play();level.set_ambience_muted(true);life._update();await ticks(2)
	check(level.audio.volume_db<=-79.,"Mute must cover the looping ambient bed")
	for sound:AudioStreamPlayer3D in life.sounds:check(sound.volume_db<=-79.,"Mute must cover active or queued local audio")
	level.set_ambience_muted(false);life._update()
	for sound:AudioStreamPlayer3D in life.sounds:check(is_equal_approx(sound.volume_db,float(sound.get_meta("base_volume_db"))),"Unmute must restore local sound gain")
	level.layered_scenery.set_brightness(.65);check(is_equal_approx(far.get_shader_parameter("brightness"),.65),"Brightness remains adjustable")
	level.layered_scenery.set_brightness(.5)
	check(actor.is_on_floor() and absf(actor.position.y-5.2)<.05,"Bridge remains playable")
	print("YARD_LIFE_","PASS" if failures==0 else "FAIL"," failures=",failures," steam_pool=",life.steam.instance_count," spark_pool=",life.flecks.instance_count)
	quit(failures)
