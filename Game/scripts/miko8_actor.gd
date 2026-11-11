extends CharacterBody3D

const MODEL := "res://models/miko8/MIKO8_Native.glb"
var model_path:String=MODEL
const DATA := "res://models/miko8/MIKO8_Native.json"
const GRAVITY := 14.0
const MAX_HEALTH := 100
var health := MAX_HEALTH
const JUMP_VELOCITY := 6.0
const JUMP_GATHER_TIME := 0.10
const JUMP_TAKEOFF_TIME := 1.0 / 30.0
const JUMP_START_EXIT := 0.32
const STOP_DECELERATION := 38.0
const STOP_TIME := 0.25
const TURN_TIME_180 := 0.20
const TURN_TIME_90 := 0.12
const SPRINT_STICK_THRESHOLD := 0.78
const AIR_MAX_SPEED := 3.0
const AIR_ACCELERATION := 24.0
const AIR_BRAKING := 28.0
const AIR_TURN_SPEED := 20.0
var visual: Node3D
var model: Node3D
var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var metadata: Dictionary
var clips: Dictionary = {}
enum State {
	LOCOMOTION,
	MOVE_START,
	GROUND_STOP,
	WALL_BLOCKED,
	SPRINT_ENTER,
	SPRINT_EXIT,
	BRAKE,
	TURN,
	JUMP_GATHER,
	JUMP_START,
	AIR,
	LAND,
	CUSTOM,
}

const STATE_NAMES: Array[String] = [
	"Locomotion",
	"MoveStart",
	"GroundStop",
	"WallBlocked",
	"SprintEnter",
	"SprintExit",
	"Brake",
	"Turn",
	"JumpGather",
	"JumpStart",
	"Air",
	"Land",
	"",
]

const NAME_TO_STATE: Dictionary = {
	"Locomotion": State.LOCOMOTION,
	"MoveStart": State.MOVE_START,
	"GroundStop": State.GROUND_STOP,
	"WallBlocked": State.WALL_BLOCKED,
	"SprintEnter": State.SPRINT_ENTER,
	"SprintExit": State.SPRINT_EXIT,
	"Brake": State.BRAKE,
	"Turn": State.TURN,
	"JumpGather": State.JUMP_GATHER,
	"JumpStart": State.JUMP_START,
	"Air": State.AIR,
	"Land": State.LAND,
}

const MASK_JUMP_ALLOWED: int = (
	(1 << State.LOCOMOTION) |
	(1 << State.SPRINT_ENTER) |
	(1 << State.SPRINT_EXIT) |
	(1 << State.TURN) |
	(1 << State.BRAKE) |
	(1 << State.WALL_BLOCKED) |
	(1 << State.GROUND_STOP) |
	(1 << State.MOVE_START)
)

const MASK_GROUNDED_LOCO: int = (
	(1 << State.LOCOMOTION) |
	(1 << State.SPRINT_ENTER) |
	(1 << State.SPRINT_EXIT) |
	(1 << State.BRAKE) |
	(1 << State.TURN)
)

const MASK_IN_AIR: int = (
	(1 << State.JUMP_GATHER) |
	(1 << State.JUMP_START) |
	(1 << State.AIR) |
	(1 << State.LAND)
)

const MASK_WALL_CHECK: int = (
	(1 << State.LOCOMOTION) |
	(1 << State.SPRINT_ENTER) |
	(1 << State.SPRINT_EXIT) |
	(1 << State.BRAKE) |
	(1 << State.MOVE_START)
)

const MASK_LANDING_CHECK: int = (
	(1 << State.JUMP_START) |
	(1 << State.AIR) |
	(1 << State.LAND)
)

var state_id: State = State.LOCOMOTION
var custom_state_name: String = ""

var state: String:
	get:
		if state_id == State.CUSTOM:
			return custom_state_name
		return STATE_NAMES[state_id]
	set(val):
		_state(val)

var state_time := 0.0
var current_clip := ""
var facing := 1
var target_facing := 1
var turn_mode := "Auto"
var last_turn_clip := ""
var turn_queue: Array[String] = []
var turn_base_yaw := 0.0
var turn_last_offset := Vector3.ZERO
var ready_for_input := false
var walk_only := false
var movement_only := false
var transition_log: Array[String] = []
var launched := false
var coyote := 0.0
var jump_buffer := 0.0
var jump_held := false
var jump_held_during_ascent := false
var jump_speed := 0.0
var landing_contact := false
var landing_time := 0.0
var start_gait := "Run"
var start_duration := 0.65
var landing_lead := 0.04
var turn_progress: Array[float] = []
var turn_angle := 0.0
var turn_playback_rate := 1.0
var head_offset: SkeletonModifier3D
var abilities: Node
var suit_polarity:=0
var polarity_control:Node
var body_collision:CollisionShape3D
var reactions:Node
var ladder_pose: SkeletonModifier3D
var walk_plane_z:=0.0
var walk_plane_floor_y:=0.0
var launcher_motion:Node
var tight_jump := true
var crouch_motion:Node
signal jump_mode_changed(tight: bool)

func set_tight_jump(value: bool) -> void:
	tight_jump = value
	jump_mode_changed.emit(tight_jump)
	print("MIKO_JUMP_MODE: ", "IMPROVED (Tight, Frame-1 Takeoff)" if tight_jump else "EXISTING (Original, 133ms Takeoff)")

func _ready() -> void:
	collision_mask = 5
	add_to_group("miko8_magnetic_suit")
	metadata = JSON.parse_string(FileAccess.get_file_as_string(DATA)) as Dictionary
	floor_snap_length = 0.12
	var collision := CollisionShape3D.new()
	body_collision=collision
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	visual = Node3D.new()
	visual.name = "Facing"
	add_child(visual)
	model = (load(model_path) as PackedScene).instantiate() as Node3D
	visual.add_child(model)
	polarity_control=preload("res://scripts/miko8_suit_polarity.gd").new()
	polarity_control.actor=self
	add_child(polarity_control)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	head_offset = preload("res://scripts/miko8_head_offset.gd").new()
	head_offset.name = "GlobalHeadLift"
	skeleton.add_child(head_offset)
	var contact_shadow=preload("res://scripts/miko8_contact_shadow.gd").new()
	contact_shadow.actor=self
	add_child(contact_shadow)
	ladder_pose = preload("res://scripts/miko8_ladder_pose.gd").new()
	ladder_pose.name = "LadderStance"
	ladder_pose.actor = self
	ladder_pose.influence = 0.0
	skeleton.add_child(ladder_pose)
	animation_player = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for label: String in metadata.clips:
		var name := "MIKO8_" + label
		assert(animation_player.has_animation(name), "Missing clip: " + name)
		clips[label] = name
		var animation := animation_player.get_animation(name)
		animation.length = metadata.clips[label].duration
		animation.loop_mode = Animation.LOOP_LINEAR if metadata.clips[label].loop else Animation.LOOP_NONE
	preload("res://scripts/miko8_stock_ladder.gd").install(self)
	preload("res://scripts/miko8_bpg_ladder_library.gd").install(self)
	preload("res://scripts/miko8_reaction_library.gd").install(self)
	preload("res://scripts/miko8_crouch_library.gd").install(self)
	var spell_aim=preload("res://scripts/miko8_spell_aim.gd").new()
	spell_aim.actor=self
	spell_aim.influence=0.0
	skeleton.add_child(spell_aim)
	_install_input()
	abilities = preload("res://scripts/miko8_abilities.gd").new()
	abilities.actor = self
	add_child(abilities)
	launcher_motion=preload("res://scripts/miko8_launcher_motion.gd").new();launcher_motion.actor=self;add_child(launcher_motion)
	var launcher_pose=preload("res://scripts/miko8_launcher_pose.gd").new();launcher_pose.actor=self;skeleton.add_child(launcher_pose)
	var foot_forward=preload("res://scripts/miko8_ladder_foot_forward.gd").new();foot_forward.actor=self;skeleton.add_child(foot_forward)
	var ladder_contacts=preload("res://scripts/miko8_side_ladder_contacts.gd").new();ladder_contacts.actor=self;skeleton.add_child(ladder_contacts)
	reactions=preload("res://scripts/miko8_reactions.gd").new()
	reactions.actor=self
	add_child(reactions)
	crouch_motion=preload("res://scripts/miko8_crouch_motion.gd").new();crouch_motion.actor=self;add_child(crouch_motion)
	reset_actor()
	ready_for_input = true
	print("MIKO8_READY native clips=", clips.keys())

func _install_input() -> void:
	for action: String in ["miko8_left", "miko8_right", "miko8_jump"]:
		if not InputMap.has_action(action): InputMap.add_action(action, 0.18)
	for direction in [-1, 1]:
		var event := InputEventJoypadMotion.new()
		event.device = -1
		event.axis = JOY_AXIS_LEFT_X
		event.axis_value = float(direction)
		InputMap.action_add_event("miko8_left" if direction < 0 else "miko8_right", event)
	var button := InputEventJoypadButton.new()
	button.device = -1
	button.button_index = JOY_BUTTON_B
	InputMap.action_add_event("miko8_jump", button)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	InputMap.action_add_event("miko8_jump", key)

func _axis() -> float:
	var value := Input.get_axis("miko8_left", "miko8_right")
	var keyboard := int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	if keyboard != 0:
		value = float(keyboard) * (1.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 0.35 if Input.is_physical_key_pressed(KEY_CTRL) else 0.65)
	return value

func _duration(label: String) -> float:
	return float(metadata.clips[label].duration)

func _speed(label: String) -> float:
	return float(metadata.clips[label].speed)

func _play(label: String, blend := 0.12, rate := 1.0) -> void:
	if current_clip == label: return
	current_clip = label
	animation_player.play(clips[label], blend, rate)
	animation_player.advance(0.0)

func _set_state_enum(new_state: State) -> void:
	if animation_player: animation_player.speed_scale = 1.0
	state_id = new_state
	state_time = 0.0
	var s_name := STATE_NAMES[new_state]
	transition_log.append(s_name)
	if new_state == State.WALL_BLOCKED:
		visual.scale = Vector3(0.96, 1.03, 0.96)

func _state(value: Variant) -> void:
	if value is int:
		_set_state_enum(value as State)
		return
	var str_val := str(value)
	if NAME_TO_STATE.has(str_val):
		_set_state_enum(NAME_TO_STATE[str_val])
	else:
		if animation_player: animation_player.speed_scale = 1.0
		state_id = State.CUSTOM
		custom_state_name = str_val
		state_time = 0.0
		transition_log.append(str_val)

func _gait(axis: float) -> String:
	if absf(axis) < 0.02: return "Idle"
	if walk_only or absf(axis) < 0.48: return "Walk"
	return "Run" if absf(axis) < SPRINT_STICK_THRESHOLD else "Sprint"

func _input(event: InputEvent) -> void:
	if ready_for_input and event.is_action_pressed("miko8_jump"):
		jump_buffer = 0.18
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_9:
			set_tight_jump(true)
		elif event.physical_keycode == KEY_0:
			set_tight_jump(false)

func _begin_jump() -> void:
	jump_buffer = 0.0
	turn_queue.clear()
	model.position = Vector3.ZERO
	# Keep the visible heading when jumping during a turn; finish facing on landing.
	if absf(sin(visual.rotation.y)) > 0.15: facing = 1 if sin(visual.rotation.y) > 0.0 else -1
	target_facing = facing
	velocity.x = clampf(velocity.x,-AIR_MAX_SPEED,AIR_MAX_SPEED)
	jump_speed = maxf(absf(velocity.x), _speed("Walk"))
	launched = false
	landing_contact = false
	jump_held_during_ascent = Input.is_action_pressed("miko8_jump")
	if tight_jump:
		_state("JumpStart")
		current_clip = "JumpStart"
		animation_player.play(clips.JumpStart, 0.04, 1.2)
		animation_player.seek(0.08, true)
		visual.scale = Vector3(1.10, 0.88, 1.10)
	else:
		_state("JumpGather")
		current_clip = "JumpStart"
		animation_player.play(clips.JumpStart, JUMP_GATHER_TIME, 0.0)
		animation_player.advance(0.0)

func _air_velocity(axis: float, delta: float) -> void:
	var gait := _gait(axis)
	var target := 0.0 if gait == "Idle" else minf(_speed(gait),AIR_MAX_SPEED) * signf(axis)
	velocity.x = move_toward(velocity.x, target, (AIR_BRAKING if gait == "Idle" else AIR_ACCELERATION) * delta)
	if absf(axis) > 0.02:
		facing = 1 if axis > 0.0 else -1
		target_facing = facing

func _landing_soon() -> bool:
	if velocity.y >= 0.0: return false
	var reach := -velocity.y * landing_lead + 0.08
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.12, global_position - Vector3.UP * reach)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()

func _resume_locomotion(axis: float) -> void:
	_state("Locomotion")
	var gait := _gait(axis)
	visual.rotation.y = PI * 0.5 if facing > 0 else -PI * 0.5
	if gait in ["Run","Sprint"] and absf(velocity.x)<0.15:_begin_move_start(gait)
	else: _play(gait,0.08)

func _begin_move_start(gait: String) -> void:
	start_gait = gait
	start_duration = 0.28 if gait == "Sprint" else 0.22
	velocity.x = _speed(start_gait) * float(facing) * 0.12
	_set_state_enum(State.MOVE_START)
	_play(gait, 0.08)

func _physics_process(delta: float) -> void:
	if not ready_for_input: return
	var axis := _axis()
	state_time += delta
	coyote = 0.10 if is_on_floor() else maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	var jump_pressed := Input.is_action_pressed("miko8_jump")
	if jump_pressed and not jump_held: jump_buffer = 0.18
	jump_held = jump_pressed
	if reactions.tick(delta, axis):
		abilities.cancel_quick_pose()
		return
	if launcher_motion.tick(delta, axis):
		abilities.cancel_quick_pose()
		return
	if not movement_only and abilities.tick(delta, axis): return
	if crouch_motion.tick(delta,0.0 if abilities.crouch_tagging else axis):return
	if jump_buffer > 0.0 and coyote > 0.0 and ((1 << state_id) & MASK_JUMP_ALLOWED) != 0:
		_begin_jump()
	var was_floor := is_on_floor()
	if not was_floor:
		var eff_gravity := GRAVITY
		if jump_held_during_ascent and absf(velocity.y) < 0.9:
			eff_gravity = GRAVITY * 0.60
		velocity.y -= eff_gravity * delta
	else: velocity.y = minf(velocity.y, 0.0)
	# Stick direction remains authoritative during stopping and an unfinished turn.
	if absf(axis) > 0.02 and ((1 << state_id) & MASK_GROUNDED_LOCO) != 0:
		var wanted := 1 if axis > 0.0 else -1
		if state_id == State.TURN:
			if wanted != target_facing:
				target_facing = wanted
				_begin_turn()
		elif wanted != facing:
			target_facing = wanted
			if state_id != State.BRAKE:
				_set_state_enum(State.BRAKE)
				_play("SprintExit", 0.07, 2.5) if absf(velocity.x) > _speed("Walk") else _play("Idle", 0.08)
	match state_id:
		State.MOVE_START:
			var wanted := _gait(axis)
			animation_player.speed_scale = clampf(absf(velocity.x) / _speed(start_gait), 0.35, 1.0)
			if wanted == "Idle":
				velocity.x = 0.0
				_set_state_enum(State.LOCOMOTION)
				_play("Idle", 0.08)
			elif axis * facing < 0:
				velocity.x = 0.0
				target_facing = -facing
				_begin_turn()
			elif wanted == "Walk":
				_set_state_enum(State.LOCOMOTION)
				_play("Walk", 0.06)
			else:
				start_gait = wanted
				var phase := clampf(state_time / start_duration, 0.0, 1.0)
				var ramp := lerpf(0.12, 1.0, pow(phase, 1.35))
				velocity.x = _speed(start_gait) * facing * ramp
				if phase >= 1.0:
					_set_state_enum(State.LOCOMOTION)
					_play(start_gait, 0.06)
		State.GROUND_STOP:
			velocity.x = move_toward(velocity.x, 0.0, STOP_DECELERATION * delta)
			if absf(axis) > 0.02:
				if axis * facing < 0:
					target_facing = -facing
					_begin_turn()
				else: _resume_locomotion(axis)
			elif absf(velocity.x) < 0.02:
				velocity.x = 0.0
				_set_state_enum(State.LOCOMOTION)
				_play("Idle", 0.08)
			else:
				animation_player.speed_scale = clampf(absf(velocity.x) / _speed(current_clip), 0.35, 1.0)
		State.WALL_BLOCKED:
			velocity.x = 0.0
			if absf(axis) < 0.02:
				_set_state_enum(State.LOCOMOTION)
			elif not test_move(global_transform, Vector3(signf(axis) * 0.06, 0, 0)):
				if axis * facing < 0:
					target_facing = -facing
					_begin_turn()
				else: _resume_locomotion(axis)
		State.LOCOMOTION:
			if axis * facing < -0.02:
				target_facing = -facing
				_set_state_enum(State.BRAKE)
			else:
				var gait := _gait(axis)
				if (gait == "Run" or gait == "Sprint") and current_clip == "Idle" and absf(velocity.x) < 0.15:
					_begin_move_start(gait)
				elif gait == "Sprint" and current_clip != "Sprint":
					_play("Sprint", 0.08)
					velocity.x = move_toward(velocity.x, _speed("Sprint") * facing, 12.0 * delta)
					animation_player.speed_scale = clampf(absf(velocity.x) / _speed("Sprint"), 0.35, 1.0)
				elif current_clip == "Sprint" and gait != "Sprint":
					_set_state_enum(State.SPRINT_EXIT)
					_play("SprintExit", 0.07, 2.5)
				elif gait == "Idle" and (current_clip == "Walk" or current_clip == "Run") and absf(velocity.x) > 0.02:
					_set_state_enum(State.GROUND_STOP)
				else:
					_play(gait)
					velocity.x = move_toward(velocity.x, 0.0 if gait == "Idle" else _speed(gait) * facing, (STOP_DECELERATION if gait == "Idle" else 12.0) * delta)
					animation_player.speed_scale = clampf(absf(velocity.x) / _speed(gait), 0.35, 1.0) if (gait == "Walk" or gait == "Run" or gait == "Sprint") else 1.0
		State.SPRINT_ENTER:
			velocity.x = move_toward(velocity.x, _speed("Sprint") * facing, _speed("Sprint") / _duration("SprintEnter") * delta)
			if axis * facing < -0.02:
				target_facing = -facing
				_set_state_enum(State.BRAKE)
			elif _gait(axis) != "Sprint":
				_set_state_enum(State.SPRINT_EXIT)
				_play("SprintExit", 0.07, 2.5)
			elif state_time >= _duration("SprintEnter"):
				_set_state_enum(State.LOCOMOTION)
				_play("Sprint", 0.08)
		State.SPRINT_EXIT:
			velocity.x = move_toward(velocity.x, 0.0, STOP_DECELERATION * delta)
			if absf(axis) > 0.02 or state_time >= STOP_TIME:
				_resume_locomotion(axis)
		State.BRAKE:
			velocity.x = move_toward(velocity.x, 0.0, STOP_DECELERATION * delta)
			if absf(axis) > 0.02 and signf(axis) == facing:
				_resume_locomotion(axis)
			elif absf(velocity.x) < 0.01: _begin_turn()
		State.TURN:
			velocity.x = 0.0
		State.JUMP_GATHER:
			if state_time >= JUMP_GATHER_TIME:
				_set_state_enum(State.JUMP_START)
				animation_player.play(clips.JumpStart, 0.0, 1.0)
		State.JUMP_START:
			_air_velocity(axis, delta)
			var takeoff_target := 0.0 if tight_jump else JUMP_TAKEOFF_TIME
			if not launched and state_time >= takeoff_target:
				velocity.y = JUMP_VELOCITY
				floor_snap_length = 0.0
				launched = true
			if jump_held_during_ascent and not jump_pressed:
				jump_held_during_ascent = false
				if velocity.y > 2.4: velocity.y = minf(velocity.y, 2.4)
			if state_time >= JUMP_START_EXIT:
				_set_state_enum(State.AIR)
				_play("JumpAir", 0.18)
		State.AIR:
			_air_velocity(axis, delta)
			if jump_held_during_ascent and not jump_pressed:
				jump_held_during_ascent = false
				if velocity.y > 2.4: velocity.y = minf(velocity.y, 2.4)
			elif velocity.y <= 0.0:
				jump_held_during_ascent = false
			if _landing_soon():
				_set_state_enum(State.LAND)
				_play("JumpLand", 0.12)
				landing_contact = false
		State.LAND:
			if landing_contact:
				landing_time += delta
				var gait := _gait(axis)
				# Plant first; restore travel only when the locomotion pose starts.
				velocity.x = 0.0
				if gait != "Idle" and landing_time >= 0.03:
					facing = 1 if axis > 0 else -1
					target_facing = facing
					if gait == "Run" or gait == "Sprint": _begin_move_start(gait)
					else:
						velocity.x = move_toward(0.0, _speed(gait) * facing, 12.0 * delta)
						_set_state_enum(State.LOCOMOTION)
						_play(gait, 0.05)
					visual.rotation.y = facing * PI / 2
				elif gait == "Idle" and landing_time >= 0.12:
					_resume_locomotion(axis)
			else: _air_velocity(axis, delta)
	animation_player.advance(delta)
	if visual.scale != Vector3.ONE:
		visual.scale = visual.scale.move_toward(Vector3.ONE, delta * 3.5)
	if ((1 << state_id) & MASK_IN_AIR) != 0:
		visual.rotation.y = lerp_angle(visual.rotation.y, PI * 0.5 if facing > 0 else -PI * 0.5, 1.0 - exp(-AIR_TURN_SPEED * delta))
	if state_id == State.TURN: _update_turn()
	move_and_slide()
	if position.y < walk_plane_floor_y - 0.12:
		walk_plane_z = move_toward(walk_plane_z, 0.0, delta * 2.5)
	# A broad terminal roof joins the inset tower decks to the normal lane.
	# Walk across its depth before the side ladder, rather than snapping on mount.
	if is_on_floor() and absf(velocity.x)>.1:
		for index in range(get_slide_collision_count()):
			var contact:=get_slide_collision(index)
			var floor_body:=contact.get_collider() as Node
			if contact.get_normal().y>.7 and floor_body and floor_body.has_meta("walk_lane_z"):
				walk_plane_z=move_toward(walk_plane_z,float(floor_body.get_meta("walk_lane_z")),delta*.65)
	position.z = walk_plane_z
	# A blocked body must not continue cycling a full running stride through the wall.
	if ((1 << state_id) & MASK_WALL_CHECK) != 0 and absf(axis) > 0.02:
		for i in range(get_slide_collision_count()):
			var normal := get_slide_collision(i).get_normal()
			if normal.x * signf(axis) < -0.65:
				velocity.x = 0.0
				_set_state_enum(State.WALL_BLOCKED)
				_play("Idle", 0.06)
				visual.scale = Vector3(0.96, 1.03, 0.96)
				break
	# Corner Nudge: If jumping upward and head clips an obstacle corner by <= 0.12m
	if not was_floor and velocity.y > 0.5 and is_on_ceiling():
		var f_sign: float = float(facing)
		if not test_move(global_transform.translated(Vector3(f_sign * 0.12, 0.08, 0)), Vector3.ZERO):
			position.x += f_sign * 0.08
	if ((1 << state_id) & MASK_LANDING_CHECK) != 0 and launched and not was_floor and is_on_floor():
		if state_id != State.LAND:
			_set_state_enum(State.LAND)
			_play("JumpLand", 0.10)
		landing_contact = true
		landing_time = 0.0
		jump_held_during_ascent = false
		visual.scale = Vector3(1.05, 0.95, 1.05)
		var landing_gait := _gait(axis)
		# Grip on contact instead of carrying airborne momentum through the recovery pose.
		var moving_landing: bool = (landing_gait == "Run" or landing_gait == "Sprint" or landing_gait == "Walk") and axis * facing > 0.0 and absf(velocity.x) > 0.15
		if moving_landing:
			_set_state_enum(State.LOCOMOTION)
			_play(landing_gait, 0.06)
			animation_player.speed_scale = clampf(absf(velocity.x) / _speed(landing_gait), 0.35, 1.0)
		else: velocity.x = 0.0
		floor_snap_length = 0.12
	if position.y < -4.0: reset_actor()

func _begin_turn() -> void:
	var side := "Left" if turn_mode.contains("Left") else "Right"
	if turn_mode == "Auto": side = "Right" if facing > 0 else "Left"
	turn_queue.assign(["Turn90" + side, "Turn90" + side] if turn_mode.contains("90") else ["Turn180" + side])
	turn_base_yaw = visual.rotation.y
	_state("Turn")
	_next_turn()

func _begin_ladder_exit_turn(direction:int)->void:
	# The supplied exit ends facing the ladder. Preserve that heading and use
	# the existing planted quarter-turn footwork before allowing horizontal travel.
	facing=direction;target_facing=direction;velocity=Vector3.ZERO
	var goal:float=direction*PI/2
	var remaining:=absf(angle_difference(visual.rotation.y,goal))
	if remaining<.05:
		_resume_locomotion(_axis())
		return
	var side:="Left" if angle_difference(visual.rotation.y,goal)>0 else "Right"
	turn_queue.assign([("Turn180" if remaining>2.4 else "Turn90")+side]);turn_base_yaw=visual.rotation.y
	_state("Turn");_next_turn()
	turn_playback_rate=float(metadata.clips[last_turn_clip].duration)/(.65 if remaining>2.4 else .45)
	animation_player.play(clips[last_turn_clip],.06,turn_playback_rate)

func _next_turn(gameplay := true) -> void:
	current_clip = ""
	last_turn_clip = turn_queue.pop_front()
	turn_last_offset = Vector3.ZERO
	var data: Dictionary = metadata.clips[last_turn_clip]
	turn_angle = deg_to_rad(90.0 if last_turn_clip.contains("90") else 180.0) * (1.0 if last_turn_clip.contains("Left") else -1.0)
	turn_playback_rate = float(data.duration) / (TURN_TIME_90 if last_turn_clip.contains("90") else TURN_TIME_180) if gameplay else 1.0
	if gameplay and turn_queue.is_empty():
		# A changed stick direction can cancel a partial turn without a heading snap.
		var goal := PI * 0.5 if target_facing > 0 else -PI * 0.5
		var remaining := angle_difference(turn_base_yaw, goal)
		if absf(absf(remaining)-PI) > 0.01: turn_angle = remaining
	# Normalized clips omit the root heading. Drive that heading during their footwork.
	var feet: Array = data.feet
	turn_progress.assign([0.0])
	var total := 0.0
	for i in range(1, feet.size()):
		var activity := 0.0
		for side: String in ["L", "R"]:
			var p: Array = feet[i-1][side]
			var q: Array = feet[i][side]
			activity += Vector3(q[0]-p[0],q[1]-p[1],q[2]-p[2]).length()
		total += maxf(0.0, activity - 0.00005)
		turn_progress.append(total)
	for i in range(turn_progress.size()):
		var t := turn_progress[i] / maxf(total, 0.0001)
		turn_progress[i] = t * t * (3.0 - 2.0 * t)
	_play(last_turn_clip, 0.06 if gameplay else 0.12, turn_playback_rate)
	animation_player.seek(0.0, true)
	state_time = 0.0

func _sample(values: Array, time: float, duration: float) -> Variant:
	var f := clampf(time / duration * float(values.size() - 1), 0.0, float(values.size() - 1))
	var i := int(f)
	var j := mini(i + 1, values.size() - 1)
	if values[0] is Array:
		return Vector3(values[i][0], values[i][1], values[i][2]).lerp(Vector3(values[j][0], values[j][1], values[j][2]), f - i)
	return lerpf(values[i], values[j], f - i)

func _update_turn() -> void:
	var data: Dictionary = metadata.clips[last_turn_clip]
	var source_time := state_time * turn_playback_rate
	visual.rotation.y = turn_base_yaw + turn_angle * float(_sample(turn_progress, source_time, data.duration))
	if source_time >= float(data.duration):
		turn_base_yaw += turn_angle
		visual.rotation.y = turn_base_yaw
		model.position = Vector3.ZERO
		if not turn_queue.is_empty(): _next_turn()
		else:
			facing = target_facing
			visual.rotation.y = PI * 0.5 if facing > 0 else -PI * 0.5
			_resume_locomotion(_axis())

func reset_actor() -> void:
	health = MAX_HEALTH
	if crouch_motion:crouch_motion.reset()
	if launcher_motion:launcher_motion.reset()
	if polarity_control:polarity_control.set_polarity(0,true)
	walk_plane_z=0.;walk_plane_floor_y=0.
	if reactions:reactions.reset()
	if abilities: abilities.reset()
	if ladder_pose: ladder_pose.preview_enabled = false
	position = Vector3(0, 0.03, 0)
	velocity = Vector3.ZERO
	jump_held_during_ascent = false
	facing = 1
	target_facing = 1
	visual.rotation.y = PI * 0.5
	model.position = Vector3.ZERO
	turn_queue.clear()
	jump_buffer = 0.0
	jump_held = false
	launched = false
	landing_contact = false
	floor_snap_length = 0.12
	_state("Locomotion")
	current_clip = ""
	_play("Idle", 0.0)



func take_hit(reaction:="HitShoulderLeft")->void:
	reactions.take_hit(reaction)

func receive_warden_bolt() -> void:
	if ready_for_input and is_physics_processing() and state != "NetworkTransfer":
		reactions.take_hit("HitShoulderLeft", true)

func die(variant:=1)->void:
	reactions.die(variant)

