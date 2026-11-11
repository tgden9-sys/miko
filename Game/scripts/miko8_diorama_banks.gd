extends Node3D
var concrete:Material
var metal:Material
var iron:Material
func _ready()->void:
	name="OpenBridgeBanks"
	var source:=StandardMaterial3D.new();source.resource_name="Mottled blue grey concrete"
	concrete=preload("res://scripts/miko8_diorama_materials.gd").convert(source)
	var steel:=StandardMaterial3D.new();steel.resource_name="Oxidised blue black steel"
	metal=preload("res://scripts/miko8_diorama_materials.gd").convert(steel)
	var dark:=StandardMaterial3D.new();dark.resource_name="Deep joints"
	iron=preload("res://scripts/miko8_diorama_materials.gd").convert(dark)
	# Actual banks behind the gameplay lane. The central six-metre opening stays empty.
	for x:float in [25.0,41.0]:
		_box(Vector3(x,-4.2,1.0),Vector3(10,3.4,1.0),concrete)
		_box(Vector3(x,-.35,-4.8),Vector3(10,.7,6.8),concrete)
		for px in range(10):
			for pz in range(4):
				_box(Vector3(x-4.5+px,.015,-2.1-pz*1.45),Vector3(.975,.045,1.425),concrete)
		_box(Vector3(x,-2.8,-8.15),Vector3(10,5.5,.35),concrete)
	for x:float in [29.85,36.15]:
		_box(Vector3(x,-3.3,-3.4),Vector3(.30,6.6,9.6),concrete)
		for z:float in [-.8,-3.8,-6.8]:
			_box(Vector3(x,-.12,z),Vector3(.45,.25,2.96),concrete)
			_box(Vector3(x,-3.3,z),Vector3(.36,.025,2.96),iron)
		# Services descend on the banks, rather than filling the central view.
		_pipe(Vector3(x+(.22 if x<33 else -.22),-1.0,-2.1),Vector3(x+(.22 if x<33 else -.22),-5.8,-2.1),.13,metal)
		for y:float in [-1.3,-2.5,-4.0,-5.4]:
			_pipe(Vector3(x,-.04+y,-2.1),Vector3(x,.04+y,-2.1),.18,metal)
	_box(Vector3(33,-6.7,-6),Vector3(6,.3,12),iron)
	for x:float in [30.6,35.4]:_pipe(Vector3(x,-5.9,-1.2),Vector3(x,-5.9,-11.0),.18,metal)
	for x:float in [30.1,35.9]:
		var light:=OmniLight3D.new();light.position=Vector3(x,-1.8,-1.2)
		light.light_color=Color("ffb96b");light.light_energy=1.6;light.omni_range=3.5;add_child(light)
		light.add_to_group("miko8_budget_visual");light.set_meta("budget_half_width",3.5)
		_box(Vector3(x,-1.8,-1.2),Vector3(.2,.55,.4),iron)
		var glow:=StandardMaterial3D.new();glow.albedo_color=Color("ffca87");glow.emission_enabled=true;glow.emission=Color("ffb96b");glow.emission_energy_multiplier=2.0
		_box(Vector3(x,-1.8,-.98),Vector3(.15,.34,.04),glow)
func _box(at:Vector3,size:Vector3,material:Material)->MeshInstance3D:
	var obj:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size
	obj.mesh=mesh;obj.position=at;obj.material_override=material;add_child(obj)
	obj.add_to_group("miko8_budget_visual");obj.set_meta("budget_half_width",size.x/2);return obj
func _pipe(a:Vector3,b:Vector3,r:float,material:Material)->void:
	var obj:=MeshInstance3D.new();var mesh:=CylinderMesh.new();mesh.top_radius=r;mesh.bottom_radius=r;mesh.height=a.distance_to(b);mesh.radial_segments=16
	obj.mesh=mesh;obj.position=(a+b)/2
	var direction:=(b-a).normalized();obj.quaternion=Quaternion(Vector3.UP,direction)
	obj.material_override=material;add_child(obj);obj.add_to_group("miko8_budget_visual");obj.set_meta("budget_half_width",absf(a.x-b.x)/2+r)
