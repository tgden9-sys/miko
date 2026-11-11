extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = load("res://scenes/miko8_side_on_mockup.tscn").instantiate()
	root.add_child(level)
	for i in range(10):
		await physics_frame

	print("--- VERIFYING OPTION A SUNLIT DUST & 3-TIER BOKEH SYSTEM ---")
	var atmo = level.atmosphere
	assert(is_instance_valid(atmo), "Atmosphere node must exist")
	assert(atmo.floating_air.instance_count == 96, "Floating air multimesh must have 96 instances")
	assert(atmo.dust.instance_count == 40, "Warm worklight dust multimesh must have 40 instances")
	assert(atmo.floating_points.size() == 96, "Must define 96 floating points across 3 tiers")

	# Check tier distribution
	var tier0_count := 0
	var tier1_count := 0
	var tier2_count := 0
	for pt in atmo.floating_points:
		if pt.tier == 0:
			tier0_count += 1
			assert(pt.p.z >= 5.5 and pt.p.z <= 11.5, "Tier 0 bokeh discs must sit in foreground Z [5.5, 11.5]")
			assert(pt.size >= 0.35 and pt.size <= 0.70, "Tier 0 bokeh discs must have large lens blur size")
		elif pt.tier == 1:
			tier1_count += 1
			assert(pt.p.z >= -0.3 and pt.p.z <= 1.8, "Tier 1 sunlit dust must sit in gameplay plane Z [-0.3, 1.8]")
		elif pt.tier == 2:
			tier2_count += 1
			assert(pt.p.z <= -1.0 and pt.p.z >= -4.5, "Tier 2 background specks must sit behind scenery Z [-4.5, -1.0]")
	
	print("Tiers: Tier 0 (foreground bokeh)=", tier0_count, ", Tier 1 (midground dust)=", tier1_count, ", Tier 2 (background specks)=", tier2_count)
	assert(tier0_count == 16, "Tier 0 must have exactly 16 foreground bokeh instances")
	assert(tier1_count == 52, "Tier 1 must have exactly 52 midground dust instances")
	assert(tier2_count == 28, "Tier 2 must have exactly 28 background speck instances")

	# Check HUD dropdown
	var dropdown = level.mote_style
	assert(is_instance_valid(dropdown), "Mote style dropdown must exist in HUD")
	assert(dropdown.item_count == 4, "Mote style dropdown must have 4 options")
	assert(dropdown.get_item_text(0) == "Motes: Bold (100%)", "Item 0 text match")
	assert(dropdown.get_item_text(1) == "Motes: Moderate (60%)", "Item 1 text match")
	assert(dropdown.get_item_text(2) == "Motes: Subtle (30%)", "Item 2 text match")
	assert(dropdown.get_item_text(3) == "Motes: Off (0%)", "Item 3 text match")

	# Check default intensity
	assert(absf(atmo.mote_intensity - 1.0) < 0.001, "Default mote intensity must be 1.0 (Bold)")

	# Check intensity change
	atmo.set_mote_intensity(0.6)
	assert(absf(atmo.mote_intensity - 0.6) < 0.001, "Mote intensity must update to 0.6")
	atmo.set_mote_intensity(0.0)
	assert(absf(atmo.mote_intensity - 0.0) < 0.001, "Mote intensity must update to 0.0")
	atmo.set_mote_intensity(1.0)

	# Check F10 cycling
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F10
	event.pressed = true
	level._unhandled_key_input(event)
	assert(dropdown.selected == 1, "F10 must cycle to Moderate (index 1)")
	assert(absf(atmo.mote_intensity - 0.6) < 0.001, "F10 must apply 0.6 intensity")

	level._unhandled_key_input(event)
	assert(dropdown.selected == 2, "F10 must cycle to Subtle (index 2)")
	assert(absf(atmo.mote_intensity - 0.3) < 0.001, "F10 must apply 0.3 intensity")

	level._unhandled_key_input(event)
	assert(dropdown.selected == 3, "F10 must cycle to Off (index 3)")
	assert(absf(atmo.mote_intensity - 0.0) < 0.001, "F10 must apply 0.0 intensity")

	level._unhandled_key_input(event)
	assert(dropdown.selected == 0, "F10 must wrap to Bold (index 0)")
	assert(absf(atmo.mote_intensity - 1.0) < 0.001, "F10 must restore 1.0 intensity")

	# Step frames to verify shader execution and volumetric lamp flare
	for i in range(20):
		await physics_frame
	atmo._update_effects()

	print("--- OPTION A SUNLIT DUST & 3-TIER BOKEH VERIFICATION: ALL PASS! ---")
	quit(0)
