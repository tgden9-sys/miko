extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	for i in range(25):
		await physics_frame

	var actor = level.actor
	var presence = level.scene_presence

	print("TESTING OPTION 1 KINEMATICS & PRACTICAL RIM LIGHTING")

	# 1. Test Dynamic Practical Rim Lighting
	actor.position = Vector3(28.0, 0.02, 0) # Directly under middle yard lamp
	level._camera(1.0 / 60.0, true)
	var mat: ShaderMaterial = actor.polarity_control.materials[0]
	var intensity_near: float = mat.get_shader_parameter("rim_intensity")
	print("Rim intensity near lamp (x=28): ", intensity_near)
	assert(intensity_near > 0.20, "Miko should receive practical rim highlight when near a yard lamp")

	actor.position = Vector3(14.0, 0.02, 0) # Far from all lamps
	level._camera(1.0 / 60.0, true)
	var intensity_far: float = mat.get_shader_parameter("rim_intensity")
	print("Rim intensity far from lamps (x=14): ", intensity_far)
	assert(intensity_far < 0.05, "Miko should not receive rim highlight when far from yard lamps")

	# 2. Test Wall Blocked Brace & Dust
	actor.position = Vector3(10.0, 0.02, 0)
	actor.facing = 1
	actor.velocity.x = 0.0
	actor._state("WallBlocked")
	presence._physics_process(1.0 / 60.0)
	assert(actor.visual.scale.y > 1.01, "WallBlocked should trigger a tactile brace visual scale")
	assert(presence.wall_dust_triggered, "WallBlocked should trigger wall contact dust flag")

	# 3. Test Skid & Turn Dust
	actor.position = Vector3(20.0, 0.02, 0)
	actor.velocity.x = 3.5
	actor._state("Brake")
	presence.skid_dust_time = 0.0
	presence._physics_process(1.0 / 60.0)
	assert(presence.skid_dust_time > 0.0, "Braking should schedule skid dust emission")

	# 4. Test Apex Float on Jump
	actor.position = Vector3(20.0, 0.02, 0)
	actor.velocity = Vector3.ZERO
	await physics_frame
	Input.action_press("miko8_jump")
	actor._begin_jump()
	actor.jump_held_during_ascent = true
	var peak := 0.0
	for i in range(35):
		await physics_frame
		peak = maxf(peak, actor.position.y)
		if actor.velocity.y < 0.0:
			break
	Input.action_release("miko8_jump")
	print("Full jump held peak height with float window: ", peak)
	assert(peak > 1.20 and peak < 1.45, "Jump peak with float window must remain within standard 1.20m - 1.45m bounds")

	print("OPTION 1 AND RIM LIGHTING VERIFICATION: ALL PASS!")
	quit(0)
