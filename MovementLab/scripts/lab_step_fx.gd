extends MultiMeshInstance3D

const CAPACITY := 80
const DUST := Color("b9a48c")
const SPARK := Color("ffc180")
const AIR := Color("76e5ee")

var actor: CharacterBody3D
var particles: Array[Dictionary] = []
var previous_x := 0.0
var stride := 0.0
var left_foot := false
var feet: Array[int] = []

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.use_custom_data = true
	batch.mesh = QuadMesh.new()
	batch.instance_count = CAPACITY
	batch.visible_instance_count = 0
	multimesh = batch
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://shaders/lab_step_fx.gdshader")
	material_override = paint
	feet = [actor.skeleton.find_bone("DEF-foot.L"),actor.skeleton.find_bone("DEF-foot.R")]
	actor.action_started.connect(_on_action)
	actor.landed.connect(_on_land)
	clear()

func clear() -> void:
	particles.clear()
	multimesh.visible_instance_count = 0
	previous_x = actor.global_position.x
	stride = 0.0

func _physics_process(_delta: float) -> void:
	var travel := absf(actor.global_position.x-previous_x)
	previous_x = actor.global_position.x
	if not actor.is_on_floor() or actor.state != "move" or actor.crouched or travel > .6 or absf(actor.velocity.x) < 1.6:
		stride = 0.0
		return
	stride += travel
	var length := lerpf(.87,1.34,clampf(absf(actor.velocity.x)/7.2,0.0,1.0))
	if stride < length:
		return
	stride -= length
	left_foot = not left_foot
	var foot := feet[int(left_foot)]
	var point := actor.global_position
	if foot >= 0:
		var posed: Vector3 = actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(foot).origin)
		point.x += clampf(posed.x-point.x,-.42,.42)
		point.z = clampf(posed.z,-.33,.33)
	_ground_burst(point,3,1,.48,false)

func _on_action(action: String) -> void:
	if action == "jump":
		_ground_burst(actor.global_position,6,4,.86,true)
	elif action == "double jump":
		var point := actor.global_position + Vector3(0,.06,.15)
		_add(point,Vector3(0,-.8,0),Vector2(.72,.32),.27,2,AIR,.83)
		for i in range(9):
			var side := randf_range(-1.0,1.0)
			_add(point+Vector3(side*.22,0,0),Vector3(side*2.3,randf_range(-5.5,-2.2),0),Vector2(.29,.064),randf_range(.16,.32),1,AIR,.88)
		for i in range(4):
			_add(point,Vector3(randf_range(-1.7,1.7),randf_range(-2.8,-1.5),0),Vector2(.28,.26),.32,0,AIR,.25)

func _on_land(speed: float) -> void:
	if speed < 2.8:
		return
	var strength := clampf(speed/12.0,.44,1.15)
	_ground_burst(actor.global_position,7,4,strength,true)

func _ground_burst(point: Vector3, dust_count: int, spark_count: int, strength: float, pulse: bool) -> void:
	point.y += .055
	if pulse:
		_add(point,Vector3.ZERO,Vector2.ONE*.65,.25,2,DUST,.37*strength,true)
	for i in range(dust_count):
		var vx: float = randf_range(-2.5,2.5) if pulse else -actor.facing*randf_range(.5,1.8)
		_add(point+Vector3(randf_range(-.17,.17),0,randf_range(-.13,.13)),
			Vector3(vx*strength,randf_range(.25,.86)*strength,0),Vector2(.29,.23),randf_range(.24,.42),0,DUST,.43*strength)
	for i in range(spark_count):
		var vx: float = randf_range(-3.1,3.1) if pulse else -actor.facing*randf_range(.8,2.5)
		_add(point,Vector3(vx,randf_range(.62,1.82),0)*strength,Vector2(.16,.031),randf_range(.12,.22),1,SPARK,.85*strength)

func _add(point: Vector3, velocity: Vector3, size: Vector2, duration: float, kind: int, tint: Color, opacity: float, flat := false) -> void:
	if particles.size() == CAPACITY:
		particles.pop_front()
	particles.append({"point":point,"velocity":velocity,"size":size,"duration":duration,"age":0.0,
		"kind":kind,"tint":tint,"opacity":opacity,"flat":flat})

func _process(delta: float) -> void:
	for i in range(particles.size()-1,-1,-1):
		var p: Dictionary = particles[i]
		p.age += delta
		if p.age >= p.duration:
			particles.remove_at(i)
			continue
		p.point += p.velocity*delta
		if p.kind == 1:
			p.velocity.y -= 10.0*delta
	for i in range(particles.size()):
		var p: Dictionary = particles[i]
		var t: float = p.age/p.duration
		var scale: Vector2 = p.size
		var basis := Basis.IDENTITY
		if p.kind == 0:
			scale *= 1.0+1.9*t
		elif p.kind == 1:
			basis = Basis(Vector3.BACK,atan2(p.velocity.y,p.velocity.x))
			scale.x *= 1.0-.65*t
		else:
			scale *= 1.0+2.4*t
			if p.flat:
				basis = Basis(Vector3.RIGHT,-PI/2)
		var tint: Color = p.tint
		tint.a = p.opacity * pow(1.0-t,1.6)
		multimesh.set_instance_transform(i,Transform3D(basis.scaled_local(Vector3(scale.x,scale.y,1)),p.point))
		multimesh.set_instance_color(i,tint)
		multimesh.set_instance_custom_data(i,Color(float(p.kind),0,0,0))
	multimesh.visible_instance_count = particles.size()
