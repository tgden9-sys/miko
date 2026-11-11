extends Node3D
const HEIGHT:=5.2
const START_X:=32.8
const END_X:=46.5
const WALK_Z:=-.81807
var departure:Node3D
var arrival:Node3D
var sections:Array[Node3D]=[]
func _ready()->void:
	name="RooftopBridgeRoute"
	departure=_building("TallLadderBuilding",START_X,true)
	arrival=_building("BridgeArrivalBuilding",END_X,false)
	_section("WestCantilever","cantilever",37.35,1.40346,false)
	_section("CentreDeck","deck",39.65,.44156,false)
	_section("EastCantilever","cantilever",41.95,1.40346,true)
	var steel:=StandardMaterial3D.new();steel.albedo_color=Color("64706f");steel.roughness=.94
	_anchors(36.2,1.,steel);_anchors(43.1,-1.,steel)
	for x:float in [36.20,38.46,40.85,43.10]:
		var cover:=MeshInstance3D.new();cover.name="BridgeJointCover"
		var plate:=BoxMesh.new();plate.size=Vector3(.095,.014,.96);cover.mesh=plate;cover.material_override=steel
		cover.position=Vector3(x,HEIGHT+.006,WALK_Z);cover.layers=4;add_child(cover)
	print("ROOFTOP_BRIDGE_READY roofs=",HEIGHT," sections=",sections.size()," ladder_x=",departure.ladder.climb_x)
func _building(label:String,x:float,with_ladder:bool)->Node3D:
	var building:=preload("res://scripts/miko8_side_on_climb_set.gd").new()
	building.site_name=label;building.building_x=x;building.roof_height=HEIGHT;building.attach_ladder=with_ladder
	building.mirror_front=not with_ladder
	building.custom_facade="res://art/cel_scene/tall_departure_facade_v1.png" if with_ladder else "res://art/cel_scene/tall_arrival_facade_v1.png"
	add_child(building);return building
func _section(label:String,asset:String,x:float,source_deck:float,reverse:bool)->void:
	var body:=StaticBody3D.new();body.name=label;body.collision_layer=1;body.collision_mask=1
	body.add_to_group("tutorial_solids");add_child(body)
	var model:Node3D=load("res://models/environment/bridge_platforms/"+asset+".glb").instantiate()
	model.name="BridgePlatformModel";model.scale=Vector3(1.21,2.1,1.15) if asset=="cantilever" else Vector3(1.30,2.1,1.44)
	model.rotation.y=PI if reverse else 0.;model.position=Vector3(x,HEIGHT-source_deck*2.1,WALK_Z);body.add_child(model)
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):mesh.layers=4
	model.add_to_group("miko8_budget_visual");model.set_meta("budget_half_width",1.5)
	# A clean deck collider keeps the remeshed grate holes and rail bumps out
	# of MIKO's single walking lane. No invisible slab spans the whole gap.
	var collision:=CollisionShape3D.new();collision.name="WalkableDeck"
	var shape:=BoxShape3D.new();shape.size=Vector3(2.33 if asset=="cantilever" else 2.50,.14,.97)
	collision.shape=shape;collision.position=Vector3(x,HEIGHT-.07,WALK_Z);body.add_child(collision)
	sections.append(body)
func _anchors(wall_x:float,outward:float,steel:Material)->void:
	for z:float in [WALK_Z-.52,WALK_Z+.52]:
		for y:float in [2.53,4.73]:
			var plate:=MeshInstance3D.new();plate.name="WallBridgeReceiver"
			var shape:=BoxMesh.new();shape.size=Vector3(.045,.52,.25);plate.mesh=shape;plate.material_override=steel
			plate.position=Vector3(wall_x+outward*.023,y,z);plate.layers=4;add_child(plate)
			for dy:float in [-.18,.18]:
				for dz:float in [-.082,.082]:
					var bolt:=MeshInstance3D.new();var head:=CylinderMesh.new();head.top_radius=.018;head.bottom_radius=.018;head.height=.018;head.radial_segments=6
					bolt.mesh=head;bolt.material_override=steel;bolt.rotation.z=PI*.5;bolt.position=Vector3(wall_x+outward*.054,y+dy,z+dz);bolt.layers=4;add_child(bolt)
