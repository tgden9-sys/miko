extends Camera2D

@export var target: Node2D
@export var lookahead_distance: float = 140.0
@export var lookahead_speed: float = 3.5
@export var follow_smoothness: float = 6.0
@export var vertical_offset: float = -40.0

var current_lookahead: float = 0.0
var impulse_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	make_current()
	position_smoothing_enabled = false
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS

func add_impulse(offset: Vector2) -> void:
	impulse_offset += offset

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		return
	
	# Determine target facing/velocity direction for lookahead
	var move_dir: float = 0.0
	if "visual_facing" in target:
		move_dir = float(target.visual_facing)
	
	var vx: float = target.velocity.x if "velocity" in target else 0.0
	var speed_ratio: float = clampf(absf(vx) / 300.0, 0.0, 1.0)
	
	# Only apply full lookahead when moving or aiming; keep steady when idle
	var is_aiming: bool = target.get("aim_side") != &"" if "aim_side" in target else false
	var effective_weight: float = 1.0 if is_aiming else maxf(0.2, speed_ratio)
	var desired_lookahead: float = move_dir * lookahead_distance * effective_weight
	
	current_lookahead = lerpf(current_lookahead, desired_lookahead, 1.0 - exp(-lookahead_speed * delta))
	
	# Decay camera impulse smoothly
	impulse_offset = impulse_offset.lerp(Vector2.ZERO, 1.0 - exp(-16.0 * delta))
	
	var desired_pos: Vector2 = target.global_position + Vector2(current_lookahead, vertical_offset) + impulse_offset
	
	# Delta-independent exponential smoothing
	global_position.x = lerpf(global_position.x, desired_pos.x, 1.0 - exp(-follow_smoothness * delta))
	global_position.y = lerpf(global_position.y, desired_pos.y, 1.0 - exp(-follow_smoothness * 0.4 * delta))
