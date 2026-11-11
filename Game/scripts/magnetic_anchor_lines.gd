extends Node2D

@onready var anchor: StaticBody2D = get_parent()

func _draw() -> void:
	var pole: int = int(anchor.get("polarity"))
	var locked: bool = bool(anchor.get("is_locked_on"))
	if pole == 0 and not locked:
		return
	var col: Color = Color(1.0, 0.10, 0.16) if pole == 1 else Color(0.10, 0.62, 1.0)
	if pole == 0:
		col = anchor.get("lock_color")
	var glow: Color = Color(col.r, col.g, col.b, 0.16)
	if int(anchor.get("mount")) == 0:
		for x in [-4.0, 4.0]:
			draw_line(Vector2(x, -101), Vector2(x, 92), glow, 12.0)
			draw_line(Vector2(x, -101), Vector2(x, 92), col, 3.0)
			draw_line(Vector2(x, -101), Vector2(x, 92), Color(1.0, 0.92, 0.88, 0.7), 0.8)
	else:
		for y in [8.0, 13.0]:
			draw_line(Vector2(-38, y), Vector2(38, y), glow, 10.0)
			draw_line(Vector2(-38, y), Vector2(38, y), col, 2.7)
			draw_line(Vector2(-38, y), Vector2(38, y), Color(1.0, 0.94, 0.88, 0.7), 0.7)
