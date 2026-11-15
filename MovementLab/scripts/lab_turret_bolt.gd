extends Node3D

const SPEED := 10.5
const LIFE := 1.25
const Guard := preload("res://scripts/lab_electric_guard.gd")

var direction: Vector3
var shooter: Vector3
var age := 0.0
var ray := PhysicsRayQueryParameters3D.new()
var red_plasma := false
var speed := SPEED
var lifetime := LIFE

static var core_mesh: SphereMesh
static var trail_mesh: QuadMesh
static var trail_paint: ShaderMaterial
static var red_core: StandardMaterial3D
static var red_trail: ShaderMaterial

func launch(origin: Vector3, heading: Vector3, source: Vector3) -> void:
	direction = heading.normalized()
	shooter = source
	var transverse := Vector3.BACK.cross(direction)
	transverse = transverse.normalized() if transverse.length_squared() > .0001 else Vector3.RIGHT
	global_transform = Transform3D(Basis(direction,transverse,direction.cross(transverse)),origin)
	ray.collision_mask = 3 | Guard.PROJECTILE_LAYER
	ray.collide_with_areas = true

func _ready() -> void:
	if not core_mesh:
		var core := StandardMaterial3D.new()
		core.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		core.albedo_color = Color("d5f5ff")
		core_mesh = SphereMesh.new()
		core_mesh.radius = .065
		core_mesh.height = .13
		core_mesh.radial_segments = 8
		core_mesh.rings = 4
		core_mesh.material = core
		trail_mesh = QuadMesh.new()
		trail_mesh.size = Vector2(.86,.28)
		trail_paint = ShaderMaterial.new()
		trail_paint.shader = preload("res://shaders/lab_halo.gdshader")
		trail_paint.set_shader_parameter("light_color",Color("329bff"))
		trail_paint.set_shader_parameter("energy",.92)
		trail_mesh.material = trail_paint
	var core := MeshInstance3D.new()
	core.mesh = core_mesh
	core.scale.x = 2.45
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)
	var trail := MeshInstance3D.new()
	trail.mesh = trail_mesh
	trail.position.x = -.17
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if red_plasma:
		if not red_core:
			red_core = core_mesh.material.duplicate() as StandardMaterial3D
			red_core.albedo_color = Color("ffd5cb")
			red_trail = trail_paint.duplicate() as ShaderMaterial
			red_trail.set_shader_parameter("light_color",Color("ff243b"))
		core.material_override = red_core
		trail.material_override = red_trail
	add_child(trail)

func _physics_process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	ray.from = global_position
	ray.to = global_position+direction*speed*delta
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(ray)
	if hit.get("collider") is Area3D:
		var area: Area3D = hit.collider
		if area.is_in_group(Guard.PROJECTILE_GROUP) and area.get_parent().intercept_bolt(shooter.x, hit.position):
			queue_free()
			return
		# The other area layers never stopped a bolt before the shield was added.
		ray.collide_with_areas = false
		hit = space.intersect_ray(ray)
		ray.collide_with_areas = true
	if hit.is_empty():
		global_position = ray.to
		return
	var body: Node = hit.collider
	if body.has_method("receive_attack"):
		body.receive_attack(shooter.x)
	queue_free()
