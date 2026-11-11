extends CharacterBody3D
## An exposed rooftop sentry. Locks its aim before a single shot.
const DRONE := "res://models/enemies/security_drone/security_drone.glb"
const MAX_HEALTH := 75
const WIND_UP := .72
const RECOVERY := 1.55
var health := MAX_HEALTH
var anchor: Vector3
var player: CharacterBody3D
var model: Node3D
var hitbox: CollisionShape3D
var lamp: StandardMaterial3D
var elapsed := 0.0
var wind := 0.0
var cooldown := 0.0
var locked_target: Vector3
var shot_side := -1.0

func _ready() -> void:
	anchor = position
	add_to_group("miko8_budget_actor")
	set_meta("budget_activity_margin", 10.0)
	model = load(DRONE).instantiate()
	model.rotation.y = -PI * .38
	model.scale = Vector3.ONE * 1.28
	add_child(model)
	hitbox = CollisionShape3D.new()
	var volume := SphereShape3D.new()
	volume.radius = .48
	hitbox.shape = volume
	add_child(hitbox)
	var status := MeshInstance3D.new()
	var lens := SphereMesh.new()
	lens.radius = .072
	lens.height = .144
	status.mesh = lens
	status.position = Vector3(-.27, .02, .33)
	lamp = StandardMaterial3D.new()
	lamp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	status.material_override = lamp
	add_child(status)
	reset_patrol()

func set_camera_active(active: bool) -> void:
	set_physics_process(active and health > 0)
	visible = active and health > 0

func reset_patrol() -> void:
	position = anchor
	health = MAX_HEALTH
	elapsed = 0.0
	wind = 0.0
	cooldown = 0.0
	shot_side = -1.0
	model.rotation.y = shot_side * PI * .38
	lamp.albedo_color = Color("7cb8be")
	hitbox.set_deferred("disabled", false)
	show()
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): player = get_parent().actor
	if not player.ready_for_input or player.health <= 0 or get_parent().resetting: return
	elapsed += delta
	cooldown = maxf(0.0, cooldown - delta)
	model.rotation.y = lerp_angle(model.rotation.y, shot_side * PI * .38, 1.0 - exp(-9.0 * delta))
	if wind > 0.0:
		wind = maxf(0.0, wind - delta)
		lamp.albedo_color = Color("ff8637").lerp(Color("fff3c4"), 1.0 - wind / WIND_UP)
		if wind == 0.0:
			var origin := global_position + Vector3(shot_side * .34, -.04, 0)
			var pool: Node = player.abilities.projectile_pool
			pool.spawn_bolt(self, origin, origin.direction_to(locked_target) * 8.5, "Warden", 1)
			pool.spawn_impact(origin, Color("ffa138"))
			cooldown = RECOVERY
		return
	position = anchor + Vector3(sin(elapsed * .85) * .65, sin(elapsed * 2.6) * .14, 0)
	lamp.albedo_color = Color("7cb8be")
	if cooldown > 0.0 or player.position.x < 83.0 or player.position.y < 2.2: return
	if player.state.begins_with("Climb"): return
	var target := player.body_collision.global_position as Vector3
	if global_position.distance_squared_to(target) > 100.0: return
	var ray := PhysicsRayQueryParameters3D.create(global_position, target, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.collider == player:
		locked_target = target
		shot_side = -1.0 if target.x < global_position.x else 1.0
		wind = WIND_UP

func receive_combat_bolt() -> void:
	if health <= 0: return
	health = maxi(0, health - 25)
	if health > 0: return
	hitbox.set_deferred("disabled", true)
	if is_instance_valid(player):
		player.abilities.projectile_pool.spawn_impact(global_position, Color("ffa138"))
	hide()
	set_physics_process(false)
