extends "res://scripts/miko7_gate_warden_patrol.gd"
## Level 4 only: original model, health, pose, hit and death effects.
## Advance between telegraphed bursts; respect walls and each roof edge.
@export var patrol_left := 0.0
@export var patrol_right := 0.0
var stagger_time := 0.0
var retreat_time := 0.0
var retreat_cooldown := 0.0
var home := Vector3.ZERO
var shots_fired := 0
var engaged := false
var recovery_time := 0.0
var burst_direction := 1
const ENGAGE_REACH := 12.0
const ANSWER_REACH := 28.0
const ADVANCE_SPEED := 1.55

func _ready() -> void:
	home = position
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = .18
	add_to_group("level4_wardens")
	super._ready()
	ring.hide()

func reset_patrol() -> void:
	stagger_time = 0.0
	retreat_time = 0.0
	retreat_cooldown = 0.0
	position = home
	velocity = Vector3.ZERO
	engaged = false
	recovery_time = 0.0
	shots_fired = 0
	super.reset_patrol()
	ring.hide()

func restore_defeated() -> void:
	health = 0
	state = State.DOWN
	death_fade = 1.0
	hitbox.set_deferred("disabled", true)
	ring.hide()
	hide()

func _physics_process(delta: float) -> void:
	if state == State.DOWN: return
	if not _resolve_player(): return
	if _is_resetting() or not player.ready_for_input or player.health <= 0: return
	recoil = move_toward(recoil, 0.0, delta * 5.0)
	return_fire_time = maxf(0.0, return_fire_time - delta)
	var sees := _sees_player(ANSWER_REACH if return_fire_time > 0.0 else ENGAGE_REACH)
	if sees:
		alert_memory = 3.0
		engaged = true
	else:
		alert_memory = maxf(0.0, alert_memory - delta)
	if alert_memory <= 0.0 and shots_left == 0: engaged = false
	velocity.x = 0.0
	retreat_cooldown = maxf(0.0, retreat_cooldown - delta)
	if stagger_time > 0.0:
		stagger_time = maxf(0.0, stagger_time - delta)
		aim_weight = 0.0
		model.rotation.z = sin(stagger_time * 20.0) * .08
		return
	model.rotation.z = 0.0
	var distance := absf(player.position.x - position.x)
	if engaged and shots_left == 0 and distance < 2.8 and distance > 1.5 and retreat_cooldown <= 0.0:
		retreat_time = .3
		retreat_cooldown = 3.2
	if retreat_time > 0.0:
		retreat_time = maxf(0.0, retreat_time - delta)
		_face_player()
		velocity.x = -direction * 2.0
		if not _safe_step(velocity.x, delta): velocity.x = 0.0
		animation.play(WALK, .1)
		animation.speed_scale = -1.5
	elif shots_left > 0:
		state = State.ALERT
		model.rotation.y = lerp_angle(model.rotation.y, burst_direction * PI * .5, 1.0 - exp(-14.0 * delta))
		aim_weight = move_toward(aim_weight, 1.0, delta * 4.0)
		shot_time -= delta
		if shot_time <= 0.0:
			_fire()
			shots_left -= 1
			shot_time = .42
			if shots_left == 0: recovery_time = 1.5
	else:
		aim_weight = move_toward(aim_weight, 0.0, delta * 4.0)
		recovery_time = maxf(0.0, recovery_time - delta)
		if engaged:
			_face_player()
			if sees and recovery_time <= 0.0:
				_begin_burst()
			elif absf(player.position.x - position.x) > 3.4:
				velocity.x = direction * ADVANCE_SPEED
		else:
			state = State.WALK
			if position.x <= patrol_left + .46: direction = 1
			if position.x >= patrol_right - .46: direction = -1
			velocity.x = direction * walk_speed
			model.rotation.y = lerp_angle(model.rotation.y, direction * PI * .5, 1.0 - exp(-10.0 * delta))
		if not _safe_step(velocity.x, delta): velocity.x = 0.0
		var moving := absf(velocity.x) > .01
		var clip := WALK if moving else IDLE
		if animation.current_animation != clip: animation.play(clip, .14)
		animation.speed_scale = absf(velocity.x) / walk_speed if moving else 1.0
	velocity.y = -0.1 if is_on_floor() else velocity.y - 14.0 * delta
	move_and_slide()
	position.z = home.z

func _face_player() -> void:
	if absf(player.position.x - position.x) > .1:
		direction = 1 if player.position.x > position.x else -1
	model.rotation.y = lerp_angle(model.rotation.y, direction * PI * .5, .32)

func _safe_step(speed: float, delta: float) -> bool:
	if absf(speed) < .01: return true
	var ahead := position.x + signf(speed) * (.42 + absf(speed) * delta)
	if ahead < patrol_left or ahead > patrol_right: return false
	var query := PhysicsRayQueryParameters3D.create(Vector3(ahead, position.y + .35, home.z), Vector3(ahead, position.y - .35, home.z), 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.normal.y > .7

func _sees_player(reach: float) -> bool:
	if not _resolve_player() or not player.ready_for_input or player.health <= 0 or _is_resetting(): return false
	if player.state.begins_with("Climb"): return false
	var center := global_position + Vector3.UP * 1.36
	var target := _player_aim_point()
	if center.distance_squared_to(target) > reach * reach: return false
	var query := PhysicsRayQueryParameters3D.create(center, target, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == player

func _begin_burst() -> void:
	# A player bolt may arrive before the first camera-enabled physics tick.
	if not _resolve_player(): return
	_face_player()
	burst_direction = direction
	aim_target = _player_aim_point()
	shots_left = 2
	shot_time = .90
	state = State.ALERT
	animation.speed_scale = 1.0
	animation.play(IDLE, .12)

func _fire() -> void:
	# Commit to the telegraphed point: moving or jumping beats this burst.
	# Check muzzle clearance too, so freight and walls stop fire.
	if not _sees_player(ANSWER_REACH): return
	if (aim_target.x - muzzle_position.x) * burst_direction < .15: return
	var query := PhysicsRayQueryParameters3D.create(muzzle_position, aim_target, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider != player: return
	super._fire()
	shots_fired += 1

func receive_combat_bolt() -> void:
	if state == State.DOWN or _is_resetting(): return
	super.receive_combat_bolt()
	if health > 0:
		engaged = true
		return_fire_time = 5.0
		alert_memory = 3.0
		# Repeated hits cannot restart the wind-up and stun-lock the Warden.
		if shots_left == 0 and recovery_time <= 0.0: _begin_burst()

func receive_sword_hit(damage: int, _attack_direction: int) -> void:
	if state == State.DOWN or _is_resetting(): return
	# Reuse the established death path with exact sword damage.
	health = maxi(1, health - damage + BOLT_DAMAGE)
	super.receive_combat_bolt()
	if health > 0:
		engaged = true
		alert_memory = 3.0
		shots_left = 0
		retreat_time = 0.0
		stagger_time = .23
		recovery_time = .28
		animation.play(IDLE, .05)
		animation.speed_scale = 1.0
