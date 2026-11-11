extends StaticBody3D
## Reusable empty canister station. Marker nodes give a future interaction its seat and approach.

const INK = preload("res://shaders/miko8_cel_outline.gdshader")
const FINISH = preload("res://shaders/miko8_service_pedestal.gdshader")
const CONTACT = preload("res://shaders/miko8_building_contact.gdshader")

func _ready() -> void:
	add_to_group("miko8_budget_visual")
	set_meta("budget_half_width", 1.15)
	var ink := ShaderMaterial.new()
	ink.shader = INK
	ink.set_shader_parameter("base_thickness", .004)
	for visual: MeshInstance3D in $Model.find_children("*", "MeshInstance3D", true, false):
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(visual.mesh.get_surface_count()):
			var source := visual.get_active_material(surface) as StandardMaterial3D
			if not source:
				continue
			var finish := ShaderMaterial.new()
			finish.shader = FINISH
			finish.set_shader_parameter("use_atlas", source.albedo_texture != null)
			if source.albedo_texture:
				finish.set_shader_parameter("paint_atlas", source.albedo_texture)
			else:
				finish.set_shader_parameter("hardware_paint", source.albedo_color)
			visual.set_surface_override_material(surface, finish)

	_contact("ChassisContact", Vector3(-.125, .008, 0), Vector2(1.39, 1.30), .54)
	_contact("PipeFlangeContact", Vector3(.65, .009, -.018), Vector2(.34, .34), .50)

func _contact(label: String, at: Vector3, footprint: Vector2, opacity: float) -> void:
	var plane := PlaneMesh.new()
	plane.size = footprint + Vector2(.62, .62)
	var shade := ShaderMaterial.new()
	shade.shader = CONTACT
	shade.set_shader_parameter("footprint", footprint)
	shade.set_shader_parameter("plane_size", plane.size)
	shade.set_shader_parameter("opacity", opacity)
	var patch := MeshInstance3D.new()
	patch.name = label
	patch.mesh = plane
	patch.position = at
	patch.material_override = shade
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(patch)
