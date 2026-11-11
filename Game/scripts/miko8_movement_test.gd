extends Node3D

const ACTOR_SCRIPT := preload("res://scripts/miko8_actor.gd")
var actor: CharacterBody3D
var camera: Camera3D
var status: Label
var controller_label: Label
var pause_button: Button
var paused := false
var quarter_view := false
var follow_x := 0.0
var walk_review := false
var reviewing := false
var review_label := ""
var game_size := false
var size_button: Button
var ability_label: Label
var review_menu: OptionButton
var wall_preview := false
var resetting := false

func _ready() -> void:
	walk_review = "--walk-review" in OS.get_cmdline_user_args()
	DisplayServer.window_set_title("MIKO — Ladders & spells review")
	_build_world()
	_build_ability_stage()
	actor = CharacterBody3D.new()
	actor.name = "MIKO8"
	actor.set_script(ACTOR_SCRIPT)
	add_child(actor)
	actor.walk_only = walk_review
	_build_hud()
	if "--ladder-review" in OS.get_cmdline_user_args(): _go_to_ladder()
	print("MIKO8_MOVEMENT_READY: left stick = walk/sprint; B = jump")

func _build_ability_stage() -> void:
	var ladder := preload("res://scripts/miko8_ladder.gd").new()
	ladder.name = "ReviewLadder"
	ladder.position = Vector3(18,0,-0.46)
	ladder.above_platform=0.;ladder.extended_rungs=false;ladder.curved_top=true
	ladder.rung_spacing=.2648;ladder.rung_offset=-.08;ladder.rail_half_width=.215
	ladder.set_meta("bpg_ladder",true);ladder.set_meta("top_entry_x",18.0);ladder.set_meta("direct_entry",true)
	add_child(ladder)
	_box(Vector3(19.875,3.08,0),Vector3(3.05,0.24,2.6),Color("233946"))
	_box(Vector3(17.975,3.08,-.975),Vector3(.75,.24,1.05),Color("233946"))
	for x in [-3.0,3.0,5.6]:
		var crate=preload("res://scripts/miko8_charge_box.gd").new()
		crate.position=Vector3(x,0.42,0)
		add_child(crate)
	for x in [-10.0,10.0]:
		var target := preload("res://scripts/miko8_spell_target.gd").new()
		target.position = Vector3(x,1.25,0)
		add_child(target)

func _go_to_ladder() -> void:
	if resetting:return
	review_menu.select(0)
	review_menu.item_selected.emit(0)
	actor.position = Vector3(18,0.02,0)
	follow_x = 18

func _box(position_value: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = position_value
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	mesh.material_override = material
	body.add_child(mesh)
	add_child(body)

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.008, 0.012, 0.02)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c7d5ed")
	environment.ambient_light_energy = 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -35, 0)
	key.light_energy = 0.9
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 145, 0)
	fill.light_energy = 0.3
	add_child(fill)
	_box(Vector3(0, -0.10, 0), Vector3(72, 0.20, 3.5), Color(0.018, 0.024, 0.035))
	_box(Vector3(12.0, 0.125, 0), Vector3(1.3, 0.25, 1.1), Color(0.055, 0.09, 0.12))
	_box(Vector3(-12.0, 0.20, 0), Vector3(1.6, 0.40, 1.1), Color(0.075, 0.065, 0.11))
	_box(Vector3(22.0, 0.25, 0), Vector3(1.3, 0.50, 1.1), Color(0.055, 0.09, 0.12))
	for x in [-35.0, 35.0]:
		_box(Vector3(x, 0.6, 0), Vector3(0.20, 1.2, 1.2), Color(0.10, 0.04, 0.03))
	var grid := ImmediateMesh.new()
	var grid_material := StandardMaterial3D.new()
	grid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_material.albedo_color = Color(0.055, 0.075, 0.095)
	grid.surface_begin(Mesh.PRIMITIVE_LINES, grid_material)
	for i in range(-144, 145):
		var x := float(i) * 0.25
		grid.surface_add_vertex(Vector3(x, 0.001, -1.75))
		grid.surface_add_vertex(Vector3(x, 0.001, 1.75))
	for i in range(-7, 8):
		var z := float(i) * 0.25
		grid.surface_add_vertex(Vector3(-36, 0.001, z))
		grid.surface_add_vertex(Vector3(36, 0.001, z))
	grid.surface_end()
	var lines := MeshInstance3D.new()
	lines.mesh = grid
	add_child(lines)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 4.0
	camera.current = true
	add_child(camera)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 20)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.05, 0.075, 0.94)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	panel.add_child(layout)
	var title := Label.new()
	title.text = "MIKO  /  Ladders & spells review"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)
	var instructions := Label.new()
	instructions.text = "Left stick: WALK at any tilt     •     Walk-only review" if walk_review else "Left stick: slight WALK / medium RUN / full SPRINT     •     A / Circle: JUMP"
	instructions.add_theme_font_size_override("font_size", 22)
	layout.add_child(instructions)
	var keyboard := Label.new()
	keyboard.text = "Keyboard: A/D or arrows: walk • Space: jump • F8: game size • R: reset • Pause: pause" if walk_review else "Keyboard: A/D run • Ctrl walk • Shift sprint • Space jump • F8 game size • R reset • Pause key pauses"
	keyboard.modulate = Color("aebed3")
	layout.add_child(keyboard)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	layout.add_child(row)
	var label := Label.new()
	label.text = "Reversal turn"
	row.add_child(label)
	var turns := OptionButton.new()
	turns.focus_mode = Control.FOCUS_NONE
	for name: String in ["Auto", "180 Left", "180 Right", "90 Left x2", "90 Right x2"]:
		turns.add_item(name)
	turns.item_selected.connect(func(index: int) -> void: actor.turn_mode = turns.get_item_text(index))
	row.add_child(turns)
	_button(row, "Reset", _request_reset)
	_button(row, "Camera angle", func() -> void: quarter_view = not quarter_view)
	_button(row, "Ladder", _go_to_ladder)
	size_button = _button(row, "Game size: 96 px", _toggle_game_size)
	size_button.tooltip_text = "Toggle detail view / 96 pixel character height on the 1080p game canvas. G also toggles."
	pause_button = _button(row, "Pause", _toggle_pause)
	var review := OptionButton.new()
	review_menu = review
	review.focus_mode = Control.FOCUS_NONE
	review.add_item("Controller play")
	for clip: String in actor.clips:
		var ladder_clip := clip.begins_with("StockLadder")
		review.add_item(clip + (" — ladder fit 1×" if ladder_clip else " — 1× + heading" if clip.begins_with("Turn") else " — source 1×"))
		review.set_item_metadata(review.item_count-1,{"clip":clip,"wall":false})
	for clip: String in ["ClimbIdle","ClimbUp","ClimbDown"]:
		review.add_item(clip + " — original wall climb")
		review.set_item_metadata(review.item_count-1,{"clip":clip,"wall":true})
	review.item_selected.connect(func(index: int) -> void:
		reviewing = index > 0
		paused = false
		pause_button.text = "Pause"
		if reviewing:
			var data: Dictionary = review.get_item_metadata(index)
			review_label = data.clip
			wall_preview = data.wall
		_restart_review()
	)
	layout.add_child(review)
	status = Label.new()
	layout.add_child(status)
	controller_label = Label.new()
	controller_label.modulate = Color("aebed3")
	layout.add_child(controller_label)
	var ability_controls := Label.new()
	var reaction_controls:=Label.new()
	reaction_controls.text="V sit | L3/Z crawl | H shoulder | Shift+H head | Ctrl+H stomach | Alt+H knockdown | Del/Shift+Del death | R reset"
	layout.add_child(reaction_controls)
	ability_controls.text = "Right stick/IJKL: aim | L1/Q: red | R1/E: blue | L2/G: sabre | R2/F: shield | R3/P: plasma | hold/release to cast"
	ability_controls.add_theme_font_size_override("font_size",17)
	layout.add_child(ability_controls)
	ability_label = Label.new()
	ability_label.add_theme_font_size_override("font_size",17)
	layout.add_child(ability_label)

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _toggle_pause() -> void:
	paused = not paused
	actor.set_physics_process(not paused and not reviewing and not resetting)
	pause_button.text = "Play" if paused else "Pause"

func _toggle_game_size() -> void:
	game_size = not game_size
	camera.size = 1.9 * 1080.0 / 96.0 if game_size else 4.0
	size_button.text = "Detail view" if game_size else "Game size: 96 px"

func _request_reset() -> void:
	if resetting:return
	resetting=true
	actor.set_physics_process(false)
	var overlay:=CanvasLayer.new()
	overlay.layer=90
	add_child(overlay)
	var fade:=ColorRect.new()
	fade.color=Color(0,0,0,0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fade)
	var out_tween:=create_tween()
	out_tween.tween_property(fade,"color:a",1.0,0.22)
	await out_tween.finished
	_restart_review()
	actor.set_physics_process(false)
	follow_x=actor.position.x
	await get_tree().create_timer(0.25).timeout
	var in_tween:=create_tween()
	in_tween.tween_property(fade,"color:a",0.0,0.35)
	await in_tween.finished
	overlay.queue_free()
	resetting=false
	actor.set_physics_process(not paused and not reviewing and not resetting)

func _restart_review() -> void:
	actor.reset_actor()
	actor.set_physics_process(not paused and not reviewing and not resetting)
	if reviewing:
		actor.ladder_pose.preview_enabled = false
		actor.head_offset.active=not review_label.begins_with("Death") and not review_label.begins_with("HitKnockback")
		if review_label.begins_with("Turn"):
			actor.turn_queue.assign([review_label])
			actor.turn_base_yaw = actor.visual.rotation.y
			actor._next_turn(false)
		else: actor._play(review_label, 0.0)
		actor._state("Clip review")

func _process(delta: float) -> void:
	if not actor or not actor.ready_for_input:
		return
	if reviewing and not paused and not resetting:
		actor.animation_player.advance(delta)
		if review_label.begins_with("GroundSit"):
			var phase:float=actor.animation_player.current_animation_position/actor._duration(review_label)
			actor.head_offset.blend_weight=smoothstep(0.05,0.80,phase) if review_label=="GroundSitExit" else 1.0-smoothstep(0.10,0.80,phase) if review_label=="GroundSitEnter" else 0.0
		if review_label.begins_with("Turn"):
			actor.visual.rotation.y = actor.turn_base_yaw + actor.turn_angle * float(actor._sample(actor.turn_progress, actor.animation_player.current_animation_position, actor._duration(review_label)))
		if actor.animation_player.current_animation_position >= actor._duration(review_label):
			if review_label.begins_with("Turn"):
				actor.turn_base_yaw += actor.turn_angle
				actor.visual.rotation.y = actor.turn_base_yaw
			actor.animation_player.seek(0.0, true)
	follow_x = lerpf(follow_x, actor.position.x, 1.0 - exp(-6.0 * delta))
	var lift := maxf(0.0, actor.position.y) * 0.75
	camera.position = Vector3(follow_x + (2.5 if quarter_view else 0.0), 1.85 + lift, 5.0)
	camera.look_at(Vector3(follow_x, 1.25 + lift, 0), Vector3.UP)
	status.text = "State: %s    •    Clip: %s    •    Speed: %.2f m/s" % [actor.state, actor.current_clip, absf(actor.velocity.x)]
	var devices := Input.get_connected_joypads()
	controller_label.text = "Controller: " + Input.get_joy_name(devices[0]) if not devices.is_empty() else "Connect a controller, or use the keyboard controls above."
	controller_label.text += " | X: red / Y: blue (again: off) | Suit: " + ["neutral","red","blue"][actor.suit_polarity]
	var hits := 0
	for target: Node in get_tree().get_nodes_in_group("miko8_spell_targets"): hits += target.hits
	ability_label.text = actor.abilities.hint + "    •    Shots: %d / target hits: %d" % [actor.abilities.shots_fired,hits]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_R: _request_reset()
		KEY_PAUSE: _toggle_pause()
		KEY_F8: _toggle_game_size()
		KEY_ESCAPE: get_tree().quit()



