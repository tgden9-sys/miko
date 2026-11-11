extends Area3D
signal collected
var is_collected:=false
var model:Node3D
var display:Node3D
var halo:MeshInstance3D
var shadow:MeshInstance3D
var rings:Array[MeshInstance3D]=[]
var motes:Array[MeshInstance3D]=[]
var elapsed:=0.
const SCALE:=.24
const CENTRE:=.228
func _ready()->void:
	name="CollectibleCanister";add_to_group("miko8_canisters");collision_layer=0;collision_mask=1
	display=Node3D.new();display.name="HoveringPickup";add_child(display)
	model=preload("res://models/environment/level2_props/canister.glb").instantiate();model.scale=Vector3.ONE*SCALE;model.rotation.z=PI*.5
	# Re-centre the horizontal source cylinder after its upright quarter turn.
	model.position=Vector3(.480*SCALE,.94767*SCALE,0);display.add_child(model)
	var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_canister_energy.gdshader")
	for i in range(2):
		var ring:=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=.132+i*.025;torus.outer_radius=.15+i*.025;torus.rings=32;torus.ring_segments=6;ring.mesh=torus;ring.material_override=paint;ring.position.y=CENTRE;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;display.add_child(ring);rings.append(ring)
	halo=_patch(Vector2(.82,.82),Color(.18,1.,.88,.27),true);halo.position.y=CENTRE;display.add_child(halo)
	var light:=OmniLight3D.new();light.light_color=Color("60ffdd");light.light_energy=.3;light.omni_range=1.1;light.position.y=CENTRE;display.add_child(light)
	var spark:=StandardMaterial3D.new();spark.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;spark.albedo_color=Color("b6fff0")
	for i in range(10):
		var mote:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.009;sphere.height=.018;sphere.radial_segments=6;sphere.rings=3;mote.mesh=sphere;mote.material_override=spark;mote.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;display.add_child(mote);motes.append(mote)
	shadow=_patch(Vector2(.44,.36),Color(0,0,0,.28),false);shadow.rotation.x=-PI*.5;shadow.position.y=.008;add_child(shadow)
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.48,.72,.46);shape.shape=box;shape.position.y=.36;add_child(shape)
	body_entered.connect(_collect)
	_process(0.)
func _patch(size:Vector2,tint:Color,billboard:bool)->MeshInstance3D:
	var mesh:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=size;mesh.mesh=quad;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var gradient:=Gradient.new();gradient.set_color(0,tint);gradient.set_color(1,Color(tint,0.));var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.width=64;texture.height=64;texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.albedo_texture=texture
	if billboard:material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;material.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	mesh.material_override=material;return mesh
func _process(delta:float)->void:
	if is_collected:return
	elapsed+=delta;display.position.y=.12+.045*sin(elapsed*2.5)
	for i in range(rings.size()):rings[i].rotation=Vector3(.24*sin(elapsed*1.3+i*PI),elapsed*(1. if i==0 else -1.3),.35 if i==0 else -.48)
	halo.scale=Vector3.ONE*(1.+.08*sin(elapsed*3.8))
	for i in range(motes.size()):
		var phase:float=fmod(elapsed*.5+i*.1,1.);var angle:float=elapsed*1.5+i*2.399
		motes[i].position=Vector3(cos(angle)*.18,CENTRE+(phase-.5)*.38,sin(angle)*.14);motes[i].scale=Vector3.ONE*sin(phase*PI)
	shadow.scale=Vector3.ONE*(1.-.10*sin(elapsed*2.5))
func _collect(body:Node3D)->void:
	if is_collected or not body.is_in_group("miko8_magnetic_suit"):return
	is_collected=true;model.hide();display.hide();shadow.hide();collected.emit()
func reset_collectible()->void:is_collected=false;elapsed=0.;model.show();display.show();shadow.show();_process(0.)
