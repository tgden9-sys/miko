extends RefCounted

const CELL := .5
const BOUNDS := Rect2(-2,-3,31,18)
const ENTRANCE := Vector3(25,0,0)
const EXIT := Vector3(23,8,0)
const SPAWN := Vector3(23.3,.04,0)
const ENTRY_INWARD := -1.0
const EXIT_OUTWARD := 1.0
const BACKDROP := Rect2(-1,-.75,29,14.5)
const LIGHTS := [Vector2(22,3.25),Vector2(9.12,6.87),Vector2(5,7.3),Vector2(10,11.8),Vector2(20,11.8)]
const OPENINGS := [Rect2(8,0,2.5,8), Rect2(10.5,0,14.5,3.5), Rect2(0,4,8,9), Rect2(8,8,15,5), Rect2(25,0,3,2.5), Rect2(23,8,5,2.5)]
const SOLIDS := [Rect2(0,5.5,3,.5), Rect2(6,7.5,9,.5)]
const CRATE_HOME := Vector3(13.35, 0.0, 0.0)
const CRATE_STOP := 8.45
const CRATE_LANDING := Vector3(8.0, 4.0, 0.0)

static func solid(point: Vector2) -> bool:
	for block: Rect2 in SOLIDS:
		if block.has_point(point):
			return true
	for opening: Rect2 in OPENINGS:
		if opening.has_point(point):
			return false
	return true

static func foreground_solid(point: Vector2) -> bool:
	for end: Array in [[ENTRANCE,-ENTRY_INWARD],[EXIT,EXIT_OUTWARD]]:
		var door: Vector3 = end[0]
		if (point.x-door.x)*end[1] > 0 and point.y >= door.y and point.y < door.y+2.5:
			return true
	return solid(point)
