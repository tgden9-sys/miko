extends Node
## High-performance, zero-allocation pre-warmed object pool for Miko's projectiles and impact VFX.
## Eliminates runtime instantiate() and queue_free() GC pressure during blaster firing.

const BOLT_CAPACITY: int = 16
const IMPACT_CAPACITY: int = 16
const PROJECTILE_SCRIPT := preload("res://scripts/miko8_spell_projectile.gd")
const IMPACT_SCRIPT := preload("res://scripts/miko8_energy_impact.gd")

var bolt_pool: Array[Node3D] = []
var active_bolts: Array[Node3D] = []
var impact_pool: Array[Node3D] = []
var active_impacts: Array[Node3D] = []

func _ready() -> void:
	name = "MikoProjectilePool"
	add_to_group("miko8_projectile_pool")
	_prewarm_all()

func _prewarm_all() -> void:
	# Prewarm projectiles
	for i in range(BOLT_CAPACITY):
		var bolt: Node3D = PROJECTILE_SCRIPT.new()
		bolt.name = "PooledBolt_%d" % i
		bolt.set_meta("pooled", true)
		bolt.set_meta("pool_ref", self)
		bolt.visible = false
		bolt.set_physics_process(false)
		bolt.position = Vector3(0.0, -100.0, 0.0)
		add_child(bolt)
		bolt_pool.append(bolt)

	# Prewarm impact effects
	for i in range(IMPACT_CAPACITY):
		var imp: Node3D = IMPACT_SCRIPT.new()
		imp.name = "PooledImpact_%d" % i
		imp.set_meta("pooled", true)
		imp.set_meta("pool_ref", self)
		imp.visible = false
		imp.set_process(false)
		imp.position = Vector3(0.0, -100.0, 0.0)
		add_child(imp)
		impact_pool.append(imp)

func spawn_bolt(caster: CharacterBody3D, origin: Vector3, velocity: Vector3, mode: String, power: int) -> Node3D:
	var bolt: Node3D = null
	if bolt_pool.is_empty():
		bolt = PROJECTILE_SCRIPT.new()
		bolt.set_meta("pooled", true)
		bolt.set_meta("pool_ref", self)
		add_child(bolt)
	else:
		bolt = bolt_pool.pop_back()

	active_bolts.append(bolt)
	if bolt.has_method("configure_bolt"):
		bolt.configure_bolt(caster, origin, velocity, mode, power)
	else:
		bolt.caster = caster
		bolt.velocity = velocity
		bolt.mode = mode
		bolt.power = power
		bolt.age = 0.0
		bolt.history.clear()
		bolt.global_position = origin
		bolt.visible = true
		bolt.set_physics_process(true)
	return bolt

func recycle_bolt(bolt: Node3D) -> void:
	if not is_instance_valid(bolt):
		return
	bolt.visible = false
	bolt.set_physics_process(false)
	bolt.position = Vector3(0.0, -100.0, 0.0)
	bolt.history.clear()
	for t in bolt.trail:
		t.visible = false
	active_bolts.erase(bolt)
	if not bolt_pool.has(bolt):
		bolt_pool.append(bolt)

func spawn_impact(pos: Vector3, tint: Color) -> Node3D:
	var imp: Node3D = null
	if impact_pool.is_empty():
		imp = IMPACT_SCRIPT.new()
		imp.set_meta("pooled", true)
		imp.set_meta("pool_ref", self)
		add_child(imp)
	else:
		imp = impact_pool.pop_back()

	active_impacts.append(imp)
	if imp.has_method("configure_impact"):
		imp.configure_impact(pos, tint)
	else:
		imp.global_position = pos
		imp.tint = tint
		imp.elapsed = 0.0
		imp.visible = true
		imp.set_process(true)
	return imp

func recycle_impact(imp: Node3D) -> void:
	if not is_instance_valid(imp):
		return
	imp.visible = false
	imp.set_process(false)
	imp.position = Vector3(0.0, -100.0, 0.0)
	active_impacts.erase(imp)
	if not impact_pool.has(imp):
		impact_pool.append(imp)
