extends Node3D
## Reusable cosmetic burst prepared with the crate, including its first render.

const FRAGMENTS := preload("res://models/props/wooden_crate_broken.glb")
const SPLINTER_COUNT := 28
const DUST_COUNT := 16
const LIFETIME := 1.45

static var sliver_mesh: BoxMesh
static var smoke_mesh: QuadMesh
static var ring_mesh: TorusMesh
static var break_sound: AudioStreamWAV

var pieces: Array[MeshInstance3D] = []
var rests: Array[Transform3D] = []
var velocity := PackedVector3Array()
var spin := PackedVector3Array()
var splinters: MultiMesh
var splinter_position := PackedVector3Array()
var splinter_velocity := PackedVector3Array()
var splinter_axis := PackedVector3Array()
var splinter_phase := PackedFloat32Array()
var splinter_settled: Array[bool] = []
var dust: MultiMesh
var dust_position := PackedVector3Array()
var dust_velocity := PackedVector3Array()
var dust_size := PackedFloat32Array()
var flash: MeshInstance3D
var flash_material: ShaderMaterial
var shock_ring: MeshInstance3D
var ring_material: StandardMaterial3D
var sound: AudioStreamPlayer
var elapsed := 0.0
var strength := 1.0
var rng := RandomNumberGenerator.new()
var floor_ray := PhysicsRayQueryParameters3D.new()

func _ready() -> void:
	_prepare_assets()
	var source := FRAGMENTS.instantiate()
	add_child(source)
	for piece: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		pieces.append(piece)
		rests.append(piece.transform)
	velocity.resize(pieces.size())
	spin.resize(pieces.size())
	splinters = _batch(sliver_mesh,SPLINTER_COUNT)
	splinter_position.resize(SPLINTER_COUNT)
	splinter_velocity.resize(SPLINTER_COUNT)
	splinter_axis.resize(SPLINTER_COUNT)
	splinter_phase.resize(SPLINTER_COUNT)
	splinter_settled.resize(SPLINTER_COUNT)
	dust = _batch(smoke_mesh,DUST_COUNT)
	dust_position.resize(DUST_COUNT)
	dust_velocity.resize(DUST_COUNT)
	dust_size.resize(DUST_COUNT)
	shock_ring = MeshInstance3D.new()
	shock_ring.mesh = ring_mesh
	shock_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring_material = StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	shock_ring.material_override = ring_material
	add_child(shock_ring)
	flash = MeshInstance3D.new()
	flash.mesh = smoke_mesh
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash_material = ShaderMaterial.new()
	flash_material.shader = preload("res://shaders/lab_halo.gdshader")
	flash.material_override = flash_material
	add_child(flash)
	sound = AudioStreamPlayer.new()
	sound.stream = break_sound
	sound.volume_db = -12.0
	add_child(sound)
	floor_ray.collision_mask = 1
	rng.randomize()
	stop()

static func _prepare_assets() -> void:
	if sliver_mesh:
		return
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("88603a")
	wood.roughness = .95
	sliver_mesh = BoxMesh.new()
	sliver_mesh.size = Vector3(.025,.14,.018)
	sliver_mesh.material = wood

	var gradient := Gradient.new()
	gradient.set_color(0,Color(1,1,1,.30))
	gradient.set_color(1,Color(1,1,1,0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5,.5)
	texture.fill_to = Vector2(1,.5)
	var smoke := StandardMaterial3D.new()
	smoke.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smoke.albedo_texture = texture
	smoke.vertex_color_use_as_albedo = true
	smoke_mesh = QuadMesh.new()
	smoke_mesh.size = Vector2.ONE
	smoke_mesh.material = smoke

	ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = .06
	ring_mesh.outer_radius = .10
	ring_mesh.rings = 20
	ring_mesh.ring_segments = 6

	var noise := RandomNumberGenerator.new()
	noise.seed = 61423
	var data := PackedByteArray()
	data.resize(7718*2)
	for index in range(7718):
		var t := float(index)/22050.0
		var crack := noise.randf_range(-1,1)*exp(-t*48.0)*.6
		var thud := sin(TAU*(120.0-t*80.0)*t)*exp(-t*22.0)*.4
		var rattle := noise.randf_range(-1,1)*exp(-t*13.0)*.12*(.5+.5*sin(t*260.0))
		data.encode_s16(index*2,int(clampf(crack+thud+rattle,-1,1)*26000.0))
	break_sound = AudioStreamWAV.new()
	break_sound.format = AudioStreamWAV.FORMAT_16_BITS
	break_sound.mix_rate = 22050
	break_sound.data = data

static func warm_up(level: Node) -> void:
	if not is_instance_valid(level) or not level.is_inside_tree() or level.has_node("CrateBreakWarmup"):
		return
	if DisplayServer.get_name() == "headless":
		return
	# The compatibility renderer first compiles these materials when they draw.
	# Render a burst once in a tiny private viewport while the room opens.
	var preview := SubViewport.new()
	preview.name = "CrateBreakWarmup"
	preview.size = Vector2i(64,64)
	preview.own_world_3d = true
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	level.add_child(preview)
	var camera := Camera3D.new()
	camera.position = Vector3(0,.55,2.5)
	preview.add_child(camera)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55,-30,0)
	key.shadow_enabled = level.get("course_shadows") == true
	preview.add_child(key)
	var effect := new()
	preview.add_child(effect)
	effect._start(Vector3(0,.4,0),Vector3.RIGHT,Color("ffaa5e"),1.0)
	for index in range(2):
		await RenderingServer.frame_post_draw
		if not is_instance_valid(preview):
			return
	preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
	preview.queue_free()

func _batch(mesh: Mesh, count: int) -> MultiMesh:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = mesh
	batch.instance_count = count
	batch.custom_aabb = AABB(Vector3(-10,-18,-5),Vector3(20,26,10))
	var visual := MultiMeshInstance3D.new()
	visual.multimesh = batch
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	return batch

func burst(point: Vector3, direction: Vector3, tint: Color, impact: float) -> void:
	_start(point,direction,tint,impact)
	add_to_group("miko8_crate_debris")
	sound.pitch_scale = rng.randf_range(.94,1.06)
	sound.play()
	set_physics_process(true)

func _start(point: Vector3, direction: Vector3, tint: Color, impact: float) -> void:
	elapsed = 0.0
	strength = impact
	for index in range(pieces.size()):
		var piece := pieces[index]
		piece.transform = rests[index]
		var radial := (to_local(piece.global_position)-Vector3(0,.4,0)).normalized()
		velocity[index] = (radial*rng.randf_range(1.4,3.0)+direction*2.0+Vector3.UP*rng.randf_range(2.0,3.8))*strength
		spin[index] = Vector3(rng.randf_range(-6,6),rng.randf_range(-6,6),rng.randf_range(-6,6))
	for index in range(SPLINTER_COUNT):
		splinter_position[index] = Vector3(rng.randf_range(-.3,.3),rng.randf_range(.15,.7),rng.randf_range(-.3,.3))
		splinter_velocity[index] = Vector3(rng.randf_range(-3.8,3.8),rng.randf_range(2.2,6.2),rng.randf_range(-1.6,1.6))+direction*2.0
		splinter_axis[index] = Vector3(rng.randf(),rng.randf()+.01,rng.randf()).normalized()
		splinter_phase[index] = rng.randf()*TAU
		splinter_settled[index] = false
		splinters.set_instance_transform(index,Transform3D(Basis(splinter_axis[index],splinter_phase[index]),splinter_position[index]))
		splinters.set_instance_color(index,Color.WHITE)
	for index in range(DUST_COUNT):
		dust_position[index] = Vector3(rng.randf_range(-.3,.3),rng.randf_range(.08,.65),rng.randf_range(-.2,.2))
		dust_velocity[index] = Vector3(rng.randf_range(-.7,.7),rng.randf_range(.2,.8),rng.randf_range(-.3,.3))
		dust_size[index] = rng.randf_range(.25,.5)
		_shade_dust(index,1.0)
	shock_ring.position = point
	shock_ring.scale = Vector3(.4,.16,.4)*strength
	shock_ring.show()
	ring_material.albedo_color = tint
	flash.position = point+Vector3(0,0,.4)
	flash.scale = Vector3(1.3,1.05,1.0)*strength
	flash_material.set_shader_parameter("light_color",tint)
	flash_material.set_shader_parameter("energy",.60*strength)
	flash.show()
	show()

func stop() -> void:
	set_physics_process(false)
	hide()
	sound.stop()
	if is_in_group("miko8_crate_debris"):
		remove_from_group("miko8_crate_debris")

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= LIFETIME:
		stop()
		return
	if flash.visible:
		flash_material.set_shader_parameter("energy",.60*strength*pow(maxf(0,1.0-elapsed/.12),2.0))
		flash.visible = elapsed < .12
	if shock_ring.visible:
		var age := minf(elapsed/.26,1.0)
		var size := lerpf(.4,2.6,1.0-pow(1.0-age,3.0))*strength
		shock_ring.scale = Vector3(size,size*.4,size)
		ring_material.albedo_color.a = (1.0-age)*.9
		shock_ring.visible = age < 1.0

	var shrink := 1.0-smoothstep(.65,LIFETIME,elapsed)
	var space := get_world_3d().direct_space_state
	for index in range(pieces.size()):
		var piece := pieces[index]
		var previous := piece.global_position
		var motion := velocity[index] + Vector3.DOWN*12.0*delta
		piece.position += motion*delta
		var surface := _surface_below(space,previous,piece.global_position,.08)
		if not surface.is_empty():
			piece.global_position.y = surface.position.y+.08
			motion.y = absf(motion.y)*.24 if absf(motion.y) > .65 else 0.0
			var damping := exp(-5.0*delta)
			motion.x *= damping
			motion.z *= damping
			spin[index] *= exp(-6.0*delta)
		velocity[index] = motion
		var rotation := spin[index]
		if rotation.length_squared() > .000001:
			piece.rotate(rotation.normalized(),rotation.length()*delta)
		piece.scale = rests[index].basis.get_scale()*shrink
	for index in range(SPLINTER_COUNT):
		if not splinter_settled[index]:
			var previous := to_global(splinter_position[index])
			splinter_velocity[index] += Vector3.DOWN*12.0*delta
			splinter_position[index] += splinter_velocity[index]*delta
			var surface := _surface_below(space,previous,to_global(splinter_position[index]),.02)
			if not surface.is_empty():
				splinter_position[index] = to_local(surface.position+Vector3.UP*.02)
				splinter_phase[index] += elapsed*9.0
				splinter_settled[index] = true
		var angle := splinter_phase[index] if splinter_settled[index] else splinter_phase[index]+elapsed*9.0
		var basis := Basis(splinter_axis[index],angle).scaled(Vector3.ONE*shrink)
		splinters.set_instance_transform(index,Transform3D(basis,splinter_position[index]))
	for index in range(DUST_COUNT):
		dust_position[index] += dust_velocity[index]*delta
		_shade_dust(index,maxf(0,1.0-elapsed/1.1))

func _shade_dust(index: int, opacity: float) -> void:
	var size := dust_size[index]*(1.0+elapsed*2.2)
	dust.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*size),dust_position[index]))
	dust.set_instance_color(index,Color(.55,.42,.27,opacity))

func _surface_below(space: PhysicsDirectSpaceState3D, previous: Vector3, current: Vector3, clearance: float) -> Dictionary:
	if current.y >= previous.y:
		return {}
	# Sweep against the real platforms so shards can fall between floors.
	floor_ray.from = previous
	floor_ray.to = current-Vector3.UP*clearance
	var hit := space.intersect_ray(floor_ray)
	if not hit.is_empty() and hit.normal.y > .5:
		return hit
	return {}
