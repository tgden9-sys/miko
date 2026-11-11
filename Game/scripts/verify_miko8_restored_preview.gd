extends SceneTree
## Physics and projection checks only. This verifier never saves screenshots.
const LEVEL_SCRIPT = preload("res://scripts/miko8_ortho_repetition.gd")
const MINIATURE_FACADE = preload("res://scripts/miko8_miniature_facade.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("RESTORED_PREVIEW_FAIL: " + message)

func ticks(count: int) -> void:
	for frame in range(count):
		await physics_frame

func run() -> void:
	var scene := load("res://scenes/miko8_ortho_repetition.tscn") as PackedScene
	var level: LEVEL_SCRIPT = scene.instantiate() as LEVEL_SCRIPT
	root.add_child(level)
	await ticks(150)
	var ground: Node3D = level.get_node("OrthographicRepeatedGround")
	var actor: CharacterBody3D = level.actor
	var camera: Camera3D = level.camera
	var enhanced := level._enhanced_art()
	var continuous_yard := enhanced and not ("--keep-bridge" in OS.get_cmdline_user_args())
	var expected_fronts := 10 if continuous_yard else 9
	var expected_default_size := 15.0 if enhanced and not ("--original-view" in OS.get_cmdline_user_args()) else 11.25
	if "--wide-view" in OS.get_cmdline_user_args():
		expected_default_size = 15.0
	check(absf(camera.size - expected_default_size) < 0.001, "Enhanced preview must default to the approved wide view; original-view and baseline retain the original size")
	check(level._continuous_yard() == continuous_yard and ground.continuous_yard == continuous_yard, "Continuous yard must be the enhanced default, with the original bridge preserved for keep-bridge and baseline")
	check(ground.modules.size() == 10, "The route must contain ten native modules")
	check(ground.module_order.size() == 10, "The active route must contain ten module entries")
	check(not ground.clean_style and not ground.diorama_style, "Cel and diorama conversions must remain disabled")
	var shared_front: ShaderMaterial
	var fronts := 0
	var baseline_fronts: Dictionary = {}
	for index in range(10):
		var expected_kind := "bridge" if index == 5 and not continuous_yard else "concrete"
		check(ground.module_order[index] == expected_kind, "Active module order must match the selected continuous or bridge route")
		var module: Node3D = ground.modules[index]
		check(absf(module.position.x - index * 6.0) < 0.001, "Native module positions must remain at 6m intervals")
		check(module.name == "%02d_%s" % [index + 1, expected_kind], "Instantiated module type must match the active route")
		if index == 5 and not continuous_yard:
			check(not module.has_node("PaintedFoundationFront"), "The bridge must retain its 3D front and open grating")
			continue
		var front := module.get_node("PaintedFoundationFront") as MeshInstance3D
		fronts += 1
		check(front.position.is_equal_approx(Vector3(3, -1.25, 1.505)), "Paintings must remain on the physical foundation face")
		check((front.mesh as QuadMesh).size.is_equal_approx(Vector2(6, 2)), "Front paintings must not replace the walking surface")
		if enhanced:
			check(bool(front.get_meta("miniature_facade", false)), "Every enhanced concrete section must use the new repeated front")
			check(front.get_meta("facade_id") == MINIATURE_FACADE.ID, "All enhanced foundations must repeat the same new artwork")
			if shared_front == null:
				shared_front = front.material_override as ShaderMaterial
			check(front.material_override == shared_front, "Repeated foundations must share one material")
		else:
			check(front.get_meta("facade_id") == ground.FACADE_LIBRARY.SEQUENCE[index], "Baseline must retain its original connected facade sequence")
			baseline_fronts[front.get_meta("facade_id")] = true
	check(fronts == expected_fronts, "Painted foundation count must match the selected route")
	var details: Node3D = ground.get_node("SurfaceDetailLayers")
	check(details.bridge_enabled == (not continuous_yard), "Surface details must disable bridge additions in the continuous yard")
	var bridge_batches := details.find_children("*", "MultiMeshInstance3D", true, false)
	check(bridge_batches.is_empty() if continuous_yard else bridge_batches.size() >= 4, "Continuous yard must have no leftover bridge grating or fastener batches; retained bridge must keep its real lattice")
	if not enhanced:
		check(baseline_fronts.size() == 9, "Baseline must retain nine distinct painted fronts")
	if enhanced:
		check(shared_front != null and shared_front.get_shader_parameter("art") is Texture2D, "The repeated photographic front must have an imported texture")
		var front_texture: Texture2D = shared_front.get_shader_parameter("art")
		check(front_texture.resource_path == MINIATURE_FACADE.TEXTURE_PATH, "Enhanced fronts must use the new image rather than a library fallback")
	var continuous_floor := ground.get_node("Continuous60mFloor") as StaticBody3D
	var floor_collision := continuous_floor.get_child(0) as CollisionShape3D
	check((floor_collision.shape as BoxShape3D).size.is_equal_approx(Vector3(60, 0.5, 2.8)), "Floor collision must remain continuous for all 60m")
	check(continuous_floor.position.is_equal_approx(Vector3(30, -0.25, 0)), "Nominal floor height must remain y=0")
	check(actor.state == "GroundSitIdle" and actor.is_on_floor(), "MIKO must start seated on the real floor")
	var wake_x := actor.position.x
	Input.action_press("miko8_right", 0.65)
	await ticks(ceili(actor._duration("GroundSitExit") * 60.0) + 120)
	Input.action_release("miko8_right")
	check(not actor.state.begins_with("GroundSit") and actor.position.x > wake_x + 0.5, "Movement input must wake MIKO and move along the deck")
	for start: float in [5.5, 11.5, 17.5, 23.5, 29.5, 35.5, 41.5, 47.5]:
		actor.reset_actor()
		actor.position = Vector3(start, 0.02, 0)
		await ticks(5)
		Input.action_press("miko8_right", 0.65)
		var stayed_on_floor := true
		for frame in range(65):
			await physics_frame
			stayed_on_floor = stayed_on_floor and absf(actor.position.y) < 0.04
		Input.action_release("miko8_right")
		await ticks(10)
		check(actor.position.x > start + 0.6 and stayed_on_floor, "Walk through the native join at " + str(start + 0.5) + "m without a drop or jump")
	var crate := level.get_node("TutorialChargeCrate") as RigidBody3D
	check(crate.freeze and absf(crate.position.x - 54.0) < 0.001, "The real crate must remain fixed at 54m")
	actor.reset_actor()
	actor.position = Vector3(51.5, 0.02, 0)
	await ticks(5)
	Input.action_press("miko8_right", 0.65)
	await ticks(160)
	Input.action_release("miko8_right")
	check(actor.position.x > 53.0 and actor.position.x < 53.5 and actor.is_on_floor(), "The solid crate must block horizontal movement")
	check(actor.state == "WallBlocked", "Actor must report a real crate collision")
	Input.action_press("miko8_right", 0.65)
	Input.action_press("miko8_jump")
	await ticks(2)
	Input.action_release("miko8_jump")
	var jump_peak := actor.position.y
	for frame in range(120):
		await physics_frame
		jump_peak = maxf(jump_peak, actor.position.y)
	Input.action_release("miko8_right")
	await ticks(30)
	check(jump_peak > 0.8 and actor.position.x > 55.0 and actor.is_on_floor(), "Jump must clear the 0.8m crate and return to the continuous deck")
	var viewport_size := root.get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var original_foot_fraction := -1.0
	var wide_foot_fraction := -1.0
	for size: float in [11.25, 15.0]:
		level._game_size_changed(0 if size < 12.0 else 1)
		var half_width := size * aspect * 0.5
		for actor_x: float in [1.0, 30.0, 59.0]:
			actor.position = Vector3(actor_x, 0.02, 0)
			level._camera(0, true)
			var expected_x := clampf(actor_x + 1.5, half_width, 60.0 - half_width)
			check(absf(camera.position.x - expected_x) < 0.001 and absf(camera.size - size) < 0.001, "Original/wide cameras must clamp within the 60m route")
			check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "The route must retain an orthographic camera")
			var expected_target_y := 2.0 * size / 11.25 + (1.2 if enhanced and size > 12.0 else 0.0)
			check(camera.position.is_equal_approx(Vector3(expected_x, expected_target_y + 7.0, 18)), "Camera elevation and original pitch must remain fixed")
			check(camera.global_basis.z.dot(Vector3(0, 7, 18).normalized()) > 0.9999, "Both view sizes must retain the same 7:18 downward pitch")
			var floor_fraction := camera.unproject_position(Vector3(camera.position.x, 0, 0)).y / viewport_size.y
			if size < 12.0:
				if original_foot_fraction < 0.0:
					original_foot_fraction = floor_fraction
				check(absf(floor_fraction - original_foot_fraction) < 0.0001, "Original view must keep a stable floor row across the route")
			else:
				if wide_foot_fraction < 0.0:
					wide_foot_fraction = floor_fraction
				check(absf(floor_fraction - wide_foot_fraction) < 0.0001, "Wide view must keep its lower floor row stable across the route")
			if enhanced:
				var backdrop: Node3D = level.get_node("RestoredDistantCity")
				backdrop.update_camera(camera.position.x)
				var city: MeshInstance3D = backdrop.city_card
				var city_mesh := city.mesh as QuadMesh
				var top_left := camera.unproject_position(city.to_global(Vector3(-city_mesh.size.x * 0.5, city_mesh.size.y * 0.5, 0)))
				var bottom_right := camera.unproject_position(city.to_global(Vector3(city_mesh.size.x * 0.5, -city_mesh.size.y * 0.5, 0)))
				check(top_left.x <= 0.0 and bottom_right.x >= viewport_size.x and top_left.y <= 0.0 and bottom_right.y >= viewport_size.y, "Distant city must cover every viewport corner at both camera sizes and all three route positions")
				check(city.global_basis.z.dot(camera.global_basis.z) > 0.999, "City artwork must face the fixed camera pitch")
	if enhanced:
		check(absf((wide_foot_fraction - original_foot_fraction) * 1080.0 - 80.5) < 1.0, "Approved wide framing must place the floor about 80.5px lower at 1080 without changing pitch")
	else:
		check(absf(wide_foot_fraction - original_foot_fraction) < 0.0001, "Baseline must preserve its original floor framing when changing view size")
	if enhanced:
		var presence: Node3D = level.scene_presence
		check(absf(presence.room_length - 60.0) < 0.001, "Air particles must cover the restored 60m route")
		check(presence.air.custom_aabb.position.x <= 0.0 and presence.air.custom_aabb.end.x >= 60.0, "Particle draw bounds must include the second half of the route")
		var distant_motes := 0
		for mote: Dictionary in presence.motes:
			if mote.p.x > 40.0:
				distant_motes += 1
		check(distant_motes > 10, "Motes must actually populate the far end, not only expand their draw bounds")
		var probes := level.find_children("StaticWalkwayReflections", "ReflectionProbe", true, false)
		check(probes.size() == 1, "Exactly one static local reflection probe must be created")
		if probes.size() == 1:
			var probe := probes[0] as ReflectionProbe
			var probe_id := probe.get_instance_id()
			check(probe.update_mode == ReflectionProbe.UPDATE_ONCE and probe.cull_mask == 1, "Reflections must update once and exclude moving actor layer2")
			for visual: GeometryInstance3D in actor.find_children("*", "GeometryInstance3D", true, false):
				check(visual.layers == 2, "Actor visuals must be excluded from static reflections")
			await ticks(30)
			var later_probes := level.find_children("StaticWalkwayReflections", "ReflectionProbe", true, false)
			check(later_probes.size() == 1 and later_probes[0].get_instance_id() == probe_id and probe.update_mode == ReflectionProbe.UPDATE_ONCE, "The static probe must remain one instance rather than recreating or updating every frame")
	# Exercise the actual reset key path rather than calling the restart helper.
	var reset_key := InputEventKey.new()
	reset_key.physical_keycode = KEY_R
	reset_key.pressed = true
	level._unhandled_key_input(reset_key)
	await ticks(60)
	check(not level.resetting and absf(actor.position.x - 2.4) < 0.01 and actor.is_on_floor() and actor.state == "GroundSitIdle", "R must restore the original seated start on the native floor")
	print("RESTORED_PREVIEW_CHECKS ", checks, " failures=", failures, " enhanced=", enhanced, " continuous_yard=", continuous_yard, " fronts=", fronts, " bridge_batches=", bridge_batches.size(), " viewport=", viewport_size, " original_feet=", original_foot_fraction, " wide_feet=", wide_foot_fraction)
	if failures == 0:
		print("RESTORED_PREVIEW_PASS: selected native 60m route, correct physical fronts and bridge batches, wake/move, eight floor joins, solid crate/jump, R reset, selected view default and framing, original/wide camera bounds")
		if enhanced:
			print("RESTORED_PREVIEW_ENHANCED_PASS: shared repeated photographic front, city coverage at six view positions/sizes, 60m particles, static reflection probe")
		else:
			print("RESTORED_PREVIEW_BASELINE_PASS: original connected nine-front library retained")
	var exit_code := 0 if failures == 0 else 1
	level.audio.stop()
	level.audio.stream = null
	level.queue_free()
	await process_frame
	await process_frame
	quit(exit_code)
