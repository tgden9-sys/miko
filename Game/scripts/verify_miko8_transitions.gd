extends SceneTree
var level: Node3D
var actor: CharacterBody3D
var results := {}
func _initialize() -> void: call_deferred("_run")
func _ticks(n: int) -> void:
	for i in range(n): await physics_frame
func _axis(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func _jump(pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_B
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func _run() -> void:
	level = load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	actor = level.actor
	for direction in [1,-1]:
		for gait in [[0.35,"Walk"],[0.65,"Run"],[1.0,"Sprint"]]:
			_axis(0)
			_jump(false)
			await process_frame
			actor.reset_actor()
			actor.facing = direction
			actor.visual.rotation.y = direction * PI/2
			actor.position.x = -8.0 * direction
			await _ticks(15)
			_axis(float(gait[0]) * direction)
			await _ticks(95)
			assert(actor.current_clip == gait[1])
			actor.position.x = -8.0 * direction
			_jump(true)
			await process_frame
			await _ticks(3)
			_jump(false)
			assert(actor.state in ["JumpGather", "JumpStart"])
			var air := false
			var landed := false
			for i in range(330):
				await physics_frame
				if actor.state == "Air": air = true
				if actor.state == "Land":
					landed = true
					_axis(0)
				if landed and actor.state == "Locomotion": break
			assert(air and landed and actor.is_on_floor())
			results[gait[1]+str(direction)] = {"air":air,"landed":landed}
	_axis(0)
	await process_frame
	actor.reset_actor()
	actor.position = Vector3(12,1.5,0)
	actor.velocity = Vector3(0,-1,0)
	actor._state("Air")
	actor.launched = true
	actor._play("JumpAir",0.0)
	for i in range(180):
		await physics_frame
		if actor.landing_contact: break
	assert(actor.landing_contact and absf(actor.position.y-0.25)<0.01)
	results.raised_platform_landing = actor.position.y
	var menus := level.find_children("*","OptionButton",true,false)
	var review: OptionButton = menus[1]
	review.select(1)
	review.item_selected.emit(1)
	await _ticks(12)
	assert(level.reviewing and not actor.is_physics_processing())
	var before: float = actor.animation_player.current_animation_position
	level._toggle_pause()
	await _ticks(12)
	assert(is_equal_approx(actor.animation_player.current_animation_position,before))
	level._toggle_pause()
	review.select(0)
	review.item_selected.emit(0)
	assert(not level.reviewing and actor.is_physics_processing())
	results.clip_selector_and_pause = true
	var file := FileAccess.open("res://../Builds/Validation/MIKO8/transition_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	print("MIKO8_TRANSITIONS_PASSED ",JSON.stringify(results))
	quit()
