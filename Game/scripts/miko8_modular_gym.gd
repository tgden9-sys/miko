extends Node3D
## MIKO 8 — Modular Platform Testing Gym
## Interactive laboratory for testing the user's actual 3D assets:
## - MOD-02: Modular Ladder Tower (res://models/environment/modular_platform/mod02_column_ladder_optimized.glb)
## - MOD-04: Catwalk Deck (res://models/environment/modular_platform/mod04_catwalk_deck_optimized.glb)

const ACTOR_SCRIPT := preload("res://scripts/miko8_actor.gd")
const CEL_SHADER := preload("res://shaders/miko8_modular_cel_prop.gdshader")
const OUTLINE_SHADER := preload("res://shaders/miko8_gym_cel_outline.gdshader")

var actor: CharacterBody3D
var camera: Camera3D
var platform_root: Node3D
var ladder_node: Node3D
var deck_body: StaticBody3D

# Asset Templates & Textures loaded via GLTFDocument
var tower_mesh_template: MeshInstance3D
var catwalk_mesh_template: MeshInstance3D
var tower_albedo_tex: Texture2D
var catwalk_albedo_tex: Texture2D
var tower_normal_tex: Texture2D
var catwalk_normal_tex: Texture2D

# Configurable Gym Parameters
var config_mode: int = 0      # 0 = Wide Catwalk-Matched (2.4m), 1 = Twin-Column Gantry, 2 = Native Scale (0.54m)
var tower_height: float = 3.20 # 3.20m, 3.60m, 2.80m, 1.80m
var shading_mode: int = 0      # 0 = Crisp Anime Cel, 1 = Raw Unshaded Texture, 2 = Standard Lit PBR
var camera_mode: int = 0       # 0 = Gentle 3D, 1 = Straight Ortho, 2 = Close-Up, 3 = Free Orbit

# Free Orbit Camera Controls
var orbit_yaw: float = 0.0
var orbit_pitch: float = 12.0
var orbit_dist: float = 7.5
var is_orbit_dragging: bool = false
var last_mouse_pos: Vector2

# UI Elements
var info_label: Label
var hud_layer: CanvasLayer
var config_option: OptionButton
var height_option: OptionButton
var shading_option: OptionButton
var camera_option: OptionButton

func _ready() -> void:
	DisplayServer.window_set_title("MIKO — Modular Platform Testing Gym (Actual 3D Assets)")
	_load_source_assets()
	_build_gym_world()
	
	actor = CharacterBody3D.new()
	actor.name = "MIKO8"
	actor.set_script(ACTOR_SCRIPT)
	actor.position = Vector3(-1.4, 0.02, 0.0)
	add_child(actor)
	actor.movement_only = false
	if actor.polarity_control:
		actor.polarity_control.set_process_unhandled_input(true)
	if actor.launcher_motion:
		actor.launcher_motion.enabled = true
	
	_rebuild_platform()
	_build_hud()
	_update_camera(0.0, true)
	print("MODULAR_GYM_READY: Actual GLB 3D assets loaded. User controls active.")

func _load_source_assets() -> void:
	# Load MOD-02 Tower
	var gltf_tower := GLTFDocument.new()
	var state_tower := GLTFState.new()
	var err_t := gltf_tower.append_from_file("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb", state_tower)
	if err_t == OK:
		var scene_t: Node = gltf_tower.generate_scene(state_tower)
		for child in scene_t.get_children():
			if child is MeshInstance3D:
				tower_mesh_template = child.duplicate()
				var mat = child.mesh.surface_get_material(0)
				if mat is StandardMaterial3D:
					tower_albedo_tex = mat.albedo_texture
					tower_normal_tex = mat.normal_texture
				break
		scene_t.queue_free()
	else:
		push_error("MODULAR_GYM: Failed to load MOD-02 tower GLB!")

	# Load MOD-04 Catwalk
	var gltf_catwalk := GLTFDocument.new()
	var state_catwalk := GLTFState.new()
	var err_c := gltf_catwalk.append_from_file("res://models/environment/modular_platform/mod04_catwalk_deck_optimized.glb", state_catwalk)
	if err_c == OK:
		var scene_c: Node = gltf_catwalk.generate_scene(state_catwalk)
		for child in scene_c.get_children():
			if child is MeshInstance3D:
				catwalk_mesh_template = child.duplicate()
				var mat = child.mesh.surface_get_material(0)
				if mat is StandardMaterial3D:
					catwalk_albedo_tex = mat.albedo_texture
					catwalk_normal_tex = mat.normal_texture
				break
		scene_c.queue_free()
	else:
		push_error("MODULAR_GYM: Failed to load MOD-04 catwalk GLB!")

func _unhandled_input(event: InputEvent) -> void:
	# Keyboard Hotkeys
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				shading_mode = 0
				shading_option.select(0)
				_apply_shading()
			KEY_2:
				shading_mode = 1
				shading_option.select(1)
				_apply_shading()
			KEY_3:
				shading_mode = 2
				shading_option.select(2)
				_apply_shading()
			KEY_TAB:
				camera_mode = (camera_mode + 1) % 4
				camera_option.select(camera_mode)
				_update_camera(0.0, true)
			KEY_R:
				actor.reset_actor()
				actor.position = Vector3(-1.4, 0.02, 0.0)
				actor.velocity = Vector3.ZERO
	
	# Orbit Camera Mouse Drag
	if camera_mode == 3:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
				is_orbit_dragging = event.pressed
				last_mouse_pos = event.position
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				orbit_dist = clampf(orbit_dist - 0.5, 2.0, 15.0)
				_update_camera(0.0, true)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				orbit_dist = clampf(orbit_dist + 0.5, 2.0, 15.0)
				_update_camera(0.0, true)
		elif event is InputEventMouseMotion and is_orbit_dragging:
			var delta: Vector2 = event.position - last_mouse_pos
			last_mouse_pos = event.position
			orbit_yaw -= delta.x * 0.4
			orbit_pitch = clampf(orbit_pitch + delta.y * 0.4, -20.0, 80.0)
			_update_camera(0.0, true)

func _process(delta: float) -> void:
	_update_camera(delta)
	_update_hud()

func _update_camera(delta: float, immediate := false) -> void:
	if not camera or not actor:
		return
	var target_x: float = actor.position.x
	var target_y: float = clampf(actor.position.y + 1.2, 1.8, 6.0)
	
	if camera_mode == 0:
		# Gentle 3D side-on (matching game camera)
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		var pitch := deg_to_rad(6.0)
		var yaw := -deg_to_rad(7.0)
		var dist := 10.0
		var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
		var screen_right: Vector3 = (Vector3.RIGHT - back * back.x).normalized()
		var screen_up := back.cross(screen_right).normalized()
		camera.size = 5.5
		camera.position = Vector3(target_x, target_y, 0.0) + back * dist
		camera.basis = Basis(screen_right, screen_up, back)
	elif camera_mode == 1:
		# Straight Orthogonal Side-On
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 5.2
		camera.position = Vector3(target_x, target_y, 10.0)
		camera.rotation_degrees = Vector3.ZERO
	elif camera_mode == 2:
		# Close-Up Ladder Inspection
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 3.0
		var ladder_x := 0.0 if config_mode != 1 else -0.90
		camera.position = Vector3(ladder_x, 1.9, 8.0)
		camera.rotation_degrees = Vector3(2.0, -3.0, 0.0)
	elif camera_mode == 3:
		# Free Orbit 3D Inspection
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 50.0
		var center := Vector3(0.0, tower_height * 0.5, -0.50)
		var yaw_rad := deg_to_rad(orbit_yaw)
		var pitch_rad := deg_to_rad(orbit_pitch)
		var offset := Vector3(
			sin(yaw_rad) * cos(pitch_rad),
			sin(pitch_rad),
			cos(yaw_rad) * cos(pitch_rad)
		) * orbit_dist
		camera.position = center + offset
		camera.look_at(center, Vector3.UP)

func _get_material_for_asset(albedo_tex: Texture2D, normal_tex: Texture2D) -> Material:
	if shading_mode == 0:
		# Crisp Anime Cel with Inverted-Hull Ink Outline
		var cel := ShaderMaterial.new()
		cel.shader = CEL_SHADER
		cel.set_shader_parameter("use_texture", true)
		cel.set_shader_parameter("base_texture", albedo_tex)
		cel.set_shader_parameter("base_color", Color(1.0, 1.0, 1.0, 1.0))
		cel.set_shader_parameter("key_direction", Vector3(-0.45, 0.75, 0.48))
		cel.set_shader_parameter("shadow_threshold", 0.15)
		cel.set_shader_parameter("light_threshold", 0.58)
		cel.set_shader_parameter("shadow_tone", Color(0.30, 0.34, 0.42))
		cel.set_shader_parameter("middle_tone", Color(0.80, 0.82, 0.85))
		cel.set_shader_parameter("light_tone", Color(1.10, 1.06, 0.98))
		cel.set_shader_parameter("rim_intensity", 0.28)
		
		var outline := ShaderMaterial.new()
		outline.shader = OUTLINE_SHADER
		outline.set_shader_parameter("ink_color", Color(0.015, 0.020, 0.028))
		outline.set_shader_parameter("thickness", 0.004)
		cel.next_pass = outline
		return cel
	elif shading_mode == 1:
		# Pure Raw Unshaded Texture View
		var unshaded := StandardMaterial3D.new()
		unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		unshaded.albedo_texture = albedo_tex
		return unshaded
	else:
		# Standard Lit PBR with Normal Maps & Roughness
		var pbr := StandardMaterial3D.new()
		pbr.albedo_texture = albedo_tex
		pbr.normal_enabled = (normal_tex != null)
		pbr.normal_texture = normal_tex
		pbr.roughness = 0.65
		pbr.metallic = 0.4
		return pbr

func _apply_shading() -> void:
	if not is_instance_valid(platform_root):
		return
	var tower_mat := _get_material_for_asset(tower_albedo_tex, tower_normal_tex)
	var catwalk_mat := _get_material_for_asset(catwalk_albedo_tex, catwalk_normal_tex)
	
	for node in platform_root.get_children():
		if node.name.begins_with("Tower"):
			if node is MeshInstance3D:
				node.material_override = tower_mat
			for m in node.find_children("*", "MeshInstance3D", true, false):
				m.material_override = tower_mat
		elif node.name.begins_with("Catwalk"):
			if node is MeshInstance3D:
				node.material_override = catwalk_mat
			for m in node.find_children("*", "MeshInstance3D", true, false):
				m.material_override = catwalk_mat

func _rebuild_platform() -> void:
	if is_instance_valid(platform_root):
		platform_root.queue_free()
	
	platform_root = Node3D.new()
	platform_root.name = "ModularAssembly"
	add_child(platform_root)
	
	var tower_mat := _get_material_for_asset(tower_albedo_tex, tower_normal_tex)
	var catwalk_mat := _get_material_for_asset(catwalk_albedo_tex, catwalk_normal_tex)
	
	# Native bounds:
	# MOD-02 Tower:  Width X = 0.541817, Height Y = 1.8000, Depth Z = 0.548725
	# MOD-04 Catwalk: Length X = 2.4000, Deck Height Y = 0.237, Rail Height = 0.868, Depth Z = 1.0060
	const NATIVE_TOWER_W: float = 0.541817
	const NATIVE_TOWER_H: float = 1.800000
	const NATIVE_TOWER_D: float = 0.548725
	
	var ladder_climb_x: float = 0.0
	var ladder_climb_z: float = 0.0
	var ladder_width_disp: float = 0.80
	
	if config_mode == 0:
		# =========================================================================
		# CONFIGURATION 0: Wide Catwalk-Matched Integrated Tower (User's Directive)
		# "the tower has a ladder built into it. the ladder tower should be wide enougth to sit the catwalk on."
		# =========================================================================
		var target_w: float = 2.40
		var target_d: float = 1.00
		var scale_x: float = target_w / NATIVE_TOWER_W
		var scale_y: float = tower_height / NATIVE_TOWER_H
		var scale_z: float = target_d / NATIVE_TOWER_D
		
		# Place Tower so front ladder face is at Z = 0.0 (Miko's walk plane)
		# Native tower is centered at Z=0 (-0.274 to +0.274), so scaled depth is -0.50 to +0.50.
		# Moving tower to Z = -0.50 aligns its front face (+Z) with Z = 0.00!
		var tower_inst: MeshInstance3D = tower_mesh_template.duplicate()
		tower_inst.name = "Tower_Wide"
		tower_inst.scale = Vector3(scale_x, scale_y, scale_z)
		tower_inst.position = Vector3(0.0, 0.0, -0.50)
		tower_inst.material_override = tower_mat
		platform_root.add_child(tower_inst)
		
		# Place Catwalk squarely on top of the tower top plate (Y = tower_height)
		# Rotate 180 deg (Y = PI) so guardrail is at the rear (Z = -1.0) and front is open at Z = 0.0
		var catwalk_inst: MeshInstance3D = catwalk_mesh_template.duplicate()
		catwalk_inst.name = "Catwalk_Deck"
		catwalk_inst.position = Vector3(0.0, tower_height, -0.50)
		catwalk_inst.rotation.y = PI
		catwalk_inst.material_override = catwalk_mat
		platform_root.add_child(catwalk_inst)
		
		ladder_climb_x = 0.0
		ladder_climb_z = 0.0
		# Native ladder is ~0.32m wide; scaled by scale_x (4.43) it spans ~1.40m wide
		ladder_width_disp = 1.40
		
	elif config_mode == 1:
		# =========================================================================
		# CONFIGURATION 1: Twin-Column Gantry
		# Two standard modular columns at X = -0.90m and X = +0.90m supporting the catwalk
		# =========================================================================
		var col_scale_x: float = 0.60 / NATIVE_TOWER_W
		var col_scale_y: float = tower_height / NATIVE_TOWER_H
		var col_scale_z: float = 0.60 / NATIVE_TOWER_D
		
		for side in [-0.90, 0.90]:
			var col: MeshInstance3D = tower_mesh_template.duplicate()
			col.name = "Tower_Col_" + ("L" if side < 0 else "R")
			col.scale = Vector3(col_scale_x, col_scale_y, col_scale_z)
			col.position = Vector3(side, 0.0, -0.30)
			col.material_override = tower_mat
			platform_root.add_child(col)
		
		# Catwalk spanning across both columns
		var catwalk_inst: MeshInstance3D = catwalk_mesh_template.duplicate()
		catwalk_inst.name = "Catwalk_Deck"
		catwalk_inst.position = Vector3(0.0, tower_height, -0.30)
		catwalk_inst.rotation.y = PI
		catwalk_inst.material_override = catwalk_mat
		platform_root.add_child(catwalk_inst)
		
		ladder_climb_x = -0.90
		ladder_climb_z = 0.0
		ladder_width_disp = 0.45
		
	else:
		# =========================================================================
		# CONFIGURATION 2: Native Scale Column (0.54m Width)
		# =========================================================================
		var scale_y: float = tower_height / NATIVE_TOWER_H
		var tower_inst: MeshInstance3D = tower_mesh_template.duplicate()
		tower_inst.name = "Tower_Native"
		tower_inst.scale = Vector3(1.0, scale_y, 1.0)
		tower_inst.position = Vector3(0.0, 0.0, -0.27)
		tower_inst.material_override = tower_mat
		platform_root.add_child(tower_inst)
		
		var catwalk_inst: MeshInstance3D = catwalk_mesh_template.duplicate()
		catwalk_inst.name = "Catwalk_Deck"
		catwalk_inst.position = Vector3(0.0, tower_height, -0.27)
		catwalk_inst.rotation.y = PI
		catwalk_inst.material_override = catwalk_mat
		platform_root.add_child(catwalk_inst)
		
		ladder_climb_x = 0.0
		ladder_climb_z = 0.0
		ladder_width_disp = 0.32

	# Solid Walkable Collider for Catwalk Floor Grating
	# Catwalk deck surface is at tower_height + 0.24m
	deck_body = StaticBody3D.new()
	deck_body.name = "GymCatwalkDeckBody"
	deck_body.collision_layer = 1
	deck_body.collision_mask = 1
	deck_body.add_to_group("tutorial_solids")
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.40, 0.20, 1.00)
	col.shape = box
	col.position = Vector3(0.0, tower_height + 0.10, -0.50 if config_mode == 0 else -0.30)
	deck_body.add_child(col)
	platform_root.add_child(deck_body)
	
	# Interactive Ladder Node on Tower's Built-In Ladder Face
	# Rung spacing scales with tower height
	var rung_pitch: float = 0.239 * (tower_height / 1.80)
	ladder_node = preload("res://scripts/miko8_ladder.gd").new()
	ladder_node.name = "GymBuiltInLadder"
	ladder_node.height = tower_height + 0.24
	ladder_node.above_platform = 0.8
	ladder_node.extended_rungs = false
	ladder_node.curved_top = true
	ladder_node.rung_spacing = rung_pitch
	ladder_node.rung_offset = -0.05
	ladder_node.rail_half_width = ladder_width_disp * 0.5
	ladder_node.industrial_model = false # Use the model's actual 3D visual ladder
	ladder_node.set_meta("direct_entry", true)
	ladder_node.set_meta("bpg_ladder", true)
	ladder_node.set_meta("top_entry_x", ladder_climb_x)
	ladder_node.dismount_side = 1
	ladder_node.position = Vector3(ladder_climb_x, 0.0, ladder_climb_z)
	platform_root.add_child(ladder_node)
	
	# Hide any internal procedural meshes inside ladder_node so only the GLB model's ladder renders
	for child in ladder_node.get_children():
		if child is MeshInstance3D:
			child.visible = false

func _build_gym_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("15181e") # Deep Studio Slate
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b4c2d4")
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 40, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -140, 0)
	fill.light_energy = 0.35
	add_child(fill)
	
	# Solid Concrete Floor
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 1
	var f_col := CollisionShape3D.new()
	var f_box := BoxShape3D.new()
	f_box.size = Vector3(60.0, 0.40, 10.0)
	f_col.shape = f_box
	f_col.position = Vector3(0.0, -0.20, 0.0)
	floor_body.add_child(f_col)
	
	var floor_mesh := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(60.0, 0.40, 10.0)
	floor_mesh.mesh = fm
	var f_mat := StandardMaterial3D.new()
	f_mat.albedo_color = Color("20252d")
	f_mat.roughness = 0.85
	floor_mesh.material_override = f_mat
	floor_mesh.position = Vector3(0.0, -0.20, 0.0)
	floor_body.add_child(floor_mesh)
	add_child(floor_body)
	
	# Metric Floor Grid (1m Major Grid, 0.25m Minor Ticks)
	var grid := ImmediateMesh.new()
	var grid_mat := StandardMaterial3D.new()
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_mat.albedo_color = Color("323b47")
	grid.surface_begin(Mesh.PRIMITIVE_LINES, grid_mat)
	for i in range(-25, 26):
		var x: float = float(i) * 1.0
		grid.surface_add_vertex(Vector3(x, 0.002, -3.0))
		grid.surface_add_vertex(Vector3(x, 0.002, 3.0))
	for j in range(-3, 4):
		var z: float = float(j) * 1.0
		grid.surface_add_vertex(Vector3(-25.0, 0.002, z))
		grid.surface_add_vertex(Vector3(25.0, 0.002, z))
	grid.surface_end()
	var lines := MeshInstance3D.new()
	lines.mesh = grid
	add_child(lines)
	
	# Rear Height Measuring Wall with Horizontal Meter Ticks
	var wall := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(60.0, 8.0, 0.20)
	wall.mesh = wm
	var w_mat := StandardMaterial3D.new()
	w_mat.albedo_color = Color("1a1e26")
	w_mat.roughness = 0.95
	wall.material_override = w_mat
	wall.position = Vector3(0.0, 4.0, -2.5)
	add_child(wall)
	
	# Metric Height Lines (every 1.0 meter on rear wall)
	var h_grid := ImmediateMesh.new()
	var h_mat := StandardMaterial3D.new()
	h_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	h_mat.albedo_color = Color("384352")
	h_grid.surface_begin(Mesh.PRIMITIVE_LINES, h_mat)
	for m in range(1, 8):
		var y: float = float(m) * 1.0
		h_grid.surface_add_vertex(Vector3(-25.0, y, -2.39))
		h_grid.surface_add_vertex(Vector3(25.0, y, -2.39))
	h_grid.surface_end()
	var h_lines := MeshInstance3D.new()
	h_lines.mesh = h_grid
	add_child(h_lines)
	
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.current = true
	add_child(camera)

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "GymHUD"
	add_child(hud_layer)
	
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 24
	panel.offset_top = 20
	panel.offset_right = 420
	panel.offset_bottom = 430
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.12, 0.94)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	hud_layer.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 9)
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "MIKO MODULAR PLATFORM GYM"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("ffd166"))
	vbox.add_child(title)
	
	info_label = Label.new()
	info_label.text = "Initializing models..."
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_color_override("font_color", Color("a8b2c1"))
	vbox.add_child(info_label)
	
	# 1. Platform Configuration
	var cfg_box := HBoxContainer.new()
	var cfg_lbl := Label.new()
	cfg_lbl.text = "Assembly:"
	cfg_lbl.custom_minimum_size.x = 110
	cfg_box.add_child(cfg_lbl)
	config_option = OptionButton.new()
	config_option.add_item("Wide Tower (2.4m - Deck Matched)", 0)
	config_option.add_item("Twin-Column Gantry (Two 0.6m Posts)", 1)
	config_option.add_item("Native Asset Scale (0.54m Column)", 2)
	config_option.select(0)
	config_option.item_selected.connect(func(idx: int): config_mode = idx; _rebuild_platform())
	cfg_box.add_child(config_option)
	vbox.add_child(cfg_box)
	
	# 2. Tower Height
	var h_box := HBoxContainer.new()
	var h_lbl := Label.new()
	h_lbl.text = "Height:"
	h_lbl.custom_minimum_size.x = 110
	h_box.add_child(h_lbl)
	height_option = OptionButton.new()
	height_option.add_item("3.20m (Observation Gantry)", 0)
	height_option.add_item("3.60m (Launcher Boost Height)", 1)
	height_option.add_item("2.80m (Standard Maintenance)", 2)
	height_option.add_item("1.80m (1-Unit Native Height)", 3)
	height_option.select(0)
	height_option.item_selected.connect(func(idx: int):
		match idx:
			0: tower_height = 3.20
			1: tower_height = 3.60
			2: tower_height = 2.80
			3: tower_height = 1.80
		_rebuild_platform()
	)
	h_box.add_child(height_option)
	vbox.add_child(h_box)
	
	# 3. Shading Style (Crisp Cel vs Raw Texture vs Lit PBR)
	var s_box := HBoxContainer.new()
	var s_lbl := Label.new()
	s_lbl.text = "Shading [1-3]:"
	s_lbl.custom_minimum_size.x = 110
	s_box.add_child(s_lbl)
	shading_option = OptionButton.new()
	shading_option.add_item("Crisp Anime Cel (Bands + Ink)", 0)
	shading_option.add_item("Raw Unshaded Texture Art", 1)
	shading_option.add_item("Standard Lit PBR Lighting", 2)
	shading_option.select(0)
	shading_option.item_selected.connect(func(idx: int): shading_mode = idx; _apply_shading())
	s_box.add_child(shading_option)
	vbox.add_child(s_box)
	
	# 4. Camera Angle
	var c_box := HBoxContainer.new()
	var c_lbl := Label.new()
	c_lbl.text = "Camera [Tab]:"
	c_lbl.custom_minimum_size.x = 110
	c_box.add_child(c_lbl)
	camera_option = OptionButton.new()
	camera_option.add_item("Gentle 3D Side-On (Game)", 0)
	camera_option.add_item("Straight Orthogonal 2D", 1)
	camera_option.add_item("Close-Up Ladder Zoom", 2)
	camera_option.add_item("Free Orbit 3D (Right-Drag)", 3)
	camera_option.select(0)
	camera_option.item_selected.connect(func(idx: int): camera_mode = idx; _update_camera(0.0, true))
	c_box.add_child(camera_option)
	vbox.add_child(c_box)
	
	# 5. Teleport & Action Buttons
	var btn_box := HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 8)
	
	var btn_ladder := Button.new()
	btn_ladder.text = "At Ladder"
	btn_ladder.pressed.connect(func():
		actor.reset_actor()
		var lx: float = 0.0 if config_mode != 1 else -0.90
		actor.position = Vector3(lx, 0.02, 0.0)
		actor.velocity = Vector3.ZERO
	)
	btn_box.add_child(btn_ladder)
	
	var btn_deck := Button.new()
	btn_deck.text = "On Catwalk"
	btn_deck.pressed.connect(func():
		actor.reset_actor()
		actor.position = Vector3(0.0, tower_height + 0.26, -0.30)
		actor.velocity = Vector3.ZERO
	)
	btn_box.add_child(btn_deck)
	
	var btn_reset := Button.new()
	btn_reset.text = "Reset [R]"
	btn_reset.pressed.connect(func():
		actor.reset_actor()
		actor.position = Vector3(-1.4, 0.02, 0.0)
		actor.velocity = Vector3.ZERO
	)
	btn_box.add_child(btn_reset)
	vbox.add_child(btn_box)

func _update_hud() -> void:
	if not info_label or not actor:
		return
	var on_ladder: bool = actor.abilities.ladder != null if actor.abilities else false
	var state_str: String = "ON LADDER" if on_ladder else ("Grounded" if actor.is_on_floor() else "Airborne")
	var ladder_w_str: String = "1.40m (Wide Heavy)" if config_mode == 0 else ("0.45m (Column-Mounted)" if config_mode == 1 else "0.32m (Native Asset)")
	
	info_label.text = "Miko: X=%.2fm, Y=%.2fm [%s]\nTower: H=%.2fm | Ladder: %s\nCatwalk: 2.40m x 1.00m (Flush on Tower Top)" % [
		actor.position.x, actor.position.y, state_str,
		tower_height, ladder_w_str
	]
