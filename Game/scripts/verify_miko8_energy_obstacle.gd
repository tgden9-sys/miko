extends SceneTree
var failures:=0
var checks:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("ENERGY_OBSTACLE_FAIL: "+message)
func ticks(count:int)->void:
	for frame in range(count):await physics_frame
func capture(label:String)->void:
	if "--headless" in OS.get_cmdline_args():return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/EnergyAndObstacle/"+label+".png")
func run()->void:
	var level=load("res://scenes/miko8_side_on_mockup.tscn").instantiate();root.add_child(level)
	await ticks(150)
	var actor=level.actor;var target=level.get_node("NewYardProps/Loader/ChargeTarget")
	for mode:String in ["Red","Blue","Plasma"]:
		actor.reset_actor();actor.position=Vector3(8.5,.02,0);level._camera(0,true);await ticks(15)
		var before:int=target.polarity
		var action:String="miko8_spell_single" if mode=="Red" else "miko8_spell_blue" if mode=="Blue" else "miko8_spell_double"
		Input.action_press(action);await ticks(100)
		if mode=="Plasma":
			# Plasma remains free-aimed; aim down at the lower loader receiver.
			actor.abilities.aim_elevation=-.20;actor.abilities.target_aim_elevation=-.20
			await ticks(8)
		check(target.polarity==before,"Held "+mode+" guide must not change the target")
		check(get_nodes_in_group("miko8_energy_bolts").is_empty(),"Holding must not emit projectiles")
		check(actor.abilities.lasers.hand_orbs[mode].visible,"Held "+mode+" orb must be visible")
		check(actor.abilities.lasers.lines.C.visible if mode=="Plasma" else actor.abilities.lasers.lines.L.visible,"Held orb must retain a guide line")
		await capture(mode.to_lower()+"_held")
		Input.action_release(action);await ticks(5)
		check(get_nodes_in_group("miko8_energy_bolts").size()==1,"Release must create one travelling "+mode+" orb")
		check(target.polarity==before,"Release must not recolour before contact")
		await capture(mode.to_lower()+"_released")
		await ticks(60)
		var expected:int=1 if mode=="Red" else 2 if mode=="Blue" else 0
		check(target.polarity==expected,"Actual "+mode+" collision must apply the right state")
		check(get_nodes_in_group("miko8_energy_bolts").is_empty(),"Impact must consume the projectile")
	# Place a real wall between the hand and loader: neither assist nor shots pass it.
	var wall:=StaticBody3D.new();var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new()
	shape.size=Vector3(.2,2.5,3);collision.shape=shape;wall.add_child(collision);wall.position=Vector3(10.3,1.25,0);level.add_child(wall)
	actor.reset_actor();actor.position=Vector3(8.5,.02,0);await ticks(15)
	Input.action_press("miko8_spell_single");await ticks(95)
	check(actor.abilities.locked_target==null,"Solid wall must block aim assistance")
	Input.action_release("miko8_spell_single");await ticks(50)
	check(target.polarity==0,"Solid wall must stop the colour projectile")
	wall.queue_free();await ticks(3)
	# Actual input-driven unaided jump into the new building.
	var obstacle=level.get_node("ServiceBlockObstacle")
	var roof:float=obstacle.to_global(Vector3(0,obstacle.HEIGHT*obstacle.height_scale-1.25,0)).y
	var wall_ray:=PhysicsRayQueryParameters3D.create(Vector3(50,1.,0),Vector3(56,1.,0),1)
	wall_ray.exclude=[actor.get_rid()]
	var wall_hit:Dictionary=level.get_world_3d().direct_space_state.intersect_ray(wall_ray)
	actor.reset_actor();actor.position=Vector3(50.5,.02,0);level._camera(0,true);await ticks(12)
	await capture("service_block_approach")
	Input.action_press("miko8_right",.65);Input.action_press("miko8_jump")
	var peak:=0.0
	for frame in range(100):
		await physics_frame;peak=maxf(peak,actor.position.y)
	Input.action_release("miko8_jump");Input.action_release("miko8_right");await ticks(20)
	check(peak<roof-1.0,"Normal jump must be substantially below the roof")
	check(wall_hit.get("collider")==obstacle and actor.position.x<float(wall_hit.get("position",Vector3.ZERO).x)-.05 and actor.is_on_floor(),"The service block must stop MIKO's actual jump/movement")
	print("OBSTACLE_UNAIDED_JUMP peak=",peak," end=",actor.position)
	# Its roof is usable geometry, not just a backdrop or tall trigger.
	actor.reset_actor();actor.position=Vector3(54.5,roof+.05,0);level._camera(0,true);await ticks(20)
	check(actor.is_on_floor() and absf(actor.position.y-roof)<.04,"Roof must support MIKO")
	Input.action_press("miko8_right",.35);await ticks(90);Input.action_release("miko8_right");await ticks(5)
	check(actor.is_on_floor() and actor.position.x>55.5,"MIKO must be able to walk on the roof")
	await capture("service_block_roof")
	# The building itself is a compatible receiver for colour shots.
	actor.reset_actor();actor.position=Vector3(51.6,.02,0);await ticks(15)
	Input.action_press("miko8_spell_blue");await ticks(100)
	check(actor.abilities.locked_target==obstacle,"The building receiver must support targeting")
	Input.action_release("miko8_spell_blue");await ticks(50)
	check(obstacle.polarity==2,"The building receiver must turn blue on contact")
	level._camera(0,true);await capture("service_block_charged")
	print("ENERGY_OBSTACLE_", "PASS" if failures==0 else "FAIL", " checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)

