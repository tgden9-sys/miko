extends Node3D
func _ready()->void:
	name="OverhangLoadingBay"
	var building:=StaticBody3D.new();building.name="ExtendedOverhang";building.position=Vector3(72,0,-.35);add_child(building)
	var model:Node3D=preload("res://models/environment/overhang_building/overhang.glb").instantiate();building.add_child(model)
	var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_overhang_skin.gdshader");paint.set_shader_parameter("concrete",preload("res://art/cel_scene/concrete_v1.png"));paint.set_shader_parameter("panels",preload("res://art/cel_scene/ladder_panels_v2.png"))
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		mesh.layers=4;mesh.create_trimesh_collision()
		for i in range(mesh.mesh.get_surface_count()):mesh.set_surface_override_material(i,paint)
	building.add_to_group("miko8_budget_visual");building.set_meta("budget_half_width",6.0)
	var footing=preload("res://scripts/miko8_building_footing.gd").new();footing.l_shaped=false;footing.rectangle_size=Vector2(3.2,3.);footing.position=Vector3(73.6,0,-.35);add_child(footing)
	var pad=preload("res://scripts/miko8_wall_mag_pad.gd").new();pad.name="CeilingMagPad";pad.mount_mode=1;pad.position=Vector3(69.2,4.4,0);pad.rotation.z=-PI/2;add_child(pad);pad.add_to_group("miko8_budget_visual");pad.set_meta("budget_half_width",2.0)
	var cargo=preload("res://scripts/miko8_heavy_cargo.gd").new();cargo.name="HeavyCargo";cargo.position=Vector3(69.2,.9,0);add_child(cargo);cargo.add_to_group("miko8_budget_visual");cargo.set_meta("budget_half_width",2.0)
