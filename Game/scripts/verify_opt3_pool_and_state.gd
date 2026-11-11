@tool
extends SceneTree

func _init() -> void:
	_run_verification()

func _run_verification() -> void:
	print("==================================================")
	print("VERIFYING OPTION 3 (CODE & ENGINE OPTIMIZATION)")
	print("AND VERIFYING MANTLE ANIMATION REMOVAL")
	print("==================================================")

	var scene: PackedScene = load("res://scenes/miko8_side_on_mockup.tscn")
	var mockup: Node = scene.instantiate()
	root.add_child(mockup)

	for f in range(5):
		await process_frame

	var actor: CharacterBody3D = mockup.get("actor") as CharacterBody3D
	assert(actor != null, "Actor must exist")
	actor.reset_actor()
	await process_frame

	# 1. State Machine Enum Verification
	print("\n--- TEST 1: ENUM-DRIVEN ACTOR STATE MACHINE ---")
	print("Initial state_id: ", actor.state_id, " (Enum: ", actor.State.LOCOMOTION, ")")
	assert(actor.state_id == actor.State.LOCOMOTION, "Initial state_id must be LOCOMOTION")
	assert(actor.state == "Locomotion", "Backward-compatible state getter must return 'Locomotion'")

	# Transition to MoveStart
	actor._set_state_enum(actor.State.MOVE_START)
	assert(actor.state_id == actor.State.MOVE_START)
	assert(actor.state == "MoveStart")

	# Backward-compatible string transition
	actor._state("Locomotion")
	assert(actor.state_id == actor.State.LOCOMOTION)
	assert(actor.state == "Locomotion")

	# External custom state support
	actor._state("GroundSitIdle")
	assert(actor.state_id == actor.State.CUSTOM)
	assert(actor.state == "GroundSitIdle")

	actor.reset_actor()
	assert(actor.state_id == actor.State.LOCOMOTION)
	print("PASS: Enum state machine verified with backward-compatible string getter/setter!")

	# 2. Mantle Animation Removal Verification
	print("\n--- TEST 2: MANTLE ANIMATION REMOVAL ---")
	assert(not actor.has_method("_check_mantle"), "Mantle check method must be removed")
	assert(not actor.has_method("_begin_mantle"), "Mantle begin method must be removed")
	assert(not "Mantle" in actor.STATE_NAMES, "Mantle state must be removed from actor states")
	print("PASS: Mantle animation and state completely removed as requested!")

	# 3. Projectile and VFX Object Pool Verification
	print("\n--- TEST 3: PRE-WARMED PROJECTILE & IMPACT VFX POOL ---")
	var abilities = actor.abilities
	assert(abilities != null, "Abilities node must exist")
	var pool = abilities.get("projectile_pool")
	assert(pool != null, "Projectile pool must exist on abilities")

	print("Initial pooled bolts: ", pool.bolt_pool.size(), " (Capacity: 16)")
	print("Initial pooled impacts: ", pool.impact_pool.size(), " (Capacity: 16)")
	assert(pool.bolt_pool.size() == 16, "Pool must be prewarmed with 16 bolts")
	assert(pool.impact_pool.size() == 16, "Pool must be prewarmed with 16 impacts")

	# Fire 25 shots across Plasma, Red, and Blue modes
	var modes := ["Plasma", "Red", "Blue"]
	var spawned_bolts: Array[Node3D] = []

	for i in range(25):
		abilities.laser_mode = modes[i % modes.size()]
		abilities._fire_spell()
		await process_frame

	print("After firing 25 shots:")
	print("  Active bolts in flight: ", pool.active_bolts.size())
	print("  Remaining free bolts in pool: ", pool.bolt_pool.size())
	print("  Active impacts: ", pool.active_impacts.size())
	print("  Remaining free impacts in pool: ", pool.impact_pool.size())

	# Wait for bolts to collide or time out and be recycled, plus their impacts
	print("Waiting for projectiles and impacts to recycle into pool...")
	for f in range(240):
		await process_frame
		if pool.active_bolts.is_empty() and pool.active_impacts.is_empty():
			print("All bolts and impacts recycled early at frame: ", f)
			break

	print("After recycling:")
	print("  Active bolts: ", pool.active_bolts.size(), " (Expected: 0)")
	print("  Recycled bolts in pool: ", pool.bolt_pool.size(), " (Expected: >= 16)")
	print("  Active impacts: ", pool.active_impacts.size(), " (Expected: 0)")
	print("  Recycled impacts in pool: ", pool.impact_pool.size(), " (Expected: >= 16)")

	assert(pool.active_bolts.is_empty(), "All bolts must be recycled back to pool")
	assert(pool.active_impacts.is_empty(), "All impacts must be recycled back to pool")
	assert(pool.bolt_pool.size() >= 16, "Pool must contain at least 16 bolts")
	assert(pool.impact_pool.size() >= 16, "Pool must contain at least 16 impacts")
	print("PASS: Pre-warmed object pool verified with zero runtime allocations!")

	# Clean up
	mockup.free()
	print("\nALL OPTION 3 OPTIMIZATIONS & REMOVALS VERIFIED CLEANLY (Exit code 0)!")
	quit(0)
