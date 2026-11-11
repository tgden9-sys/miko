extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/security_drone.tscn")
	if scene == null:
		push_error("Drone scene could not load")
		quit(1)
		return
	var drone := scene.instantiate()
	drone.position = Vector2(100, 100)
	root.add_child(drone)
	if not drone.patrol_left.visible or drone.patrol_right.visible:
		push_error("Outbound flight must face left")
		quit(1)
		return
	await physics_frame
	if drone.thruster_socket.position.x <= 0.0:
		push_error("Thruster smoke did not follow the left-facing nozzle")
		quit(1)
		return
	for i in range(540):
		await physics_frame
	if drone.position.x < -211 or drone.position.x > 100:
		push_error("Patrol left its path")
		quit(1)
		return
	if drone.state == drone.State.RETURN and (not drone.patrol_right.visible or drone.patrol_left.visible):
		push_error("Return flight must face right")
		quit(1)
		return
	if drone.state == drone.State.RETURN and drone.thruster_socket.position.x >= 0.0:
		push_error("Thruster smoke did not follow the right-facing nozzle")
		quit(1)
		return
	print("DRONE PATROL OK state=", drone.state, " x=", drone.position.x)
	var dummy := Node2D.new()
	dummy.name = "Robot"
	dummy.position = drone.position + Vector2(75, 80)
	drone.get_parent().add_child(dummy)
	# The patrol drone resolves the player when it enters the scene.
	drone.player = dummy
	await physics_frame
	if drone.state != drone.State.FACE_FRONT or drone.left_gun.rotation != 0.0:
		push_error("Drone must turn toward camera before alert")
		quit(1)
		return
	for i in range(24):
		await physics_frame
	if drone.state != drone.State.ALERT or drone.left_gun.rotation != 0.0:
		push_error("Alert must light visor before gun movement")
		quit(1)
		return
	for i in range(88):
		await physics_frame
	if drone.state < drone.State.AIM:
		push_error("Drone did not aim after alert")
		quit(1)
		return
	print("DRONE ALERT OK state=", drone.state, " left gun=", drone.left_gun.rotation)
	quit()
