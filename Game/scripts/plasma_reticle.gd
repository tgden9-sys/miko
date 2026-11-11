extends Node2D

@export var is_locked_on: bool = false
@export var charge_ratio: float = 0.0
@export var reticle_color: Color = Color(0.95, 0.45, 1.0, 0.85)

@onready var light: PointLight2D = get_node_or_null("ReticleLight")

var pulse: float = 0.0

func _process(delta: float) -> void:
	if not visible:
		if light != null:
			light.enabled = false
		return
	
	pulse += delta * 12.0
	var is_active: bool = is_locked_on or charge_ratio > 0.15
	if light != null:
		# Standby mode has zero point light glare; active lock/charge flares on with chromatic glow
		light.enabled = is_active
		if is_active:
			light.color = Color(reticle_color.r, reticle_color.g, reticle_color.b, 1.0)
			light.energy = 0.8 + 0.4 * sin(pulse) + (0.9 if is_locked_on else 0.0)
			light.texture_scale = 0.6 + 0.35 * charge_ratio
	queue_redraw()

func _draw() -> void:
	var is_active: bool = is_locked_on or charge_ratio > 0.15

	# An open four-corner receptacle shows where an unlatched beam can tag.
	if not is_active:
		var standby_col: Color = Color(reticle_color.r, reticle_color.g, reticle_color.b, 0.9)
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var corner := Vector2(sx * 11.0, sy * 11.0)
				draw_line(corner, corner - Vector2(sx * 5.0, 0), standby_col, 2.0)
				draw_line(corner, corner - Vector2(0, sy * 5.0), standby_col, 2.0)
		draw_circle(Vector2.ZERO, 2.0, standby_col)
		return

	# Active mode (locked onto crate or charging plasma): full holographic brackets & diamond HUD
	var base_alpha: float = 0.85 if not is_locked_on else 1.0
	var col_outer: Color = Color(reticle_color.r, reticle_color.g, reticle_color.b, base_alpha)
	var col_core: Color = Color(2.4, 2.2, 2.8, 1.0)
	var base_r: float = 17.0 - 5.0 * clampf(charge_ratio, 0.0, 1.0) + sin(pulse) * 1.5
	if is_locked_on:
		base_r += 3.0

	# Central diamond
	var diamond = PackedVector2Array([
		Vector2(0, -base_r * 0.45),
		Vector2(base_r * 0.45, 0),
		Vector2(0, base_r * 0.45),
		Vector2(-base_r * 0.45, 0)
	])
	draw_colored_polygon(diamond, Color(col_outer.r, col_outer.g, col_outer.b, 0.22))
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), col_outer, 1.8)

	# Hot center pip
	draw_circle(Vector2.ZERO, 2.8, col_core)

	# 4 Corner brackets
	var b_dist: float = base_r
	var b_len: float = 6.0
	# Top-Left
	draw_line(Vector2(-b_dist, -b_dist), Vector2(-b_dist + b_len, -b_dist), col_outer, 2.0)
	draw_line(Vector2(-b_dist, -b_dist), Vector2(-b_dist, -b_dist + b_len), col_outer, 2.0)
	# Top-Right
	draw_line(Vector2(b_dist, -b_dist), Vector2(b_dist - b_len, -b_dist), col_outer, 2.0)
	draw_line(Vector2(b_dist, -b_dist), Vector2(b_dist, -b_dist + b_len), col_outer, 2.0)
	# Bottom-Left
	draw_line(Vector2(-b_dist, b_dist), Vector2(-b_dist + b_len, b_dist), col_outer, 2.0)
	draw_line(Vector2(-b_dist, b_dist), Vector2(-b_dist, b_dist - b_len), col_outer, 2.0)
	# Bottom-Right
	draw_line(Vector2(b_dist, b_dist), Vector2(b_dist - b_len, b_dist), col_outer, 2.0)
	draw_line(Vector2(b_dist, b_dist), Vector2(b_dist, b_dist - b_len), col_outer, 2.0)
