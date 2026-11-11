extends SceneTree
var failures:=0
var checks:Array[String]=[]
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func check(ok:bool,label:String)->void:
	checks.append(("PASS " if ok else "FAIL ")+label)
	if not ok:failures+=1;push_error(label)
func sample(actor:Node,label:String)->void:
	if DisplayServer.get_name()!="headless":await process_frame;await RenderingServer.frame_post_draw
	var a=actor.abilities;var line:MeshInstance3D=a.lasers.lines.L
	check(line.visible and a.lasers.starts.has("L") and a.lasers.ends.has("L"),label+" guide stays active")
	if not line.visible or not a.lasers.starts.has("L"):return
	var from:Vector3=a.lasers.starts.L;var to:Vector3=a.lasers.ends.L
	check(from.is_finite() and to.is_finite() and from.distance_to(to)>.15,label+" has valid current endpoints")
	check(line.global_position.distance_to(from)<.001,label+" mesh follows its current hand origin")
	var vertices:PackedVector3Array=line.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var camera:=root.get_camera_3d();var pixel:float=camera.size/root.get_visible_rect().size.y
	check(vertices[0].distance_to(vertices[1])/pixel>1.45,label+" core is at least 1.45 screen pixels wide")
	var color:Color=line.material_override.albedo_color
	check(line.material_override.no_depth_test and line.material_override.render_priority>0,label+" renders above scenery depth")
	check((color.r>color.b if a.laser_mode=="Red" else color.b>color.r),label+" uses the current shot colour")
	if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://../Builds/Validation/Level2Props/guide_fixed_"+label.replace(" ","_")+".png")
func run()->void:
	var level=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(level);await ticks(20);level.elapsed=10.;level.fade.color.a=0.
	var actor=level.actor;var crate=level.get_node("Level2Platforms/SwitchTestCrate")
	actor.reset_actor();actor.position=Vector3(16,.02,0);actor.facing=-1;actor.target_facing=-1;actor.visual.rotation.y=-PI/2.;await ticks(8)
	var index:=0
	for action in ["miko8_spell_single","miko8_spell_blue","miko8_spell_single","miko8_spell_blue"]:
		Input.action_press(action);await ticks(35)
		await sample(actor,"hold_%d_%s"%[index,actor.abilities.laser_mode])
		# Aim freely away from the previously charged box, then return to it.
		Input.action_press("miko8_aim_up",.8);await ticks(45);Input.action_release("miko8_aim_up");await ticks(3)
		await sample(actor,"free_%d_%s"%[index,actor.abilities.laser_mode])
		for i in range(10):
			var origin:Vector3=actor.abilities._single_origin();actor.abilities.aim_elevation=atan2(crate.position.y+.15-origin.y,absf(crate.position.x-origin.x));actor.abilities.target_aim_elevation=actor.abilities.aim_elevation;await ticks(3)
		await sample(actor,"target_%d_%s"%[index,actor.abilities.laser_mode])
		Input.action_release(action);await ticks(45)
		check(crate.polarity==(1 if action=="miko8_spell_single" else 2),"Shot %d actually changes the crate charge"%index)
		check(not actor.abilities.lasers.lines.L.visible and actor.abilities.lasers.starts.is_empty(),"Shot %d clears its previous guide"%index)
		index+=1
	if DisplayServer.get_name()!="headless":
		Input.action_press("miko8_spell_blue");await ticks(35);Input.action_press("miko8_aim_up",.8);await ticks(40);Input.action_release("miko8_aim_up")
		# A painted card in front of the entire shot reproduces the scenery
		# occlusion independently of charge state or beam thickness.
		var card:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(15,8);card.mesh=quad;card.position=Vector3(10,3,3)
		var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.albedo_color=Color(.08,.10,.16,1.);card.material_override=material;level.add_child(card)
		await process_frame;await RenderingServer.frame_post_draw
		var screenshot:=root.get_texture().get_image();var a=actor.abilities;var point:Vector2=root.get_camera_3d().unproject_position(a.lasers.starts.L.lerp(a.lasers.ends.L,.25))
		point*=Vector2(screenshot.get_width(),screenshot.get_height())/root.get_visible_rect().size
		var visible_pixels:=0
		for x in range(-3,4):
			for y in range(-3,4):
				var color:=screenshot.get_pixel(clampi(int(point.x)+x,0,screenshot.get_width()-1),clampi(int(point.y)+y,0,screenshot.get_height()-1))
				if color.b>.25 and color.b>color.r*1.4:visible_pixels+=1
		check(visible_pixels>0,"Rendered blue guide remains visible over an intervening scenery card")
		screenshot.save_png("res://../Builds/Validation/Level2Props/guide_over_scenery.png");Input.action_release("miko8_spell_blue");card.queue_free()
	var result:={"failures":failures,"checks":checks};FileAccess.open("res://../Builds/Validation/Level2Props/repeat_guides.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "));print(JSON.stringify(result,"  "));quit(0 if failures==0 else 1)
