@tool
extends RefCounted

const PAINT := preload("res://shaders/lab_paint.gdshader")
const HALO := preload("res://shaders/lab_halo.gdshader")

static var paint_material: ShaderMaterial
static var lamp_material: StandardMaterial3D
static var mesh_arrays: Dictionary = {}
static var cube := BoxMesh.new()
static var tube := _cylinder()
static var face := QuadMesh.new()
static var shell := _chamfered_case()
static var ring := _ring()

var parent: Node3D
var batches: Array[Array] = [[], []]

func _init(root: Node3D) -> void:
	parent = root

static func _cylinder() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.height = 1.0
	mesh.top_radius = 0.5
	mesh.bottom_radius = 0.5
	mesh.radial_segments = 16
	mesh.rings = 0
	return mesh

static func _ring() -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = .92
	mesh.outer_radius = 1.0
	mesh.rings = 48
	mesh.ring_segments = 8
	return mesh

static func _chamfered_case() -> ArrayMesh:
	var corners := [
		Vector2(-.5,-.38),Vector2(-.5,.38),Vector2(-.38,.5),Vector2(.38,.5),
		Vector2(.5,.38),Vector2(.5,-.38),Vector2(.38,-.5),Vector2(-.38,-.5)
	]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in range(corners.size()):
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i+1)%corners.size()]
		var af := Vector3(a.x*.97,a.y*.97,.5)
		var bf := Vector3(b.x*.97,b.y*.97,.5)
		var am := Vector3(a.x,a.y,.34)
		var bm := Vector3(b.x,b.y,.34)
		var ab := Vector3(a.x,a.y,-.5)
		var bb := Vector3(b.x,b.y,-.5)
		for vertex: Vector3 in [Vector3(0,0,.5),af,bf,af,am,bf,bf,am,bm,am,ab,bm,bm,ab,bb,Vector3(0,0,-.5),bb,ab]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()

func box(at: Vector3, size: Vector3, color: Color, lit := false, rotation := Vector3.ZERO) -> void:
	_part(cube, at, size, color, lit, rotation)

func cylinder(at: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO, lit := false) -> void:
	_part(tube, at, size, color, lit, rotation)

func plate(at: Vector3, size: Vector3, color: Color) -> void:
	_part(shell, at, size, color, false, Vector3.ZERO)

func torus(at: Vector3, size: Vector3, color: Color, rotation: Vector3, lit := false) -> void:
	_part(ring, at, size, color, lit, rotation)

func _part(mesh: Mesh, at: Vector3, size: Vector3, color: Color, lit: bool, rotation: Vector3) -> void:
	var basis := Basis.from_euler(rotation).scaled_local(size)
	batches[int(lit)].append([mesh, Transform3D(basis, at), color])

func finish() -> void:
	if not paint_material:
		paint_material = ShaderMaterial.new()
		paint_material.shader = PAINT
		paint_material.set_shader_parameter("wear_map", load("res://art/lab_weathered_metal.png"))
	if not lamp_material:
		lamp_material = StandardMaterial3D.new()
		lamp_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lamp_material.vertex_color_use_as_albedo = true
		lamp_material.vertex_color_is_srgb = true

	var combined := ArrayMesh.new()
	for index in range(batches.size()):
		if batches[index].is_empty():
			continue
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(paint_material if index == 0 else lamp_material)
		var vertex_offset := 0
		for part: Array in batches[index]:
			var source: Mesh = part[0]
			if not mesh_arrays.has(source):
				mesh_arrays[source] = source.surface_get_arrays(0)
			var arrays: Array = mesh_arrays[source]
			var transform: Transform3D = part[1]
			var normal_basis := transform.basis.inverse().transposed()
			var color: Color = part[2]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			for vertex in range(vertices.size()):
				surface.set_color(color)
				surface.set_normal((normal_basis * normals[vertex]).normalized())
				surface.add_vertex(transform * vertices[vertex])
			if indices.is_empty():
				for vertex in range(vertices.size()):
					surface.add_index(vertex_offset + vertex)
			else:
				for vertex in indices:
					surface.add_index(vertex_offset + vertex)
			vertex_offset += vertices.size()
		surface.commit(combined)
		batches[index].clear()
	var node := MeshInstance3D.new()
	node.mesh = combined
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)

func quad(at: Vector3, size: Vector2, material: Material, rotation := Vector3.ZERO) -> void:
	var node := MeshInstance3D.new()
	node.mesh = face
	node.position = at
	node.rotation = rotation
	node.scale = Vector3(size.x, size.y, 1)
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)

func glow(at: Vector3, size: Vector2, color: Color, energy: float, rotation := Vector3.ZERO, flicker := 0.0) -> void:
	var material := ShaderMaterial.new()
	material.shader = HALO
	material.set_shader_parameter("light_color", color)
	material.set_shader_parameter("energy", energy)
	material.set_shader_parameter("flicker", flicker)
	quad(at, size, material, rotation)

func text(at: Vector3, caption: String, color: Color, height := 0.22, left := false) -> void:
	var label := Label3D.new()
	label.position = at
	label.text = caption
	label.pixel_size = height / 48.0
	label.font_size = 48
	label.outline_size = 0
	label.modulate = color
	if left:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(label)
