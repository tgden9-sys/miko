extends "res://scripts/miko8_charge_box.gd"
## Kinetic Bowling Crate:
## When charged (polarity != 0), blasting or shooting this crate launches it
## forward at high velocity (~18 m/s) as a kinetic projectile that bowls through guards!

const BOWLING_SPEED := 18.5
const MIN_CRUSH_SPEED := 4.5
var bowling_active := false
var bowling_heading := 1.0
var crushed_targets: Array[Node] = []

func _ready() -> void:
	super._ready()
	add_to_group("miko8_kinetic_crates")
	contact_monitor = true
	max_contacts_reported = 4

func reset_charge_body() -> void:
	bowling_active = false
	crushed_targets.clear()
	super.reset_charge_body()

func receive_blaster(_power: int, _hit_point: Vector3, dir: Vector3) -> void:
	if polarity == 0:
		lock_in_color(Color("ff434e"))
	_launch_bowling(dir)

func receive_plasma(_power: int, _hit_point: Vector3, dir: Vector3) -> void:
	if polarity == 0:
		lock_in_color(Color("ff434e"))
	_launch_bowling(dir)

func charge_at(color: Color, world_point: Vector3) -> void:
	var prev_polarity := polarity
	super.charge_at(color, world_point)
	if prev_polarity != 0:
		var actor: Node = _get_suit_actor()
		var heading := 1.0
		if is_instance_valid(actor) and "facing" in actor:
			heading = float(actor.facing)
		elif is_instance_valid(actor):
			heading = 1.0 if global_position.x > actor.global_position.x else -1.0
		_launch_bowling(Vector3(heading, 0, 0))

func _launch_bowling(dir: Vector3) -> void:
	bowling_heading = signf(dir.x) if absf(dir.x) > 0.05 else 1.0
	bowling_active = true
	crushed_targets.clear()
	sleeping = false
	freeze = false
	linear_velocity = Vector3(bowling_heading * BOWLING_SPEED, 0.8, 0)
	var spark = preload("res://scripts/miko8_crate_charge_spark.gd").new()
	spark.tint = Color("ff5a36") if polarity == 1 else Color("4fa5ff")
	add_child(spark)
	spark.position = Vector3(-bowling_heading * 0.4, 0.4, 0)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not bowling_active:
		return
	var current_speed := absf(linear_velocity.x)
	if current_speed < MIN_CRUSH_SPEED:
		bowling_active = false
		crushed_targets.clear()
		return
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, crate_size.y * 0.5, 0),
		global_position + Vector3(bowling_heading * (crate_size.x * 0.6 + 0.65), crate_size.y * 0.5, 0),
		4,
		[get_rid()]
	)
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var collider = hit.collider
		if is_instance_valid(collider) and not crushed_targets.has(collider):
			crushed_targets.append(collider)
			if collider.has_method("receive_kinetic_crush"):
				collider.receive_kinetic_crush(self)
			elif collider.has_method("receive_combat_bolt"):
				for i in range(4):
					collider.receive_combat_bolt()
			var actor: Node = _get_suit_actor()
			if is_instance_valid(actor) and "abilities" in actor:
				actor.abilities.projectile_pool.spawn_impact(hit.position, Color("ff9922"))
			linear_velocity.x *= 0.82
