extends RefCounted

const CELL := .5
const BOUNDS := Rect2(-3,-3,29,13)
const ENTRANCE := Vector3(1,0,0)
const EXIT := Vector3(21.5,0,0)
const SPAWN := Vector3(2.7,.04,0)
const DOOR_HEIGHT := 2.5
const BACKDROP := Rect2(-1.5,-1.25,25.5,8.5)
const LIGHTS := [Vector2(4.4,4.15),Vector2(18,4.15)]
const OPENING := Rect2(-3,0,29,6.5)
const SOLIDS := [
		Rect2(-3,0,1.5,6.5), Rect2(-1.5,2.5,2.5,4), Rect2(21.5,2.5,4.5,4),
		Rect2(1,4.5,5,2), Rect2(17,4.5,4.5,2),
		Rect2(7.5,0,2.5,.5), Rect2(10,0,3,1), Rect2(13,0,2.5,.5)
]

static func solid(point: Vector2) -> bool:
	for block: Rect2 in SOLIDS:
		if block.has_point(point):
			return true
	return not OPENING.has_point(point)

static func foreground_solid(point: Vector2) -> bool:
	if point.y >= 0 and point.y < DOOR_HEIGHT and (point.x < ENTRANCE.x or point.x >= EXIT.x):
		return true
	return solid(point)
