extends Area2D

const TEXTURE_NEUTRAL: Texture2D = preload("res://sprites/fixtures/freight_lock_neutral.png")
const TEXTURE_RED: Texture2D = preload("res://sprites/fixtures/freight_lock_red.png")
const TEXTURE_BLUE: Texture2D = preload("res://sprites/fixtures/freight_lock_blue.png")

enum Polarity { NEUTRAL, RED, BLUE }

@export var polarity: Polarity = Polarity.NEUTRAL

@onready var indicator: Node2D = $ChargeIndicator
@onready var charge_light: PointLight2D = $ChargeLight
@onready var sprite: Sprite2D = $Sprite2D

var is_locked_on: bool = false
var lock_color: Color = Color.WHITE
var launch_flash: float = 0.0

func _ready() -> void:
	add_to_group("launch_fixtures")
	_update_appearance()

func set_locked_on(active: bool, _hit_point: Vector2, beam_color: Color) -> void:
	is_locked_on = active
	lock_color = beam_color
	indicator.queue_redraw()

func lock_in_color(color: Color) -> void:
	polarity = Polarity.RED if color.r > color.b else Polarity.BLUE
	is_locked_on = false
	_update_appearance()

func neutralize() -> void:
	polarity = Polarity.NEUTRAL
	is_locked_on = false
	_update_appearance()

func trigger_launch() -> void:
	launch_flash = 0.28
	indicator.queue_redraw()

func _process(delta: float) -> void:
	if launch_flash > 0.0:
		launch_flash = maxf(0.0, launch_flash - delta)
		indicator.queue_redraw()

func _update_appearance() -> void:
	if sprite != null:
		match polarity:
			Polarity.RED: sprite.texture = TEXTURE_RED
			Polarity.BLUE: sprite.texture = TEXTURE_BLUE
			_: sprite.texture = TEXTURE_NEUTRAL
	if indicator != null:
		indicator.queue_redraw()
	if charge_light != null:
		charge_light.enabled = polarity != Polarity.NEUTRAL
		charge_light.color = Color(1.0, 0.2, 0.26) if polarity == Polarity.RED else Color(0.16, 0.64, 1.0)
