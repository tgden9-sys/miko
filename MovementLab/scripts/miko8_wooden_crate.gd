extends StaticBody3D

const CRATE_WIDTH := 0.8
const CRATE_HEIGHT := 0.8
const CRATE_DEPTH := 0.8
const BreakEffect := preload("res://scripts/miko8_crate_break_effect.gd")

var broken := false
var settle_stack := false
var rest_position := Vector3.ZERO
var fall_speed := 0.0
var visual_model: Node3D
var collision_shape: CollisionShape3D
var debris: BreakEffect

func _ready() -> void:
	name = "WoodenCrate"
	add_to_group("miko8_breakable_crates")
	collision_layer = 1
	collision_mask = 0
	rest_position = global_position
	
	collision_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(CRATE_WIDTH, CRATE_HEIGHT, CRATE_DEPTH)
	collision_shape.shape = box
	collision_shape.position = Vector3(0, CRATE_HEIGHT * 0.5, 0)
	add_child(collision_shape)
	
	if ResourceLoader.exists("res://models/props/wooden_crate.glb"):
		visual_model = load("res://models/props/wooden_crate.glb").instantiate()
		visual_model.scale = Vector3(0.8 / 0.998, 0.8 / 0.95, 0.8 / 0.998)
		add_child(visual_model)
		# Ensure wooden crate materials use three-tone shader or cel look
		for mesh: MeshInstance3D in visual_model.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var orig := mesh.get_active_material(surface) as StandardMaterial3D
				if orig and ResourceLoader.exists("res://shaders/miko8_three_tone.gdshader"):
					var paint := ShaderMaterial.new()
					paint.shader = preload("res://shaders/miko8_three_tone.gdshader")
					paint.set_shader_parameter("base_texture", orig.albedo_texture)
					mesh.set_surface_override_material(surface, paint)

	debris = BreakEffect.new()
	add_child(debris)
	BreakEffect.warm_up.call_deferred(get_parent())

func _physics_process(delta: float) -> void:
	if not settle_stack or broken:
		return
	var distance := 0.08 + fall_speed * delta + 9.8 * delta * delta
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.025, global_position + Vector3.DOWN * distance, 1, [get_rid()])
	var support := get_world_3d().direct_space_state.intersect_ray(ray)
	if not support.is_empty():
		global_position.y = support.position.y
		fall_speed = 0.0
	else:
		fall_speed += 9.8 * delta
		global_position.y = maxf(0.0, global_position.y - fall_speed * delta)

func sword_contact_point(attacker: Vector3) -> Vector3:
	# End the obstruction ray just inside the struck face. The crate's base is
	# its origin, so the generic enemy target sits above the lid of a crate.
	var local := to_local(attacker)
	return to_global(Vector3(
		clampf(local.x, -CRATE_WIDTH * .5 + .035, CRATE_WIDTH * .5 - .035),
		clampf(local.y, .06, CRATE_HEIGHT - .06),
		clampf(local.z, -CRATE_DEPTH * .5 + .035, CRATE_DEPTH * .5 - .035)))

func receive_hit(_amount: int, direction: int, _lift: float) -> void:
	_break_crate(global_position + Vector3.UP * (CRATE_HEIGHT * 0.5), Vector3(float(direction), 0.35, 0.0).normalized(), Color("ffaa5e"), 1.0)

func receive_laser(pole: int, point: Vector3, normal: Vector3) -> void:
	var tint := Color("ff3038") if pole == 1 else Color("3284ff")
	_break_crate(point, -normal + Vector3.UP * 0.2, tint, 1.1)

func _break_crate(point: Vector3, direction: Vector3, tint: Color, strength: float) -> void:
	if broken:
		return
	restore_broken()
	debris.burst(to_local(point), direction, tint, strength)

func restore_broken() -> void:
	broken = true
	set_deferred("collision_layer", 0)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if visual_model:
		visual_model.hide()

func reset_crate() -> void:
	broken = false
	collision_layer = 1
	global_position = rest_position
	fall_speed = 0.0
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if visual_model:
		visual_model.show()
	debris.stop()
