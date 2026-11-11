extends Node3D
var tint:=Color("b366ff")
var elapsed:=0.0
var duration:=.35
var particles:MultiMesh
var material:StandardMaterial3D
var nova:MeshInstance3D
var nova_material:ShaderMaterial

func _plasma_tint()->bool:
	return tint.r>.45 and tint.b>.7 and tint.b>tint.r

func _ready()->void:
	top_level = true
	var visual:=MultiMeshInstance3D.new()
	particles=MultiMesh.new()
	particles.transform_format=MultiMesh.TRANSFORM_3D
	var mesh:=SphereMesh.new()
	mesh.radius=.035
	mesh.height=.07
	mesh.radial_segments=6
	mesh.rings=3
	material=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=tint.lerp(Color.WHITE,.4)
	mesh.material=material
	particles.mesh=mesh
	particles.instance_count=18
	particles.custom_aabb=AABB(Vector3.ONE*-2,Vector3.ONE*4)
	visual.multimesh=particles
	visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	nova=MeshInstance3D.new()
	var disc:=QuadMesh.new()
	disc.size=Vector2(1.8,1.8)
	nova.mesh=disc
	nova_material=ShaderMaterial.new()
	nova_material.shader=preload("res://shaders/miko8_plasma_impact.gdshader")
	nova.material_override=nova_material
	nova.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nova.visible=_plasma_tint()
	add_child(nova)

func configure_impact(pos: Vector3, new_tint: Color) -> void:
	scale=Vector3.ONE
	global_position = pos
	tint = new_tint
	elapsed = 0.0
	duration=.20 if tint.g>tint.r and tint.g>tint.b else .35
	nova.visible=_plasma_tint() or tint.g>tint.r and tint.g>tint.b
	nova.scale=Vector3.ONE*(.42 if duration==.20 else 1.)
	nova_material.set_shader_parameter("tint",tint)
	nova_material.set_shader_parameter("progress",0.)
	if material:
		material.albedo_color = tint.lerp(Color.WHITE, 0.4)
	visible = true
	set_process(true)

func _process(delta:float)->void:
	elapsed+=delta
	if nova.visible:
		var camera:=get_viewport().get_camera_3d()
		if camera:nova.global_basis=camera.global_basis.scaled(nova.global_basis.get_scale())
		nova_material.set_shader_parameter("progress",clampf(elapsed/duration,0.,1.))
	if elapsed>duration:
		if has_meta("pool_ref") and is_instance_valid(get_meta("pool_ref")):
			get_meta("pool_ref").recycle_impact(self)
		else:
			queue_free()
		return
	for index in range(particles.instance_count):
		var angle:=index*2.399
		var direction:=Vector3(cos(angle),sin(angle),sin(index*7.1)*.5).normalized()
		var distance:float=elapsed*(1.4+fmod(index*.71,1.2))
		var streak:=Basis.looking_at(direction,Vector3.UP).scaled(Vector3(.45,.45,2.4)*(1.-elapsed/duration))
		particles.set_instance_transform(index,Transform3D(streak,direction*distance))
