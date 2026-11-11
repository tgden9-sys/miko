extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	for i in range(25):
		await physics_frame

	var actor = level.actor
	var camera: Camera3D = level.camera

	print("TESTING CAMERA STABILITY (ZERO NAUSEA)")

	# Initial camera size
	assert(absf(camera.size - 15.0) < 0.05, "Camera height must remain rock solid at 15.0")

	# 1. Test sprint stability
	actor.position = Vector3(20.0, 0.02, 0)
	actor._resume_locomotion(1.0)
	actor._state("Locomotion")
	actor.current_clip = "Sprint"
	actor.velocity.x = 5.2

	for i in range(45):
		level._camera(1.0 / 60.0, false)
		await physics_frame

	print("Camera size during full sprint: ", camera.size)
	assert(absf(camera.size - 15.0) < 0.05, "Camera height must not zoom out during sprint")

	# 2. Test stop stability
	actor.current_clip = "Idle"
	actor.velocity.x = 0.0
	for i in range(30):
		level._camera(1.0 / 60.0, false)
		await physics_frame

	assert(absf(camera.size - 15.0) < 0.05, "Camera height must remain 15.0 on stop")

	# 3. Test FPS label existence and visibility
	assert(level.performance != null, "Performance label must exist")
	assert(level.performance.visible, "Performance FPS counter must be visible")

	print("CAMERA STABILITY AND FPS COUNTER PASS!")
	quit(0)
