extends Node3D
## Shared hand/projectile energy: turbulent core, rising bubbles, sparks and soft halo.
var mode:="Plasma"
var radius:=.22
var tint:=Color("b366ff")
var core:MeshInstance3D
var bubbles:Array[MeshInstance3D]=[]
var sparks:MultiMesh
var light:OmniLight3D
var elapsed:=0.0
var energy_mat:ShaderMaterial
var corona:MeshInstance3D
var glow_gradient:Gradient
var built_radius:=.22

func set_mode(new_mode: String) -> void:
	mode = new_mode
	tint = color_for(mode)
	if energy_mat:
		energy_mat.set_shader_parameter("energy_color", tint)
		energy_mat.set_shader_parameter("agitation", 1.0 if mode == "Plasma" else 0.55)
	if is_instance_valid(light):
		light.light_color = tint
		light.light_energy = 0.60 if mode == "Plasma" else 0.3
	if corona:corona.visible=mode=="Plasma"
	if glow_gradient:
		for index in range(glow_gradient.get_point_count()):
			var alpha:=glow_gradient.get_color(index).a
			glow_gradient.set_color(index,Color(tint.r,tint.g,tint.b,alpha))

static func color_for(value:String)->Color:
	if value == "Warden": return Color("ffa138")
	return Color("58ff71") if value=="Green" else Color("ff394d") if value=="Red" else Color("369fff") if value=="Blue" else Color("b366ff")
func _ready()->void:
	built_radius=radius
	tint=color_for(mode)
	var energy:=ShaderMaterial.new();energy.shader=preload("res://shaders/miko8_energy_core.gdshader")
	energy.set_shader_parameter("energy_color",tint);energy.set_shader_parameter("agitation",1.0 if mode=="Plasma" else .55)
	energy_mat = energy
	core=_sphere(radius,energy);core.name="TurbulentCore"
	var glow:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2.ONE*radius*5.8;glow.mesh=quad
	var gradient:=Gradient.new();gradient.set_color(0,Color(tint.r,tint.g,tint.b,.34));gradient.set_color(1,Color(tint.r,tint.g,tint.b,0))
	glow_gradient=gradient
	gradient.add_point(.25,Color(tint.r,tint.g,tint.b,.20));gradient.add_point(.70,Color(tint.r,tint.g,tint.b,.025))
	var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.width=64;texture.height=64
	texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
	var haze:=StandardMaterial3D.new();haze.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	haze.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;haze.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	haze.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;haze.albedo_texture=texture
	glow.material_override=haze;glow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(glow)
	corona=MeshInstance3D.new()
	var corona_mesh:=QuadMesh.new()
	corona_mesh.size=Vector2.ONE*radius*4.6
	corona.mesh=corona_mesh
	var corona_paint:=ShaderMaterial.new()
	corona_paint.shader=preload("res://shaders/miko8_plasma_corona.gdshader")
	corona.material_override=corona_paint
	corona.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	corona.visible=mode=="Plasma"
	add_child(corona)
	for index in range(7 if mode=="Plasma" else 4):
		bubbles.append(_sphere(radius*.24,energy))
	var particles:=MultiMeshInstance3D.new();sparks=MultiMesh.new();sparks.transform_format=MultiMesh.TRANSFORM_3D;sparks.use_colors=true
	var spark_mesh:=SphereMesh.new();spark_mesh.radius=.012;spark_mesh.height=.024;spark_mesh.radial_segments=6;spark_mesh.rings=3
	var spark_mat:=StandardMaterial3D.new();spark_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.vertex_color_use_as_albedo=true;spark_mat.albedo_color=Color.WHITE;spark_mesh.material=spark_mat
	sparks.mesh=spark_mesh;sparks.instance_count=14 if mode=="Plasma" else 7
	sparks.custom_aabb=AABB(Vector3.ONE*-1.5,Vector3.ONE*3)
	particles.multimesh=sparks;particles.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(particles)
	light=OmniLight3D.new();light.light_color=tint;light.light_energy=.60 if mode=="Plasma" else .3
	light.omni_range=1.6;light.shadow_enabled=false;add_child(light)
func _sphere(size:float,material:Material)->MeshInstance3D:
	var visual:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=size;mesh.height=size*2
	mesh.radial_segments=20;mesh.rings=10;visual.mesh=mesh;visual.material_override=material
	visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(visual);return visual
func _process(delta:float)->void:
	if not is_visible_in_tree():return
	elapsed+=delta
	var camera:=get_viewport().get_camera_3d()
	if camera:corona.global_basis=camera.global_basis.scaled(Vector3.ONE*scale.x)
	core.scale=Vector3.ONE*(1.+.055*sin(elapsed*13.)+.025*sin(elapsed*23.))
	for index in range(bubbles.size()):
		var phase:=fmod(elapsed*(.9+index*.055)+index*.159,1.)
		var angle:=index*2.399+elapsed*(2.4+index*.12)
		var spread:=radius*(.75+phase*.65)
		bubbles[index].position=Vector3(cos(angle)*spread,(phase-.35)*radius*2.4,sin(angle)*spread*.65)
		bubbles[index].scale=Vector3.ONE*sin(phase*PI)*(.7+phase*.7)
	for index in range(sparks.instance_count):
		var age:=fmod(elapsed*.7+index*.137,1.)
		var angle:=index*2.399+elapsed*2.
		var reach:=radius*(1.+age*1.5)
		var point:=Vector3(cos(angle)*reach,(age-.25)*radius*3.3,sin(angle)*reach*.65)
		sparks.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*(1.-age)),point))
		sparks.set_instance_color(index,tint.lerp(Color.WHITE,.5))
	light.light_energy=(.6 if mode=="Plasma" else .3)*(1.+.12*sin(elapsed*17.))
