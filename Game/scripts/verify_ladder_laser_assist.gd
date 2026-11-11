extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	var robot: CharacterBody2D = level.get_node("Robot")
	assert(not robot._ladder_mount_requested(false, false, false), "Up arrow still mounts the ladder")
	assert(robot._ladder_mount_requested(true, false, false), "Controller A cannot start a climb")
	assert(robot._ladder_mount_requested(false, true, true), "Down input cannot descend from the top")
	var ladder: Area2D = level.get_node("Ladders/LadderCentral")
	robot.global_position = Vector2(ladder.global_position.x, ladder.bottom_y - 50.0)
	robot.active_ladder = ladder
	robot.ladder_state = robot.LadderState.MOUNTING
	robot.sprite.play(&"ladder_mount_right")
	for i in range(3):
		await physics_frame
	assert(robot.sprite.animation == &"ladder_mount_right", "Mount pose was replaced before MIKO turned")

	robot.ladder_state = robot.LadderState.NONE
	robot.active_ladder = null
	robot.global_position = Vector2(620.0, 829.7)
	robot.velocity = Vector2.ZERO
	level.get_node("MagneticDrainFixture").global_position = Vector2(3000, 878)
	var crate: CharacterBody2D = level.get_node("Crates/CrateGround1")
	for other in level.get_node("Crates").get_children():
		if other != crate:
			other.global_position = Vector2(3000, 100)
	crate.global_position = Vector2(770, 856)
	crate.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	robot.aim_side = &"aim_left_arm"
	robot.aim_l_progress = 1.0
	robot.aim_angle_degrees = 0.0
	robot._update_layers()
	robot._update_beam(&"aim_left_arm", 1.0 / 60.0)
	assert(robot.locked_target == crate, "Laser did not auto-lock on the nearby crate")
	assert(robot.plasma_reticle.is_locked_on, "Target receptacle did not show a lock")
	crate.global_position = Vector2(3000, 100)
	await physics_frame
	robot.aim_side = &"aim_left_arm"
	robot.aim_l_progress = 1.0
	robot._update_layers()
	robot._update_beam(&"aim_left_arm", 1.0 / 60.0)
	assert(robot.locked_target == null, "Laser retained a missing target")
	assert(absf(robot.beam.points[0].distance_to(robot.beam.points[1]) - robot.TAG_BEAM_REACH) < 1.0, "Open-air laser did not end at 200 pixels")
	assert(robot.plasma_reticle.visible and not robot.plasma_reticle.is_locked_on, "Open-air target receptacle is missing")
	print("LADDER_LASER_ASSIST_OK")
	quit()
