extends CharacterBody3D
## Standalone action controller. No dependency on the old actor or level systems.
signal impact(point: Vector3, strength: float)
signal action_started(action: String)
signal landed(speed: float)
signal attack_effect(point: Vector3, direction: int, variant: int, slam: bool)
signal sword_style_changed(index: int, name: String, desc: String)
var effect_fired := false
const SPEED := 7.2
const ACCEL := 105.0
const BRAKE := 125.0
const AIR_ACCEL := 70.0
const JUMP := 10.5
const GRAVITY := 28.0
const FALL_GRAVITY := 43.0
const COYOTE := 0.085
const BUFFER := 0.14
const DASH_SPEED := 17.5
const DASH_TIME := 0.15
const CROUCH_ENTER_TIME := 0.18
const ATTACKS := [
	{"clip":"SwordA", "startup":0.075, "active":0.065, "recovery":0.15, "contact":7.0/30.0, "end":8.0/30.0, "damage":24},
	{"clip":"SwordB", "startup":0.085, "active":0.075, "recovery":0.16, "contact":7.0/30.0, "end":10.0/30.0, "damage":26},
	{"clip":"SwordC", "startup":0.115, "active":0.10, "recovery":0.20, "contact":14.0/30.0, "end":17.0/30.0, "damage":36},
]
const AIR_ATTACKS := [
	{"clip":"AirA", "begin":0.0, "finish":.4, "startup":.075, "active":.07, "recovery":.13, "contact":7.0/30, "end":9.0/30, "damage":20},
	{"clip":"AirCombo", "begin":12.0/30, "finish":1.0, "startup":.09, "active":.075, "recovery":.16, "contact":21.0/30, "end":23.0/30, "damage":25},
]
const LAUNCHER := {"clip":"Uppercut", "begin":1.0/30, "finish":.7, "startup":.10, "active":.075, "recovery":.19, "contact":5.5/30, "end":7.5/30, "damage":30}
var visual: Node3D
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var blade: Node3D
var sword_bulkheads: Array[AABB] = []
var blade_materials: Array[ShaderMaterial] = []
var sword_wall_left := Vector3(-10000,0,0)
var sword_wall_right := Vector3(10000,0,0)
var trail: ImmediateMesh
var trail_edges: Array[Vector3] = []
var trail_ages: Array[float] = []
var trail_center := Vector3.ZERO
var dash_ghosts: Array[Dictionary] = []
var ghost_timer := 0.0
var ghost_shader: Shader
var falling_sparks: Array[Dictionary] = []
var spark_mesh: BoxMesh
var smoke_mesh: SphereMesh
var spark_mat_white: StandardMaterial3D
var spark_mat_gold: StandardMaterial3D
var spark_mat_cyan: StandardMaterial3D
var spark_mat_fire: StandardMaterial3D
var spark_mat_ink: StandardMaterial3D
var spark_mat_spirit: StandardMaterial3D
var spark_mat_dust: StandardMaterial3D
var spark_mat_magenta: StandardMaterial3D
var spark_mat_sakura: StandardMaterial3D
var spark_mat_smoke: StandardMaterial3D
var ribbon_mat: ShaderMaterial
var sword_style := 2

const SWORD_STYLES: Array[Dictionary] = [
	{
		"name": "Pure White Razor",
		"desc": "Minimalist precision anime cutting line. Crisp white core, zero clutter, tight floor sparks.",
		"swath_base": 0.48, "swath_tip": 1.18, "life": 0.09,
		"style_mode": 0, "spark_type": "white_spark", "spark_count": 1,
	},
	{
		"name": "Ozone Cel Smoke Wake",
		"desc": "Billowing anime vector smoke puffs along a broad crescent with cel rim highlights.",
		"swath_base": 0.22, "swath_tip": 1.55, "life": 0.17,
		"style_mode": 1, "spark_type": "smoke_puff", "spark_count": 2,
	},
	{
		"name": "High-Voltage Lightning",
		"desc": "Sizzling high-frequency electric arcs with cyan crackles and rapid floor sparks.",
		"swath_base": 0.40, "swath_tip": 1.25, "life": 0.10,
		"style_mode": 2, "spark_type": "electric_spark", "spark_count": 3,
	},
	{
		"name": "Molten Ember Cleave",
		"desc": "Blazing volcanic magma arc with fiery orange coals that bounce and smolder on the floor.",
		"swath_base": 0.30, "swath_tip": 1.45, "life": 0.14,
		"style_mode": 3, "spark_type": "molten_ember", "spark_count": 3,
	},
	{
		"name": "Shadow Ink (Sumi-e)",
		"desc": "Calligraphic Japanese brushstroke with deep obsidian ink wash and black splatter droplets.",
		"swath_base": 0.32, "swath_tip": 1.38, "life": 0.15,
		"style_mode": 4, "spark_type": "ink_splat", "spark_count": 2,
	},
	{
		"name": "Ghost Phantom Mirage",
		"desc": "Mystical spiritual aurora ribbon with ethereal violet-cyan waves and slow-drifting spirit motes.",
		"swath_base": 0.35, "swath_tip": 1.35, "life": 0.16,
		"style_mode": 5, "spark_type": "spirit_mote", "spark_count": 2,
	},
	{
		"name": "Heavy Iron Meat Cleaver",
		"desc": "Brutal industrial steel cleave kicking up dense grey dust clouds and chipped stone debris.",
		"swath_base": 0.50, "swath_tip": 1.15, "life": 0.08,
		"style_mode": 6, "spark_type": "dust_debris", "spark_count": 3,
	},
	{
		"name": "Cyber Neon Glitch",
		"desc": "Synthwave digital vector laser with scanlines, raster notches, and pixel bit drops.",
		"swath_base": 0.38, "swath_tip": 1.30, "life": 0.11,
		"style_mode": 7, "spark_type": "cyber_bit", "spark_count": 2,
	},
	{
		"name": "Sakura Blossom Storm",
		"desc": "Poetic anime floral slash. Elegant pink trail showering delicate fluttering sakura flower petals.",
		"swath_base": 0.38, "swath_tip": 1.32, "life": 0.14,
		"style_mode": 8, "spark_type": "sakura_petal", "spark_count": 2,
	},
	{
		"name": "Supernova Maximum Juice",
		"desc": "Over-the-top comic climax: massive 1.7m radiant supernova arc, starbursts, and molten floor cascade!",
		"swath_base": 0.18, "swath_tip": 1.68, "life": 0.20,
		"style_mode": 9, "spark_type": "supernova_cascade", "spark_count": 4,
	}
]
var pose_name := ""
var head_before_lift := Quaternion.IDENTITY
var head_lift_applied := false
var state := "move"
var age := 0.0
var facing := 1
var coyote := 0.0
var buffers := {"jump":0.0, "attack":0.0, "dash":0.0, "parry":0.0}
var jumps := 0
var air_dash_used := false
var dash_cooldown := 0.0
var hitstop := 0.0
var combo := 0
var combo_timeout := 0.0
var queued_combo := false
var attack_kind := "normal"
var attack_in_air := false
var air_hang_left := .14
var air_recovery_age := 1.0
var struck: Array[Node] = []
var jump_pose_age := 1.0
var land_age := 1.0
var slam_landed := false
var health := 100
var parry_count := 0
var invulnerable := 0.0
var automation := false
var command_axis := 0.0
var command_vertical := 0.0
var command_held := false
var model_path := "res://models/Miko.glb"
var polarity_controls := false
var suit_polarity := 0
var suit_materials: Array[ShaderMaterial] = []
var laser: Node3D
var laser_pole := 0
var laser_direction := Vector3.RIGHT
var laser_hand := -1
var laser_forearm := -1
var laser_upper_arm := -1
var body_collision: CollisionShape3D
var stand_shape: CapsuleShape3D
var crouch_shape: CapsuleShape3D
var stand_query := PhysicsShapeQueryParameters3D.new()
var crouched := false
var crouch_time := 0.0
var crouch_exit_time := -1.0
var look_down_time := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.12
	var shape := CapsuleShape3D.new()
	shape.radius = 0.26
	shape.height = 1.65
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body_collision = collider
	stand_shape = shape
	crouch_shape = shape.duplicate() as CapsuleShape3D
	crouch_shape.height = 1.2
	stand_query.shape = stand_shape
	stand_query.exclude = [get_rid()]
	stand_query.collision_mask = 1
	collider.position.y = 0.825
	add_child(collider)
	visual = Node3D.new()
	add_child(visual)
	model = (load(model_path) as PackedScene).instantiate()
	visual.add_child(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	player = model.find_children("*", "AnimationPlayer", true, false)[0]
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for name: String in ["Idle", "Run", "Sprint", "JumpAir"]:
		player.get_animation("MIKO8_"+name).loop_mode = Animation.LOOP_LINEAR
	preload("res://scripts/animation_bank.gd").install(player, skeleton, "res://models/MIKO8_Combat.json")
	preload("res://scripts/animation_bank.gd").install(player, skeleton, "res://models/LabActions.json")
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original := mesh.get_active_material(surface) as StandardMaterial3D
			if original:
				var paint := ShaderMaterial.new()
				paint.shader = preload("res://shaders/miko8_three_tone.gdshader")
				paint.set_shader_parameter("base_texture", original.albedo_texture)
				mesh.set_surface_override_material(surface, paint)
				suit_materials.append(paint)
	if polarity_controls:
		_install_polarity_poses()
		laser = preload("res://scripts/lab_polarity_laser.gd").new()
		laser.actor = self
		add_child(laser)
		add_to_group("miko8_magnetic_suit")
	_build_sword()
	ghost_shader = preload("res://shaders/dash_ghost.gdshader")
	spark_mesh = BoxMesh.new()
	spark_mesh.size = Vector3(1.0, 1.0, 1.0)
	smoke_mesh = SphereMesh.new()
	smoke_mesh.radius = 0.05
	smoke_mesh.height = 0.10
	spark_mat_white = _make_unshaded(Color("ffffff"))
	spark_mat_gold = _make_unshaded(Color("ffe080"))
	spark_mat_cyan = _make_unshaded(Color("38f4ff"))
	spark_mat_fire = _make_unshaded(Color("ff6b1a"))
	spark_mat_ink = _make_unshaded(Color("111116"))
	spark_mat_spirit = _make_unshaded(Color("d888ff"))
	spark_mat_dust = _make_unshaded(Color("8a9ca4"))
	spark_mat_magenta = _make_unshaded(Color("ff1f8f"))
	spark_mat_sakura = _make_unshaded(Color("ffb8d4"))
	spark_mat_smoke = _make_unshaded(Color("7eaeb8"))
	_install_input()
	reset()

func _make_unshaded(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	return m

func _install_input() -> void:
	var bindings := {
		"left": [KEY_A, KEY_LEFT],
		"right": [KEY_D, KEY_RIGHT],
		"up": [KEY_W, KEY_UP],
		"down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE],
		"attack": [KEY_J],
		"dash": [KEY_SHIFT],
		"parry": [KEY_K],
		"reset": [KEY_R],
		"dummy": [KEY_T],
		"zoom": [KEY_Z],
		"next_style": [KEY_C, KEY_TAB, KEY_E],
		"prev_style": [KEY_Q],
		"style_0": [KEY_1],
		"style_1": [KEY_2],
		"style_2": [KEY_3],
		"style_3": [KEY_4],
		"style_4": [KEY_5],
		"style_5": [KEY_6],
		"style_6": [KEY_7],
		"style_7": [KEY_8],
		"style_8": [KEY_9],
		"style_9": [KEY_0]
	}
	if polarity_controls:
		bindings["laser_red"] = [KEY_F]
		bindings["laser_blue"] = [KEY_G]
		bindings["charge_red"] = [KEY_U]
		bindings["charge_blue"] = [KEY_I]
	for action: String in bindings:
		if InputMap.has_action(action): continue
		InputMap.add_action(action, 0.2)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	var buttons := {
		"jump": JOY_BUTTON_A,
		"attack": JOY_BUTTON_X,
		"dash": JOY_BUTTON_B,
		"parry": JOY_BUTTON_LEFT_SHOULDER,
		"reset": JOY_BUTTON_BACK,
		"dummy": JOY_BUTTON_Y,
		"zoom": JOY_BUTTON_RIGHT_STICK,
		"left": JOY_BUTTON_DPAD_LEFT,
		"right": JOY_BUTTON_DPAD_RIGHT,
		"up": JOY_BUTTON_DPAD_UP,
		"down": JOY_BUTTON_DPAD_DOWN,
		"next_style": JOY_BUTTON_RIGHT_SHOULDER
	}
	# InputMap persists across scene loads, so clear the outgoing face and shoulder map.
	for action in ["jump","attack","dash","parry","dummy","next_style","charge_red","charge_blue"]:
		if InputMap.has_action(action):
			for binding in InputMap.action_get_events(action):
				if binding is InputEventJoypadButton:
					InputMap.action_erase_event(action,binding)
	if polarity_controls:
		buttons["jump"] = JOY_BUTTON_A
		buttons["attack"] = JOY_BUTTON_X
		buttons["dash"] = JOY_BUTTON_B
		buttons["parry"] = JOY_BUTTON_Y
		buttons.erase("dummy")
		buttons.erase("next_style")
		buttons["charge_red"] = JOY_BUTTON_LEFT_SHOULDER
		buttons["charge_blue"] = JOY_BUTTON_RIGHT_SHOULDER
		for action in ["laser_red","laser_blue"]:
			var trigger := InputEventJoypadMotion.new()
			trigger.axis = JOY_AXIS_TRIGGER_LEFT if action == "laser_red" else JOY_AXIS_TRIGGER_RIGHT
			trigger.axis_value = 1.0
			if not InputMap.action_has_event(action,trigger):
				InputMap.action_add_event(action,trigger)
	for action: String in buttons:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		var event := InputEventJoypadButton.new()
		event.button_index = buttons[action]
		if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)
	for action: String in ["left", "right", "up", "down"]:
		var event := InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_LEFT_X if action in ["left", "right"] else JOY_AXIS_LEFT_Y
		event.axis_value = -1.0 if action in ["left", "up"] else 1.0
		if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)

	if polarity_controls:
		_install_laser_aim()

func _install_laser_aim() -> void:
	var inputs := {
		"laser_aim_left": [JOY_AXIS_RIGHT_X,-1.0,KEY_H],
		"laser_aim_right": [JOY_AXIS_RIGHT_X,1.0,KEY_L],
		"laser_aim_up": [JOY_AXIS_RIGHT_Y,-1.0,KEY_O],
		"laser_aim_down": [JOY_AXIS_RIGHT_Y,1.0,KEY_N]
	}
	for action: String in inputs:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action,.24)
		var motion := InputEventJoypadMotion.new()
		motion.axis = inputs[action][0]
		motion.axis_value = inputs[action][1]
		InputMap.action_add_event(action,motion)
		var key := InputEventKey.new()
		key.physical_keycode = inputs[action][2]
		InputMap.action_add_event(action,key)

func reset() -> void:
	_set_crouched(false)
	crouch_time = 0.0
	crouch_exit_time = -1.0
	look_down_time = 0.0
	_set_suit_pole(0)
	laser_pole = 0
	if laser: laser.stop()
	position = Vector3(-5.5, 0.04, 0)
	velocity = Vector3.ZERO
	state = "move"
	age = 0
	facing = 1
	coyote = 0
	jumps = 0
	air_dash_used = false
	air_hang_left = .14
	air_recovery_age = 1.0
	dash_cooldown = 0
	hitstop = 0
	combo = 0
	combo_timeout = 0
	queued_combo = false
	slam_landed = false
	struck.clear()
	trail_edges.clear()
	trail_ages.clear()
	trail.clear_surfaces()
	for g: Dictionary in dash_ghosts:
		if is_instance_valid(g.get("node")):
			g.node.queue_free()
	dash_ghosts.clear()
	ghost_timer = 0.0
	for sp: Dictionary in falling_sparks:
		if is_instance_valid(sp.get("node")):
			sp.node.queue_free()
	falling_sparks.clear()
	health = 100
	parry_count = 0
	invulnerable = 0
	jump_pose_age = 1
	land_age = 1
	for action: String in buffers: buffers[action] = 0.0
	visual.rotation = Vector3(0, PI/2, 0)
	visual.position = Vector3.ZERO

	head_lift_applied = false
	_pose("SwordIdle", 0, true)

func press(action: String) -> void:
	buffers[action] = BUFFER

func _physics_process(delta: float) -> void:
	var axis := command_axis if automation else Input.get_axis("left", "right")
	var vertical := command_vertical if automation else Input.get_axis("down", "up")
	var held := command_held if automation else Input.is_action_pressed("jump")
	if not automation:
		for action: String in buffers:
			if Input.is_action_just_pressed(action): press(action)
		if Input.is_action_just_pressed("reset"): get_parent().reset_room()
		if Input.is_action_just_pressed("next_style"): next_sword_style()
		elif Input.is_action_just_pressed("prev_style"): prev_sword_style()
		for s_idx in range(10):
			if Input.is_action_just_pressed("style_%d" % s_idx):
				set_sword_style(s_idx)
	if polarity_controls and not automation:
		if Input.is_action_just_pressed("charge_red"):
			_set_suit_pole(0 if suit_polarity == 1 else 1)
		elif Input.is_action_just_pressed("charge_blue"):
			_set_suit_pole(0 if suit_polarity == 2 else 2)
	if hitstop > 0:
		hitstop = maxf(0, hitstop-delta)
		return
	for action: String in buffers: buffers[action] = maxf(0.0, float(buffers[action])-delta)
	age += delta
	jump_pose_age += delta
	land_age += delta
	air_recovery_age += delta
	dash_cooldown = maxf(0, dash_cooldown-delta)
	combo_timeout = maxf(0, combo_timeout-delta)
	invulnerable = maxf(0, invulnerable-delta)
	var grounded := is_on_floor()
	if grounded and velocity.y <= 0:
		coyote = COYOTE
		jumps = 0
		air_dash_used = false
		air_hang_left = .14
	else:
		coyote = maxf(0, coyote-delta)
	if absf(axis) > 0.15 and state == "move": facing = 1 if axis > 0 else -1
	if polarity_controls:
		var requested := _requested_laser() if not automation else 0
		if state == "laser" and (requested == 0 or vertical < -.5 or _combat_buffered()):
			_change_state("move")
		_update_crouch(delta, grounded, vertical, axis)
		if state == "move" and not crouched and requested != 0 and not _combat_buffered():
			_change_state("laser")
		laser_pole = requested if state == "laser" else 0
		if laser_pole != 0:
			_update_laser_direction()
	var can_cancel := not crouched and (state == "move" or (state == "attack" and age >= _active_end()) or (state == "parry" and age > .20))
	if can_cancel and buffers.dash > 0 and dash_cooldown <= 0 and (grounded or not air_dash_used):
		buffers.dash = 0.0
		if absf(axis) > .15: facing = 1 if axis > 0 else -1
		visual.rotation.y = facing * PI * 0.5
		_change_state("dash")
		dash_cooldown = .30
		if not grounded: air_dash_used = true
	elif can_cancel and buffers.parry > 0:
		buffers.parry = 0.0
		_change_state("parry")
	elif can_cancel and buffers.jump > 0 and (coyote > 0 or jumps < 2):
		buffers.jump = 0.0
		if coyote > 0: jumps = 1
		else: jumps = maxi(1, jumps) + 1
		velocity.y = JUMP if jumps == 1 else JUMP*.94
		coyote = 0
		jump_pose_age = 0
		_change_state("move")
		grounded = false
		action_started.emit("jump" if jumps == 1 else "double jump")
	if state == "move" and not crouched and buffers.attack > 0:
		buffers.attack = 0.0
		if vertical < -.45 and not grounded:
			_change_state("slam")
			slam_landed = false
			struck.clear()
			velocity = Vector3.ZERO
		else:
			_start_attack("launcher" if vertical > .45 else "normal", 0 if combo_timeout <= 0 else combo)
	elif state == "attack" and buffers.attack > 0:
		queued_combo = true
		buffers.attack = 0.0
	if not held and velocity.y > 3.8 and state == "move": velocity.y = minf(velocity.y, 3.8)
	if state not in ["dash", "slam"]:
		var gravity := FALL_GRAVITY if velocity.y < 0 else GRAVITY
		# Slight apex hang helps direction changes; never applies during falling slams.
		if absf(velocity.y) < 1.2 and not grounded: gravity *= .7
		# A finite hang budget per airtime, only near the apex. Attacks never
		# add vertical speed, reset the jump, or replenish this budget.
		if state == "attack" and attack_in_air and air_hang_left > 0 and absf(velocity.y) < 2:
			gravity *= .55
			air_hang_left = maxf(0,air_hang_left-delta)
		velocity.y -= gravity*delta
	match state:
		"move":
			var acceleration := (ACCEL if absf(axis) > .15 else BRAKE) if grounded else AIR_ACCEL
			velocity.x = move_toward(velocity.x, axis*(.9 if crouched else SPEED), acceleration*delta)
		"laser":
			velocity.x = move_toward(velocity.x,0.0,55.0*delta)
		"dash":
			velocity = Vector3(facing*DASH_SPEED, 0, 0)
			if age >= DASH_TIME:
				_change_state("move")
				velocity.x = axis*SPEED
		"attack":
			if attack_in_air:
				velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
			else:
				var target_vx := 0.0
				var step_accel := 80.0
				if combo == 0:
					if age < 0.065:
						target_vx = facing * 2.2
						step_accel = 120.0
					else:
						target_vx = 0.0
						step_accel = 70.0
				elif combo == 1:
					if age < 0.075:
						target_vx = facing * 1.8
						step_accel = 100.0
					else:
						target_vx = 0.0
						step_accel = 65.0
				elif combo == 2:
					if age < 0.110:
						target_vx = facing * 3.4
						step_accel = 140.0
					else:
						target_vx = 0.0
						step_accel = 90.0
				else:
					if age < 0.080:
						target_vx = facing * 1.4
						step_accel = 90.0
					else:
						target_vx = 0.0
						step_accel = 60.0
				velocity.x = move_toward(velocity.x, target_vx, step_accel * delta)
			if age >= _startup() and age <= _active_end(): _strike()
			if queued_combo and age >= _active_end()+.045:
				_start_attack("normal", (combo+1)%(2 if attack_in_air else 3))
			elif age >= _total_attack():
				combo = (combo+1)%(2 if attack_in_air else 3)
				combo_timeout = .24
				if attack_in_air: air_recovery_age = 0
				_change_state("move")
		"parry":
			velocity.x = move_toward(velocity.x, 0.0, BRAKE*delta)
			if age >= .34: _change_state("move")
		"slam":
			velocity.x = 0
			if slam_landed:
				velocity.y = -1
				if age >= .24: _change_state("move")
			elif age < .11: velocity.y = .6
			else: velocity.y = -24
	velocity.z = 0
	var fall_speed := maxf(0.0,-velocity.y)
	move_and_slide()
	global_position.z = 0
	if is_on_floor() and not grounded and velocity.y <= 0:
		land_age = 0
		if state != "slam": landed.emit(fall_speed)
		if state == "attack" and attack_in_air:
			if queued_combo: buffers.attack = BUFFER
			queued_combo = false
			_change_state("move")
		if state == "slam" and not slam_landed:
			slam_landed = true
			age = 0
			_strike(true)
			impact.emit(global_position+Vector3.UP*.12, .55)
			attack_effect.emit(global_position+Vector3(facing*1.65,0,0), facing, 0, true)
			hitstop = .055
	if global_position.y < -5: get_parent().reset_room()
	if state == "dash":
		visual.rotation.y = facing * PI * 0.5
	else:
		var target_rot := facing * PI * 0.5
		visual.rotation.y = wrapf(rotate_toward(visual.rotation.y, target_rot, delta * 30.0), -PI, PI)
	_animate(delta, axis)
	_update_laser_beam(delta)
	_update_sword_walls()
	_update_trail()
	for i in range(dash_ghosts.size() - 1, -1, -1):
		var g: Dictionary = dash_ghosts[i]
		g.life -= delta
		var f: float = clampf(g.life / g.max_life, 0.0, 1.0)
		if g.mat:
			g.mat.set_shader_parameter("alpha_fade", f * 0.20)
		if g.life <= 0:
			if is_instance_valid(g.get("node")):
				g.node.queue_free()
			dash_ghosts.remove_at(i)
	for i in range(falling_sparks.size() - 1, -1, -1):
		var sp: Dictionary = falling_sparks[i]
		sp.life -= delta
		if sp.life <= 0:
			if is_instance_valid(sp.get("node")):
				sp.node.queue_free()
			falling_sparks.remove_at(i)
			continue
		var ptype: String = sp.get("type", "white_spark")
		var floor_y := 0.0
		if sp.node.position.x >= 2.9 and sp.node.position.x <= 6.7:
			floor_y = 1.44
		
		match ptype:
			"smoke_puff":
				sp.velocity.y += 1.1 * delta
				sp.velocity.x = move_toward(sp.velocity.x, 0.0, 2.8 * delta)
				sp.node.position += sp.velocity * delta
				var f := clampf(sp.life / sp.max_life, 0.0, 1.0)
				var sz := (0.05 + (1.0 - f) * 0.14) * f
				sp.node.scale = Vector3.ONE * sz
			"sakura_petal":
				sp.sway_age += delta * 6.5
				sp.velocity.y = move_toward(sp.velocity.y, -1.3, 4.5 * delta)
				sp.velocity.x = sin(sp.sway_age) * 1.4 + float(sp.get("drift_x", 0.0))
				sp.node.position += sp.velocity * delta
				if sp.node.position.y <= floor_y:
					sp.node.position.y = floor_y + 0.005
					sp.velocity = Vector3.ZERO
				var f := clampf(sp.life / sp.max_life, 0.0, 1.0)
				sp.node.scale = Vector3(0.045 * f, 0.024 * f, 0.018 * f)
				sp.node.rotation.z += delta * 3.5
			"spirit_mote":
				sp.sway_age += delta * 4.2
				sp.velocity.y = move_toward(sp.velocity.y, 0.85, 2.2 * delta)
				sp.velocity.x = cos(sp.sway_age) * 0.7
				sp.node.position += sp.velocity * delta
				var f := clampf(sp.life / sp.max_life, 0.0, 1.0)
				var pulse := 0.038 + 0.016 * sin(sp.sway_age * 2.2)
				sp.node.scale = Vector3.ONE * pulse * f
			"molten_ember":
				sp.velocity.y -= 26.0 * delta
				sp.velocity.x = move_toward(sp.velocity.x, 0.0, 3.2 * delta)
				sp.node.position += sp.velocity * delta
				if sp.node.position.y <= floor_y:
					sp.node.position.y = floor_y + 0.005
					if sp.velocity.y < -1.0:
						sp.velocity.y = -sp.velocity.y * 0.44
						sp.velocity.x *= 0.72
					else:
						sp.velocity.y = 0.0
						sp.velocity.x = move_toward(sp.velocity.x, 0.0, 14.0 * delta)
				var f := clampf(sp.life / sp.max_life, 0.0, 1.0)
				var sz: float = (0.042 + float(sp.get("seed", 0.0)) * 0.015) * f
				sp.node.scale = Vector3(sz * 1.5, sz, sz)
			"ink_splat":
				sp.velocity.y -= 27.0 * delta
				sp.velocity.x = move_toward(sp.velocity.x, 0.0, 4.0 * delta)
				sp.node.position += sp.velocity * delta
				var f := clampf(sp.life / sp.max_life, 0.0, 1.0)
				if sp.node.position.y <= floor_y:
					sp.node.position.y = floor_y + 0.003
					sp.velocity = Vector3.ZERO
					sp.node.scale = Vector3(0.085 * (1.8 - f * 0.8), 0.005, 0.07 * (1.8 - f * 0.8))
				else:
					sp.node.scale = Vector3.ONE * 0.034 * f
			"dust_debris":
				sp.velocity.y -= 24.0 * delta
				sp.velocity.x = move_toward(sp.velocity.x, 0.0, 4.5 * delta)
				sp.node.position += sp.velocity * delta
				if sp.node.position.y <= floor_y:
					sp.node.position.y = floor_y + 0.005
					if sp.velocity.y < -1.0:
						sp.velocity.y = -sp.velocity.y * 0.28
					else:
						sp.velocity.y = 0.0
						sp.velocity.x = move_toward(sp.velocity.x, 0.0, 12.0 * delta)
				var f := clampf(sp.life / sp.max_life, 0.0, 1.0)
				var dust_sz: float = (0.036 + float(sp.get("seed", 0.0)) * 0.02) * f
				sp.node.scale = Vector3.ONE * dust_sz
				sp.node.rotation.z += delta * 5.0
			"cyber_bit":
				sp.velocity.y -= 16.0 * delta
				sp.node.position += sp.velocity * delta
				if sp.node.position.y <= floor_y:
					sp.node.position.y = floor_y + 0.005
					sp.velocity = Vector3.ZERO
				var f := clampf(sp.life / sp.max_life, 0.0, 1.0)
				var blink: float = 1.0 if fposmod(sp.life * 25.0, 1.0) > 0.3 else 0.0
				sp.node.scale = Vector3(0.028, 0.028, 0.028) * f * blink
			_: # "white_spark", "electric_spark", "supernova_cascade"
				sp.velocity.y -= (32.0 if ptype == "electric_spark" else 22.0) * delta
				sp.velocity.x = move_toward(sp.velocity.x, 0.0, 3.5 * delta)
				sp.node.position += sp.velocity * delta
				if ptype == "electric_spark":
					sp.node.position.x += randf_range(-0.010, 0.010)
				if sp.node.position.y <= floor_y:
					sp.node.position.y = floor_y + 0.005
					if sp.velocity.y < -0.8:
						sp.velocity.y = -sp.velocity.y * 0.32
						sp.velocity.x *= 0.65
					else:
						sp.velocity.y = 0.0
						sp.velocity.x = move_toward(sp.velocity.x, 0.0, 12.0 * delta)
				var f: float = clampf(sp.life / sp.max_life, 0.0, 1.0)
				var sp_speed: float = sp.velocity.length()
				var sp_len := clampf(0.04 + sp_speed * 0.012, 0.04, 0.14)
				sp.node.scale = Vector3(sp_len * f, 0.016 * f, 0.016 * f)
				if sp_speed > 0.3:
					sp.node.rotation.z = atan2(sp.velocity.y, sp.velocity.x)
		if _sword_particle_behind_wall(sp.node.position):
			sp.node.queue_free()
			falling_sparks.remove_at(i)
	if state == "dash":
		ghost_timer -= delta
		if ghost_timer <= 0.0 and age < DASH_TIME - 0.01:
			ghost_timer = 0.040
			_spawn_dash_ghost()


func _change_state(value: String) -> void:
	state = value
	age = 0
	if value == "dash":
		ghost_timer = 0.0
	action_started.emit(value)

func _start_attack(kind: String, index: int) -> void:
	trail_edges.clear()
	trail_ages.clear()
	effect_fired = false
	_change_state("attack")
	attack_kind = kind
	attack_in_air = not is_on_floor()
	combo = index
	queued_combo = false
	struck.clear()
	# Physics keeps its existing jump arc; authored air poses supply the motion.

func _attack_spec() -> Dictionary:
	if attack_kind == "launcher": return LAUNCHER
	return AIR_ATTACKS[combo%2] if attack_in_air else ATTACKS[combo%3]

func _startup() -> float:
	return float(_attack_spec().startup)

func _active_end() -> float:
	return _startup() + float(_attack_spec().active)
func _total_attack() -> float:
	return _active_end() + float(_attack_spec().recovery)

func _strike(slam := false) -> void:
	if not slam and not effect_fired:
		effect_fired = true
		attack_effect.emit(global_position+Vector3(0,.95,.25),facing,3 if attack_kind == "launcher" else combo,false)
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.4, 1.4, 1.0) if slam else Vector3(1.9, 2.0, 1.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = global_position + (Vector3(0,.55,0) if slam else Vector3(facing*.9,1.0,0))
	query.collision_mask = 4
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 8):
		var target: Node3D = result.collider
		if target in struck or not target.has_method("receive_hit"): continue
		var point := target.global_position+Vector3.UP*.9
		var ray := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.8, point, 1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		struck.append(target)
		var launch := 8.5 if attack_kind == "launcher" else (4.0 if slam else (3.0 if attack_in_air else 0.0))
		target.receive_hit(50 if slam else int(_attack_spec().damage), facing, launch)
		var hs: float = 0.045
		var imp: float = 0.28
		if slam:
			hs = 0.085
			imp = 0.70
		elif attack_kind == "launcher":
			hs = 0.065
			imp = 0.45
		elif combo == 2:
			hs = 0.075
			imp = 0.55
		elif combo == 1:
			hs = 0.050
			imp = 0.34
		hitstop = hs
		target.hitstop = hs
		impact.emit(point, imp)

func receive_attack(from_x: float) -> bool:
	if state == "dash" or invulnerable > 0: return false
	if state == "parry" and age >= .025 and age <= .17 and (from_x-global_position.x)*facing > 0:
		parry_count += 1
		hitstop = .075
		impact.emit(global_position+Vector3(facing*.5,1,0), .55)
		return true
	health = maxi(0, health-10)
	invulnerable = .65
	impact.emit(global_position+Vector3.UP, .2)
	return false

func _clip(label: String) -> String:
	for library: String in ["MIKO8_Combat/", "LabActions/", "MIKO8_Crouch/", "LaserPose/", "MIKO8_"]:
		if player.has_animation(library+label): return library+label
	return "MIKO8_Idle"

func _pose(label: String, time: float, restart := false) -> void:
	var full := _clip(label)
	if pose_name != full or restart:
		pose_name = full
		player.play(full, .045)
	# Advance the blend clock even while sampling retimed source keys manually.
	# A zero-only advance leaves entry blends stuck for an entire attack.
	player.advance(1.0/60.0)
	player.seek(time, true)
	player.advance(0)

func _animate(delta: float, axis: float = 0.0) -> void:
	var head := skeleton.find_bone("DEF-head")
	# Some imported clips omit constant head tracks. Restore the unmodified
	# sample before playback so the established lift never accumulates.
	if head >= 0 and head_lift_applied:
		skeleton.set_bone_pose_rotation(head,head_before_lift)
	
	# Procedural spine/torso banking (Prince of Persia style lean)
	var target_lean := 0.0
	if state in ["attack", "parry", "slam"]:
		target_lean = 0.0
	elif state == "dash":
		target_lean = -float(facing) * 0.14
	elif is_on_floor():
		if absf(velocity.x) > 0.20:
			var speed_ratio := clampf(velocity.x / SPEED, -1.0, 1.0)
			if (velocity.x > 0.5 and axis <= 0.0) or (velocity.x < -0.5 and axis >= 0.0):
				# Hard brake skid tilt backward
				target_lean = (velocity.x / SPEED) * 0.08
			else:
				# Athletic sprint forward lean (~7 deg)
				target_lean = -speed_ratio * 0.12
	else:
		# Mid-air trajectory tilt
		target_lean = -clampf(velocity.x / SPEED, -1.0, 1.0) * 0.06
	
	visual.rotation.z = move_toward(visual.rotation.z, target_lean, delta * 3.5)
	
	# Procedural running landing compression (shock absorption dip)
	if is_on_floor() and land_age < 0.08 and absf(velocity.x) > 0.20:
		var dip := (1.0 - land_age / 0.08) * 0.045
		visual.position.y = -dip
	else:
		visual.position.y = 0.0

	if state == "attack":
		var spec: Dictionary = _attack_spec()
		var label: String = spec.clip
		var contact: float = spec.contact
		var end: float = spec.end
		var duration: float = spec.get("finish",player.get_animation(_clip(label)).length)
		var t: float
		if age < _startup(): t = lerpf(float(spec.get("begin",0.0)), contact, age/_startup())
		elif age < _active_end(): t = lerpf(contact, end, (age-_startup())/(_active_end()-_startup()))
		else: t = lerpf(end, duration, clampf((age-_active_end())/(_total_attack()-_active_end()),0,1))
		_pose(label, t)
	elif state == "dash":
		_pose("Dash", lerpf(.02, .38, clampf(age/DASH_TIME,0,1)))
	elif state == "parry":
		# Get to the actual sword-block silhouette during the parry window,
		# then play a shortened return instead of waiting 1.23 seconds.
		var t := lerpf(0,.16,age/.025) if age < .025 else (lerpf(.16,.56,(age-.025)/.145) if age < .17 else lerpf(.56,1.23,(age-.17)/.17))
		_pose("SwordBlock",t)
	elif state == "slam":
		# Hold the overhead anticipation while falling. Contact plays the
		# downward strike (frames 8-11), then compresses the long recovery.
		_pose("GroundPound", lerpf(10.0/30,1.16,clampf(age/.24,0,1)) if slam_landed else minf(2.0/30+age*1.2,8.0/30))
	elif state == "laser":
		var enter_length := player.get_animation(_clip("SpellSingleEnter")).length
		var enter_time := age*2.8
		if enter_time < enter_length:
			_pose("SpellSingleEnter",enter_time)
		else:
			var loop_length := player.get_animation(_clip("SpellSingleIdle")).length
			_pose("SpellSingleIdle",fposmod((age-enter_length/2.8),loop_length))
		_aim_laser_arm()
	elif crouched:
		var enter_length := player.get_animation(_clip("CrouchEnter")).length
		if crouch_time < CROUCH_ENTER_TIME:
			_pose("CrouchEnter", enter_length * crouch_time / CROUCH_ENTER_TIME)
		elif absf(velocity.x) > .12:
			_play_locomotion("CrouchForward",delta*absf(velocity.x)/.713)
		else:
			_pose("CrouchEnter",enter_length)
	elif crouch_exit_time >= 0.0 and is_on_floor():
		_pose("CrouchExit",crouch_exit_time*2.1)
	elif not is_on_floor():
		if jumps == 2 and jump_pose_age < .48: _pose("DoubleJump",jump_pose_age/.48*.9)
		elif air_recovery_age < .16: _pose("AirRecovery",air_recovery_age/.16*.433)
		elif jump_pose_age < .16: _pose("JumpStart", .15+jump_pose_age*1.4)
		else:
			# Tri-phase airborne posing (Ascent, Apex Float, Descent Anticipation)
			if velocity.y > 1.8:
				_pose("JumpAir", fmod(jump_pose_age * 1.2, 2.5))
			elif velocity.y < -2.2:
				_pose("AirIdle", 0.55 + fmod(jump_pose_age * 0.8, 0.45))
			else:
				_pose("AirIdle", fmod(jump_pose_age, 1.0666))
	else:
		# Dual-tier locomotion blending (SwordIdle -> Run -> Sprint)
		var speed := absf(velocity.x)
		var label := "SwordIdle"
		if speed > 4.2:
			label = "Sprint"
		elif speed > 0.20:
			label = "Run"
		
		if label == "SwordIdle" and land_age < .10:
			_pose("JumpLand", .18+land_age*2.0)
		else:
			var full := _clip(label)
			if pose_name != full:
				pose_name = full
				player.play(full, .08)
			var play_rate := 1.0
			if label == "Sprint":
				play_rate = clampf(speed / 7.2, 0.85, 1.35)
			elif label == "Run":
				play_rate = clampf(speed / 3.8, 0.80, 1.40)
			player.advance(delta * play_rate)
	# Preserve the established head lift without accumulating a modifier offset.
	if head >= 0:
		head_before_lift = skeleton.get_bone_pose_rotation(head)
		skeleton.set_bone_pose_rotation(head, head_before_lift*Quaternion(Vector3.RIGHT,deg_to_rad(-30)))
		head_lift_applied = true

func _build_sword() -> void:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = "DEF-hand.R"
	skeleton.add_child(attachment)
	blade = Node3D.new()
	attachment.add_child(blade)
	var index := skeleton.get_bone_rest(skeleton.find_bone("DEF-f_index.01.R")).origin
	var pinky := skeleton.get_bone_rest(skeleton.find_bone("DEF-f_pinky.01.R")).origin
	blade.position = (index+pinky)*.43
	blade.basis = Basis(Quaternion(Vector3.RIGHT,(index-pinky).normalized()))
	var sword_parts: Array[Dictionary] = [
		# Pommel (Kashira) & Gold Ring
		{"type":"box", "size":Vector3(0.032, 0.058, 0.042), "pos":Vector3(-0.125, 0, 0), "rot":Vector3.ZERO, "color":Color("182024")},
		{"type":"box", "size":Vector3(0.012, 0.062, 0.046), "pos":Vector3(-0.108, 0, 0), "rot":Vector3.ZERO, "color":Color("d4af37")},
		# Ergonomic Grip (Tsuka) & Diamond Wraps
		{"type":"box", "size":Vector3(0.185, 0.048, 0.034), "pos":Vector3(-0.010, 0, 0), "rot":Vector3.ZERO, "color":Color("1a2428")},
		{"type":"box", "size":Vector3(0.014, 0.052, 0.038), "pos":Vector3(-0.060, 0, 0), "rot":Vector3.ZERO, "color":Color("2a3c42")},
		{"type":"box", "size":Vector3(0.014, 0.052, 0.038), "pos":Vector3(-0.010, 0, 0), "rot":Vector3.ZERO, "color":Color("2a3c42")},
		{"type":"box", "size":Vector3(0.014, 0.052, 0.038), "pos":Vector3(0.040, 0, 0), "rot":Vector3.ZERO, "color":Color("2a3c42")},
		# Handguard (Tsuba) & Brass Inner Ring
		{"type":"box", "size":Vector3(0.022, 0.145, 0.098), "pos":Vector3(0.092, 0, 0), "rot":Vector3.ZERO, "color":Color("141b1e")},
		{"type":"box", "size":Vector3(0.026, 0.092, 0.066), "pos":Vector3(0.092, 0, 0), "rot":Vector3.ZERO, "color":Color("d4af37")},
		# Blade Collar (Habaki)
		{"type":"box", "size":Vector3(0.034, 0.056, 0.028), "pos":Vector3(0.120, 0, 0), "rot":Vector3.ZERO, "color":Color("ffd24d")},
		# Blade Spine (dark structured back ridge)
		{"type":"box", "size":Vector3(0.880, 0.020, 0.022), "pos":Vector3(0.580, 0.015, 0), "rot":Vector3.ZERO, "color":Color("182d32")},
		# Blade Body (sleek cel steel)
		{"type":"box", "size":Vector3(0.880, 0.036, 0.012), "pos":Vector3(0.580, -0.010, 0), "rot":Vector3.ZERO, "color":Color("9ebbc2")},
		# Razor Cutting Edge (pure white highlight line)
		{"type":"box", "size":Vector3(0.880, 0.008, 0.006), "pos":Vector3(0.580, -0.027, 0), "rot":Vector3.ZERO, "color":Color("ffffff")},
		# Blade Tip (Kissaki) - angled cutting wedge
		{"type":"prism", "size":Vector3(0.050, 0.140, 0.012), "pos":Vector3(1.085, -0.007, 0), "rot":Vector3(0, 0, -PI*0.5), "color":Color("9ebbc2")},
		# Kissaki White Cutting Edge Tip
		{"type":"prism", "size":Vector3(0.018, 0.140, 0.006), "pos":Vector3(1.085, -0.023, 0), "rot":Vector3(0, 0, -PI*0.5), "color":Color("ffffff")}
	]
	for p: Dictionary in sword_parts:
		var mesh_inst := MeshInstance3D.new()
		if p.type == "box":
			var box := BoxMesh.new()
			box.size = p.size
			mesh_inst.mesh = box
		elif p.type == "prism":
			var prism := PrismMesh.new()
			prism.size = p.size
			mesh_inst.mesh = prism
		mesh_inst.position = p.pos
		mesh_inst.rotation = p.rot
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/lab_sword.gdshader")
		mat.set_shader_parameter("tint",p.color)
		blade_materials.append(mat)
		mesh_inst.material_override = mat
		blade.add_child(mesh_inst)
	trail = ImmediateMesh.new()
	var ribbon := MeshInstance3D.new()
	ribbon.mesh = trail
	ribbon.top_level = true
	ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://shaders/blade_trail.gdshader")
	paint.set_shader_parameter("style_mode", SWORD_STYLES[sword_style].style_mode)
	ribbon_mat = paint
	blade_materials.append(paint)
	ribbon.material_override = paint
	add_child(ribbon)
	ribbon.global_transform = Transform3D.IDENTITY

func _update_sword_walls() -> void:
	if sword_bulkheads.is_empty():
		return
	var left := Vector3(-10000,0,0)
	var right := Vector3(10000,0,0)
	var p := global_position
	for wall in sword_bulkheads:
		if p.y + 3.0 < wall.position.y or p.y - 2.0 > wall.end.y:
			continue
		if wall.end.x <= p.x and wall.end.x > left.x and p.x-wall.end.x < 4.0:
			left = Vector3(wall.end.x,wall.position.y,wall.end.y)
		elif wall.position.x >= p.x and wall.position.x < right.x and wall.position.x-p.x < 4.0:
			right = Vector3(wall.position.x,wall.position.y,wall.end.y)
	if left == sword_wall_left and right == sword_wall_right:
		return
	sword_wall_left = left
	sword_wall_right = right
	for material in blade_materials:
		material.set_shader_parameter("wall_left",left)
		material.set_shader_parameter("wall_right",right)

func _sword_particle_behind_wall(point: Vector3) -> bool:
	return (point.x < sword_wall_left.x and point.y >= sword_wall_left.y and point.y <= sword_wall_left.z
		or point.x > sword_wall_right.x and point.y >= sword_wall_right.y and point.y <= sword_wall_right.z)

func set_sword_style(index: int) -> void:
	sword_style = clampi(index, 0, SWORD_STYLES.size() - 1)
	var style: Dictionary = SWORD_STYLES[sword_style]
	if ribbon_mat:
		ribbon_mat.set_shader_parameter("style_mode", style.style_mode)
	sword_style_changed.emit(sword_style, style.name, style.desc)

func next_sword_style() -> void:
	set_sword_style((sword_style + 1) % SWORD_STYLES.size())

func prev_sword_style() -> void:
	set_sword_style((sword_style - 1 + SWORD_STYLES.size()) % SWORD_STYLES.size())

func _catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)

func _update_trail() -> void:
	trail.clear_surfaces()
	var cur_style: Dictionary = SWORD_STYLES[sword_style]
	var trail_life: float = cur_style.get("life", 0.11)
	for i in range(trail_ages.size()):
		trail_ages[i] += 1.0 / 60.0
	while not trail_ages.is_empty() and trail_ages[0] > trail_life:
		trail_ages.pop_front()
		trail_edges.pop_front()
		trail_edges.pop_front()
	if state == "attack" and age >= _startup() * 0.35 and age <= _active_end() + 0.035:
		var hand_bone: int = skeleton.find_bone("DEF-hand.R")
		var hand_xf: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(hand_bone)
		var sword_xf: Transform3D = hand_xf * blade.transform
		var base_pos: Vector3 = sword_xf * Vector3(float(cur_style.get("swath_base", 0.46)), -0.015, 0.0)
		var tip_pos: Vector3 = sword_xf * Vector3(float(cur_style.get("swath_tip", 1.20)), -0.020, 0.0)
		base_pos.z = 0.35
		tip_pos.z = 0.35
		trail_edges.append(base_pos)
		trail_edges.append(tip_pos)
		trail_ages.append(0.0)
		var is_finisher_hit: bool = (combo == 2 and not attack_in_air)
		var spark_count: int = int(cur_style.get("spark_count", 1)) * (2 if is_finisher_hit else 1)
		for s in range(spark_count):
			_spawn_style_particle(base_pos, tip_pos, cur_style, is_finisher_hit)
	var count := trail_ages.size()
	if count < 2:
		return
	var sub_steps := 5
	var total_steps := (count - 1) * sub_steps
	if total_steps < 1:
		return
	var is_finisher: bool = (combo == 2 and not attack_in_air)
	trail.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for seg in range(count - 1):
		var p0_b: Vector3 = trail_edges[maxi(0, seg - 1) * 2]
		var p1_b: Vector3 = trail_edges[seg * 2]
		var p2_b: Vector3 = trail_edges[(seg + 1) * 2]
		var p3_b: Vector3 = trail_edges[mini(count - 1, seg + 2) * 2]
		var p0_t: Vector3 = trail_edges[maxi(0, seg - 1) * 2 + 1]
		var p1_t: Vector3 = trail_edges[seg * 2 + 1]
		var p2_t: Vector3 = trail_edges[(seg + 1) * 2 + 1]
		var p3_t: Vector3 = trail_edges[mini(count - 1, seg + 2) * 2 + 1]
		var a1: float = trail_ages[seg]
		var a2: float = trail_ages[seg + 1]
		for step in range(sub_steps if seg < count - 2 else sub_steps + 1):
			var s := float(step) / float(sub_steps)
			var cur_b := _catmull(p0_b, p1_b, p2_b, p3_b, s)
			var cur_t := _catmull(p0_t, p1_t, p2_t, p3_t, s)
			var cur_age := lerpf(a1, a2, s)
			var u := float(seg * sub_steps + step) / float(total_steps)
			var alpha := clampf(1.0 - (cur_age / trail_life), 0.0, 1.0)
			var tint := Color(1.0, 0.85, 0.30, alpha) if is_finisher else Color(1.0, 1.0, 1.0, alpha)
			trail.surface_set_color(tint)
			trail.surface_set_uv(Vector2(u, 0.0))
			trail.surface_add_vertex(cur_b)
			trail.surface_set_color(tint)
			trail.surface_set_uv(Vector2(u, 1.0))
			trail.surface_add_vertex(cur_t)
	trail.surface_end()

func _spawn_dash_ghost() -> void:
	if not model or not skeleton: return
	while dash_ghosts.size() >= 8:
		var oldest: Dictionary = dash_ghosts.pop_front()
		if is_instance_valid(oldest.get("node")):
			oldest.node.queue_free()
	var ghost_root := Node3D.new()
	add_child(ghost_root)
	ghost_root.top_level = true
	ghost_root.global_position = global_position
	ghost_root.rotation.y = visual.rotation.y
	
	var dup: Node3D = model.duplicate()
	ghost_root.add_child(dup)
	
	var dup_skel: Skeleton3D = dup.find_children("*", "Skeleton3D", true, false)[0]
	for b in range(skeleton.get_bone_count()):
		dup_skel.set_bone_pose_position(b, skeleton.get_bone_pose_position(b))
		dup_skel.set_bone_pose_rotation(b, skeleton.get_bone_pose_rotation(b))
		dup_skel.set_bone_pose_scale(b, skeleton.get_bone_pose_scale(b))
	
	var mat := ShaderMaterial.new()
	mat.shader = ghost_shader
	mat.set_shader_parameter("alpha_fade", 0.20)
	for m: MeshInstance3D in dup.find_children("*", "MeshInstance3D", true, false):
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	dash_ghosts.append({
		"node": ghost_root,
		"mat": mat,
		"life": 0.22,
		"max_life": 0.22
	})

func _spawn_style_particle(base_pos: Vector3, tip_pos: Vector3, style: Dictionary, is_finisher: bool) -> void:
	while falling_sparks.size() >= 40:
		var oldest: Dictionary = falling_sparks.pop_front()
		if is_instance_valid(oldest.get("node")):
			oldest.node.queue_free()
	
	var ptype: String = style.get("spark_type", "white_spark")
	var inst := MeshInstance3D.new()
	inst.top_level = true
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var mat: StandardMaterial3D = spark_mat_white
	var mesh: Mesh = spark_mesh
	var life_time := randf_range(0.42, 0.58)
	
	match ptype:
		"smoke_puff":
			mesh = smoke_mesh
			mat = spark_mat_smoke
			life_time = randf_range(0.35, 0.52)
		"electric_spark":
			mesh = spark_mesh
			mat = (spark_mat_cyan if randf() > 0.35 else spark_mat_white) if not is_finisher else spark_mat_gold
			life_time = randf_range(0.28, 0.44)
		"molten_ember":
			mesh = smoke_mesh
			mat = spark_mat_fire if randf() > 0.35 else spark_mat_gold
			life_time = randf_range(0.50, 0.72)
		"ink_splat":
			mesh = spark_mesh
			mat = spark_mat_ink
			life_time = randf_range(0.55, 0.80)
		"spirit_mote":
			mesh = smoke_mesh
			mat = spark_mat_spirit if randf() > 0.4 else spark_mat_cyan
			life_time = randf_range(0.48, 0.68)
		"dust_debris":
			mesh = spark_mesh
			mat = spark_mat_dust
			life_time = randf_range(0.38, 0.55)
		"cyber_bit":
			mesh = spark_mesh
			mat = spark_mat_magenta if randf() > 0.5 else spark_mat_cyan
			life_time = randf_range(0.30, 0.48)
		"sakura_petal":
			mesh = spark_mesh
			mat = spark_mat_sakura
			life_time = randf_range(0.60, 0.95)
		"supernova_cascade":
			mesh = spark_mesh if randf() > 0.45 else smoke_mesh
			mat = spark_mat_gold if randf() > 0.3 else spark_mat_white
			life_time = randf_range(0.48, 0.70)
		_: # "white_spark"
			mesh = spark_mesh
			mat = spark_mat_gold if is_finisher else spark_mat_white
			life_time = randf_range(0.42, 0.58)

	inst.mesh = mesh
	inst.material_override = mat
	
	var t_pos := randf_range(0.25, 1.0)
	var spawn_pt := base_pos.lerp(tip_pos, t_pos) + Vector3(randf_range(-0.02, 0.02), randf_range(-0.02, 0.02), 0.0)
	spawn_pt.z = 0.25
	if _sword_particle_behind_wall(spawn_pt):
		inst.free()
		return
	inst.position = spawn_pt
	
	var blade_dir := (tip_pos - base_pos).normalized()
	var tangent := Vector3(-blade_dir.y, blade_dir.x, 0.0) * float(facing)
	var sp_vel := tangent * randf_range(1.8, 4.2) + Vector3(randf_range(-0.8, 0.8), randf_range(0.2, 2.2), 0.0)
	if ptype == "smoke_puff":
		sp_vel = tangent * randf_range(0.6, 1.8) + Vector3(randf_range(-0.4, 0.4), randf_range(0.4, 1.4), 0.0)
	elif ptype == "sakura_petal":
		sp_vel = tangent * randf_range(0.8, 2.2) + Vector3(randf_range(-0.5, 0.5), randf_range(0.2, 1.2), 0.0)
	elif ptype == "cyber_bit":
		sp_vel = tangent * randf_range(2.5, 5.0) + Vector3(randf_range(-1.0, 1.0), randf_range(-0.5, 2.0), 0.0)
	
	inst.rotation.z = atan2(sp_vel.y, sp_vel.x)
	add_child(inst)
	
	falling_sparks.append({
		"node": inst,
		"velocity": sp_vel,
		"life": life_time,
		"max_life": life_time,
		"type": ptype,
		"sway_age": randf_range(0.0, PI * 2.0),
		"drift_x": randf_range(-0.3, 0.3),
		"seed": randf()
	})

func _spawn_falling_spark(base_pos: Vector3, tip_pos: Vector3, is_gold: bool) -> void:
	_spawn_style_particle(base_pos, tip_pos, SWORD_STYLES[sword_style], is_gold)

func _install_polarity_poses() -> void:
	preload("res://scripts/animation_bank.gd").install(player,skeleton,"res://models/MIKO8_Crouch.json")
	var library := preload("res://models/MIKO8_LaserPose.res").duplicate(true) as AnimationLibrary
	var path := str(player.get_node(player.root_node).get_path_to(skeleton))
	for name in library.get_animation_list():
		var animation := library.get_animation(name)
		for track in range(animation.get_track_count()-1,-1,-1):
			var bone_path := animation.track_get_path(track)
			if bone_path.get_subname_count() != 1 or skeleton.find_bone(bone_path.get_subname(0)) < 0:
				animation.remove_track(track)
			else:
				animation.track_set_path(track,NodePath(path+":"+str(bone_path.get_subname(0))))
	player.add_animation_library("LaserPose",library)
	laser_hand = skeleton.find_bone("DEF-hand.L")
	laser_forearm = skeleton.find_bone("DEF-forearm.L")
	laser_upper_arm = skeleton.find_bone("DEF-upper_arm.L")

func _play_locomotion(label: String, delta: float) -> void:
	var full := _clip(label)
	if pose_name != full:
		pose_name = full
		player.play(full,.08)
	player.advance(delta)

func _set_suit_pole(value: int) -> void:
	suit_polarity = value
	for material in suit_materials:
		material.set_shader_parameter("polarity",value)

func _set_crouched(low: bool) -> void:
	if crouched == low:
		return
	crouched = low
	body_collision.shape = crouch_shape if low else stand_shape
	body_collision.position.y = body_collision.shape.height*.5
	crouch_time = 0.0
	crouch_exit_time = -1.0 if low else 0.0

func _update_crouch(delta: float, grounded: bool, vertical: float, horizontal: float) -> void:
	var held := vertical < -.5
	if crouched and (not held or buffers.jump > 0):
		stand_query.transform = Transform3D(Basis.IDENTITY,global_position+Vector3.UP*(stand_shape.height*.5+.025))
		if get_world_3d().direct_space_state.intersect_shape(stand_query,1).is_empty():
			_set_crouched(false)
	elif not crouched and held and grounded and state == "move" and buffers.jump <= 0:
		_set_crouched(true)
	if crouched:
		crouch_time += delta
	look_down_time = look_down_time + delta if crouched and grounded and held else 0.0
	if crouch_exit_time >= 0.0:
		crouch_exit_time += delta
		# Let the locomotion pose take over as soon as movement starts.
		if absf(horizontal) > .15 or crouch_exit_time >= .39:
			crouch_exit_time = -1.0

func _combat_buffered() -> bool:
	return buffers.jump > 0 or buffers.dash > 0 or buffers.attack > 0 or buffers.parry > 0

func _requested_laser() -> int:
	var red := Input.get_action_raw_strength("laser_red")
	var blue := Input.get_action_raw_strength("laser_blue")
	if maxf(red,blue) < .4:
		return 0
	if is_equal_approx(red,blue) and laser_pole != 0:
		return laser_pole
	return 1 if red >= blue else 2

func _update_laser_direction() -> void:
	var aim := Input.get_vector("laser_aim_left","laser_aim_right","laser_aim_down","laser_aim_up")
	var manual_aim := aim.length_squared() >= .01
	if not manual_aim:
		aim = Vector2(facing,0)
	elif absf(aim.x) > .15:
		facing = 1 if aim.x > 0 else -1
	var free_direction := Vector3(aim.x,aim.y,0).normalized()
	var origin := global_position + Vector3(facing*.3,1.12,0)
	laser_direction = laser.resolve_aim(origin,free_direction,laser_pole,manual_aim)

func _aim_laser_arm() -> void:
	if laser_hand < 0 or laser_forearm < 0 or laser_upper_arm < 0:
		return
	var current := skeleton.get_bone_global_pose(laser_hand).origin-skeleton.get_bone_global_pose(laser_forearm).origin
	if current.length_squared() < .00001:
		return
	var desired := (skeleton.global_basis.inverse()*laser_direction).normalized()
	var pose := skeleton.get_bone_global_pose(laser_upper_arm)
	pose.basis = Basis(Quaternion(current.normalized(),desired))*pose.basis
	skeleton.set_bone_global_pose(laser_upper_arm,pose)

func _update_laser_beam(delta: float) -> void:
	if not laser:
		return
	if laser_pole == 0:
		if laser.visible or is_instance_valid(laser.locked_target): laser.stop()
		return
	var palm := skeleton.to_global(skeleton.get_bone_global_pose(laser_hand).origin)
	laser.tick(delta,palm+laser_direction*.11,laser_direction,laser_pole)
