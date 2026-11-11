extends StaticBody2D

enum Polarity { NEUTRAL, RED, BLUE }
enum Mount { WALL, CEILING }

@export var mount: Mount = Mount.WALL
@export var polarity: Polarity = Polarity.NEUTRAL
@export var magnetic_range: float = 285.0

@onready var charge_light: PointLight2D = $ChargeLight
@onready var charge_lines: Node2D = $ChargeLines

var is_locked_on: bool = false
var lock_color: Color = Color.WHITE

func _ready() -> void:
	add_to_group("magnetic_anchors")
	add_to_group("tag_targets")
	_update_appearance()

func set_locked_on(active: bool, _hit_point: Vector2, beam_color: Color) -> void:
	is_locked_on = active
	lock_color = beam_color
	charge_lines.queue_redraw()

func lock_in_color(color: Color) -> void:
	polarity = Polarity.RED if color.r > color.b else Polarity.BLUE
	is_locked_on = false
	_update_appearance()

func neutralize() -> void:
	polarity = Polarity.NEUTRAL
	is_locked_on = false
	_update_appearance()

func _update_appearance() -> void:
	if charge_light != null:
		charge_light.enabled = polarity != Polarity.NEUTRAL
		charge_light.color = Color(1.0, 0.12, 0.19) if polarity == Polarity.RED else Color(0.12, 0.58, 1.0)
	if charge_lines != null:
		charge_lines.queue_redraw()

func magnetic_contact_center(crate: CharacterBody2D) -> Vector2:
	var half_width: float = crate.magnetic_half_width() if crate.has_method("magnetic_half_width") else 27.0
	if mount == Mount.WALL:
		var side: float = -1.0 if crate.global_position.x < global_position.x else 1.0
		return Vector2(global_position.x + side * (29.0 + half_width + 3.0), crate.global_position.y)
	# The illustrated shell extends below its collider; leave a visible air gap.
	return Vector2(crate.global_position.x, global_position.y + 28.0 + 25.0 + 8.0)
