extends Control

const FIRST_LEVEL := "res://scenes/miko8_side_on_mockup.tscn"
const CANVAS := Vector2(1920, 1080)
const AMBER := Color("#dda455")
const IVORY := Color("#f5eddf")
const MUTED := Color("#a4b4c3")
const CITY := preload("res://art/cel_scene/city_far_bokeh_v1.png")
const MIKO := preload("res://models/miko8/MIKO8_Native.glb")
const SUIT := preload("res://shaders/miko8_three_tone.gdshader")

var composition: Control
var backdrop: TextureRect
var start_button: Button
var fade: ColorRect
var starting := false

func _ready() -> void:
	backdrop = TextureRect.new()
	backdrop.texture = CITY
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color("#8191a7")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	composition = Control.new()
	composition.size = CANVAS
	add_child(composition)
	composition.draw.connect(_draw_frame)

	_make_hero()
	var heading := SystemFont.new()
	heading.font_names = PackedStringArray(["Bahnschrift", "Arial"])
	heading.font_weight = 800
	var wordmark := HBoxContainer.new()
	wordmark.position = Vector2(126, 304)
	wordmark.add_theme_constant_override("separation", 8)
	composition.add_child(wordmark)
	for part: String in ["MIKO", "7"]:
		var letter := Label.new()
		letter.text = part
		letter.add_theme_font_override("font", heading)
		letter.add_theme_font_size_override("font_size", 195)
		letter.add_theme_color_override("font_color", AMBER if part == "7" else IVORY)
		wordmark.add_child(letter)

	_label("S E R V I C E   Y A R D     /     0 1", Vector2(142, 263), 22, AMBER)
	_label("Magnetic Intelligent Kinetic Operator", Vector2(141, 537), 34, IVORY)
	_label("ENTER   /   B", Vector2(144, 754), 20, MUTED)
	_label("SUBSTATION 04", Vector2(1458, 922), 24, IVORY)
	_label("S E R V I C E   N E T W O R K", Vector2(1458, 960), 15, MUTED)

	start_button = Button.new()
	start_button.text = "Start Game    →"
	start_button.position = Vector2(140, 657)
	start_button.size = Vector2(334, 74)
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	start_button.add_theme_font_size_override("font_size", 28)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#e9b96c") if state == "hover" else AMBER
		style.set_corner_radius_all(4)
		if state == "focus":
			style.draw_center = false
			style.border_color = IVORY
			style.set_border_width_all(2)
			style.set_expand_margin_all(5)
		start_button.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		start_button.add_theme_color_override(state, Color("#201c19"))
	start_button.pressed.connect(_start)
	composition.add_child(start_button)
	start_button.grab_focus()

	fade = ColorRect.new()
	fade.color = Color.TRANSPARENT
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_fit_composition)
	_fit_composition()

func _fit_composition() -> void:
	var fit := minf(size.x / CANVAS.x, size.y / CANVAS.y)
	composition.scale = Vector2.ONE * fit
	composition.position = (size - CANVAS * fit) * 0.5

func _label(value: String, at: Vector2, font_size: int, tint: Color) -> void:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_color_override("font_color", tint)
	label.add_theme_font_size_override("font_size", font_size)
	composition.add_child(label)

func _draw_frame() -> void:
	# Darken the artwork beneath the wordmark, leaving the city visible behind Miko.
	var left := Color(0.016, 0.025, 0.045, 0.96)
	var right := Color(0.016, 0.025, 0.045, 0.33)
	composition.draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(1250, 0), Vector2(1250, 1080), Vector2(0, 1080)]),
		PackedColorArray([left, right, right, left])
	)
	composition.draw_rect(Rect2(1250, 0, 670, 1080), right)
	var center := Vector2(1368, 514)
	composition.draw_circle(center, 321.0, Color(0.025, 0.045, 0.079, 0.72), true, -1.0, true)
	composition.draw_arc(center, 321.0, 0.0, TAU, 128, Color("#526477"), 2.0, true)
	composition.draw_arc(center, 342.0, -2.98, -2.14, 40, AMBER, 3.0, true)
	composition.draw_arc(center, 342.0, 0.35, 1.20, 40, Color("#74acc3"), 3.0, true)
	for tick in range(48):
		var direction := Vector2.from_angle(tick * TAU / 48.0)
		composition.draw_line(center + direction * 327.0, center + direction * 332.0, Color("#738496"), 1.5, true)
	composition.draw_line(Vector2(140, 117), Vector2(1780, 117), Color("#526477"), 1.0)
	composition.draw_line(Vector2(140, 1000), Vector2(1780, 1000), Color("#526477"), 1.0)
	composition.draw_rect(Rect2(140, 117, 72, 4), AMBER)
	composition.draw_rect(Rect2(140, 599, 66, 3), AMBER)
	composition.draw_rect(Rect2(213, 599, 467, 1), Color("#526477"))

func _make_hero() -> void:
	var panel := SubViewportContainer.new()
	panel.position = Vector2(993, 99)
	panel.size = Vector2(750, 830)
	panel.stretch = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	composition.add_child(panel)
	var view := SubViewport.new()
	view.transparent_bg = true
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_2X
	panel.add_child(view)

	var model := MIKO.instantiate() as Node3D
	model.rotation.y = deg_to_rad(-22.0)
	view.add_child(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.28
	camera.position = Vector3(0, 1.02, 4)
	view.add_child(camera)
	camera.make_current()

	var outline := ShaderMaterial.new()
	outline.shader = preload("res://shaders/miko8_cel_outline.gdshader")
	outline.set_shader_parameter("base_thickness", 0.004)
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var paint := ShaderMaterial.new()
			paint.shader = SUIT
			paint.set_shader_parameter("base_texture", source.albedo_texture)
			paint.set_shader_parameter("key_direction", Vector3(-0.38, 0.6, 0.73))
			paint.set_shader_parameter("rim_light_pos", Vector3(1.6, 1.6, -0.8))
			paint.set_shader_parameter("rim_intensity", 0.42)
			paint.next_pass = outline
			mesh.set_surface_override_material(surface, paint)

	var idle := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	idle.play("MIKO8_Idle")
	idle.get_animation("MIKO8_Idle").loop_mode = Animation.LOOP_LINEAR

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		get_viewport().set_input_as_handled()
		_start()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_start()

func _start() -> void:
	if starting:
		return
	starting = true
	start_button.disabled = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var transition := create_tween()
	transition.tween_property(fade, "color", Color.BLACK, 0.26)
	await transition.finished
	var result := get_tree().change_scene_to_file(FIRST_LEVEL)
	if result != OK:
		push_error("Could not start MIKO7: " + error_string(result))
		fade.color = Color.TRANSPARENT
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		start_button.disabled = false
		start_button.grab_focus()
		starting = false
