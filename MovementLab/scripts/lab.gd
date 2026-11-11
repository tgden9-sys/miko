extends Node3D
var actor: CharacterBody3D
var dummy: CharacterBody3D
var camera: Camera3D
var status: Label
var diagnostics: Label
var style_banner: Label
var trauma := 0.0
var zoomed := false
var sparks: Array[Dictionary] = []
var frame_samples: Array[float] = []
var course_title := "MIKO  /  MOVEMENT LAB"
var course_note := "ANIMATION STUDY * Single sword / aerial combo / uppercut / double jump / ground pound."
var course_shadows := true
var course_polarity_controls := false
var course_target_model: PackedScene

func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("17202a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c8d4df")
	environment.ambient_light_energy = .7
	world.environment = environment
	add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55,-30,0)
	key.light_energy = 1.1
	key.shadow_enabled = course_shadows
	add_child(key)
	_build_course()
	actor = preload("res://scripts/actor.gd").new()
	actor.name = "Miko"
	actor.polarity_controls = course_polarity_controls
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--model="): actor.model_path = argument.trim_prefix("--model=")
	add_child(actor)
	actor.impact.connect(_impact)
	actor.attack_effect.connect(_attack_effect)
	actor.sword_style_changed.connect(_on_sword_style_changed)
	dummy = preload("res://scripts/agile_droid.gd").new() if course_target_model else preload("res://scripts/dummy.gd").new()
	dummy.name = "AgileDroid" if course_target_model else "Dummy"
	dummy.actor = actor
	dummy.model_scene = course_target_model
	add_child(dummy)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9.2
	camera.position = Vector3(.5,3.2,18)
	camera.current = true
	add_child(camera)
	_build_ui()
	print("MOVEMENT_LAB_READY model=",actor.model_path," bones=",actor.skeleton.get_bone_count())

func _build_course() -> void:
	_block("Floor", Vector3(0,-.25,0),Vector3(27,.5,3),Color("4a555d"))
	_block("JumpPlatform", Vector3(4.8,.72,0),Vector3(3.6,1.44,2.4),Color("7a9294"))
	_block("LeftBoundary",Vector3(-13.5,3,0),Vector3(.2,6,3),Color.TRANSPARENT,false)
	_block("RightBoundary",Vector3(13.5,3,0),Vector3(.2,6,3),Color.TRANSPARENT,false)

func _block(label: String, location: Vector3, size: Vector3, color: Color, visible_mesh := true) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = location
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	if visible_mesh:
		var display := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		display.mesh = box
		var paint := StandardMaterial3D.new()
		paint.albedo_color = color
		paint.roughness = 1
		display.material_override = paint
		body.add_child(display)
	add_child(body)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = course_title
	title.position = Vector2(36,26)
	title.add_theme_font_size_override("font_size",28)
	layer.add_child(title)
	var controls := Label.new()
	controls.position = Vector2(36,66)
	controls.add_theme_font_size_override("font_size",19)
	controls.text = "A  JUMP / DOUBLE JUMP     X  SWORD     B  DASH     LB  PARRY     RB  CYCLE SWORDS [1-10]\nUP + X  LAUNCH     DOWN + X in air  SLAM     Y  DUMMY ATTACKS     View  RESET     R3  CLOSE VIEW"
	layer.add_child(controls)
	style_banner = Label.new()
	style_banner.position = Vector2(36, 116)
	style_banner.add_theme_font_size_override("font_size", 19)
	style_banner.modulate = Color("7ce8ff")
	var cur_s: Dictionary = actor.SWORD_STYLES[actor.sword_style]
	style_banner.text = "STYLE [%d/10]  %s:  %s  (Cycle: C / Tab / 1-0)" % [actor.sword_style + 1, cur_s.name.to_upper(), cur_s.desc]
	layer.add_child(style_banner)
	var keyboard := Label.new()
	keyboard.text = "Keyboard: A/D move * Space jump * J sword * Shift dash * K parry * C/Tab/E next style * Q prev * 1-0 direct style * T dummy * R reset * Z view"
	keyboard.position = Vector2(36,1006)
	keyboard.add_theme_font_size_override("font_size",18)
	keyboard.modulate = Color("9fadb8")
	layer.add_child(keyboard)
	var note := Label.new()
	note.text = course_note
	note.position = Vector2(36,1038)
	note.add_theme_font_size_override("font_size",18)
	note.modulate = Color("c7ac79")
	layer.add_child(note)
	status = Label.new()
	status.position = Vector2(36,150)
	status.add_theme_font_size_override("font_size",19)
	layer.add_child(status)
	diagnostics = Label.new()
	diagnostics.position = Vector2(36,186)
	diagnostics.add_theme_font_size_override("font_size",16)
	diagnostics.modulate = Color("9fadb8")
	layer.add_child(diagnostics)

func _on_sword_style_changed(index: int, s_name: String, desc: String) -> void:
	if style_banner:
		style_banner.text = "STYLE [%d/10]  %s:  %s  (Cycle: C / Tab / 1-0)" % [index + 1, s_name.to_upper(), desc]

func reset_room() -> void:
	for effect: Node in get_tree().get_nodes_in_group("attack_effects"): effect.queue_free()
	actor.reset()
	dummy.reset()
	trauma = 0

func _process(delta: float) -> void:
	if dummy.arm and Input.is_action_just_pressed("dummy"): dummy.attacking = not dummy.attacking
	if Input.is_action_just_pressed("zoom"): zoomed = not zoomed
	if Input.is_physical_key_pressed(KEY_ESCAPE): get_tree().quit()
	trauma = move_toward(trauma,0,delta*5)
	_update_camera(delta)
	_update_status()
	for i in range(sparks.size()-1,-1,-1):
		var spark: Dictionary = sparks[i]
		spark.life -= delta
		spark.node.position += spark.velocity*delta
		spark.velocity.y -= 14*delta
		var max_l: float = spark.get("max_life", 0.18)
		spark.node.scale = Vector3.ONE*maxf(.01, spark.life / max_l)
		if spark.life <= 0:
			spark.node.queue_free()
			sparks.remove_at(i)

func _update_camera(delta: float) -> void:
	# Keep the starting character, dummy and complete platform in one view.
	var focus_x := .5
	if actor.position.x < -6.4: focus_x = actor.position.x+6.9
	elif actor.position.x > 7.4: focus_x = actor.position.x-6.9
	if zoomed: focus_x = actor.position.x
	camera.size = lerpf(camera.size,4.5 if zoomed else 9.2,1-exp(-delta*9))
	camera.position.x = lerpf(camera.position.x,focus_x,1-exp(-delta*7))
	camera.position.y = (actor.position.y+1.7 if zoomed else 3.2)+sin(Time.get_ticks_msec()*.11)*trauma*.06

func _update_status() -> void:
	status.text = "Health %d   |   Parries %d   |   %s" % [actor.health, actor.parry_count, "Dummy attacks ON" if dummy.attacking else "Dummy attacks OFF"]
	diagnostics.text = "%s   |   %d FPS" % [actor.state.to_upper(), Engine.get_frames_per_second()]

func _impact(point: Vector3, strength: float) -> void:
	var contact := preload("res://scripts/contact_flash.gd").new()
	contact.position = point + Vector3(0, 0, 0.65)
	contact.heavy = strength > 0.45
	contact.add_to_group("attack_effects")
	add_child(contact)
	trauma = maxf(trauma, strength * 0.7)
	var count := 9 if strength > 0.45 else 6
	var facing_dir := float(actor.facing)
	for i in range(count):
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		var spark_len := randf_range(0.18, 0.28) if strength > 0.45 else randf_range(0.12, 0.20)
		box.size = Vector3(spark_len, 0.024, 0.024)
		mesh.mesh = box
		var paint := StandardMaterial3D.new()
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if strength > 0.45:
			paint.albedo_color = Color("ffffff") if i % 2 == 0 else Color("fae0a0")
		else:
			paint.albedo_color = Color("ffffff") if i % 2 == 0 else Color("b8cad2")
		mesh.material_override = paint
		mesh.position = point + Vector3(0, 0, 0.4)
		var base_angle := randf_range(-0.65, 0.75)
		mesh.rotation.z = base_angle
		add_child(mesh)
		var speed := randf_range(6.5, 11.0) + strength * 4.0
		var vel := Vector3(cos(base_angle) * facing_dir, sin(base_angle), 0.0) * speed
		sparks.append({"node": mesh, "life": 0.18, "max_life": 0.18, "velocity": vel})

func _attack_effect(point: Vector3, direction: int, variant: int, slam: bool) -> void:
	if not slam: return
	var effect := preload("res://scripts/attack_fx.gd").new()
	effect.position = point
	effect.direction = direction
	effect.variant = variant
	effect.slam = slam
	effect.floor_height = actor.position.y if actor.is_on_floor() or slam else 0.0
	effect.add_to_group("attack_effects")
	add_child(effect)
	if slam:
		trauma = maxf(trauma, .95)
	elif variant == 2:
		trauma = maxf(trauma, .40)
	elif variant == 3:
		trauma = maxf(trauma, .35)
