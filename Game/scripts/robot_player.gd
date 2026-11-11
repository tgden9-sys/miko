extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var beam: Line2D = $AimBeam
@onready var beam_glow: Line2D = $BeamGlow
@onready var sparkles: CPUParticles2D = $BeamSparkles
@onready var raycast: RayCast2D = $AimRayCast

const MOVE_SPEED: float = 340.0
const JUMP_SPEED: float = -430.0
const GRAVITY: float = 980.0
const DASH_SPEED: float = 780.0
const DASH_DURATION: float = 0.24

const DEFAULT_BEAM_LENGTH: float = 95.0
const MIN_BEAM_LENGTH: float = 35.0
const MAX_BEAM_LENGTH: float = 1400.0
const BEAM_LENGTH_SPEED: float = 750.0
const MOUSE_LENGTH_SENSITIVITY: float = 2.4
const MOUSE_ANGLE_SENSITIVITY: float = 0.32

var facing: int = 1
var visual_facing: int = 1
var turn_target: int = 1
var turning: bool = false
var transition: StringName = &""
var aim_side: StringName = &""
var aim_lowering: bool = false
var aim_angle_degrees: float = 0.0
var aim_angle_velocity: float = 0.0
var current_beam_length: float = DEFAULT_BEAM_LENGTH
var locked_target: Object = null
var aim_anchors: Dictionary = {}
var dash_left: float = 0.0
var dash_ready: bool = true
var jump_was_down: bool = false
var dash_was_down: bool = false
var previous_direction: int = 0
var was_on_floor: bool = false
var has_touched_floor: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var anchors_text: String = FileAccess.get_file_as_string("res://sprites/aim_anchors.json")
	var parsed: Variant = JSON.parse_string(anchors_text)
	if parsed is Dictionary:
		aim_anchors = parsed
	sprite.flip_h = false
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(&"idle")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	if event is InputEventMouseMotion:
		var is_aiming: bool = aim_side != &"" or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_E)
		if is_aiming:
			# Laser length is controlled by mouse movement in the facing direction
			var forward_delta: float = event.relative.x * float(visual_facing)
			current_beam_length = clampf(current_beam_length + forward_delta * MOUSE_LENGTH_SENSITIVITY, MIN_BEAM_LENGTH, MAX_BEAM_LENGTH)

			# Vertical mouse movement tilts arm and beam elevation
			aim_angle_degrees = clampf(aim_angle_degrees - event.relative.y * MOUSE_ANGLE_SENSITIVITY, -40.0, 40.0)

func _on_animation_finished() -> void:
	if aim_lowering:
		aim_side = &""
		aim_lowering = false
	elif turning:
		visual_facing = turn_target
		turning = false
	elif transition != &"":
		transition = &""

func _faced_clip(base: StringName) -> StringName:
	return StringName(str(base) + ("_left" if visual_facing < 0 else ""))

func _aim_angle_clip() -> StringName:
	var base: String = str(_faced_clip(aim_side))
	var sample: int = clampi(roundi(aim_angle_degrees / 2.0) * 2, -40, 40)
	if sample > 0:
		return StringName(base + "_up" + str(sample))
	if sample < 0:
		return StringName(base + "_down" + str(-sample))
	return StringName(base)

func _clear_locked_target(released: bool = false) -> void:
	if locked_target != null and is_instance_valid(locked_target):
		if released:
			var release_color: Color = Color(1.0, 0.16, 0.19) if aim_side == &"aim_left_arm" else Color(0.18, 0.55, 1.0)
			if locked_target.has_method("lock_in_color"):
				locked_target.lock_in_color(release_color)
			elif locked_target.has_method("set_locked_on"):
				locked_target.set_locked_on(false, Vector2.ZERO, Color.WHITE)
		else:
			if locked_target.has_method("set_locked_on"):
				locked_target.set_locked_on(false, Vector2.ZERO, Color.WHITE)
	locked_target = null

func _update_beam(aim_request: StringName) -> void:
	var base_clip: StringName = _faced_clip(aim_side)
	var raised: bool = sprite.animation != base_clip or sprite.frame >= 10
	beam.visible = aim_request != &"" and raised
	beam_glow.visible = beam.visible
	if not beam.visible:
		raycast.enabled = false
		sparkles.emitting = false
		_clear_locked_target(aim_lowering)
		queue_redraw()
		return

	var clip: StringName = _aim_angle_clip()
	var position_data: Array = aim_anchors.get(str(clip), [0.0, 0.0])
	var radians_angle: float = deg_to_rad(aim_angle_degrees)
	var direction: Vector2 = Vector2(float(visual_facing) * cos(radians_angle), -sin(radians_angle))
	var origin: Vector2 = Vector2(float(position_data[0]), float(position_data[1])) + direction * 8.0
	var end_local: Vector2 = origin + direction * current_beam_length

	raycast.position = origin
	raycast.target_position = direction * current_beam_length
	raycast.enabled = true
	raycast.force_raycast_update()

	var hit_crate: Object = null
	if raycast.is_colliding():
		var hit_point_global: Vector2 = raycast.get_collision_point()
		end_local = to_local(hit_point_global)
		var collider: Object = raycast.get_collider()
		if collider != null and collider.is_in_group("crates"):
			hit_crate = collider

	if hit_crate != locked_target:
		_clear_locked_target(false)
		locked_target = hit_crate

	var is_locked: bool = (locked_target != null)
	var is_red: bool = (aim_side == &"aim_left_arm")
	var active_color: Color = Color(1.0, 0.16, 0.19) if is_red else Color(0.18, 0.55, 1.0)

	if is_locked:
		if locked_target.has_method("set_locked_on"):
			locked_target.set_locked_on(true, to_global(end_local), active_color)
		beam.width = 3.8
		beam_glow.width = 16.0
		if is_red:
			beam.default_color = Color(1.0, 0.18, 0.22, 0.65)
			beam_glow.default_color = Color(1.0, 0.08, 0.14, 0.30)
		else:
			beam.default_color = Color(0.22, 0.60, 1.0, 0.65)
			beam_glow.default_color = Color(0.10, 0.45, 1.0, 0.30)
	else:
		beam.width = 2.0
		beam_glow.width = 9.0
		if is_red:
			beam.default_color = Color(1.0, 0.32, 0.36, 0.28)
			beam_glow.default_color = Color(1.0, 0.14, 0.18, 0.08)
		else:
			beam.default_color = Color(0.28, 0.65, 1.0, 0.28)
			beam_glow.default_color = Color(0.12, 0.45, 1.0, 0.08)

	var points: PackedVector2Array = PackedVector2Array([origin, end_local])
	beam.points = points
	beam_glow.points = points

	sparkles.position = end_local
	sparkles.color = Color(active_color.r, active_color.g, active_color.b, 0.95 if is_locked else 0.55)
	sparkles.emitting = true
	queue_redraw()

func _draw() -> void:
	if beam.visible and beam.points.size() >= 2:
		var tip: Vector2 = beam.points[1]
		var t: float = float(Time.get_ticks_msec()) * 0.009
		var is_locked: bool = (locked_target != null)
		var ray_len: float = (7.5 if is_locked else 5.0) + 2.0 * sin(t * 3.5)
		var col: Color = beam.default_color
		var star_col: Color = Color(col.r, col.g, col.b, 0.9 if is_locked else 0.65)
		var glow_col: Color = Color(col.r, col.g, col.b, 0.35)

		var cos_t: float = cos(t)
		var sin_t: float = sin(t)
		var arm_x: Vector2 = Vector2(cos_t, sin_t) * ray_len
		var arm_y: Vector2 = Vector2(-sin_t, cos_t) * ray_len

		draw_line(tip - arm_x, tip + arm_x, glow_col, 3.5)
		draw_line(tip - arm_y, tip + arm_y, glow_col, 3.5)
		draw_line(tip - arm_x, tip + arm_x, star_col, 1.5)
		draw_line(tip - arm_y, tip + arm_y, star_col, 1.5)
		draw_circle(tip, 1.8, star_col)

func _physics_process(delta: float) -> void:
	var left_down: bool = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right_down: bool = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var jump_down: bool = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP)
	var dash_down: bool = Input.is_key_pressed(KEY_X)
	var aim_request: StringName = &""
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_Q):
		aim_request = &"aim_left_arm"
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_E):
		aim_request = &"aim_right_arm"

	if aim_request != &"":
		var adjust: int = int(Input.is_key_pressed(KEY_UP)) - int(Input.is_key_pressed(KEY_DOWN))
		if adjust != 0:
			aim_angle_velocity = move_toward(aim_angle_velocity, float(adjust) * 90.0, 540.0 * delta)
			aim_angle_degrees = clampf(aim_angle_degrees + aim_angle_velocity * delta, -40.0, 40.0)
			if absf(aim_angle_degrees) >= 40.0 and signf(aim_angle_velocity) == signf(aim_angle_degrees):
				aim_angle_velocity = 0.0
		else:
			aim_angle_velocity = move_toward(aim_angle_velocity, 0.0, 540.0 * delta)

		var forward_input: float = float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT))
		var length_dir: float = forward_input * float(visual_facing)
		if length_dir != 0.0:
			current_beam_length = clampf(current_beam_length + length_dir * BEAM_LENGTH_SPEED * delta, MIN_BEAM_LENGTH, MAX_BEAM_LENGTH)

	var aim_active: bool = aim_request != &"" or aim_side != &""
	var direction: int = 0 if aim_active else int(right_down) - int(left_down)
	if direction != 0:
		facing = direction

	if is_on_floor():
		dash_ready = true
		if jump_down and not jump_was_down and not aim_active:
			velocity.y = JUMP_SPEED

	if dash_down and not dash_was_down and dash_ready and not aim_active:
		dash_left = DASH_DURATION
		dash_ready = false

	if aim_active:
		dash_left = 0.0
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		elif velocity.y > 0.0:
			velocity.y = 0.0
	elif dash_left > 0.0:
		dash_left = maxf(0.0, dash_left - delta)
		velocity.x = float(facing) * DASH_SPEED
		velocity.y = 0.0
	else:
		velocity.x = float(direction) * MOVE_SPEED
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		elif velocity.y > 0.0:
			velocity.y = 0.0

	move_and_slide()
	position.x = clampf(position.x, 65.0, 1855.0)
	var grounded: bool = is_on_floor()
	var landed: bool = grounded and not was_on_floor and has_touched_floor
	if grounded:
		has_touched_floor = true

	if aim_request != &"":
		if turning:
			visual_facing = turn_target
			turning = false
		if aim_side != aim_request or aim_lowering:
			transition = &""
			aim_side = aim_request
			aim_lowering = false
			aim_angle_degrees = 0.0
			aim_angle_velocity = 0.0
			current_beam_length = DEFAULT_BEAM_LENGTH
			sprite.play(_faced_clip(aim_side))
			if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif aim_side != &"":
		if not aim_lowering:
			aim_lowering = true
			_clear_locked_target(true)
			sprite.play_backwards(_faced_clip(aim_side))
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			sprite.play_backwards(_faced_clip(aim_side))
	elif not turning and direction != 0 and direction != visual_facing:
		turning = true
		transition = &""
		turn_target = direction
		sprite.play(&"turn_to_left" if direction < 0 else &"turn_to_right")

	if not turning and aim_side == &"":
		if dash_left > 0.0:
			transition = &""
			if sprite.animation != _faced_clip(&"dash"):
				sprite.play(_faced_clip(&"dash"))
		elif not grounded:
			transition = &""
			if sprite.animation != _faced_clip(&"jump"):
				sprite.play(_faced_clip(&"jump"))
		else:
			if landed:
				transition = &"land"
				sprite.play(_faced_clip(transition))
			elif direction != 0 and previous_direction == 0:
				transition = &"move_start"
				sprite.play(_faced_clip(transition))
			elif direction == 0 and previous_direction != 0:
				transition = &"move_stop"
				sprite.play(_faced_clip(transition))
			if transition == &"":
				var state: StringName = &"move" if direction != 0 else &"idle"
				state = _faced_clip(state)
				if sprite.animation != state or not sprite.is_playing():
					sprite.play(state)

	if aim_request != &"" and aim_side != &"":
		var base_clip: StringName = _faced_clip(aim_side)
		var angle_clip: StringName = _aim_angle_clip()
		if sprite.animation != base_clip or sprite.frame >= 10:
			if sprite.animation != angle_clip:
				var sample: int = clampi(roundi(aim_angle_degrees / 2.0) * 2, -40, 40)
				if sample == 0:
					sprite.play(base_clip)
					sprite.set_frame_and_progress(11, 0.0)
				else:
					sprite.play(angle_clip)
	_update_beam(aim_request)

	jump_was_down = jump_down
	dash_was_down = dash_down
	previous_direction = direction
	was_on_floor = grounded
