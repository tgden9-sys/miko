extends SceneTree
## Independent physics/projection verification; no GPU captures or image writes.
const MOCKUP_SCRIPT = preload("res://scripts/miko8_side_on_mockup.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("SIDE_ON_MOCKUP_FAIL: " + message)

func ticks(count: int) -> void:
	for frame in range(count):
		await physics_frame

func key_event(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event

func check_camera(level: MOCKUP_SCRIPT, raised: bool) -> void:
	var camera: Camera3D = level.camera
	var viewport_size := root.get_visible_rect().size
	var half_width := 15.0 * viewport_size.x / maxf(viewport_size.y, 1.0) * 0.5
	var pitch := atan(7.0 / 18.0) if raised else deg_to_rad(6.0)
	var expected_back := Vector3(0, sin(pitch), cos(pitch))
	for actor_x: float in [2.4, 32.0, 63.0]:
		level.actor.position = Vector3(actor_x, 0.02, 0)
		level._camera(0, true)
		var expected_x := clampf(actor_x + 1.5, half_width, 64.0 - half_width)
		check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL and absf(camera.size - 15.0) < 0.001, "Both camera options must retain the approved orthographic size 15")
		check(absf(camera.position.x - expected_x) < 0.001, "Camera must scroll and clamp to the 64m room")
		check(camera.global_basis.z.dot(expected_back) > 0.99999, "Camera pitch must match the selected side-on or earlier angle without horizontal yaw")
		var floor_row := camera.unproject_position(Vector3(camera.position.x, 0, 0)).y / viewport_size.y
		check(absf(floor_row - 0.80) < 0.0001, "Changing pitch must preserve the lower floor at normalized row 0.80")
		for city:MeshInstance3D in [level.layered_scenery.city_card,level.layered_scenery.city_mid_card]:
			var size:Vector2=(city.mesh as QuadMesh).size
			var minimum:=Vector2(INF,INF);var maximum:=Vector2(-INF,-INF)
			for corner:Vector2 in [Vector2(-1,-1),Vector2(-1,1),Vector2(1,-1),Vector2(1,1)]:
				var screen:=camera.unproject_position(city.to_global(Vector3(corner.x*size.x*.5,corner.y*size.y*.5,0)))
				minimum=minimum.min(screen);maximum=maximum.max(screen)
			check(minimum.x<=0 and maximum.x>=viewport_size.x and minimum.y<=0 and maximum.y>=viewport_size.y,"Both city layers must cover every route position without exposed image edges")

func check_atmosphere(level: MOCKUP_SCRIPT, enabled: bool) -> void:
	var atmosphere: Node3D = level.atmosphere
	check(level.atmosphere_toggle.button_pressed == enabled, "Atmosphere checkbox must reflect its current option")
	check(atmosphere.effects_enabled == enabled and atmosphere.visible == enabled and atmosphere.is_processing() == enabled, "Atmosphere option must control effect state, visibility and processing together")
	check(level.scene_presence.is_processing(), "Atmosphere toggle must preserve the existing general scene particles and foot contacts")
	for node in level.scene_presence.get_children():
		if node is MultiMeshInstance3D and node.multimesh==level.scene_presence.air:
			check(node.visible==enabled,"Atmosphere toggle must also control general airborne particles")

func check_reset(level: MOCKUP_SCRIPT, expected_raised: bool, expected_atmosphere: bool) -> void:
	level._unhandled_key_input(key_event(KEY_R))
	await ticks(60)
	check(not level.resetting and level.actor.is_on_floor() and level.actor.state == "GroundSitIdle", "R must finish the reset and restore the seated actor on the real floor")
	check(absf(level.actor.position.x - 2.4) < 0.01, "R must restore the original start position")
	check(level.raised_camera == expected_raised and level.game_size.selected == (1 if expected_raised else 0), "Reset must preserve the chosen camera option")
	check_atmosphere(level, expected_atmosphere)
	check_camera(level, expected_raised)

func run() -> void:
	var packed := load("res://scenes/miko8_side_on_mockup.tscn") as PackedScene
	var level: MOCKUP_SCRIPT = packed.instantiate() as MOCKUP_SCRIPT
	root.add_child(level)
	await ticks(150)
	var actor: CharacterBody3D = level.actor
	var ground: Node3D = level.get_node("OrthographicRepeatedGround")
	check(actor is CharacterBody3D and actor.skeleton is Skeleton3D and actor.model is Node3D, "MIKO must remain the animated 3D actor")
	check(actor.scale.is_equal_approx(Vector3.ONE) and absf(actor.position.z) < 0.001, "Actor scale and the physical gameplay lane must remain unchanged")
	check(actor.is_on_floor() and actor.state == "GroundSitIdle", "Mockup must begin with MIKO seated on the real deck")
	check(level.has_node("MockupRoomEnd") and level.has_node("RearServiceApron"), "Mockup must retain its physical end stop and rear visual apron")
	var floor_body := ground.get_node("ContinuousRoomFloor") as StaticBody3D
	var floor_collision := floor_body.get_child(0) as CollisionShape3D
	var floor_box := floor_collision.shape as BoxShape3D
	check(floor_box.size.is_equal_approx(Vector3(64, 0.5, 2.8)) and floor_body.position.is_equal_approx(Vector3(32, -0.25, 0)), "Extended room must have a continuous 64m physical floor")
	check(ground.modules.size() == 11 and ground.module_order[5] == "concrete", "Extended room must retain shared concrete ground modules")
	var seen_meshes: Dictionary = {}
	var retained_triangles := 0
	var forbidden_triangles := 0
	for visual: MeshInstance3D in ground.find_children("*", "MeshInstance3D", true, false):
		var mesh := visual.mesh as ArrayMesh
		if mesh == null or seen_meshes.has(mesh):
			continue
		seen_meshes[mesh] = true
		for surface in range(mesh.get_surface_count()):
			var arrays := mesh.surface_get_arrays(surface)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for offset in range(0, indices.size(), 3):
				var centre := (points[indices[offset]] + points[indices[offset + 1]] + points[indices[offset + 2]]) / 3.0
				retained_triangles += 1
				if centre.y > 0.022 and centre.z < -0.25:
					forbidden_triangles += 1
	check(retained_triangles > 1000 and forbidden_triangles == 0, "Runtime furniture trimming must remove rear posts/rails while retaining real ground geometry")
	check(not level.raised_camera and level.game_size.selected == 0, "Side-on camera must be selected by default")
	# New atmosphere is a small separate visual system, not the general air.
	var atmosphere: Node3D = level.atmosphere
	check_atmosphere(level, true)
	check(atmosphere.dust.instance_count == 40 and atmosphere.dust_node.multimesh == atmosphere.dust, "Worklight atmosphere must cover all five pictured lamps")
	check(atmosphere.floating_air.instance_count==96,"Near drifting air must cover the whole extended room")
	check(atmosphere.dust != level.scene_presence.air and atmosphere.dust != level.scene_presence.local, "Worklight motes must remain separate from existing scene-presence particles")
	check(atmosphere.cards.size() == 13, "Atmosphere must contain lamp haze, exhaust and low drifting mist")
	check(atmosphere.find_children("*", "CollisionObject3D", true, false).is_empty() and atmosphere.find_children("*", "CollisionShape3D", true, false).is_empty(), "Atmosphere must not add physics bodies or collision shapes")
	for record: Dictionary in atmosphere.cards:
		var card: MeshInstance3D = record.node
		var quad := card.mesh as QuadMesh
		var behind_actor := true
		for corner: Vector2 in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
			var point := card.to_global(Vector3(corner.x * quad.size.x * 0.5, corner.y * quad.size.y * 0.5, 0))
			behind_actor = behind_actor and point.z < 0.0
		if record.factor<1.0:check(behind_actor, "Lamp haze and exhaust must remain behind the actor plane")
	check(atmosphere.dust.visible_instance_count > 0 and atmosphere.dust.visible_instance_count <= 40, "Only nearby worklight motes should be active")
	var motes_behind_actor := true
	for index in range(atmosphere.dust.visible_instance_count):
		var transform: Transform3D = atmosphere.dust.get_instance_transform(index)
		motes_behind_actor = motes_behind_actor and atmosphere.dust_node.to_global(transform.origin).z < 0.0
	# Dummy rendering does not necessarily retain MultiMesh transform buffers.
	# Test the readback capability before asserting a GPU-buffer position.
	var readback_probe := MultiMesh.new()
	readback_probe.transform_format = MultiMesh.TRANSFORM_3D
	readback_probe.mesh = QuadMesh.new()
	readback_probe.instance_count = 1
	var known_transform := Transform3D(Basis.IDENTITY, Vector3(1, 2, -3))
	readback_probe.set_instance_transform(0, known_transform)
	if readback_probe.get_instance_transform(0).is_equal_approx(known_transform):
		check(motes_behind_actor, "Active worklight motes must remain behind the actor plane")
	else:
		print("SIDE_ON_MOTE_READBACK_UNAVAILABLE: renderer does not retain MultiMesh transform buffers; ordinary card depth and dedicated instance count are checked")
	for child in ground.get_children():
		if child is OmniLight3D:
			check(not child.visible and not child.is_in_group("miko8_budget_visual"), "Removed rear lamp furniture must not leave active native ground lights")
	var practical_lights := 0
	for child in level.get_children():
		if child is OmniLight3D:
			practical_lights += 1
	check(practical_lights == 5, "Picture-aligned practical lights must cover both halves")
	level._unhandled_key_input(key_event(KEY_F7))
	var paused_elapsed: float = atmosphere.elapsed
	await ticks(10)
	check_atmosphere(level, false)
	check(absf(atmosphere.elapsed - paused_elapsed) < 0.0001, "F7 must actually stop atmosphere animation while disabled")
	level.atmosphere_toggle.button_pressed = true
	await ticks(10)
	check_atmosphere(level, true)
	check(atmosphere.elapsed > paused_elapsed, "Checkbox must re-enable atmosphere processing")
	# Wake and actual movement in both directions, including the native turn.
	var initial_x := actor.position.x
	Input.action_press("miko8_right", 0.65)
	await ticks(ceili(actor._duration("GroundSitExit") * 60.0) + 120)
	Input.action_release("miko8_right")
	check(not actor.state.begins_with("GroundSit") and actor.position.x > initial_x + 0.5, "Right input must wake MIKO and actually move along the physical floor")
	actor.reset_actor()
	actor.position = Vector3(12, 0.02, 0)
	await ticks(5)
	Input.action_press("miko8_right", 0.65)
	await ticks(120)
	Input.action_release("miko8_right")
	await ticks(15)
	check(actor.position.x > 13.0 and actor.is_on_floor(), "MIKO must move right after wake-up")
	var right_x := actor.position.x
	Input.action_press("miko8_left", 0.65)
	await ticks(180)
	Input.action_release("miko8_left")
	await ticks(15)
	check(actor.position.x < right_x - 1.0 and actor.is_on_floor() and actor.facing == -1, "Left input must complete the turn and move MIKO left")
	# The backdrop must not alter real crate collision or jump physics.
	var crate := level.get_node("TutorialChargeCrate") as RigidBody3D
	check(crate.freeze and absf(crate.position.x - 24.0) < 0.001, "The mockup crate must be a real frozen 3D body at 24m")
	actor.reset_actor()
	actor.position = Vector3(21.5, 0.02, 0)
	await ticks(5)
	Input.action_press("miko8_right", 0.65)
	await ticks(160)
	Input.action_release("miko8_right")
	check(actor.position.x > 23.0 and actor.position.x < 23.5 and actor.state == "WallBlocked" and actor.is_on_floor(), "Crate collision must stop movement before the real 0.8m box")
	Input.action_press("miko8_right", 0.65)
	Input.action_press("miko8_jump")
	await ticks(2)
	Input.action_release("miko8_jump")
	var peak := actor.position.y
	for frame in range(120):
		await physics_frame
		peak = maxf(peak, actor.position.y)
	Input.action_release("miko8_right")
	await ticks(30)
	check(peak > 0.8 and actor.position.x > 25.0 and actor.is_on_floor(), "A real input-driven jump must clear the crate and land on the deck")
	actor.reset_actor()
	actor.position = Vector3(61, 0.02, 0)
	await ticks(5)
	Input.action_press("miko8_right", 0.65)
	await ticks(160)
	Input.action_release("miko8_right")
	check(actor.position.x > 63.5 and actor.position.x < 64.0 and actor.state == "WallBlocked", "The 64m room end must physically stop MIKO")
	check(actor.test_move(actor.global_transform, Vector3.RIGHT * 0.5), "The room end must remain solid to the actor capsule")
	for boundary:float in [32,36,42,48,54,60]:
		actor.reset_actor();actor.position=Vector3(boundary-.5,.02,0);await ticks(5)
		Input.action_press("miko8_right",.65);var grounded:=true
		for step in range(70):
			await physics_frame;grounded=grounded and absf(actor.position.y)<.04
		Input.action_release("miko8_right");await ticks(5)
		check(grounded and actor.position.x>boundary+.5,"The new route must cross the "+str(boundary)+"m join without a wall or floor gap")
	actor.reset_actor()
	check_camera(level, false)
	# Verify scroll and parallax independently from the separate coverage tests.
	var backdrop: Node3D = level.layered_scenery
	check(absf(backdrop.room_length - 64.0) < 0.001 and absf(level.scene_presence.room_length - 64.0) < 0.001, "Scenery and particles must use the doubled room length")
	check(backdrop.flat_art.size() == 2, "Near scenery must include a distinct second building collection")
	check(is_instance_valid(level.foreground) and level.foreground.pieces.size()==5,"Foreground must contain independent blurred cutouts")
	var near_record: Dictionary = backdrop.flat_art[0]
	var near_card: MeshInstance3D = near_record.mesh
	var far_card: MeshInstance3D = backdrop.city_card
	check(backdrop.city_layers_active and is_instance_valid(backdrop.city_mid_card), "Imported far and mid city assets must enable the complete separate layer pair")
	if not backdrop.city_layers_active:
		quit(1)
		return
	var mid_card: MeshInstance3D = backdrop.city_mid_card
	check(absf(near_record.factor - 0.95) < 0.001 and absf(backdrop.far_city_parallax_factor - 0.10) < 0.001 and absf(backdrop.mid_city_parallax_factor - 0.40) < 0.001, "Near, mid and far layers must use distinct 95%/40%/10% natural parallax")
	var far_material := far_card.material_override as StandardMaterial3D
	var mid_material := mid_card.material_override as StandardMaterial3D
	var far_texture: Texture2D = far_material.albedo_texture
	var mid_texture: Texture2D = mid_material.albedo_texture
	check(far_material != mid_material and far_material.get_rid().is_valid() and mid_material.get_rid().is_valid() and far_material.get_rid() != mid_material.get_rid(), "Far and mid city cards must use distinct material resources and RIDs")
	check(far_texture != mid_texture and far_texture.get_rid().is_valid() and mid_texture.get_rid().is_valid() and far_texture.get_rid() != mid_texture.get_rid(), "Far and mid city cards must use distinct texture resources and RIDs")
	check(far_texture.resource_path == backdrop.CITY_FAR_PATH and mid_texture.resource_path == backdrop.CITY_MID_PATH, "Active cards must use the newly imported separate city artwork")
	check(mid_material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and far_material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "Mid skyline must composite transparently over the opaque far city")
	var mid_image := mid_texture.get_image()
	if mid_image.is_compressed():
		mid_image.decompress()
	check(mid_image.detect_alpha() != Image.ALPHA_NONE, "Mid city texture must contain actual transparent pixels")
	check(backdrop.find_children("*", "CollisionObject3D", true, false).is_empty() and backdrop.find_children("*", "CollisionShape3D", true, false).is_empty(), "Separate city layers must not add physics")
	actor.position.x = 2.4
	level._camera(0, true)
	var left_camera_x := level.camera.position.x
	var near_left_x := near_card.global_position.x
	var far_left_x := far_card.global_position.x
	var mid_left_x := mid_card.global_position.x
	actor.position.x = 63.0
	level._camera(0, true)
	var scroll := level.camera.position.x - left_camera_x
	check(scroll > 37.0, "The camera must scroll through the full doubled room")
	check(absf(near_card.global_position.x - near_left_x - scroll * 0.05) < 0.001, "Near scenery must move through the frame at its 95% parallax factor")
	check(absf(far_card.global_position.x - far_left_x - scroll * 0.90) < 0.001, "Far city must move through the frame at its 10% parallax factor")
	check(absf(mid_card.global_position.x - mid_left_x - scroll * 0.60) < 0.001, "Mid city must move through the frame at its 40% parallax factor")
	# F6 uses the real key handler and both options survive the R reset path.
	level.atmosphere_toggle.button_pressed = false
	level._unhandled_key_input(key_event(KEY_F6))
	check(level.raised_camera and level.game_size.selected == 1, "F6 must select the earlier camera angle")
	check_camera(level, true)
	await check_reset(level, true, false)
	level._unhandled_key_input(key_event(KEY_F7))
	check_atmosphere(level, true)
	level._unhandled_key_input(key_event(KEY_F6))
	check(not level.raised_camera and level.game_size.selected == 0, "F6 must return to the six-degree side-on camera")
	await check_reset(level, false, true)
	print("SIDE_ON_MOCKUP_CHECKS ", checks, " failures=", failures, " retained_ground_triangles=", retained_triangles, " camera_scroll=", scroll, " jump_peak=", peak)
	if failures == 0:
		print("SIDE_ON_MOCKUP_PASS: 64m collision and camera route, six new floor joins, existing crate/jump, 0.80 floor row and F6, layered city coverage, two near building sections, foreground cutouts, expanded atmosphere and general-air toggle, reset persistence")
	var result := 0 if failures == 0 else 1
	level.audio.stop()
	level.audio.stream = null
	level.queue_free()
	await process_frame
	await process_frame
	quit(result)
