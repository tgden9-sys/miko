extends Node3D

var layout = preload("res://scripts/lab_cutaway_layout.gd")
var metal_tint := Color.WHITE
const Kit := preload("res://scripts/lab_art_kit.gd")
var trim: ShaderMaterial

func _ready() -> void:
	trim = Kit.bulkhead_paint().duplicate()
	var dark := StandardMaterial3D.new()
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.albedo_color = Color("020405")
	var cols := roundi(layout.BOUNDS.size.x/layout.CELL)
	var rows := roundi(layout.BOUNDS.size.y/layout.CELL)
	# Merge each row so geometry scales with the perimeter, not the room area.
	for row in range(rows):
		var column := 0
		while column < cols:
			var start := column
			if not _solid(column,row):
				column += 1
				continue
			while column < cols and _solid(column,row):
				column += 1
			var left: float = layout.BOUNDS.position.x+start*layout.CELL
			var bottom: float = layout.BOUNDS.position.y+row*layout.CELL
			var width: float = (column-start)*layout.CELL
			var body := StaticBody3D.new()
			body.position = Vector3(left+width*.5,bottom+layout.CELL*.5,0)
			var shape := BoxShape3D.new()
			shape.size = Vector3(width,layout.CELL,4)
			var collision := CollisionShape3D.new()
			collision.shape = shape
			body.add_child(collision)
			add_child(body)
			var lining := MeshInstance3D.new()
			var solid_mesh := BoxMesh.new()
			solid_mesh.size = Vector3(width,layout.CELL,3.30)
			var arrays := solid_mesh.get_mesh_arrays()
			var colors := PackedColorArray()
			colors.resize(arrays[Mesh.ARRAY_VERTEX].size())
			colors.fill(Color("68777b") * metal_tint)
			arrays[Mesh.ARRAY_COLOR] = colors
			var textured_mesh := ArrayMesh.new()
			textured_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			lining.mesh = textured_mesh
			lining.position.z = -1.0
			lining.material_override = trim
			body.add_child(lining)
	# Foreground includes the tunnel cheeks, while physics keeps the passages open.
	for row in range(rows):
		var column := 0
		while column < cols:
			var start := column
			if not _front_solid(column,row):
				column += 1
				continue
			while column < cols and _front_solid(column,row):
				column += 1
			var left: float = layout.BOUNDS.position.x+start*layout.CELL
			var bottom: float = layout.BOUNDS.position.y+row*layout.CELL
			var width: float = (column-start)*layout.CELL
			var face := MeshInstance3D.new()
			var mesh := QuadMesh.new()
			mesh.size = Vector2(width+.002,layout.CELL+.002)
			face.mesh = mesh
			face.material_override = dark
			face.position = Vector3(left+width*.5,bottom+layout.CELL*.5,.66)
			add_child(face)
	# Merge exposed boundaries into continuous trim, using the same occupancy map.
	var edge_surface := SurfaceTool.new()
	edge_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	edge_surface.set_material(trim)
	var kit := Kit.new(self,trim)
	for row in range(rows):
		for side in [-1,1]:
			var column := 0
			while column < cols:
				if not (_front_solid(column,row) and not _front_solid(column,row+side)):
					column += 1
					continue
				var start := column
				while column < cols and _front_solid(column,row) and not _front_solid(column,row+side):
					column += 1
				var x: float = layout.BOUNDS.position.x+start*layout.CELL
				var y: float = layout.BOUNDS.position.y+(row+(1 if side > 0 else 0))*layout.CELL
				_edge(edge_surface,kit,Vector2(x,y),Vector2((column-start)*layout.CELL,0),side)
	for column in range(cols):
		for side in [-1,1]:
			var row := 0
			while row < rows:
				if not (_front_solid(column,row) and not _front_solid(column+side,row)):
					row += 1
					continue
				var start := row
				while row < rows and _front_solid(column,row) and not _front_solid(column+side,row):
					row += 1
				var x: float = layout.BOUNDS.position.x+(column+(1 if side > 0 else 0))*layout.CELL
				var y: float = layout.BOUNDS.position.y+start*layout.CELL
				_edge(edge_surface,kit,Vector2(x,y),Vector2(0,(row-start)*layout.CELL),side)
	var edging := MeshInstance3D.new()
	edging.mesh = edge_surface.commit()
	edging.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(edging)
	kit.finish()

func _solid(column: int,row: int) -> bool:
	return layout.solid(layout.BOUNDS.position+Vector2(column+.5,row+.5)*layout.CELL)

func _front_solid(column: int,row: int) -> bool:
	return layout.foreground_solid(layout.BOUNDS.position+Vector2(column+.5,row+.5)*layout.CELL)

func _edge(surface: SurfaceTool, kit: Kit, start: Vector2, extent: Vector2, side: int) -> void:
	var horizontal := extent.x > 0
	var length := extent.length()
	var along := extent/length
	var inward := Vector2(0,-side) if horizontal else Vector2(-side,0)
	var end := start+extent
	# The same profile ends on the 45 degree joint for both adjoining edges.
	var start_mitre := -1.0 if layout.foreground_solid(start+(inward-along)*.25) else 1.0
	var end_mitre := -1.0 if layout.foreground_solid(end+(inward+along)*.25) else 1.0
	var profile := [Vector2(0,.665),Vector2(.055,.81),Vector2(.105,.81),
		Vector2(.15,.75),Vector2(.19,.75),Vector2(.235,.815),
		Vector2(.30,.815),Vector2(.36,.68)]
	var colors := [Color("63777a"),Color("a6b4b0"),Color("52636a"),
		Color("17272c"),Color("34484c"),Color("43585d"),Color("18262c")]
	for index in range(colors.size()):
		var outer: Vector2 = profile[index]
		var inner: Vector2 = profile[index+1]
		var a := _rim_vertex(start, inward+along*start_mitre, outer)
		var b := _rim_vertex(end, inward-along*end_mitre, outer)
		var c := _rim_vertex(end, inward-along*end_mitre, inner)
		var d := _rim_vertex(start, inward+along*start_mitre, inner)
		var vertices := [a,b,c,a,c,d] if along.cross(inward) < 0 else [a,c,b,a,d,c]
		for vertex: Vector3 in vertices:
			surface.set_color(colors[index] * metal_tint)
			surface.set_normal(Vector3.BACK)
			surface.add_vertex(vertex)
	if horizontal and side > 0 and length > 2:
		var sections := ceili(length/3.3)
		for index in range(sections):
			var x: float = start.x+length*(index+.5)/sections
			kit.box(Vector3(x,start.y-.26,.825),Vector3(.30,.025,.02),Color("9fbcbe") * metal_tint,true)

func _rim_vertex(point: Vector2, direction: Vector2, profile: Vector2) -> Vector3:
	var offset := point+direction*profile.x
	return Vector3(offset.x,offset.y,profile.y)
