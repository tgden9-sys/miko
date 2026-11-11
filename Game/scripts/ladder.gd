class_name Ladder
extends Area2D

@export var ladder_height: float = 290.0
@export var climb_width: float = 64.0
@export var climb_speed: float = 126.0
@export var descent_speed: float = 75.6
@export var rung_spacing: float = 24.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var top_y: float:
	get:
		return global_position.y - ladder_height * 0.5

var bottom_y: float:
	get:
		return global_position.y + ladder_height * 0.5

var climb_x: float:
	get:
		return global_position.x

func _ready() -> void:
	add_to_group("ladders")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_dimensions()
	queue_redraw()

func _update_dimensions() -> void:
	if sprite != null:
		sprite.hide()
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		collision_shape.shape = collision_shape.shape.duplicate()
		collision_shape.shape.size = Vector2(climb_width, ladder_height)

func _draw() -> void:
	# Narrow rolled-steel rails sit beneath the rendered climbing hands.
	# Continuous grip faces also accommodate the alternating hand heights.
	var upper: float = -ladder_height * 0.5
	var lower: float = ladder_height * 0.5
	var left: float = -25.0
	var right: float = 29.0
	var dark := Color("121f30")
	var steel := Color("43596c")
	var edge := Color("8195a4")
	# Wall stand-offs with anchor plates, kept away from the gripping face.
	for y in [upper + 12.0, 0.0, lower - 12.0]:
		for x in [left, right]:
			var outwards: float = -1.0 if x < 0.0 else 1.0
			draw_rect(Rect2(Vector2(x - 5.0 + outwards * 7.0, y - 10.0), Vector2(10, 20)), dark)
			draw_rect(Rect2(Vector2(x - 4.0 + outwards * 7.0, y - 9.0), Vector2(8, 17)), steel)
			draw_line(Vector2(x, y), Vector2(x + outwards * 9.0, y), edge, 3.0)
			for bolt_y in [-6.0, 6.0]:
				draw_circle(Vector2(x + outwards * 7.0, y + bolt_y), 1.6, dark)
				draw_line(Vector2(x + outwards * 7.0 - 0.7, y + bolt_y - 0.7), Vector2(x + outwards * 7.0 + 0.7, y + bolt_y - 0.7), edge)
	# Box-section rungs: shadow, front face, worn top lip and traction cuts.
	var rung_y: float = upper + 10.0
	while rung_y < lower - 2.0:
		draw_rect(Rect2(left - 2.0, rung_y - 2.0, right - left + 4.0, 7.0), dark)
		draw_rect(Rect2(left, rung_y - 2.0, right - left, 4.0), steel)
		draw_line(Vector2(left, rung_y - 2.0), Vector2(right, rung_y - 2.0), edge, 1.0)
		for grip_x in range(-16, 24, 5):
			draw_line(Vector2(grip_x, rung_y), Vector2(grip_x + 2, rung_y), Color("263a4b"), 1.0)
		for weld_x in [left + 4.0, right - 4.0]:
			draw_line(Vector2(weld_x, rung_y - 1.0), Vector2(weld_x, rung_y + 2.0), Color("687b88"), 2.0)
		rung_y += rung_spacing
	for x in [left, right]:
		draw_rect(Rect2(x - 5.0, upper - 4.0, 10.0, ladder_height + 9.0), dark)
		draw_rect(Rect2(x - 3.0, upper - 3.0, 6.0, ladder_height + 6.0), steel)
		draw_line(Vector2(x - 2.0, upper - 2.0), Vector2(x - 2.0, lower + 2.0), edge, 1.0)
		draw_line(Vector2(x + 2.0, upper - 2.0), Vector2(x + 2.0, lower + 2.0), Color("293b4e"), 2.0)
		# Small oxide chips break up the manufactured edges without visual noise.
		for chip in range(12):
			var chip_y: float = upper + fmod(float(chip * 47 + int(x) * 3 + 500), ladder_height)
			draw_line(Vector2(x + 1.0, chip_y), Vector2(x + 2.0, chip_y + 2.0), Color("756451"), 1.0)
		# Muted brass end sleeves and a dark inset fastener.
		for cap_y in [upper, lower]:
			draw_rect(Rect2(x - 4.0, cap_y - 3.0, 8.0, 6.0), Color("8a8267"))
			draw_circle(Vector2(x, cap_y), 1.5, dark)

func is_near_top(y: float) -> bool:
	return y <= top_y + 35.0

func is_near_bottom(y: float) -> bool:
	return y >= bottom_y - 35.0

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("register_ladder"):
		body.register_ladder(self)

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("unregister_ladder"):
		body.unregister_ladder(self)
