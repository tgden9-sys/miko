extends Node3D

const Kit := preload("res://scripts/lab_art_kit.gd")
enum Machine { PUMP, PRESSURE, FAN, PISTON, VALVES, EMPTY }

var shaft_material: StandardMaterial3D
var column_material: StandardMaterial3D
var bay_materials: Array[StandardMaterial3D] = []
const INK := Color("151d25")
const VOID := Color("0e181f")
const IRON := Color("354048")
const STEEL := Color("515a5b")
const EDGE := Color("8d8b7c")
const FLOOR := Color("78817f")
const AMBER := Color("ffbd73")
const ALONG_X := Vector3(0,0,PI/2)


func _ready() -> void:
	var atlas := load("res://art/lab_sealed_bays.webp") as Texture2D
	for slot in range(Machine.size()):
		var material := _scenery_material(atlas)
		# Inset the UVs by one pixel to keep the edges of neighbouring cells out.
		var padding := Vector2.ONE / Vector2(atlas.get_size())
		material.uv1_scale = Vector3(1.0/3.0-2.0*padding.x,.5-2.0*padding.y,1)
		material.uv1_offset = Vector3(float(slot%3)/3.0+padding.x,floorf(slot/3.0)*.5+padding.y,0)
		bay_materials.append(material)
	shaft_material = _scenery_material(load("res://art/lab_shaft_finished.webp"))
	column_material = shaft_material.duplicate() as StandardMaterial3D
	column_material.uv1_scale = Vector3(.179,1.0,1.0)
	column_material.uv1_offset = Vector3(.013,0,0)
	_hall("WakeBay",0,18,0,[Machine.EMPTY,Machine.PUMP])
	_hall("Assembly",18,42,0,[Machine.EMPTY,Machine.PISTON,Machine.EMPTY])
	_hall("EastAccess",42,58,0,[Machine.EMPTY,Machine.EMPTY])
	_hall("Coolant",6,37,6,[Machine.FAN,Machine.EMPTY,Machine.PRESSURE,Machine.EMPTY])
	_hall("Exchange",37,58,6,[Machine.EMPTY,Machine.VALVES,Machine.EMPTY])
	_hall("Diagnostics",6,25,12,[Machine.EMPTY,Machine.EMPTY,Machine.PISTON])
	_hall("DataHall",25,49,12,[Machine.EMPTY,Machine.VALVES,Machine.EMPTY])
	_hall("UplinkAccess",49,65,12,[Machine.EMPTY,Machine.FAN])
	_hall("Dispatch",78,94,0,[Machine.EMPTY,Machine.EMPTY])
	_shaft("EastService",58,65,0,12)
	_shaft("WestService",0,6,6,18)
	_shaft("TransferDrop",65,78,0,18)
	_underfloor()

func _section(section_name: String, location: Vector3) -> Kit:
	var root := Node3D.new()
	root.name = section_name
	root.position = location
	add_child(root)
	return Kit.new(root)

func deck(start: float, end: float, level: float) -> void:
	var x := start
	while x < end:
		var width := minf(5.0,end-x)
		var kit := _section("DeckSkin",Vector3(x+width*.5,level,0))
		kit.box(Vector3(0,-.07,0),Vector3(width-.016,.14,3.7),FLOOR)
		kit.box(Vector3(0,-.28,0),Vector3(width-.018,.3,3.61),INK)
		kit.box(Vector3(0,-.205,1.82),Vector3(width-.04,.10,.09),STEEL)
		kit.box(Vector3(0,-.049,1.859),Vector3(width-.06,.035,.025),Color("aaa99d"))
		kit.box(Vector3(0,-.34,1.831),Vector3(width-.24,.13,.08),IRON)
		kit.box(Vector3(0,.006,-1.3),Vector3(width-.08,.012,.046),Color("a88b59"))
		kit.box(Vector3(0,.006,1.19),Vector3(width-.13,.012,.043),IRON)
		for fraction in [-.27,.27]:
			kit.box(Vector3(width*float(fraction),.007,1.42),Vector3(width*.25,.014,.13),STEEL)
		for fraction in [-.37,0.0,.37]:
			var joint := width*float(fraction)
			kit.box(Vector3(joint,-.29,1.886),Vector3(.11,.25,.04),STEEL)
			kit.box(Vector3(joint,-.038,1.893),Vector3(.045,.032,.02),INK)
		if width > 2.0:
			kit.box(Vector3(0,-.235,1.888),Vector3(.94,.068,.034),INK)
			kit.box(Vector3(0,-.232,1.912),Vector3(.72,.023,.017),AMBER,true)
		kit.finish()
		x += width

func column(at: Vector3, size: Vector3, marked: bool) -> void:
	var kit := _section("Bulkhead",at)
	kit.box(Vector3.ZERO,size,Color("423029") if marked else Color("282d2b"))
	var face := column_material
	var rail_width := .115 if marked else .026
	var rail_color := Color("bc814a") if marked else Color("524b3f")
	if marked:
		face = column_material.duplicate() as StandardMaterial3D
		face.albedo_color = Color("c9a88c")
	var count := ceili(size.y / 3.2)
	var segment := size.y/count
	for row in range(count):
		var y := -size.y*.5 + (float(row)+.5)*segment
		kit.quad(Vector3(0,y,size.z*.5+.009),Vector2(size.x-.025,segment),face)
		if row > 0:
			kit.box(Vector3(0,y-segment*.5,size.z*.5+.032),Vector3(size.x-.004,.075,.08),Color("544d40"))
	for side in [-1.0,1.0]:
		kit.box(Vector3(side*(size.x*.5-rail_width*.5),0,size.z*.5+.018),Vector3(rail_width,size.y,.034),rail_color)
	if marked:
		for row in range(count):
			var y := -size.y*.5 + (float(row)+.5)*segment
			var band := Vector3(0,y,size.z*.5+.049)
			kit.box(band,Vector3(size.x-.04,.26,.047),Color("a77846"))
			for stripe in range(5):
				var x := (float(stripe)-2.0)*.17
				kit.box(band+Vector3(x,0,.029),Vector3(.058,.269,.015),INK,false,Vector3(0,0,-.45))
	kit.finish()

func _hall(title: String, start: float, end: float, level: float, machines: Array[int]) -> void:
	var count := machines.size()
	var width := (end-start)/count
	for i in range(count):
		var x := start + width*(float(i)+.5)
		var kit := _section(title + "Bay", Vector3(x,level,0))
		kit.quad(Vector3(0,2.80,-3.04),Vector2(width,6.0),bay_materials[machines[i]])

func _scenery_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.texture_repeat = false
	return material

func _shaft(title: String, start: float, end: float, bottom: float, top: float) -> void:
	var width := end-start
	var height := top-bottom
	var kit := _section(title,Vector3((start+end)*.5,bottom,0))
	var section_count := ceili(height / (9.0 if width > 9.0 else 6.0))
	var section_height := height / section_count
	for section in range(section_count):
		var y := (float(section)+.5)*section_height
		kit.quad(Vector3(0,y-.20,-3.04),Vector2(width,section_height),shaft_material)

	kit.finish()

func _underfloor() -> void:
	for bay in range(16):
		var kit := _section("FoundationBay",Vector3((float(bay)+.5)*5.875,0,0))
		kit.box(Vector3(0,-1.66,-.27),Vector3(5.875,2.55,2.94),VOID)
		kit.box(Vector3(-2.86,-1.36,1.32),Vector3(.24,1.92,.28),IRON)
		kit.box(Vector3(0,-1.93,1.32),Vector3(5.875,.22,.30),IRON)
		kit.cylinder(Vector3(0,-.87,1.18),Vector3(.29,5.875,.29),STEEL,ALONG_X)
		kit.cylinder(Vector3(0,-1.26,1.11),Vector3(.13,5.875,.13),IRON,ALONG_X)
		for x in [-1.77,1.77]:
			kit.cylinder(Vector3(x,-.87,1.18),Vector3(.40,.19,.4),IRON,ALONG_X)
		kit.box(Vector3(0,-.69,1.364),Vector3(.86,.059,.046),AMBER.darkened(.36),true)
		kit.finish()
