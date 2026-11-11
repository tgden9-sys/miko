extends SceneTree

var materials: Array[ShaderMaterial] = []
var status: Label
var sprites: Array[AnimatedSprite2D] = []

func _initialize() -> void:
	call_deferred("_run")

func _label(text: String, pos: Vector2, size: int, color: Color = Color("d6e3ed")) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	return label

func _run() -> void:
	root.size = Vector2i(1200, 640)
	root.content_scale_size = Vector2i(1200, 640)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_v29/exhaust_frames"))
	_label("MIKO / EXHAUST STUDIES", Vector2(42, 22), 24)
	_label("Same nozzle. Continuous flowing effects. Enlarged for comparison.", Vector2(42, 56), 16, Color("8fa6ba"))
	var names := ["A / SOFT VAPOUR", "B / BLUE FLAME", "C / HOT CORE + VAPOUR"]
	var descriptions := ["Quiet, soft and mechanical", "Full-width turbulent flame", "Bright engine with a soft wake"]
	for i in range(3):
		var x: float = 200 + i * 400
		_label(names[i], Vector2(x - 154, 106), 19)
		_label(descriptions[i], Vector2(x - 154, 135), 15, Color("8fa6ba"))
		var exhaust := ColorRect.new()
		# Projected nozzle centre in idle_000 is (218, 284), not sprite centre.
		exhaust.position = Vector2(x + 25.5 - 114, 343)
		exhaust.size = Vector2(228, 215)
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/procedural_exhaust.gdshader")
		mat.set_shader_parameter("style", i)
		exhaust.material = mat
		materials.append(mat)
		root.add_child(exhaust)
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = load("res://sprites/robot_frames.tres")
		sprite.animation = &"idle"
		sprite.position = Vector2(x, 254)
		sprite.scale = Vector2(0.98, 0.98)
		root.add_child(sprite)
		sprites.append(sprite)
	status = _label("IDLE / gentle output", Vector2(42, 580), 23)
	_label("The same boost response would be used for ascending a ladder.", Vector2(42, 614), 15, Color("8fa6ba"))
	# Explicit time makes these captured previews reproducible.
	for frame in range(120):
		var time: float = frame / 20.0
		var power: float = 0.16
		if time >= 2.0 and time < 4.0:
			power = 0.16 + 0.84 * smoothstep(2.0, 2.30, time)
			status.text = "JUMP / stronger downward thrust"
		elif time >= 4.0:
			power = 0.8
			status.text = "LADDER ASCENT / sustained output"
		for i in range(3):
			materials[i].set_shader_parameter("flow_time", time)
			materials[i].set_shader_parameter("thrust", power)
			sprites[i].frame = int(time * 16) % sprites[i].sprite_frames.get_frame_count(&"idle")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://qa_v29/exhaust_frames/%03d.png" % frame)
	print("EXHAUST_PREVIEW_COMPLETE")
	quit()
