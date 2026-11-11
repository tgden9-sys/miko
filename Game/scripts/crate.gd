extends CharacterBody2D

enum Polarity { BROWN, RED, BLUE }

const TEXTURE_NEUTRAL = preload("res://sprites/crate_neutral.png")
const TEXTURE_RED = preload("res://sprites/crate_red.png")
const TEXTURE_BLUE = preload("res://sprites/crate_blue.png")

const GRAVITY: float = 980.0
const MAGNET_RANGE: float = 200.0
const REPEL_EXPLODE_IMPULSE: float = -680.0

# Physical Friction & Magnetic Acceleration:
const STATIC_FRICTION_THRESHOLD: float = 85.0
const KINETIC_FRICTION_COEFF: float = 180.0
const MAX_ATTRACT_SPEED: float = 580.0
const MIN_CREEP_SPEED: float = 12.0
const SUIT_STANDOFF: float = 88.0
const SUIT_FOLLOW_BAND: float = 155.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var sparks: CPUParticles2D = $MagneticSparks

@export var polarity: Polarity = Polarity.BROWN
# Refresh with a magnetic beam; plasma discharges immediately. Zero disables expiry.
@export var charge_duration: float = 15.0
const BREAKAWAY_SECONDS: float = 2.0
var charge_remaining: float = 0.0
var breakaway_remaining: float = 0.0
var repulsion_count: int = 0
var is_locked_on: bool = false
var lock_color: Color = Color.WHITE
var lock_pulse: float = 0.0
var base_modulate: Color = Color.WHITE
var repel_cooldown: float = 0.0
var field_timer: float = 0.0

func _ready() -> void:
	add_to_group("crates")
	charge_remaining = charge_duration if polarity != Polarity.BROWN else 0.0
	_update_texture_polarity()
	base_modulate = Color.WHITE

func _update_texture_polarity() -> void:
	if sprite == null:
		return
	match polarity:
		Polarity.BROWN:
			sprite.texture = TEXTURE_NEUTRAL
		Polarity.RED:
			sprite.texture = TEXTURE_RED
		Polarity.BLUE:
			sprite.texture = TEXTURE_BLUE

func _process(delta: float) -> void:
	field_timer += delta
	if is_locked_on:
		lock_pulse += delta * 9.0
		var pulse: float = 0.5 + 0.5 * sin(lock_pulse)
		# Full-body radiant color illumination on the chrome chassis:
		sprite.modulate = Color(1.3, 1.3, 1.3, 1.0).lerp(lock_color, 0.82 + 0.18 * pulse)
		queue_redraw()
	else:
		if sprite.modulate != base_modulate:
			sprite.modulate = sprite.modulate.lerp(base_modulate, 10.0 * delta)
		if polarity != Polarity.BROWN:
			queue_redraw()

func set_locked_on(active: bool, _hit_point: Vector2, beam_color: Color) -> void:
	is_locked_on = active
	lock_color = beam_color
	if active and polarity != Polarity.BROWN:
		charge_remaining = charge_duration
	queue_redraw()

func lock_in_color(color: Color) -> void:
	if color.r > color.b:
		polarity = Polarity.RED
	else:
		polarity = Polarity.BLUE
	_update_texture_polarity()
	# Searing initial flash on polarity polarization
	sprite.modulate = Color(1.4, 1.4, 1.4, 1.0)
	base_modulate = Color.WHITE
	is_locked_on = false
	repel_cooldown = 0.0
	charge_remaining = charge_duration
	queue_redraw()

func neutralize() -> void:
	polarity = Polarity.BROWN
	charge_remaining = 0.0
	breakaway_remaining = 0.0
	repel_cooldown = 0.0
	is_locked_on = false
	base_modulate = Color.WHITE
	_update_texture_polarity()
	sprite.modulate = Color(1.35, 1.35, 1.35)
	queue_redraw()

func _physics_process(delta: float) -> void:
	breakaway_remaining = maxf(0.0, breakaway_remaining - delta)
	if polarity != Polarity.BROWN and charge_duration > 0.0:
		charge_remaining = maxf(0.0, charge_remaining - delta)
		if charge_remaining <= 0.0:
			neutralize()
	if repel_cooldown > 0.0:
		repel_cooldown = maxf(0.0, repel_cooldown - delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	# Only red and blue crates have magnetic properties; brown crates do nothing
	var is_magnetically_pulled: bool = false
	if polarity != Polarity.BROWN:
		is_magnetically_pulled = _process_magnetism(delta)
		is_magnetically_pulled = _process_suit_magnetism(delta) or is_magnetically_pulled
		is_magnetically_pulled = _process_anchor_magnetism(delta) or is_magnetically_pulled

	# Ground friction deceleration when not being magnetically pulled
	if is_on_floor() and not is_magnetically_pulled:
		if absf(velocity.x) > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, 480.0 * delta)

	move_and_slide()

func _process_anchor_magnetism(delta: float) -> bool:
	var affected: bool = false
	for node in get_tree().get_nodes_in_group("magnetic_anchors"):
		if not (node is StaticBody2D) or int(node.get("polarity")) == 0:
			continue
		var anchor: StaticBody2D = node as StaticBody2D
		var same: bool = int(anchor.get("polarity")) == int(polarity)
		var reach: float = float(anchor.get("magnetic_range"))
		var offset: Vector2 = anchor.global_position - global_position
		if int(anchor.get("mount")) == 0:
			if absf(offset.x) > reach or absf(offset.y) > 142.0:
				continue
			var side: float = signf(offset.x)
			if side == 0.0:
				continue
			var contact_x: float = anchor.magnetic_contact_center(self).x
			var gap: float = absf(contact_x - global_position.x)
			var influence: float = clampf(1.0 - gap / reach, 0.0, 1.0)
			if same:
				velocity.x = move_toward(velocity.x, -side * 460.0, (1050.0 + 1300.0 * influence) * delta)
			else:
				var target_speed: float = side * minf(430.0, 35.0 + gap * 3.0)
				velocity.x = move_toward(velocity.x, target_speed, (1200.0 + 2200.0 * influence) * delta)
			affected = true
		else:
			if absf(offset.x) > 82.0 or offset.y >= 0.0 or -offset.y > reach:
				continue
			var target_y: float = anchor.magnetic_contact_center(self).y
			if same:
				velocity.y = move_toward(velocity.y, 480.0, 1900.0 * delta)
			else:
				var desired_y: float = clampf((target_y - global_position.y) * 7.0, -370.0, 180.0)
				velocity.y = move_toward(velocity.y, desired_y, 2700.0 * delta)
			affected = true
	return affected

func _process_suit_magnetism(delta: float) -> bool:
	var suit: CharacterBody2D = get_tree().get_first_node_in_group("magnetic_suit") as CharacterBody2D
	if suit == null or not suit.polarity_enabled or suit.reaction_state == suit.ReactionState.DYING:
		return false
	var suit_pole: int = int(suit.suit_polarity)
	if suit_pole == 0:
		return false
	var offset: Vector2 = suit.global_position - global_position
	var distance: float = offset.length()
	if distance < 30.0 or distance >= MAGNET_RANGE * 2.0:
		return false
	if suit_pole != int(polarity) and distance < SUIT_FOLLOW_BAND:
		# Follow the moving suit while preserving a visible gap in front of MIKO.
		var side: float = signf(offset.x)
		if side == 0.0:
			side = 1.0
		var error: float = distance - SUIT_STANDOFF
		var desired_x: float = suit.velocity.x + side * clampf(error * 5.0, -260.0, 260.0)
		velocity.x = move_toward(velocity.x, desired_x, 1800.0 * delta)
		velocity.x = clampf(velocity.x, -520.0, 520.0)
		return true
	var strength: float = pow(1.0 - distance / (MAGNET_RANGE * 2.0), 1.5)
	var sign_force: float = -1.0 if suit_pole == int(polarity) else 1.0
	var acceleration: Vector2 = offset / distance * sign_force * (1000.0 * strength)
	velocity += acceleration * delta
	velocity.x = clampf(velocity.x, -520.0, 520.0)
	velocity.y = clampf(velocity.y, -650.0, 650.0)
	return true

func _process_magnetism(delta: float) -> bool:
	var being_pulled: bool = false
	var repel_target: CharacterBody2D = null
	var repel_delta: Vector2 = Vector2.ZERO
	var repel_distance: float = INF
	var crates: Array[Node] = get_tree().get_nodes_in_group("crates")
	for other in crates:
		if other == self or not (other is CharacterBody2D):
			continue
		var other_crate: CharacterBody2D = other as CharacterBody2D
		var other_polarity = other_crate.get("polarity")

		# Brown crates will not do anything
		if other_polarity == null or other_polarity == Polarity.BROWN:
			continue

		var delta_pos: Vector2 = other_crate.global_position - global_position
		var dist: float = delta_pos.length()

		# Mutual interaction occurs whenever the two 200px magnetic field circles touch or overlap:
		var interaction_range: float = MAGNET_RANGE * 2.0
		if dist > interaction_range or dist < 1.0:
			continue

		var dir: Vector2 = delta_pos.normalized()

		# LIKE POLES REPEL (Red + Red, or Blue + Blue)
		if other_polarity == polarity:
			# Stacking repulsion or horizontal repulsion trigger
			if (absf(delta_pos.x) < 55.0 and dist < 125.0) or dist < 110.0:
				if repel_cooldown <= 0.0 and other_crate.repel_cooldown <= 0.0 and dist < repel_distance:
					repel_target = other_crate
					repel_delta = delta_pos
					repel_distance = dist

		# OPPOSING POLES ATTRACT (Red + Blue)
		else:
			# Neither side of an attraction pair can cancel an escape impulse.
			if breakaway_remaining > 0.0 or other_crate.breakaway_remaining > 0.0:
				continue
			var contact_distance: float = magnetic_half_width() + other_crate.magnetic_half_width() + 2.0
			if dist > contact_distance:
				being_pulled = true
				# Scale the contact point to each crate's collider width.
				var proximity: float = clampf(1.0 - ((dist - contact_distance) / (interaction_range - contact_distance)), 0.0, 1.0)
				
				# Non-linear magnetic pull: gentle creep at boundary, violent surge near center
				var pull_force: float = STATIC_FRICTION_THRESHOLD + 12.0 + 1550.0 * pow(proximity, 2.6)
				
				# Target speed starts at slow 12 px/s creep and accelerates to 580 px/s near center:
				var target_speed: float = lerpf(MIN_CREEP_SPEED, MAX_ATTRACT_SPEED, pow(proximity, 1.8))
				
				# Static vs Kinetic Friction model:
				var current_speed: float = absf(velocity.x)
				var is_moving: bool = current_speed > 25.0
				
				if not is_moving:
					# Overcoming static friction: starts slowly creeping, overcoming heavy inertia
					var breakaway_accel: float = (pull_force - STATIC_FRICTION_THRESHOLD) * 1.15
					velocity.x = move_toward(velocity.x, dir.x * target_speed, breakaway_accel * delta)
				else:
					# In kinetic sliding state: acceleration gathers speed, kinetic friction opposes motion
					var net_accel: float = maxf(40.0, pull_force - KINETIC_FRICTION_COEFF) * (0.8 + proximity * 2.8)
					velocity.x = move_toward(velocity.x, dir.x * target_speed, net_accel * delta)
					
					# High-speed friction scrape particles
					if is_on_floor() and current_speed > 160.0 and sparks != null and not sparks.emitting:
						sparks.color = Color(1.0, 0.85, 0.35, 0.6)
						sparks.position = Vector2(0, 20)
						sparks.direction = Vector2(-dir.x, -0.4)
						sparks.restart()
						sparks.emitting = true
			else:
				# Contact latching
				if absf(velocity.x) > 40.0:
					_play_magnetic_burst()
				velocity.x = 0.0

	# Resolve repulsion last, so iteration order cannot overwrite its impulse.
	if repel_target != null:
		_trigger_repulsion(repel_target, repel_delta)
		return false
	return being_pulled

func magnetic_half_width() -> float:
	var box: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D
	return box.size.x * 0.5 if box != null else 36.0

func _trigger_repulsion(other_crate: CharacterBody2D, delta_pos: Vector2) -> void:
	repel_cooldown = BREAKAWAY_SECONDS
	other_crate.repel_cooldown = BREAKAWAY_SECONDS
	breakaway_remaining = BREAKAWAY_SECONDS
	other_crate.breakaway_remaining = BREAKAWAY_SECONDS
	repulsion_count += 1
	other_crate.repulsion_count += 1
	_play_magnetic_burst()
	other_crate._play_magnetic_burst()

	# If stacked (vertical alignment):
	if absf(delta_pos.x) < 55.0:
		var is_self_top: bool = delta_pos.y > 0.0
		var top_crate: CharacterBody2D = self if is_self_top else other_crate
		var bottom_crate: CharacterBody2D = other_crate if is_self_top else self

		var dx: float = top_crate.global_position.x - bottom_crate.global_position.x
		var side_dir: float = signf(dx) if absf(dx) > 0.5 else (1.0 if randf() > 0.5 else -1.0)
		var kick_speed: float = 460.0

		top_crate.velocity.y = REPEL_EXPLODE_IMPULSE
		top_crate.velocity.x = side_dir * kick_speed
		bottom_crate.velocity.x = -side_dir * 120.0
	else:
		# Side-by-side repulsion
		var push_dir: float = -signf(delta_pos.x) if absf(delta_pos.x) > 0.1 else (1.0 if randf() > 0.5 else -1.0)
		# Enough travel to clear a third crate's 400 px coupling range.
		var kick_x: float = 560.0
		velocity.x = push_dir * kick_x
		velocity.y = -150.0

		other_crate.velocity.x = -push_dir * kick_x
		other_crate.velocity.y = -150.0

		if other_crate.has_method("_play_magnetic_burst"):
			other_crate._play_magnetic_burst()

func _play_magnetic_burst() -> void:
	if sparks:
		var spark_col: Color = Color(1.0, 0.2, 0.25) if polarity == Polarity.RED else Color(0.2, 0.65, 1.0)
		sparks.color = spark_col
		sparks.restart()
		sparks.emitting = true

func _draw() -> void:
	# 1. Subtle Magnetic Field Extent (Polarized Crates Only)
	if polarity != Polarity.BROWN:
		_draw_magnetic_field()

	# 2. Holographic Target Reticle Brackets (When Targeted by Player)
	if is_locked_on:
		var box: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D
		var half_w: float = box.size.x * 0.5 + 2.0 if box != null else 38.0
		var half_h: float = box.size.y * 0.5 + 2.0 if box != null else 20.0
		var b_len: float = 9.0
		var pulse_alpha: float = 0.75 + 0.25 * sin(lock_pulse)
		var col: Color = Color(lock_color.r, lock_color.g, lock_color.b, pulse_alpha)
		var glow_col: Color = Color(lock_color.r, lock_color.g, lock_color.b, 0.32 * pulse_alpha)

		# Outer glow brackets
		draw_line(Vector2(-half_w, -half_h), Vector2(-half_w + b_len, -half_h), glow_col, 4.0)
		draw_line(Vector2(-half_w, -half_h), Vector2(-half_w, -half_h + b_len), glow_col, 4.0)
		draw_line(Vector2(half_w, -half_h), Vector2(half_w - b_len, -half_h), glow_col, 4.0)
		draw_line(Vector2(half_w, -half_h), Vector2(half_w, -half_h + b_len), glow_col, 4.0)
		draw_line(Vector2(-half_w, half_h), Vector2(-half_w + b_len, half_h), glow_col, 4.0)
		draw_line(Vector2(-half_w, half_h), Vector2(-half_w, half_h - b_len), glow_col, 4.0)
		draw_line(Vector2(half_w, half_h), Vector2(half_w - b_len, half_h), glow_col, 4.0)
		draw_line(Vector2(half_w, half_h), Vector2(half_w, -half_h + b_len), glow_col, 4.0)

		# Sharp inner brackets
		draw_line(Vector2(-half_w, -half_h), Vector2(-half_w + b_len, -half_h), col, 2.0)
		draw_line(Vector2(-half_w, -half_h), Vector2(-half_w, -half_h + b_len), col, 2.0)
		draw_line(Vector2(half_w, -half_h), Vector2(half_w - b_len, -half_h), col, 2.0)
		draw_line(Vector2(half_w, -half_h), Vector2(half_w, -half_h + b_len), col, 2.0)
		draw_line(Vector2(-half_w, half_h), Vector2(-half_w + b_len, half_h), col, 2.0)
		draw_line(Vector2(-half_w, half_h), Vector2(-half_w, half_h - b_len), col, 2.0)
		draw_line(Vector2(half_w, half_h), Vector2(half_w - b_len, half_h), col, 2.0)
		draw_line(Vector2(half_w, half_h), Vector2(half_w, half_h - b_len), col, 2.0)

func _draw_magnetic_field() -> void:
	var is_red: bool = (polarity == Polarity.RED)
	var charge_fade: float = clampf(charge_remaining / 3.0, 0.2, 1.0) if charge_duration > 0.0 else 1.0
	var field_strength: float = charge_fade * (0.35 if breakaway_remaining > 0.0 else 1.0)
	var col_field: Color = Color(1.0, 0.24, 0.30) if is_red else Color(0.20, 0.78, 1.0)

	# Mutual interaction occurs when the two magnetic fields touch or overlap:
	var interaction_range: float = MAGNET_RANGE * 2.0
	var nearest_dist: float = 99999.0
	var nearest_crate: CharacterBody2D = null
	var is_opposite_pole: bool = false
	var crates: Array[Node] = get_tree().get_nodes_in_group("crates")
	for other in crates:
		if other == self or not (other is CharacterBody2D):
			continue
		var other_pol = other.get("polarity")
		if other_pol == null or other_pol == Polarity.BROWN:
			continue
		var d: float = global_position.distance_to(other.global_position)
		if d < interaction_range and d < nearest_dist and breakaway_remaining <= 0.0 and other.breakaway_remaining <= 0.0:
			nearest_dist = d
			nearest_crate = other as CharacterBody2D
			is_opposite_pole = (other_pol != polarity)

	var has_neighbor: bool = (nearest_crate != null)

	# 1. Subtle Translucent Radial Field Extent Disc (Soft atmospheric ambient volume)
	var pulse_glow: float = sin(field_timer * 2.6) * 0.006
	var disc_alpha: float = (0.026 if has_neighbor else 0.018) + pulse_glow
	draw_circle(Vector2.ZERO, MAGNET_RANGE, Color(col_field.r, col_field.g, col_field.b, disc_alpha * field_strength))

	# 2. Fine Perimeter Boundary Ring at MAGNET_RANGE (280 px) - Tuned to half intensity
	var breath: float = sin(field_timer * 2.2) * 0.02
	var base_ring_alpha: float = ((0.24 if has_neighbor else 0.16) + breath) * field_strength
	var ring_col: Color = Color(col_field.r, col_field.g, col_field.b, base_ring_alpha)

	# Crisp dashed perimeter circle (48 segments)
	var segments: int = 48
	var step_angle: float = TAU / float(segments)
	var dash_fill_ratio: float = 0.58
	for i in range(segments):
		var a1: float = float(i) * step_angle
		var a2: float = a1 + step_angle * dash_fill_ratio
		var p1: Vector2 = Vector2(cos(a1), sin(a1)) * MAGNET_RANGE
		var p2: Vector2 = Vector2(cos(a2), sin(a2)) * MAGNET_RANGE
		draw_line(p1, p2, ring_col, 1.4, true)

	# 3. Cardinal Alignment Notches & Polarity Markers
	var notch_len: float = 5.0
	var notches: Array[Vector2] = [
		Vector2(0, -MAGNET_RANGE), Vector2(0, MAGNET_RANGE),
		Vector2(-MAGNET_RANGE, 0), Vector2(MAGNET_RANGE, 0)
	]
	var notch_col: Color = Color(col_field.r, col_field.g, col_field.b, base_ring_alpha * 1.15)
	for n_pos in notches:
		var n_dir: Vector2 = n_pos.normalized()
		draw_line(n_pos - n_dir * notch_len, n_pos + n_dir * notch_len, notch_col, 1.5, true)

	# 4. Orbiting Magnetic Flux Chevrons (Clockwise for North/Red, Counter-Clockwise for South/Blue)
	var orbit_dir: float = 1.0 if is_red else -1.0
	var orbit_speed: float = 0.85 * orbit_dir
	var num_orbitals: int = 4
	for k in range(num_orbitals):
		var base_orb_angle: float = float(k) * (TAU / float(num_orbitals)) + field_timer * orbit_speed
		var p_mid: Vector2 = Vector2(cos(base_orb_angle), sin(base_orb_angle)) * MAGNET_RANGE
		var tangent: Vector2 = Vector2(-sin(base_orb_angle), cos(base_orb_angle)) * orbit_dir
		var normal: Vector2 = Vector2(cos(base_orb_angle), sin(base_orb_angle))
		
		# Compact chevron pointing along the magnetic flux orbit
		var chev_tip: Vector2 = p_mid + tangent * 6.5
		var chev_left: Vector2 = p_mid - tangent * 3.8 + normal * 3.5
		var chev_right: Vector2 = p_mid - tangent * 3.8 - normal * 3.5
		var chev_col: Color = Color(col_field.r, col_field.g, col_field.b, base_ring_alpha * 0.95)
		draw_line(chev_left, chev_tip, chev_col, 1.4, true)
		draw_line(chev_right, chev_tip, chev_col, 1.4, true)

	# 5. Expanding Outward Pulse Wave
	var ripple_period: float = 2.4
	var ripple_prog: float = fmod(field_timer, ripple_period) / ripple_period
	var ripple_r: float = ripple_prog * MAGNET_RANGE
	var ripple_alpha: float = (0.08 if not has_neighbor else 0.12) * (1.0 - ripple_prog) * field_strength
	if ripple_r > 20.0 and ripple_alpha > 0.005:
		draw_arc(Vector2.ZERO, ripple_r, 0.0, TAU, 36, Color(col_field.r, col_field.g, col_field.b, ripple_alpha), 1.2, true)

	# 6. Dynamic Inter-Crate Magnetic Coupling Tether
	if has_neighbor and nearest_crate != null:
		var local_other: Vector2 = to_local(nearest_crate.global_position)
		var proximity: float = clampf(1.0 - (nearest_dist / interaction_range), 0.0, 1.0)
		var flux_alpha: float = (0.18 + 0.28 * proximity) * field_strength

		if is_opposite_pole:
			# OPPOSITE POLES (Attraction): Dual bowed magnetic streamline field loops
			var mid: Vector2 = local_other * 0.5
			var perp: Vector2 = Vector2(-local_other.y, local_other.x).normalized()
			var bow_amp: float = 24.0 * (1.0 - proximity * 0.4)
			var bow_offset: float = sin(field_timer * 3.5) * 3.0

			# Central magnetic flux line
			var core_col: Color = Color(col_field.r, col_field.g, col_field.b, flux_alpha)
			draw_line(Vector2.ZERO, local_other, core_col, 1.7, true)

			# Upper and lower curved flux streamline loops
			var arc_pts_1: PackedVector2Array = PackedVector2Array()
			var arc_pts_2: PackedVector2Array = PackedVector2Array()
			var segs: int = 12
			for s in range(segs + 1):
				var t: float = float(s) / float(segs)
				var pt_straight: Vector2 = local_other * t
				var arch: float = sin(t * PI)
				arc_pts_1.append(pt_straight + perp * (bow_amp * arch + bow_offset * arch))
				arc_pts_2.append(pt_straight - perp * (bow_amp * arch + bow_offset * arch))

			var stream_col: Color = Color(col_field.r, col_field.g, col_field.b, flux_alpha * 0.65)
			for s in range(segs):
				draw_line(arc_pts_1[s], arc_pts_1[s + 1], stream_col, 1.2, true)
				draw_line(arc_pts_2[s], arc_pts_2[s + 1], stream_col, 1.2, true)
		else:
			# LIKE POLES (Repulsion): Deflection field barrier plane perpendicular to interaction axis
			var mid: Vector2 = local_other * 0.5
			var norm: Vector2 = Vector2(-local_other.y, local_other.x).normalized()
			var bar_len: float = 18.0 + 12.0 * proximity
			var jitter: float = (randf() - 0.5) * 3.0
			var rep_col: Color = Color(col_field.r, col_field.g, col_field.b, flux_alpha * 0.75)
			draw_line(mid - norm * bar_len + Vector2(jitter, jitter), mid + norm * bar_len - Vector2(jitter, jitter), rep_col, 1.8, true)
