extends CharacterBody3D
var actor: CharacterBody3D
var model_scene: PackedScene
var home := Vector3(.3, 0, 0)
var hitstop := 0.0
var hits := 0
var damage := 0
var last_damage := 0
var stagger := 0.0
var flash := 0.0
var attacking := false
var attack_age := 0.0
var attack_fired := false
var paint: StandardMaterial3D
var body: Node3D
var droid: Node3D
var droid_materials: Array[ShaderMaterial] = []
var arm: MeshInstance3D
var label: Label3D
var popups: Array[Dictionary] = []

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var shape := CapsuleShape3D.new()
	shape.radius = .42 if model_scene else .35
	shape.height = 2.124 if model_scene else 1.65
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = shape.height*.5
	add_child(collider)
	paint = StandardMaterial3D.new()
	paint.albedo_color = Color("cf8d56")
	paint.roughness = 1
	body = Node3D.new()
	add_child(body)
	if model_scene:
		droid = model_scene.instantiate() as Node3D
		droid.rotation.y = -1.03
		droid.scale = Vector3.ONE*1.116
		body.add_child(droid)
		for mesh: MeshInstance3D in droid.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.get_surface_override_material_count()):
				var original := mesh.get_active_material(surface) as StandardMaterial3D
				if original:
					var material := ShaderMaterial.new()
					material.shader = preload("res://shaders/miko8_three_tone.gdshader")
					material.set_shader_parameter("base_texture", original.albedo_texture)
					mesh.set_surface_override_material(surface, material)
					droid_materials.append(material)
	else:
		_build_dummy_visual()
	reset()

func _build_dummy_visual() -> void:
	var torso := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = .31
	cylinder.bottom_radius = .22
	cylinder.height = .85
	cylinder.radial_segments = 12
	torso.mesh = cylinder
	torso.position.y = .95
	torso.material_override = paint
	body.add_child(torso)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = .22
	sphere.height = .44
	sphere.radial_segments = 12
	sphere.rings = 6
	head.mesh = sphere
	head.position.y = 1.6
	head.material_override = paint
	body.add_child(head)
	arm = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(1.15,.12,.12)
	arm.mesh = bar
	arm.position.y = 1.1
	arm.material_override = paint
	body.add_child(arm)
	var post := MeshInstance3D.new()
	var pole := CylinderMesh.new()
	pole.top_radius = .06
	pole.bottom_radius = .06
	pole.height = .7
	pole.radial_segments = 8
	post.mesh = pole
	post.position.y = .35
	post.material_override = paint
	body.add_child(post)
	label = Label3D.new()
	label.position = Vector3(0,2.1,0)
	label.font_size = 28
	label.pixel_size = .005
	label.no_depth_test = true
	add_child(label)

func reset() -> void:
	for p: Dictionary in popups:
		if is_instance_valid(p.node):
			p.node.queue_free()
	popups.clear()
	position = home
	velocity = Vector3.ZERO
	hits = 0
	damage = 0
	last_damage = 0
	hitstop = 0
	stagger = 0
	flash = 0
	attack_age = 0
	attack_fired = false
	if body:
		body.scale = Vector3.ONE
		body.rotation = Vector3.ZERO
	_refresh_label()

func _update_popups(delta: float) -> void:
	for i in range(popups.size() - 1, -1, -1):
		var p: Dictionary = popups[i]
		p.life -= delta
		p.node.position.y += p.vy * delta
		p.vy = move_toward(p.vy, 0.4, delta * 9.0)
		var f: float = clampf(p.life / p.max_life, 0.0, 1.0)
		p.node.scale = Vector3.ONE * (1.3 if f > 0.8 else f * 1.3)
		p.node.modulate.a = f
		if p.life <= 0:
			p.node.queue_free()
			popups.remove_at(i)

func _physics_process(delta: float) -> void:
	_update_popups(delta)
	if hitstop > 0:
		hitstop = maxf(0, hitstop - delta)
		return
	stagger = maxf(0, stagger - delta)
	flash = maxf(0, flash - delta)
	velocity.y -= 25 * delta
	velocity.x = move_toward(velocity.x, 0, delta * 12)
	move_and_slide()
	position.z = 0
	if is_on_floor() and stagger <= 0 and absf(position.x - home.x) > .01:
		position.x = move_toward(position.x, home.x, delta * .8)
	body.rotation.z = sin(stagger * 36) * stagger * .20
	body.scale = body.scale.lerp(Vector3.ONE, 1.0 - exp(-delta * 20.0))
	if flash > 0.05:
		paint.albedo_color = Color("ffffff")
	elif flash > 0:
		paint.albedo_color = Color("fff0b0")
	else:
		paint.albedo_color = Color("cf8d56")
	if arm and attacking and stagger <= 0:
		attack_age += delta
		var sign_to_actor: float = signf(actor.position.x - position.x)
		if attack_age > 1.3 and attack_age < 1.95:
			paint.albedo_color = Color("ffca54")
			arm.rotation.z = sign_to_actor * .55
		elif attack_age >= 1.95 and not attack_fired:
			attack_fired = true
			arm.rotation.z = 0
			if absf(actor.position.x - position.x) < 1.8 and absf(actor.position.y - position.y) < 1.6:
				if actor.receive_attack(position.x):
					stagger = .8
					hitstop = .075
					flash = .2
		if attack_age >= 2.7:
			attack_age = 0
			attack_fired = false
	else:
		attack_age = 0
		attack_fired = false
		if arm: arm.rotation.z = 0
	_refresh_label()

func receive_hit(amount: int, direction: int, lift: float) -> void:
	hits += 1
	damage += amount
	last_damage = amount
	stagger = .30
	flash = .10
	var is_heavy: bool = amount >= 36
	if not model_scene:
		body.scale = Vector3(1.20, 0.82, 1.0) if is_heavy else Vector3(1.14, 0.88, 1.0)
	velocity.x = direction * (1.0 if lift <= 0 else 1.6)
	if lift > 0:
		velocity.y = lift
	_spawn_damage_popup(amount, direction)
	_refresh_label()

func _spawn_damage_popup(amount: int, direction: int) -> void:
	var pop := Label3D.new()
	var is_crit: bool = amount >= 36
	pop.text = ("%d!" if is_crit else "%d") % amount
	pop.font_size = 36 if is_crit else 28
	pop.pixel_size = 0.005
	pop.no_depth_test = true
	pop.modulate = Color("fae0a0") if is_crit else Color("ffffff")
	pop.outline_modulate = Color("182024")
	pop.outline_size = 6
	pop.position = Vector3(float(direction) * 0.2 + randf_range(-0.1, 0.1), 2.25 + randf_range(0.0, 0.15), 0.4)
	add_child(pop)
	popups.append({"node": pop, "life": 0.40, "max_life": 0.40, "vy": 3.0})

func _refresh_label() -> void:
	if not label: return
	label.text = ("PARRY PRACTICE" if attacking else "TRAINING DUMMY") + "\n%d hits  ·  %d damage" % [hits, damage]
