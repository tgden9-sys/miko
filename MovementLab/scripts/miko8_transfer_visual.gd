extends Node3D
## A flush emitter, a projected glyph and a small set of coherent transfer strands.

var actor:CharacterBody3D
var camera:Camera3D
var glyph:MeshInstance3D
var glyph_material:ShaderMaterial
var strand_material:ShaderMaterial
var strands:ImmediateMesh
var strand_visual:MeshInstance3D
var emitter_material:ShaderMaterial
var projection:MeshInstance3D
var projection_material:ShaderMaterial
var motes:MultiMesh
var elapsed:=0.0

func _ready()->void:
	var housing:=MeshInstance3D.new()
	housing.name="EmitterHousing"
	var shell:=BoxMesh.new()
	shell.size=Vector3(.81,.040,.38)
	housing.mesh=shell
	housing.position=Vector3(0,.020,.12)
	housing.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shell_paint:=StandardMaterial3D.new()
	shell_paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	shell_paint.albedo_color=Color("26343a")
	housing.material_override=shell_paint
	add_child(housing)

	var emitter:=MeshInstance3D.new()
	emitter.name="FlushEmitter"
	var plate:=PlaneMesh.new()
	plate.size=Vector2(1.52,1.02)
	emitter.mesh=plate
	emitter.position=Vector3(0,.042,.12)
	emitter.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emitter_material=ShaderMaterial.new()
	emitter_material.shader=preload("res://shaders/miko8_transfer_emitter.gdshader")
	emitter.material_override=emitter_material
	add_child(emitter)

	projection=MeshInstance3D.new()
	projection.name="EmitterProjection"
	var beam:=QuadMesh.new()
	beam.size=Vector2(.44,1.0)
	projection.mesh=beam
	projection.position=Vector3(0,.55,.12)
	projection.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	projection_material=ShaderMaterial.new()
	projection_material.shader=preload("res://shaders/miko8_transfer_projection.gdshader")
	projection.material_override=projection_material
	add_child(projection)

	var light_paint:=StandardMaterial3D.new()
	light_paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	light_paint.albedo_color=Color("a2e8d7")
	glyph=MeshInstance3D.new()
	var quad:=QuadMesh.new()
	quad.size=Vector2(.94,.94)
	glyph.mesh=quad
	glyph.position=Vector3(0,1.30,.14)
	glyph_material=ShaderMaterial.new()
	glyph_material.shader=preload("res://shaders/miko8_transfer_glyph.gdshader")
	glyph.material_override=glyph_material
	glyph.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glyph)
	strand_material=ShaderMaterial.new()
	strand_material.shader=preload("res://shaders/miko8_transfer_ribbon.gdshader")
	strands=ImmediateMesh.new()
	strand_visual=MeshInstance3D.new()
	strand_visual.mesh=strands
	strand_visual.material_override=strand_material
	strand_visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(strand_visual)
	motes=MultiMesh.new()
	motes.transform_format=MultiMesh.TRANSFORM_3D
	var mote_mesh:=BoxMesh.new()
	mote_mesh.size=Vector3(.026,.026,.012)
	mote_mesh.material=light_paint
	motes.mesh=mote_mesh
	motes.instance_count=16
	motes.visible_instance_count=0
	var mote_visual:=MultiMeshInstance3D.new()
	mote_visual.multimesh=motes
	mote_visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mote_visual)

func _curve(start:Vector3,finish:Vector3,t:float,spread:float)->Vector3:
	var control_a:=start+Vector3(.22+spread,-.28,.02)
	var control_b:=finish+Vector3(-.24+spread,.50,.02)
	var s:=1.-t
	return s*s*s*start+3.*s*s*t*control_a+3.*s*t*t*control_b+t*t*t*finish

func _ribbon(points:PackedVector3Array,width:float)->void:
	for i in range(points.size()-1):
		var along:=(points[i+1]-points[i]).normalized()
		var normal:=along.cross(camera.global_basis.z).normalized()*width*.5
		var corners:=[points[i]-normal,points[i]+normal,points[i+1]+normal,points[i+1]-normal]
		var uvs:=[Vector2(0,float(i)/float(points.size()-1)),Vector2(1,float(i)/float(points.size()-1)),
			Vector2(1,float(i+1)/float(points.size()-1)),Vector2(0,float(i+1)/float(points.size()-1))]
		for index:int in [0,1,2,0,2,3]:
			strands.surface_set_uv(uvs[index])
			strands.surface_add_vertex(corners[index])

func update_effect(delta:float,progress:float,charge:float,contact:bool,arriving:=false)->void:
	elapsed+=delta
	glyph.global_basis=camera.global_basis
	var horizontal:=camera.global_basis.x.slide(Vector3.UP).normalized()
	projection.global_basis=Basis(horizontal,Vector3.UP,horizontal.cross(Vector3.UP))
	glyph_material.set_shader_parameter("lock_amount",charge)
	emitter_material.set_shader_parameter("lock_amount",charge)
	projection_material.set_shader_parameter("lock_amount",charge)
	strands.clear_surfaces()
	strands.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_ribbon(PackedVector3Array([Vector3(0,.045,.12),Vector3(0,1.02,.14)]),.027)
	if contact:
		var hand:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-f_index.03.L")).origin)
		_ribbon(PackedVector3Array([to_local(hand),glyph.position]),.032)
	var activity:=smoothstep(.015,.13,progress)*(1.-smoothstep(.89,1.,progress))
	var start:=to_local(actor.global_position)+Vector3(0,clampf(progress*2.12-.075,.04,1.82),.17)
	var finish:=Vector3(0,.05,.12)
	if activity>.001:
		for strand in range(6):
			var spread:=(float(strand)-2.5)*.055
			var from:=start+Vector3(spread,.022*sin(elapsed*3.+strand),float(strand%2)*.035)
			var points:=PackedVector3Array()
			for step in range(25):
				var t:=float(step)/24.
				points.append(_curve(from,finish,t,spread))
			_ribbon(points,.047*activity)
	strands.surface_end()
	motes.visible_instance_count=16 if activity>.001 else 0
	for index in range(motes.visible_instance_count):
		var t:=fposmod(elapsed*.65+float(index)/16.,1.)
		if arriving:t=1.-t
		var spread:=(float(index%6)-2.5)*.055
		var point:=_curve(start+Vector3(spread,0,0),finish,t,spread)
		var scale_amount:=activity*sin(t*PI)
		motes.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_amount),point))
