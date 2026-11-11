extends Node3D
## Short-range charging beam. Draw the same trace used to charge a target.

const RED := Color("ff394d")
const BLUE := Color("369fff")
const RANGE := 24.0
const SNAP_RANGE := 200.0*1.9/96.0
const TARGET_DWELL := .12

var actor: CharacterBody3D
var start := Vector3.ZERO
var end := Vector3.ZERO
var locked_target: Node3D
var lock_pole := 0
var last_target: Node3D
var last_pole := 0
var dwell := 0.0
var charged := false
var core := MeshInstance3D.new()
var halo := MeshInstance3D.new()
var core_material := StandardMaterial3D.new()
var halo_material := StandardMaterial3D.new()
var ray := PhysicsRayQueryParameters3D.new()

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_build_ribbon(core,core_material,false)
	_build_ribbon(halo,halo_material,true)
	ray.exclude = [actor.get_rid()]
	stop()

func _build_ribbon(node: MeshInstance3D, material: StandardMaterial3D, glow: bool) -> void:
	node.mesh = ImmediateMesh.new()
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	add_child(node)

func stop() -> void:
	_set_lock(null,0)
	hide()
	last_target = null
	last_pole = 0
	dwell = 0.0
	charged = false

func resolve_aim(origin: Vector3, direction: Vector3, pole: int, manual: bool) -> Vector3:
	var best: Node3D
	var best_score := INF
	# As in the tutorial, acquire nearby forward targets through a wide cone.
	# Deliberate right-stick aiming uses the tighter near-ray tolerance.
	for candidate: Node3D in get_tree().get_nodes_in_group("miko8_charge_targets"):
		var offset := candidate.global_position-origin
		offset.z = 0.0
		var distance := offset.length()
		if distance < .2 or distance > SNAP_RANGE or absf(candidate.global_position.z-origin.z) > .5:
			continue
		var along := offset.dot(direction)
		if along <= .2:
			continue
		var off_axis := (offset-direction*along).length()
		var alignment := along/distance
		if (manual and off_axis > .85) or (not manual and alignment < .5):
			continue
		var score := off_axis + distance*.08
		if candidate == locked_target and not manual:
			score = -1.0
		if score >= best_score or _trace(origin,origin+offset).get("collider") != candidate:
			continue
		best = candidate
		best_score = score
	_set_lock(best,pole)
	if not is_instance_valid(best):
		return direction
	var target := best.global_position
	target.z = 0.0
	return origin.direction_to(target)

func _set_lock(target: Node3D, pole: int) -> void:
	if locked_target == target and lock_pole == pole:
		return
	if is_instance_valid(locked_target) and locked_target.has_method("set_locked_on"):
		locked_target.set_locked_on(false,Vector3.ZERO,Color.WHITE)
	locked_target = target
	lock_pole = pole
	if is_instance_valid(target) and target.has_method("set_locked_on"):
		target.set_locked_on(true,target.global_position,RED if pole == 1 else BLUE)

func _trace(from: Vector3, to: Vector3) -> Dictionary:
	ray.from = from
	ray.to = to
	ray.collision_mask = 5
	ray.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	ray.collide_with_areas = false
	return hit

func tick(delta: float, origin: Vector3, direction: Vector3, pole: int) -> void:
	var space := get_world_3d().direct_space_state
	ray.from = actor.global_position + Vector3.UP*1.1
	ray.to = origin
	ray.collision_mask = 1
	var muzzle_hit := space.intersect_ray(ray)
	if not muzzle_hit.is_empty():
		stop()
		return
	var trace_origin := Vector3(origin.x,origin.y,0)
	var target_point := trace_origin + direction*RANGE
	if is_instance_valid(locked_target):
		target_point = locked_target.global_position
		target_point.z = 0.0
	var hit := _trace(trace_origin,target_point)
	start = origin
	end = hit.get("position",target_point)
	var tint := RED if pole == 1 else BLUE
	_draw(tint)
	var target: Node3D = hit.get("collider")
	if target != last_target or pole != last_pole:
		last_target = target
		last_pole = pole
		dwell = 0.0
		charged = false
	if is_instance_valid(target) and target.has_method("charge_at") and not charged:
		dwell += delta
		if dwell >= TARGET_DWELL:
			target.charge_at(tint,end)
			charged = true

func _draw(tint: Color) -> void:
	var span := end-start
	if span.length_squared() < .0001:
		hide()
		return
	var camera := get_viewport().get_camera_3d()
	var normal := camera.global_basis.z if camera else Vector3.BACK
	var side := span.normalized().cross(normal).normalized()
	core_material.albedo_color = tint.lerp(Color.WHITE,.38)
	halo_material.albedo_color = Color(tint.r,tint.g,tint.b,.27)
	_ribbon(core.mesh,side*.009)
	_ribbon(halo.mesh,side*.026)
	show()

func _ribbon(mesh: ImmediateMesh, side: Vector3) -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in [start-side,start+side,end+side,start-side,end+side,end-side]:
		mesh.surface_add_vertex(point)
	mesh.surface_end()
