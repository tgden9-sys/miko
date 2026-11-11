extends Node3D
const CRATE=preload("res://scripts/miko8_charge_box.gd")
const STOREY:=2.63
const COURSE_STACK_X:=57.65
const COURSE_STACK_Z:=-.81807
func _ready()->void:
	name="Level2Platforms"
	for i in range(2):
		_stack(str(i),25.+5.*i)
	_stack("CourseFinish",COURSE_STACK_X,COURSE_STACK_Z)
	for offset:float in [-.55,.50,1.55]:
		_crate(Vector3(COURSE_STACK_X+offset,STOREY+.4,COURSE_STACK_Z),STOREY)
	for start:float in [20.]:
		_crate(Vector3(start,.4,0));_crate(Vector3(start+1.05,.4,0));_crate(Vector3(start+1.05,1.2,0))
	var switch=preload("res://scenes/reusable_pressure_switch.tscn").instantiate();switch.position=Vector3(12.,0,0);add_child(switch)
	var load_crate:=_crate(Vector3(14.,.4,0));load_crate.name="SwitchTestCrate"
	var canister=preload("res://scripts/miko8_collectible_canister.gd").new();canister.position=Vector3(30.,STOREY,0);add_child(canister)
	var crossing:=preload("res://scenes/reusable_cooling_station.tscn").instantiate();crossing.position=Vector3(66.,0,0);add_child(crossing)
func _stack(suffix:String,x:float,z:=0.)->void:
	_platform("BottomSolid"+suffix,preload("res://models/environment/level2_props/endcap.glb"),Vector3(x,0,z),1.279736,1.190739)
	_platform("TopOpen"+suffix,preload("res://models/environment/level2_props/platform.glb"),Vector3(x,STOREY,z),1.267573,1.131672)

func _platform(label:String,asset:PackedScene,at:Vector3,deck:float,depth:float)->void:
	var assembly:=Node3D.new();assembly.name=label;assembly.position=at;add_child(assembly)
	var model:Node3D=asset.instantiate();model.name="PlatformModel";model.rotation.y=PI*.5;model.scale=Vector3(2.2/depth,2.6/deck,5./1.9034);assembly.add_child(model)
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		mesh.create_trimesh_collision()
		if label.begins_with("TopOpen"):
			# The visible end opens along X, with the playable bay centered in depth.
			var bay := AABB(at + Vector3(-2.5, .08, -1.1), Vector3(5., 2.42, 2.2))
			for child in mesh.get_children():
				if child is StaticBody3D:
					child.set_meta("miko8_open_end_bay", bay)
		for surface in range(mesh.mesh.get_surface_count()):
			var source:=mesh.get_active_material(surface) as StandardMaterial3D
			if not source:continue
			var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_platform_neutral_steel.gdshader")
			paint.set_shader_parameter("base_texture",source.albedo_texture);paint.set_shader_parameter("base_color",source.albedo_color);mesh.set_surface_override_material(surface,paint)
	# Smooth support over the grating; leave the volume underneath open.
	var roof:=StaticBody3D.new();roof.name="WalkableDeck";assembly.add_child(roof)
	var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(4.80,.13,2.02);collision.shape=box;collision.position.y=2.565;roof.add_child(collision)
func _crate(at:Vector3,elevated_floor:=0.0)->RigidBody3D:
	var crate:=CRATE.new()
	crate.position=at
	crate.elevated_lane_floor_y=elevated_floor
	add_child(crate)
	return crate



