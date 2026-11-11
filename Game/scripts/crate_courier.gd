extends "res://scripts/crate.gd"

const COURIER_NEUTRAL: Texture2D = preload("res://sprites/crates/courier_side_neutral.png")
const COURIER_RED: Texture2D = preload("res://sprites/crates/courier_side_red.png")
const COURIER_BLUE: Texture2D = preload("res://sprites/crates/courier_side_blue.png")

func _update_texture_polarity() -> void:
	if sprite == null:
		return
	match int(polarity):
		0: sprite.texture = COURIER_NEUTRAL
		1: sprite.texture = COURIER_RED
		2: sprite.texture = COURIER_BLUE
