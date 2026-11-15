extends "res://scripts/lab_run.gd"

const ENTRANCE := Vector3(2.35,0,0)
const SHIELD := preload("res://props/lab_polarity_shield.tscn")
const Door := preload("res://scripts/lab_polarity_shield.gd")
const MetalCrate := preload("res://scripts/miko8_charge_box.gd")
const WoodenCrate := preload("res://scripts/miko8_wooden_crate.gd")
const Dressing := preload("res://scripts/lab_compact_dressing.gd")
const Rooms := preload("res://scripts/lab_relay_rooms.gd")
const WorldTransfer := &"relay_room_transfer"
const TUNNEL_DEPTH := 8.0

enum DoorPhase { PLAY, LEAVE, FADE_OUT, FADE_IN, ENTER }

@export_range(0,4) var room_index := 0

var checkpoint := 0
var room_width: float
var room_roof: float
var exit_position: Vector3
var entry_shield: Door
var exit_shield: Door
var door_phase := DoorPhase.PLAY
var door_fade: ColorRect
var suit_readout: Node2D
var was_automated := false
var displayed_fps := -1
var travel_direction := 1.0
var room_history: Dictionary = {}
var incoming: Dictionary = {}
var network_node: Node3D
var completed := false
var completion_label: Label

@onready var dressing: Dressing = $Dressing

func _ready() -> void:
	room_width = Rooms.LAYOUTS[room_index].width
	room_roof = Rooms.LAYOUTS[room_index].roof
	exit_position = _at(Rooms.LAYOUTS[room_index].get("exit",Vector2.ZERO))
	if get_tree().has_meta(WorldTransfer):
		incoming = get_tree().get_meta(WorldTransfer)
		get_tree().remove_meta(WorldTransfer)
		room_history = incoming.history
	course_spawn_dummy = false
	course_zoom_controls = false
	next_level_path = ""
	super._ready()
	camera.fov = rad_to_deg(2.0*atan(VIEW_HEIGHT*.5/CAMERA_DISTANCE))
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.background_color = Color("080e12")
			child.environment.ambient_light_energy = .47
		elif child is DirectionalLight3D:
			child.light_energy = 1.05
	entry_shield.actor = actor
	step_fx.ground_wisp_tint = Color("9aafb2")
	step_fx.ground_wisp_zone = dressing.by_vent
	for material in actor.suit_materials:
		material.set_shader_parameter("room_lighting",1.0)
		dressing.apply_room_lighting(material)
		if exit_shield:
			material.set_shader_parameter("relay_position",exit_position+Vector3(0,1.06,.42))
			material.set_shader_parameter("relay_color",exit_shield.field_color())
	if exit_shield:
		exit_shield.actor = actor
		_update_relay_power(1.0,1.0,-1.0)
	else:
		_build_final_node()
	if not incoming.is_empty():
		_arrive_from_room()

func _at(point: Vector2) -> Vector3:
	return Vector3(point.x,point.y,0)

func _spawn_extra_droids() -> void:
	pass

func _spawn_crates() -> void:
	for floor_point: Vector2 in Rooms.LAYOUTS[room_index].wood:
		var crate := WoodenCrate.new()
		crate.position = _at(floor_point)
		add_child(crate)
		wooden_crates.append(crate)
	for floor_point: Vector2 in Rooms.LAYOUTS[room_index].metal:
		_spawn_metal(_at(floor_point)+Vector3.UP*.40,floor_point.y)

func _spawn_metal(home: Vector3, floor_y: float) -> MetalCrate:
	var crate := MetalCrate.new()
	crate.position = home
	crate.elevated_lane_floor_y = floor_y
	add_child(crate)
	metal_crates.append(crate)
	return crate

func _update_wave_spawner(_delta: float) -> void:
	pass

func _build_ui() -> void:
	var health := CanvasLayer.new()
	add_child(health)
	suit_readout = preload("res://scripts/miko8_health_bar.gd").new()
	suit_readout.actor = actor
	health.add_child(suit_readout)

	var fps_panel := PanelContainer.new()
	fps_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fps_skin := StyleBoxFlat.new()
	fps_skin.bg_color = Color(0.042,0.065,0.082,.84)
	fps_skin.corner_radius_top_left = 4
	fps_skin.corner_radius_bottom_left = 4
	fps_skin.corner_radius_top_right = 4
	fps_skin.corner_radius_bottom_right = 4
	fps_panel.add_theme_stylebox_override("panel",fps_skin)
	health.add_child(fps_panel)
	fps_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fps_panel.offset_left = -126
	fps_panel.offset_right = -24
	fps_panel.offset_top = 22
	fps_panel.offset_bottom = 59
	diagnostics = Label.new()
	diagnostics.name = "FrameRate"
	diagnostics.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diagnostics.add_theme_font_size_override("font_size",18)
	diagnostics.add_theme_color_override("font_color",Color("bfdbd4"))
	fps_panel.add_child(diagnostics)

	var transition_layer := CanvasLayer.new()
	transition_layer.layer = 20
	add_child(transition_layer)
	door_fade = ColorRect.new()
	door_fade.color = Color(0,0,0,0)
	door_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_layer.add_child(door_fade)
	door_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _update_status() -> void:
	var fps := Engine.get_frames_per_second()
	if fps != displayed_fps:
		displayed_fps = fps
		diagnostics.text = "%d FPS" % fps

func _on_sword_style_changed(_index: int, _style_name: String, _description: String) -> void:
	pass

func _build_course() -> void:
	for deck: Vector3 in Rooms.LAYOUTS[room_index].decks:
		_slab(deck.x,deck.y,deck.z)
	_block("Roof",Vector3(room_width*.5,room_roof-.225,0),Vector3(room_width,.45,3.7),FRAME,false)
	var has_exit: bool = Rooms.LAYOUTS[room_index].has("exit")
	_room_boundary(0,-1.0,ENTRANCE.y if room_index > 0 else -1.0)
	_room_boundary(room_width,1.0,exit_position.y if has_exit else -1.0)
	for landing: Vector3 in Rooms.LAYOUTS[room_index].landings:
		_landing("Landing",Vector3(landing.x,landing.y,0),landing.z)
	entry_shield = SHIELD.instantiate()
	entry_shield.name = "EntranceDoor"
	entry_shield.position = ENTRANCE
	entry_shield.arrival = true
	entry_shield.sealed = room_index == 0
	entry_shield.service_housing = room_index in [1,2,3]
	entry_shield.low_profile = room_index == 1
	entry_shield.return_length = ENTRANCE.x
	entry_shield.steel = dressing.room_steel
	add_child(entry_shield)
	if not has_exit:
		return
	exit_shield = SHIELD.instantiate()
	exit_shield.name = "ExitShield"
	exit_shield.position = exit_position
	exit_shield.pole = Rooms.LAYOUTS[room_index].pole
	exit_shield.service_housing = room_index in [1,2,3]
	exit_shield.low_profile = room_index == 1
	exit_shield.return_length = room_width-exit_position.x
	exit_shield.steel = dressing.room_steel
	add_child(exit_shield)
	if room_index == 0:
		dressing.build_relay(Vector3(22.5,12,-2.84),exit_shield.power_terminal(),exit_position+Vector3(0,1.06,.42),exit_shield.field_color())
	else:
		dressing.set_shield_light(exit_position+Vector3(0,1.06,.42),exit_shield.field_color())
	exit_shield.power_visuals.connect(_update_relay_power)

func _room_boundary(edge: float, direction: float, door_y: float) -> void:
	var wall_center := edge+direction*.28
	if door_y < 0.0:
		_boundary_span(wall_center,0.0,room_roof)
		return
	# The unseen part of the tunnel gives freight room to clear the wall ahead of Miko.
	var lintel := door_y+Door.OPENING_HEIGHT
	if door_y > 0.0:
		_boundary_span(wall_center,0.0,door_y)
	_boundary_span(wall_center,lintel,room_roof)
	_boundary_span(wall_center+direction*TUNNEL_DEPTH,door_y,lintel)
	var tunnel_center := edge+direction*TUNNEL_DEPTH*.5
	var tunnel_slab := Vector3(TUNNEL_DEPTH,.45,3.7)
	_block("TunnelFloor",Vector3(tunnel_center,door_y-.225,0),tunnel_slab,FRAME,false)
	_block("TunnelLintel",Vector3(tunnel_center,lintel+.225,0),tunnel_slab,FRAME,false)

func _boundary_span(x: float, bottom: float, top: float) -> void:
	_block("RoomBoundary",Vector3(x,(top+bottom)*.5,0),Vector3(.56,top-bottom,4),FRAME,false)

func _update_relay_power(feed: float, spill: float, surge: float) -> void:
	dressing.set_relay_power(feed,spill,surge)
	for material in actor.suit_materials:
		material.set_shader_parameter("relay_power",spill)

func _landing(label: String, at: Vector3, width: float) -> void:
	var landing := preload("res://props/lab_landing.tscn").instantiate()
	landing.name = label
	landing.position = at
	landing.width = width
	landing.surface_material = dressing.room_deck if room_index in [1,2,3] else null
	if room_index == 1 or room_index == 3:
		landing.beacon = Color("b9e9ed")
	$Landings.add_child(landing)
	dressing.mount_landing(at,width)

func _add_network_node(_node_name: String, _x: float) -> void:
	pass

func reset_room() -> void:
	super.reset_room()
	actor.position = _at(Rooms.LAYOUTS[room_index].checkpoints[checkpoint])+Vector3.UP*.04
	actor.facing = -1 if checkpoint == 1 and room_roof == 18.0 else 1
	camera_focus = actor.position.x
	camera_height = actor.position.y + 2.5
	_update_camera(1.0)

func _update_camera(delta: float) -> void:
	var player := actor.position
	if door_phase == DoorPhase.PLAY and actor.is_on_floor():
		var stops: Array = Rooms.LAYOUTS[room_index].checkpoints
		for index in range(checkpoint+1,stops.size()):
			var stop: Vector2 = stops[index]
			if absf(player.y-stop.y) < .2 and absf(player.x-stop.x) < (5.0 if room_index == 1 else 7.0):
				checkpoint = index
	var viewport := get_viewport().get_visible_rect().size
	var half_width := minf(room_width*.5,VIEW_HEIGHT*viewport.x/maxf(1.0,viewport.y)*.5)
	var lead := actor.velocity.x*.17 + float(actor.facing)*.72
	var east_turn: float = Rooms.LAYOUTS[room_index].decks[1].y if room_roof >= 12.0 else room_width
	var first_rise := lerpf(smoothstep(4.0,5.65,player.y),smoothstep(1.45,5.65,player.y),smoothstep(east_turn-2.0,east_turn+2.0,player.x))
	var second_rise := lerpf(smoothstep(10.0,11.6,player.y),smoothstep(7.55,11.6,player.y),1.0-smoothstep(6.0,10.0,player.x))
	var floor_y := (first_rise+second_rise)*6.0
	var west_inset := 8.0*second_rise*smoothstep(6.0,15.0,player.x) if room_roof == 18.0 else 0.0
	var east_inset := 5.2*first_rise*(1.0-second_rise)*(1.0-smoothstep(east_turn-8.0,east_turn,player.x)) if room_roof == 18.0 else 0.0
	var pan_range := room_width-2.0*half_width
	var inset_scale := minf(1.0,pan_range/maxf(west_inset+east_inset,.001))
	var left_bound := half_width+west_inset*inset_scale
	var right_bound := room_width-half_width-east_inset*inset_scale
	var center_x := clampf(player.x+lead,left_bound,maxf(left_bound,right_bound))
	var look_below := 1.05 if actor.look_down_time > .32 else 0.0
	var jump_follow := clampf((player.y-floor_y)*.25,-.30,.60)
	var wanted_y := floor_y+3.08+jump_follow-look_below
	if room_index == 1:
		wanted_y = player.y+2.2-look_below
	elif room_index == 2:
		wanted_y = 3.65+clampf(player.y*.16,0,.35)-look_below
	elif room_index == 3:
		wanted_y = player.y+2.7-look_below
	var lowest := minf(room_roof*.5,VIEW_HEIGHT*.5-.85)
	var highest := maxf(lowest,room_roof-VIEW_HEIGHT*.5+.80)
	var center_y := clampf(wanted_y,lowest,highest)
	if not dressing.has_fixed_lighting():
		var lower_light := 1.0-smoothstep(2.8,5.4,player.y)
		var upper_light := smoothstep(8.6,11.5,player.y)
		var gallery_light := smoothstep(2.1,5.4,player.y)*(1.0-upper_light)
		dressing.light_floors(Vector3(lower_light,gallery_light,upper_light),1.0-exp(-delta*4.4))
	camera_focus = lerpf(camera_focus,center_x,1.0-exp(-delta*5.5))
	camera_height = lerpf(camera_height,center_y,1.0-exp(-delta*5.0))
	camera_height = minf(camera_height,player.y+3.72)
	var focus := Vector3(camera_focus,camera_height,0)
	camera.position = focus + Vector3(0,CAMERA_RISE,CAMERA_DISTANCE)
	camera.look_at(focus)

func _build_final_node() -> void:
	network_node = preload("res://scripts/miko8_transfer_visual.gd").new()
	network_node.name = "FinalNetworkNode"
	network_node.actor = actor
	network_node.camera = camera
	network_node.position = _at(Rooms.LAYOUTS[room_index].node)+Vector3(0,0,-.48)
	dressing.add_child(network_node)
	completion_label = Label.new()
	completion_label.text = "NETWORK LINK ESTABLISHED"
	completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_label.add_theme_font_size_override("font_size",24)
	completion_label.add_theme_color_override("font_color",Color("b6ddd1"))
	suit_readout.get_parent().add_child(completion_label)
	completion_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	completion_label.offset_left = -230
	completion_label.offset_right = 230
	completion_label.offset_top = 32
	completion_label.hide()

func _update_network_transfer(delta: float) -> void:
	if not network_node:
		return
	var offset := actor.position-network_node.position
	var standing: bool = actor.is_on_floor() and actor.health > 0 and absf(offset.x) < .83 and absf(offset.y) < .2
	relay_charge = move_toward(relay_charge,1.0 if standing or completed else 0.0,delta)
	if relay_charge >= 1.0:
		completed = true
		completion_label.show()
	network_node.update_effect(delta,relay_charge,relay_charge,standing and not completed)

func _physics_process(delta: float) -> void:
	_update_door_transition(delta)
	_push_metal_crate()
	super._physics_process(delta)

func _push_metal_crate() -> void:
	if door_phase != DoorPhase.PLAY and door_phase != DoorPhase.LEAVE:
		return
	var axis: float = actor.command_axis if actor.automation else Input.get_axis("left","right")
	if absf(axis) < .15:
		return
	for index in range(actor.get_slide_collision_count()):
		var hit := actor.get_slide_collision(index)
		var crate := hit.get_collider() as MetalCrate
		if crate and hit.get_normal().x*axis < -.5 and absf(crate.position.y-actor.position.y-.4) < .4:
			crate.apply_central_force(Vector3(axis*68.0,0,0))
			return

func _update_door_transition(delta: float) -> void:
	match door_phase:
		DoorPhase.PLAY:
			if not actor.is_on_floor():
				return
			if exit_shield and absf(actor.position.y-exit_position.y) < .2 and actor.position.x > exit_position.x+Door.PASSAGE_CLEARANCE:
				_start_leaving(1.0)
			elif room_index > 0 and actor.position.y < .2 and actor.position.x < ENTRANCE.x-Door.PASSAGE_CLEARANCE:
				_start_leaving(-1.0)
		DoorPhase.LEAVE:
			var behind_wall := actor.position.x >= exit_position.x+2.68 if travel_direction > 0 else actor.position.x <= .62
			if behind_wall:
				actor.command_axis = 0.0
				door_phase = DoorPhase.FADE_OUT
		DoorPhase.FADE_OUT:
			door_fade.color.a = move_toward(door_fade.color.a,1.0,delta*5.0)
			if door_fade.color.a >= 1.0:
				door_phase = DoorPhase.FADE_IN
				_enter_destination.call_deferred()
		DoorPhase.FADE_IN:
			door_fade.color.a = move_toward(door_fade.color.a,0.0,delta*4.0)
			if door_fade.color.a <= 0.0:
				actor.command_axis = travel_direction
				door_phase = DoorPhase.ENTER
		DoorPhase.ENTER:
			var emerged := (actor.position.x >= ENTRANCE.x+1.8) if travel_direction > 0 else (actor.position.x <= exit_position.x-1.65)
			if emerged:
				actor.command_axis = 0.0
				actor.automation = was_automated
				door_phase = DoorPhase.PLAY
				suit_readout.set_process(true)

func _start_leaving(direction: float) -> void:
	_take_door_control()
	travel_direction = direction
	actor.command_axis = direction
	door_phase = DoorPhase.LEAVE

func _take_door_control() -> void:
	was_automated = actor.automation
	actor.automation = true
	actor.command_axis = 0.0
	actor.command_vertical = 0.0
	actor.command_held = false
	suit_readout.set_process(false)
	suit_readout.hide()
	for action in actor.buffers:
		actor.buffers[action] = 0.0

func _enter_destination() -> void:
	var destination: String = Rooms.PATHS[room_index+int(travel_direction)]
	var tree := get_tree()
	var freight: Array[Dictionary] = []
	var remaining: Array[Dictionary] = []
	var threshold := exit_position if travel_direction > 0 else ENTRANCE
	for crate: MetalCrate in metal_crates:
		var data := {"position":crate.position,"home":crate.home_position,"floor":crate.elevated_lane_floor_y,
			"pole":crate.polarity,"charge":crate.charge_remaining}
		var through := (crate.position.x-threshold.x)*travel_direction > .50
		if through and absf(crate.position.y-threshold.y-.40) < .26:
			freight.append(data)
		else:
			remaining.append(data)
	var broken: Array[bool] = []
	for crate: WoodenCrate in wooden_crates:
		broken.append(crate.broken)
	room_history[room_index] = {"metal":remaining,"wood":broken,"completed":completed}
	tree.set_meta(WorldTransfer,{"history":room_history,"direction":travel_direction,"freight":freight,
		"health":actor.health,"polarity":actor.suit_polarity,"style":actor.sword_style,"automation":was_automated})
	if tree.change_scene_to_file(destination) != OK:
		tree.remove_meta(WorldTransfer)
		push_error("Could not enter "+destination)
		actor.position = threshold+Vector3(-travel_direction*1.7,.04,0)
		actor.automation = was_automated
		door_fade.color.a = 0.0
		door_phase = DoorPhase.PLAY
		suit_readout.set_process(true)

func _arrive_from_room() -> void:
	travel_direction = incoming.direction
	var returning := travel_direction < 0.0
	var threshold := exit_position if returning else ENTRANCE
	_restore_room()
	_place_cargo(incoming.freight,threshold)
	actor.health = incoming.health
	actor._set_suit_pole(incoming.polarity)
	actor.set_sword_style(incoming.style)
	actor.automation = incoming.automation
	_take_door_control()
	actor.position = threshold+Vector3(-travel_direction*1.82,.04,0)
	actor.velocity = Vector3.ZERO
	actor.facing = int(travel_direction)
	if returning:
		exit_shield.open_for_return()
		checkpoint = Rooms.LAYOUTS[room_index].checkpoints.size()-1
	door_fade.color.a = 1.0
	door_phase = DoorPhase.FADE_IN
	step_fx.clear()
	_update_camera(3.0)
	camera.reset_physics_interpolation()
	actor.reset_physics_interpolation()
	incoming.clear()

func _restore_room() -> void:
	if not room_history.has(room_index):
		return
	var saved: Dictionary = room_history[room_index]
	completed = saved.completed
	for crate in metal_crates:
		remove_child(crate)
		crate.queue_free()
	metal_crates.clear()
	for data: Dictionary in saved.metal:
		var crate := _spawn_metal(data.home,data.floor)
		crate.move_through_door(data.position)
		_restore_charge(crate,data)
	for index in range(wooden_crates.size()):
		if saved.wood[index]:
			wooden_crates[index].restore_broken()

func _place_cargo(freight: Array, threshold: Vector3) -> void:
	var x := threshold.x+travel_direction*3.1
	var occupied: Array[float] = []
	for crate in metal_crates:
		if absf(crate.position.y-threshold.y) < 1.0:
			occupied.append(crate.position.x)
	for crate in wooden_crates:
		if not crate.broken and absf(crate.position.y-threshold.y) < 1.0:
			occupied.append(crate.position.x)
	occupied.sort()
	if travel_direction < 0.0:
		occupied.reverse()
	for data: Dictionary in freight:
		for other_x in occupied:
			if absf(other_x-x) < 1.0:
				x = other_x+travel_direction
		var crate := _spawn_metal(Vector3(x,threshold.y+.425,0),threshold.y)
		_restore_charge(crate,data)
		x += travel_direction*1.02

func _restore_charge(crate: MetalCrate, data: Dictionary) -> void:
	if data.pole != 0:
		crate.restore_charge(data.pole,data.charge)
