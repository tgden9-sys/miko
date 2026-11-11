extends Node3D
const MATERIALS=preload("res://scripts/miko8_cel_materials.gd")
const ORDER:=["service_room","transformer","ventilation","transformer","service_room","ventilation","transformer","service_room","ventilation","transformer"]
func _ready()->void:
	name="CelSubstationBays"
	for i in range(ORDER.size()):
		var bay:Node3D=load("res://models/environment/cel_diorama/"+ORDER[i]+".glb").instantiate()
		bay.position.x=i*6-3;bay.name="Bay%02d_%s"%[i,ORDER[i]];add_child(bay)
		for mesh:MeshInstance3D in bay.find_children("*","MeshInstance3D",true,false):
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			for s in range(mesh.mesh.get_surface_count()):
				var original:=mesh.get_active_material(s) as StandardMaterial3D
				if original:mesh.set_surface_override_material(s,MATERIALS.convert(original))
			mesh.add_to_group("miko8_budget_visual");mesh.set_meta("budget_half_width",6.0)
		var lamp_at:=Vector3(i*6-0.5,3.15,-4.8) if ORDER[i]=="service_room" else Vector3(i*6+1.85,3.65,-4.6)
		if ORDER[i]=="ventilation":lamp_at=Vector3(i*6,4.1,-5.1)
		var light:=OmniLight3D.new();light.position=lamp_at;light.light_color=Color("ffc17b")
		light.light_energy=0.95;light.omni_range=3.3;light.shadow_enabled=false;add_child(light)
		light.add_to_group("miko8_budget_visual");light.set_meta("budget_half_width",4.1)
		var halo:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(1.05,0.8)
		halo.mesh=quad;halo.position=lamp_at+Vector3(0,0,0.06)
		var material:=ShaderMaterial.new();material.shader=preload("res://shaders/miko_practical_halo.gdshader")
		halo.material_override=material;halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(halo)
		halo.add_to_group("miko8_budget_visual");halo.set_meta("budget_half_width",0.7)
