extends Node3D

const Kit := preload("res://scripts/lab_art_kit.gd")
const DEPTH_SHADER := preload("res://shaders/lab_cutaway_depth.gdshader")
const MIST_WIDTH := 3.8
const MIST_OFFSET := .48
var occupied: Array[Vector2] = []

func build(contours: Array[PackedVector2Array], layout: RefCounted, vents: Array, tint: Color, steel: ShaderMaterial) -> void:
	name = "CutawayDepth"
	var air := SurfaceTool.new()
	air.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := ShaderMaterial.new()
	material.shader = DEPTH_SHADER
	material.set_shader_parameter("spill_tint",tint)
	air.set_material(material)
	var fittings := Kit.new(self,steel)
	var ledges: Array[Vector3] = []
	for loop in contours:
		for index in range(loop.size()):
			var start := loop[index]
			var end := loop[(index+1)%loop.size()]
			if is_equal_approx(start.y,end.y) and end.x-start.x >= 4.3:
				ledges.append(Vector3(start.x,end.x,start.y))
	var outlet_limit := 2 if absf(layout.EXIT.x-layout.ENTRANCE.x) >= 40.0 else 1
	for vent: Vector3 in vents:
		for run in ledges:
			var site := Vector2(vent.x,run.z)
			if is_equal_approx(vent.y,run.z) and _fits(site,run,layout):
				occupied.append(site)
				break
		if occupied.size() >= outlet_limit:
			break
	if occupied.is_empty():
		# Some vents face a thin shelf or another room below. Find a deeper apron.
		ledges.sort_custom(func(first: Vector3, second: Vector3) -> bool: return first.y-first.x > second.y-second.x)
		for run in ledges:
			var site := Vector2((run.x+run.y)*.5-MIST_OFFSET,run.z)
			if _fits(site,run,layout):
				occupied.append(site)
				break
	if occupied.is_empty():
		return
	for site in occupied:
		_add_exhaust(fittings,air,site)
	fittings.finish()
	var effect := MeshInstance3D.new()
	effect.name = "EdgeMist"
	effect.mesh = air.commit()
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(effect)

func _fits(site: Vector2, run: Vector3, layout: RefCounted) -> bool:
	var center := site.x+MIST_OFFSET
	if center-run.x < MIST_WIDTH*.5+.15 or run.y-center < MIST_WIDTH*.5+.15:
		return false
	for outlet in occupied:
		if site.distance_to(outlet) < 9.0:
			return false
	for door: Vector3 in [layout.ENTRANCE,layout.EXIT]:
		if absf(site.x-door.x) < 2.25 and absf(site.y-door.y) < .75:
			return false
	for sample in range(1,5):
		for side in [-1,0,1]:
			if not layout.foreground_solid(Vector2(center+MIST_WIDTH*.5*side,site.y-sample*.25)):
				return false
	return site.y-1.0 >= layout.BOUNDS.position.y+.30

func _add_exhaust(kit: Kit, mesh: SurfaceTool, site: Vector2) -> void:
	var port := Vector3(site.x,site.y-.21,.825)
	kit.plate(port,Vector3(.68,.245,.097),Color("233238"))
	kit.plate(port+Vector3(0,-.019,.051),Vector3(.52,.145,.026),Color("11191c"))
	for vane in range(3):
		kit.box(port+Vector3((vane-1)*.13,-.020,.070),Vector3(.035,.087,.025),Color("536467"))
	var top_center := Vector3(site.x+MIST_OFFSET,site.y+.09,1.01)
	for uv: Vector2 in [Vector2(0,0),Vector2(1,1),Vector2(1,0),Vector2(0,0),Vector2(0,1),Vector2(1,1)]:
		mesh.set_uv(uv)
		mesh.set_uv2(Vector2(site.x,0))
		mesh.add_vertex(top_center+Vector3((uv.x-.5)*MIST_WIDTH,-uv.y,0))
