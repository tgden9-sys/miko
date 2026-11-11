extends Node3D
## Complete scenery volumes behind the Level 1 route. The front artwork
## contains only the outward wall; the left walls and roofs are real depth.

const BUILDING_SKIN := preload("res://shaders/miko8_service_yard_building.gdshader")
const YARD_ART := preload("res://art/cel_scene/near_yard_v1.png")
const EXTENSION_ART := preload("res://art/cel_scene/near_extension_v1.png")
const WORKSHOP_ART := preload("res://art/cel_scene/workshop_facade_v1.png")
const CONCRETE := preload("res://art/cel_scene/concrete_v1.png")
const PANELS := preload("res://art/cel_scene/ladder_panels_v2.png")
const EXHAUST := preload("res://models/environment/yard_life/exhaust_outlet.glb")

enum Bay { OFFICE, WORKSHOP, SWITCHGEAR, VENTILATION, BRICK }

# These are the flat wall faces within the source art, measured in the
# 2048 x 683 reference view. No bay uses the painted roof or side wall.
const FACADES := {
	Bay.OFFICE: [YARD_ART, Rect2(15, 253, 508, 409), 0.92],
	Bay.WORKSHOP: [WORKSHOP_ART, Rect2(), 0.80],
	Bay.SWITCHGEAR: [EXTENSION_ART, Rect2(28, 288, 411, 374), 1.0],
	Bay.VENTILATION: [EXTENSION_ART, Rect2(476, 421, 886, 242), 0.87],
	Bay.BRICK: [EXTENSION_ART, Rect2(1402, 195, 597, 469), 0.94],
}

# End X, eaves height, front Z, facade. Each group ends against the full
# cooling station, with silhouettes offset from the playable roof edges.
const GROUPS := [
	[[6.8, 5.4, -3.8, Bay.OFFICE], [18.6, 5.8, -3.0, Bay.WORKSHOP],
	 [27.2, 6.2, -4.15, Bay.SWITCHGEAR], [42.7, 4.15, -3.55, Bay.VENTILATION],
	 [53.4, 6.05, -4.0, Bay.OFFICE], [0.0, 6.55, -3.12, Bay.BRICK]],
	[[86.0, 3.8, -3.1, Bay.VENTILATION], [96.2, 6.1, -4.05, Bay.SWITCHGEAR],
	 [108.2, 5.9, -3.14, Bay.WORKSHOP], [119.0, 6.35, -4.1, Bay.OFFICE],
	 [0.0, 6.25, -3.18, Bay.BRICK]],
	[[149.0, 3.85, -3.45, Bay.VENTILATION], [158.5, 6.7, -3.0, Bay.BRICK],
	 [166.5, 5.65, -4.15, Bay.SWITCHGEAR], [0.0, 5.45, -3.25, Bay.WORKSHOP]],
	[[193.8, 5.8, -3.6, Bay.BRICK], [204.4, 6.2, -4.2, Bay.OFFICE],
	 [216.8, 5.5, -3.1, Bay.WORKSHOP], [0.0, 3.95, -3.9, Bay.VENTILATION]],
	[[247.1, 6.3, -3.3, Bay.BRICK], [0.0, 5.6, -4.1, Bay.SWITCHGEAR]],
]

var district_variant := 1
var cooling_plots: Array
var room_length: float
var _skins: Array[ShaderMaterial] = []
var _flashing := StandardMaterial3D.new()
const FLASHING_COLOR := Color("383d40")

func _ready() -> void:
	name = "ServiceYardBuildings"
	_flashing.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flashing.albedo_color = FLASHING_COLOR
	if district_variant == 4:
		_security_district()
		return
	if district_variant == 3:
		_freight_district()
		return
	if district_variant == 2:
		_pump_works()
		return
	var left := -8.0
	for group in range(GROUPS.size()):
		var plots: Array = GROUPS[group]
		var limit: float = cooling_plots[group] - 3.4 if group < cooling_plots.size() else room_length + 8.0
		for index in range(plots.size()):
			var entry: Array = plots[index]
			var right: float = limit if index == plots.size() - 1 else entry[0]
			_building(left, right, entry[1], entry[2], entry[3], index % 2 == 0)
			left = right
		if group < cooling_plots.size():
			left = cooling_plots[group] + 3.8

func set_brightness(value: float) -> void:
	for skin in _skins:
		skin.set_shader_parameter("brightness", value)
	_flashing.albedo_color = FLASHING_COLOR * (value / 0.5)

func _building(left: float, right: float, height: float, front: float, kind: Bay, roof_vent: bool) -> void:
	# A common rear line connects adjacent wings, even where the eaves or
	# frontage step. No independent backing wall sits behind the artwork.
	const REAR := -7.4
	var width := right - left
	var depth := front - REAR
	var building := Node3D.new()
	building.name = "%s_%03d" % [Bay.keys()[kind].capitalize(), int(right)]
	building.position = Vector3((left + right) * 0.5, -0.02, (front + REAR) * 0.5)
	building.add_to_group("miko8_budget_visual")
	building.set_meta("budget_half_width", width * 0.5 + 2.0)
	add_child(building)
	var size := Vector3(width, height, depth)
	var art: Array = FACADES[kind]
	var crop: Rect2 = art[1]
	var skin := ShaderMaterial.new()
	skin.shader = BUILDING_SKIN
	skin.set_shader_parameter("facade", art[0])
	if crop.has_area():
		skin.set_shader_parameter("facade_rect", Vector4(crop.position.x / 2048.0, crop.position.y / 683.0, crop.size.x / 2048.0, crop.size.y / 683.0))
	skin.set_shader_parameter("panels", PANELS)
	skin.set_shader_parameter("concrete", CONCRETE)
	skin.set_shader_parameter("dimensions", size)
	skin.set_shader_parameter("facade_gain", art[2])
	_skins.append(skin)
	_box(building, "WallsAndRoof", Vector3.UP * height * 0.5, size, skin)
	_box(building, "Eaves", Vector3(0, height - .065, depth * .5), Vector3(width, .14, .13), _flashing)
	_box(building, "FoundationCourse", Vector3(0, .065, .03), Vector3(width, .13, depth + .06), _flashing)
	var vent_x := width * (0.26 if roof_vent else -0.23)
	_roof_outlet(building, Vector3(vent_x, height, depth * .1), 1.6 if kind == Bay.OFFICE else 2.0)
	if kind == Bay.VENTILATION:
		_roof_outlet(building, Vector3(vent_x - 1.25, height, depth * .1), 1.45)

func _roof_outlet(building: Node3D, at: Vector3, size: float) -> void:
	var vent: Node3D = EXHAUST.instantiate()
	vent.name = "RoofExhaust"
	vent.position = at
	vent.scale = Vector3.ONE * size
	building.add_child(vent)
	for mesh: MeshInstance3D in vent.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(mesh.mesh.get_surface_count()):
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			if source:
				var paint := source.duplicate() as StandardMaterial3D
				paint.vertex_color_use_as_albedo = true
				paint.albedo_color = Color("899398")
				mesh.set_surface_override_material(surface, paint)

func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.name = label
	visual.mesh = mesh
	visual.position = at
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)

func _pump_works() -> void:
	# Whole wings join the dedicated cooling station at its actual footprint.
	var plots := [
		[6.0,5.6,-3.8,Bay.OFFICE], [18.5,5.2,-3.1,Bay.WORKSHOP],
		[29.0,6.1,-4.0,Bay.SWITCHGEAR], [43.0,4.0,-3.2,Bay.VENTILATION],
		[51.0,5.8,-4.1,Bay.BRICK], [63.0,5.0,-3.6,Bay.WORKSHOP],
		[73.0,6.2,-4.1,Bay.OFFICE], [84.6,5.4,-3.2,Bay.SWITCHGEAR],
		[103.0,5.7,-3.8,Bay.BRICK], [117.0,4.0,-3.1,Bay.VENTILATION],
		[130.0,5.4,-4.0,Bay.WORKSHOP], [140.0,6.2,-3.5,Bay.OFFICE],
		[151.0,4.1,-3.2,Bay.VENTILATION], [164.0,5.7,-4.0,Bay.SWITCHGEAR],
		[room_length+8.0,5.5,-3.3,Bay.WORKSHOP],
	]
	var left := -8.0
	for index in range(plots.size()):
		var plot: Array = plots[index]
		_building(left, plot[0], plot[1], plot[2], plot[3], index % 2 == 0)
		left = 91.8 if index == 7 else float(plot[0])

func _freight_district() -> void:
	# Shipping halls and service wings, with clear plots for both cooling stations.
	# Low rooflines behind the launch landings preserve their silhouettes.
	var plots := [
		[7.5,5.7,-3.8,Bay.OFFICE], [21.0,5.1,-3.2,Bay.WORKSHOP],
		[34.0,4.3,-4.0,Bay.VENTILATION], [45.0,5.6,-3.4,Bay.SWITCHGEAR],
		[61.6,4.1,-4.1,Bay.WORKSHOP],
		[81.5,5.7,-3.5,Bay.BRICK], [102.0,4.0,-4.1,Bay.VENTILATION],
		[114.0,5.8,-3.3,Bay.SWITCHGEAR], [126.0,5.0,-4.0,Bay.WORKSHOP],
		[137.0,5.8,-3.5,Bay.OFFICE], [148.0,5.1,-4.0,Bay.WORKSHOP],
		[162.6,4.0,-3.4,Bay.VENTILATION],
		[180.0,5.6,-3.9,Bay.BRICK], [room_length+8.0,5.1,-3.2,Bay.SWITCHGEAR],
	]
	var left := -8.0
	for index in range(plots.size()):
		var plot: Array = plots[index]
		_building(left, plot[0], plot[1], plot[2], plot[3], index % 2 == 0)
		left = float(plot[0])

func _security_district() -> void:
	# Connected depot wings; the only gap is filled by the complete cooling station.
	var plots := [
		[8.0, 5.8, -3.9, Bay.OFFICE], [24.0, 5.4, -3.15, Bay.SWITCHGEAR],
		[35.0, 4.2, -3.65, Bay.VENTILATION], [46.0, 5.8, -3.75, Bay.BRICK],
		[58.0, 5.2, -3.2, Bay.WORKSHOP], [68.0, 5.9, -3.5, Bay.OFFICE],
		[78.0, 4.0, -4.1, Bay.VENTILATION], [89.0, 5.6, -3.8, Bay.SWITCHGEAR],
		[105.0, 4.2, -3.8, Bay.VENTILATION], [115.6, 5.1, -3.3, Bay.WORKSHOP],
		[136.0, 5.9, -3.9, Bay.OFFICE], [148.0, 5.4, -3.6, Bay.BRICK],
		[165.0, 4.3, -4.0, Bay.VENTILATION], [room_length + 8.0, 6.3, -3.3, Bay.SWITCHGEAR],
	]
	var left := -8.0
	for index in range(plots.size()):
		var plot: Array = plots[index]
		_building(left, plot[0], plot[1], plot[2], plot[3], index % 2 == 0)
		left = float(plot[0])
		if index == 9: left = 122.8
