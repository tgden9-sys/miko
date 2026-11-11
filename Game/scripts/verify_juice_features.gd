extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	for i in range(25):
		await physics_frame

	var actor = level.actor
	actor.reset_actor()
	for i in range(5):
		await physics_frame

	print("--- 1. Testing Polarity Shift Visual Juice ---")
	actor.polarity_control.set_polarity(1)
	for i in range(2):
		await physics_frame
	assert(actor.suit_polarity == 1, "Suit polarity must be 1 (Red)")
	
	var found_red_fx := false
	for child in level.get_children():
		if child is Node3D and child.get_child_count() >= 5:
			var has_light := false
			var has_burst := false
			for grand in child.get_children():
				if grand is OmniLight3D: has_light = true
				if grand is MeshInstance3D: has_burst = true
			if has_light and has_burst:
				found_red_fx = true
				break
	assert(found_red_fx, "Polarity shift to Red must spawn visual juice with light and shockwave ring")

	actor.polarity_control.set_polarity(2)
	for i in range(2):
		await physics_frame
	assert(actor.suit_polarity == 2, "Suit polarity must be 2 (Blue)")
	var found_blue_fx := false
	for child in level.get_children():
		if child is Node3D and child.get_child_count() >= 5:
			for grand in child.get_children():
				if grand is OmniLight3D and grand.light_color.b > grand.light_color.r:
					found_blue_fx = true
					break
	assert(found_blue_fx, "Polarity shift to Blue must spawn blue visual juice")

	print("--- 2. Testing Launcher Dock Clamp Visual Juice ---")
	var launcher = level.get_node("NewYardProps/Loader/ChargeTarget")
	assert(launcher != null, "ChargeTarget launcher must exist")
	launcher.lock_in_color(Color.RED)
	actor.reset_actor()
	actor.position = Vector3(11.35, 0.02, 0)
	actor.facing = 1
	actor.visual.rotation.y = PI * 0.5
	actor.polarity_control.set_polarity(2)
	for i in range(15):
		await physics_frame

	Input.action_press("miko8_right", 0.5)
	for i in range(90):
		await physics_frame
		if actor.state == "LauncherAttach": break
	Input.action_release("miko8_right")
	assert(actor.state == "LauncherAttach", "Actor must enter LauncherAttach")

	for i in range(90):
		await physics_frame
		if actor.state == "LauncherHold": break
	assert(actor.state == "LauncherHold", "Actor must reach LauncherHold")

	var found_clamp_fx := false
	for child in level.get_children():
		if child is Node3D and child.get_child_count() >= 10:
			var light_count := 0
			var torus_count := 0
			for grand in child.get_children():
				if grand is OmniLight3D: light_count += 1
				if grand is MeshInstance3D and grand.mesh is TorusMesh: torus_count += 1
			if light_count >= 2 and torus_count >= 2:
				found_clamp_fx = true
				break
	assert(found_clamp_fx, "Launcher dock clamp must spawn dual cap rings & base pulse")

	print("--- 3. Testing Polarity Shift from Hold to Matching Pole -> Release & Launch ---")
	actor.polarity_control.set_polarity(1)
	for i in range(4):
		await physics_frame
	assert(actor.state == "LauncherRelease", "Matching polarity must enter LauncherRelease")

	for i in range(40):
		await physics_frame
		if actor.state == "Air": break
	assert(actor.state == "Air", "Launcher must launch Miko into Air")
	assert(actor.velocity.y > 7.0, "Miko must achieve boost velocity")

	print("ALL POLARITY SHIFT AND LAUNCHER CONNECTION JUICE TESTS PASSED!")
	quit()
