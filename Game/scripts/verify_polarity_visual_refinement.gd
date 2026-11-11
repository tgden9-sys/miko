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

	print("--- 1. Testing Neutral Polarity Effect Color is Green ---")
	# First switch to Red, then switch to Neutral (0)
	actor.polarity_control.set_polarity(1)
	for i in range(2):
		await physics_frame
	
	actor.polarity_control.set_polarity(0)
	for i in range(2):
		await physics_frame
	
	assert(actor.suit_polarity == 0, "Suit polarity must be 0 (Neutral)")
	var found_green_fx := false
	var found_burst_mesh: MeshInstance3D = null
	for child in level.get_children():
		if child is Node3D and child.get_child_count() >= 5:
			for grand in child.get_children():
				if grand is OmniLight3D:
					if grand.light_color.g > grand.light_color.r and grand.light_color.g > grand.light_color.b:
						found_green_fx = true
				if grand is MeshInstance3D and grand.material_override is ShaderMaterial:
					var sm := grand.material_override as ShaderMaterial
					if sm.shader == preload("res://shaders/miko8_polarity_burst.gdshader"):
						found_burst_mesh = grand
	assert(found_green_fx, "Neutral polarity shift must produce a green light effect (light_color.g dominant)")
	assert(found_burst_mesh != null, "Polarity shift burst mesh must exist")
	var bmat := found_burst_mesh.material_override as ShaderMaterial
	var tint_param: Color = bmat.get_shader_parameter("color")
	assert(tint_param.g > tint_param.r and tint_param.g > tint_param.b, "Burst shader tint color must be green")
	print("PASS: Neutral polarity effect is vibrant green (tint: %s)" % tint_param)

	print("--- 2. Testing Softness and Dropped Opacity ---")
	var initial_opacity: float = bmat.get_shader_parameter("master_opacity")
	assert(initial_opacity <= 0.45, "Master opacity must be soft (<= 0.45, got %f)" % initial_opacity)
	var initial_thickness: float = bmat.get_shader_parameter("ring_thickness")
	assert(initial_thickness >= 0.045, "Ring thickness must be wide and soft (>= 0.045, got %f)" % initial_thickness)
	print("PASS: Burst has soft wide diffusion (thickness: %f) and dropped opacity (%f)" % [initial_thickness, initial_opacity])

	print("--- 3. Testing Effect Follows Miko While Moving ---")
	# Switch polarity while Miko has high velocity and is running forward
	actor.velocity.x = 6.0
	actor.polarity_control.set_polarity(2)
	for i in range(2):
		await physics_frame
	
	var blue_fx: Node3D = null
	for child in level.get_children():
		if child is Node3D and child.get_child_count() >= 5:
			for grand in child.get_children():
				if grand is OmniLight3D and grand.light_color.b > grand.light_color.r:
					blue_fx = child
					break
	assert(blue_fx != null, "Blue fx must be spawned")
	
	# Move actor by 2.0 meters over several frames and verify blue_fx follows actor
	for frame in range(10):
		actor.position.x += 0.25
		await process_frame
		var expected_pos: Vector3 = actor.global_position + Vector3(0, 0.85, 0.12)
		var diff: float = blue_fx.global_position.distance_to(expected_pos)
		assert(diff < 0.001, "Polarity effect must track actor center dynamically (diff was %f)" % diff)
	print("PASS: Polarity burst dynamically stays perfectly centered on Miko while moving!")

	print("ALL POLARITY VISUAL REFINEMENT TESTS PASSED!")
	quit()
