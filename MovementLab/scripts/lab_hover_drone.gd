extends StaticBody3D

const EYE := preload("res://props/hover_drone_eye.tscn")
const CONTACT := preload("res://shaders/lab_contact.gdshader")
const Bolt := preload("res://scripts/lab_turret_bolt.gd")
const PATROL_RADIUS := 3.9
const PATROL_PERIOD := 8.6
const EYE_SOCKET := Vector3(0,-.03,.704)
const DECK_HEIGHT := 6.0
const LEFT_LIMIT := 1.6
const RIGHT_LIMIT := 18.5
const PURSUIT_SPEED := 5.8
const SCAN_RANGE := 5.6
const SCAN_ANGLE := .34
const LOCK_TIME := .52
const COMMIT_TIME := .25
const BOLT_GAP := .22
const COOLDOWN_TIME := 2.5
const ACTIVE_SCAN := Color(1.0,.085,.15)
const RESTING_SCAN := Color(.80,.66,.65)
enum ScanPhase { SEARCH, LOCK, COMMIT, BURST, COOLDOWN, BROKEN }

var target: CharacterBody3D
var home: Vector3
var body: Node3D
var eye: Node3D
var shadow: MeshInstance3D
var shadow_paint: ShaderMaterial
var elapsed := 0.0
var scan: MeshInstance3D
var scan_paint: ShaderMaterial
var scan_phase := ScanPhase.SEARCH
var scan_timer := 0.0
var burst_aim := Vector3.ZERO
var projectiles: Node3D
var ray := PhysicsRayQueryParameters3D.new()
var pursuing := false
var horizontal_speed := 0.0
var hits := 0
var hitstop := 0.0
var hurtbox: CollisionShape3D
var hull_paint: ShaderMaterial
var burst: CPUParticles3D
var chips: CPUParticles3D
var flash: MeshInstance3D
var flash_paint: ShaderMaterial
var break_sound: AudioStreamPlayer3D
var crash: Tween

func _ready() -> void:
	home = position
	var asset := load("res://models/props/lab_hover_drone.glb") as PackedScene
	body = asset.instantiate() as Node3D
	body.scale = Vector3.ONE*.5
	add_child(body)
	var mesh: MeshInstance3D = body.find_children("*","MeshInstance3D",true,false)[0]
	var baked := mesh.get_active_material(0) as StandardMaterial3D
	var paint := ShaderMaterial.new()
	hull_paint = paint
	paint.shader = preload("res://shaders/miko8_three_tone.gdshader")
	paint.set_shader_parameter("base_texture",baked.albedo_texture)
	paint.set_shader_parameter("shadow_tone",Vector3(.67,.65,.63))
	paint.set_shader_parameter("middle_tone",Vector3(1.03,1.0,.94))
	paint.set_shader_parameter("light_tone",Vector3(1.33,1.26,1.15))
	paint.set_shader_parameter("transition_width",.09)
	mesh.set_surface_override_material(0,paint)
	eye = EYE.instantiate() as Node3D
	eye.position = EYE_SOCKET
	eye.scale = Vector3.ONE*1.24
	body.add_child(eye)
	shadow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(.9,.65)
	shadow.mesh = quad
	shadow_paint = ShaderMaterial.new()
	shadow_paint.shader = CONTACT
	shadow.material_override = shadow_paint
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.top_level = true
	shadow.rotation.x = -PI*.5
	add_child(shadow)
	_build_scan()
	_build_damage()
	projectiles = Node3D.new()
	projectiles.name = "PlasmaBolts"
	add_child(projectiles)
	reset()

func reset() -> void:
	for bolt: Node in projectiles.get_children():
		bolt.set_physics_process(false)
		bolt.queue_free()
	if crash and crash.is_running():
		crash.kill()
	hits = 0
	hitstop = 0
	pursuing = false
	horizontal_speed = 0
	elapsed = 0.0
	scan_phase = ScanPhase.SEARCH
	scan_timer = 0.0
	body.rotation = Vector3(0,-.65,0)
	body.show()
	shadow.show()
	burst.emitting = false
	chips.emitting = false
	flash.hide()
	break_sound.stop()
	hull_paint.set_shader_parameter("droid_warning",0.0)
	hurtbox.set_deferred("disabled",false)
	position = home+Vector3(PATROL_RADIUS,0,0)
	eye.rotation = Vector3.ZERO
	eye.show()
	_update_hover(0.0)
	scan.hide()

func _physics_process(delta: float) -> void:
	if scan_phase == ScanPhase.BROKEN:
		return
	hitstop = maxf(0,hitstop-delta)
	hull_paint.set_shader_parameter("droid_warning",hitstop*4.0)
	if pursuing and not _target_in_zone():
		pursuing = false
		_change_scan(ScanPhase.SEARCH)
	elapsed = fmod(elapsed+delta,PATROL_PERIOD)
	_update_hover(delta)
	_update_scan(delta)

func _update_hover(delta: float) -> void:
	var phase := elapsed*TAU/PATROL_PERIOD
	var height := .14*cos(phase*2.0)+.10*sin(phase*4.0)
	var goal_x := home.x+PATROL_RADIUS*cos(phase)
	var speed := 3.4
	if pursuing:
		goal_x = clampf(target.position.x,LEFT_LIMIT,RIGHT_LIMIT)
		speed = PURSUIT_SPEED
	var desired_speed := clampf((goal_x-position.x)*3.4,-speed,speed)
	horizontal_speed = move_toward(horizontal_speed,desired_speed,delta*18)
	position.x = clampf(position.x+horizontal_speed*delta,LEFT_LIMIT,RIGHT_LIMIT)
	position.y = home.y+height
	position.z = home.z+.095*sin(phase*2.0)
	var drift := clampf(horizontal_speed/3.4,-1,1)
	var yaw := .94*tanh(drift*4.0)
	var watch := Vector3.ZERO
	var tracking := false
	if _target_in_zone():
		watch = target.global_position+Vector3.UP*1.08-eye.global_position
		tracking = pursuing or watch.length_squared() < SCAN_RANGE*SCAN_RANGE
		if tracking:
			# Turn enough to keep the target in view while still banking with travel.
			var look_yaw := clampf(atan2(watch.x,watch.z),-1.14,1.14)
			yaw = lerpf(yaw,look_yaw,.70)
	var response := 1.0-exp(-delta*5.0)
	body.rotation.y = lerpf(body.rotation.y,yaw,response)
	body.rotation.z = lerpf(body.rotation.z,-drift*.18,response)
	body.rotation.x = lerpf(body.rotation.x,-.07+cos(phase*2.0)*.045,response)
	var aim := Vector2.ZERO
	if tracking:
		var local := body.global_basis.inverse()*watch
		aim.x = clampf(atan2(local.x,local.z),-.57,.57)
		# Keep at least a sliver of the tiny lens facing the gameplay camera.
		aim.x = clampf(aim.x,-1.18-body.rotation.y,1.18-body.rotation.y)
		aim.y = -clampf(atan2(local.y,Vector2(local.x,local.z).length()),-.68,.68)
	eye.rotation.y = lerpf(eye.rotation.y,aim.x,response)
	eye.rotation.x = lerpf(eye.rotation.x,aim.y,response)
	# Patrol stays above the continuous upper deck.
	shadow.global_position = Vector3(global_position.x,DECK_HEIGHT+.025,global_position.z)
	shadow_paint.set_shader_parameter("opacity",.17-height*.11)

func _target_in_zone() -> bool:
	return is_instance_valid(target) and target.health > 0 and target.position.y >= DECK_HEIGHT-.18 \
		and target.position.x >= LEFT_LIMIT and target.position.x <= RIGHT_LIMIT

func _build_scan() -> void:
	scan_paint = ShaderMaterial.new()
	scan_paint.shader = preload("res://shaders/lab_drone_scan.gdshader")
	scan_paint.set_shader_parameter("deck_height",DECK_HEIGHT)
	scan = MeshInstance3D.new()
	scan.mesh = QuadMesh.new()
	scan.material_override = scan_paint
	scan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scan.top_level = true
	add_child(scan)

func _update_scan(delta: float) -> void:
	var origin := eye.to_global(Vector3(0,0,.127))
	var direction := Vector3(.51*sin(elapsed*TAU/PATROL_PERIOD*2.0),-1,.11).normalized()
	var can_target := _target_in_zone()
	var chest := target.global_position+Vector3.UP*1.04 if can_target else Vector3.ZERO
	var aim := origin.direction_to(chest) if can_target else direction
	var in_range := can_target and origin.distance_squared_to(chest) < SCAN_RANGE*SCAN_RANGE
	scan_timer += delta
	match scan_phase:
		ScanPhase.SEARCH:
			_draw_scan(origin,origin+direction*SCAN_RANGE,SCAN_ANGLE,.18)
			if in_range and aim.dot(direction) >= cos(SCAN_ANGLE) and _trace(origin,chest,1).is_empty():
				pursuing = true
				_change_scan(ScanPhase.LOCK)
		ScanPhase.LOCK:
			if not in_range or not _trace(origin,chest,1).is_empty():
				scan.hide()
				scan_timer = 0
				return
			var progress := smoothstep(0.0,LOCK_TIME,scan_timer)
			_draw_scan(origin,chest+aim*.38,lerpf(SCAN_ANGLE,.047,progress),lerpf(.18,.36,progress))
			if scan_timer >= LOCK_TIME:
				_change_scan(ScanPhase.COMMIT)
		ScanPhase.COMMIT:
			if not in_range or not _trace(origin,chest,1).is_empty():
				scan.hide()
				_change_scan(ScanPhase.LOCK)
				return
			burst_aim = _lead_target(origin,chest)
			_draw_scan(origin,burst_aim,.047,.36+.05*sin(scan_timer*38.0))
			if scan_timer >= COMMIT_TIME:
				_fire_bolt(origin,burst_aim)
				_change_scan(ScanPhase.BURST)
		ScanPhase.BURST:
			if in_range and _trace(origin,chest,1).is_empty():
				burst_aim = _lead_target(origin,chest)
			_draw_scan(origin,burst_aim,.047,.15)
			if scan_timer >= BOLT_GAP:
				_fire_bolt(origin,burst_aim)
				_change_scan(ScanPhase.COOLDOWN)
				_draw_cooldown(origin,direction)
		ScanPhase.COOLDOWN:
			_draw_cooldown(origin,direction)
			if scan_timer >= COOLDOWN_TIME:
				_change_scan(ScanPhase.LOCK)

func _change_scan(next: ScanPhase) -> void:
	scan_phase = next
	scan_timer = 0.0

func _lead_target(origin: Vector3, chest: Vector3) -> Vector3:
	# Solve for the bolt reaching Miko's horizontal path at the same time as him.
	# Airborne motion is left out of the prediction so jumping remains a dodge.
	var travel := Vector3(target.velocity.x,0,0)
	var offset := chest-origin
	var closing := Bolt.SPEED*Bolt.SPEED-travel.length_squared()
	var along := offset.dot(travel)
	var time := offset.length()/Bolt.SPEED
	if closing > .01:
		time = (along+sqrt(along*along+closing*offset.length_squared()))/closing
	var ahead := chest+travel*clampf(time,0.0,.62)
	ahead.x = clampf(ahead.x,LEFT_LIMIT,RIGHT_LIMIT)
	return ahead

func _draw_cooldown(origin: Vector3, direction: Vector3) -> void:
	var open := smoothstep(0.0,.25,scan_timer)
	var rearm := smoothstep(COOLDOWN_TIME-.25,COOLDOWN_TIME,scan_timer)
	var end := burst_aim.lerp(origin+direction*SCAN_RANGE,open)
	_draw_scan(origin,end,lerpf(.047,SCAN_ANGLE,open),lerpf(.065,.18,rearm),RESTING_SCAN.lerp(ACTIVE_SCAN,rearm))

func _fire_bolt(origin: Vector3, aim: Vector3) -> void:
	var bolt := Bolt.new()
	bolt.top_level = true
	bolt.red_plasma = true
	projectiles.add_child(bolt)
	bolt.launch(origin,origin.direction_to(aim),global_position)

func _trace(origin: Vector3, end: Vector3, mask: int) -> Dictionary:
	ray.from = origin
	ray.to = end
	ray.collision_mask = mask
	return get_world_3d().direct_space_state.intersect_ray(ray)

func _draw_scan(origin: Vector3, end: Vector3, angle: float, opacity: float, tint := ACTIVE_SCAN) -> void:
	var axis := end-origin
	var span := axis.length()
	if span < .01:
		scan.hide()
		return
	var along := axis/span
	var transverse := Vector3.BACK.cross(along)
	var sideways := transverse.normalized() if transverse.length_squared() > .0001 else Vector3.RIGHT
	var width := maxf(.10,2.0*tan(angle)*span)
	var basis := Basis(along*span,sideways*width,along.cross(sideways))
	scan.global_transform = Transform3D(basis,(origin+end)*.5)
	scan_paint.set_shader_parameter("opacity",opacity)
	scan_paint.set_shader_parameter("tint",tint)
	scan.show()

func _build_damage() -> void:
	collision_layer = 4
	collision_mask = 0
	hurtbox = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(.92,.43,.94)
	hurtbox.shape = shape
	hurtbox.position.z = .14
	add_child(hurtbox)
	burst = _make_debris(24,Color("ffae73"),Vector3(.027,.075,.025),.46,5.1)
	chips = _make_debris(12,Color("566a6a"),Vector3(.075,.042,.055),.78,2.9)
	flash = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.65,1.65)
	flash.mesh = quad
	flash_paint = ShaderMaterial.new()
	flash_paint.shader = preload("res://shaders/lab_halo.gdshader")
	flash_paint.set_shader_parameter("light_color",Color("ffe3ac"))
	flash.material_override = flash_paint
	flash.top_level = true
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flash)
	break_sound = AudioStreamPlayer3D.new()
	break_sound.stream = AudioStreamWAV.load_from_file("res://audio/laser_clash.wav")
	break_sound.max_distance = 15
	break_sound.volume_db = -6
	break_sound.pitch_scale = .74
	add_child(break_sound)

func _make_debris(count: int, tint: Color, size: Vector3, duration: float, speed: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.top_level = true
	particles.emitting = false
	particles.one_shot = true
	particles.amount = count
	particles.lifetime = duration
	particles.explosiveness = 1
	particles.direction = Vector3.UP
	particles.spread = 180
	particles.gravity = Vector3.DOWN*10
	particles.initial_velocity_min = speed*.4
	particles.initial_velocity_max = speed
	var chip := BoxMesh.new()
	chip.size = size
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = tint
	chip.material = paint
	particles.mesh = chip
	add_child(particles)
	return particles

func get_hit_point() -> Vector3:
	return hurtbox.global_position

func receive_hit(_damage: int, direction: int, _lift: float) -> void:
	if scan_phase == ScanPhase.BROKEN:
		return
	hits += 1
	if hits == 1:
		hitstop = .07
		return
	pursuing = false
	_change_scan(ScanPhase.BROKEN)
	scan.hide()
	hurtbox.set_deferred("disabled",true)
	eye.hide()
	hull_paint.set_shader_parameter("droid_warning",.18)
	break_sound.play()
	_emit_burst(global_position)
	var wreck_x := clampf(position.x+direction*.85,LEFT_LIMIT,RIGHT_LIMIT)
	var landing := Vector3(wreck_x,DECK_HEIGHT+.16,position.z)
	crash = create_tween().set_parallel()
	crash.tween_property(self,"position",landing,.53).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	crash.tween_property(body,"rotation:z",body.rotation.z+direction*3.0,.53)
	crash.tween_method(_fade_flash,1.9,0.0,.25)
	crash.chain().tween_callback(_finish_crash)
	crash.chain().tween_method(_fade_flash,.8,0.0,.19)

func _emit_burst(at: Vector3) -> void:
	for particles: CPUParticles3D in [burst,chips]:
		particles.global_position = at
		particles.restart()
		particles.emitting = true
	flash.global_position = at

func _fade_flash(energy: float) -> void:
	flash.visible = energy > .02
	flash_paint.set_shader_parameter("energy",energy)

func _finish_crash() -> void:
	body.hide()
	shadow.hide()
	_emit_burst(global_position)
