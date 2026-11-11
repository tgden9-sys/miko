extends Node3D
## Counterweighted cargo shutter. Closing pauses while anything occupies its path.
var refined:=false
var opened:=false
var conduit_length:=5.
var travel:=0.
var door:AnimatableBody3D
var indicator:StandardMaterial3D
var query_shape:BoxShape3D
var blade_shape:BoxShape3D
var blade_collision:CollisionShape3D
var slats:Array[MeshInstance3D]=[]

func _ready()->void:
	name="SensorShutter"
	var steel:=_paint(Color("657071"))
	var dark:=_paint(Color("28343b"))
	var trim:=_paint(Color("b29555"))
	indicator=StandardMaterial3D.new();indicator.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	for z:float in [-1.45,1.45]:
		_part(self,Vector3(.68,4.4,.22),Vector3(0,2.2,z),steel)
		_part(self,Vector3(.82,.14,.40),Vector3(0,.07,z),dark)
		_part(self,Vector3(.10,3.5,.06),Vector3(-.35,1.85,z+.13),trim)
		for y:float in [.25,1.25,2.25,3.25,4.1]:
			_part(self,Vector3(.74,.08,.28),Vector3(0,y,z),dark)
			for x:float in [-.22,.22]:
				var bolt:=MeshInstance3D.new();var cylinder:=CylinderMesh.new()
				cylinder.top_radius=.025;cylinder.bottom_radius=.025;cylinder.height=.025;cylinder.radial_segments=6
				bolt.mesh=cylinder;bolt.rotation.x=PI*.5;bolt.position=Vector3(x,y,z+.155);bolt.material_override=trim;bolt.layers=4;add_child(bolt)
	_part(self,Vector3(.92,.48,3.25),Vector3(0,4.25,0),dark)
	_part(self,Vector3(.12,.13,2.7),Vector3(-.48,4.25,0),indicator)
	door=AnimatableBody3D.new();door.name="SlidingPanel";door.sync_to_physics=false;add_child(door)
	blade_shape=BoxShape3D.new();blade_shape.size=Vector3(.42,3.7,2.75)
	blade_collision=CollisionShape3D.new();blade_collision.shape=blade_shape;blade_collision.position.y=1.85;door.add_child(blade_collision)
	for i in range(10):
		var slat:=_part(self,Vector3(.48,.35,2.66),Vector3(0,.2+float(i)*.36,0),steel)
		_part(slat,Vector3(.51,.045,2.60),Vector3(0,-.12,0),trim if i==0 else dark)
		slats.append(slat)
	# A recessed actuator panel and status bars on the camera-facing post.
	_part(self,Vector3(.46,.80,.04),Vector3(0,2.3,1.59),dark)
	for y:float in [2.15,2.3,2.45]:_part(self,Vector3(.28,.035,.05),Vector3(0,y,1.62),indicator)
	for y:float in [.5,.61,.72,.83]:_part(self,Vector3(.35,.04,.04),Vector3(0,y,1.59),dark)
	# A small conduit visibly connects the nearby plate to its actuator.
	_part(self,Vector3(conduit_length,.035,.06),Vector3(-conduit_length*.5,.026,-1.1),dark)
	for i in range(1,ceili(conduit_length)):_part(self,Vector3(.12,.04,.08),Vector3(-float(i),.035,-1.1),indicator)
	if refined:_refine_hardware(steel,dark,trim)
	query_shape=BoxShape3D.new();query_shape.size=Vector3(.9,3.75,2.7)
	set_open(false)

func _paint(color:Color)->ShaderMaterial:
	var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_cooling_steel.gdshader")
	paint.set_shader_parameter("paint",color);paint.set_shader_parameter("wear",preload("res://art/cel_scene/cooling_station/duct_atlas_v1.png"));return paint

func _part(parent:Node3D,size:Vector3,at:Vector3,material:Material)->MeshInstance3D:
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size;mesh.mesh=box
	mesh.position=at;mesh.material_override=material;mesh.layers=4;parent.add_child(mesh);return mesh

func set_open(value:bool)->void:
	opened=value
	indicator.albedo_color=Color("b086ff") if value else Color("7edba3")

func _physics_process(delta:float)->void:
	var target_travel := 3.85 if opened else 0.0
	if travel == target_travel: return
	if not opened and travel>0.:
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=query_shape
		query.transform=Transform3D(Basis.IDENTITY,global_position+Vector3(0,1.88,0))
		query.collision_mask=5;query.exclude=[door.get_rid()]
		if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return
	travel=move_toward(travel,target_travel,delta*2.6)
	_update_panel()

func _update_panel()->void:
	var remaining:=maxf(.02,3.7-travel)
	blade_shape.size.y=remaining;blade_collision.position.y=travel+remaining*.5
	blade_collision.disabled=travel>=3.7
	# The leaves retract into the head cassette instead of sticking into the sky.
	for i in range(slats.size()):
		slats[i].position.y=.2+float(i)*.36+travel
		slats[i].visible=slats[i].position.y<4.12

func reset_shutter()->void:
	set_open(false);travel=0.;_update_panel()

func _refine_hardware(steel:Material,dark:Material,trim:Material)->void:
	var edge:=_paint(Color("9aa5a3"))
	# A continuous head cassette and rear wall receiver make this a fitted machine.
	_part(self,Vector3(.94,.72,3.3),Vector3(0,4.18,0),steel)
	_part(self,Vector3(.74,.46,.10),Vector3(0,4.18,1.70),dark)
	for x:float in [-.26,-.13,0.,.13,.26]:
		_part(self,Vector3(.045,.28,.025),Vector3(x,4.18,1.765),edge)
	_part(self,Vector3(.70,.10,.10),Vector3(0,3.86,1.70),indicator)
	# Broad perimeter frame, recessed service panel and external guide rails.
	for z:float in [-1.45,1.45]:
		_part(self,Vector3(.86,.18,.48),Vector3(0,.09,z),steel)
		for x:float in [-.37,.37]:
			_part(self,Vector3(.07,3.7,.31),Vector3(x,1.97,z),edge)
		_part(self,Vector3(.76,.12,.34),Vector3(0,3.76,z),trim)
	for x:float in [-.29,.29]:
		_part(self,Vector3(.035,.90,.09),Vector3(x,2.32,1.64),edge)
	_part(self,Vector3(.55,.035,.09),Vector3(0,2.78,1.64),edge)
	_part(self,Vector3(.55,.035,.09),Vector3(0,1.86,1.64),edge)
	for i in range(slats.size()):
		var slat:=slats[i]
		# Recesses and raised lips on both travel-facing surfaces read in profile.
		for side:float in [-1.,1.]:
			_part(slat,Vector3(.025,.20,2.32),Vector3(side*.25,.01,0),dark)
			_part(slat,Vector3(.035,.025,2.42),Vector3(side*.27,.12,0),edge)
			for z:float in [-1.12,1.12]:
				_part(slat,Vector3(.04,.25,.06),Vector3(side*.27,0,z),steel)
		if i==0:
			_part(slat,Vector3(.58,.12,2.7),Vector3(0,-.10,0),dark)
	# Header identification is painted on the front post, clear at gameplay scale.
	var label:=Label3D.new()
	label.text="LOCK / %02d" % int(position.x)
	label.font_size=40;label.pixel_size=.0025
	label.position=Vector3(0,3.37,1.64)
	label.modulate=Color("d4d7c9");label.outline_size=4
	label.no_depth_test=false;label.layers=4;add_child(label)
