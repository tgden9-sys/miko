extends Node3D
const HEIGHT:=3.45
var towers:Array[Node3D]=[]
func _ready()->void:
	name="TowerCatwalkTest"
	for x:float in [8.,15.6]:
		var tower:=Node3D.new();tower.name="LadderTower";add_child(tower);towers.append(tower)
		_model(tower,"tower",Vector3(x,0,-.76),Vector3.ONE*(HEIGHT/1.902982),0.)
		_floor(tower,Vector3(x,HEIGHT-.07,-.76),Vector3(1.,.14,1.))
		var ladder=preload("res://scripts/miko8_ladder.gd").new();ladder.position=Vector3(x,0,0);ladder.height=HEIGHT;ladder.above_platform=0.;ladder.visible=false;ladder.set_meta("bpg_ladder",true);ladder.set_meta("direct_entry",true);ladder.set_meta("top_entry_x",x);tower.add_child(ladder)
	for x:float in [9.8,14.0]:
		var section:=Node3D.new();section.name="CatwalkSection";add_child(section)
		_model(section,"catwalk",Vector3(x,HEIGHT-.046635*1.5,-.7),Vector3(1.5,1.5,1.7),PI/2)
		_floor(section,Vector3(x,HEIGHT-.07,-.7),Vector3(3.22,.14,1.1))
func _model(parent:Node,name:String,at:Vector3,stretch:Vector3,yaw:float)->void:
	var model:Node3D=load("res://models/environment/tower_catwalk/"+name+".glb").instantiate();model.position=at;model.scale=stretch;model.rotation.y=yaw;parent.add_child(model)
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		mesh.layers=4
		for i in range(mesh.mesh.get_surface_count()):
			var source:=mesh.get_active_material(i) as StandardMaterial3D
			if not source:continue
			var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_tower_catwalk_cel.gdshader");paint.set_shader_parameter("base_texture",source.albedo_texture);paint.set_shader_parameter("base_color",source.albedo_color);mesh.set_surface_override_material(i,paint)
func _floor(parent:Node,at:Vector3,size:Vector3)->void:
	var body:=StaticBody3D.new();body.position=at;var c:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=size;c.shape=box;body.add_child(c);parent.add_child(body)
