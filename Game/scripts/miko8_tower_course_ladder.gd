extends "res://scripts/miko8_ladder.gd"
## The supplied tower already contains its ladder; register interaction only.
func _ready()->void:
	add_to_group("miko8_ladders")
