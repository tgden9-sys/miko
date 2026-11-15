extends "res://scripts/lab_run.gd"

const Layout := preload("res://scripts/lab_cutaway_layout.gd")
const ThermalLayout := preload("res://scripts/lab_thermal_layout.gd")
const ShaftLayout := preload("res://scripts/lab_coolant_shaft_layout.gd")
const SwitchbackLayout := preload("res://scripts/lab_relay_switchback_layout.gd")
const GalleryLayout := preload("res://scripts/lab_condensate_gallery_layout.gd")
const Expansion := preload("res://scripts/lab_expansion_layout.gd")
const RailGun := preload("res://scripts/lab_rail_gun.gd")
const RedScout := preload("res://scripts/lab_red_scout.gd")
const ROOM_SCENES := [
	"res://lab_cutaway.tscn",
	"res://lab_thermal_exchange.tscn",
	"res://lab_coolant_shaft.tscn",
	"res://lab_relay_switchback.tscn",
	"res://lab_condensate_gallery.tscn",
	"res://lab_maintenance_hall.tscn",
] + Expansion.SCENES
const TRANSFER_META := &"cutaway_door_arrival"
const Kit := preload("res://scripts/lab_art_kit.gd")
const CUTAWAY_VIEW_HEIGHT := 9.4
const CUTAWAY_CAMERA_DISTANCE := 32.0
const CUTAWAY_CAMERA_RISE := 1.35
const VENTS := [Vector3(5.4,0,-1.1),Vector3(12.6,0,-1.1),
	Vector3(20.0,2,-1.1),Vector3(26.85,4,-1.1),Vector3(42.1,4,-1.1)]
const THERMAL_VENTS := [Vector3(5.35,0,-1.1),Vector3(16.1,0,-1.1)]
const THERMAL_METAL := Color(1.28,.97,.69)
const SHAFT_METAL := Color(.77,1.08,1.06)
const SHAFT_VENTS := [Vector3(4.3,0,-1.1),Vector3(2.4,8,-1.1),Vector3(11.6,16,-1.1)]
@export var thermal_exchange := false
@export var coolant_shaft := false
@export_enum("None","Relay Switchback","Condensate Gallery") var upper_room := 0
@export var expansion_room := -1
@export var connect_exit := true
var layout
var expansion_layout: Expansion
var vents: Array
var arriving := false
var returning_to_lab := false
var gate: Node3D
var complete := false
var leaving := false
var exit_fade: ColorRect
var suit_readout: Node2D
var checkpoint := Vector3(3,.04,0)
var scout: RedScout
var wall_turrets: Array[StaticBody3D] = []
var hover_drone: Node3D
var mine_crawler: CharacterBody3D
var relay_station: Node3D
var rail_gun: Node3D
var crate_step: Node3D
var entrance_inward := 1.0
var exit_outward := 1.0
var previous_room := ""
var next_room := ""
var room_index := -1

func _ready() -> void:
	course_electric_shield = true
	layout = ThermalLayout if thermal_exchange else Layout
	vents = THERMAL_VENTS if thermal_exchange else VENTS
	room_index = ROOM_SCENES.find(scene_file_path)
	if room_index > 0:
		previous_room = ROOM_SCENES[room_index - 1]
	if room_index >= 0 and room_index + 1 < ROOM_SCENES.size():
		next_room = ROOM_SCENES[room_index + 1]
	if coolant_shaft:
		layout = ShaftLayout
		vents = SHAFT_VENTS
	if upper_room != 0:
		layout = SwitchbackLayout if upper_room == 1 else GalleryLayout
		entrance_inward = layout.ENTRY_INWARD
		exit_outward = layout.EXIT_OUTWARD
		vents = [Vector3(8,0,-1.1),Vector3(9,6,-1.1)] if upper_room == 1 else [Vector3(17,0,-1.1),Vector3(11,8,-1.1)]
	if expansion_room >= 0:
		expansion_layout = Expansion.new(expansion_room)
		layout = expansion_layout
		entrance_inward = expansion_layout.ENTRY_INWARD
		exit_outward = expansion_layout.EXIT_OUTWARD
		vents = expansion_layout.room.vents
	checkpoint = layout.SPAWN
	course_spawn_dummy = false
	course_zoom_controls = false
	next_level_path = ""
	super._ready()
	if expansion_layout:
		actor.facing = int(entrance_inward)
		actor.visual.rotation.y = entrance_inward * PI * .5
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = rad_to_deg(2.0*atan(CUTAWAY_VIEW_HEIGHT*.5/CUTAWAY_CAMERA_DISTANCE))
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.background_color = Color("020405")
	gate.actor = actor
	for material in actor.suit_materials:
		_set_lab_lighting(material)
		material.set_shader_parameter("room_lighting",.55)
	step_fx.ground_wisp_zone = _by_vent
	step_fx.ground_wisp_tint = Color("d6bd96") if thermal_exchange else Color("aabebc")
	if get_tree().has_meta(TRANSFER_META):
		var state: Dictionary = get_tree().get_meta(TRANSFER_META)
		get_tree().remove_meta(TRANSFER_META)
		actor.health = state.health
		actor._set_suit_pole(state.pole)
		actor.shield_hits = state.get("shield_hits", actor.SHIELD_CAPACITY)
		actor.shield_recharge_time = state.get("shield_recharge_time", 0.0)
		returning_to_lab = state.get("returning", false)
		if returning_to_lab:
			actor.position = layout.EXIT+Vector3(1.65*exit_outward,.04,0)
			actor.facing = int(-exit_outward)
			gate.open_for_return()
			checkpoint = Vector3(34,4.04,0) if previous_room.is_empty() else layout.EXIT+Vector3(-3*exit_outward,.04,0)
		else:
			actor.position = layout.ENTRANCE+Vector3(-.85*entrance_inward,.04,0)
			actor.facing = int(entrance_inward)
		actor.automation = true
		actor.command_axis = -exit_outward if returning_to_lab else entrance_inward
		exit_fade.color.a = 1
		suit_readout.hide()
		suit_readout.set_process(false)
		arriving = true
	_update_camera(10)

func _set_lab_lighting(material: ShaderMaterial) -> void:
	material.set_shader_parameter("fixed_room_lighting",true)
	if expansion_layout:
		material.set_shader_parameter("fixed_ambient",expansion_layout.room.ambient)
		var lamp: Color = expansion_layout.room.lamp
		var tint := Vector3(lamp.r, lamp.g, lamp.b) * .21
		var first: Vector2 = expansion_layout.LIGHTS.front()
		var last: Vector2 = expansion_layout.LIGHTS.back()
		material.set_shader_parameter("first_light_pool",Vector4(first.x,first.y-1.3,8.0,5.0))
		material.set_shader_parameter("second_light_pool",Vector4(last.x,last.y-1.3,8.0,5.0))
		material.set_shader_parameter("first_light_tint",tint)
		material.set_shader_parameter("second_light_tint",tint)
		return
	if upper_room != 0:
		material.set_shader_parameter("fixed_ambient",Vector3(.78,.73,.66) if upper_room == 1 else Vector3(.71,.72,.87))
		var pool: Vector2 = layout.LIGHTS[1]
		material.set_shader_parameter("first_light_pool",Vector4(pool.x,pool.y-1,8,5))
		pool = layout.LIGHTS[3]
		material.set_shader_parameter("second_light_pool",Vector4(pool.x,pool.y-1,8,5))
		var lamp := Vector3(.25,.20,.14) if upper_room == 1 else Vector3(.21,.19,.31)
		material.set_shader_parameter("first_light_tint",lamp)
		material.set_shader_parameter("second_light_tint",lamp)
		return
	if coolant_shaft:
		material.set_shader_parameter("fixed_ambient",Vector3(.61,.78,.78))
		material.set_shader_parameter("first_light_pool",Vector4(4,5.2,7,6))
		material.set_shader_parameter("first_light_tint",Vector3(.18,.35,.22))
		material.set_shader_parameter("second_light_pool",Vector4(11,16.5,6,6))
		material.set_shader_parameter("second_light_tint",Vector3(.19,.35,.26))
		return
	if thermal_exchange:
		material.set_shader_parameter("fixed_ambient",Vector3(.80,.61,.42))
		material.set_shader_parameter("first_light_pool",Vector4(4.4,3.15,5.0,3.7))
		material.set_shader_parameter("first_light_tint",Vector3(.57,.32,.15))
		material.set_shader_parameter("second_light_pool",Vector4(18,3.05,5.0,3.7))
		material.set_shader_parameter("second_light_tint",Vector3(.49,.31,.17))
		return
	material.set_shader_parameter("fixed_ambient",Vector3(.66,.73,.79))
	material.set_shader_parameter("first_light_pool",Vector4(7,3.6,10.5,5.0))
	material.set_shader_parameter("first_light_tint",Vector3(.48,.28,.12))
	material.set_shader_parameter("second_light_pool",Vector4(45,7.5,12.5,5.0))
	material.set_shader_parameter("second_light_tint",Vector3(.40,.26,.12))

func _build_course() -> void:
	var shell := preload("res://scripts/lab_cutaway_shell.gd").new()
	shell.layout = layout
	shell.metal_tint = THERMAL_METAL if thermal_exchange else Color.WHITE
	if coolant_shaft:
		shell.metal_tint = SHAFT_METAL
	if upper_room != 0:
		shell.metal_tint = Color(1.13,1.03,.91) if upper_room == 1 else Color(.91,.92,1.12)
	if expansion_layout:
		shell.metal_tint = expansion_layout.room.metal
	add_child(shell)
	var kit := Kit.new(self)
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://shaders/lab_room_backdrop.gdshader")
	var art := "res://art/lab_thermal_exchange.png" if thermal_exchange else "res://art/lab_cutaway_wall.png"
	if coolant_shaft:
		art = "res://art/lab_coolant_shaft.png"
	if upper_room != 0:
		art = "res://art/lab_relay_switchback.png" if upper_room == 1 else "res://art/lab_condensate_gallery.png"
	if expansion_layout:
		art = "res://art/lab_expansion_%s.png" % expansion_layout.room.art
	var texture := load(art) as Texture2D
	paint.set_shader_parameter("backdrop",texture)
	paint.set_shader_parameter("backdrop_tint",Color(1.0,.99,.91) if thermal_exchange else Color(.85,.91,.94))
	_set_lab_lighting(paint)
	paint.set_shader_parameter("recession",.08 if thermal_exchange else .16)
	var backdrop: Rect2 = layout.BACKDROP
	if expansion_layout and texture:
		var image_aspect := texture.get_size().aspect()
		var wall_aspect := backdrop.size.aspect()
		var crop := Vector2(minf(1.0,wall_aspect/image_aspect),minf(1.0,image_aspect/wall_aspect))
		var offset := (Vector2.ONE-crop)*.5
		if expansion_layout.room.get("mirror_art",false):
			offset.x += crop.x
			crop.x = -crop.x
		paint.set_shader_parameter("atlas_scale",crop)
		paint.set_shader_parameter("atlas_offset",offset)
	var center := backdrop.get_center()
	kit.quad(Vector3(center.x,center.y,-3.0),backdrop.size,paint)
	var glow := ShaderMaterial.new()
	glow.shader = preload("res://shaders/lab_service_lamp.gdshader")
	glow.set_shader_parameter("tint",Color("ffd29b") if thermal_exchange else Color("f0d6ac"))
	if coolant_shaft:
		glow.set_shader_parameter("tint",Color("c6ffe2"))
	if upper_room != 0:
		glow.set_shader_parameter("tint",Color("f6dfbe") if upper_room == 1 else Color("e0dcff"))
	if expansion_layout:
		glow.set_shader_parameter("tint",expansion_layout.room.lamp)
	var beam := glow.duplicate() as ShaderMaterial
	beam.set_shader_parameter("beam",true)
	for point: Vector2 in layout.LIGHTS:
		var at := Vector3(point.x,point.y,-1.9)
		kit.plate(at,Vector3(1.26,.19,.28),Color("333e43"))
		kit.quad(at+Vector3(0,-.018,.17),Vector2(.92,.055),glow)
		kit.quad(at+Vector3(0,-2.12,.14),Vector2(4.2,4.24),beam)
		_add_lamp_dust(at+Vector3(0,-2.12,.24))
	if expansion_room == 0:
		kit.box(Vector3(26.5,RailGun.TRACK_Y,RailGun.TRACK_Z),Vector3(46,.13,.16),Color("4c5962"))
		kit.box(Vector3(26.5,RailGun.TRACK_Y+.058,RailGun.TRACK_Z),Vector3(46,.045,.21),Color("7f8a90"))
		for x in range(5,50,4):
			kit.plate(Vector3(x,RailGun.TRACK_Y-.15,RailGun.TRACK_Z-.96),Vector3(.22,.24,1.83),Color("4d595e"))
	kit.finish()
	if coolant_shaft:
		_build_service_ledge(8.52,13.5,1.46,shell.metal_tint)
	elif upper_room == 1:
		_build_service_ledge(15.85,1.5,2.3,shell.metal_tint)
		_build_service_ledge(20.45,1.5,2.3,shell.metal_tint)
	var mist := ShaderMaterial.new()
	mist.shader = preload("res://shaders/lab_vent_mist.gdshader")
	for vent: Vector3 in vents:
		var grate := Kit.new(self,Kit.bulkhead_paint())
		grate.box(vent+Vector3.UP*.02,Vector3(.88,.045,.50),Color("53626a"))
		grate.box(vent+Vector3.UP*.045,Vector3(.76,.012,.38),Color("131c20"))
		for index in range(7):
			grate.box(vent+Vector3((index-3)*.102,.058,0),Vector3(.045,.023,.38),Color("72827f"))
		grate.finish()
		kit.quad(vent+Vector3(1.65,.52,.19),Vector2(6.2,1.04),mist)
		kit.quad(vent+Vector3(1.12,.36,.68),Vector2(4.75,.72),mist)
	var door_type := preload("res://scripts/lab_cutaway_door.gd")
	var entrance := door_type.new()
	entrance.position = layout.ENTRANCE
	entrance.arrival = true
	entrance.sealed = previous_room.is_empty()
	entrance.passage_direction = entrance_inward
	entrance.metal_tint = shell.metal_tint
	add_child(entrance)
	gate = door_type.new()
	gate.position = layout.EXIT
	gate.passage_direction = exit_outward
	gate.pole = 1 if coolant_shaft or (expansion_layout and expansion_room % 2 == 1) else 2
	gate.metal_tint = shell.metal_tint
	add_child(gate)
	if expansion_layout and expansion_layout.room.has("locked_door"):
		var locked := door_type.new()
		locked.name = "LockedServiceDoor"
		locked.position = expansion_layout.room.locked_door
		locked.sealed = true
		locked.metal_shutter = true
		locked.metal_tint = shell.metal_tint
		add_child(locked)
		relay_station = preload("res://scripts/lab_relay_station.gd").new()
		relay_station.name = "RelayStation"
		relay_station.shutter = locked
		add_child(relay_station)

func _build_service_ledge(first_x: float, underside: float, spacing: float, tint: Color) -> void:
	# Cantilevered steps meet the rear wall at bolted gussets.
	var brackets := Kit.new(self,Kit.bulkhead_paint())
	for x in [first_x,first_x+spacing]:
		brackets.plate(Vector3(x,underside-.45,-2.48),Vector3(.32,.98,.27),Color("304348")*tint)
		brackets.box(Vector3(x,underside-.47,-1.94),Vector3(.19,1.20,.25),Color("3d5658")*tint,false,Vector3(-.82,0,0))
		brackets.cylinder(Vector3(x,underside-.87,-2.31),Vector3(.085,.045,.085),Color("70827e")*tint,Vector3(PI*.5,0,0))
	brackets.finish()

func _by_vent(point: Vector3) -> bool:
	for vent: Vector3 in vents:
		if absf(point.y-vent.y) < .28 and point.x > vent.x-.4 and point.x < vent.x+4.3:
			return true
	return false

func _add_lamp_dust(at: Vector3) -> void:
	var volume := Vector3(3.4,4.15,1.1)
	var random := RandomNumberGenerator.new()
	random.seed = roundi(at.x*470)
	var points := PackedVector3Array()
	for index in range(24):
		points.append(Vector3(random.randf(),random.randf(),random.randf()))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS,arrays)
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://shaders/lab_light_dust.gdshader")
	paint.set_shader_parameter("dust_color",Color("e3d3b1"))
	paint.set_shader_parameter("drift_volume",volume)
	var dust := MeshInstance3D.new()
	dust.mesh = mesh
	dust.position = at
	dust.custom_aabb = AABB(-volume*.5,volume).grow(.1)
	dust.material_override = paint
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dust)

func _spawn_extra_droids() -> void:
	if relay_station:
		relay_station.actor = actor
	if thermal_exchange:
		_add_red_scout(RedScout.new())
	elif coolant_shaft:
		_add_shaft_turret("WallTurret", Vector3(14.01, 7.82, -.78), PI)
		_add_shaft_turret("LowerWallTurret", Vector3(14.01, 3.35, -.78), PI, 2.0)
		_add_shaft_turret("UpperWallTurret", Vector3(-.01, 17.48, -.78), 0.0)
	elif upper_room == 1:
		hover_drone = preload("res://scripts/lab_hover_drone.gd").new()
		hover_drone.name = "HoverDrone"
		hover_drone.position = Vector3(10.55,9.44,-.47)
		hover_drone.target = actor
		add_child(hover_drone)
	elif upper_room == 2:
		var gallery_scout := RedScout.new()
		gallery_scout.home = Vector3(4.95, 4.04, -.64)
		gallery_scout.left_turn = 3.52
		gallery_scout.right_turn = 6.90
		gallery_scout.initial_facing = -1.0
		gallery_scout.thermal_steps = false
		_add_red_scout(gallery_scout)
		mine_crawler = preload("res://scripts/lab_mine_crawler.gd").new()
		mine_crawler.name = "MineCrawler"
		mine_crawler.position = Vector3(18.0, 8.035, 0)
		mine_crawler.target = actor
		add_child(mine_crawler)
	elif expansion_room == 0:
		rail_gun = RailGun.new()
		rail_gun.name = "RailGun"
		rail_gun.target = actor
		add_child(rail_gun)

func _add_red_scout(placed_scout: RedScout) -> void:
	scout = placed_scout
	scout.name = "RedScout"
	scout.target = actor
	add_child(scout)

func _add_shaft_turret(label: String, at: Vector3, yaw: float, entry_grace := 0.0) -> void:
	var turret := preload("res://scripts/lab_wall_turret.gd").new()
	turret.name = label
	turret.position = at
	turret.rotation.y = yaw
	turret.target = actor
	turret.entry_grace = entry_grace
	add_child(turret)
	wall_turrets.append(turret)

func _spawn_crates() -> void:
	if upper_room == 0:
		return
	crate_step = preload("res://scripts/lab_crate_step.gd").new()
	crate_step.name = "CrateStep"
	crate_step.actor = actor
	crate_step.home = layout.CRATE_HOME
	crate_step.stop_x = layout.CRATE_STOP
	crate_step.landing = layout.CRATE_LANDING
	crate_step.precharged = upper_room == 1
	crate_step.progress_key = StringName("cutaway_crate_step_%d" % upper_room)
	crate_step.hint_layer = suit_readout.get_parent()
	add_child(crate_step)

func _update_wave_spawner(_delta: float) -> void:
	pass

func _add_network_node(_label: String,_x: float) -> void:
	pass

func _build_ui() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	suit_readout = preload("res://scripts/miko8_health_bar.gd").new()
	suit_readout.actor = actor
	hud.add_child(suit_readout)
	var fps_panel := PanelContainer.new()
	fps_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(fps_panel)
	fps_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fps_panel.offset_left = -144
	fps_panel.offset_right = -20
	fps_panel.offset_top = 18
	fps_panel.offset_bottom = 58
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color(.02,.04,.05,.88)
	skin.content_margin_left = 12
	skin.content_margin_right = 12
	skin.content_margin_top = 7
	skin.content_margin_bottom = 7
	fps_panel.add_theme_stylebox_override("panel",skin)
	diagnostics = Label.new()
	diagnostics.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diagnostics.add_theme_font_size_override("font_size",22)
	diagnostics.add_theme_color_override("font_color",Color("d8eee9"))
	fps_panel.add_child(diagnostics)
	status = Label.new()
	status.position = Vector2(24,47)
	status.add_theme_font_size_override("font_size",20)
	hud.add_child(status)
	exit_fade = ColorRect.new()
	exit_fade.color = Color(0,0,0,0)
	exit_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(exit_fade)
	exit_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _on_sword_style_changed(_index: int,_name: String,_description: String) -> void:
	pass

func _update_status() -> void:
	diagnostics.text = "%d FPS" % Engine.get_frames_per_second()
	status.text = "LAB COMPLETE" if complete else ""

func reset_room() -> void:
	if crate_step:
		crate_step.reset()
	if scout:
		scout.reset()
	for turret in wall_turrets:
		turret.reset()
	if hover_drone:
		hover_drone.reset()
	if mine_crawler:
		mine_crawler.reset()
	if rail_gun:
		rail_gun.reset()
	if leaving or arriving:
		actor.automation = false
	arriving = false
	returning_to_lab = false
	leaving = false
	complete = false
	if exit_fade:
		exit_fade.color.a = 0
		suit_readout.show()
		suit_readout.set_process(true)
	actor.reset()
	actor.position = checkpoint
	actor.facing = int(entrance_inward)
	if step_fx:
		step_fx.clear()
	camera_focus = checkpoint.x
	camera_height = checkpoint.y+2.7
	_update_camera(10)

func _update_camera(delta: float) -> void:
	if not camera:
		return
	var p := actor.position
	if previous_room.is_empty() and actor.is_on_floor() and p.x > 33 and p.y >= 4:
		checkpoint = Vector3(34,4.04,0)
	elif previous_room.is_empty() and actor.is_on_floor() and p.x > 18 and p.x < 20:
		checkpoint = Vector3(18.7,.04,0)
	var aspect := get_viewport().get_visible_rect().size.aspect()
	var half_width := CUTAWAY_VIEW_HEIGHT*aspect*.5
	# Keep the doorway at the edge, with only the mounting face in the room view.
	var left: float = layout.ENTRANCE.x+half_width-1.15
	var right: float = layout.EXIT.x+1.55-half_width
	var target_x := clampf(p.x+actor.facing*.7,left,right) if left <= right else (left+right)*.5
	var climb := smoothstep(17,34,p.x)
	var target_y := 3.05 if thermal_exchange else lerpf(2.8,6.8,climb)
	if not thermal_exchange and p.x > 18 and p.x < 32:
		target_y = maxf(target_y,p.y+1.3)
	if coolant_shaft:
		target_x = 7.5
		target_y = clampf(p.y+2.35,3.8,17.5)
		if actor.is_on_floor() and p.x >= 2 and p.x <= 5.5:
			for landing: Vector3 in ShaftLayout.LANDINGS:
				if absf(p.y-landing.y) < .18 and landing.y > checkpoint.y:
					checkpoint = landing
	if upper_room != 0:
		var room_left := 1.0 if upper_room == 1 else 0.0
		var left_limit := room_left+half_width-1.1
		var right_limit := 26.5-half_width
		target_x = clampf(p.x+actor.facing*.6,left_limit,right_limit) if left_limit <= right_limit else (left_limit+right_limit)*.5
		target_y = clampf(p.y+2.8,3.5,9.1 if upper_room == 1 else 10.8)
	if expansion_layout:
		var width: float = expansion_layout.room.width
		if expansion_layout.room.has("service_bay") and p.y > 7.15:
			width += smoothstep(45.7, 48.0, p.x) * expansion_layout.room.service_bay.size.x
		var bottom: float = expansion_layout.room.bottom
		var top: float = expansion_layout.room.top
		var margin := maxf(0.0,half_width-1.15)
		target_x = clampf(p.x+actor.facing*.7,margin,width-margin) if margin*2 < width else width*.5
		target_y = clampf(p.y+2.5,bottom+2.9,maxf(bottom+2.9,top-3.1))
	camera_focus = lerpf(camera_focus,target_x,1-exp(-delta*6))
	camera_height = lerpf(camera_height,target_y,1-exp(-delta*5))
	var focus := Vector3(camera_focus,camera_height,0)
	camera.position = focus+Vector3(0,CUTAWAY_CAMERA_RISE,CUTAWAY_CAMERA_DISTANCE)
	camera.look_at(focus)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.physical_keycode != KEY_F6:
		return
	if relay_transition_pending or (leaving and not next_room.is_empty()):
		return
	get_viewport().set_input_as_handled()
	var destination: String = ROOM_SCENES[(room_index + 1) % ROOM_SCENES.size()]
	var error := get_tree().change_scene_to_file(destination)
	if error != OK:
		push_error("Could not open the next expansion room: %s" % error)

func _update_network_transfer(delta: float) -> void:
	var exit_distance: float = (actor.position.x-layout.EXIT.x)*exit_outward
	var entry_distance: float = (actor.position.x-layout.ENTRANCE.x)*entrance_inward
	if arriving:
		exit_fade.color.a = move_toward(exit_fade.color.a,0,delta*4.0)
		var clear: bool = exit_distance <= -2.1 if returning_to_lab else (actor.position.x-layout.SPAWN.x)*entrance_inward >= 0
		if clear:
			actor.command_axis = 0
			actor.automation = false
			arriving = false
			returning_to_lab = false
		else:
			var visible_in_room := exit_distance < 0 if returning_to_lab else entry_distance >= 0
			suit_readout.visible = visible_in_room
			suit_readout.set_process(visible_in_room)
			return
	if not previous_room.is_empty() and not leaving and entry_distance < -.55 and absf(actor.position.y-layout.ENTRANCE.y) < .25:
		exit_fade.color.a = move_toward(exit_fade.color.a,1,delta*5)
		if not relay_transition_pending and exit_fade.color.a >= 1:
			relay_transition_pending = true
			_transfer_through_door.call_deferred(previous_room,true)
	elif not leaving:
		exit_fade.color.a = move_toward(exit_fade.color.a,0,delta*5)
	if not leaving:
		var past_exit: bool = exit_distance >= .15 and absf(actor.position.y-layout.EXIT.y) < .25
		var behind_entrance: bool = entry_distance < -.15 and absf(actor.position.y-layout.ENTRANCE.y) < .25
		var in_view := not (past_exit or behind_entrance)
		if suit_readout.visible != in_view:
			suit_readout.visible = in_view
			suit_readout.set_process(in_view)
	if exit_distance > .9 and absf(actor.position.y-layout.EXIT.y) < .25 and actor.is_on_floor() and not leaving:
		leaving = true
		suit_readout.hide()
		suit_readout.set_process(false)
		actor.automation = true
		actor.command_axis = exit_outward
	if leaving and not complete and exit_distance > 2.9:
		actor.command_axis = 0
		exit_fade.color.a = move_toward(exit_fade.color.a,1,delta*1.7)
		complete = exit_fade.color.a >= 1
		if complete:
			if connect_exit and not next_room.is_empty():
				_transfer_through_door.call_deferred(next_room,false)
			else:
				status.move_to_front()

func _transfer_through_door(destination: String, returning: bool) -> void:
	var tree := get_tree()
	tree.set_meta(TRANSFER_META, {
		"health": actor.health, "pole": actor.suit_polarity, "returning": returning,
		"shield_hits": actor.shield_hits, "shield_recharge_time": actor.shield_recharge_time,
	})
	var error := tree.change_scene_to_file(destination)
	if error != OK:
		tree.remove_meta(TRANSFER_META)
		relay_transition_pending = false
		status.move_to_front()
		push_error("Could not open the connected room: %s" % error)
