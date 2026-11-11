extends Node3D
## Cel-shaded magnetic charge shockwave and spark burst

var tint := Color("ff3038")
var elapsed := 0.0
var duration := 0.35
var ring: MeshInstance3D
var sparks: MultiMeshInstance3D
var spark_data: Array[Dictionary] = []

func _ready() -> void:
	name = "CrateChargeSpark"
	# 1. Expanding magnetic shock ring
	ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.08
	torus.outer_radius = 0.12
	torus.rings = 24
	torus.ring_segments = 6
	ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring_mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.85)
	ring.material_override = ring_mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)

	# 2. Burst of 14 radial spark motes
	sparks = MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	var sphere := SphereMesh.new()
	sphere.radius = 0.028
	sphere.height = 0.056
	sphere.radial_segments = 6
	sphere.rings = 3
	var spark_mat := StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_mat.vertex_color_use_as_albedo = true
	sphere.material = spark_mat
	batch.mesh = sphere
	batch.instance_count = 14
	batch.custom_aabb = AABB(Vector3.ONE * -3.0, Vector3.ONE * 6.0)
	sparks.multimesh = batch
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(14):
		var angle := float(i) / 14.0 * TAU + rng.randf_range(-0.15, 0.15)
		var elevation := rng.randf_range(-0.5, 0.5)
		var dir := Vector3(cos(angle), elevation, sin(angle) * 0.4).normalized()
		var speed := rng.randf_range(2.2, 4.5)
		spark_data.append({
			"pos": Vector3.ZERO,
			"vel": dir * speed,
			"scale": rng.randf_range(0.8, 1.4)
		})
		batch.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return

	var t := clampf(elapsed / duration, 0.0, 1.0)
	var fade := 1.0 - t
	var ease_out := 1.0 - pow(1.0 - t, 3.0)

	# Ring expands from 0.2m to 1.8m
	var ring_scale := lerpf(0.3, 1.8, ease_out)
	ring.scale = Vector3(ring_scale, ring_scale * 0.3, ring_scale)
	(ring.material_override as StandardMaterial3D).albedo_color = Color(tint.r, tint.g, tint.b, fade * 0.85)

	# Sparks radiate outward with drag
	var batch := sparks.multimesh
	for i in range(spark_data.size()):
		var data: Dictionary = spark_data[i]
		data.vel *= exp(-4.0 * delta)
		data.pos += data.vel * delta
		var s: float = float(data.scale) * fade
		var transform := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s), data.pos)
		batch.set_instance_transform(i, transform)
		batch.set_instance_color(i, Color(tint.r, tint.g, tint.b, fade))
