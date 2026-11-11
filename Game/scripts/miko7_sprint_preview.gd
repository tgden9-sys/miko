extends Control

const MODEL_PATH := "res://models/miko7/review_v6/MIKO7_Locomotion_v6.glb"
var player: AnimationPlayer
var animation_name: StringName
var animation: Animation
var camera: Camera3D
var viewport: SubViewport
var timeline: HSlider
var status: Label
var play_button: Button
var stage: Node3D
var grid_node: MeshInstance3D
var paused := false
var speed := 1.0
var game_scale := false
var angle := "Side"
var ready_for_review := false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("171e29"))
	var background := ColorRect.new()
	background.color = Color("101722")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "MIKO7  /  Sprint review"
	title.add_theme_font_size_override("font_size", 30)
	layout.add_child(title)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	layout.add_child(toolbar)
	play_button = _button(toolbar, "Pause", _toggle_pause)
	_button(toolbar, "Restart", func() -> void: player.seek(0.0, true))
	_button(toolbar, "Previous frame", func() -> void: _step(-1))
	_button(toolbar, "Next frame", func() -> void: _step(1))
	for view_name: String in ["Side", "Front", "Three-quarter"]:
		_button(toolbar, view_name, _set_angle.bind(view_name))
	var scale_button := _button(toolbar, "Game size: 96 px", _toggle_scale)
	scale_button.tooltip_text = "Toggle close-up / a 96 px reference height at the project's 1080p canvas size."
	var speed_label := Label.new()
	speed_label.text = "   Speed"
	toolbar.add_child(speed_label)
	var speed_menu := OptionButton.new()
	speed_menu.focus_mode = Control.FOCUS_NONE
	for label: String in ["0.25x", "0.5x", "1x"]:
		speed_menu.add_item(label)
	speed_menu.select(2)
	speed_menu.item_selected.connect(func(index: int) -> void:
		speed = [0.25, 0.5, 1.0][index]
		_apply_speed())
	toolbar.add_child(speed_menu)
	var container := SubViewportContainer.new()
	container.stretch = true
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.custom_minimum_size = Vector2(0, 300)
	layout.add_child(container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1400, 760)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	_build_stage()
	var model_scene := load(MODEL_PATH) as PackedScene
	if model_scene == null:
		push_error("MIKO7 model could not be loaded")
		return
	var model := model_scene.instantiate() as Node3D
	stage.add_child(model)
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_error("MIKO7 GLB has no AnimationPlayer")
		return
	player = players[0] as AnimationPlayer
	for name: StringName in player.get_animation_list():
		if String(name).to_lower().contains("sprint"):
			animation_name = name
	if animation_name.is_empty():
		push_error("Sprint animation missing; available: " + str(player.get_animation_list()))
		return
	animation = player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR
	player.play(animation_name)
	player.advance(0.0)
	var scrub_row := HBoxContainer.new()
	layout.add_child(scrub_row)
	timeline = HSlider.new()
	timeline.focus_mode = Control.FOCUS_NONE
	timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline.min_value = 0.0
	timeline.max_value = animation.length
	timeline.step = 1.0 / 30.0
	timeline.value_changed.connect(func(value: float) -> void:
		paused = true
		_apply_speed()
		player.seek(value, true))
	scrub_row.add_child(timeline)
	status = Label.new()
	status.custom_minimum_size.x = 310
	scrub_row.add_child(status)
	var help := Label.new()
	help.text = "Space: pause / play    •    Left / Right: step one frame    •    1 / 2 / 3: camera view    •    G: game size    •    R: restart"
	help.add_theme_font_size_override("font_size", 18)
	layout.add_child(help)
	var note := Label.new()
	note.text = "One corrected Sprint clip • In-place animation • The normal game opens as usual from Play MIKO.cmd"
	note.modulate = Color("9daec3")
	layout.add_child(note)
	viewport.size_changed.connect(_update_camera_size)
	_set_angle("Side")
	ready_for_review = true
	print("MIKO7_PREVIEW_READY animation=", animation_name, " length=", animation.length, " tracks=", animation.get_track_count())

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 42
	button.add_theme_font_size_override("font_size", 19)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_stage() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.008, 0.012, 0.020)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c7d5ed")
	environment.ambient_light_energy = 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	stage.add_child(environment_node)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -35, 0)
	key.light_energy = 0.9
	key.shadow_enabled = true
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 145, 0)
	fill.light_energy = 0.3
	stage.add_child(fill)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100, 100)
	floor_mesh.mesh = plane
	floor_mesh.position.y = 0.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.018, 0.024, 0.035)
	material.roughness = 0.9
	floor_mesh.material_override = material
	stage.add_child(floor_mesh)
	var grid := ImmediateMesh.new()
	var grid_material := StandardMaterial3D.new()
	grid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_material.albedo_color = Color("40516a")
	grid.surface_begin(Mesh.PRIMITIVE_LINES, grid_material)
	for i in range(-20, 21):
		var coordinate := float(i) * 0.25
		grid.surface_add_vertex(Vector3(coordinate, 0.001, -5))
		grid.surface_add_vertex(Vector3(coordinate, 0.001, 5))
		grid.surface_add_vertex(Vector3(-5, 0.001, coordinate))
		grid.surface_add_vertex(Vector3(5, 0.001, coordinate))
	grid.surface_end()
	grid_node = MeshInstance3D.new()
	grid_node.mesh = grid
	stage.add_child(grid_node)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.current = true
	stage.add_child(camera)

func _set_angle(value: String) -> void:
	angle = value
	match angle:
		"Side": camera.position = Vector3(3, 0.68, 0)
		"Front": camera.position = Vector3(0, 0.68, 3)
		_: camera.position = Vector3(2.4, 1.05, 3)
	camera.look_at(Vector3(0, 0.48, 0), Vector3.UP)
	_update_camera_size()

func _update_camera_size() -> void:
	if camera == null or viewport == null:
		return
	camera.size = float(viewport.size.y) * 1.002 / 96.0 if game_scale else 1.38
	grid_node.visible = not game_scale

func _toggle_scale() -> void:
	game_scale = not game_scale
	_update_camera_size()

func _toggle_pause() -> void:
	paused = not paused
	_apply_speed()

func _apply_speed() -> void:
	if player:
		player.speed_scale = 0.0 if paused else speed
	if play_button:
		play_button.text = "Play" if paused else "Pause"

func _step(direction: int) -> void:
	if not ready_for_review:
		return
	paused = true
	_apply_speed()
	var time := fposmod(player.current_animation_position + float(direction) / 30.0, animation.length)
	player.seek(time, true)

func _process(_delta: float) -> void:
	if not ready_for_review:
		return
	timeline.set_value_no_signal(player.current_animation_position)
	var frame := int(round(player.current_animation_position * 30.0)) + 1
	status.text = "  Frame %02d  |  %.2fx  |  %s" % [frame, speed, "96 px reference" if game_scale else "Detail view"]

func _unhandled_key_input(event: InputEvent) -> void:
	if not ready_for_review or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_SPACE: _toggle_pause()
		KEY_LEFT: _step(-1)
		KEY_RIGHT: _step(1)
		KEY_1: _set_angle("Side")
		KEY_2: _set_angle("Front")
		KEY_3: _set_angle("Three-quarter")
		KEY_G: _toggle_scale()
		KEY_R: player.seek(0.0, true)
		KEY_ESCAPE: get_tree().quit()
