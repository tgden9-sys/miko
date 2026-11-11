extends Node3D
## Two short back-port filaments and pooled ion flecks. No actor material edits.
var actor:CharacterBody3D
var camera:Camera3D
var enabled:=true
var ribbons:Array=[[],[]]
var ribbon_mesh:=ImmediateMesh.new()
var sparks:MultiMesh
var particles:Array[Dictionary]=[]
var rng:=RandomNumberGenerator.new()
var previous:=Vector3.ZERO
var was_grounded:=true
var emission_time:=0.0
var spine:=-1
var toggle:CheckButton
var emitted:=0
const LIFE:=.38
const COUNT:=40
func _ready()->void:
	name="MikoEnergyWake";process_physics_priority=10;rng.seed=82013
	previous=actor.global_position;spine=actor.skeleton.find_bone("DEF-spine.003")
	var visual:=MeshInstance3D.new();visual.name="BackPortFilaments";visual.mesh=ribbon_mesh
	var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_energy_wake.gdshader")
	visual.material_override=paint;visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(visual)
	var quad:=QuadMesh.new();quad.size=Vector2.ONE
	var fleck:=ShaderMaterial.new();fleck.shader=preload("res://shaders/miko8_energy_spark.gdshader");quad.material=fleck
	sparks=MultiMesh.new();sparks.transform_format=MultiMesh.TRANSFORM_3D;sparks.use_colors=true
	sparks.mesh=quad;sparks.instance_count=COUNT;sparks.custom_aabb=AABB(Vector3(-5,-3,-5),Vector3(76,20,12))
	var batch:=MultiMeshInstance3D.new();batch.name="IonFlecks";batch.multimesh=sparks
	batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(batch)
	for i in range(COUNT):
		particles.append({"age":1.,"life":0.});sparks.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
	toggle=CheckButton.new();toggle.text="Energy wake";toggle.button_pressed=true;toggle.focus_mode=Control.FOCUS_NONE
	toggle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	toggle.offset_left=-274;toggle.offset_right=-38;toggle.offset_top=308;toggle.offset_bottom=344
	toggle.add_theme_font_size_override("font_size",18);get_parent().game_size.get_parent().add_child(toggle)
	toggle.toggled.connect(set_enabled)
func set_enabled(value:bool)->void:
	enabled=value;toggle.set_pressed_no_signal(value)
	if not value:clear_wake()
func clear_wake()->void:
	for points:Array in ribbons:points.clear()
	ribbon_mesh.clear_surfaces()
	for i in range(COUNT):
		particles[i].age=1.;particles[i].life=0.
		sparks.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
func colour()->Color:
	return Color("ff6878").srgb_to_linear() if actor.suit_polarity==1 else Color("60baff").srgb_to_linear() if actor.suit_polarity==2 else Color("81f4ce").srgb_to_linear()
func _emit(point:Vector3,velocity:Vector3,size:float,life:float)->void:
	for i in range(COUNT):
		if particles[i].age>=particles[i].life:
			particles[i]={"p":point,"v":velocity,"age":0.,"life":life,"size":size,"colour":colour()};emitted+=1;return
func _physics_process(delta:float)->void:
	if not actor.ready_for_input:return
	var moved:=actor.global_position.distance_to(previous);previous=actor.global_position
	if moved>1.5:clear_wake();was_grounded=actor.is_on_floor();return
	for points:Array in ribbons:
		for point:Dictionary in points:point.age+=delta
		while not points.is_empty() and points[0].age>LIFE:points.pop_front()
	var blocked:bool=actor.state.begins_with("Climb") or actor.state in ["Turn","Death","Dead"]
	var grounded:=actor.is_on_floor()
	var moving:bool=absf(actor.velocity.x)>1.25 or (not grounded and actor.state in ["Air","JumpStart"])
	if enabled and not blocked and moving:
		var port:Vector3=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(spine).origin)+Vector3(-actor.facing*.27,0,.15)
		for i in range(2):
			var point:=port+Vector3(0,-float(i)*.17,0)
			if ribbons[i].is_empty() or point.distance_to(ribbons[i][-1].p)>.018:
				ribbons[i].append({"p":point,"age":0.,"colour":colour()})
		emission_time-=delta
		if emission_time<=0:
			emission_time=.055
			_emit(port+Vector3(0,rng.randf_range(-.18,.04),.015),Vector3(-actor.facing*.35,rng.randf_range(.05,.24),rng.randf_range(-.04,.04)),rng.randf_range(.055,.09),rng.randf_range(.25,.48))
		if was_grounded and not grounded:
			for i in range(8):_emit(port,Vector3(-actor.facing*rng.randf_range(.2,.8),rng.randf_range(-.4,.4),rng.randf_range(-.1,.1)),rng.randf_range(.04,.075),rng.randf_range(.2,.4))
	was_grounded=grounded
func _vertex(point:Dictionary,side:Vector3,edge:float)->void:
	var fade:=pow(maxf(0.,1.-float(point.age)/LIFE),.75)
	var tint:Color=point.colour;tint.a=fade
	ribbon_mesh.surface_set_color(tint);ribbon_mesh.surface_set_uv(Vector2(edge,float(point.age)/LIFE))
	ribbon_mesh.surface_add_vertex(point.p+side*(edge-.5)*.14*(.5+fade*.5))
func _process(delta:float)->void:
	if not camera:return
	ribbon_mesh.clear_surfaces()
	var any:bool=ribbons[0].size()>1 or ribbons[1].size()>1
	if any:
		ribbon_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for points:Array in ribbons:
			for i in range(1,points.size()):
				var a:Dictionary=points[i-1];var b:Dictionary=points[i]
				var side:Vector3=(b.p-a.p).cross(camera.global_basis.z).normalized()
				_vertex(a,side,0.);_vertex(b,side,0.);_vertex(a,side,1.)
				_vertex(a,side,1.);_vertex(b,side,0.);_vertex(b,side,1.)
		ribbon_mesh.surface_end()
	for i in range(COUNT):
		var p:Dictionary=particles[i]
		if p.age>=p.life:
			sparks.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO));continue
		p.age+=delta;p.p+=p.v*delta
		var fade:=maxf(0.,1.-float(p.age)/float(p.life))
		var tint:Color=p.colour;tint.a=fade*.8
		sparks.set_instance_transform(i,Transform3D(camera.global_basis.scaled(Vector3.ONE*float(p.size)*(0.5+fade*.5)),p.p))
		sparks.set_instance_color(i,tint)
func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F10:
		set_enabled(not enabled);get_viewport().set_input_as_handled()
