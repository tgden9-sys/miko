extends Node2D

func _draw() -> void:
	var fixture: Area2D = get_parent() as Area2D
	if fixture.launch_flash <= 0.0:
		return
	var tone := Color(0.86, 0.88, 0.83)
	match int(fixture.polarity):
		1: tone = Color(1.0, 0.24, 0.27)
		2: tone = Color(0.22, 0.70, 1.0)
	var flash := tone
	flash.a = fixture.launch_flash / 0.28 * 0.55
	draw_line(Vector2(-29.0, -11.0), Vector2(29.0, -11.0), flash, 3.0, true)
