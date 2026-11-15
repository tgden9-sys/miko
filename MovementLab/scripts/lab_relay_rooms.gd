extends RefCounted

const PATHS := [
	"res://lab_level_3.tscn",
	"res://lab_pressure_riser.tscn",
	"res://lab_service_gallery.tscn",
	"res://lab_coolant_exchange.tscn",
	"res://lab_network_vault.tscn",
]

# Decks use (left, right, height). Landings use (center, height, width).
const LAYOUTS := [
	{
		"width": 36.0, "roof": 18.0, "exit": Vector2(30.4,12), "pole": 1,
		"decks": [Vector3(0,36,0),Vector3(0,27,6),Vector3(8,36,12)],
		"landings": [Vector3(30,2,3.1),Vector3(34,4,3),Vector3(5,8,2.8),Vector3(2.1,10,2.6)],
		"checkpoints": [Vector2(4.15,0),Vector2(24,6),Vector2(11,12)],
		"wood": [Vector2(9.7,0),Vector2(19.2,6),Vector2(15.9,12)],
		"metal": [Vector2(16.9,0),Vector2(13.4,6),Vector2(22.8,12)],
	},
	{
		"width": 16.0, "roof": 24.0, "exit": Vector2(12.8,18), "pole": 2,
		"decks": [Vector3(0,16,0),Vector3(8.0,16,18)],
		"landings": [Vector3(7.2,2.25,2.9),Vector3(11,4.5,2.9),Vector3(7.5,6.75,2.9),
			Vector3(4.2,9,4.65),Vector3(7.5,11.25,3),Vector3(11.1,13.5,2.8),Vector3(6.85,15.75,3.4)],
		"checkpoints": [Vector2(4.15,0),Vector2(4,9),Vector2(10,18)],
		"wood": [], "metal": [],
	},
	{
		"width": 43.0, "roof": 8.0, "exit": Vector2(38,0), "pole": 1,
		"decks": [Vector3(0,43,0)],
		"landings": [Vector3(11.0,2.10,3.3),Vector3(33.0,2.1,3.3)],
		"checkpoints": [Vector2(4.15,0),Vector2(24,0)],
		"wood": [Vector2(15.3,0),Vector2(28.1,0)], "metal": [Vector2(21,0)],
	},
	{
		"width": 32.0, "roof": 16.0, "exit": Vector2(27.8,6.6), "pole": 2,
		"decks": [Vector3(0,32,0),Vector3(17.1,20.9,3.2),Vector3(25.15,32,6.6)],
		"landings": [Vector3(14.0,1.6,3.0),Vector3(22.35,4.85,3.4)],
		"checkpoints": [Vector2(4.15,0),Vector2(18.3,3.2),Vector2(26.0,6.6)],
		"wood": [Vector2(9.3,0),Vector2(24.2,0)],
		"metal": [Vector2(19.35,3.2)],
	},
	{
		"width": 33.0, "roof": 12.0, "node": Vector2(4.2,6),
		"decks": [Vector3(0,33,0),Vector3(0,24,6)],
		"landings": [Vector3(27.3,2.15,3.0),Vector3(30.8,4.12,2.8)],
		"checkpoints": [Vector2(4.15,0),Vector2(22,6)],
		"wood": [Vector2(13.7,0),Vector2(16.5,6)], "metal": [Vector2(19.6,0)],
	},
]
