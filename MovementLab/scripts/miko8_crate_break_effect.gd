extends Node3D
## Textured pieces of the actual crate; cosmetic debris never blocks the actor.
var push_direction:=Vector3.RIGHT
var hit_point:=Vector3.ZERO
var energy_tint:=Color("d5a1ff")
var impact_strength:=1.0
var pieces:Array[Dictionary]=[]
var splinters:MultiMesh
var splinter_data:Array[Dictionary]=[]
var dust:MultiMesh
var dust_data:Array[Dictionary]=[]
var elapsed:=0.0
var flash:OmniLight3D
var shock_ring:MeshInstance3D
var rng:=RandomNumberGenerator.new()
func _ready()->void:
	name="WoodenCrateBreak";add_to_group("miko8_crate_debris");rng.randomize()
	if impact_strength>=1.0:
		get_tree().call_group("miko8_impact_feedback","crate_impact_feedback")
	var source:Node3D=preload("res://models/props/wooden_crate_broken.glb").instantiate();add_child(source)
	for piece:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var relative:Vector3=source.transform*piece.transform.origin
		var radial:Vector3=(relative-Vector3(0,.4,0)).normalized()
		var impulse:=radial*rng.randf_range(1.4,3.0)+push_direction*2.0+Vector3.UP*rng.randf_range(2.0,3.8)
		impulse*=impact_strength
		pieces.append({"node":piece,"velocity":impulse,"spin":Vector3(rng.randf_range(-6,6),rng.randf_range(-6,6),rng.randf_range(-6,6)),"base_scale":piece.scale})
	var wood:=StandardMaterial3D.new();wood.albedo_color=Color("88603a");wood.roughness=.95
	var sliver:=BoxMesh.new();sliver.size=Vector3(.025,.14,.018);sliver.material=wood
	splinters=_batch(sliver,28)
	for index in range(28):
		splinter_data.append({"p":Vector3(rng.randf_range(-.3,.3),rng.randf_range(.15,.7),rng.randf_range(-.3,.3)),"v":Vector3(rng.randf_range(-3.8,3.8),rng.randf_range(2.2,6.2),rng.randf_range(-1.6,1.6))+push_direction*2.,"axis":Vector3(rng.randf(),rng.randf(),rng.randf()).normalized(),"phase":rng.randf()*TAU})
	var smoke:=QuadMesh.new();smoke.size=Vector2.ONE
	var gradient:=Gradient.new();gradient.set_color(0,Color(1,1,1,.30));gradient.set_color(1,Color(1,1,1,0))
	var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.width=64;texture.height=64
	texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
	var dust_mat:=StandardMaterial3D.new();dust_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;dust_mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	dust_mat.albedo_texture=texture;dust_mat.vertex_color_use_as_albedo=true;smoke.material=dust_mat
	dust=_batch(smoke,16)
	for index in range(16):
		dust_data.append({"p":Vector3(rng.randf_range(-.3,.3),rng.randf_range(.08,.65),rng.randf_range(-.2,.2)),"v":Vector3(rng.randf_range(-.7,.7),rng.randf_range(.2,.8),rng.randf_range(-.3,.3)),"size":rng.randf_range(.25,.5)})
	shock_ring=MeshInstance3D.new()
	var torus:=TorusMesh.new();torus.inner_radius=0.06;torus.outer_radius=0.10;torus.rings=20;torus.ring_segments=6
	shock_ring.mesh=torus
	var ring_mat:=StandardMaterial3D.new();ring_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;ring_mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	ring_mat.albedo_color=energy_tint;shock_ring.material_override=ring_mat
	shock_ring.position=hit_point;shock_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shock_ring)
	flash=OmniLight3D.new();flash.light_color=energy_tint;flash.light_energy=1.8*impact_strength;flash.omni_range=3.0*impact_strength
	flash.position=hit_point;flash.shadow_enabled=false;add_child(flash)
	_sound()
	get_tree().call_group("miko8_cel_art","convert_debris",self)
func _batch(mesh:Mesh,count:int)->MultiMesh:
	var visual:=MultiMeshInstance3D.new();var batch:=MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true;batch.mesh=mesh;batch.instance_count=count
	batch.custom_aabb=AABB(Vector3(-10,-18,-5),Vector3(20,26,10));visual.multimesh=batch
	visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(visual)
	for index in range(count):batch.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
	return batch
func _sound()->void:
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050
	var data:=PackedByteArray();data.resize(7718*2)
	for index in range(7718):
		var t:=float(index)/22050.
		var crack:=rng.randf_range(-1,1)*exp(-t*48.)*.6
		var thud:=sin(TAU*(120.-t*80.)*t)*exp(-t*22.)*.4
		var rattle:=rng.randf_range(-1,1)*exp(-t*13.)*.12*(.5+.5*sin(t*260.))
		data.encode_s16(index*2,int(clampf(crack+thud+rattle,-1,1)*26000.))
	stream.data=data
	var sound:=AudioStreamPlayer.new();sound.stream=stream;sound.volume_db=-12;add_child(sound);sound.play()
func _physics_process(delta:float)->void:
	elapsed+=delta
	if elapsed>1.45:queue_free();return
	flash.light_energy=1.8*impact_strength*pow(maxf(0,1.-elapsed/.12),2)
	if is_instance_valid(shock_ring) and elapsed<0.26:
		var st:=elapsed/0.26
		var s_scale:=lerpf(0.4,2.6,1.0-pow(1.0-st,3.0))*impact_strength
		shock_ring.scale=Vector3(s_scale,s_scale*0.4,s_scale)
		(shock_ring.material_override as StandardMaterial3D).albedo_color.a=(1.0-st)*0.9
	elif is_instance_valid(shock_ring):
		shock_ring.visible=false
	var shrink:=1.-smoothstep(.65,1.45,elapsed)
	for record:Dictionary in pieces:
		var node:MeshInstance3D=record.node
		var previous:=node.global_position
		record.velocity.y-=12.*delta;node.position+=record.velocity*delta
		var support:=_surface_below(previous,node.global_position,.08)
		if not support.is_empty():
			node.global_position.y=support.position.y+.08
			record.velocity.y=absf(record.velocity.y)*.24 if absf(record.velocity.y)>.65 else 0.
			record.velocity.x*=exp(-5.*delta);record.velocity.z*=exp(-5.*delta);record.spin*=exp(-6.*delta)
		var spin:Vector3=record.spin
		if spin.length()>.001:node.rotate(spin.normalized(),spin.length()*delta)
		node.scale=record.base_scale*shrink
	for index in range(splinter_data.size()):
		var record:Dictionary=splinter_data[index]
		var previous:Vector3=to_global(record.p)
		record.v.y-=12.*delta;record.p+=record.v*delta
		var support:=_surface_below(previous,to_global(record.p),.02)
		if not support.is_empty():
			record.p=to_local(support.position+Vector3.UP*.02);record.v=Vector3.ZERO
		var basis:=Basis(record.axis,record.phase+elapsed*9.).scaled(Vector3.ONE*shrink)
		splinters.set_instance_transform(index,Transform3D(basis,record.p))
	for index in range(dust_data.size()):
		var record:Dictionary=dust_data[index];record.p+=record.v*delta
		var size:float=record.size*(1.+elapsed*2.2)
		dust.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*size),record.p))
		dust.set_instance_color(index,Color(.55,.42,.27,maxf(0,1.-elapsed/1.1)))

func _surface_below(previous:Vector3,current:Vector3,clearance:float)->Dictionary:
	if current.y>=previous.y:return {}
	# Sweep against actual floors/roofs. The crate's spawn height is not a floor.
	var ray:=PhysicsRayQueryParameters3D.create(previous,current-Vector3.UP*clearance,1)
	var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and hit.normal.y>.5:return hit
	return {}
