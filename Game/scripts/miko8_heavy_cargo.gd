extends "res://scripts/miko8_charge_box.gd"
func _ready()->void:
	suit_movable=false;block_movable=false;charge_squash=false
	super._ready();mass=25.;linear_damp=2.
	set_meta("magnetic_half_height",.9);set_meta("magnetic_half_width",1.1);set_meta("budget_half_width",1.4)
	display_root.queue_free();charge_materials.clear();charge_meshes.clear()
	display_root=preload("res://models/props/heavy_cargo/heavy_cargo.glb").instantiate();display_root.name="HeavyCargoModel";add_child(display_root);base_scale=Vector3.ONE
	for child in get_children():
		if child is CollisionShape3D:child.shape.size=Vector3(2.2,1.8,1.4)
	display_root.position.y=-.9
	marker.mesh.size=Vector3(2.25,1.85,1.45)
	for mesh:MeshInstance3D in display_root.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var source:=mesh.get_active_material(i) as StandardMaterial3D
			if not source:continue
			var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_crate.gdshader");paint.set_shader_parameter("base_texture",source.albedo_texture);paint.set_shader_parameter("base_color",source.albedo_color)
			paint.set_shader_parameter("metallic_factor",0.);paint.set_shader_parameter("roughness_factor",.95);mesh.set_surface_override_material(i,paint);charge_materials.append(paint)
			charge_meshes.append(mesh)
			var bounds:=mesh.mesh.get_aabb()
			paint.set_shader_parameter("bounds_center",bounds.get_center())
			paint.set_shader_parameter("bounds_half",bounds.size*.5)
	_update_color()
