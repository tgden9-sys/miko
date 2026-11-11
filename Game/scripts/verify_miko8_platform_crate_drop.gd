extends SceneTree

const PLATFORMS = preload("res://scripts/miko8_level2_props.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func _check(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		failures += 1

func _run() -> void:
	var level := preload("res://scenes/miko8_level_02.tscn").instantiate()
	root.add_child(level)
	var actor: CharacterBody3D = level.actor
	var crates: Array[RigidBody3D] = []
	for child in level.get_node("Level2Platforms").get_children():
		if child is RigidBody3D and child.position.z < -.3:
			crates.append(child)
	_check(crates.size() == 3, "The finish deck has three crates")
	if crates.size() != 3:
		quit(1)
		return
	await _ticks(30)
	for side: float in [-1., 1.]:
		var crate := crates.front() as RigidBody3D if side < 0 else crates.back() as RigidBody3D
		var home: Vector3 = crate.position
		_check(absf(home.y - (PLATFORMS.STOREY + .4)) < .07 and home.z < -.7,
			"Crate rests in the upper walking lane before being pushed")
		# Give it a sideways shove like a magnetic push, in the actual finish stack.
		crate.apply_central_impulse(Vector3(side * crate.mass * 9., 0., 0.))
		await _ticks(190)
		var landed := crate.position
		_check(absf(landed.y - .4) < .04 and absf(landed.z) < .025,
			"Crate from side %s lands in Miko's ground lane: %s" % [side, landed])

		# Start on the open side of the landed crate and fire a regular red bolt.
		actor.reset_actor()
		actor.position = Vector3(landed.x + side * 1.65, .02, 0.)
		actor.facing = int(-side)
		actor.abilities.aim_facing = int(-side)
		actor.abilities.aim_engaged = true
		actor.abilities.laser_mode = "Red"
		actor._state("SpellHold")
		await _ticks(8)
		actor.abilities.has_snapped_initial = false
		actor.abilities.aim_elevation = -.4
		actor.abilities._refresh_target()
		actor.abilities._fire_spell()
		await _ticks(20)
		_check(crate.polarity == 1, "Miko can charge the fallen crate from the ground")

		# Check the actual player body hits the crate at Z=0.
		var hit := KinematicCollision3D.new()
		var sweep_from := Transform3D(Basis.IDENTITY, Vector3(landed.x + side * 1.25, .03, 0.))
		_check(actor.test_move(sweep_from, Vector3(-side * 1.25, 0., 0.), hit)
			and hit.get_collider() == crate, "The fallen crate is solid to Miko")

		crate.reset_charge_body()
		actor.reset_actor()
		await _ticks(15)
		_check(crate.position.distance_to(home) < .05, "Reset restores the crate to its original deck")
	level.free()
	quit(1 if failures else 0)
