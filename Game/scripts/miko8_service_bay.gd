extends Node3D
## Interchangeable facade dressing, aligned to the existing six-metre module.
## Geometry is built once per type and shared by every later placement.
@export_enum("Valve bay","Twin pipe bay") var variant:=0
static var geometry:Dictionary={}
static var materials:Dictionary={}
var parts:Array[Dictionary]=[]
var iron:Material
var oxide:Material
var bright:Material
var recess:Material

func _ready()->void:
	name="ValveServiceBay" if variant==0 else "TwinPipeServiceBay"
	iron=_material("iron",Color("45505a"),0.65)
	oxide=_material("oxide",Color("875436"),0.55)
	bright=_material("fasteners",Color("a29477"),0.7)
	recess=_material("recess",Color("202b32"),0.1)
	if not geometry.has(variant):
		_frame()
		if variant==0:_valve_bay()
		else:_twin_bay()
		geometry[variant]=_merge()
	var visual:=MeshInstance3D.new();visual.mesh=geometry[variant]
	visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual);visual.add_to_group("miko8_budget_visual");visual.set_meta("budget_half_width",6.0)
	var lamp:=OmniLight3D.new();lamp.position=Vector3(3.1,-0.65,2.0)
	lamp.light_color=Color("ffbd7c");lamp.light_energy=0.8;lamp.omni_range=1.9
	add_child(lamp);lamp.add_to_group("miko8_budget_visual");lamp.set_meta("budget_half_width",1.9)

func _material(key:String,color:Color,metal:float)->Material:
	if materials.has(key):return materials[key]
	var material:=ShaderMaterial.new();material.shader=preload("res://shaders/ortho_preview_wear.gdshader")
	material.set_shader_parameter("base_color",color)
	material.set_shader_parameter("metal",metal)
	material.set_shader_parameter("wear",preload("res://art/tutorial/ortho_materials/painted_steel.png"))
	material.set_shader_parameter("texture_scale",0.8)
	material.set_shader_parameter("bump_strength",0.0005)
	materials[key]=material;return material

func _glow(key:String,color:Color)->Material:
	if materials.has(key):return materials[key]
	var material:=StandardMaterial3D.new();material.albedo_color=color
	material.emission_enabled=true;material.emission=color;material.emission_energy_multiplier=0.8
	material.roughness=0.55;materials[key]=material;return material

func _part(mesh:Mesh,at:Vector3,material:Material,basis:=Basis.IDENTITY)->void:
	parts.append({"mesh":mesh,"transform":Transform3D(basis,at),"material":material})

func _box(at:Vector3,size:Vector3,material:Material)->void:
	var mesh:=BoxMesh.new();mesh.size=size;_part(mesh,at,material)

func _rod(a:Vector3,b:Vector3,radius:float,material:Material,sides:=12)->void:
	var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius
	mesh.height=a.distance_to(b);mesh.radial_segments=sides;mesh.rings=1
	_part(mesh,(a+b)/2,material,Basis(Quaternion(Vector3.UP,(b-a).normalized())))

func _bolt(at:Vector3,radius:=0.022)->void:
	_rod(at-Vector3(0,0,0.01),at+Vector3(0,0,0.012),radius,bright,6)

func _tube(points:Array[Vector3],radius:float,material:Material)->void:
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array()
	var uv:=PackedVector2Array();var indices:=PackedInt32Array();var distance:=0.0
	for i in range(points.size()):
		if i>0:distance+=points[i].distance_to(points[i-1])
		var tangent:Vector3=(points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]).normalized()
		var n:=tangent.cross(Vector3.FORWARD).normalized();var b:=tangent.cross(n).normalized()
		for side in range(13):
			var angle:=TAU*float(side)/12.0
			var normal:=n*cos(angle)+b*sin(angle)
			vertices.append(points[i]+normal*radius);normals.append(normal);uv.append(Vector2(float(side)/12,distance))
			if i>0 and side<12:
				var a:=(i-1)*13+side;var c:=i*13+side
				indices.append_array(PackedInt32Array([a,c,a+1,a+1,c,c+1]))
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	_part(mesh,Vector3.ZERO,material)

func _flange(at:Vector3,axis:Vector3,radius:=0.17)->void:
	_rod(at-axis*0.035,at+axis*0.035,radius,oxide,20)
	var n:=axis.cross(Vector3.FORWARD).normalized()
	if n.length()<0.1:n=Vector3.UP
	var b:=axis.cross(n).normalized()
	for i in range(6):
		var angle:=TAU*i/6.0
		var offset:Vector3=(n*cos(angle)+b*sin(angle))*(radius*0.77)
		_rod(at+offset-axis*0.048,at+offset+axis*0.048,0.014,bright,6)

func _frame()->void:
	# The frame projects from the wall, leaving the dark service panel recessed.
	_box(Vector3(3.1,-1.36,1.50),Vector3(2.7,1.75,0.06),recess)
	for x:float in [1.72,4.48]:
		_box(Vector3(x,-1.36,1.60),Vector3(0.10,1.90,0.18),iron)
		for y:float in [-0.51,-2.18]:_bolt(Vector3(x,y,1.70))
	for y:float in [-0.43,-2.27]:_box(Vector3(3.1,y,1.60),Vector3(2.86,0.10,0.18),iron)
	_box(Vector3(3.1,-0.57,1.72),Vector3(0.48,0.13,0.20),iron)
	_box(Vector3(3.1,-0.61,1.83),Vector3(0.37,0.045,0.02),_glow("amber",Color("ffc078")))

func _valve_bay()->void:
	var path:Array[Vector3]=[Vector3(0.50,-0.67,1.76),Vector3(1.85,-0.67,1.76)]
	for i in range(1,9):
		var angle:=PI/2-float(i)/8*PI/2
		path.append(Vector3(1.85+0.28*cos(angle),-0.95+0.28*sin(angle),1.76))
	path.append(Vector3(2.13,-1.25,1.76))
	for i in range(1,9):
		var angle:=PI+float(i)/8*PI/2
		path.append(Vector3(2.41+0.28*cos(angle),-1.25+0.28*sin(angle),1.76))
	path.append(Vector3(5.20,-1.53,1.76));_tube(path,0.12,iron)
	_flange(Vector3(1.25,-0.67,1.76),Vector3.RIGHT)
	_flange(Vector3(2.13,-1.23,1.76),Vector3.UP)
	_flange(Vector3(4.45,-1.53,1.76),Vector3.RIGHT)
	_rod(Vector3(3.1,-1.53,1.76),Vector3(3.1,-1.53,2.08),0.035,bright)
	var wheel:=TorusMesh.new();wheel.inner_radius=0.185;wheel.outer_radius=0.23
	wheel.rings=32;wheel.ring_segments=8
	_part(wheel,Vector3(3.1,-1.53,2.08),oxide,Basis(Vector3.RIGHT,PI/2))
	for i in range(6):
		var angle:=i*TAU/6
		_rod(Vector3(3.1,-1.53,2.08),Vector3(3.1+cos(angle)*0.20,-1.53+sin(angle)*0.20,2.08),0.013,oxide)
	_bolt(Vector3(3.1,-1.53,2.10),0.035)
	_box(Vector3(3.95,-1.03,1.66),Vector3(0.48,0.57,0.18),iron)
	_box(Vector3(3.95,-1.03,1.77),Vector3(0.40,0.49,0.035),oxide)
	for x:float in [3.80,4.10]:
		for y:float in [-0.84,-1.22]:_bolt(Vector3(x,y,1.80),0.016)
	_tube([Vector3(4.19,-1.12,1.66),Vector3(4.36,-1.12,1.66),Vector3(4.36,-0.82,1.66),Vector3(4.95,-0.82,1.66)],0.025,oxide)

func _twin_bay()->void:
	for right:bool in [false,true]:
		var path:Array[Vector3]=[Vector3(0.50,-0.67,1.76),Vector3(2.10,-0.67,1.76)]
		for i in range(1,9):
			var angle:=PI/2-float(i)/8*PI/2
			path.append(Vector3(2.10+0.28*cos(angle),-0.95+0.28*sin(angle),1.76))
		path.append(Vector3(2.38,-2.36,1.76))
		if right:
			for i in range(path.size()):path[i].x=6.2-path[i].x
		_tube(path,0.135,iron)
		_flange(Vector3(4.95 if right else 1.25,-0.67,1.76),Vector3.RIGHT,0.185)
		_flange(Vector3(3.82 if right else 2.38,-1.40,1.76),Vector3.UP,0.185)
		_flange(Vector3(3.82 if right else 2.38,-2.12,1.76),Vector3.UP,0.185)
	_box(Vector3(3.1,-1.28,1.68),Vector3(0.47,0.66,0.20),iron)
	_box(Vector3(3.1,-1.28,1.80),Vector3(0.39,0.58,0.035),oxide)
	var indicator:=SphereMesh.new();indicator.radius=0.035;indicator.height=0.07
	indicator.radial_segments=12;indicator.rings=6
	_part(indicator,Vector3(3.1,-1.16,1.845),_glow("cyan",Color("64cdd4")))
	for x:float in [2.96,3.24]:
		for y:float in [-1.05,-1.51]:_bolt(Vector3(x,y,1.84),0.014)
	_tube([Vector3(3.1,-1.62,1.65),Vector3(3.1,-2.10,1.65),Vector3(3.3,-2.20,1.65),Vector3(4.95,-2.20,1.65)],0.025,oxide)

func _merge()->ArrayMesh:
	var grouped:Dictionary={}
	for part:Dictionary in parts:
		if not grouped.has(part.material):grouped[part.material]=[]
		grouped[part.material].append(part)
	var mesh:=ArrayMesh.new()
	for material:Material in grouped:
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part:Dictionary in grouped[material]:surface.append_from(part.mesh,0,part.transform)
		surface.set_material(material);surface.commit(mesh)
	return mesh
