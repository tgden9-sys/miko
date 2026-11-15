extends CharacterBody3D

const EnemyBurst := preload("res://scripts/lab_enemy_burst.gd")
const LEFT_LIMIT := 15.1
const RIGHT_LIMIT := 22.2
const NOTICE_RANGE := 5.2
const WINDUP := .42
const LAND_RECOVERY := .52
const JUMP_SPEED := 7.3
const GRAVITY := 27.5
const FLIGHT_TIME := 2.0 * JUMP_SPEED / GRAVITY
const MAX_HOP := 4.7
const STOMP_RANGE := 1.26
const DURABILITY := 2
const IDLE_SCAN_PERIOD := 3.6
const IDLE_SCAN_ANGLE := 1.17
const IMPACT_SIZE := Vector2(5.15, 1.48)
enum State { IDLE, WINDUP, AIR, RECOVER, BROKEN }

var target: CharacterBody3D
var state := State.IDLE
var age := 0.0
var hitstop := 0.0
var hits := 0
var facing := 1.0
var home: Vector3
var model: Node3D
var shell: MeshInstance3D
var foot: MeshInstance3D
var rest: Vector3
var shell_paint: ShaderMaterial
var foot_paint: ShaderMaterial
var shape: CollisionShape3D
var warning: MeshInstance3D
var warning_paint: ShaderMaterial
var shock: MeshInstance3D
var shock_paint: ShaderMaterial
var shadow: MeshInstance3D
var shadow_paint: ShaderMaterial
var audio: AudioStreamPlayer3D
var metal: AudioStreamOggVorbis
var destruction: EnemyBurst
var impact_fade: Tween

func _ready() -> void:
	home = position
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = .13
	shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.86,.83,.84)
	shape.position.y = .42
	shape.shape = box
	add_child(shape)
	var source := load("res://models/props/lab_magnetic_hopper.glb") as PackedScene
	model = source.instantiate() as Node3D
	add_child(model)
	shell = model.find_child("HopperShell",true,false)
	foot = model.find_child("MagnetFoot",true,false)
	rest = shell.position
	shell_paint = _paint(shell)
	shell_paint.set_shader_parameter("warm_paint_tint",Vector3(.76,.75,.89))
	foot_paint = _paint(foot)
	foot_paint.set_shader_parameter("warm_paint_tint",Vector3(.57,.60,.68))
	_build_effects()
	destruction = EnemyBurst.new()
	destruction.ember_color = Color("ff9c59")
	add_child(destruction)
	reset()

func _paint(part: MeshInstance3D) -> ShaderMaterial:
	var baked := part.get_active_material(0) as StandardMaterial3D
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://shaders/miko8_three_tone.gdshader")
	paint.set_shader_parameter("base_texture",baked.albedo_texture)
	paint.set_shader_parameter("shadow_tone",Vector3(.62,.62,.69))
	paint.set_shader_parameter("middle_tone",Vector3(.91,.92,1.01))
	paint.set_shader_parameter("light_tone",Vector3(1.12,1.14,1.24))
	paint.set_shader_parameter("transition_width",.09)
	part.set_surface_override_material(0,paint)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return paint

func reset() -> void:
	destruction.reset()
	if impact_fade and impact_fade.is_running():
		impact_fade.kill()
	position = home
	velocity = Vector3.ZERO
	facing = 1
	hits = 0
	hitstop = 0
	_enter(State.IDLE)
	model.show()
	shadow.show()
	foot.show()
	shell.show()
	shell.position = rest
	shell.rotation = Vector3.ZERO
	foot.rotation = Vector3.ZERO
	model.rotation.y = 1.05
	shell_paint.set_shader_parameter("droid_warning",0.0)
	foot_paint.set_shader_parameter("droid_warning",0.0)
	shape.set_deferred("disabled",false)
	warning.hide()
	shock.hide()
	audio.stop()

func _physics_process(delta: float) -> void:
	if state == State.BROKEN:
		return
	hitstop = maxf(0.0,hitstop-delta)
	shell_paint.set_shader_parameter("droid_warning",hitstop*3.7)
	if hitstop > 0:
		return
	age += delta
	var ready_to_attack := _target_on_deck()
	if not is_on_floor():
		velocity.y -= GRAVITY*delta
	match state:
		State.IDLE:
			if ready_to_attack and is_on_floor() and absf(target.position.x-position.x) < NOTICE_RANGE:
				_face_target()
				_enter(State.WINDUP)
				_play(metal,1.75,-12)
		State.WINDUP:
			if not ready_to_attack:
				_enter(State.IDLE)
			else:
				if age < WINDUP*.65:
					_face_target()
				if age >= WINDUP:
					_launch()
		State.RECOVER:
			if age >= LAND_RECOVERY:
				_enter(State.IDLE)
	move_and_slide()
	if state == State.AIR and is_on_floor() and velocity.y <= 0.0:
		_land()
	_animate(delta)

func _face_target() -> void:
	var offset := target.position.x-position.x
	if absf(offset) > .12:
		facing = signf(offset)

func _target_on_deck() -> bool:
	return is_instance_valid(target) and target.health > 0 and target.position.x >= LEFT_LIMIT-.24 \
		and target.position.x <= RIGHT_LIMIT+.22 and target.position.y < 1.28

func _launch() -> void:
	# Read the player's run on takeoff, then commit to one landing point.
	var lead := clampf(target.velocity.x * .36, -2.55, 2.55)
	var landing_x := clampf(target.position.x+lead,position.x-MAX_HOP,position.x+MAX_HOP)
	landing_x = clampf(landing_x,LEFT_LIMIT,RIGHT_LIMIT)
	var distance := landing_x-position.x
	velocity.x = distance/(FLIGHT_TIME+1.0/60.0)
	velocity.y = JUMP_SPEED
	if absf(distance) > .12:
		facing = signf(distance)
	_enter(State.AIR)
	_play(metal,1.5,-11)

func _land() -> void:
	velocity.x = 0
	_enter(State.RECOVER)
	_impact()
	if is_instance_valid(target) and target.health > 0 and absf(target.position.y-position.y) < .54 \
			and absf(target.position.x-position.x) < STOMP_RANGE:
		target.receive_attack(global_position.x-facing*.04)

func _enter(next: State) -> void:
	state = next
	age = 0.0

func _animate(delta: float) -> void:
	var compression := 0.0
	var pitch := 0.0
	var foot_pitch := 0.0
	var head_yaw := facing * 1.06
	match state:
		State.IDLE:
			compression = .012*(.5+.5*sin(age*4.0))
			head_yaw = facing * IDLE_SCAN_ANGLE * cos(age * TAU / IDLE_SCAN_PERIOD)
		State.WINDUP:
			var progress := smoothstep(0.0,WINDUP*.83,age)
			compression = .129*progress
			pitch = .16*progress
		State.AIR:
			var in_air := clampf(age/FLIGHT_TIME,0.0,1.0)
			# Extend the piston first, then tip the chassis ahead of the foot.
			compression = .10*(1.0-smoothstep(0.0,.10,age))
			pitch = lerpf(-.16,.23,smoothstep(.10,.92,in_air))
			foot_pitch = -.11*sin(PI*in_air)
		State.RECOVER:
			compression = .15*smoothstep(0.0,.052,age)*(1.0-smoothstep(.28,.70,age))
			pitch = .16*(1.0-smoothstep(.04,.29,age))-.055*sin(age*29.0)*exp(-age*10.0)
	var response := 1.0-exp(-delta*23)
	var current_head_yaw := model.rotation.y + shell.rotation.y
	if state != State.IDLE:
		model.rotation.y = rotate_toward(model.rotation.y,facing*1.06,delta*11)
	var turn_speed := 2.8 if state == State.IDLE else 10.5
	shell.rotation.y = wrapf(rotate_toward(current_head_yaw,head_yaw,delta*turn_speed)-model.rotation.y,-PI,PI)
	shell.position.y = lerpf(shell.position.y,rest.y-compression,response)
	shell.rotation.x = lerpf(shell.rotation.x,pitch,response)
	foot.rotation.x = lerpf(foot.rotation.x,foot_pitch,response)
	warning.visible = state == State.WINDUP
	if warning.visible:
		warning.global_position = shell.to_global(Vector3(-.086,.327,.493))
		warning_paint.set_shader_parameter("energy",.32+.48*smoothstep(0.0,WINDUP,age)+.12*sin(age*36))
	shadow.global_position = Vector3(global_position.x,.023,global_position.z)
	shadow_paint.set_shader_parameter("opacity",clampf(.43-global_position.y*.24,.13,.43))

func _build_effects() -> void:
	warning_paint = ShaderMaterial.new()
	warning_paint.shader = preload("res://shaders/lab_halo.gdshader")
	warning_paint.set_shader_parameter("light_color",Color("ffaf44"))
	warning = _quad(Vector2(.45,.27),warning_paint)
	shock_paint = ShaderMaterial.new()
	shock_paint.shader = preload("res://shaders/ground_impact.gdshader")
	shock_paint.set_shader_parameter("metal_landing",true)
	shock = _quad(IMPACT_SIZE,shock_paint)
	shadow_paint = ShaderMaterial.new()
	shadow_paint.shader = preload("res://shaders/lab_contact.gdshader")
	shadow = _quad(Vector2(.93,.64),shadow_paint)
	shadow.rotation.x = -PI*.5
	metal = AudioStreamOggVorbis.load_from_file("res://audio/impactPlate_heavy_000.ogg")
	audio = AudioStreamPlayer3D.new()
	audio.max_distance = 16
	add_child(audio)

func _quad(size: Vector2, paint: ShaderMaterial) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	var effect := MeshInstance3D.new()
	effect.mesh = quad
	effect.material_override = paint
	effect.top_level = true
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(effect)
	return effect

func _play(stream: AudioStream, pitch: float, volume: float) -> void:
	audio.stream = stream
	audio.pitch_scale = pitch
	audio.volume_db = volume
	audio.play()

func _impact() -> void:
	if impact_fade and impact_fade.is_running():
		impact_fade.kill()
	shock.global_position = global_position+Vector3(0,IMPACT_SIZE.y*.4,.62)
	shock.show()
	shock_paint.set_shader_parameter("age",0.0)
	impact_fade = create_tween()
	impact_fade.tween_method(func(value: float): shock_paint.set_shader_parameter("age",value),0.0,.44,.44)
	impact_fade.tween_callback(shock.hide)
	_play(metal,.73,-7)

func get_hit_point() -> Vector3:
	return global_position+Vector3(0,.42,0)

func receive_hit(_damage: int, direction: int, _lift: float) -> void:
	if state == State.BROKEN:
		return
	hits += 1
	if hits < DURABILITY:
		hitstop = .06
		return
	_enter(State.BROKEN)
	shape.set_deferred("disabled",true)
	shadow.hide()
	warning.hide()
	velocity = Vector3.ZERO
	audio.stop()
	shell_paint.set_shader_parameter("droid_warning",0.0)
	destruction.explode(global_position+Vector3.UP*.48,home.y-.035,direction,[shell,foot])
	model.hide()
