extends StaticBody3D

const CRATE_WIDTH := 0.96
const CRATE_HEIGHT := 0.95
const CRATE_DEPTH := 0.96

var broken := false
var settle_stack := false
var rest_position := Vector3.ZERO
var fall_speed := 0.0
var visual_model: Node3D
var collision_shape: CollisionShape3D

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

func receive_hit(amount: int, direction: int, _lift: float) -> void:
	_break_crate(global_position + Vector3.UP * (CRATE_HEIGHT * 0.5), Vector3(float(direction), 0.35, 0.0).normalized(), Color("ffaa5e"), 1.0)

func receive_laser(pole: int, point: Vector3, normal: Vector3) -> void:
	var tint := Color("ff3038") if pole == 1 else Color("3284ff")
	_break_crate(point, -normal + Vector3.UP * 0.2, tint, 1.1)

func _break_crate(point: Vector3, direction: Vector3, tint: Color, strength: float) -> void:
	if broken:
		return
	broken = true
	set_deferred("collision_layer", 0)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if visual_model:
		visual_model.hide()
	
	if ResourceLoader.exists("res://scripts/miko8_crate_break_effect.gd"):
		var debris = preload("res://scripts/miko8_crate_break_effect.gd").new()
		debris.push_direction = direction
		debris.hit_point = point - global_position
		debris.energy_tint = tint
		debris.impact_strength = strength
		get_parent().add_child(debris)
		debris.global_position = global_position

func reset_crate() -> void:
	broken = false
	collision_layer = 1
	global_position = rest_position
	fall_speed = 0.0
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if visual_model:
		visual_model.show()
