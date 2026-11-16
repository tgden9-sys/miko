extends Node3D
## Static, rounded cutaway kit. Uses the shell's occupancy for every joint;
## collision stays owned by the shell. No per-frame geometry or extra lights.

const Kit := preload("res://scripts/lab_art_kit.gd")
const RADIUS := 0.24
const ARC_STEPS := 8
# Clear the side lining between the portal's jambs, leaving the near cutaway cheek intact.
const DOOR_REVEAL_MIN_Z := -2.10
const DOOR_REVEAL_MAX_Z := .44
const DOOR_REVEAL_HEIGHT := 2.32
var layout
var metal_tint := Color.WHITE
var authored_details := false
var show_exit_reveal := true
var extra_door_reveals: Array[Vector3] = []
var vents: Array = []
var depth_tint := Color.WHITE
var finish: ShaderMaterial
var triangle_count := 0

func _ready() -> void:
	name = "RoundedLabFinish"
	finish = ShaderMaterial.new()
	finish.shader = preload("res://shaders/lab_edge_finish.gdshader")
	finish.set_shader_parameter("steel_map", load("res://art/lab_bulkhead_steel.png"))
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
	black.albedo_color = Color("020405")
	var mask := SurfaceTool.new()
	mask.begin(Mesh.PRIMITIVE_TRIANGLES)
	mask.set_material(black)
	_build_mask(mask)
	_commit(mask, "CutawayFace")
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(finish)
	var loops := _contours()
	for loop: PackedVector2Array in loops:
		_build_rim(surface, loop)
	_commit(surface, "RoundedLining")
	var depth := preload("res://scripts/lab_cutaway_depth.gd").new()
	depth.build(loops,layout,vents,depth_tint,finish)
	add_child(depth)
	if authored_details:
		_build_details(depth.occupied)
	else:
		_build_room_details(loops,depth.occupied)
	set_meta("static_triangles", triangle_count)
	set_meta("contour_count", loops.size())

func _solid(point: Vector2) -> bool:
	return layout.foreground_solid(point)

func _count_at(corner: Vector2) -> int:
	var count := 0
	for offset in [Vector2(-.02,-.02),Vector2(.02,-.02),Vector2(.02,.02),Vector2(-.02,.02)]:
		if _solid(corner + offset):
			count += 1
	return count

func _arc_at(p: Vector2, prev: Vector2, next: Vector2, radius: float) -> PackedVector2Array:
	var incoming := (p - prev).normalized()
	var outgoing := (next - p).normalized()
	var center := p - incoming * radius + outgoing * radius
	var angle := (-outgoing).angle()
	var turn := atan2(incoming.cross(outgoing), incoming.dot(outgoing))
	var result := PackedVector2Array()
	for i in range(ARC_STEPS + 1):
		result.append(center + Vector2.from_angle(angle + turn * float(i) / ARC_STEPS) * radius)
	return result

func _build_mask(surface: SurfaceTool) -> void:
	var cols := roundi(layout.BOUNDS.size.x / layout.CELL)
	var rows := roundi(layout.BOUNDS.size.y / layout.CELL)
	for y in range(rows):
		for x in range(cols):
			var p: Vector2 = layout.BOUNDS.position + Vector2(x,y) * layout.CELL
			var corners := PackedVector2Array([p,p+Vector2(layout.CELL,0),p+Vector2.ONE*layout.CELL,p+Vector2(0,layout.CELL)])
			var solid := _solid(p + Vector2.ONE * layout.CELL * .5)
			var polygon := PackedVector2Array()
			for c in range(4):
				var corner := corners[c]
				var count := _count_at(corner)
				if solid:
					var opposite: Vector2 = (corner - p - Vector2.ONE * layout.CELL * .5).sign()
					var diagonal := count == 2 and _solid(corner+opposite*.02)
					if count == 1 or diagonal:
						polygon.append_array(_arc_at(corner, corners[(c+3)%4], corners[(c+1)%4], RADIUS))
					else:
						polygon.append(corner)
				elif count == 3:
					# Fill only the little rounded return in an otherwise open cell.
					var fillet := PackedVector2Array([corner])
					fillet.append_array(_arc_at(corner, corners[(c+3)%4], corners[(c+1)%4], RADIUS))
					_face(surface, fillet)
			if solid:
				_face(surface, polygon)

func _face(surface: SurfaceTool, points: PackedVector2Array) -> void:
	var indices := Geometry2D.triangulate_polygon(points)
	for index in indices:
		surface.set_normal(Vector3.BACK)
		surface.set_color(Color.WHITE)
		surface.add_vertex(Vector3(points[index].x, points[index].y, .665))
	triangle_count += indices.size() / 3

func _contours() -> Array[PackedVector2Array]:
	var edges := {}
	var cols := roundi(layout.BOUNDS.size.x / layout.CELL)
	var rows := roundi(layout.BOUNDS.size.y / layout.CELL)
	for y in range(rows):
		for x in range(cols):
			var center: Vector2 = layout.BOUNDS.position + Vector2(x+.5,y+.5) * layout.CELL
			if not _solid(center):
				continue
			# Directed edges keep solid material on the right, including door cheeks.
			if not _solid(center + Vector2.UP * layout.CELL):
				_add_edge(edges,Vector2i(x+1,y),Vector2i(x,y))
			if not _solid(center + Vector2.DOWN * layout.CELL):
				_add_edge(edges,Vector2i(x,y+1),Vector2i(x+1,y+1))
			if not _solid(center + Vector2.LEFT * layout.CELL):
				_add_edge(edges,Vector2i(x,y),Vector2i(x,y+1))
			if not _solid(center + Vector2.RIGHT * layout.CELL):
				_add_edge(edges,Vector2i(x+1,y+1),Vector2i(x+1,y))
	var result: Array[PackedVector2Array] = []
	while not edges.is_empty():
		var start: Vector2i = edges.keys()[0]
		for candidate: Vector2i in edges:
			if edges[candidate].size() == 1:
				start = candidate
				break
		var cursor := start
		var raw: Array[Vector2i] = []
		var incoming := Vector2i.ZERO
		while edges.has(cursor):
			var choices: Array = edges[cursor]
			var next: Vector2i = choices[0]
			# At a diagonal contact keep the two solid corners independent.
			var right := cursor + Vector2i(incoming.y,-incoming.x)
			if choices.size() > 1 and right in choices:
				next = right
			raw.append(cursor)
			choices.erase(next)
			if choices.is_empty():
				edges.erase(cursor)
			incoming = next-cursor
			cursor = next
			if cursor == start:
				break
		assert(cursor == start, "Cutaway perimeter must be closed")
		var points := PackedVector2Array()
		for i in range(raw.size()):
			var before := raw[i] - raw[(i + raw.size() - 1) % raw.size()]
			var after := raw[(i + 1) % raw.size()] - raw[i]
			if before != after:
				points.append(layout.BOUNDS.position + Vector2(raw[i]) * layout.CELL)
		result.append(points)
	return result

func _add_edge(edges: Dictionary, from: Vector2i, to: Vector2i) -> void:
	if not edges.has(from):
		edges[from] = []
	edges[from].append(to)

func _ring(points: PackedVector2Array, inset: float, corner_radius := RADIUS) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(points.size()):
		var p := points[i]
		var prev := points[(i + points.size() - 1) % points.size()]
		var next := points[(i + 1) % points.size()]
		var incoming := (p - prev).normalized()
		var outgoing := (next - p).normalized()
		var right_in := Vector2(incoming.y, -incoming.x)
		var right_out := Vector2(outgoing.y, -outgoing.x)
		var offset := (right_in + right_out) * inset
		var radius := corner_radius + inset * signf(incoming.cross(outgoing))
		result.append_array(_arc_at(p+offset, p+offset-incoming, p+offset+outgoing, radius))
	return result

func _build_rim(surface: SurfaceTool, points: PackedVector2Array) -> void:
	# Deep reveal, rolled nose, dark gasket, and one small inner return.
	# Extrude the same rounded section all the way to the rear wall. A smaller
	# rear radius leaves a square shoulder visible behind the rounded front lip.
	var profile := [Vector2(0,-2.65),Vector2(0,.65),Vector2(.012,.73),
		Vector2(.035,.79),Vector2(.070,.825),Vector2(.105,.83),
		Vector2(.135,.80),Vector2(.155,.73),Vector2(.173,.73),Vector2(.195,.68)]
	var colors := [Color("596568"),Color("627378"),Color("78898c"),Color("88999b"),
		Color("65787c"),Color("43575d"),Color("1a292f"),Color("101b21"),Color("2b3b42")]
	for band in range(profile.size()-1):
		var a: Vector2 = profile[band]
		var b: Vector2 = profile[band+1]
		var ring_a := _ring(points, a.x)
		var ring_b := _ring(points, b.x)
		for i in range(ring_a.size()):
			var j := (i+1) % ring_a.size()
			var normals := [_rim_normal(ring_a,i,b-a),_rim_normal(ring_a,j,b-a)]
			if band == 0:
				if _cut_door_reveal(surface,ring_a[i],ring_a[j],Vector2(a.y,b.y),normals,colors[band]):
					continue
			var vertices := [Vector3(ring_a[i].x,ring_a[i].y,a.y),Vector3(ring_a[j].x,ring_a[j].y,a.y),
				Vector3(ring_b[j].x,ring_b[j].y,b.y),Vector3(ring_b[i].x,ring_b[i].y,b.y)]
			_rim_quad(surface,vertices,normals,colors[band])

func _cut_door_reveal(surface: SurfaceTool, start: Vector2, end: Vector2, depth: Vector2, normals: Array, color: Color) -> bool:
	if is_equal_approx(start.y,end.y):
		return false
	var openings: Array[Vector2] = []
	var doors: Array[Vector3] = [layout.ENTRANCE]
	if show_exit_reveal:
		doors.append(layout.EXIT)
	doors.append_array(extra_door_reveals)
	for door in doors:
		var jamb := is_equal_approx(start.x,door.x) and is_equal_approx(end.x,door.x)
		var rounded_foot := (absf(start.x-door.x) <= RADIUS+.001 and absf(end.x-door.x) <= RADIUS+.001
			and maxf(start.y,end.y) <= door.y+RADIUS+.001)
		if not jamb and not rounded_foot:
			continue
		var low := maxf(minf(start.y,end.y),door.y)
		var high := minf(maxf(start.y,end.y),door.y+DOOR_REVEAL_HEIGHT)
		if high <= low:
			continue
		var from := inverse_lerp(start.y,end.y,low)
		var to := inverse_lerp(start.y,end.y,high)
		openings.append(Vector2(minf(from,to),maxf(from,to)))
	if openings.is_empty():
		return false
	openings.sort()
	var previous := 0.0
	for opening in openings:
		_reveal_strip(surface,start,end,Vector2(previous,opening.x),depth,normals,color)
		_reveal_strip(surface,start,end,opening,Vector2(depth.x,DOOR_REVEAL_MIN_Z),normals,color)
		_reveal_strip(surface,start,end,opening,Vector2(DOOR_REVEAL_MAX_Z,depth.y),normals,color)
		previous = opening.y
	_reveal_strip(surface,start,end,Vector2(previous,1),depth,normals,color)
	return true

func _reveal_strip(surface: SurfaceTool, start: Vector2, end: Vector2, range_along: Vector2, depth: Vector2, normals: Array, color: Color) -> void:
	if is_equal_approx(range_along.x,range_along.y):
		return
	var p := start.lerp(end,range_along.x)
	var q := start.lerp(end,range_along.y)
	_rim_quad(surface,[Vector3(p.x,p.y,depth.x),Vector3(q.x,q.y,depth.x),
		Vector3(q.x,q.y,depth.y),Vector3(p.x,p.y,depth.y)],
		[normals[0].lerp(normals[1],range_along.x).normalized(),
			normals[0].lerp(normals[1],range_along.y).normalized()],color)

func _rim_quad(surface: SurfaceTool, vertices: Array, normals: Array, color: Color) -> void:
	for index in [0,1,2,0,2,3]:
		surface.set_normal(normals[0] if index == 0 or index == 3 else normals[1])
		surface.set_color(color * metal_tint)
		surface.add_vertex(vertices[index])
	triangle_count += 2

func _rim_normal(ring: PackedVector2Array, index: int, profile_delta: Vector2) -> Vector3:
	var previous := ring[(index+ring.size()-1)%ring.size()]
	var next := ring[(index+1)%ring.size()]
	var along := ((ring[index]-previous).normalized()+(next-ring[index]).normalized()).normalized()
	var inward := Vector2(along.y,-along.x)
	return Vector3(-inward.x*profile_delta.y,-inward.y*profile_delta.y,profile_delta.x).normalized()

func _has_depth_fitting(site: Vector2, occupied: Array[Vector2]) -> bool:
	for fitting in occupied:
		if absf(site.y-fitting.y) < .20 and absf(site.x-fitting.x) < 1.02:
			return true
	return false

func _build_room_details(loops: Array[PackedVector2Array], occupied: Array[Vector2]) -> void:
	var kit := Kit.new(self,finish)
	var cable_sites: Array[Vector2] = []
	for loop in loops:
		for index in range(loop.size()):
			var start := loop[index]
			var end := loop[(index+1)%loop.size()]
			if not is_equal_approx(start.y,end.y):
				continue
			var span := end.x-start.x
			if span >= 2.5:
				# Small inset deck lights spaced along navigable edges.
				var count := maxi(1, floori(span/4.8))
				for slot in range(count):
					var x := start.x+span*(slot+.5)/count
					if _has_depth_fitting(Vector2(x,start.y),occupied):
						continue
					kit.plate(Vector3(x,start.y-.085,.84),Vector3(.38,.10,.065),Color("26363c")*metal_tint)
					kit.box(Vector3(x,start.y-.078,.879),Vector3(.19,.018,.009),Color("9bb6af")*metal_tint,true)
				if span >= 4.5:
					var x := start.x+span*.31
					if _has_depth_fitting(Vector2(x,start.y),occupied):
						continue
					kit.plate(Vector3(x,start.y-.31,.72),Vector3(.96,.18,.13),Color("26373e")*metal_tint)
					for joint in range(5):
						kit.box(Vector3(x+(joint-2)*.14,start.y-.31,.794),Vector3(.058,.087,.022),Color("59696a")*metal_tint)
			elif span <= -3.0:
				var site := start.lerp(end,.35)
				if not layout.solid(site-Vector2(.65,.55)) and not layout.solid(site+Vector2(.65,-.55)):
					cable_sites.append(site)
	# Use only a small number of hanging bundles to leave the room's focal points clear.
	for index in range(mini(cable_sites.size(),2)):
		var site := cable_sites[index]
		var half_span := .56+.13*index
		for strand in range(2):
			var path := PackedVector3Array()
			for sample in range(21):
				var t := float(sample)/20.0
				path.append(Vector3(site.x+lerpf(-half_span,half_span,t),site.y-.04-sin(t*PI)*(.22+strand*.14),-.94-strand*.12))
			_cable(path,.034 if strand == 0 else .024,Color("303d41")*metal_tint)
		for side: float in [-1.0,1.0]:
			kit.plate(Vector3(site.x+side*half_span,site.y-.05,-1.0),Vector3(.14,.13,.30),Color("536167")*metal_tint)
	kit.finish()

func _build_details(occupied: Array[Vector2]) -> void:
	var kit := Kit.new(self, finish)
	# Small replaceable service inserts, kept below the actual walking surface.
	for site in [Vector2(9.5,1),Vector2(21.25,2),Vector2(28.5,4),Vector2(38.5,5.5),Vector2(46,4)]:
		if _has_depth_fitting(site,occupied):
			continue
		kit.plate(Vector3(site.x,site.y-.32,.72),Vector3(1.30,.28,.14),Color("26363d"))
		kit.plate(Vector3(site.x,site.y-.32,.80),Vector3(1.07,.16,.025),Color("111b20"))
		for j in range(7):
			kit.box(Vector3(site.x+(j-3)*.13,site.y-.32,.822),Vector3(.055,.115,.025),Color("4b5e64"))
		for side in [-1,1]:
			kit.cylinder(Vector3(site.x+side*.57,site.y-.32,.81),Vector3(.045,.025,.045),Color("718185"),Vector3(PI*.5,0,0))
	# Restrained marker tabs; avoid the old continuous bright picture-frame stripe.
	for site in [Vector2(4.5,0),Vector2(12.2,0),Vector2(20.1,2),Vector2(27.1,4),Vector2(34.9,4),Vector2(42.3,4),Vector2(49.3,4)]:
		if _has_depth_fitting(site,occupied):
			continue
		kit.plate(Vector3(site.x,site.y-.085,.84),Vector3(.36,.10,.075),Color("26383e"))
		kit.box(Vector3(site.x,site.y-.077,.884),Vector3(.18,.016,.009),Color("849d9c"),true)
	# Local, attached cable bundles sit behind Miko and outside the jumping line.
	for cable_site in [Vector4(15.7,4.5,.94,.31),Vector4(24.4,7,1.28,.44),Vector4(33.3,8.5,1.58,.27)]:
		var anchor := Vector2(cable_site.x,cable_site.y)
		var span: float = cable_site.z
		for strand in range(2):
			var path := PackedVector3Array()
			for i in range(21):
				var t := float(i)/20
				path.append(Vector3(anchor.x-span*.5+t*span,anchor.y-.04-sin(t*PI)*(cable_site.w+strand*.13),-.94-strand*.12))
			_cable(path, .035 if strand == 0 else .025, Color("283238"))
		for side in [-1,1]:
			kit.plate(Vector3(anchor.x+side*span*.5,anchor.y-.06,-.99),Vector3(.15,.14,.27),Color("4e5c60"))
	# Vertical service conduit on the tall return, with curved ends and brackets.
	var pipe := PackedVector3Array()
	pipe.append(Vector3(26.78,.48,.82))
	for i in range(9):
		var angle := -PI*.5 - float(i)/8*PI*.5
		pipe.append(Vector3(26.68+cos(angle)*.18,.66+sin(angle)*.18,.82))
	pipe.append(Vector3(26.50,3.12,.82))
	for i in range(1,9):
		var angle := PI - float(i)/8*PI*.5
		pipe.append(Vector3(26.68+cos(angle)*.18,3.12+sin(angle)*.18,.82))
	pipe.append(Vector3(26.78,3.3,.82))
	# This conduit stays in the dark cross-section, leaving the gap unobstructed.
	for y in [.72,1.8,3.15]:
		kit.plate(Vector3(26.50,y,.80),Vector3(.20,.10,.13),Color("35464c"))
	_cable(pipe,.052,Color("34434a"))
	kit.finish()

func _cable(path: PackedVector3Array, radius: float, color: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(finish)
	for i in range(path.size()-1):
		var along := (path[i+1]-path[i]).normalized()
		var across := along.cross(Vector3.BACK).normalized()
		for j in range(8):
			var a := TAU*float(j)/8
			var b := TAU*float(j+1)/8
			var na := across*cos(a)+Vector3.BACK*sin(a)
			var nb := across*cos(b)+Vector3.BACK*sin(b)
			var verts := [path[i]+na*radius,path[i+1]+na*radius,path[i+1]+nb*radius,path[i]+nb*radius]
			for index in [0,1,2,0,2,3]:
				surface.set_color(color)
				surface.set_normal(na if index < 2 else nb)
				surface.add_vertex(verts[index])
			triangle_count += 2
	_commit(surface, "ServiceCable")

func _commit(surface: SurfaceTool, label: String) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = surface.commit()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
