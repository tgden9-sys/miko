extends Node3D
## Supplied ladder building, fitted to the existing climbing motion.
const LADDER_X:=18.3
const TOP_Y:=2.83364
var ladder:Node3D
@export var building_x:=20.6
@export var roof_height:=TOP_Y
@export var site_name:="LadderBuilding"
@export var attach_ladder:=true
@export var mirror_front:=false
@export var custom_facade:=""
static var mirrored_meshes:Dictionary={}

func _ready()->void:
	name=site_name
	var model:Node3D=load("res://models/environment/ladder_building/ladder_building.glb").instantiate()
	model.name="CleanedLadderBuilding";model.scale=Vector3(6.8/1.903564,(roof_height+.008)/1.004187,2.8/1.460719)
	model.position=Vector3(building_x,-.008,-.39);add_child(model)
	var skin:=ShaderMaterial.new();skin.shader=preload("res://shaders/miko8_ladder_building_skin.gdshader")
	skin.set_shader_parameter("facade",preload("res://art/materials/ladder_building/industrial_service_wall_v1.png"))
	skin.set_shader_parameter("concrete",preload("res://art/materials/ladder_building/weathered_concrete_tile_v1.png"))
	skin.set_shader_parameter("building_origin",Vector3(building_x,0.,-.39));skin.set_shader_parameter("building_height",roof_height)
	if mirror_front:skin.set_shader_parameter("facade_start_x",-3.20)
	if not custom_facade.is_empty():
		skin.set_meta("cel_facade_art",custom_facade);skin.set_shader_parameter("facade_height",roof_height)
		if "departure" in custom_facade:skin.set_shader_parameter("facade_end_v",.955)
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		mesh.layers=4
		if mirror_front:mesh.mesh=_mirror(mesh.mesh)
		mesh.create_trimesh_collision()
		for index in range(mesh.mesh.get_surface_count()):
			mesh.set_surface_override_material(index,skin)
	model.add_to_group("miko8_budget_visual");model.set_meta("budget_half_width",4.0)
	if building_x!=20.6:
		var contact:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(8.,4.1);contact.mesh=plane
		var shadow:=ShaderMaterial.new();shadow.shader=preload("res://shaders/miko8_ladder_building_contact.gdshader")
		shadow.set_shader_parameter("mirror_x",mirror_front)
		contact.material_override=shadow;contact.position=Vector3(building_x,.012,-.39);contact.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(contact)
	var footing:=preload("res://scripts/miko8_building_footing.gd").new()
	footing.position=Vector3(building_x,0.,-.39);footing.mirror_x=mirror_front;add_child(footing)
	if not attach_ladder:return
	var ladder_x:=building_x-2.3
	ladder=preload("res://scripts/miko8_ladder.gd").new()
	ladder.name="ServiceLadder";ladder.height=roof_height;ladder.above_platform=0.
	ladder.extended_rungs=false;ladder.curved_top=true
	ladder.rung_spacing=.2648;ladder.rung_offset=-.08;ladder.rail_half_width=.215
	ladder.set_meta("direct_entry",true);ladder.set_meta("bpg_ladder",true);ladder.set_meta("top_entry_x",ladder_x)
	ladder.dismount_side=1;ladder.position=Vector3(ladder_x,0,-.46);add_child(ladder)
	print("LADDER_BUILDING_READY roof=",roof_height)
func _mirror(source:Mesh)->ArrayMesh:
	if mirrored_meshes.has(source):return mirrored_meshes[source]
	var result:=ArrayMesh.new()
	for surface in range(source.get_surface_count()):
		var arrays:=source.surface_get_arrays(surface)
		var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		for i in range(points.size()):points[i].x=-points[i].x
		for i in range(normals.size()):normals[i].x=-normals[i].x
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		for i in range(0,indices.size(),3):
			var old:=indices[i+1];indices[i+1]=indices[i+2];indices[i+2]=old
		if arrays[Mesh.ARRAY_TANGENT]!=null:
			var tangents:PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
			for i in range(0,tangents.size(),4):tangents[i]=-tangents[i];tangents[i+3]=-tangents[i+3]
			arrays[Mesh.ARRAY_TANGENT]=tangents
		arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mirrored_meshes[source]=result;return result

