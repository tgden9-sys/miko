extends Node3D

const LIFETIME := .98
const SMOKE_TIME := .64
const GRAVITY := 17.0

var ember_color := Color("ff8039")
var blast: MeshInstance3D
var flash: ShaderMaterial
var sparks: CPUParticles3D
var sound: AudioStreamPlayer3D
var age := 0.0
var floor_y := 0.0
var pieces: Array[Node3D] = []
var velocities: Array[Vector3] = []
var spins: Array[Vector3] = []
var clearances: Array[float] = []

func _ready() -> void:
	top_level = true
	blast = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(3.15, 2.65)
	blast.mesh = quad
	flash = ShaderMaterial.new()
	flash.shader = preload("res://shaders/lab_enemy_blast.gdshader")
	flash.set_shader_parameter("ember_color", ember_color)
	blast.material_override = flash
	blast.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(blast)
	sparks = CPUParticles3D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = 30
	sparks.lifetime = .50
	sparks.explosiveness = 1.0
	sparks.direction = Vector3.UP
	sparks.spread = 81.0
	sparks.gravity = Vector3.DOWN * 15.0
	sparks.initial_velocity_min = 3.1
	sparks.initial_velocity_max = 7.0
	sparks.particle_flag_align_y = true
	sparks.scale_amount_min = .32
	sparks.scale_amount_max = 1.0
	var hot := StandardMaterial3D.new()
	hot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hot.vertex_color_use_as_albedo = true
	hot.vertex_color_is_srgb = true
	sparks.color = ember_color.lerp(Color("fff6d4"), .62)
	var streak := BoxMesh.new()
	streak.size = Vector3(.032, .16, .032)
	streak.material = hot
	sparks.mesh = streak
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)
	sound = AudioStreamPlayer3D.new()
	sound.stream = AudioStreamOggVorbis.load_from_file("res://audio/impact_heavy.ogg")
	sound.max_distance = 16.0
	sound.volume_db = -4.5
	sound.pitch_scale = .86
	add_child(sound)
	reset()

func reset() -> void:
	hide()
	set_physics_process(false)
	sparks.emitting = false
	sound.stop()
	_clear_debris()

func _clear_debris() -> void:
	for piece in pieces:
		piece.hide()
		piece.queue_free()
	pieces.clear()
	velocities.clear()
	spins.clear()
	clearances.clear()

func explode(point: Vector3, deck_height: float, direction: int, source: Array[MeshInstance3D]) -> void:
	reset()
	global_position = point
	floor_y = deck_height
	age = 0.0
	# Keep depth separation between the fireball and the flying panels.
	blast.position = Vector3(0, .19, .40)
	flash.set_shader_parameter("age", 0.0)
	blast.show()
	var flip := -1.0 if direction < 0 else 1.0
	for i in range(source.size()):
		_throw_panel(source[i], i, flip)
	show()
	sparks.restart()
	sparks.emitting = true
	sound.play()
	set_physics_process(true)

func _throw_panel(part: MeshInstance3D, index: int, direction: float) -> void:
	var bounds := part.get_aabb()
	var center := bounds.get_center()
	var pivot := Node3D.new()
	add_child(pivot)
	pivot.global_transform = Transform3D(part.global_basis, part.to_global(center))
	var mesh := MeshInstance3D.new()
	mesh.mesh = part.mesh
	mesh.position = -center
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for surface in range(mesh.mesh.get_surface_count()):
		mesh.set_surface_override_material(surface, part.get_active_material(surface))
	pivot.add_child(mesh)
	pieces.append(pivot)
	var side := direction if index % 2 == 0 else -direction
	var forward := .38 if index % 2 == 0 else -.36
	velocities.append(Vector3(side * (2.1 + index * .54), 4.0 + (index % 3) * .78, forward))
	spins.append(Vector3(side * (2.1 + index), 1.7 - index * .84, -side * 6.25))
	clearances.append(maxf(.08, minf(bounds.size.y * .44 + .03, .31)))

func _physics_process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		hide()
		_clear_debris()
		set_physics_process(false)
		return
	blast.visible = age < SMOKE_TIME
	if blast.visible:
		flash.set_shader_parameter("age", age)
	var shrink := 1.0 - smoothstep(.67, LIFETIME, age)
	for i in range(pieces.size()):
		var piece := pieces[i]
		var motion := velocities[i] + Vector3.DOWN * GRAVITY * delta
		var next := piece.global_position + motion * delta
		var contact := floor_y + clearances[i] * shrink
		if next.y < contact:
			next.y = contact
			motion = Vector3(motion.x * .58, maxf(0.0, -motion.y * .23 - .35), motion.z * .56)
			spins[i] *= .55
		velocities[i] = motion
		piece.global_position = next
		piece.rotation += spins[i] * delta
		piece.scale = Vector3.ONE * shrink
