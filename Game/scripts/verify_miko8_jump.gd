extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var level: Node3D = load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor: CharacterBody3D = level.actor
	for i in range(30): await physics_frame
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_B
	event.pressed = true
	Input.parse_input_event(event)
	for i in range(10):
		await physics_frame
		print("INPUT_DEBUG ",i," ",actor.state," ",Input.is_action_pressed("miko8_jump")," ",actor.jump_buffer," ",actor.is_physics_processing())
	assert(actor.state == "JumpStart")
	quit()
