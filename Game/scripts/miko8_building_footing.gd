extends Node3D
var mirror_x:=false
var l_shaped:=true
var rectangle_size:=Vector2(5.44,2.55)
var material:ShaderMaterial
func _ready()->void:
	name="GroundedConcreteFooting"
	material=ShaderMaterial.new();material.shader=preload("res://shaders/miko8_building_footing.gdshader")
	if l_shaped:
		_plinth(Vector2(4.58,2.88),Vector2(-1.15 if mirror_x else 1.15,0))
		_plinth(Vector2(2.38,1.42),Vector2(2.25 if mirror_x else -2.25,-.73))
		_drain(Vector3(-1.15 if mirror_x else 1.15,.016,1.53),4.3)
	else:
		_plinth(rectangle_size+Vector2(.08,.08),Vector2.ZERO)
		_drain(Vector3(0,.016,rectangle_size.y*.5+.13),rectangle_size.x-.18)
func _quad(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3)->void:
	var normal:Vector3=(b-a).cross(c-a).normalized()
	for p:Vector3 in [a,b,c,a,c,d]:surface.set_normal(normal);surface.add_vertex(p)
func _plinth(size:Vector2,centre:Vector2)->void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings:Array=[]
	for band:int in range(3):
		var inset:=.022 if band==2 else 0.
		var y:float=[-.025,.13,.17][band]
		var ring:Array[Vector3]=[]
		for corner:Vector2 in [Vector2(-1,-1),Vector2(-1,1),Vector2(1,1),Vector2(1,-1)]:
			var p:Vector2=centre+corner*(size*.5-Vector2.ONE*inset);ring.append(Vector3(p.x,y,p.y))
		rings.append(ring)
	for band:int in range(2):
		for i:int in range(4):
			var j:=(i+1)%4;_quad(surface,rings[band][i],rings[band][j],rings[band+1][j],rings[band+1][i])
	_quad(surface,rings[2][0],rings[2][1],rings[2][2],rings[2][3])
	var visual:=MeshInstance3D.new();visual.mesh=surface.commit();visual.material_override=material;visual.layers=4;add_child(visual)
func _drain(at:Vector3,width:float)->void:
	var visual:=MeshInstance3D.new();visual.name="WallDrainChannel";visual.position=at
	var shape:=BoxMesh.new();shape.size=Vector3(width,.022,.16);visual.mesh=shape
	var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_ground_drain.gdshader")
	visual.material_override=paint;visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(visual)
