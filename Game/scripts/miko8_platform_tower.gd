extends Node3D
## Matched caps, frame footprints, ladder dimensions and a single cel palette.
@export_enum("Small", "Medium", "Large") var variant:=0
@export var deck_height:=2.8
@export var reverse_face:=false
@export var front_ladder:=true
@export var dismount_side:=1
const DECK_WIDTH:=2.0
const DECK_DEPTH:=1.6
const LADDER_WIDTH:=.43
const WALK_Z:=-.81807
const CENTRE_Z:=-1.22
const ASSETS:=[
	preload("res://models/environment/platform_towers_v2/small.glb"),
	preload("res://models/environment/platform_towers_v2/medium.glb"),
	preload("res://models/environment/platform_towers_v2/large.glb"),
]
var ladder:Node3D
var roof:StaticBody3D
var model:Node3D
static var materials:Dictionary={}
static var contact_material:StandardMaterial3D
static var outline:ShaderMaterial

func _ready()->void:
	add_to_group("miko8_platform_towers")
	model=ASSETS[variant].instantiate();model.name="TowerModel"
	model.position.z=CENTRE_Z;model.rotation.y=PI if reverse_face else 0.
	add_child(model)
	model.add_to_group("miko8_budget_visual");model.set_meta("budget_half_width",1.15)
	if not outline:
		outline=ShaderMaterial.new();outline.shader=preload("res://shaders/miko8_cel_outline.gdshader")
		outline.set_shader_parameter("base_thickness",.011)
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		mesh.layers=4
		if mesh.name.begins_with("ClimbLadder"):mesh.visible=front_ladder
		for surface in range(mesh.mesh.get_surface_count()):
			var source:=mesh.get_active_material(surface) as StandardMaterial3D
			if not source:continue
			var label:=source.resource_name
			var kind:=0
			for pair:Array in [["TowerSteel",1],["TowerAmber",2],["TowerDeck",3],["TowerRung",4],["TowerInk",5],["TowerBolt",6]]:
				if label.begins_with(pair[0]):kind=pair[1];break
			var key:String=str(kind)+":"+(str(source.albedo_texture.get_instance_id()) if kind==0 and source.albedo_texture else "shared")
			if not materials.has(key):
				var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_matched_tower_cel.gdshader")
				paint.set_shader_parameter("surface_kind",kind)
				if kind==0:paint.set_shader_parameter("source_paint",source.albedo_texture)
				materials[key]=paint
			if mesh.name.begins_with("ClimbLadder"):
				var tread := kind == 4
				var safety:=ShaderMaterial.new()
				safety.shader=preload("res://shaders/miko8_ladder_safety.gdshader")
				safety.set_shader_parameter("paint",Color("919a94") if tread else Color("b88a55"))
				safety.set_shader_parameter("tread",tread)
				mesh.set_surface_override_material(surface,safety)
			else:
				mesh.set_surface_override_material(surface,materials[key])
	roof=_box("WalkableDeck",Vector3(0,deck_height-.075,CENTRE_Z),Vector3(1.92,.15,1.54))
	roof.add_to_group("miko8_tower_decks")
	_box("Column",Vector3(0,(deck_height-.18)*.5,CENTRE_Z),Vector3(.94,deck_height-.18,.82))
	if front_ladder:
		_mounting_crossbars()
		ladder=preload("res://scripts/miko8_tower_course_ladder.gd").new()
		ladder.name="TowerLadder";ladder.height=deck_height;ladder.position.z=-.46
		ladder.above_platform=0.;ladder.dismount_side=dismount_side
		ladder.set_meta("bpg_ladder",true);ladder.set_meta("direct_entry",true)
		ladder.set_meta("top_entry_x",global_position.x);add_child(ladder)
	_contact()

func _mounting_crossbars()->void:
	# The cleared frame is open. Each ladder standoff needs a real transverse
	# receiver reaching the side posts, rather than a plate hanging in space.
	var y:=.32
	while y<deck_height-.20:
		var bar:=MeshInstance3D.new();bar.name="LadderMountReceiver"
		var box:=BoxMesh.new();box.size=Vector3(.90,.055,.06);bar.mesh=box
		bar.position=Vector3(0,y,CENTRE_Z+.40);bar.material_override=materials["1:shared"]
		bar.layers=4;add_child(bar)
		for x:float in [-.35,.35]:
			var bolt:=MeshInstance3D.new();bolt.name="LadderReceiverBolt"
			var head:=CylinderMesh.new();head.top_radius=.012;head.bottom_radius=.012;head.height=.008;head.radial_segments=8
			bolt.mesh=head;bolt.rotation.x=PI*.5;bolt.position=Vector3(x,y,CENTRE_Z+.435)
			bolt.material_override=materials["6:shared"];bolt.layers=4;add_child(bolt)
		y+=1.05

func _box(label:String,at:Vector3,size:Vector3)->StaticBody3D:
	var body:=StaticBody3D.new();body.name=label;body.position=at
	var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=size
	collision.shape=box;body.add_child(collision);add_child(body);return body

func _contact()->void:
	if not contact_material:
		contact_material=StandardMaterial3D.new();contact_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		contact_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		var gradient:=Gradient.new();gradient.set_color(0,Color(0,0,0,.38));gradient.set_color(1,Color(0,0,0,0))
		var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.width=64;texture.height=64
		texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1.,.5)
		contact_material.albedo_texture=texture
	var patch:=MeshInstance3D.new();patch.name="FootContactShadow"
	var plane:=PlaneMesh.new();plane.size=Vector2(1.65,1.3);patch.mesh=plane
	patch.position=Vector3(0,.006,CENTRE_Z);patch.material_override=contact_material
	patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(patch)

