extends Node3D
## A transverse duct: local Z runs from the building through the walking lane
## to the front of the deck. Its intake is a real termination, not a loose pipe.
@export var clearance:=1.38
@export var passage_length:=2.20
@export var wall_z:=-3.60
@export var edge_z:=1.62
@export var include_building:=false
const ART:="res://art/cel_scene/cooling_station/"
var steel:ShaderMaterial
var rim:ShaderMaterial
var dark:ShaderMaterial
var yellow:ShaderMaterial

func _ready()->void:
	name="CoolingStation" if include_building else "CoolingCrossing"
	steel=_paint(Color("535e60"));rim=_paint(Color("818881"));dark=_paint(Color("242d32"));yellow=_paint(Color("c99b44"))
	if include_building:_station()
	var top:=clearance+1.00
	var depth:=edge_z-wall_z
	var center:=Vector3(0,clearance+.50,(wall_z+edge_z)*.5)
	_bevel("DuctShell",Vector3(passage_length,1.,depth),center,.085,steel)
	_solid("DuctClearance",Vector3(passage_length,1.,depth),center)
	# The full flange overlaps the facade, including a dark recessed gasket.
	_box("WallGasket",Vector3(passage_length+.42,1.40,.09),Vector3(0,clearance+.50,wall_z+.015),dark)
	_bevel("MountingFlange",Vector3(passage_length+.32,1.30,.10),Vector3(0,clearance+.50,wall_z+.08),.06,steel)
	_bevel("WallTransitionCollar",Vector3(passage_length+.15,1.12,.36),Vector3(0,clearance+.55,wall_z+.25),.10,dark)
	for x in [-1.,1.]:
		for y in [-.52,0.,.52]:_bolt(Vector3(x*(passage_length*.5+.10),clearance+.5+y,wall_z+.145))
	# Three broad removable cassettes, with true metal seams around the painted panels.
	for z:float in [wall_z+.22,lerpf(wall_z,edge_z,.34),lerpf(wall_z,edge_z,.67),edge_z-.16]:
		_bevel("SleeveSeal",Vector3(passage_length+.04,1.025,.13),Vector3(0,clearance+.51,z),.09,dark)
		_bevel("SleeveBand",Vector3(passage_length+.065,1.035,.065),Vector3(0,clearance+.515,z),.09,steel)
		for side in [-1.,1.]:
			var bolt:=_bolt(Vector3(side*(passage_length*.5+.043),clearance+.65,z));bolt.rotation.y=PI*.5
	var side_art:=_atlas(Vector4(.5,0,.5,.5))
	var cover_art:=_atlas(Vector4(0,.5,.5,.5))
	for side in [-1.,1.]:
		for z:float in [lerpf(wall_z,edge_z,.18),lerpf(wall_z,edge_z,.50),lerpf(wall_z,edge_z,.82)]:
			_panel("AccessCassette",Vector2((depth-.32)/3.,.84),Vector3(side*(passage_length*.5+.012),clearance+.51,z),Vector3(0,side*PI*.5,0),side_art)
		_box("LowerRolledLip",Vector3(.05,.055,depth-.3),Vector3(side*(passage_length*.5-.015),clearance+.055,center.z),rim)
	for z:float in [lerpf(wall_z,edge_z,.18),lerpf(wall_z,edge_z,.50),lerpf(wall_z,edge_z,.82)]:
		_panel("TopCover",Vector2(passage_length-.18,(depth-.32)/3.),Vector3(0,top+.006,z),Vector3(-PI*.5,0,0),cover_art)
	# Front intake has a framed, recessed louvre bank. Nothing hangs in front of Miko.
	_bevel("IntakeFrame",Vector3(passage_length+.065,1.05,.20),Vector3(0,clearance+.515,edge_z),.075,steel)
	_panel("PaintedIntake",Vector2(passage_length+.025,1.015),Vector3(0,clearance+.515,edge_z+.106),Vector3.ZERO,_atlas(Vector4(0,0,.5,.5)))
	# Bevelled perimeter and proud lower bumper provide real silhouette depth.
	for side in [-1.,1.]:
		_bevel("IntakeEdge",Vector3(.035,.88,.045),Vector3(side*(passage_length*.5+.025),clearance+.515,edge_z+.10),.012,rim)
	_box("LowerBumperEdge",Vector3(passage_length-.14,.022,.035),Vector3(0,clearance+.014,edge_z+.12),rim)
	# Folded edge strips catch the key light; recessed access seams break up the shell.
	for side in [-1.,1.]:
		_box("FoldedTopEdge",Vector3(.035,.025,depth-.34),Vector3(side*(passage_length*.5-.09),top-.015,center.z),rim)
	for z:float in [lerpf(wall_z,edge_z,.34),lerpf(wall_z,edge_z,.67)]:
		_box("TopPanelSeam",Vector3(passage_length-.25,.008,.018),Vector3(0,top+.005,z+.13),dark)
	for side in [-1.,1.]:
		# Tie rods carry the cantilever back into high wall anchors.
		var x:float=side*(passage_length*.5-.13)
		var high:=Vector3(x,top+.60,wall_z+.19)
		var low:=Vector3(x,top+.06,edge_z-.40)
		_bevel("TieAnchor",Vector3(.28,.33,.12),Vector3(x,high.y,wall_z+.07),.035,steel)
		for offset in [-.1,.1]:_bolt(Vector3(x,high.y+offset,wall_z+.14))
		_bar("SuspensionRod",high,low,.045,rim)
		_bar("TensionAdjuster",high.lerp(low,.72),high.lerp(low,.81),.085,steel)
		_bevel("RodClevis",Vector3(.15,.18,.22),Vector3(x,top+.02,edge_z-.40),.025,dark)
		_bolt(Vector3(x,top+.06,edge_z-.27))
		_lamp(Vector3(side*.82,clearance+.91,edge_z+.12),Vector2(.16,.08),.10)
	# Flush painted threshold bars give the low route a readable entrance and exit.
	for side in [-1.,1.]:
		_box("DeckThreshold",Vector3(.10,.009,4.80),Vector3(side*(passage_length*.5+.16),.009,-.90),yellow)
	_shadow(Vector3(0,.013,-.55),Vector2(passage_length+1.,4.8))
	add_to_group("miko8_budget_visual");set_meta("budget_half_width",4.2 if include_building else passage_length*.5+1.)

func _station()->void:
	# One complete building occupies the old 7.2m plot, with its facade composed
	# around the duct socket. No stock windows or doors remain behind the mount.
	var origin:=Vector3(.20,-.025,wall_z-1.4)
	var skin:=ShaderMaterial.new();skin.shader=preload("res://shaders/miko8_ladder_building_skin.gdshader")
	skin.set_meta("cel_facade_art",ART+"facade_v1.png")
	skin.set_shader_parameter("building_origin",to_global(origin));skin.set_shader_parameter("building_height",4.4);skin.set_shader_parameter("facade_height",4.4)
	skin.set_shader_parameter("facade_start_x",-3.6);skin.set_shader_parameter("facade_width",7.2)
	_box("CoolingStationWalls",Vector3(7.2,4.4,2.8),origin+Vector3(0,2.2,0),skin)
	var concrete:=ShaderMaterial.new();concrete.shader=preload("res://shaders/miko8_shared_concrete.gdshader")
	concrete.set_shader_parameter("grain",preload("res://art/cel_scene/concrete_v1.png"))
	_bevel("RoofCoping",Vector3(7.32,.14,2.98),origin+Vector3(0,4.43,0),.045,concrete)
	_box("GroundSill",Vector3(7.26,.13,2.92),origin+Vector3(0,.07,0),dark)
	for side in [-1.,1.]:
		_bevel("FacadeEdgePier",Vector3(.16,4.36,.16),origin+Vector3(side*3.50,2.2,1.44),.025,concrete)
		# Roof plant is mounted on feet, with a short flange into the roof.
		var unit:Node3D=preload("res://models/environment/yard_life/exhaust_outlet.glb").instantiate()
		unit.name="RoofHeatExchanger";unit.position=origin+Vector3(side*2.5,4.52,-.20);unit.scale=Vector3.ONE*.85;add_child(unit)
		for mesh:MeshInstance3D in unit.find_children("*","MeshInstance3D",true,false):
			mesh.layers=4
			for i in range(mesh.mesh.get_surface_count()):
				var original:=mesh.get_active_material(i) as StandardMaterial3D
				if original:
					var finish:=original.duplicate() as StandardMaterial3D
					finish.vertex_color_use_as_albedo=true
					mesh.set_surface_override_material(i,finish)
		_bevel("RoofPlantCurb",Vector3(.82,.12,.8),origin+Vector3(side*2.5,4.51,-.20),.03,dark)
		_lamp(Vector3(.20+side*2.15,2.43,wall_z+.06),Vector2(.13,.23),.16)
	_shadow(Vector3(.2,.014,wall_z+.25),Vector2(7.5,1.1))
	# Sparse weeds in the sheltered wall junction keep the lower edge grounded.
	var weeds:=preload("res://scripts/miko8_yard_foliage.gd").new()
	weeds.rng.seed=80317;weeds.material=ShaderMaterial.new();weeds.material.shader=preload("res://shaders/miko8_yard_grass.gdshader")
	for point:Vector3 in [Vector3(-3.14,0,wall_z+.15),Vector3(3.48,0,wall_z+.17),Vector3(2.95,0,wall_z+.12)]:
		var tuft:=MeshInstance3D.new();tuft.name="WallJointWeeds";tuft.mesh=weeds._tuft(2);tuft.position=point;tuft.scale=Vector3.ONE*.72;tuft.material_override=weeds.material;tuft.layers=4;add_child(tuft)
	weeds.free()

func _atlas(rect:Vector4)->ShaderMaterial:
	var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/miko8_cooling_atlas.gdshader");mat.set_shader_parameter("art",load(ART+"duct_atlas_v1.png"));mat.set_shader_parameter("atlas_rect",rect);return mat
func _panel(label:String,size:Vector2,at:Vector3,angles:Vector3,mat:Material)->void:
	var visual:=MeshInstance3D.new();visual.name=label;var q:=QuadMesh.new();q.size=size;visual.mesh=q;visual.position=at;visual.rotation=angles;visual.material_override=mat;visual.layers=4;add_child(visual)
func _lamp(at:Vector3,size:Vector2,strength:float)->void:
	var halo:=ShaderMaterial.new();halo.shader=preload("res://shaders/miko_practical_halo.gdshader");halo.set_shader_parameter("strength",strength)
	_panel("WarmRunningLight",size*3.0,at,Vector3.ZERO,halo)

func _paint(color:Color)->ShaderMaterial:
	var m:=ShaderMaterial.new();m.shader=preload("res://shaders/miko8_cooling_steel.gdshader");m.set_shader_parameter("paint",color);m.set_shader_parameter("wear",load(ART+"duct_atlas_v1.png"));return m
func _box(label:String,size:Vector3,at:Vector3,mat:Material)->MeshInstance3D:
	var m:=MeshInstance3D.new();m.name=label;var b:=BoxMesh.new();b.size=size;m.mesh=b;m.position=at;m.material_override=mat;m.layers=4;add_child(m);return m
func _bevel(label:String,size:Vector3,at:Vector3,b:float,mat:Material)->MeshInstance3D:
	var w:=size.x*.5;var h:=size.y*.5;var d:=size.z*.5
	var p: Array[Vector2]=[Vector2(-w+b,-h),Vector2(w-b,-h),Vector2(w,-h+b),Vector2(w,h-b),Vector2(w-b,h),Vector2(-w+b,h),Vector2(-w,h-b),Vector2(-w,-h+b)]
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(8):
		var a:=Vector3(p[i].x,p[i].y,-d);var c:=Vector3(p[(i+1)%8].x,p[(i+1)%8].y,-d)
		_tri(st,a,c,a+Vector3(0,0,size.z));_tri(st,c,c+Vector3(0,0,size.z),a+Vector3(0,0,size.z))
		_tri(st,Vector3(0,0,-d),c,a);_tri(st,Vector3(0,0,d),a+Vector3(0,0,size.z),c+Vector3(0,0,size.z))
	st.generate_normals();var m:=MeshInstance3D.new();m.name=label;m.mesh=st.commit();m.position=at;m.material_override=mat;m.layers=4;add_child(m);return m
func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
	st.add_vertex(a);st.add_vertex(c);st.add_vertex(b)
func _bolt(at:Vector3)->MeshInstance3D:
	var m:=MeshInstance3D.new();var b:=CylinderMesh.new();b.top_radius=.035;b.bottom_radius=.035;b.height=.025;b.radial_segments=6;m.mesh=b;m.position=at;m.rotation.x=PI*.5;m.material_override=yellow;m.layers=4;add_child(m);return m
func _bar(label:String,a:Vector3,b:Vector3,width:float,mat:Material)->void:
	var m:=_box(label,Vector3(width,width,a.distance_to(b)),(a+b)*.5,mat);m.look_at(global_transform*b,Vector3.UP)
func _solid(label:String,size:Vector3,at:Vector3)->void:
	var body:=StaticBody3D.new();body.name=label;body.position=at;var c:=CollisionShape3D.new();var b:=BoxShape3D.new();b.size=size;c.shape=b;body.add_child(c);add_child(body);body.add_to_group("tutorial_solids")
func _shadow(at:Vector3,size:Vector2)->void:
	var g:=Gradient.new();g.set_color(0,Color(0,0,0,.40));g.set_color(1,Color(0,0,0,0))
	var t:=GradientTexture2D.new();t.gradient=g;t.width=64;t.height=64;t.fill=GradientTexture2D.FILL_RADIAL;t.fill_from=Vector2(.5,.5);t.fill_to=Vector2(1.,.5)
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_texture=t
	var m:=MeshInstance3D.new();var p:=PlaneMesh.new();p.size=size;m.mesh=p;m.position=at;m.material_override=mat;m.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(m)
