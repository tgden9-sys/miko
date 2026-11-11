extends "res://scripts/miko8_charge_box.gd"
func _ready()->void:
	freeze=true
	add_to_group("miko8_budget_visual");set_meta("budget_half_width",1.5)
	super._ready()
	display_root.queue_free()
	charge_materials.clear()
	display_root=preload("res://models/props/charge_base/charge_base.glb").instantiate()
	add_child(display_root)
	var bounds:=AABB();var first:=true
	for mesh:MeshInstance3D in display_root.find_children("*","MeshInstance3D",true,false):
		var box:AABB=(display_root.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds=box if first else bounds.merge(box);first=false
	var fit:=Vector3(.95,.8,.75)/bounds.size
	display_root.scale=fit
	base_scale=fit
	display_root.position=Vector3(-bounds.get_center().x*fit.x,-.4-bounds.position.y*fit.y,-bounds.get_center().z*fit.z)
	for child in get_children():
		if child is CollisionShape3D:child.shape.size=Vector3(.95,.8,.75)
	for mesh:MeshInstance3D in display_root.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var original:=mesh.get_active_material(i) as StandardMaterial3D
			if not original:continue
			var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_charge_base.gdshader")
			paint.set_shader_parameter("base_texture",original.albedo_texture)
			paint.set_shader_parameter("base_color",original.albedo_color)
			mesh.set_surface_override_material(i,paint);charge_materials.append(paint)
	var patch:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(1.18,.98);patch.mesh=plane;patch.position.y=-.392
	var gradient:=Gradient.new();gradient.set_color(0,Color(0,0,0,.65));gradient.set_color(1,Color(0,0,0,0))
	var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.width=64;texture.height=64;texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
	var shadow:=StandardMaterial3D.new();shadow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;shadow.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;shadow.albedo_texture=texture
	patch.material_override=shadow;patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(patch)
	_update_color()
