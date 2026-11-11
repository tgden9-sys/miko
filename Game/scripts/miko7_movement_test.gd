extends Node3D

const ACTOR_SCRIPT := preload("res://scripts/miko7_locomotion_actor.gd")
var actor: CharacterBody3D
var camera: Camera3D
var status: Label
var controller_label: Label
var pause_button: Button
var paused := false
var quarter_view := false
var follow_x := 0.0
var walk_review := false

func _ready() -> void:
	walk_review = "--walk-review" in OS.get_cmdline_user_args()
	DisplayServer.window_set_title("MIKO7 — Walk & jump review v6" if walk_review else "MIKO7 — Movement review v6")
	_build_world()
	actor = CharacterBody3D.new()
	actor.name = "MIKO7"
	actor.set_script(ACTOR_SCRIPT)
	add_child(actor)
	actor.walk_only = walk_review
	_build_hud()
	print("MIKO7_MOVEMENT_READY: left stick = walk/sprint; B = jump")

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
	_box(Vector3(0, -0.10, 0), Vector3(24, 0.20, 3.5), Color(0.018, 0.024, 0.035))
	_box(Vector3(4.5, 0.125, 0), Vector3(1.3, 0.25, 1.1), Color(0.055, 0.09, 0.12))
	_box(Vector3(-4.5, 0.20, 0), Vector3(1.6, 0.40, 1.1), Color(0.075, 0.065, 0.11))
	_box(Vector3(7.1, 0.25, 0), Vector3(1.3, 0.50, 1.1), Color(0.055, 0.09, 0.12))
	for x in [-10.0, 10.0]:
		_box(Vector3(x, 0.6, 0), Vector3(0.20, 1.2, 1.2), Color(0.10, 0.04, 0.03))
	var grid := ImmediateMesh.new()
	var grid_material := StandardMaterial3D.new()
	grid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_material.albedo_color = Color(0.055, 0.075, 0.095)
	grid.surface_begin(Mesh.PRIMITIVE_LINES, grid_material)
	for i in range(-48, 49):
		var x := float(i) * 0.25
		grid.surface_add_vertex(Vector3(x, 0.001, -1.75))
		grid.surface_add_vertex(Vector3(x, 0.001, 1.75))
	for i in range(-7, 8):
		var z := float(i) * 0.25
		grid.surface_add_vertex(Vector3(-12, 0.001, z))
		grid.surface_add_vertex(Vector3(12, 0.001, z))
	grid.surface_end()
	var lines := MeshInstance3D.new()
	lines.mesh = grid
	add_child(lines)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 2.65
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
	title.text = "MIKO7  /  Walk & jump review" if walk_review else "MIKO7  /  Movement review v6"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)
	var instructions := Label.new()
	instructions.text = "Left stick: WALK at any tilt     •     Walk-only review" if walk_review else "Left stick: tilt to WALK, push fully to SPRINT     •     B / Circle: JUMP"
	instructions.add_theme_font_size_override("font_size", 22)
	layout.add_child(instructions)
	var keyboard := Label.new()
	keyboard.text = "Keyboard: A/D or arrows: walk • Space: jump • R: reset • P: pause" if walk_review else "Keyboard: A/D or arrows • Shift: sprint • Space: jump • R: reset • P: pause"
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
	_button(row, "Reset", func() -> void: actor.reset_actor())
	_button(row, "Camera angle", func() -> void: quarter_view = not quarter_view)
	pause_button = _button(row, "Pause", _toggle_pause)
	status = Label.new()
	layout.add_child(status)
	controller_label = Label.new()
	controller_label.modulate = Color("aebed3")
	layout.add_child(controller_label)

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _toggle_pause() -> void:
	paused = not paused
	actor.set_physics_process(not paused)
	pause_button.text = "Play" if paused else "Pause"

func _process(delta: float) -> void:
	if not actor or not actor.ready_for_input:
		return
	follow_x = lerpf(follow_x, actor.position.x, 1.0 - exp(-6.0 * delta))
	var lift := maxf(0.0, actor.position.y) * 0.30
	camera.position = Vector3(follow_x + (2.5 if quarter_view else 0.0), 1.35 + lift, 5.0)
	camera.look_at(Vector3(follow_x, 0.85 + lift, 0), Vector3.UP)
	status.text = "State: %s    •    Clip: %s    •    Speed: %.2f m/s" % [actor.state, actor.current_clip, absf(actor.velocity.x)]
	var devices := Input.get_connected_joypads()
	controller_label.text = "Controller: " + Input.get_joy_name(devices[0]) if not devices.is_empty() else "Connect a controller, or use the keyboard controls above."

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_R: actor.reset_actor()
		KEY_P: _toggle_pause()
		KEY_ESCAPE: get_tree().quit()
