extends Node3D
## Straight-sided scenery modules; decorative geometry never obstructs the lane.
var variant:=2
var room_length:=80.
var reserve_cooling_plot:=true
var buildings:Array[Node3D]=[]
func _ready()->void:
	name="NearBuildingDistrict"
	var paving:=ShaderMaterial.new();paving.shader=preload("res://shaders/miko8_restored_paving.gdshader")
	paving.set_shader_parameter("grain",preload("res://art/cel_scene/concrete_v1.png"));paving.set_shader_parameter("damp_amount",.12)
	var court:=_box(self,"ContinuousForecourt",Vector3(room_length+6.,.16,6.4),Vector3(room_length*.5,-.08,-4.4),Color.WHITE)
	court.material_override=paving
	var cursor:float=-3.
	for i in range(ceili(room_length/7.)+2):
		var width:float=([6.8,8.,7.2][i%3] if variant==2 else [10.,8.5,11.][i%3])
		var height:float=([5.2,6.4,4.4,7.,5.6,4.8][i%6] if variant==2 else [4.2,5.,3.8,5.6][i%4])
		# This plot is occupied by the complete cooling-station assembly.
		if reserve_cooling_plot and variant==2 and i==8:
			cursor+=width+.85
			continue
		var root:=Node3D.new();root.name="Building%02d"%i;root.position=Vector3(cursor+width*.5,-.025,-5.);add_child(root);buildings.append(root)
		var skin:=ShaderMaterial.new();skin.shader=preload("res://shaders/miko8_ladder_building_skin.gdshader")
		skin.set_meta("cel_facade_art","res://art/cel_scene/tall_departure_facade_v1.png" if (i+variant)%2==0 else "res://art/cel_scene/tall_arrival_facade_v1.png")
		skin.set_shader_parameter("building_origin",root.global_position);skin.set_shader_parameter("building_height",height);skin.set_shader_parameter("facade_height",height)
		skin.set_shader_parameter("facade_start_x",-width*.5);skin.set_shader_parameter("facade_width",width)
		var walls:=_box(root,"OrthogonalWalls",Vector3(width,height,2.8),Vector3(0,height*.5,0),Color.WHITE);walls.material_override=skin
		_box(root,"GroundPlinth",Vector3(width+.06,.20,2.86),Vector3(0,.1,0),Color("333b3e"))
		var coping:=_box(root,"RoofCoping",Vector3(width+.14,.09,2.94),Vector3(0,height+.045,0),Color("6a7070"));coping.material_override=skin
		for side in [-1.,1.]:_box(root,"CornerPier",Vector3(.12,height,.09),Vector3(side*(width*.5-.06),height*.5,1.43),Color("646b6a"))
		var unit:Node3D=preload("res://models/environment/yard_life/exhaust_outlet.glb").instantiate();unit.position=Vector3(-width*.28,height+.09,0);unit.scale=Vector3.ONE*(1.25 if variant==2 else .85);root.add_child(unit)
		for mesh:MeshInstance3D in unit.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh.mesh.get_surface_count()):
				var material:=mesh.get_active_material(surface) as StandardMaterial3D
				if material:material.vertex_color_use_as_albedo=true
		cursor+=width+(.85 if variant==2 else .3)
func _box(parent:Node3D,label:String,size:Vector3,at:Vector3,color:Color)->MeshInstance3D:
	var visual:=MeshInstance3D.new();visual.name=label;var box:=BoxMesh.new();box.size=size;visual.mesh=box;visual.position=at;visual.layers=4
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.95;visual.material_override=material;parent.add_child(visual);return visual
