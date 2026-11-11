extends Node
## Shared lighting/ground-contact treatment for the real buildings.
var scene:Node3D
var contacts:Array[MeshInstance3D]=[]
var materials:Array[ShaderMaterial]=[]
func _ready()->void:
	name="ArchitectureIntegration";scene=get_parent()
	for mesh:MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
		if mesh.layers!=4 or not mesh.mesh:continue
		for index in range(mesh.mesh.get_surface_count()):
			var material:=mesh.get_active_material(index) as ShaderMaterial
			if material and material.shader in [preload("res://shaders/miko8_ladder_building_skin.gdshader"),preload("res://shaders/miko8_loader.gdshader")]:
				if not materials.has(material):materials.append(material)
	var patch:=MeshInstance3D.new();patch.name="LadderBuildingGroundContact"
	var plane:=PlaneMesh.new();plane.size=Vector2(8.0,4.1);patch.mesh=plane
	var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_ladder_building_contact.gdshader")
	patch.material_override=paint;patch.position=Vector3(20.6,.012,-.39)
	patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(patch);contacts.append(patch)
	set_enabled(true)
	var workshop_footing:=preload("res://scripts/miko8_building_footing.gd").new()
	workshop_footing.l_shaped=false;workshop_footing.position=Vector3(55.4,0.,-.6);scene.add_child(workshop_footing)
func set_enabled(enabled:bool)->void:
	var key:DirectionalLight3D=scene.get_node("NeutralArchitectureKey")
	var fill:DirectionalLight3D=scene.get_node("NeutralArchitectureFill")
	key.rotation_degrees=Vector3(-38,18,0) if enabled else Vector3(-24,-48,0)
	key.light_energy=.82 if enabled else .64
	key.shadow_enabled=enabled
	key.directional_shadow_mode=0;key.directional_shadow_max_distance=45.
	key.shadow_bias=.02;key.shadow_normal_bias=.35
	fill.light_energy=.035 if enabled else .15
	fill.light_color=Color("adb8c7") if enabled else Color("fff4e6")
	for paint:ShaderMaterial in materials:
		paint.set_shader_parameter("architecture_ao",.65 if enabled else 1.)
		paint.set_shader_parameter("architecture_gain",.92 if enabled else 1.)
		if paint.shader==preload("res://shaders/miko8_loader.gdshader"):
			paint.set_shader_parameter("architecture_roughness_min",.88 if enabled else .35)
			paint.set_shader_parameter("architecture_specular",.18 if enabled else .5)
			paint.set_shader_parameter("architecture_metallic_scale",.25 if enabled else 1.)
	for contact:MeshInstance3D in contacts:contact.visible=enabled
