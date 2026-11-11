extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _check() -> void:
	var core: SpriteFrames = load("res://sprites/robot_frames.tres")
	var layers: SpriteFrames = load("res://layers/layer_frames.tres")
	var parts: SpriteFrames = load("res://layers/aim_parts.tres")
	if core == null or layers == null or parts == null:
		_fail("Missing core or layer SpriteFrames")
		return
	if core.get_animation_speed(&"turn_to_left") < 70.0:
		_fail("Turn speed was not increased")
		return
	for clip in [&"body_move", &"L_move", &"R_move", &"L_aim_L",
		&"R_aim_R", &"L_plasma", &"R_plasma",
		&"body_move_left", &"L_aim_L_left", &"R_aim_R_left"]:
		if not layers.has_animation(clip):
			_fail("Missing layer clip " + str(clip))
			return
	for clip in [&"upper_L_aim_L", &"forearm_L_aim_L", &"hand_L_aim_L",
		&"upper_R_aim_R", &"forearm_R_aim_R", &"hand_R_aim_R_left"]:
		if not parts.has_animation(clip):
			_fail("Missing segmented clip " + str(clip))
			return
	var packed: PackedScene = load("res://scenes/demo.tscn")
	if packed == null:
		_fail("Demo did not load")
		return
	var demo: Node = packed.instantiate()
	root.add_child(demo)
	var player: CharacterBody2D = demo.get_node("Robot")
	var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	var body: AnimatedSprite2D = player.get_node("BodyLayer")
	var arm_l: AnimatedSprite2D = player.get_node("ArmLPivot/ArmL")
	var arm_r: AnimatedSprite2D = player.get_node("ArmRPivot/ArmR")
	var upper_l: AnimatedSprite2D = player.get_node("ArmLPivot/Upper")
	var forearm_l: AnimatedSprite2D = player.get_node("ArmLPivot/Forearm")
	var hand_l_art: AnimatedSprite2D = player.get_node("ArmLPivot/Hand")
	var upper_r: AnimatedSprite2D = player.get_node("ArmRPivot/Upper")
	var forearm_r: AnimatedSprite2D = player.get_node("ArmRPivot/Forearm")
	var hand_r_art: AnimatedSprite2D = player.get_node("ArmRPivot/Hand")
	var beam: Line2D = player.get_node("AimBeam")
	for tick in range(45):
		await physics_frame
	var start_x: float = player.position.x
	_key(KEY_D, true)
	_key(KEY_Q, true)
	for tick in range(32):
		await physics_frame
	print("AIM_MOVE dx=", player.position.x - start_x,
		" body=", body.animation, " left=", upper_l.animation)
	if player.position.x - start_x < 100.0 or not body.visible or sprite.visible:
		_fail("Robot did not move with independent body layer while aiming")
		return
	if upper_l.animation != &"upper_L_aim_L" or not beam.visible or arm_l.visible:
		_fail("Red arm or beam did not raise during movement")
		return
	if not forearm_l.visible or not hand_l_art.visible or player.get_node("ArmRPivot").z_index < 1:
		_fail("Separated arm pieces or rear arm draw order are incorrect")
		return
	_key(KEY_Q, false)
	_key(KEY_E, true)
	for tick in range(4):
		await physics_frame
	print("SWITCH body=",body.animation," L=",player.get("aim_l_progress"),
		" R=",player.get("aim_r_progress"))
	if not body.visible or sprite.animation.begins_with("aim_"):
		_fail("Switch reset the body animation")
		return
	if player.get("aim_l_progress") <= 0.0 or player.get("aim_r_progress") <= 0.0:
		_fail("Arms did not cross-transition")
		return
	for tick in range(25):
		await physics_frame
	_key(KEY_UP, true)
	for tick in range(15):
		await physics_frame
	_key(KEY_UP, false)
	print("BLUE_AIM angle=",player.get("aim_angle_degrees"),
		" rotation=",player.get_node("ArmRPivot").rotation)
	if player.get("aim_angle_degrees") <= 2.0 or upper_r.animation != &"upper_R_aim_R":
		_fail("Blue arm did not aim continuously")
		return
	_key(KEY_E, false)
	_key(KEY_D, false)
	for tick in range(35):
		await physics_frame
	if body.visible or not sprite.visible:
		_fail("Layered arms did not settle back to full animation")
		return
	player.position.x = 400.0 # Clear space before the first crate for projectile inspection.
	_key(KEY_F, true)
	for tick in range(24):
		await physics_frame
	print("PLASMA arms=",arm_l.animation," / ",arm_r.animation,
		" shot=",demo.get_node_or_null("PlasmaProjectile") != null,
		" progress=",player.get("plasma_progress"),
		" fired=",player.get("plasma_fired"))
	if arm_l.animation != &"L_plasma" or arm_r.animation != &"R_plasma":
		_fail("Coordinated plasma raise did not play")
		return
	var found_projectile: bool = false
	for child in demo.get_children():
		if child.name.begins_with("PlasmaProjectile"):
			found_projectile = true
	if not found_projectile:
		_fail("Purple projectile was not fired from both hands")
		return
	_key(KEY_F, false)
	for tick in range(28):
		await physics_frame
	_key(KEY_A, true)
	for tick in range(38):
		await physics_frame
	_key(KEY_A, false)
	if player.get("visual_facing") != -1:
		_fail("Faster model turn did not reach left-facing state")
		return
	_key(KEY_F, true)
	for tick in range(24):
		await physics_frame
	print("LEFT_PLASMA arms=", arm_l.animation, " / ", arm_r.animation)
	if arm_l.animation != &"L_plasma_left" or arm_r.animation != &"R_plasma_left":
		_fail("Left-facing coordinated plasma raise did not play")
		return
	_key(KEY_F, false)
	for tick in range(28):
		await physics_frame
	_key(KEY_Q, true)
	for tick in range(30):
		await physics_frame
	var left_shoulder: Vector2 = player.get_node("ArmLPivot").position
	var left_hand: Vector2 = player.get("hand_l")
	print("LEFT_RED_AIM shoulder_to_hand=", left_hand.distance_to(left_shoulder),
		" clip=", upper_l.animation, " beam=", beam.visible)
	if upper_l.animation != &"upper_L_aim_L_left" or not beam.visible:
		_fail("Left-facing corrected red aim did not play")
		return
	if left_hand.distance_to(left_shoulder) < 31.0:
		_fail("Left-facing red arm still appears foreshortened")
		return
	_key(KEY_Q, false)
	_key(KEY_E, true)
	for tick in range(30):
		await physics_frame
	var blue_hand: Vector2 = player.get("hand_r")
	print("LEFT_BLUE_AIM hand=", blue_hand, " upper=", upper_r.animation,
		" parts=", forearm_r.visible and hand_r_art.visible)
	if upper_r.animation != &"upper_R_aim_R_left" or not forearm_r.visible or not hand_r_art.visible:
		_fail("Left-facing blue arm pieces are missing")
		return
	if blue_hand.x > -34.0 or player.get_node("ArmRPivot").z_index <= body.z_index:
		_fail("Blue hand remains behind the head or background")
		return
	_key(KEY_E, false)
	print("LAYERED_DEMO_VALID")
	quit(0)
