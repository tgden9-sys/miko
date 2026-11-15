extends RefCounted

# Rectangles are in world metres, with Y increasing upward.
# Empty space defines the route. All remaining cells become solid cutaway walls.
const CELL := .5
const BOUNDS := Rect2(-3,-3,60,19)
const OPENINGS := [
	Rect2(0,0,18,6),
	Rect2(18,0,14,12),
	Rect2(32,4,22,6),
	Rect2(54,4,3,2.5),
]
const SOLIDS := [
	Rect2(0,2.5,1,2),
	Rect2(8,0,3,1),
	Rect2(0,4.5,5,1.5),
	Rect2(14,4.5,4,1.5),
	Rect2(19.5,0,3.5,2),
	Rect2(26,0,5,4),
	# An accessible landing a metre below the two upper decks.
	Rect2(31,0,1,3),
	Rect2(23.5,7,2,5),
	Rect2(37,4,3,1.5),
	Rect2(32,8.5,3,1.5),
	Rect2(51.5,6.5,2.5,3.5),
]
const BACKDROP := Rect2(-1,-3.5,56,18.67)
const LIGHTS := [Vector2(6,5.3),Vector2(12,5.3),Vector2(21,10.9),Vector2(29,10.9),Vector2(41,9.3),Vector2(50,9.3)]
const SPAWN := Vector3(3,.04,0)
const ENTRANCE := Vector3(1,0,0)
const EXIT := Vector3(51.5,4,0)
const DOOR_HEIGHT := 2.5

# Traversable tunnels are concealed behind the near wall. This visual occupancy
# shares the shell's perimeter/mitres without turning the passage into collision.
static func foreground_solid(point: Vector2) -> bool:
	if point.x <= ENTRANCE.x and point.y >= ENTRANCE.y and point.y < ENTRANCE.y+DOOR_HEIGHT:
		return true
	if point.x >= EXIT.x and point.y >= EXIT.y and point.y < EXIT.y+DOOR_HEIGHT:
		return true
	return solid(point)

static func solid(point: Vector2) -> bool:
	for block: Rect2 in SOLIDS:
		if block.has_point(point):
			return true
	for opening: Rect2 in OPENINGS:
		if opening.has_point(point):
			return false
	return true
