extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_layer: AnimatedSprite2D = $BodyLayer
@onready var arm_l_pivot: Node2D = $ArmLPivot
@onready var arm_r_pivot: Node2D = $ArmRPivot
@onready var arm_l: AnimatedSprite2D = $ArmLPivot/ArmL
@onready var arm_r: AnimatedSprite2D = $ArmRPivot/ArmR
@onready var arm_l_parts: Array = [$ArmLPivot/Upper, $ArmLPivot/Forearm, $ArmLPivot/Hand]
@onready var arm_r_parts: Array = [$ArmRPivot/Upper, $ArmRPivot/Forearm, $ArmRPivot/Hand]
@onready var beam: Line2D = $AimBeam
@onready var beam_glow: Line2D = $BeamGlow
@onready var beam_core: Line2D = get_node_or_null("BeamCore")
@onready var beam_r: Line2D = get_node_or_null("AimBeamR")
@onready var beam_glow_r: Line2D = get_node_or_null("AimBeamGlowR")
@onready var beam_core_r: Line2D = get_node_or_null("BeamCoreR")
@onready var plasma_reticle: Node2D = get_node_or_null("PlasmaReticle")
@onready var sparkles: CPUParticles2D = $BeamSparkles
@onready var raycast: RayCast2D = $AimRayCast
@onready var muzzle_light: PointLight2D = get_node_or_null("MuzzleLight")
@onready var thruster_light: PointLight2D = get_node_or_null("ThrusterLight")
@onready var wrist_led_l: PointLight2D = get_node_or_null("WristLedL")
@onready var wrist_led_r: PointLight2D = get_node_or_null("WristLedR")
@onready var thruster_blast: CPUParticles2D = get_node_or_null("ThrusterBlast")
@onready var landing_dust: CPUParticles2D = get_node_or_null("LandingDust")
@onready var death_sparks: CPUParticles2D = $DeathSparks
@onready var death_smoke: CPUParticles2D = $DeathSmoke
@onready var thruster_trail: CPUParticles2D = get_node_or_null("ThrusterTrail")
@onready var shadow: Sprite2D = get_node_or_null("Shadow")

var wrist_pos_l: Vector2 = Vector2.ZERO
var wrist_pos_r: Vector2 = Vector2.ZERO
var plasma_flash_timer: float = 0.0
var plasma_aiming: bool = false

const MOVE_SPEED: float = 340.0
const JUMP_SPEED: float = -520.0
const JUMP_GRAVITY: float = 980.0
const FALL_GRAVITY: float = 1450.0
const FAST_FALL_GRAVITY: float = 2100.0
const JUMP_CUT_DECEL: float = 1200.0

const COYOTE_TIME_MAX: float = 0.10
const JUMP_BUFFER_MAX: float = 0.12
const DASH_SPEED: float = 780.0
const DASH_DURATION: float = 0.24

const FEET_Y_OFFSET: float = 48.0
const BASE_SPRITE_SCALE: Vector2 = Vector2(0.364, 0.364)

const DEFAULT_BEAM_LENGTH: float = 200.0
const TAG_BEAM_REACH: float = 200.0
const MIN_BEAM_LENGTH: float = 35.0
const MAX_BEAM_LENGTH: float = 1400.0
const BEAM_LENGTH_SPEED: float = 750.0
const MOUSE_LENGTH_SENSITIVITY: float = 2.4
const MOUSE_ANGLE_SENSITIVITY: float = 0.32
const ARM_RAISE_SPEED: float = 2.8
const MAX_AIM_ELEVATION: float = 88.0
const MIN_AIM_ELEVATION: float = -88.0
const PLASMA_SPEED: float = 1100.0
const PLASMA_SCENE: PackedScene = preload("res://scenes/plasma_projectile.tscn")
const QUICK_BLASTER_SCENE: PackedScene = preload("res://scenes/quick_blaster_bolt.tscn")
const SUIT_EYE_SHADER: Shader = preload("res://shaders/suit_eyes.gdshader")

enum SuitPolarity { NEUTRAL, RED, BLUE }
@export var polarity_enabled: bool = false
var suit_polarity: SuitPolarity = SuitPolarity.NEUTRAL
var eye_materials: Array[ShaderMaterial] = []
var controller_id: int = -1
var controller_aiming: bool = false
var controller_aim_mode: int = 0
const CONTROLLER_STICK_DEADZONE: float = 0.20
const CONTROLLER_AIM_DEADZONE: float = 0.38
const CONTROLLER_AIM_SPEED: float = 65.0
const CONTROLLER_REACH_SPEED: float = 520.0
const CONTROLLER_LASER_START_REACH: float = 200.0
const CONTROLLER_PLASMA_START_REACH: float = 55.0
const CONTROLLER_TURN_HOLD: float = 0.22
var controller_turn_progress: float = 0.0
var latched_fixture: Area2D = null
var fixture_launch_lockout: float = 0.0
const FIXTURE_LAUNCH_SPEED: float = 900.0
const FIXTURE_LAUNCH_ANIMATION_TIME: float = 12.0 / 30.0
var fixture_launch_animation_time: float = 0.0
var pending_fixture_launch: bool = false
var fixture_detaching: bool = false

enum ReactionState { NORMAL, DYING, HURT }
var reaction_state: ReactionState = ReactionState.NORMAL
var reaction_time: float = 0.0
var reaction_origin: Vector2 = Vector2.ZERO
var death_landed: bool = false
var death_impact_time: float = 0.0
var exhaust_effect: Node2D = null

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
var lock_intensity: float = 0.0
var locked_target: Object = null
var aim_anchors: Dictionary = {}
var layer_points: Dictionary = {}
var aim_l_progress: float = 0.0
var aim_r_progress: float = 0.0
var plasma_progress: float = 0.0
var plasma_was_down: bool = false
var plasma_controller_armed: bool = false
var plasma_fired: bool = false
var plasma_active: bool = false
var quick_blaster_was_down: bool = false
var quick_blaster_cooldown: float = 0.0
var hand_l: Vector2 = Vector2.ZERO
var hand_r: Vector2 = Vector2.ZERO
var dash_left: float = 0.0
var dash_ready: bool = true
var is_jumping: bool = false
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_was_down: bool = false
var dash_was_down: bool = false
var previous_direction: int = 0
var was_on_floor: bool = false
var has_touched_floor: bool = false
var squash_stretch: Vector2 = Vector2(1.0, 1.0)
var squash_stretch_velocity: Vector2 = Vector2.ZERO

enum LadderState { NONE, MOUNTING, CLIMBING, IDLE, DISMOUNTING }
var ladder_state: LadderState = LadderState.NONE
var active_ladder: Area2D = null
var nearby_ladder: Area2D = null
const LADDER_TOP_DISMOUNT_MARGIN: float = 24.0

func register_ladder(ladder: Area2D) -> void:
	nearby_ladder = ladder

func unregister_ladder(ladder: Area2D) -> void:
	if nearby_ladder == ladder:
		nearby_ladder = null

func _find_nearby_ladder() -> Area2D:
	if nearby_ladder != null and is_instance_valid(nearby_ladder):
		return nearby_ladder
	for node in get_tree().get_nodes_in_group("ladders"):
		if node is Area2D:
			var lad_height: float = node.ladder_height if "ladder_height" in node else 290.0
			var dx: float = absf(global_position.x - node.global_position.x)
			# Include the standing player's centre above the top platform.
			var y_min: float = node.global_position.y - lad_height * 0.5 - 64.0
			var y_max: float = node.global_position.y + lad_height * 0.5 + 40.0
			if dx < 48.0 and global_position.y >= y_min and global_position.y <= y_max:
				return node
	return null

func _ready() -> void:
	add_to_group("magnetic_suit")
	reaction_origin = global_position
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var anchors_text: String = FileAccess.get_file_as_string("res://sprites/aim_anchors.json")
	var parsed: Variant = JSON.parse_string(anchors_text)
	if parsed is Dictionary:
		aim_anchors = parsed
	var layer_text: String = FileAccess.get_file_as_string("res://layers/layer_points.json")
	var layer_parsed: Variant = JSON.parse_string(layer_text)
	if layer_parsed is Dictionary:
		layer_points = layer_parsed
	if shadow != null:
		shadow.top_level = true
		shadow.z_index = 0
	sprite.flip_h = false
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(&"idle")
	# Reverse the existing rendered mount: release the grip, lower the arms
	# and turn back to the current facing without a sprite crossfade.
	sprite.sprite_frames = sprite.sprite_frames.duplicate()
	for side in ["right", "left"]:
		var mount := StringName("ladder_mount_" + side)
		var release := StringName("ladder_dismount_" + side)
		sprite.sprite_frames.add_animation(release)
		sprite.sprite_frames.set_animation_loop(release, false)
		sprite.sprite_frames.set_animation_speed(release, 24.0)
		for index in range(sprite.sprite_frames.get_frame_count(mount) - 1, -1, -1):
			sprite.sprite_frames.add_frame(release, sprite.sprite_frames.get_frame_texture(mount, index))
	sprite.sprite_frames.add_animation(&"death")
	sprite.sprite_frames.set_animation_loop(&"death", false)
	sprite.sprite_frames.set_animation_speed(&"death", 20.0)
	for index in range(20):
		var path: String = "res://sprites/death/death_%03d.png" % index
		sprite.sprite_frames.add_frame(&"death", load(path))
	for clip in [&"death_fall", &"death_impact"]:
		sprite.sprite_frames.add_animation(clip)
		sprite.sprite_frames.set_animation_loop(clip, false)
		sprite.sprite_frames.set_animation_speed(clip, 20.0)
	for index in range(8):
		sprite.sprite_frames.add_frame(&"death_fall", sprite.sprite_frames.get_frame_texture(&"death", index))
	for index in range(8, 20):
		sprite.sprite_frames.add_frame(&"death_impact", sprite.sprite_frames.get_frame_texture(&"death", index))
	sprite.sprite_frames.add_animation(&"knockback")
	sprite.sprite_frames.set_animation_loop(&"knockback", false)
	sprite.sprite_frames.set_animation_speed(&"knockback", 20.0)
	for index in range(18):
		var path: String = "res://sprites/knockback/knockback_%03d.png" % index
		sprite.sprite_frames.add_frame(&"knockback", load(path))
	for clip in [&"charge_attach", &"charge_release", &"charge_launch"]:
		sprite.sprite_frames.add_animation(clip)
		sprite.sprite_frames.set_animation_loop(clip, false)
		sprite.sprite_frames.set_animation_speed(clip, 30.0)
		var count: int = 14 if clip == &"charge_attach" else (10 if clip == &"charge_release" else 12)
		for index in range(count):
			var path: String = "res://sprites/%s/%s_%03d.png" % [clip, clip, index]
			sprite.sprite_frames.add_frame(clip, load(path))
	raycast.add_exception(self)
	exhaust_effect = Node2D.new()
	exhaust_effect.name = "ProceduralExhaust"
	exhaust_effect.set_script(preload("res://scripts/procedural_exhaust.gd"))
	add_child(exhaust_effect)
	for art in [sprite, body_layer]:
		var eye_material := ShaderMaterial.new()
		eye_material.shader = SUIT_EYE_SHADER
		art.material = eye_material
		eye_materials.append(eye_material)
	if plasma_reticle != null:
		var targeting_layer := CanvasLayer.new()
		targeting_layer.name = "TargetingOverlay"
		targeting_layer.layer = 11
		targeting_layer.follow_viewport_enabled = true
		add_child(targeting_layer)
		plasma_reticle.reparent(targeting_layer, false)
	_update_suit_polarity_visuals()

func _unhandled_input(event: InputEvent) -> void:
	# Temporary sandbox trigger until hazards are wired up.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			die()
		elif event.keycode == KEY_H:
			take_damage(Vector2(float(-facing) * 270.0, 0.0))
		elif event.keycode == KEY_C and polarity_enabled:
			_cycle_suit_polarity()
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B and ladder_state == LadderState.NONE and _find_nearby_ladder() == null:
		_cycle_suit_polarity()
	if event is InputEventJoypadButton and event.pressed and polarity_enabled:
		if event.button_index == JOY_BUTTON_Y:
			_toggle_suit_polarity(SuitPolarity.RED)
		elif event.button_index == JOY_BUTTON_X:
			_toggle_suit_polarity(SuitPolarity.BLUE)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	if event is InputEventMouseMotion:
		var is_plasma: bool = plasma_aiming or Input.is_key_pressed(KEY_F) or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
		var is_aiming: bool = is_plasma or aim_side != &"" or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_E)
		if is_aiming:
			# Laser length is controlled by horizontal mouse movement (for single laser)
			if not is_plasma:
				var forward_delta: float = event.relative.x * float(visual_facing)
				var new_length: float = current_beam_length + forward_delta * MOUSE_LENGTH_SENSITIVITY
				if new_length < MIN_BEAM_LENGTH * 0.4 and not turning:
					_begin_aim_turn()
				elif not turning:
					current_beam_length = clampf(new_length, MIN_BEAM_LENGTH, MAX_BEAM_LENGTH)

			# Vertical mouse movement tilts arm and beam elevation up and down
			aim_angle_degrees = clampf(aim_angle_degrees - event.relative.y * MOUSE_ANGLE_SENSITIVITY, MIN_AIM_ELEVATION, MAX_AIM_ELEVATION)

func _on_animation_finished() -> void:
	if reaction_state != ReactionState.NORMAL:
		return
	if fixture_detaching:
		fixture_detaching = false
		sprite.play(_faced_clip(&"idle"))
	elif ladder_state == LadderState.DISMOUNTING:
		ladder_state = LadderState.NONE
		active_ladder = null
		velocity = Vector2.ZERO
		sprite.play(_faced_clip(&"idle"))
	elif ladder_state == LadderState.MOUNTING:
		ladder_state = LadderState.IDLE
		sprite.play(&"ladder_idle")
	elif aim_lowering:
		aim_side = &""
		aim_lowering = false
	elif turning:
		visual_facing = turn_target
		facing = turn_target
		turning = false
	elif transition != &"":
		transition = &""

func _faced_clip(base: StringName) -> StringName:
	return StringName(str(base) + ("_left" if visual_facing < 0 else ""))

func _cycle_suit_polarity() -> void:
	var next_pole: int = (int(suit_polarity) + 1) % 3
	if latched_fixture != null and is_instance_valid(latched_fixture):
		next_pole = int(latched_fixture.get("polarity"))
	set_suit_polarity(next_pole)

func _toggle_suit_polarity(pole: SuitPolarity) -> void:
	set_suit_polarity(SuitPolarity.NEUTRAL if suit_polarity == pole else pole)

func _begin_aim_turn() -> void:
	if turning:
		return
	turn_target = -visual_facing
	turning = true
	controller_turn_progress = 0.0
	current_beam_length = MIN_BEAM_LENGTH
	sprite.play(&"turn_to_left" if turn_target < 0 else &"turn_to_right")

func _pad_button(button: JoyButton) -> bool:
	return controller_id >= 0 and Input.is_joy_button_pressed(controller_id, button)

func _pad_axis(axis: JoyAxis) -> float:
	return Input.get_joy_axis(controller_id, axis) if controller_id >= 0 else 0.0

func _ladder_mount_requested(climb_up: bool, climb_down: bool, at_top_ledge: bool) -> bool:
	return (climb_down and at_top_ledge) or (climb_up and not at_top_ledge)

func _nearest_tag_target(origin: Vector2, forward: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = TAG_BEAM_REACH + 1.0
	for candidate in get_tree().get_nodes_in_group("crates") + get_tree().get_nodes_in_group("launch_fixtures") + get_tree().get_nodes_in_group("magnetic_anchors"):
		if not (candidate is CollisionObject2D) or not candidate.has_method("set_locked_on"):
			continue
		var offset: Vector2 = candidate.global_position - (global_position + origin)
		var distance: float = offset.length()
		if distance < 1.0 or distance > TAG_BEAM_REACH or distance >= best_distance:
			continue
		if offset.normalized().dot(forward) < 0.45:
			continue
		var query := PhysicsRayQueryParameters2D.create(global_position + origin, candidate.global_position, 3, [get_rid()])
		query.collide_with_areas = true
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		if hit.get("collider") == candidate:
			best_distance = distance
			best = {"target": candidate, "point": to_local(hit.position), "normal": hit.normal}
	return best

func _position_reticle(endpoint: Vector2) -> void:
	if plasma_reticle != null:
		plasma_reticle.position = global_position + endpoint

func _apply_controller_aim(stick: Vector2, delta: float) -> void:
	if turning or stick.length() <= CONTROLLER_AIM_DEADZONE:
		controller_turn_progress = 0.0
		return
	var elevation_input: float = _controller_axis_curve(stick.y)
	aim_angle_degrees = clampf(aim_angle_degrees - elevation_input * CONTROLLER_AIM_SPEED * delta, MIN_AIM_ELEVATION, MAX_AIM_ELEVATION)
	var reach_input: float = _controller_axis_curve(stick.x * float(visual_facing))
	if reach_input < 0.0 and current_beam_length <= MIN_BEAM_LENGTH + 0.01 and controller_aim_mode != 3:
		controller_turn_progress += -reach_input * delta
		if controller_turn_progress >= CONTROLLER_TURN_HOLD:
			_begin_aim_turn()
	else:
		controller_turn_progress = 0.0
	var reach_speed: float = CONTROLLER_REACH_SPEED * lerpf(0.45, 1.0, clampf(current_beam_length / MAX_BEAM_LENGTH, 0.0, 1.0))
	current_beam_length = clampf(current_beam_length + reach_input * reach_speed * delta, MIN_BEAM_LENGTH, MAX_BEAM_LENGTH)

func _controller_axis_curve(value: float) -> float:
	var amount: float = clampf((absf(value) - CONTROLLER_AIM_DEADZONE) / (1.0 - CONTROLLER_AIM_DEADZONE), 0.0, 1.0)
	return signf(value) * amount * amount

func set_suit_polarity(value: int) -> void:
	if not polarity_enabled or reaction_state != ReactionState.NORMAL:
		return
	var next_polarity: int = clampi(value, 0, 2)
	var should_launch: bool = latched_fixture != null and is_instance_valid(latched_fixture) and next_polarity == int(latched_fixture.get("polarity"))
	suit_polarity = next_polarity
	_update_suit_polarity_visuals()
	if should_launch:
		if not is_on_floor() or (sprite.animation == &"charge_attach" and sprite.frame < 13):
			pending_fixture_launch = true
		else:
			_launch_from_fixture()
	elif latched_fixture != null and (next_polarity == 0 or not is_instance_valid(latched_fixture) or next_polarity != 3 - int(latched_fixture.get("polarity"))):
		latched_fixture = null
		pending_fixture_launch = false
		fixture_detaching = true
		if sprite.animation == &"charge_attach":
			sprite.play(&"charge_release")

func _launch_from_fixture() -> void:
	if latched_fixture == null:
		return
	pending_fixture_launch = false
	if latched_fixture.has_method("trigger_launch"):
		latched_fixture.trigger_launch()
	latched_fixture = null
	fixture_launch_lockout = 0.35
	fixture_launch_animation_time = FIXTURE_LAUNCH_ANIMATION_TIME
	velocity = Vector2(velocity.x * 0.3, -FIXTURE_LAUNCH_SPEED)
	is_jumping = true
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	dash_left = 0.0
	if thruster_blast != null:
		thruster_blast.restart()
		thruster_blast.emitting = true
	sprite.play(&"charge_launch")

func _update_fixture_latch() -> void:
	if pending_fixture_launch and latched_fixture != null and is_instance_valid(latched_fixture):
		return
	if not polarity_enabled or suit_polarity == SuitPolarity.NEUTRAL or fixture_launch_lockout > 0.0:
		latched_fixture = null
		return
	latched_fixture = null
	for fixture in get_tree().get_nodes_in_group("launch_fixtures"):
		if not (fixture is Area2D) or int(fixture.get("polarity")) == 0 or int(fixture.get("polarity")) == int(suit_polarity):
			continue
		var offset: Vector2 = global_position - fixture.global_position
		if absf(offset.x) <= 56.0 and offset.y >= -170.0 and offset.y <= -25.0:
			if latched_fixture == null:
				turning = false
				dash_left = 0.0
				squash_stretch = Vector2.ONE
				squash_stretch_velocity = Vector2.ZERO
			latched_fixture = fixture as Area2D
			break

func _update_suit_polarity_visuals() -> void:
	var active: int = int(suit_polarity) if polarity_enabled and reaction_state != ReactionState.DYING else 0
	for material in eye_materials:
		material.set_shader_parameter("polarity", active)
	if thruster_light != null:
		match active:
			1: thruster_light.color = Color(1.0, 0.18, 0.26)
			2: thruster_light.color = Color(0.16, 0.67, 1.0)
			_: thruster_light.color = Color(0.32, 0.70, 1.0)

func take_damage(knockback: Vector2) -> void:
	if reaction_state != ReactionState.NORMAL:
		return
	reaction_state = ReactionState.HURT
	reaction_time = 0.0
	velocity = knockback
	latched_fixture = null
	pending_fixture_launch = false
	fixture_launch_animation_time = 0.0
	ladder_state = LadderState.NONE
	active_ladder = null
	dash_left = 0.0
	turning = false
	transition = &""
	_clear_locked_target(false)
	aim_side = &""
	aim_l_progress = 0.0
	aim_r_progress = 0.0
	plasma_progress = 0.0
	plasma_aiming = false
	plasma_active = false
	beam.visible = false
	beam_glow.visible = false
	if beam_r != null:
		beam_r.visible = false
	if beam_glow_r != null:
		beam_glow_r.visible = false
	if beam_core != null:
		beam_core.visible = false
	if beam_core_r != null:
		beam_core_r.visible = false
	body_layer.visible = false
	arm_l_pivot.visible = false
	arm_r_pivot.visible = false
	sprite.visible = true
	sprite.scale = Vector2(0.395, 0.395)
	var fixture_art_lift: float = 0.0
	if latched_fixture != null and is_instance_valid(latched_fixture):
		fixture_art_lift = 10.0
	elif fixture_detaching and sprite.animation == &"charge_release":
		fixture_art_lift = 10.0 * (1.0 - float(sprite.frame) / 9.0)
	elif fixture_launch_animation_time > 0.0:
		fixture_art_lift = 10.0 * fixture_launch_animation_time / FIXTURE_LAUNCH_ANIMATION_TIME
	sprite.position = Vector2(0.0, -fixture_art_lift)
	sprite.rotation = 0.0
	sprite.modulate = Color.WHITE
	sprite.flip_h = visual_facing < 0
	sprite.speed_scale = 1.0
	sprite.play(&"knockback")
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func die() -> void:
	if reaction_state != ReactionState.NORMAL:
		return
	reaction_state = ReactionState.DYING
	reaction_time = 0.0
	latched_fixture = null
	pending_fixture_launch = false
	fixture_launch_animation_time = 0.0
	death_landed = false
	death_impact_time = 0.0
	ladder_state = LadderState.NONE
	active_ladder = null
	dash_left = 0.0
	turning = false
	transition = &""
	_clear_locked_target(false)
	aim_side = &""
	aim_l_progress = 0.0
	aim_r_progress = 0.0
	plasma_progress = 0.0
	plasma_aiming = false
	plasma_active = false
	beam.visible = false
	beam_glow.visible = false
	if beam_r != null:
		beam_r.visible = false
	if beam_glow_r != null:
		beam_glow_r.visible = false
	if beam_core != null:
		beam_core.visible = false
	if beam_core_r != null:
		beam_core_r.visible = false
	body_layer.visible = false
	arm_l_pivot.visible = false
	arm_r_pivot.visible = false
	sprite.visible = true
	sprite.scale = Vector2(0.395, 0.395)
	sprite.position = Vector2.ZERO
	sprite.rotation = 0.0
	sprite.modulate = Color.WHITE
	sprite.flip_h = visual_facing < 0
	sprite.speed_scale = 1.0
	sprite.play(&"death_fall")
	_update_suit_polarity_visuals()
	for light in [thruster_light, muzzle_light, wrist_led_l, wrist_led_r]:
		if light != null:
			light.enabled = false
	if exhaust_effect != null:
		exhaust_effect.set("powered", false)
	if thruster_trail != null:
		thruster_trail.emitting = false
	if thruster_blast != null:
		thruster_blast.emitting = false
	if shadow != null:
		shadow.visible = false
	death_sparks.position = Vector2(0.0, 12.0)
	death_sparks.restart()
	death_sparks.emitting = true
	death_smoke.position = Vector2(0.0, 12.0)
	death_smoke.restart()
	death_smoke.emitting = true
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _physics_reaction(delta: float) -> void:
	reaction_time += delta
	if reaction_state == ReactionState.HURT:
		if not is_on_floor():
			velocity.y += FALL_GRAVITY * delta
		velocity.x = move_toward(velocity.x, 0.0, 520.0 * delta)
		move_and_slide()
		position.x = clampf(position.x, 65.0, 3150.0)
		if reaction_time >= 0.9:
			reaction_state = ReactionState.NORMAL
			sprite.flip_h = false
			sprite.scale = BASE_SPRITE_SCALE
			sprite.play(_faced_clip(&"idle"))
			jump_was_down = true
			dash_was_down = true
		_update_shadow()
		return
	if not death_landed:
		if not is_on_floor():
			velocity.y += FALL_GRAVITY * delta
		velocity.x = move_toward(velocity.x, 0.0, 520.0 * delta)
		move_and_slide()
		position.x = clampf(position.x, 65.0, 3150.0)
		if is_on_floor() and reaction_time >= 0.4:
			death_landed = true
			death_impact_time = 0.0
			velocity = Vector2.ZERO
			sprite.play(&"death_impact")
	else:
		death_impact_time += delta
	var fall_progress: float = clampf(reaction_time / 1.0, 0.0, 1.0)
	death_smoke.position = Vector2(float(visual_facing) * lerpf(0.0, 16.0, fall_progress), lerpf(12.0, 28.0, fall_progress))
	if reaction_time >= 1.05:
		death_smoke.emitting = false
	if not death_landed or death_impact_time < 1.6:
		return
	global_position = reaction_origin
	velocity = Vector2.ZERO
	sprite.flip_h = false
	sprite.play(_faced_clip(&"idle"))
	for light in [thruster_light, wrist_led_l, wrist_led_r]:
		if light != null:
			light.enabled = true
	if exhaust_effect != null:
		exhaust_effect.set("powered", true)
	death_sparks.emitting = false
	death_smoke.emitting = false
	reaction_state = ReactionState.NORMAL
	_update_suit_polarity_visuals()
	jump_was_down = true
	dash_was_down = true

func _vector_from_json(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func _layer_entry(group: String, clip: String, index: int) -> Dictionary:
	var group_data: Dictionary = layer_points.get(group, {})
	var frames: Array = group_data.get(clip, [])
	if frames.is_empty():
		return {}
	return frames[clampi(index, 0, frames.size() - 1)]

func _sync_layer(animated: AnimatedSprite2D, clip: StringName, index: int) -> void:
	if animated.animation != clip:
		animated.animation = clip
	animated.stop()
	animated.frame = clampi(index, 0, animated.sprite_frames.get_frame_count(clip) - 1)

func _place_arm(side: String, base: String, base_index: int) -> Vector2:
	var pivot: Node2D = arm_l_pivot if side == "L" else arm_r_pivot
	var art: AnimatedSprite2D = arm_l if side == "L" else arm_r
	var parts: Array = arm_l_parts if side == "L" else arm_r_parts
	var base_entry: Dictionary = _layer_entry("base", base, base_index)
	if base_entry.is_empty():
		return Vector2.ZERO
	var rest: Dictionary = base_entry[side]
	var base_shoulder: Vector2 = _vector_from_json(rest["shoulder"])
	var base_wrist: Vector2 = _vector_from_json(rest["wrist"])
	var progress: float = aim_l_progress if side == "L" else aim_r_progress
	var face: String = "_left" if visual_facing < 0 else ""
	var track: String = ""
	var pose: Dictionary = {}
	var index: int = 0
	if plasma_progress > 0.001:
		track = "plasma" + face
		index = clampi(roundi(plasma_progress * 15.0), 0, 15)
		var plasma_entry: Dictionary = _layer_entry("plasma", track, index)
		pose = plasma_entry.get(side, {})
	elif progress > 0.001:
		track = "aim_" + side + face
		index = clampi(roundi(progress * 11.0), 0, 11)
		pose = _layer_entry("aim", track, index)
	var y_offset: float = FEET_Y_OFFSET * (1.0 - squash_stretch.y)
	if pose.is_empty():
		# Non-aiming arm is rendered in full body canvas space; anchor directly to body root with squash & stretch
		pivot.position = Vector2(0.0, y_offset)
		pivot.scale = squash_stretch
		pivot.rotation = 0.0
		art.visible = true
		for part in parts:
			part.visible = false
		art.position = Vector2.ZERO
		_sync_layer(art, StringName(side + "_" + base), base_index)
		var calculated_wrist: Vector2 = Vector2(0.0, y_offset) + base_wrist * squash_stretch
		if side == "L":
			wrist_pos_l = calculated_wrist
		else:
			wrist_pos_r = calculated_wrist
		return calculated_wrist
	var pose_shoulder: Vector2 = _vector_from_json(pose["shoulder"])
	var pose_wrist: Vector2 = _vector_from_json(pose["wrist"])
	var segmented: bool = plasma_progress <= 0.001
	# The selected body frame supplies the actual socket position. Applying the
	# arm's source-camera travel again pulls the shoulder away from that socket.
	pivot.position = base_shoulder * squash_stretch + Vector2(0.0, y_offset)
	pivot.scale = squash_stretch
	var eff_prog: float = plasma_progress if plasma_progress > 0.001 else progress
	pivot.rotation = -float(visual_facing) * deg_to_rad(aim_angle_degrees) * eff_prog
	art.visible = not segmented
	if segmented:
		for part_index in range(3):
			var part: AnimatedSprite2D = parts[part_index]
			part.visible = true
			part.position = -pose_shoulder
			var label: String = ["upper", "forearm", "hand"][part_index]
			_sync_layer(part, StringName(label + "_" + side + "_" + track), index)
	else:
		for part in parts:
			part.visible = false
		art.position = -pose_shoulder
		_sync_layer(art, StringName(side + "_" + track), index)
	var active_wrist: Vector2 = pivot.position + (pose_wrist - pose_shoulder).rotated(pivot.rotation) * squash_stretch
	if side == "L":
		wrist_pos_l = active_wrist
	else:
		wrist_pos_r = active_wrist
	return active_wrist

func _update_layers() -> void:
	if ladder_state != LadderState.NONE:
		sprite.visible = true
		body_layer.visible = false
		arm_l_pivot.visible = false
		arm_r_pivot.visible = false
		return
	var layered: bool = (aim_l_progress > 0.001 or aim_r_progress > 0.001
		or plasma_progress > 0.001 or aim_side != &"" or plasma_active)
	var base: String = str(sprite.animation)
	var available: bool = layer_points.get("base", {}).has(base)
	layered = layered and available
	sprite.visible = not layered
	body_layer.visible = layered
	arm_l_pivot.visible = layered
	arm_r_pivot.visible = layered
	if not layered:
		return
	var body_index: int = sprite.frame
	var motion_offset := Vector2.ZERO
	if visual_facing < 0 and aim_r_progress > 0.001 and not turning:
		# Blue firing turns the torso with the arm. Both socket landmarks and the
		# resting arm are rendered from that same pose, including during swaps.
		var moving: Dictionary = _layer_entry("base", base, sprite.frame)
		var rest_motion: Dictionary = _layer_entry("base", base, 0)
		if not moving.is_empty() and not rest_motion.is_empty():
			for side in ["L", "R"]:
				motion_offset += (_vector_from_json(moving[side]["shoulder"]) - _vector_from_json(rest_motion[side]["shoulder"])) * 0.5
		base = "blue_turn"
		body_index = clampi(roundi(aim_r_progress * 11.0), 0, 11)
	_sync_layer(body_layer, StringName("body_" + base), body_index)
	arm_l_pivot.z_index = 3 if visual_facing > 0 else 1
	arm_r_pivot.z_index = 1 if visual_facing > 0 else 3
	hand_l = _place_arm("L", base, body_index)
	hand_r = _place_arm("R", base, body_index)
	var offset: Vector2 = motion_offset * squash_stretch
	body_layer.position += offset
	arm_l_pivot.position += offset
	arm_r_pivot.position += offset
	hand_l += offset
	hand_r += offset
	wrist_pos_l = hand_l
	wrist_pos_r = hand_r

func _clear_locked_target(released: bool = false) -> void:
	if locked_target != null and is_instance_valid(locked_target):
		if released:
			var release_color: Color = Color(1.0, 0.22, 0.28) if aim_side == &"aim_left_arm" else Color(0.2, 0.75, 1.0)
			if locked_target.has_method("lock_in_color"):
				locked_target.lock_in_color(release_color)
			elif locked_target.has_method("set_locked_on"):
				locked_target.set_locked_on(false, Vector2.ZERO, Color.WHITE)
		else:
			if locked_target.has_method("set_locked_on"):
				locked_target.set_locked_on(false, Vector2.ZERO, Color.WHITE)
	locked_target = null

func _update_beam(aim_request: StringName, delta: float) -> void:
	var raised: bool = (aim_l_progress >= 0.70 if aim_side == &"aim_left_arm"
		else aim_r_progress >= 0.70)
	var single_beam_active: bool = aim_request != &"" and raised and not plasma_aiming
	var plasma_beam_active: bool = plasma_aiming and plasma_progress >= 0.60

	beam.visible = single_beam_active or plasma_beam_active
	beam_glow.visible = single_beam_active or plasma_beam_active
	if beam_core != null:
		beam_core.visible = single_beam_active or plasma_beam_active

	if beam_r != null:
		beam_r.visible = plasma_beam_active
	if beam_glow_r != null:
		beam_glow_r.visible = plasma_beam_active
	if beam_core_r != null:
		beam_core_r.visible = plasma_beam_active
	if plasma_reticle != null:
		plasma_reticle.visible = plasma_beam_active or single_beam_active

	if not single_beam_active and not plasma_beam_active:
		lock_intensity = 0.0
		sparkles.emitting = false
		_clear_locked_target(false)
		if plasma_flash_timer <= 0.0 and muzzle_light != null:
			muzzle_light.enabled = false
		return

	var rad: float = deg_to_rad(aim_angle_degrees)
	var forward: Vector2 = Vector2(cos(rad) * float(visual_facing), -sin(rad)).normalized()

	if plasma_beam_active:
		# Dual-laser convergence mode (Red Left + Blue Right converging on target)
		var origin_l: Vector2 = hand_l
		var origin_r: Vector2 = hand_r
		var origin_mid: Vector2 = (hand_l + hand_r) * 0.5

		var target_range: float = current_beam_length if controller_aiming or plasma_controller_armed else MAX_BEAM_LENGTH
		var desired_target: Vector2 = origin_mid + forward * target_range
		raycast.enabled = true
		raycast.global_position = global_position + origin_mid
		raycast.target_position = forward * target_range
		raycast.force_raycast_update()

		var endpoint: Vector2 = desired_target
		var hit_collider: Object = null
		if raycast.is_colliding():
			endpoint = to_local(raycast.get_collision_point())
			hit_collider = raycast.get_collider()

		var is_interactive_target: bool = false
		if hit_collider != null and hit_collider.has_method("set_locked_on"):
			is_interactive_target = true
			if locked_target != hit_collider:
				_clear_locked_target(false)
				locked_target = hit_collider
			locked_target.set_locked_on(true, raycast.get_collision_point(), Color(0.85, 0.35, 1.0, 1.0))
		else:
			_clear_locked_target(false)

		var target_lock: float = 1.0 if is_interactive_target else (0.42 if raycast.is_colliding() else 0.0)
		lock_intensity = move_toward(lock_intensity, target_lock, 12.0 * delta)

		# Left beam (Crimson Red guide)
		var pts_l: PackedVector2Array = PackedVector2Array([origin_l, endpoint])
		beam.points = pts_l
		beam_glow.points = pts_l
		beam.width = 1.8
		beam_glow.width = 7.0
		beam.default_color = Color(1.0, 0.22, 0.30, 0.65)
		beam_glow.default_color = Color(1.0, 0.12, 0.20, 0.18)
		if beam_core != null:
			beam_core.points = pts_l
			beam_core.width = 1.0
			beam_core.visible = true
			beam_core.default_color = Color(1.0, 0.85, 0.88, 0.6)

		# Right beam (Electric Cyan guide)
		var pts_r: PackedVector2Array = PackedVector2Array([origin_r, endpoint])
		if beam_r != null:
			beam_r.points = pts_r
			beam_r.width = 1.8
			beam_r.default_color = Color(0.20, 0.75, 1.0, 0.65)
		if beam_glow_r != null:
			beam_glow_r.points = pts_r
			beam_glow_r.width = 7.0
			beam_glow_r.default_color = Color(0.12, 0.50, 1.0, 0.18)
		if beam_core_r != null:
			beam_core_r.points = pts_r
			beam_core_r.width = 1.0
			beam_core_r.visible = true
			beam_core_r.default_color = Color(0.85, 0.95, 1.0, 0.6)

		# Reticle at exact convergence point with Violet color
		if plasma_reticle != null:
			plasma_reticle.visible = true
			_position_reticle(endpoint)
			plasma_reticle.set("charge_ratio", plasma_progress)
			plasma_reticle.set("is_locked_on", is_interactive_target)
			plasma_reticle.set("reticle_color", Color(0.95, 0.45, 1.0))

		if muzzle_light != null:
			muzzle_light.enabled = true
			muzzle_light.color = Color(0.85, 0.35, 1.0, 1.0)
			muzzle_light.position = origin_mid
			muzzle_light.energy = 0.8 + 0.6 * plasma_progress
			muzzle_light.texture_scale = 0.9 + 0.4 * plasma_progress

		sparkles.emitting = false

	else:
		# Single-arm laser mode (Well-balanced contrast between searching and locked)
		var is_red: bool = (aim_side == &"aim_left_arm")
		var origin: Vector2 = hand_l if is_red else hand_r
		var beam_length: float = current_beam_length
		var desired_target: Vector2 = origin + forward * beam_length
		raycast.enabled = true
		raycast.global_position = global_position + origin
		raycast.target_position = forward * beam_length
		raycast.force_raycast_update()

		var endpoint: Vector2 = desired_target
		var hit_collider: Object = null
		var hit_normal: Vector2 = -forward
		if raycast.is_colliding():
			endpoint = to_local(raycast.get_collision_point())
			hit_collider = raycast.get_collider()
			hit_normal = raycast.get_collision_normal()
		var nearby_target: Dictionary = _nearest_tag_target(origin, forward)
		if not nearby_target.is_empty():
			endpoint = nearby_target.point
			hit_collider = nearby_target.target
			hit_normal = nearby_target.normal

		var is_interactive_target: bool = false
		if hit_collider != null and hit_collider.has_method("set_locked_on"):
			is_interactive_target = true
			if locked_target != hit_collider:
				_clear_locked_target(false)
				locked_target = hit_collider
			var lock_color: Color = Color(1.0, 0.22, 0.28, 1.0) if is_red else Color(0.2, 0.75, 1.0, 1.0)
			locked_target.set_locked_on(true, raycast.get_collision_point(), lock_color)
		else:
			_clear_locked_target(false)

		var target_lock: float = 1.0 if is_interactive_target else (0.04 if raycast.is_colliding() else 0.0)
		var ramp_speed: float = 14.0 if target_lock > lock_intensity else 9.0
		lock_intensity = move_toward(lock_intensity, target_lock, ramp_speed * delta)

		# Refined balanced beam scaling:
		# Searching: 1.4px collimated guide wire; Locked: 2.6px high-energy beam with 1.2px hot white core
		var w_core: float = lerpf(0.5, 1.3, lock_intensity)
		var w_beam: float = lerpf(2.2, 3.0, lock_intensity)
		var w_glow: float = lerpf(7.0, 12.0, lock_intensity)

		var pts: PackedVector2Array = PackedVector2Array([origin, endpoint])
		beam.points = pts
		beam_glow.points = pts
		if beam_core != null:
			beam_core.points = pts
			beam_core.width = w_core
			beam_core.visible = true
			beam_core.default_color = Color(1.0, 0.78, 0.80, 0.55 + lock_intensity * 0.4) if is_red else Color(0.72, 0.90, 1.0, 0.55 + lock_intensity * 0.4)

		beam.width = w_beam
		beam_glow.width = w_glow

		if is_red:
			var alpha_beam: float = lerpf(0.80, 1.0, lock_intensity)
			var alpha_glow: float = lerpf(0.18, 0.30, lock_intensity)
			beam.default_color = Color(1.0, 0.20, 0.26, alpha_beam)
			beam_glow.default_color = Color(1.0, 0.08, 0.16, alpha_glow)
		else:
			var alpha_beam: float = lerpf(0.80, 1.0, lock_intensity)
			var alpha_glow: float = lerpf(0.18, 0.30, lock_intensity)
			beam.default_color = Color(0.18, 0.65, 1.0, alpha_beam)
			beam_glow.default_color = Color(0.10, 0.42, 1.0, alpha_glow)

		# Sparkles deflect off interactive targets
		if (raycast.is_colliding() or is_interactive_target) and (is_interactive_target or lock_intensity > 0.4):
			sparkles.position = endpoint
			var spark_base_col: Color = Color(1.0, 0.35, 0.4) if is_red else Color(0.4, 0.8, 1.0)
			sparkles.modulate = Color(spark_base_col.r, spark_base_col.g, spark_base_col.b, lerpf(0.5, 1.0, lock_intensity))
			sparkles.direction = hit_normal
			sparkles.spread = 75.0
			sparkles.initial_velocity_min = lerpf(30.0, 100.0, lock_intensity)
			sparkles.initial_velocity_max = lerpf(60.0, 200.0, lock_intensity)
			sparkles.emitting = true
		else:
			sparkles.emitting = false

		if plasma_reticle != null:
			plasma_reticle.visible = true
			_position_reticle(endpoint)
			plasma_reticle.set("charge_ratio", lock_intensity)
			plasma_reticle.set("is_locked_on", is_interactive_target)
			var ret_col: Color = Color(1.0, 0.22, 0.28) if is_red else Color(0.2, 0.75, 1.0)
			plasma_reticle.set("reticle_color", ret_col)

		if muzzle_light != null:
			muzzle_light.enabled = true
			var base_col: Color = Color(1.0, 0.22, 0.3, 1.0) if is_red else Color(0.2, 0.75, 1.0, 1.0)
			muzzle_light.color = base_col
			muzzle_light.position = origin
			var t_flicker: float = float(Time.get_ticks_msec()) * 0.03
			muzzle_light.energy = lerpf(0.40, 1.70, lock_intensity) + (sin(t_flicker) * 0.15 if lock_intensity > 0.3 else 0.0)
			muzzle_light.texture_scale = lerpf(0.55, 1.25, lock_intensity)

func _fire_plasma() -> void:
	var proj: Area2D = PLASMA_SCENE.instantiate()
	var origin: Vector2 = (hand_l + hand_r) * 0.5
	proj.global_position = global_position + origin
	var rad: float = deg_to_rad(aim_angle_degrees)
	var dir: Vector2 = Vector2(cos(rad) * float(visual_facing), -sin(rad)).normalized()
	proj.velocity = dir * PLASMA_SPEED
	proj.direction = dir
	proj.shooter = self
	get_parent().add_child(proj)

	plasma_flash_timer = 0.14
	if muzzle_light != null:
		muzzle_light.enabled = true
		muzzle_light.color = Color(0.85, 0.35, 1.0, 1.0)
		muzzle_light.position = origin
		muzzle_light.energy = 3.4
		muzzle_light.texture_scale = 2.0

	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_impulse"):
		cam.add_impulse(-dir * 5.0)

func _fire_quick_blaster() -> void:
	var bolt: Area2D = QUICK_BLASTER_SCENE.instantiate()
	get_parent().add_child(bolt)
	var muzzle: Vector2 = Vector2(float(visual_facing) * 34.0, 31.0)
	bolt.global_position = global_position + muzzle
	bolt.direction = Vector2(float(visual_facing), 0.0)
	bolt.shooter = self
	quick_blaster_cooldown = 0.16
	plasma_flash_timer = 0.08
	if muzzle_light != null:
		muzzle_light.enabled = true
		muzzle_light.color = Color(0.15, 1.0, 0.25)
		muzzle_light.position = muzzle
		muzzle_light.energy = 2.0
		muzzle_light.texture_scale = 0.55

func _physics_process(delta: float) -> void:
	if reaction_state != ReactionState.NORMAL:
		_physics_reaction(delta)
		return
	if pending_fixture_launch and is_on_floor() and sprite.animation == &"charge_attach" and sprite.frame >= 13:
		_launch_from_fixture()
	var launch_pose_finished: bool = fixture_launch_animation_time > 0.0 and fixture_launch_animation_time <= delta
	fixture_launch_animation_time = maxf(0.0, fixture_launch_animation_time - delta)
	fixture_launch_lockout = maxf(0.0, fixture_launch_lockout - delta)
	var pads: Array[int] = Input.get_connected_joypads()
	controller_id = pads[0] if not pads.is_empty() else -1
	var stick_x: float = _pad_axis(JOY_AXIS_LEFT_X)
	var stick_y: float = _pad_axis(JOY_AXIS_LEFT_Y)
	var key_right: bool = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var key_left: bool = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var dpad_right: bool = _pad_button(JOY_BUTTON_DPAD_RIGHT)
	var dpad_left: bool = _pad_button(JOY_BUTTON_DPAD_LEFT)
	var right_down: bool = key_right or dpad_right or stick_x > CONTROLLER_STICK_DEADZONE
	var left_down: bool = key_left or dpad_left or stick_x < -CONTROLLER_STICK_DEADZONE
	var down_down: bool = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or _pad_button(JOY_BUTTON_DPAD_DOWN) or stick_y > 0.55
	var up_down: bool = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or _pad_button(JOY_BUTTON_DPAD_UP) or stick_y < -0.55
	var controller_a: bool = _pad_button(JOY_BUTTON_A)
	var controller_b: bool = _pad_button(JOY_BUTTON_B)
	var space_down: bool = Input.is_key_pressed(KEY_SPACE)
	var move_axis: float = float(int(key_right or dpad_right) - int(key_left or dpad_left))
	if move_axis == 0.0 and absf(stick_x) > CONTROLLER_STICK_DEADZONE:
		move_axis = signf(stick_x) * (absf(stick_x) - CONTROLLER_STICK_DEADZONE) / (1.0 - CONTROLLER_STICK_DEADZONE)

	var ladder_candidate: Area2D = _find_nearby_ladder()
	var in_ladder_zone: bool = (ladder_candidate != null)
	var climb_up: bool = up_down
	var mount_up: bool = Input.is_key_pressed(KEY_W) or (controller_b and in_ladder_zone)
	var jump_down: bool = space_down or controller_a or (up_down and not in_ladder_zone and ladder_state == LadderState.NONE)
	var dash_down: bool = Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_K) or _pad_button(JOY_BUTTON_LEFT_STICK)
	var mb_left: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var mb_right: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var both_mouse_down: bool = mb_left and mb_right
	var pad_red: bool = _pad_button(JOY_BUTTON_LEFT_SHOULDER)
	var pad_blue: bool = _pad_button(JOY_BUTTON_RIGHT_SHOULDER)
	var controller_plasma: bool = _pad_axis(JOY_AXIS_TRIGGER_RIGHT) > 0.35
	var quick_blaster_down: bool = _pad_axis(JOY_AXIS_TRIGGER_LEFT) > 0.35 or Input.is_key_pressed(KEY_G)
	quick_blaster_cooldown = maxf(0.0, quick_blaster_cooldown - delta)
	if quick_blaster_down and not quick_blaster_was_down and quick_blaster_cooldown <= 0.0 and ladder_state == LadderState.NONE:
		_fire_quick_blaster()
	quick_blaster_was_down = quick_blaster_down
	var new_controller_mode: int = 3 if controller_plasma else (1 if pad_red else (2 if pad_blue else 0))
	controller_aiming = new_controller_mode != 0
	if controller_aiming and new_controller_mode != controller_aim_mode:
		current_beam_length = CONTROLLER_PLASMA_START_REACH if new_controller_mode == 3 else CONTROLLER_LASER_START_REACH
		controller_turn_progress = 0.0
	controller_aim_mode = new_controller_mode
	var plasma_down: bool = Input.is_key_pressed(KEY_F) or both_mouse_down or controller_plasma

	var jump_pressed: bool = jump_down and not jump_was_down

	# Coyote time & jump buffer tracking
	if is_on_floor():
		coyote_timer = COYOTE_TIME_MAX
		is_jumping = false
		dash_ready = true
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)

	if jump_pressed:
		jump_buffer_timer = JUMP_BUFFER_MAX
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	var aim_request: StringName = &""
	if not plasma_down:
		if Input.is_key_pressed(KEY_Q) or (mb_left and not mb_right) or pad_red:
			aim_request = &"aim_left_arm"
		elif Input.is_key_pressed(KEY_E) or (mb_right and not mb_left) or pad_blue:
			aim_request = &"aim_right_arm"
	if controller_aiming:
		var right_stick := Vector2(_pad_axis(JOY_AXIS_RIGHT_X), _pad_axis(JOY_AXIS_RIGHT_Y))
		_apply_controller_aim(right_stick, delta)

	if aim_request != &"" or plasma_down or plasma_progress > 0.001:
		var adjust: int = int(Input.is_key_pressed(KEY_UP)) - int(Input.is_key_pressed(KEY_DOWN))
		if adjust != 0:
			aim_angle_velocity = move_toward(aim_angle_velocity, float(adjust) * 90.0, 540.0 * delta)
			aim_angle_degrees = clampf(aim_angle_degrees + aim_angle_velocity * delta, MIN_AIM_ELEVATION, MAX_AIM_ELEVATION)
			if (aim_angle_degrees >= MAX_AIM_ELEVATION or aim_angle_degrees <= MIN_AIM_ELEVATION) and signf(aim_angle_velocity) == signf(aim_angle_degrees):
				aim_angle_velocity = 0.0
		else:
			aim_angle_velocity = move_toward(aim_angle_velocity, 0.0, 540.0 * delta)

		var forward_input: float = float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT))
		var length_dir: float = forward_input * float(visual_facing)
		if length_dir != 0.0:
			current_beam_length = clampf(current_beam_length + length_dir * BEAM_LENGTH_SPEED * delta, MIN_BEAM_LENGTH, MAX_BEAM_LENGTH)

	var aim_active: bool = (aim_request != &"" or aim_side != &""
		or plasma_down or plasma_progress > 0.001 or aim_l_progress > 0.001 or aim_r_progress > 0.001)
	var direction: int = int(right_down) - int(left_down)
	if direction != 0 and not aim_active and ladder_state == LadderState.NONE:
		facing = direction

	# --- Ladder Climbing Mechanics ---
	var on_ladder: bool = (ladder_state != LadderState.NONE)

	if on_ladder:
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		dash_left = 0.0
		turning = false
		is_jumping = false
		squash_stretch = Vector2(1.0, 1.0)
		squash_stretch_velocity = Vector2.ZERO

		# Aiming or shooting breaks off ladder immediately
		if aim_active:
			ladder_state = LadderState.NONE
			active_ladder = null
			on_ladder = false
		# Jump leaps off ladder
		elif jump_pressed:
			ladder_state = LadderState.NONE
			var h_dir: float = float(int(right_down) - int(left_down))
			velocity.y = JUMP_SPEED * 0.85
			if h_dir != 0.0:
				velocity.x = h_dir * MOVE_SPEED
				visual_facing = int(signf(h_dir))
				facing = visual_facing
			else:
				velocity.x = float(visual_facing) * (MOVE_SPEED * 0.4)
			is_jumping = true
			active_ladder = null
			on_ladder = false
			sprite.play(_faced_clip(&"jump"))
			if thruster_blast != null:
				thruster_blast.restart()
				thruster_blast.emitting = true
		elif active_ladder == null or not is_instance_valid(active_ladder):
			ladder_state = LadderState.NONE
			on_ladder = false
		else:
			# At the floor, walking away releases the rails immediately. Higher up,
			# horizontal input never swaps the ladder pose for a walking pose.
			if direction != 0 and (is_on_floor() or global_position.y >= active_ladder.bottom_y - 44.0):
				ladder_state = LadderState.NONE
				active_ladder = null
				on_ladder = false
				velocity = Vector2.ZERO
				sprite.play(_faced_clip(&"idle"))
		if on_ladder:
			# Align horizontally to ladder center
			global_position.x = move_toward(global_position.x, active_ladder.climb_x, 600.0 * delta)
			velocity.x = 0.0

			if ladder_state == LadderState.MOUNTING or ladder_state == LadderState.DISMOUNTING:
				velocity.y = 0.0
			else:
				var v_axis: float = 0.0 if ladder_state == LadderState.MOUNTING or ladder_state == LadderState.DISMOUNTING else float(int(down_down) - int(climb_up))
				if v_axis < 0.0: # Climbing UP
					velocity.y = -active_ladder.climb_speed
					ladder_state = LadderState.CLIMBING

					if thruster_light != null:
						thruster_light.energy = 1.6

					# Top ledge dismount
					if global_position.y <= active_ladder.top_y + LADDER_TOP_DISMOUNT_MARGIN:
						ladder_state = LadderState.NONE
						global_position.y = active_ladder.top_y - 18.0
						velocity = Vector2(float(visual_facing) * 160.0, -120.0)
						active_ladder = null
						on_ladder = false
						sprite.play(_faced_clip(&"move"))
						if thruster_trail != null:
							thruster_trail.emitting = false

				if v_axis > 0.0: # Climbing DOWN
					velocity.y = active_ladder.descent_speed
					ladder_state = LadderState.CLIMBING

					if thruster_trail != null:
						thruster_trail.emitting = false

					# Bottom dismount
					if is_on_floor() or global_position.y >= active_ladder.bottom_y - 44.0:
						ladder_state = LadderState.DISMOUNTING
						velocity = Vector2.ZERO
						sprite.speed_scale = 1.0
						sprite.play(&"ladder_dismount_right" if visual_facing > 0 else &"ladder_dismount_left")

				# Engine-assisted travel: both hands keep the same rail-grip pose.
				if ladder_state != LadderState.DISMOUNTING and ladder_state != LadderState.MOUNTING:
					if sprite.animation != &"ladder_idle":
						sprite.play(&"ladder_idle")
					sprite.set_frame_and_progress(0, 0.0)
					sprite.pause()

				if v_axis == 0.0 and ladder_state != LadderState.DISMOUNTING and ladder_state != LadderState.MOUNTING: # Holding ladder / Idle
					velocity.y = 0.0
					ladder_state = LadderState.IDLE
					if sprite.animation != &"ladder_idle":
						sprite.play(&"ladder_idle")
					if thruster_trail != null:
						thruster_trail.emitting = false
	else:
		# Check ladder mount initiation
		if ladder_candidate != null and not aim_active:
			var at_top_ledge: bool = (global_position.y < ladder_candidate.top_y + 35.0)
			var wants_mount: bool = _ladder_mount_requested(mount_up, down_down, at_top_ledge)

			if wants_mount:
				ladder_state = LadderState.MOUNTING
				active_ladder = ladder_candidate
				on_ladder = true
				velocity = Vector2.ZERO
				global_position.x = active_ladder.climb_x
				if down_down and at_top_ledge:
					# The upper platform is one-way. Begin below its collision
					# face rather than trying to descend through a solid contact.
					global_position.y = maxf(global_position.y, active_ladder.top_y + 38.0)
				if visual_facing > 0:
					sprite.play(&"ladder_mount_right")
				else:
					sprite.play(&"ladder_mount_left")


	if not on_ladder:
		# Jump initiation with coyote time, jump buffering & jump blast sparks
		if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and not aim_active and latched_fixture == null:
			velocity.y = JUMP_SPEED
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			is_jumping = true
			if thruster_blast != null:
				thruster_blast.restart()
				thruster_blast.emitting = true
			if thruster_light != null:
				thruster_light.energy = 3.6

		# Asymmetric jump gravity: snappy ascent, heavier responsive descent
		if not is_on_floor():
			if velocity.y < 0.0:
				if not jump_down and fixture_launch_animation_time <= 0.0:
					velocity.y = move_toward(velocity.y, 0.0, JUMP_CUT_DECEL * delta)
				velocity.y += JUMP_GRAVITY * delta
			else:
				if down_down:
					velocity.y += FAST_FALL_GRAVITY * delta
				else:
					velocity.y += FALL_GRAVITY * delta

		# Ascending thruster spark trail
		if thruster_trail != null:
			thruster_trail.emitting = (not is_on_floor() and velocity.y < -40.0)

		if dash_down and not dash_was_down and dash_ready and not aim_active:
			dash_left = DASH_DURATION
			dash_ready = false

		if aim_active:
			dash_left = 0.0
			if turning:
				velocity.x = 0.0
			else:
				velocity.x = move_axis * MOVE_SPEED
			if is_on_floor() and velocity.y > 0.0:
				velocity.y = 0.0
		elif dash_left > 0.0:
			dash_left = maxf(0.0, dash_left - delta)
			velocity.x = float(facing) * DASH_SPEED
			velocity.y = 0.0
		else:
			if turning:
				velocity.x = 0.0
			else:
				velocity.x = move_axis * MOVE_SPEED
			if is_on_floor() and velocity.y > 0.0:
				velocity.y = 0.0

	if not on_ladder:
		if latched_fixture != null and is_instance_valid(latched_fixture):
			velocity.x = clampf((latched_fixture.global_position.x - global_position.x) * 8.0, -220.0, 220.0)
			if not is_on_floor():
				velocity.y = move_toward(velocity.y, 520.0, 1800.0 * delta)
			jump_buffer_timer = 0.0
	else:
		latched_fixture = null
	move_and_slide()
	_update_fixture_latch()
	position.x = clampf(position.x, 65.0, 3150.0)
	var grounded: bool = is_on_floor()
	var landed: bool = grounded and not was_on_floor and has_touched_floor
	if grounded:
		has_touched_floor = true

	# A landing can disturb the floor without deforming MIKO's rigid body.
	if landed and latched_fixture == null:
		if landing_dust != null:
			landing_dust.restart()
			landing_dust.emitting = true

	# Keep the rendered rig at its authored proportions through jumps, impacts,
	# and magnetic forces. Pose changes come from the rendered animations.
	squash_stretch = Vector2.ONE
	squash_stretch_velocity = Vector2.ZERO
	sprite.scale = BASE_SPRITE_SCALE
	body_layer.scale = BASE_SPRITE_SCALE
	sprite.position = Vector2.ZERO
	body_layer.position = Vector2.ZERO

	if aim_request != &"" or plasma_down:
		transition = &""
	if aim_request != &"" or plasma_down or plasma_aiming:
		if aim_request != &"" and aim_side != aim_request:
			_clear_locked_target(false)
			aim_side = aim_request
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE and not controller_aiming:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif controller_aiming and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		if aim_side != &"":
			_clear_locked_target(true)
			aim_side = &""
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if plasma_down and not plasma_was_down:
		plasma_fired = false
		plasma_controller_armed = controller_plasma
		_clear_locked_target(false)
	plasma_active = plasma_down
	if not aim_active and not turning and latched_fixture == null and not fixture_detaching and fixture_launch_animation_time <= 0.0 and direction != 0 and direction != visual_facing:
		turning = true
		transition = &""
		turn_target = direction
		sprite.play(&"turn_to_left" if direction < 0 else &"turn_to_right")
		sprite.speed_scale = 1.33

	if fixture_detaching:
		sprite.speed_scale = 1.0
		if sprite.animation != &"charge_release":
			sprite.play(&"charge_release")
	elif not turning and ladder_state == LadderState.NONE and fixture_launch_animation_time > 0.0:
		sprite.speed_scale = 1.0
		if sprite.animation != &"charge_launch":
			sprite.play(&"charge_launch")
	elif not turning and ladder_state == LadderState.NONE and latched_fixture != null:
		transition = &""
		sprite.speed_scale = 1.0
		if sprite.animation != &"charge_attach":
			sprite.play(&"charge_attach")
		elif not sprite.is_playing():
			sprite.set_frame_and_progress(13, 0.0)
			sprite.pause()
	elif not turning and ladder_state == LadderState.NONE:
		sprite.speed_scale = 1.0
		if dash_left > 0.0:
			transition = &""
			if sprite.animation != _faced_clip(&"dash"):
				sprite.play(_faced_clip(&"dash"))
		elif not grounded:
			transition = &""
			var air_clip: StringName = &"jump" if velocity.y < 50.0 else &"fall"
			if sprite.sprite_frames.has_animation(_faced_clip(air_clip)):
				if sprite.animation != _faced_clip(air_clip):
					sprite.play(_faced_clip(air_clip))
			elif sprite.animation != _faced_clip(&"jump"):
				sprite.play(_faced_clip(&"jump"))
			if launch_pose_finished:
				sprite.set_frame_and_progress(4, 0.0)
		else:
			if aim_active:
				transition = &""
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

	# Exponential decay on muzzle flash
	if plasma_flash_timer > 0.0:
		plasma_flash_timer = maxf(0.0, plasma_flash_timer - delta)
		if muzzle_light != null:
			muzzle_light.energy = 3.4 * (plasma_flash_timer / 0.14)
			if plasma_flash_timer <= 0.0 and aim_request == &"" and not plasma_aiming:
				muzzle_light.enabled = false

	aim_l_progress = move_toward(aim_l_progress,
		1.0 if aim_request == &"aim_left_arm" else 0.0, ARM_RAISE_SPEED * delta)
	aim_r_progress = move_toward(aim_r_progress,
		1.0 if aim_request == &"aim_right_arm" else 0.0, ARM_RAISE_SPEED * delta)

	# Hold-to-Aim & Release-to-Fire:
	var plasma_released: bool = not plasma_down and plasma_was_down
	if plasma_down:
		plasma_aiming = true
		plasma_progress = move_toward(plasma_progress, 1.0, ARM_RAISE_SPEED * delta)
	else:
		if plasma_released and not plasma_fired:
			_fire_plasma()
			plasma_fired = true
		plasma_progress = move_toward(plasma_progress, 0.0, ARM_RAISE_SPEED * 1.6 * delta)
		if plasma_progress <= 0.001:
			plasma_aiming = false
			plasma_fired = false
			plasma_controller_armed = false
	plasma_was_down = plasma_down

	_update_layers()
	_update_beam(aim_request, delta)

	# Dynamic Thruster Lighting:
	if thruster_light != null:
		var base_energy: float = 1.35 if not grounded and velocity.y < 0.0 else (0.85 if absf(velocity.x) > 20.0 else 0.45)
		var t_flicker: float = float(Time.get_ticks_msec()) * 0.001
		var flicker: float = sin(t_flicker * 3.1) * 0.12 + sin(t_flicker * 7.7) * 0.06
		thruster_light.energy = base_energy + flicker
		thruster_light.position = Vector2(0, 28 + (8.0 if not grounded and velocity.y < 0.0 else 0.0))

	# Dynamic LED Wrist Accents (Crimson Left / Electric Blue Right)
	var t_led: float = float(Time.get_ticks_msec()) * 0.005
	if wrist_led_l != null:
		wrist_led_l.position = wrist_pos_l
		if aim_side == &"aim_left_arm":
			wrist_led_l.energy = 2.4 + lock_intensity * 1.4
			wrist_led_l.texture_scale = 0.55 + lock_intensity * 0.35
		else:
			wrist_led_l.energy = 0.85 + sin(t_led * 2.8) * 0.2
			wrist_led_l.texture_scale = 0.36

	if wrist_led_r != null:
		wrist_led_r.position = wrist_pos_r
		if aim_side == &"aim_right_arm":
			wrist_led_r.energy = 2.4 + lock_intensity * 1.4
			wrist_led_r.texture_scale = 0.55 + lock_intensity * 0.35
		else:
			wrist_led_r.energy = 0.85 + sin(t_led * 2.8 + 1.6) * 0.2
			wrist_led_r.texture_scale = 0.36

	jump_was_down = jump_down
	dash_was_down = dash_down
	previous_direction = direction
	was_on_floor = grounded
	_update_shadow()


func _update_shadow() -> void:
	if shadow == null:
		return
	if ladder_state != LadderState.NONE:
		shadow.visible = false
		return

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var ray_origin: Vector2 = global_position + Vector2(0.0, 30.0)
	var ray_end: Vector2 = ray_origin + Vector2(0.0, 700.0)
	var query := PhysicsRayQueryParameters2D.create(ray_origin, ray_end)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)

	if not result.is_empty():
		var floor_pos: Vector2 = result.position
		shadow.global_position.x = global_position.x
		shadow.global_position.y = floor_pos.y
		var dist: float = floor_pos.y - (global_position.y + FEET_Y_OFFSET)
		if dist >= -5.0 and dist < 450.0:
			shadow.visible = true
			var t: float = clampf(dist / 450.0, 0.0, 1.0)
			shadow.modulate.a = (1.0 - t * 0.75) * 0.85
			shadow.scale = Vector2(0.38, 0.22) * (1.0 - t * 0.40)
		else:
			shadow.visible = false
	else:
		shadow.visible = false
