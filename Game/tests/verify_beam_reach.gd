extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody2D = scene.get_node("Robot")
	await physics_frame
	player.set("aim_side", &"aim_left_arm")
	player.set("aim_l_progress", 1.0)
	player.set("plasma_aiming", false)
	player.set("current_beam_length", 550.0)
	player.call("_update_beam", &"aim_left_arm", 1.0 / 60.0)
	var raycast: RayCast2D = player.get_node("AimRayCast")
	if absf(raycast.target_position.length() - 550.0) > 0.5:
		push_error("Magnetic beam could not extend past 200 px")
		quit(1)
		return
	player.set("current_beam_length", 200.0)
	player.call("_update_beam", &"aim_left_arm", 1.0 / 60.0)
	if absf(raycast.target_position.length() - 200.0) > 0.5:
		push_error("Magnetic beam did not use the 200 px starting reach")
		quit(1)
		return
	print("MAGNETIC BEAM REACH OK 200 -> 550")
	quit()
