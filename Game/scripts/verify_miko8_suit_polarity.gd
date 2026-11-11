extends SceneTree
func _initialize()->void:call_deferred("_run")
func press(index:int)->void:
	for pressed:bool in [true,false]:
		var event:=InputEventJoypadButton.new()
		event.device=0;event.button_index=index;event.pressed=pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
func _run()->void:
	var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor=level.actor
	for pair in [[JOY_BUTTON_Y,1],[JOY_BUTTON_Y,0],[JOY_BUTTON_X,2],[JOY_BUTTON_X,0],[JOY_BUTTON_Y,1],[JOY_BUTTON_X,2]]:
		await press(pair[0])
		assert(actor.suit_polarity==pair[1])
		for material in actor.polarity_control.materials:assert(material.get_shader_parameter("polarity")==pair[1])
	assert(not actor.state.begins_with("Spell"))
	if not DisplayServer.get_name().to_lower().contains("headless"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/ladder_candidates/suit_polarity_live.png")
	print("SUIT_POLARITY_PASS: Y red/off, X blue/off, direct colour switch, independent of hand lasers")
	quit()
