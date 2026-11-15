extends StaticBody3D

const Bolt := preload("res://scripts/lab_turret_bolt.gd")
const TURN_RATE := 5.4
const REST_RATE := 1.6
const MUZZLE_OFFSET := Vector3(.66,-.043,0)
const CHARGE_TIME := .3
const BOLT_INTERVAL := .22
const COOLDOWN := 3.0
const MAX_HITS := 3
enum Phase { WATCH, CHARGE, BURST, COOLDOWN, BROKEN }

@export var entry_grace := 0.0

var target: CharacterBody3D
var emitter: Node3D
var has_target := false
var sight_ray := PhysicsRayQueryParameters3D.new()
var phase := Phase.WATCH
var hits := 0
var hitstop := 0.0
var timer := 0.0
var grace_remaining := 0.0
var shots_left := 0
var muzzle: Marker3D
var muzzle_glow: MeshInstance3D
var muzzle_paint: ShaderMaterial
var body_paint: ShaderMaterial
var hurtbox: CollisionShape3D
var projectiles: Node3D
var emitter_rest: Transform3D
var flash := 0.0
var shot_flash := 0.0
var sound: AudioStreamPlayer3D
var sparks: CPUParticles3D
var fragments: CPUParticles3D
var break_tween: Tween

static var charge_sound: AudioStreamWAV
static var shot_sound: AudioStreamWAV
static var break_sound: AudioStreamWAV

func _ready() -> void:
	var model_scene := load("res://models/props/lab_wall_turret.glb") as PackedScene
	var model := model_scene.instantiate() as Node3D
	add_child(model)
	emitter = model.find_child("Emitter",true,false) as Node3D
	emitter_rest = emitter.transform
	var mount := model.find_child("WallMount",true,false) as MeshInstance3D
	var baked := mount.get_active_material(0) as StandardMaterial3D
	var paint := ShaderMaterial.new()
	body_paint = paint
	paint.shader = preload("res://shaders/miko8_three_tone.gdshader")
	paint.set_shader_parameter("base_texture",baked.albedo_texture)
	paint.set_shader_parameter("red_paint_tint",Vector3(.60,.96,1.0))
	paint.set_shader_parameter("scene_tint",Color(.94,1.0,1.0))
	paint.set_shader_parameter("shadow_tone",Vector3(.48,.54,.58))
	paint.set_shader_parameter("middle_tone",Vector3(.78,.86,.88))
	paint.set_shader_parameter("light_tone",Vector3(1.07,1.16,1.15))
	paint.set_shader_parameter("transition_width",.1)
	for part: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		part.set_surface_override_material(0,paint)
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = MUZZLE_OFFSET
	emitter.add_child(muzzle)
	sight_ray.collision_mask = 1
	collision_layer = 4
	collision_mask = 0
	hurtbox = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.93,.82,1.02)
	hurtbox.shape = box
	# Move toward the camera in world space so both wall mounts can take sword hits.
	hurtbox.position = Vector3(.63, -.10, 0.0) + global_basis.inverse() * Vector3.BACK * .40
	add_child(hurtbox)
	projectiles = Node3D.new()
	add_child(projectiles)
	_build_effects()

func get_hit_point() -> Vector3:
	return hurtbox.global_position

func reset() -> void:
	if break_tween and break_tween.is_running():
		break_tween.kill()
	for bolt: Node in projectiles.get_children():
		bolt.set_physics_process(false)
		bolt.queue_free()
	sound.stop()
	sparks.emitting = false
	fragments.emitting = false
	emitter.transform = emitter_rest
	emitter.show()
	hurtbox.set_deferred("disabled",false)
	hits = 0
	hitstop = 0
	flash = 0
	shot_flash = 0
	phase = Phase.WATCH
	timer = 0
	grace_remaining = entry_grace
	has_target = false
	muzzle_paint.set_shader_parameter("light_color",Color("43a3ff"))
	body_paint.set_shader_parameter("droid_warning",0.0)
	body_paint.set_shader_parameter("scene_tint",Color(.94,1.0,1.0))
	_set_glow(0.0)

func _physics_process(delta: float) -> void:
	if phase == Phase.BROKEN:
		return
	if grace_remaining > 0.0:
		if is_instance_valid(target) and not target.automation:
			grace_remaining = maxf(0.0, grace_remaining - delta)
		return
	hitstop = maxf(0.0,hitstop-delta)
	flash = move_toward(flash,0.0,delta*9.0)
	body_paint.set_shader_parameter("droid_warning",flash*.32)
	var aim := Vector3.ZERO
	var point := _visible_point()
	has_target = point.is_finite()
	if has_target:
		var offset := to_local(point) - to_local(emitter.global_position)
		aim.y = atan2(-offset.z, offset.x)
		aim.z = atan2(offset.y, Vector2(offset.x, offset.z).length())
	var turn_step := (TURN_RATE if has_target else REST_RATE)*delta
	emitter.rotation.y = rotate_toward(emitter.rotation.y, aim.y, turn_step)
	emitter.rotation.z = rotate_toward(emitter.rotation.z, aim.z, turn_step)
	var aligned := false
	if has_target:
		var direction := muzzle.global_position.direction_to(point)
		aligned = direction.dot(emitter.global_basis.x.normalized()) > .96 and _clear_path(muzzle.global_position, point)
	_update_fire(delta, point, aligned)
	muzzle_glow.global_position = muzzle.global_position

func _visible_point() -> Vector3:
	if not is_instance_valid(target) or target.health <= 0:
		return Vector3.INF
	var chest := .65 if target.crouched else .98
	var head := 1.01 if target.crouched else 1.46
	for height: float in [chest, head, .35]:
		var point := target.global_position + Vector3.UP * height
		if _clear_path(emitter.global_position, point):
			return point
	return Vector3.INF

func _clear_path(from: Vector3, to: Vector3) -> bool:
	sight_ray.from = from
	sight_ray.to = to
	return get_world_3d().direct_space_state.intersect_ray(sight_ray).is_empty()

func _update_fire(delta: float, point: Vector3, aligned: bool) -> void:
	timer -= delta
	shot_flash = move_toward(shot_flash,0.0,delta*16.0)
	match phase:
		Phase.WATCH:
			_set_glow(0.0)
			if has_target:
				phase = Phase.CHARGE
				timer = CHARGE_TIME
				_play_sound(charge_sound,-14.0)
		Phase.CHARGE:
			if not has_target:
				phase = Phase.WATCH
				sound.stop()
				_set_glow(0.0)
				return
			var progress := 1.0-clampf(timer/CHARGE_TIME,0.0,1.0)
			_set_glow(lerpf(.42,1.05,progress)+sin(progress*TAU*4.0)*.07)
			if timer <= 0 and aligned:
				phase = Phase.BURST
				shots_left = 3
				_fire(point)
		Phase.BURST:
			_set_glow(.23+shot_flash)
			if not has_target:
				shots_left = 0
				phase = Phase.COOLDOWN
				timer = COOLDOWN
			elif timer <= 0 and aligned:
				_fire(point)
		Phase.COOLDOWN:
			_set_glow(shot_flash)
			if timer <= 0:
				phase = Phase.WATCH

func _fire(point: Vector3) -> void:
	var bolt := Bolt.new()
	var origin := muzzle.global_position
	bolt.lifetime = maxf(bolt.lifetime, (origin.distance_to(point) + 1.5) / bolt.speed)
	projectiles.add_child(bolt)
	bolt.launch(origin, origin.direction_to(point), global_position)
	_play_sound(shot_sound,-8.5)
	shot_flash = 1.35
	_set_glow(shot_flash)
	shots_left -= 1
	if shots_left == 0:
		phase = Phase.COOLDOWN
		timer = COOLDOWN
	else:
		timer = BOLT_INTERVAL

func receive_hit(_damage: int, _direction: int, _lift: float) -> void:
	if phase == Phase.BROKEN:
		return
	hits += 1
	flash = 1.0
	if hits < MAX_HITS:
		return
	phase = Phase.BROKEN
	has_target = false
	hurtbox.set_deferred("disabled",true)
	_play_sound(break_sound,-5.5)
	sparks.global_position = emitter.global_position + global_basis.x.normalized() * .15
	fragments.global_position = sparks.global_position
	sparks.restart()
	sparks.emitting = true
	fragments.restart()
	fragments.emitting = true
	muzzle_glow.global_position = sparks.global_position
	muzzle_paint.set_shader_parameter("light_color",Color("cbe7ff"))
	_set_glow(1.8)
	body_paint.set_shader_parameter("droid_warning",.22)
	break_tween = create_tween().set_parallel()
	break_tween.tween_method(_set_glow,1.8,0.0,.26)
	break_tween.tween_property(emitter,"position",emitter.position+Vector3(.38,-1.8,0),.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	break_tween.tween_property(emitter,"rotation:z",emitter.rotation.z-2.6,.42)
	break_tween.chain().tween_callback(emitter.hide)
	break_tween.chain().tween_callback(_scorch_mount)

func _scorch_mount() -> void:
	body_paint.set_shader_parameter("droid_warning",0.0)
	body_paint.set_shader_parameter("scene_tint",Color(.54,.59,.60))
	muzzle_paint.set_shader_parameter("light_color",Color("43a3ff"))
	_set_glow(0.0)

func _set_glow(energy: float) -> void:
	muzzle_glow.visible = energy > .01
	muzzle_glow.scale = Vector3.ONE*(.72+.35*energy)
	muzzle_paint.set_shader_parameter("energy",energy)

func _build_effects() -> void:
	muzzle_paint = ShaderMaterial.new()
	muzzle_paint.shader = preload("res://shaders/lab_halo.gdshader")
	muzzle_paint.set_shader_parameter("light_color",Color("43a3ff"))
	muzzle_glow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(.9,.9)
	muzzle_glow.mesh = quad
	muzzle_glow.material_override = muzzle_paint
	muzzle_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle_glow.top_level = true
	add_child(muzzle_glow)
	_set_glow(0.0)
	sparks = _burst_particles(Color("8cd6ff"),Vector3(.035,.11,.035),26,.46,5.8)
	fragments = _burst_particles(Color("8a9697"),Vector3(.065,.045,.095),12,.60,3.4)
	if not charge_sound:
		charge_sound = _make_sound(0,CHARGE_TIME)
		shot_sound = _make_sound(1,.21)
		break_sound = _make_sound(2,.48)
	sound = AudioStreamPlayer3D.new()
	sound.max_distance = 17.0
	add_child(sound)

func _burst_particles(tint: Color, size: Vector3, count: int, life: float, speed: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.emitting = false
	particles.amount = count
	particles.lifetime = life
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector3.LEFT
	particles.spread = 78.0
	particles.initial_velocity_min = speed*.35
	particles.initial_velocity_max = speed
	particles.gravity = Vector3.DOWN*12
	particles.top_level = true
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = tint
	var chips := BoxMesh.new()
	chips.size = size
	chips.material = material
	particles.mesh = chips
	add_child(particles)
	return particles

func _play_sound(stream: AudioStreamWAV, volume: float) -> void:
	sound.stream = stream
	sound.volume_db = volume
	sound.play()

static func _make_sound(kind: int, duration: float) -> AudioStreamWAV:
	const RATE := 22050
	var bytes := PackedByteArray()
	bytes.resize(roundi(duration*RATE)*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 797+kind
	for index in range(bytes.size()/2):
		var time := float(index)/RATE
		var noise := rng.randf_range(-1.0,1.0)
		var wave: float
		match kind:
			0:
				var progress := time/duration
				var fade := smoothstep(0.0,.09,progress)*(1.0-smoothstep(.94,1.0,progress))
				var sweep := TAU*(135.0+380.0*progress)*time
				wave = (sin(sweep)*.29+sin(sweep*1.51)*.15)*fade
			1:
				var sweep := TAU*(760.0*time+75.0*(1.0-exp(-time*32.0)))
				wave = sin(sweep)*exp(-time*27.0)*.62+noise*exp(-time*75.0)*.26
			_:
				wave = sin(TAU*(105.0-66.0*time)*time)*exp(-time*13.0)*.55
				wave += noise*exp(-time*11.5)*.38
				wave += sin(TAU*497.0*time)*exp(-time*18.0)*.14
		bytes.encode_s16(index*2,roundi(clampf(wave,-1.0,1.0)*28000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream
