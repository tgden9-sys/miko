extends Node2D

enum State { FORWARD, SCAN, TURN_OUT, RETURN, TURN_HOME, RESUME_SIDE, FACE_FRONT, ALERT, AIM, FIRE, COOLDOWN }

@export var patrol_distance := 310.0
@export var patrol_speed := 85.0
@export var detection_range := 430.0
@export var shot_speed := 700.0

const ART_SCALE := 0.21
const LEFT_PIVOT := Vector2(-210, -50) * ART_SCALE
const RIGHT_PIVOT := Vector2(210, -50) * ART_SCALE
const LEFT_MUZZLE := Vector2(-210, 85) * ART_SCALE
const RIGHT_MUZZLE := Vector2(210, 85) * ART_SCALE
const BULLET := preload("res://scenes/security_drone_bolt.tscn")
const BODY_IDLE := preload("res://sprites/security_drone/body_idle.png")
const BODY_ALERT := preload("res://sprites/security_drone/body_alert.png")

var state := State.FORWARD
var state_time := 0.0
var home_x := 0.0
var player: Node2D
var turn_frames: Array[Texture2D] = []
var shots_fired := 0
var hover_time := 0.0
var facing_right_before_alert := true
var resuming_right := true

@onready var art: Node2D = $Art
@onready var body: Sprite2D = $Art/Body
@onready var left_gun: Node2D = $Art/LeftGun
@onready var right_gun: Node2D = $Art/RightGun
@onready var turn_sprite: Sprite2D = $Art/TurnSprite
@onready var patrol_right: Sprite2D = $Art/PatrolRight
@onready var patrol_left: Sprite2D = $Art/PatrolLeft
@onready var thruster_socket: Node2D = $Art/ThrusterSocket
@onready var thruster: ColorRect = $Art/ThrusterSocket/Thruster

func _ready() -> void:
	home_x = global_position.x
	player = get_parent().get_node_or_null("Robot") as Node2D
	left_gun.position = LEFT_PIVOT
	right_gun.position = RIGHT_PIVOT
	$Art/LeftGun/Sprite.position = -LEFT_PIVOT
	$Art/RightGun/Sprite.position = -RIGHT_PIVOT
	for i in range(10):
		turn_frames.append(load("res://sprites/security_drone/turn_%02d.png" % i))
	_set_state(State.FORWARD)

func _physics_process(delta: float) -> void:
	state_time += delta
	hover_time += delta
	art.position.y = sin(hover_time * 3.1) * 2.5
	thruster.modulate.a = 0.7 + sin(hover_time * 12.0) * 0.12
	if _can_see_player() and state < State.FACE_FRONT:
		facing_right_before_alert = state == State.RETURN or (state == State.RESUME_SIDE and resuming_right) or (state == State.TURN_OUT and state_time >= 0.375) or (state == State.TURN_HOME and state_time < 0.375)
		_set_state(State.FACE_FRONT)
	match state:
		State.FORWARD:
			position.x = maxf(home_x - patrol_distance, position.x - patrol_speed * delta)
			if position.x <= home_x - patrol_distance + 0.5:
				_set_state(State.SCAN)
		State.SCAN:
			_update_turn()
			if state_time >= 1.25:
				_set_state(State.TURN_OUT)
		State.TURN_OUT:
			_update_turn()
			if state_time >= 0.75:
				_set_state(State.RETURN)
		State.RETURN:
			position.x = minf(home_x, position.x + patrol_speed * delta)
			if position.x >= home_x - 0.5:
				_set_state(State.TURN_HOME)
		State.TURN_HOME:
			_update_turn()
			if state_time >= 0.75:
				_set_state(State.FORWARD)
		State.FACE_FRONT:
			_update_turn()
			if state_time >= 0.38:
				_set_state(State.ALERT)
		State.RESUME_SIDE:
			_update_turn()
			if state_time >= 0.38:
				_set_state(State.FORWARD if resuming_right else State.RETURN)
		State.ALERT:
			if not _can_see_player():
				_resume_patrol()
			elif state_time >= 0.48:
				_set_state(State.AIM)
		State.AIM:
			if not _can_see_player():
				_resume_patrol()
			else:
				_aim_guns(delta)
			if state == State.AIM and state_time >= 0.58:
				_set_state(State.FIRE)
		State.FIRE:
			if not _can_see_player():
				_resume_patrol()
				_update_thruster_socket()
				return
			_aim_guns(delta)
			if shots_fired == 0:
				_fire(left_gun, LEFT_PIVOT, LEFT_MUZZLE)
				shots_fired = 1
			if shots_fired == 1 and state_time >= 0.14:
				_fire(right_gun, RIGHT_PIVOT, RIGHT_MUZZLE)
				shots_fired = 2
			if state_time >= 0.30:
				_set_state(State.COOLDOWN)
		State.COOLDOWN:
			_aim_guns(delta)
			if not _can_see_player():
				_resume_patrol()
			elif state_time >= 1.2:
				_set_state(State.AIM)
	_update_thruster_socket()

func _can_see_player() -> bool:
	if not is_instance_valid(player) or global_position.distance_to(player.global_position) > detection_range:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == player

func _resume_patrol() -> void:
	resuming_right = position.x < home_x - 10.0
	_set_state(State.RESUME_SIDE)

func _set_state(next: State) -> void:
	state = next
	state_time = 0.0
	shots_fired = 0
	var alerted := state >= State.ALERT
	body.texture = BODY_ALERT if alerted else BODY_IDLE
	turn_sprite.visible = state == State.SCAN or state == State.TURN_OUT or state == State.TURN_HOME or state == State.FACE_FRONT or state == State.RESUME_SIDE
	patrol_left.visible = state == State.FORWARD
	patrol_right.visible = state == State.RETURN
	body.visible = state >= State.ALERT
	left_gun.visible = body.visible
	right_gun.visible = body.visible
	if state == State.FORWARD or state == State.RETURN:
		left_gun.rotation = 0.0
		right_gun.rotation = 0.0
	if state == State.ALERT:
		left_gun.rotation = 0.0
		right_gun.rotation = 0.0
	if turn_sprite.visible:
		_update_turn()
	_update_thruster_socket()

func _update_turn() -> void:
	var frame := mini(9, int(state_time / 0.75 * 10.0))
	if state == State.TURN_OUT:
		frame = 9 - frame
	elif state == State.SCAN:
		frame = 9 - mini(2, int((1.0 - absf(2.0 * state_time / 1.25 - 1.0)) * 3.0))
	elif state == State.FACE_FRONT:
		var fraction := clampf(state_time / 0.38, 0.0, 1.0)
		frame = mini(4, int(fraction * 5.0)) if facing_right_before_alert else maxi(5, 9 - int(fraction * 5.0))
	elif state == State.RESUME_SIDE:
		var fraction := clampf(state_time / 0.38, 0.0, 1.0)
		frame = maxi(0, 4 - int(fraction * 5.0)) if resuming_right else mini(9, 5 + int(fraction * 5.0))
	turn_sprite.texture = turn_frames[frame]

func _update_thruster_socket() -> void:
	# The plume begins at the visible nozzle in each rendered view.
	var side_amount := 0.0
	if patrol_right.visible:
		side_amount = 1.0
	elif patrol_left.visible:
		side_amount = -1.0
	elif turn_sprite.visible:
		var frame := turn_frames.find(turn_sprite.texture)
		side_amount = 1.0 - 2.0 * clampf(float(frame) / 9.0, 0.0, 1.0)
	thruster_socket.position = Vector2(-5.0 * side_amount, 36.0)
	thruster_socket.rotation = side_amount * 0.25

func _aim_guns(delta: float) -> void:
	if not is_instance_valid(player):
		return
	for pair in [[left_gun, LEFT_MUZZLE], [right_gun, RIGHT_MUZZLE]]:
		var gun: Node2D = pair[0]
		var muzzle: Vector2 = pair[1]
		var desired := Vector2.DOWN.angle_to((player.global_position - (global_position + muzzle)).normalized())
		gun.rotation = move_toward(gun.rotation, clampf(desired, -0.9, 0.9), delta * 2.4)

func _fire(gun: Node2D, pivot: Vector2, muzzle: Vector2) -> void:
	if not is_instance_valid(player):
		return
	var bolt := BULLET.instantiate() as Area2D
	get_parent().add_child(bolt)
	bolt.global_position = global_position + art.position + pivot + (muzzle - pivot).rotated(gun.rotation)
	bolt.direction = (player.global_position - bolt.global_position).normalized()
	bolt.speed = shot_speed
	gun.rotation += -0.10 if gun == left_gun else 0.10
