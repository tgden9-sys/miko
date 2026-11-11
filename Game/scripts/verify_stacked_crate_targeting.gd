extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	for i in range(25):
		await physics_frame

	var actor = level.actor
	var abilities = actor.abilities
	var lower_crate = level.get_node("WorkshopCrateLower")
	var upper_crate = level.get_node("WorkshopCrateUpper")

	assert(lower_crate != null and upper_crate != null, "Stacked crates must exist in scene")

	print("TESTING STACKED CRATE TARGET SELECTION & FREE VERTICAL AIM")

	# Position Miko facing the stacked pair cleanly in the workshop approach
	actor.position = Vector3(50.0, 0.02, 0)
	actor.facing = 1
	abilities.aim_facing = 1
	abilities.laser_mode = "Red"
	actor._state("SpellHold")
	for i in range(3):
		await physics_frame

	# 1. Aim toward the upper crate (-8 degrees from shoulder height)
	abilities.aim_elevation = deg_to_rad(-8.0)
	abilities._refresh_target()
	print("Aiming UP toward upper crate (-8 deg) locked target: ", abilities.locked_target.name if abilities.locked_target else "null")
	assert(abilities.locked_target == upper_crate, "Aiming toward upper crate should smoothly select WorkshopCrateUpper")

	# 2. Aim DOWN toward the lower crate (-41 degrees)
	abilities.aim_elevation = deg_to_rad(-41.0)
	abilities._refresh_target()
	print("Aiming DOWN (-41 deg) locked target: ", abilities.locked_target.name if abilities.locked_target else "null")
	assert(abilities.locked_target == lower_crate, "Aiming down should smoothly select WorkshopCrateLower")

	# 3. Test that switching back and forth between upper and lower crates requires only gentle stick movement
	abilities.aim_elevation = deg_to_rad(-8.0)
	abilities._refresh_target()
	print("Aiming back toward upper crate (-8 deg) locked target: ", abilities.locked_target.name if abilities.locked_target else "null")
	assert(abilities.locked_target == upper_crate, "Switching back up should re-select WorkshopCrateUpper without extreme stick deflection")

	# 4. Test that Miko's arm elevation responds to right stick while locked
	var initial_elevation = abilities.aim_elevation
	abilities.update_aim(Vector2(0, -0.8), 0.1) # Push stick up
	assert(abilities.aim_elevation > initial_elevation, "Right stick up should freely increase aim elevation while locked")

	print("STACKED CRATE TARGETING TEST PASSED!")
	quit(0)
