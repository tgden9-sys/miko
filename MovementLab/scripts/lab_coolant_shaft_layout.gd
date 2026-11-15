extends RefCounted

const CELL := .5
const BOUNDS := Rect2(-3,-3,21,28)
const ENTRANCE := Vector3(1,0,0)
const EXIT := Vector3(14,16,0)
const SPAWN := Vector3(2.7,.04,0)
const DOOR_HEIGHT := 2.5
const BACKDROP := Rect2(-1,-3,16,24)
const LIGHTS := [Vector2(3,2.25),Vector2(10.8,7.15),Vector2(3,11.15),
	Vector2(10.8,15.15),Vector2(10.8,19)]
const OPENINGS := [Rect2(-1.5,0,15.5,2.5), Rect2(0,2.5,14,18),
	Rect2(14,16,4,2.5)]
const LANDINGS := [Vector3(4,4.04,0),Vector3(4,8.04,0),
	Vector3(4,12.04,0),Vector3(4,16.04,0)]
const SOLIDS := [
	Rect2(0,2.5,1,1), Rect2(8,1.5,6,.5), Rect2(0,3.5,6,.5),
	Rect2(8,5.5,6,.5), Rect2(0,7.5,6,.5), Rect2(8,9.5,6,.5), Rect2(0,11.5,6,.5),
	Rect2(8,13.5,2.5,.5), Rect2(0,15.5,6,.5),
	Rect2(10.5,15.5,3.5,.5)
]

static func solid(point: Vector2) -> bool:
	for block: Rect2 in SOLIDS:
		if block.has_point(point):
			return true
	for opening: Rect2 in OPENINGS:
		if opening.has_point(point):
			return false
	return true

static func foreground_solid(point: Vector2) -> bool:
	if point.x < ENTRANCE.x and point.y >= 0 and point.y < DOOR_HEIGHT:
		return true
	if point.x >= EXIT.x and point.y >= EXIT.y and point.y < EXIT.y+DOOR_HEIGHT:
		return true
	return solid(point)
