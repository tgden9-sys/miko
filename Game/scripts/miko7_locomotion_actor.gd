extends CharacterBody3D

signal mode_changed(mode: String)

const MODEL := "res://models/miko7/review_v6/MIKO7_Locomotion_v6.glb"
const DATA := "res://models/miko7/review_v6/MIKO7_Locomotion_v6.json"
const WALK_SPEED := 0.72
const SPRINT_SPEED := 2.20
const GRAVITY := 9.0
const JUMP_VELOCITY := 3.5
const JUMP_PREPARE_TIME := 0.14
const TAKEOFF_DELAY := 0.09
const JUMP_ENTRY_TIME := 0.14
const JUMP_ENTRY_SOURCE_TIME := 0.12
const JUMP_START_RATE := 2.2
const LAND_RATE := 2.4
const TURN_RATE := 1.8

var visual: Node3D
var animation_player: AnimationPlayer
var metadata: Dictionary
var clips: Dictionary = {}
var state := "Locomotion"
var state_time := 0.0
var current_clip := ""
var facing := 1
var target_facing := 1
var turn_mode := "Auto"
var stick := 0.0
var jump_buffer := 0.0
var coyote := 0.0
var launched := false
var ready_for_input := false
var walk_only := false
var turn_queue: Array[String] = []
var turn_start_yaw := 0.0
var turn_last_motion := Vector3.ZERO
var last_turn_clip := ""
var transition_log: Array[String] = []
var pose_skeleton: Skeleton3D
var pose_nodes: Array[Node3D] = []
var jump_pose_from: Dictionary = {}
var jump_pose_to: Dictionary = {}

func _ready() -> void:
	_install_input()
	floor_snap_length = 0.09
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.13
	shape.height = 0.90
	collision.shape = shape
	collision.position.y = 0.45
	add_child(collision)
	metadata = JSON.parse_string(FileAccess.get_file_as_string(DATA)) as Dictionary
	visual = Node3D.new()
	visual.name = "Facing"
	add_child(visual)
	var model := (load(MODEL) as PackedScene).instantiate() as Node3D
	visual.add_child(model)
	pose_skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	pose_nodes.append(model)
	for node: Node in model.find_children("*", "Node3D", true, false):
		pose_nodes.append(node as Node3D)
	animation_player = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for label: String in metadata["clips"]:
		for name: StringName in animation_player.get_animation_list():
			if String(name) == "MIKO7_" + label:
				clips[label] = name
				var animation := animation_player.get_animation(name)
				animation.length = float(metadata["clips"][label]["duration"])
				animation.loop_mode = Animation.LOOP_LINEAR if bool(metadata["clips"][label]["loop"]) else Animation.LOOP_NONE
	assert(clips.size() == 10, "Expected all ten locomotion and turn clips")
	visual.rotation.y = PI * 0.5
	_play("Idle", 0.0)
	ready_for_input = true
	print("MIKO7_ACTOR_READY clips=", clips.keys())

func _install_input() -> void:
	for action: String in ["miko7_left", "miko7_right", "miko7_jump"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.18)
	for direction in [-1, 1]:
		var event := InputEventJoypadMotion.new()
		event.device = -1
		event.axis = JOY_AXIS_LEFT_X
		event.axis_value = float(direction)
		InputMap.action_add_event("miko7_left" if direction < 0 else "miko7_right", event)
	var jump := InputEventJoypadButton.new()
	jump.device = -1
	jump.button_index = JOY_BUTTON_B
	InputMap.action_add_event("miko7_jump", jump)
	for keycode in [KEY_SPACE, KEY_B]:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event("miko7_jump", event)

func _input_axis() -> float:
	var axis := Input.get_axis("miko7_left", "miko7_right")
	var keyboard := int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	if keyboard != 0:
		axis = float(keyboard) * (1.0 if walk_only or Input.is_physical_key_pressed(KEY_SHIFT) else 0.55)
	return axis

func _set_state(value: String) -> void:
	state = value
	state_time = 0.0
	transition_log.append(value)
	mode_changed.emit(value)

func _play(label: String, blend := 0.12, rate := 1.0) -> void:
	if current_clip != label:
		current_clip = label
		animation_player.play(clips[label], blend)
		animation_player.advance(0.0)
	animation_player.speed_scale = rate

func _physics_process(delta: float) -> void:
	if not ready_for_input:
		return
	stick = _input_axis()
	state_time += delta
	jump_buffer = maxf(0.0, jump_buffer - delta)
	coyote = 0.10 if is_on_floor() else maxf(0.0, coyote - delta)
	if Input.is_action_just_pressed("miko7_jump"):
		jump_buffer = 0.15
	if jump_buffer > 0.0 and coyote > 0.0 and state in ["Locomotion", "Brake", "Turn", "Land"]:
		if state != "Land" or state_time > 0.18:
			_begin_jump()
	var was_floor := is_on_floor()
	if not was_floor:
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	match state:
		"Locomotion": _locomotion(delta)
		"Brake":
			velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
			if not walk_only and absf(velocity.x) > WALK_SPEED:
				_play("Sprint", 0.10, clampf(absf(velocity.x) / SPRINT_SPEED, 0.05, 1.15))
			else:
				_play("Walk", 0.10, clampf(absf(velocity.x) / WALK_SPEED, 0.05, 1.3))
			if absf(velocity.x) < 0.04:
				_begin_turn(target_facing)
		"Turn": velocity.x = 0.0
		"JumpPrepare":
			_air_steer(delta)
			var blend := clampf(state_time / JUMP_PREPARE_TIME, 0.0, 1.0)
			_apply_pose_blend(jump_pose_from, jump_pose_to, blend * blend * (3.0 - 2.0 * blend))
			if state_time >= JUMP_PREPARE_TIME:
				_set_state("JumpStart")
				current_clip = ""
				_play("JumpStart", 0.0, JUMP_START_RATE)
		"JumpStart":
			_air_steer(delta)
			animation_player.seek(minf(_jump_start_time(state_time), _duration("JumpStart")), true)
			if not launched and state_time >= TAKEOFF_DELAY:
				velocity.y = JUMP_VELOCITY
				launched = true
				floor_snap_length = 0.0
			if _jump_start_time(state_time) >= _duration("JumpStart"):
				_set_state("Air")
				_play("JumpAir", 0.10)
		"Air": _air_steer(delta)
		"Land":
			velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
			if state_time >= _duration("JumpLand") / LAND_RATE:
				_set_state("Locomotion")
	if state not in ["JumpPrepare", "JumpStart"]:
		animation_player.advance(delta)
	if state == "Turn":
		_update_turn()
	else:
		var desired_yaw := PI * 0.5 if facing > 0 else -PI * 0.5
		visual.rotation.y = lerp_angle(visual.rotation.y, desired_yaw, minf(1.0, delta * 14.0))
	move_and_slide()
	position.z = 0.0
	if state in ["JumpStart", "Air"] and launched and not was_floor and is_on_floor():
		land()
	elif state == "Locomotion" and not is_on_floor() and coyote <= 0.0:
		launched = true
		_set_state("Air")
		_play("JumpAir", 0.12)
	if position.y < -4.0:
		reset_actor()

func _desired_speed(value: float) -> float:
	var amount := absf(value)
	if amount < 0.06:
		return 0.0
	if walk_only:
		return signf(value) * lerpf(0.12, WALK_SPEED, amount)
	if amount < 0.78:
		return signf(value) * lerpf(0.12, WALK_SPEED, clampf(amount / 0.78, 0, 1))
	return signf(value) * lerpf(WALK_SPEED, SPRINT_SPEED, (amount - 0.78) / 0.22)

func _locomotion(delta: float) -> void:
	if absf(stick) > 0.10 and int(signf(stick)) != facing and is_on_floor():
		target_facing = int(signf(stick))
		_set_state("Brake")
		return
	var desired := _desired_speed(stick)
	velocity.x = move_toward(velocity.x, desired, 4.0 * delta)
	if absf(velocity.x) < 0.025:
		_play("Idle", 0.16)
	elif not walk_only and (absf(velocity.x) > WALK_SPEED * 1.15 or (current_clip == "Sprint" and absf(velocity.x) > WALK_SPEED * 1.02)):
		_play("Sprint", 0.14, clampf(absf(velocity.x) / SPRINT_SPEED, 0.05, 1.15))
	else:
		_play("Walk", 0.14, clampf(absf(velocity.x) / WALK_SPEED, 0.05, 1.3))

func _air_steer(delta: float) -> void:
	velocity.x = move_toward(velocity.x, _desired_speed(stick), 2.2 * delta)
	if absf(stick) > 0.15:
		facing = int(signf(stick))

func _begin_jump() -> void:
	jump_buffer = 0.0
	coyote = 0.0
	launched = false
	turn_queue.clear()
	if state == "Turn":
		facing = target_facing
	# Start from the actual visible pose, including its current walk phase.
	# Hold the take-off clip's first pose while we build an eased preparation.
	jump_pose_from = _capture_pose()
	animation_player.play(clips["JumpStart"], 0.0)
	animation_player.seek(0.0, true)
	animation_player.advance(0.0)
	jump_pose_to = _capture_pose()
	animation_player.stop(true)
	_apply_pose_blend(jump_pose_from, jump_pose_to, 0.0)
	current_clip = "JumpPrepare"
	_set_state("JumpPrepare")

func _capture_pose() -> Dictionary:
	var nodes: Array[Transform3D] = []
	for node: Node3D in pose_nodes:
		nodes.append(node.transform)
	var positions: Array[Vector3] = []
	var rotations: Array[Quaternion] = []
	var scales: Array[Vector3] = []
	for i in range(pose_skeleton.get_bone_count()):
		positions.append(pose_skeleton.get_bone_pose_position(i))
		rotations.append(pose_skeleton.get_bone_pose_rotation(i))
		scales.append(pose_skeleton.get_bone_pose_scale(i))
	var feet: Array[Transform3D] = []
	for side: String in ["L", "R"]:
		var index := pose_skeleton.find_bone("DEF-foot." + side)
		feet.append(visual.global_transform.affine_inverse() * pose_skeleton.global_transform * pose_skeleton.get_bone_global_pose(index))
	return {"nodes": nodes, "positions": positions, "rotations": rotations, "scales": scales, "feet": feet}

func _apply_pose_blend(from_pose: Dictionary, to_pose: Dictionary, weight: float) -> void:
	for i in range(pose_nodes.size()):
		var first: Transform3D = from_pose["nodes"][i]
		pose_nodes[i].transform = first.interpolate_with(to_pose["nodes"][i], weight)
	for i in range(pose_skeleton.get_bone_count()):
		var p: Vector3 = from_pose["positions"][i]
		var q: Quaternion = from_pose["rotations"][i]
		var s: Vector3 = from_pose["scales"][i]
		pose_skeleton.set_bone_pose_position(i, p.lerp(to_pose["positions"][i], weight))
		pose_skeleton.set_bone_pose_rotation(i, q.slerp(to_pose["rotations"][i], weight))
		pose_skeleton.set_bone_pose_scale(i, s.lerp(to_pose["scales"][i], weight))
	for side_index in range(2):
		var first: Transform3D = from_pose["feet"][side_index]
		var foot_in_visual := first.interpolate_with(to_pose["feet"][side_index], weight)
		var foot_in_skeleton := pose_skeleton.global_transform.affine_inverse() * visual.global_transform * foot_in_visual
		_solve_prepare_leg("L" if side_index == 0 else "R", foot_in_skeleton)

func _set_bone_global_pose(index: int, desired: Transform3D) -> void:
	var parent := pose_skeleton.get_bone_parent(index)
	var local := desired
	if parent >= 0:
		local = pose_skeleton.get_bone_global_pose(parent).affine_inverse() * desired
	pose_skeleton.set_bone_pose_position(index, local.origin)
	pose_skeleton.set_bone_pose_rotation(index, local.basis.orthonormalized().get_rotation_quaternion())
	pose_skeleton.set_bone_pose_scale(index, local.basis.get_scale())

func _solve_prepare_leg(side: String, foot: Transform3D) -> void:
	var thigh := pose_skeleton.find_bone("DEF-thigh." + side)
	var shin := pose_skeleton.find_bone("DEF-shin." + side)
	var ankle := pose_skeleton.find_bone("DEF-foot." + side)
	var upper := pose_skeleton.get_bone_global_pose(thigh)
	var lower := pose_skeleton.get_bone_global_pose(shin)
	var old_foot := pose_skeleton.get_bone_global_pose(ankle)
	var hip := upper.origin
	var first_length := pose_skeleton.get_bone_rest(shin).origin.length()
	var second_length := pose_skeleton.get_bone_rest(ankle).origin.length()
	var distance := clampf(hip.distance_to(foot.origin), 0.001, first_length + second_length - 0.00001)
	var axis := (foot.origin - hip).normalized()
	var pole := lower.origin - hip
	pole -= axis * pole.dot(axis)
	if pole.length() < 0.0001:
		pole = Vector3.FORWARD - axis * Vector3.FORWARD.dot(axis)
	pole = pole.normalized()
	var along := (first_length * first_length - second_length * second_length + distance * distance) / (2.0 * distance)
	var height := sqrt(maxf(0.0, first_length * first_length - along * along))
	var knee := hip + axis * along + pole * height
	var upper_rotation := Quaternion((lower.origin - hip).normalized(), (knee - hip).normalized())
	var lower_rotation := Quaternion((old_foot.origin - lower.origin).normalized(), (foot.origin - knee).normalized())
	_set_bone_global_pose(thigh, Transform3D(Basis(upper_rotation) * upper.basis, hip))
	_set_bone_global_pose(shin, Transform3D(Basis(lower_rotation) * lower.basis, knee))
	_set_bone_global_pose(ankle, foot)

func _jump_start_time(time: float) -> float:
	if time >= JUMP_ENTRY_TIME:
		return JUMP_ENTRY_SOURCE_TIME + (time - JUMP_ENTRY_TIME) * JUMP_START_RATE
	var t := clampf(time / JUMP_ENTRY_TIME, 0.0, 1.0)
	# Monotonic Hermite timing: ease from rest, then join the clip at its normal rate.
	return (-2.0 * t * t * t + 3.0 * t * t) * JUMP_ENTRY_SOURCE_TIME + (t * t * t - t * t) * JUMP_START_RATE * JUMP_ENTRY_TIME

func land() -> void:
	floor_snap_length = 0.09
	velocity.y = 0.0
	launched = false
	_set_state("Land")
	_play("JumpLand", 0.07, LAND_RATE)

func _begin_turn(direction: int) -> void:
	target_facing = direction
	turn_queue.clear()
	var label := "Turn180Right" if facing > 0 else "Turn180Left"
	match turn_mode:
		"180 Left": label = "Turn180Left"
		"180 Right": label = "Turn180Right"
		"90 Left x2": label = "Turn90Left"
		"90 Right x2": label = "Turn90Right"
	turn_queue.append(label)
	if label.begins_with("Turn90"):
		turn_queue.append(label)
	_set_state("Turn")
	_start_turn_segment()

func _start_turn_segment() -> void:
	var label := turn_queue.pop_front() as String
	turn_start_yaw = visual.rotation.y
	turn_last_motion = Vector3.ZERO
	last_turn_clip = label
	current_clip = ""
	_play(label, 0.10, TURN_RATE)

func _sample_track(values: Array, time: float) -> Variant:
	var frame := clampf(time * 30.0, 0.0, float(values.size() - 1))
	var index := int(floor(frame))
	var next := mini(index + 1, values.size() - 1)
	var fraction := frame - float(index)
	if values[index] is Array:
		var a := Vector3(float(values[index][0]), float(values[index][1]), float(values[index][2]))
		var b := Vector3(float(values[next][0]), float(values[next][1]), float(values[next][2]))
		return a.lerp(b, fraction)
	return lerpf(float(values[index]), float(values[next]), fraction)

func _update_turn() -> void:
	var data: Dictionary = metadata["clips"][current_clip]
	var time := animation_player.current_animation_position
	visual.rotation.y = turn_start_yaw + float(_sample_track(data["yaw"], time))
	var motion: Vector3 = _sample_track(data["root_motion"], time)
	var offset := (motion - turn_last_motion).rotated(Vector3.UP, turn_start_yaw)
	# Apply root travel through collision-aware movement, once, on the side-scrolling axis.
	move_and_collide(Vector3(offset.x, 0, 0))
	turn_last_motion = motion
	if time >= float(data["duration"]) - 0.001:
		if not turn_queue.is_empty():
			_start_turn_segment()
		else:
			facing = target_facing
			visual.rotation.y = PI * 0.5 if facing > 0 else -PI * 0.5
			_set_state("Locomotion")
			_play("Idle", 0.12)

func _duration(label: String) -> float:
	return float(metadata["clips"][label]["duration"])

func reset_actor() -> void:
	global_position = Vector3.ZERO
	velocity = Vector3.ZERO
	facing = 1
	target_facing = 1
	visual.rotation.y = PI * 0.5
	turn_queue.clear()
	jump_buffer = 0.0
	launched = false
	floor_snap_length = 0.09
	_set_state("Locomotion")
	animation_player.stop()
	current_clip = ""
	_play("Idle", 0.0)
