extends "res://scripts/lab_run.gd"
## Relay Works: a single readable route with three independently editable puzzle bays.
@export_range(1.0, 8.0, .25) var coolant_gap := 2.5
@export_range(1.0, 8.0, .25) var upper_gap := 3.0
@export_range(1.0, 8.0, .25) var exit_gap := 2.5
const EAST_WALL := 130.0
const OUTBOUND_RELAY := Vector3(105,6,0)
const STOPS := [
	Vector3(4,.04,0), Vector3(30,.04,0), Vector3(30,6.04,0),
	Vector3(16,6.04,0), Vector3(12,12.04,0), Vector3(48,12.04,0),
	Vector3(68,.04,0), Vector3(81,4.04,0), Vector3(108,.04,0),
	Vector3(117,.04,0), OUTBOUND_RELAY + Vector3(9,.04,0),
]
const NAMES := [
	"Relay Arrival", "Pump Stair", "Coolant Return", "West Lift", "Upper Exchange",
	"Cascade", "Lower Service", "Distribution Gallery", "Switchyard", "East Riser", "Outbound Relay",
]
const HINTS := [
	"RIGHT  /  Follow the amber deck to the pump stair", "UP  /  Staggered landings lead to the gallery",
	"LEFT  /  Cross the coolant gallery", "LEFT + UP  /  Climb around the gallery end",
	"RIGHT  /  Follow the upper exchange", "RIGHT + DOWN  /  Follow the three broad landings",
	"RIGHT + UP  /  Climb to the distribution gallery", "RIGHT  /  Cross the gallery and drop into the switchyard",
	"RIGHT  /  Pass the transformer to the east riser", "UP  /  Climb the riser and jump left to the relay",
	"LEFT  /  Follow the mezzanine to the network node",
]
var route_checkpoint := 0
var completed := false

func _ready() -> void:
	course_spawn_dummy = false
	course_zoom_controls = false
	next_level_path = ""
	super._ready()
	camera.fov = rad_to_deg(2.0*atan(VIEW_HEIGHT*.5/CAMERA_DISTANCE))

func _build_ui() -> void:
	course_title = "MIKO   /   LEVEL 2 - RELAY WORKS"
	super._build_ui()

func _spawn_extra_droids() -> void:
	pass

func _spawn_crates() -> void:
	pass

func _update_wave_spawner(_delta: float) -> void:
	pass

func _add_network_node(node_name: String, x: float) -> void:
	if node_name == "NetworkRelaySocket":
		super._add_network_node(node_name, OUTBOUND_RELAY.x)
		get_node("Dressing/" + node_name).position.y = OUTBOUND_RELAY.y
	else:
		super._add_network_node(node_name, x)

func _build_course() -> void:
	_slab(0,32,0)
	_landing("PumpLower",34,2,3)
	_landing("PumpUpper",39,4,3)
	# Wide staging pads on each side; widen a bay with its exported gap property.
	_puzzle_deck("CoolantPuzzleBay",14,34,6,24,coolant_gap)
	_landing("WestLower",10,8,3)
	_landing("WestUpper",5,10,3)
	_puzzle_deck("UpperPuzzleBay",10,50,12,32,upper_gap)
	_slab(0,50,18)
	_landing("CascadeUpper",55,9,5)
	_landing("CascadeMiddle",60,6,5)
	_landing("CascadeLower",65,3,5)
	_slab(62,73,0)
	_landing("ServiceLower",76,2,3)
	_puzzle_deck("OutboundPuzzleBay",79,96,4,87,exit_gap)
	_landing("SwitchyardDrop",98.5,2,3)
	_slab(101,119,0)
	_landing("RiserLower",121,2,3)
	_landing("RiserUpper",126,4,3)
	_slab(102,121,6)
	_slab(96, EAST_WALL, 12)
	_bulkhead("WestBoundary",Vector3(-.3,8,0),Vector3(.6,21,4))
	_bulkhead("PumpDivider",Vector3(43,5.5,0),Vector3(.6,12,4))
	var lintel := AABB(Vector3(99.575,5.3,-2), Vector3(.65,6.7,4))
	_block("SwitchyardLintel",lintel.get_center(),lintel.size,FRAME,false)
	bulkhead_bounds.append(lintel)
	_bulkhead("EastBoundary",Vector3(EAST_WALL+.3,5,0),Vector3(.6,16,4))

func _puzzle_deck(label: String, start: float, finish: float, height: float, center: float, gap: float) -> void:
	_slab(start,center-gap*.5,height)
	_slab(center+gap*.5,finish,height)
	var marker := Marker3D.new()
	marker.name = label
	marker.position = Vector3(center,height,0)
	marker.set_meta("gap_width",gap)
	marker.set_meta("purpose","Reserved magnetic-block puzzle bay; edit exported gap on level root")
	add_child(marker)

func _landing(label: String, x: float, y: float, width: float) -> void:
	var landing := preload("res://props/lab_landing.tscn").instantiate()
	landing.name = label
	landing.position = Vector3(x,y,0)
	landing.width = width
	$Landings.add_child(landing)
	$Dressing.landing_support(label,x,y,width)

func reset_room() -> void:
	super.reset_room()
	actor.position = STOPS[route_checkpoint]
	actor.facing = -1 if route_checkpoint in [2,3,10] else 1
	camera_focus = actor.position.x + float(actor.facing)*2.2
	camera_height = actor.position.y + 2.7
	_update_camera(1.0)

func _update_camera(delta: float) -> void:
	var p := actor.position
	# Broad landing regions also catch players who jump past a milestone marker.
	# Save only grounded positions, with fixed safe spawn pads for each region.
	if actor.is_on_floor():
		var reached := 0
		if absf(p.y) < .2 and p.x > 24 and p.x < 32: reached = 1
		if absf(p.y-6) < .2 and p.x >= 14 and p.x <= 34: reached = 3 if p.x < 21 else 2
		if absf(p.y-12) < .2 and p.x >= 10 and p.x <= 50: reached = 5 if p.x > 44 else 4
		if absf(p.y) < .2 and p.x >= 62 and p.x <= 73: reached = 6
		if absf(p.y-4) < .2 and p.x >= 79 and p.x <= 96: reached = 7
		if absf(p.y) < .2 and p.x >= 101 and p.x <= 119: reached = 9 if p.x > 115 else 8
		if absf(p.y-6) < .2 and p.x >= 102: reached = 10
		route_checkpoint = maxi(route_checkpoint,reached)
	active_room = route_checkpoint
	var view := get_viewport().get_visible_rect().size
	var half_width := minf(EAST_WALL*.5,VIEW_HEIGHT*view.x/maxf(1.0,view.y)*.5)
	var lead := float(actor.facing)*2.2 + clampf(actor.velocity.x*.16,-1.2,1.2)
	var target_x := clampf(p.x+lead,half_width,EAST_WALL-half_width)
	camera_focus = lerpf(camera_focus,target_x,1.0-exp(-delta*5.5))
	var target_y := p.y + 2.7
	if actor.look_down_time > .32: target_y -= 1.6
	camera_height = lerpf(camera_height,target_y,1.0-exp(-delta*5.0))
	var focus := Vector3(camera_focus,camera_height,0)
	camera.position = focus + Vector3(0,CAMERA_RISE,CAMERA_DISTANCE)
	camera.look_at(focus)

func _update_status() -> void:
	status.text = NAMES[route_checkpoint]
	direction_hint.text = "Level 2 complete  /  Relay Works surveyed" if completed else HINTS[route_checkpoint]
	diagnostics.text = "LEVEL 2  /  HP %d  /  %d FPS" % [actor.health,Engine.get_frames_per_second()]

func _update_network_transfer(delta: float) -> void:
	var relay := get_node_or_null("Dressing/NetworkRelaySocket")
	if not relay: return
	var near := absf(actor.position.x-OUTBOUND_RELAY.x) < .85 and absf(actor.position.y-OUTBOUND_RELAY.y) < .2
	if near and actor.is_on_floor() and actor.health > 0: completed = true
	relay.update_effect(delta,0.0,1.0 if completed else 0.0,false)
