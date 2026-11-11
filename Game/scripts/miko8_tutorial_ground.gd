extends Node3D
## Real planar deck + front foundation + back rail. Source pixels are not stretched
## over generic boxes: each image region is mapped to its corresponding surface.
const WIDTH:=8.0
const DEPTH:=2.0
const PIECES:=[
	{"file":"service","back":242.0,"front":317.0,"rail":150.0},
	{"file":"pipes","back":326.0,"front":392.0,"rail":244.0},
	{"file":"bridge","back":250.0,"front":330.0,"rail":182.0},
	{"file":"crate_bay","back":334.0,"front":395.0,"rail":255.0}]
var pieces:Array[Node3D]=[]
func _ready()->void:
	name="PaintedGroundKit"
	for i in range(PIECES.size()):_piece(i,PIECES[i])
	# Bridge deck is continuous. This lesson has one jump obstacle: the real crate.
	var solid:=StaticBody3D.new()
	solid.name="ContinuousDeckCollision"
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new();box.size=Vector3(32,0.5,DEPTH)
	shape.shape=box;solid.position=Vector3(16,-0.25,0)
	solid.add_child(shape);add_child(solid)
	solid.add_to_group("tutorial_solids")
	for x:float in [-0.25,32.25]:
		var stop:=StaticBody3D.new();stop.position=Vector3(x,2,0)
		var wall:=CollisionShape3D.new()
		var boundary:=BoxShape3D.new();boundary.size=Vector3(0.5,5,3)
		wall.shape=boundary;stop.add_child(wall);add_child(stop)

func _material(texture:Texture2D,vertical:Vector2)->ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/tutorial_ground_piece.gdshader")
	material.set_shader_parameter("art",texture)
	material.set_shader_parameter("vertical_range",vertical/724.0)
	return material

func _surface(parent:Node3D,mesh:Mesh,at:Vector3,material:Material)->MeshInstance3D:
	var surface:=MeshInstance3D.new();surface.mesh=mesh
	surface.position=at;surface.material_override=material
	surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(surface)
	surface.add_to_group("miko8_budget_visual")
	surface.set_meta("budget_half_width",WIDTH/2)
	return surface

func _piece(index:int,definition:Dictionary)->void:
	var tile:=Node3D.new();tile.name="Module_"+definition.file
	tile.position.x=index*WIDTH+WIDTH/2;add_child(tile);pieces.append(tile)
	var texture:=load("res://art/tutorial/ground_kit/"+definition.file+".png") as Texture2D
	var top:=PlaneMesh.new();top.size=Vector2(WIDTH,DEPTH)
	_surface(tile,top,Vector3.ZERO,_material(texture,Vector2(definition.back,definition.front)))
	var height:float=(724.0-definition.front)*0.0042
	var face:=QuadMesh.new();face.size=Vector2(WIDTH,height)
	_surface(tile,face,Vector3(0,-height/2,DEPTH/2+0.002),_material(texture,Vector2(definition.front,724)))
	var rail_height:float=definition.back/(definition.back-definition.rail)*0.70
	var rail:=QuadMesh.new();rail.size=Vector2(WIDTH,rail_height)
	_surface(tile,rail,Vector3(0,rail_height/2,-DEPTH/2),_material(texture,Vector2(0,definition.back)))
