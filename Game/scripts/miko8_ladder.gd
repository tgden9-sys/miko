extends Node3D
@export var height:=3.2
@export var dismount_side:=1
@export var above_platform:=1.5
@export var extended_rungs:=true
@export var curved_top:=false
@export var rung_spacing:=.23898
@export var rung_offset:=0.0
@export var rail_half_width:=.255
@export var industrial_model:=true
var gameplay_detail := false
## Opt-in: geometry and authored character motion share this local frame.
@export var side_mount:=false
const SIDE_ROOF_INSET := .24
const SIDE_CLIMB_STANDOFF := .46
static var safety_paint:ShaderMaterial
static var tread_paint:ShaderMaterial
func motion_point(value:Array)->Vector3:
	var p:=Vector3(-value[0],value[1],-value[2])
	if side_mount:
		# Finish with both feet inside the coping. Keep the rung phase unchanged.
		p.z-=SIDE_ROOF_INSET*smoothstep(.32,.81807,-p.z)
		return global_basis*p
	return p
func motion_origin()->Vector3:
	return global_position+global_basis*Vector3(0,0,SIDE_CLIMB_STANDOFF) if side_mount else Vector3(climb_x,bottom_y,0)
func top_entry_position()->Vector3:
	return motion_origin()+motion_point([0.,height,.81807])
func climb_yaw()->float:
	return PI+global_rotation.y if side_mount else PI
var top_y:float:
	get:return global_position.y+height
var bottom_y:float:
	get:return global_position.y
var climb_x:float:
	get:return global_position.x
func _ready()->void:
	add_to_group("miko8_ladders")
	if industrial_model:
		_build_industrial();return
	var steel:=_safety_material(Color("b88a55"))
	var visible_height:=height+above_platform
	var rail_height:=visible_height-.08 if curved_top else visible_height+.075
	for x in [-rail_half_width,rail_half_width]:
		var rail:=MeshInstance3D.new()
		var shape:=CylinderMesh.new()
		shape.top_radius=0.035
		shape.bottom_radius=0.035
		shape.height=rail_height+.075
		rail.mesh=shape
		rail.material_override=steel
		rail.position=Vector3(x,(rail_height-.075)/2,0)
		add_child(rail)
		if curved_top:
			var points:Array[Vector3]=[]
			for index in range(7):
				var angle:=float(index)/6.*PI*.5
				points.append(Vector3(x,height+above_platform-.08+.08*sin(angle),-.08+.08*cos(angle)))
			points.append(Vector3(x,height+above_platform,-.37))
			for index in range(points.size()-1):
				var a:Vector3=points[index];var b:Vector3=points[index+1]
				var curve:=MeshInstance3D.new();var tube:=CylinderMesh.new()
				tube.top_radius=.035;tube.bottom_radius=.035;tube.height=a.distance_to(b);tube.radial_segments=16
				curve.mesh=tube;curve.material_override=steel;curve.position=(a+b)*.5
				curve.quaternion=Quaternion(Vector3.UP,(b-a).normalized());add_child(curve)
	var rung_height:=visible_height if extended_rungs else height-.10
	for i in range(1,int((rung_height-rung_offset)/rung_spacing)+1):
		var rung:=MeshInstance3D.new()
		var shape:=BoxMesh.new()
		shape.size=Vector3(0.58,0.045,0.075)
		rung.mesh=shape
		rung.material_override=_safety_material(Color("919a94"),true)
		rung.position.y=i*rung_spacing+rung_offset
		add_child(rung)
	var parts: Array[MeshInstance3D] = []
	for child in find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D:
			parts.append(child)
	preload("res://scripts/miko8_static_mesh_batch.gd").bake(self, parts)
	for p in parts:
		p.queue_free()
	add_to_group("miko8_budget_visual")
	set_meta("budget_half_width", rail_half_width + 1.0)
func _part(asset:String,at:Vector3,stretch:=Vector3.ONE)->void:
	var suffix := "_gameplay" if gameplay_detail else ""
	var part:Node3D=load("res://models/environment/industrial_ladder/"+asset+suffix+".glb").instantiate()
	part.name=asset;part.position=at;part.scale=stretch;add_child(part)
	for mesh:MeshInstance3D in part.find_children("*","MeshInstance3D",true,false):
		mesh.layers=4
		if asset in ["rail_1m","roof_return"]:
			if not safety_paint:
				safety_paint=_safety_material(Color("b88a55"))
			mesh.material_override=safety_paint
		elif asset=="grip_rung":
			if not tread_paint:
				tread_paint=_safety_material(Color("919a94"),true)
			mesh.material_override=tread_paint
		for i in range(mesh.mesh.get_surface_count()):
			var paint:=mesh.get_active_material(i) as StandardMaterial3D
			if paint:paint.vertex_color_use_as_albedo=true
func _build_industrial()->void:
	var visible_height:=height+above_platform
	var rail_height:=visible_height-.08 if curved_top else visible_height+.075
	for x:float in [-rail_half_width,rail_half_width]:
		_part("rail_1m",Vector3(x,0,0),Vector3(1.,rail_height,1.))
		var y:=.32
		while y<height-.22:
			_part("wall_standoff",Vector3(x,y,0));y+=1.15
		if curved_top:_part("roof_return",Vector3(x,visible_height,0))
	var rung_height:=visible_height if extended_rungs else height-.10
	for i in range(1,int((rung_height-rung_offset)/rung_spacing)+1):
		_part("grip_rung",Vector3(0,i*rung_spacing+rung_offset,0),Vector3(rail_half_width/.215,1.,1.))
	var parts: Array[MeshInstance3D] = []
	for child in find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D:
			parts.append(child)
	preload("res://scripts/miko8_static_mesh_batch.gd").bake(self, parts)
	for child in get_children():
		if child is Node3D and child.get_child_count() > 0:
			child.queue_free()
	add_to_group("miko8_budget_visual")
	set_meta("budget_half_width", rail_half_width + 1.0)

func _safety_material(color:Color,tread:=false)->ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/miko8_ladder_safety.gdshader")
	material.set_shader_parameter("paint",color)
	material.set_shader_parameter("tread",tread)
	return material
