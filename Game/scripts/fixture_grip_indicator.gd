extends Node2D

var glow: float = 0.0
var pulse: float = 0.0

func _process(delta: float) -> void:
	var fixture: Area2D = get_parent() as Area2D
	var suit: Node = get_tree().get_first_node_in_group("magnetic_suit")
	var attached: bool = suit != null and suit.get("latched_fixture") == fixture
	if attached:
		attached = absf(suit.global_position.x - fixture.global_position.x) < 9.0 and (suit as CharacterBody2D).is_on_floor()
	# A short fade keeps the contacts from popping as the suit engages.
	glow = move_toward(glow, 1.0 if attached else 0.0, delta * 7.0)
	pulse += delta * 8.0
	queue_redraw()

func _draw() -> void:
	if glow <= 0.01:
		return
	var fixture: Area2D = get_parent() as Area2D
	var tone := Color(1.0, 0.24, 0.3) if int(fixture.get("polarity")) == 1 else Color(0.23, 0.73, 1.0)
	var brightness: float = glow * (0.8 + 0.2 * sin(pulse))
	for sign in [-1.0, 1.0]:
		var post_x: float = sign * 38.0
		var hand_x: float = sign * 44.0
		var y: float = -44.0
		var soft := Color(tone.r, tone.g, tone.b, brightness * 0.24)
		var solid := Color(tone.r, tone.g, tone.b, brightness * 0.95)
		draw_line(Vector2(post_x, y), Vector2(hand_x, y), soft, 9.0, true)
		draw_line(Vector2(post_x, y), Vector2(hand_x, y), solid, 2.3, true)
		draw_line(Vector2(post_x, y - 6.0), Vector2(post_x, y + 6.0), soft, 6.0, true)
		draw_line(Vector2(post_x, y - 6.0), Vector2(post_x, y + 6.0), solid, 2.0, true)
		draw_line(Vector2(hand_x, y - 4.0), Vector2(hand_x, y + 4.0), Color(1.0, 1.0, 1.0, brightness * 0.8), 1.4, true)
