extends "res://scripts/dummy.gd"

const MAX_HEALTH := 100
const PATROL_RADIUS := 3.0
const WALK_SPEED := 1.2
const SIGHT_RANGE := 5.3
const WINDUP := .95
const SWIPE := .24
enum Mode { PATROL, APPROACH, WINDUP, SWIPE, DOWN }

var skeleton: Skeleton3D
var animation: AnimationPlayer
var health := MAX_HEALTH
var mode := Mode.PATROL
var elapsed := 0.0
var facing := 1
var patrol_direction := 1
var current_clip := ""
var clip_names := {}
var guard_rotations := {}
var sword: Node3D
var sword_material: StandardMaterial3D
var death_tween: Tween
var struck := false
var model_scale := 1.0
var trail_fx: Node3D

func _ready() -> void:
	super._ready()
	skeleton = droid.find_children("*", "Skeleton3D", true, false)[0]
	animation = droid.find_children("*", "AnimationPlayer", true, false)[0]
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in animation.get_animation_list():
		clip_names[clip.get_slice("Warden_", 1)] = clip
	# Match the imported character mesh height before applying animation.
	var miko_mesh: MeshInstance3D = actor.model.find_children("*", "MeshInstance3D", true, false)[0]
	var enemy_mesh: MeshInstance3D = droid.find_children("*", "MeshInstance3D", true, false)[0]
	model_scale = miko_mesh.get_aabb().size.y / enemy_mesh.get_aabb().size.y
	droid.scale = Vector3.ONE * model_scale
	var collider: CollisionShape3D = get_child(0)
	collider.shape.height = miko_mesh.get_aabb().size.y
	collider.shape.radius = .35
	collider.position.y = collider.shape.height * .5
	animation.play(clip_names.Guard)
	animation.seek(.22, true)
	animation.advance(0.0)
	for i in range(skeleton.get_bone_count()):
		var name := skeleton.get_bone_name(i)
		if "arm" in name or "hand" in name or "shoulder" in name or "spine" in name or "f_" in name or "thumb" in name:
			guard_rotations[i] = skeleton.get_bone_pose_rotation(i)
	_build_sword()
	trail_fx = preload("res://scripts/enemy_sword_trail.gd").new()
	trail_fx.fighter = self
	add_child(trail_fx)
	var canvas := CanvasLayer.new()
	canvas.layer = 3
	add_child(canvas)
	var bar := preload("res://scripts/miko8_health_bar.gd").new()
	bar.actor = self
	bar.hostile = true
	canvas.add_child(bar)
	reset()

func _build_sword() -> void:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = "DEF-hand.R"
	skeleton.add_child(attachment)
	sword = Node3D.new()
	attachment.add_child(sword)
	var index := skeleton.get_bone_rest(skeleton.find_bone("DEF-f_index.01.R")).origin
	var pinky := skeleton.get_bone_rest(skeleton.find_bone("DEF-f_pinky.01.R")).origin
	sword.position = (index + pinky) * .43
	sword.basis = Basis(Quaternion(Vector3.RIGHT, (index - pinky).normalized()))
	sword_material = StandardMaterial3D.new()
	sword_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sword_material.albedo_color = Color("ed283b")
	for part in [
		[Vector3(.20,.05,.04), Vector3.ZERO, Color("252b34")],
		[Vector3(.04,.19,.08), Vector3(.11,0,0), Color("913348")],
		[Vector3(.88,.065,.025), Vector3(.57,0,0), Color("ed283b")],
		[Vector3(.88,.012,.027), Vector3(.57,-.033,0), Color("ffb6b8")]]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[0]
		mesh.mesh = box
		mesh.position = part[1]
		var material := sword_material.duplicate() as StandardMaterial3D
		material.albedo_color = part[2]
		mesh.material_override = material
		sword.add_child(mesh)

func reset() -> void:
	super.reset()
	if death_tween:
		death_tween.kill()
		death_tween = null
	show()
	health = MAX_HEALTH
	collision_layer = 4
	mode = Mode.PATROL
	elapsed = 0.0
	facing = 1
	patrol_direction = 1
	current_clip = ""
	struck = false
	body.position = Vector3.ZERO
	droid.scale = Vector3.ONE * model_scale
	droid.rotation.y = PI * .5
	if sword:
		sword.show()
	_set_dissolve(0.0)
	if trail_fx:
		trail_fx.clear()

func _enter(next: Mode) -> void:
	mode = next
	elapsed = 0.0
	struck = false

func _physics_process(delta: float) -> void:
	_update_popups(delta)
	if hitstop > 0:
		hitstop = maxf(0, hitstop - delta)
		return
	elapsed += delta
	stagger = maxf(0, stagger - delta)
	velocity.y -= 25.0 * delta
	var speed := 0.0
	if stagger <= 0.0:
		match mode:
			Mode.PATROL:
				if _sees_miko():
					facing = 1 if actor.position.x > position.x else -1
					_enter(Mode.APPROACH)
				else:
					if absf(position.x-home.x) >= PATROL_RADIUS and (position.x-home.x)*patrol_direction > 0:
						patrol_direction *= -1
					facing = patrol_direction
					speed = facing * WALK_SPEED
			Mode.APPROACH:
				if not _sees_miko():
					_enter(Mode.PATROL)
				else:
					facing = 1 if actor.position.x > position.x else -1
					if absf(actor.position.x-position.x) < 1.65 and absf(actor.position.y-position.y) < .65:
						_enter(Mode.WINDUP)
					else:
						speed = facing * WALK_SPEED
			Mode.WINDUP:
				if elapsed >= WINDUP:
					_enter(Mode.SWIPE)
			Mode.SWIPE:
				if elapsed >= .06 and not struck:
					struck = true
					_strike()
				if elapsed >= SWIPE:
					_enter(Mode.APPROACH)
	velocity.x = move_toward(velocity.x, speed, delta * 9.0)
	if mode != Mode.DOWN or not is_on_floor():
		move_and_slide()
	position.z = 0.0
	if mode == Mode.DOWN and is_on_floor() and not death_tween:
		_start_death()
	_animate(delta)

func _sees_miko() -> bool:
	if actor.health <= 0 or absf(actor.position.x-position.x) > SIGHT_RANGE or absf(actor.position.y-position.y) > 1.5:
		return false
	var query := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP, actor.global_position+Vector3.UP, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _strike() -> void:
	var offset := actor.global_position-global_position
	if offset.x*facing < 0 or absf(offset.x) > 2.0 or absf(offset.y) > 1.1:
		return
	var query := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP, actor.global_position+Vector3.UP, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return
	if actor.receive_attack(global_position.x):
		stagger = .75
		hitstop = .075
		_enter(Mode.APPROACH)

func _animate(delta: float) -> void:
	if not animation:
		return
	var clip := "Idle"
	if mode == Mode.DOWN:
		clip = "Death"
	elif mode in [Mode.WINDUP, Mode.SWIPE]:
		clip = "Slash"
	elif mode == Mode.APPROACH:
		clip = "Walk" if absf(velocity.x) > .05 else "Guard"
	elif absf(velocity.x) > .05:
		clip = "Walk"
	if clip != current_clip:
		animation.play(clip_names[clip], .16)
		current_clip = clip
		animation.get_animation(clip_names[clip]).loop_mode = Animation.LOOP_LINEAR if clip in ["Idle","Walk"] else Animation.LOOP_NONE
	animation.advance(delta)
	if clip == "Guard":
		animation.seek(.22, true)
	elif mode == Mode.WINDUP:
		animation.seek(lerpf(0.0, .20, clampf(elapsed/WINDUP,0,1)), true)
	elif mode == Mode.SWIPE:
		animation.seek(lerpf(.20,.43,clampf(elapsed/SWIPE,0,1)), true)
	if mode == Mode.APPROACH:
		for bone in guard_rotations:
			skeleton.set_bone_pose_rotation(bone, guard_rotations[bone])
	if mode != Mode.DOWN:
		droid.rotation.y = rotate_toward(droid.rotation.y, facing*PI*.5, delta*8.0)
	for material in droid_materials:
		material.set_shader_parameter("droid_warning", .7 * sin(PI*clampf((elapsed-.65)/.30,0,1)) if mode == Mode.WINDUP else 0.0)

func receive_hit(amount: int, direction: int, lift: float) -> void:
	if mode == Mode.DOWN:
		return
	super.receive_hit(amount,direction,lift)
	health = maxi(0,health-amount)
	_enter(Mode.APPROACH if health > 0 else Mode.DOWN)
	if health == 0:
		collision_layer = 0
		velocity.x = direction * .6

func _start_death() -> void:
	death_tween = create_tween()
	death_tween.tween_interval(5.0)
	death_tween.tween_method(_set_dissolve,0.0,1.0,.9)
	death_tween.tween_callback(hide)

func _set_dissolve(value: float) -> void:
	for material in droid_materials:
		material.set_shader_parameter("dissolve", value)
	if sword:
		sword.visible = value < .6

