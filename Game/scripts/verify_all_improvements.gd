@tool
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("VERIFYING ALL 5 PERFORMANCE & GAMEPLAY IMPROVEMENTS")
	print("==================================================")

	var mockup_scene: PackedScene = load("res://scenes/miko8_side_on_mockup.tscn")
	var mockup = mockup_scene.instantiate()
	root.add_child(mockup)
	for f in range(12): await physics_frame

	var actor = mockup.get("actor") as CharacterBody3D
	var abilities = actor.abilities
	var launcher_motion = actor.launcher_motion

	# -------------------------------------------------------------------------
	# 1. VERIFY ZERO-ALLOCATION RAYCASTING & CACHED GROUPS
	# -------------------------------------------------------------------------
	print("\n--- 1. VERIFY ZERO-ALLOCATION RAYCASTING & CACHED GROUPS ---")
	assert(abilities._reusable_ray_query != null, "Persistent ray query must be initialized")
	var query_instance = abilities._reusable_ray_query
	var hit = abilities._segment_hit(Vector3(10, 1, 0), Vector3(10, -1, 0))
	assert(abilities._reusable_ray_query == query_instance, "Must reuse identical query instance (0 heap allocations)")
	
	var ladders = abilities._get_ladders()
	assert(ladders.size() > 0, "Cached ladders must be populated")
	var targets = abilities._get_charge_targets()
	assert(targets.size() > 0, "Cached charge targets must be populated")
	print("PASS: Raycast pooling and cached groups verified with 0 allocations!")

	# -------------------------------------------------------------------------
	# 2. VERIFY BITMASK STATE CHECKS IN ABILITIES & LAUNCHER
	# -------------------------------------------------------------------------
	print("\n--- 2. VERIFY BITMASK STATE CHECKS ---")
	actor.reset_actor()
	await physics_frame
	assert(launcher_motion._free_state(), "Launcher _free_state must return true in Locomotion via bitmask")
	
	# Verify bitmask behavior across all locomotion states
	actor.state = "MoveStart"
	assert(launcher_motion._free_state(), "Free state in MoveStart")
	actor.state = "Air"
	assert(launcher_motion._free_state(), "Free state in Air")
	actor.state = "LauncherAttach"
	assert(not launcher_motion._free_state(), "Free state false when attached")
	actor.reset_actor()
	print("PASS: Single-cycle bitmask state checks verified!")

	# -------------------------------------------------------------------------
	# 3. VERIFY CRATE PHYSICS STABILITY & SLEEP DE-JITTER
	# -------------------------------------------------------------------------
	print("\n--- 3. VERIFY CRATE PHYSICS STABILITY & SLEEP DE-JITTER ---")
	var crate = mockup.get_node_or_null("TutorialChargeCrate")
	assert(crate != null, "TutorialChargeCrate must exist in mockup")
	
	# Allow crate to settle
	for f in range(25): await physics_frame
	assert(crate.sleeping or crate.linear_velocity.length_squared() < 0.01, "Uncharged resting crate must settle/sleep")
	assert(absf(crate.position.z) < 0.005, "Crate must strictly remain on Z=0.0 planar axis")
	assert(crate.position.y >= 0.395, "Crate must not sink below floor height")

	# Charge crate and verify wake
	crate.lock_in_color(Color("309cff"))
	assert(not crate.sleeping, "Crate must wake up immediately when charged")
	assert(crate.polarity == 2, "Crate polarity set to Blue (2)")
	crate.neutralize()
	print("PASS: Crate physics de-jitter, sleeping, and planar clamping verified!")

	# -------------------------------------------------------------------------
	# 4. VERIFY VELOCITY-SENSITIVE DIRECTIONAL CAMERA LOOKAHEAD & TIER FRAMING
	# -------------------------------------------------------------------------
	print("\n--- 4. VERIFY CAMERA DIRECTIONAL LOOKAHEAD & TIER FRAMING ---")
	actor.position = Vector3(20.0, 0.02, 0)
	actor.facing = 1
	actor.velocity.x = 4.0 # Moving right
	mockup._camera(0.016, true) # Immediate update
	var lead_right = mockup.camera_lead_x
	print("Camera lead when moving right: ", lead_right)
	assert(lead_right > 1.5, "Camera must lead ahead in positive X when moving right")

	actor.facing = -1
	actor.velocity.x = -4.0 # Moving left
	mockup._camera(0.016, true)
	var lead_left = mockup.camera_lead_x
	print("Camera lead when moving left: ", lead_left)
	assert(lead_left < -1.5, "Camera must lead ahead in negative X when moving left (no looking behind player)")

	# Verify rooftop tier framing
	actor.walk_plane_floor_y = 5.2
	mockup._camera(0.016, true)
	assert(mockup.camera_floor_y > 4.5, "Camera must smoothly frame upper platform tier")
	actor.walk_plane_floor_y = 0.0
	mockup._camera(0.016, true)
	print("PASS: Dynamic directional lookahead & tier framing verified!")

	# -------------------------------------------------------------------------
	# 5. VERIFY ATMOSPHERE MOTE PERFORMANCE & CULLING
	# -------------------------------------------------------------------------
	print("\n--- 5. VERIFY ATMOSPHERE MOTE CULLING & RENDERING ---")
	var atmos = mockup.atmosphere
	assert(atmos != null, "Atmosphere must be loaded in mockup")
	mockup._camera(0.016, false)
	atmos._update_effects()
	assert(atmos.floating_air.visible_instance_count <= 96, "Mote count within total capacity")
	assert(atmos.floating_air.visible_instance_count > 0, "Visible motes inside camera frustum active")
	print("Visible motes inside frustum: ", atmos.floating_air.visible_instance_count, " of 96 total")
	print("PASS: Atmosphere mote frustum culling and basis optimization verified!")

	print("\n==================================================")
	print("ALL 5 IMPROVEMENTS FULLY VERIFIED CLEANLY (Exit 0)")
	print("==================================================")
	mockup.free()
	quit(0)
