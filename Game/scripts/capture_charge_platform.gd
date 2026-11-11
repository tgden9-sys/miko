extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _save(name: String) -> void:
	for i in range(3):
		await process_frame
	var path: String = "res://../Builds/Validation/%s.png" % name
	var result: Error = root.get_texture().get_image().save_png(path)
	assert(result == OK)
	print("CAPTURED ", path)

func _run() -> void:
	var level: Node = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	var robot: CharacterBody2D = level.get_node("Robot")
	var fixture: Area2D = level.get_node("MagneticDrainFixture")
	var camera: Camera2D = level.get_node("Camera2D")
	camera.target = null
	camera.global_position = Vector2(750, 800)
	camera.zoom = Vector2(2.0, 2.0)
	level.get_node("ParallaxForeground").visible = false
	for crate in level.get_node("Crates").get_children():
		crate.neutralize()
	fixture.polarity = 1
	fixture._update_appearance()
	robot.global_position = Vector2(750, 745)
	robot.velocity = Vector2.ZERO
	robot.set_suit_polarity(2)
	for i in range(80):
		await physics_frame
	assert(robot.get("latched_fixture") == fixture)
	await _save("miko_charge_attached")
	robot.set_suit_polarity(0)
	for i in range(4):
		await physics_frame
	await _save("miko_charge_release_mid")
	for i in range(15):
		await physics_frame
	await _save("miko_charge_release_end")
	robot.set_suit_polarity(2)
	for i in range(50):
		await physics_frame
	assert(robot.get("latched_fixture") == fixture)
	robot.set_suit_polarity(1)
	for i in range(40):
		if robot.get("latched_fixture") == null:
			break
		await physics_frame
	for i in range(5):
		await physics_frame
	await _save("miko_charge_launch")
	for i in range(22):
		await physics_frame
	camera.global_position = robot.global_position + Vector2(0, -60)
	await _save("miko_charge_jump")
	print("CHARGE_CAPTURE_COMPLETE")
	quit()
