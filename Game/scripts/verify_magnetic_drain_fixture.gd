extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var robot: CharacterBody2D = level.get_node("Robot")
	var fixture: Area2D = level.get_node("MagneticDrainFixture")
	var pad_switch := InputEventJoypadButton.new()
	pad_switch.button_index = JOY_BUTTON_B
	pad_switch.pressed = true
	for expected_pole in [1, 2, 0]:
		robot._unhandled_input(pad_switch)
		assert(robot.suit_polarity == expected_pole, "Controller B failed to cycle suit polarity")
	print("CONNECTED_CONTROLLERS=", Input.get_connected_joypads())
	for crate in level.get_node("Crates").get_children():
		crate.neutralize()
		crate.global_position = Vector2(2900.0, 100.0)
	var fixed_position: Vector2 = fixture.global_position
	var query_high := PhysicsRayQueryParameters2D.create(Vector2(620.0, 850.0), Vector2(750.0, 850.0), 1)
	query_high.exclude = [robot.get_rid()]
	query_high.collide_with_areas = true
	var high_hit: Dictionary = robot.get_world_2d().direct_space_state.intersect_ray(query_high)
	assert(high_hit.get("collider") != fixture, "The tagging beam targets empty air above the fixture")
	var query_low := PhysicsRayQueryParameters2D.create(Vector2(620.0, 868.0), Vector2(750.0, 868.0), 1)
	query_low.exclude = [robot.get_rid()]
	query_low.collide_with_areas = true
	var low_hit: Dictionary = robot.get_world_2d().direct_space_state.intersect_ray(query_low)
	assert(low_hit.get("collider") == fixture, "The tagging beam cannot hit the visible fixture")
	for i in range(8):
		await physics_frame
	var approach_x: float = robot.global_position.x
	var obstruction: KinematicCollision2D = robot.move_and_collide(Vector2(130.0, 0.0))
	assert(obstruction == null and robot.global_position.x > approach_x + 125.0, "Fixture blocks MIKO's walk-on approach")
	robot.set("aim_side", &"aim_left_arm")
	robot.set("locked_target", fixture)
	robot._clear_locked_target(true)
	assert(fixture.polarity == 1, "Red beam did not charge the fixture")
	for charged_pole in [1, 2]:
		fixture.polarity = charged_pole
		fixture._update_appearance()
		robot.global_position = Vector2(750.0, 790.0)
		robot.velocity = Vector2.ZERO
		robot.set("fixture_launch_lockout", 0.0)
		robot.set_suit_polarity(3 - charged_pole)
		for i in range(30):
			await physics_frame
		assert(robot.get("latched_fixture") == fixture, "Opposite suit polarity did not latch MIKO")
		assert(robot.get("squash_stretch").distance_to(Vector2.ONE) < 0.001, "Latch squashed MIKO")
		assert(robot.get_node("AnimatedSprite2D").animation == &"charge_attach", "MIKO did not enter the platform attachment animation")
		var launch_y: float = robot.global_position.y
		robot._unhandled_input(pad_switch)
		assert(robot.suit_polarity == charged_pole, "Controller B did not switch to the fixture's matching polarity")
		for i in range(40):
			if robot.get("latched_fixture") == null:
				break
			await physics_frame
		assert(robot.velocity.y < -800.0, "Matching polarity did not launch upward after the attachment pose")
		assert(robot.get("latched_fixture") == null)
		assert(robot.get_node("AnimatedSprite2D").animation == &"charge_launch", "MIKO did not play the launch animation")
		for i in range(10):
			await physics_frame
		assert(robot.global_position.y < launch_y - 80.0, "MIKO did not rise after launch")
		assert(fixture.global_position == fixed_position, "Ground fixture moved")
	fixture.polarity = 1
	fixture._update_appearance()
	robot.global_position = Vector2(750.0, 790.0)
	robot.velocity = Vector2.ZERO
	robot.fixture_launch_lockout = 0.0
	robot.set_suit_polarity(2)
	for i in range(35):
		await physics_frame
	assert(robot.latched_fixture == fixture, "Could not attach for release test")
	robot.set_suit_polarity(0)
	assert(robot.fixture_detaching, "Neutral release skipped detach state")
	assert(robot.sprite.animation == &"charge_release" and robot.sprite.is_playing(), "Neutral release did not start its release animation")
	for i in range(36):
		await physics_frame
	assert(not robot.fixture_detaching, "Detach animation did not finish")
	print("MAGNETIC_DRAIN_FIXTURE_OK")
	quit()
