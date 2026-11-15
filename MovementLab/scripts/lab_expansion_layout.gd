extends RefCounted

const CELL := .5
const SCENES := [
	"res://lab_haulage_run.tscn",
	"res://lab_pressure_bridge.tscn",
	"res://lab_filter_cascade.tscn",
	"res://lab_coolant_sump.tscn",
	"res://lab_relay_bench.tscn",
]

# Rectangles are in world metres. The common cutaway shell fits both doors and
# builds collision and finished edges from these same openings and solids.
const ROOMS := [
	{
		"art": "rail", "width": 53.0, "bottom": 0.0, "top": 6.5,
		"entrance": Vector2(0, 0), "exit": Vector2(53, 0),
		"openings": [Rect2(0, 0, 53, 6.5)],
		"solid": [],
		"lights": [Vector2(5, 5.45), Vector2(15, 5.45), Vector2(26, 5.45), Vector2(38, 5.45), Vector2(48, 5.45)],
		"vents": [Vector3(8, 0, -1.1), Vector3(29, 0, -1.1), Vector3(46, 0, -1.1)],
		"metal": Color(.94, .98, 1.04), "ambient": Vector3(.76, .82, .88), "lamp": Color("daeaff"),
	},
	{
		"art": "bridge", "width": 32.0, "bottom": 0.0, "top": 14.0,
		"entrance": Vector2(0, 0), "exit": Vector2(32, 0),
		"openings": [Rect2(0, 0, 9, 14), Rect2(9, 8, 14, 6), Rect2(23, 0, 9, 14)],
		"solid": [Rect2(5.5, 2, 3, .5), Rect2(1, 4, 3, .5), Rect2(5.5, 6, 3, .5),
			Rect2(23, 5.5, 3, .5), Rect2(27.5, 3, 3.5, .5), Rect2(23.5, 1, 2.5, .5)],
		"lights": [Vector2(7, 4.9), Vector2(5, 10.5), Vector2(16, 12.5), Vector2(28, 10.5), Vector2(30, 5.8)],
		"vents": [Vector3(6, 0, -1.1), Vector3(15, 8, -1.1), Vector3(28, 0, -1.1)],
		"metal": Color(.98, 1.08, 1.04), "ambient": Vector3(.67, .83, .81), "lamp": Color("c4f5e8"),
	},
	{
		"art": "filter", "width": 30.0, "bottom": 0.0, "top": 12.0,
		"entrance": Vector2(0, 6), "exit": Vector2(30, 0),
		"openings": [Rect2(0, 6, 7, 6), Rect2(7, 4, 7, 7), Rect2(14, 2, 8, 7), Rect2(22, 0, 8, 7)],
		"solid": [Rect2(9.5, 6, 2.5, .5), Rect2(17.5, 4, 3, .5), Rect2(24, 2, 2.5, .5)],
		"lights": [Vector2(4, 10.8), Vector2(10.75, 9.75), Vector2(17, 7.9), Vector2(25, 5.8)],
		"vents": [Vector3(4.5, 6, -1.1), Vector3(13, 4, -1.1), Vector3(26, 0, -1.1)],
		"metal": Color(1.03, 1.03, .92), "ambient": Vector3(.79, .84, .72), "lamp": Color("ececc8"),
	},
	{
		"art": "sump", "mirror_art": true, "width": 32.0, "bottom": -4.0, "top": 9.0,
		"entrance": Vector2(0, 0), "exit": Vector2(32, 2.5),
		"openings": [Rect2(0, 0, 8, 7), Rect2(8, -4, 17, 13), Rect2(25, 2.5, 7, 6.5)],
		"solid": [Rect2(9.5, -2.5, 3.5, .5), Rect2(14.5, -1.5, 4, .5), Rect2(19.5, 0, 4, .5),
			Rect2(16.5, -3, 3.5, .5), Rect2(20.5, -2, 3.5, .5)],
		"lights": [Vector2(5, 5.8), Vector2(14, 4.7), Vector2(22, 5.1), Vector2(28, 7.55)],
		"vents": [Vector3(12, -4, -1.1), Vector3(21, -4, -1.1), Vector3(5, 0, -1.1)],
		"metal": Color(.9, .96, 1.14), "ambient": Vector3(.67, .76, .92), "lamp": Color("c9ddff"),
	},
	{
		"art": "relay", "width": 36.0, "bottom": -2.0, "top": 10.0,
		"entrance": Vector2(0, 0), "exit": Vector2(36, 4),
		"openings": [Rect2(0, 0, 12, 6), Rect2(12, 1.5, 4, 6.5), Rect2(16, -2, 6, 12),
			Rect2(22, 2.5, 5, 7.5), Rect2(27, 4, 9, 6)],
		"solid": [Rect2(17, -1, 2.5, .5), Rect2(19, .75, 2.5, .75)],
		"lights": [Vector2(5, 4.8), Vector2(13.5, 6.5), Vector2(19, 8.2), Vector2(25, 8.8), Vector2(32, 8.8)],
		"vents": [Vector3(7, 0, -1.1), Vector3(14, 1.5, -1.1), Vector3(31.5, 4, -1.1)],
		"metal": Color(1.14, .99, .93), "ambient": Vector3(.86, .75, .73), "lamp": Color("ffe0ca"),
	},
	{
		"art": "maintenance", "width": 46.0, "bottom": 0.0, "top": 14.0,
		"entrance": Vector2(0, 0), "exit": Vector2(46, 0), "locked_door": Vector3(46, 7.5, 0),
		"service_bay": Rect2(46, 7.5, 3.5, 2.5),
		"openings": [Rect2(0, 0, 14, 9), Rect2(14, 0, 18, 14), Rect2(32, 0, 14, 12), Rect2(46, 7.5, 3.5, 2.5)],
		"solid": [Rect2(14, 0, 16, 1.5), Rect2(19, 1.5, 8, 1), Rect2(27.5, 4, 3.5, .5),
			Rect2(32.5, 6, 4.5, .5), Rect2(37.5, 7, 8.5, .5)],
		"lights": [Vector2(4, 6.8), Vector2(12, 7.6), Vector2(20, 8.8), Vector2(28, 10.9),
			Vector2(35, 10.7), Vector2(41, 10.85), Vector2(41, 5.7)],
		"vents": [Vector3(8, 0, -1.1), Vector3(22, 2.5, -1.1), Vector3(39, 0, -1.1), Vector3(41.5, 7.5, -1.1)],
		"metal": Color(1.06, 1.02, .92), "ambient": Vector3(.81, .83, .75), "lamp": Color("ffdfb7"),
	},
]

var BOUNDS: Rect2
var BACKDROP: Rect2
var ENTRANCE: Vector3
var EXIT: Vector3
var SPAWN: Vector3
var LIGHTS: Array
var ENTRY_INWARD: float
var EXIT_OUTWARD: float
var room: Dictionary
var openings: Array
var solids: Array

func _init(index: int) -> void:
	room = ROOMS[index]
	var width: float = room.width
	var bottom: float = room.bottom
	var top: float = room.top
	BOUNDS = Rect2(-5, bottom - 4, width + 10, top - bottom + 7)
	BACKDROP = Rect2(-2.0, bottom - .75, width + 4, top - bottom + 1.5)
	ENTRANCE = Vector3(room.entrance.x, room.entrance.y, 0)
	EXIT = Vector3(room.exit.x, room.exit.y, 0)
	ENTRY_INWARD = 1.0 if ENTRANCE.x == 0.0 else -1.0
	EXIT_OUTWARD = -1.0 if EXIT.x == 0.0 else 1.0
	SPAWN = ENTRANCE + Vector3(1.7 * ENTRY_INWARD, .04, 0)
	LIGHTS = room.lights
	openings = room.openings.duplicate()
	solids = room.solid
	for door: Vector3 in [ENTRANCE, EXIT]:
		var tunnel_x := -4.0 if door.x == 0.0 else width
		openings.append(Rect2(tunnel_x, door.y, 4, 2.5))

func solid(point: Vector2) -> bool:
	for block: Rect2 in solids:
		if block.has_point(point):
			return true
	for opening: Rect2 in openings:
		if opening.has_point(point):
			return false
	return true

func foreground_solid(point: Vector2) -> bool:
	if room.has("service_bay") and room.service_bay.has_point(point):
		return false
	return point.x < 0.0 or point.x >= room.width or solid(point)
