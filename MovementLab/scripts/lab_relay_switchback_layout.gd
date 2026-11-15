extends RefCounted

const CELL := .5
# Leave solid cells past the turn at x=25 so the shell builds a continuous
# right wall with collision, lining and joined deck trim.
const BOUNDS := Rect2(-3,-3,31,16)
const ENTRANCE := Vector3(1,0,0)
const EXIT := Vector3(1,6,0)
const SPAWN := Vector3(2.7,.04,0)
const ENTRY_INWARD := 1.0
const EXIT_OUTWARD := -1.0
const BACKDROP := Rect2(-1,-1.5,27,13.5)
const LIGHTS := [Vector2(5,4.65),Vector2(17,4.65),Vector2(22,8.25),Vector2(5,9.9),Vector2(14,9.9)]
const OPENINGS := [Rect2(1,0,24,5.5), Rect2(19,5.5,6,5.5), Rect2(1,6,18,5), Rect2(-3,0,4,2.5), Rect2(-3,6,4,2.5)]
const SOLIDS := [Rect2(15,1.5,9.5,.5)]
const CRATE_HOME := Vector3(17.45, 2.0, 0.0)
const CRATE_STOP := 19.67
const CRATE_LANDING := Vector3(19.0, 6.0, 0.0)

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
