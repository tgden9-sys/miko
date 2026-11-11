extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures.append(label)
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func ticks(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	var level: Node3D = load("res://scenes/miko7_patrol_yard.tscn").instantiate()
	root.add_child(level)
	await ticks(15)
	var actor: CharacterBody3D = level.actor
	var guard: CharacterBody3D = level.get_node("GateWarden")
	var combat: Node = actor.abilities.combat
	for enemy in get_nodes_in_group("level4_wardens"): enemy.set_physics_process(false)
	actor.reset_actor()
	actor.position = Vector3(17.7, .02, 0)
	guard.position = Vector3(18.5, 0, 0)
	guard.recovery_time = 100.0
	guard.shots_left = 0
	guard.retreat_cooldown = 100.0
	guard.set_physics_process(true)
	Input.action_press("miko8_right")
	await ticks(90)
	Input.action_release("miko8_right")
	check(absf(guard.position.x - 18.5) < .04, "Running contact does not slide warden")
	check(actor.position.x < guard.position.x - .5, "Warden blocks Miko")
	guard.set_physics_process(false)
	actor.position = Vector3(17.25, .02, 0)
	actor.facing = 1
	await ticks(5)
	Input.action_press("miko8_spell_double")
	await ticks(2)
	check(combat.guarding, "R2 raises shield")
	var health_before: int = actor.health
	actor.abilities.projectile_pool.spawn_bolt(guard, actor.global_position + Vector3(1.5, 1, 0), Vector3(-9.8, 0, 0), "Warden", 1)
	await ticks(12)
	check(actor.health == health_before and combat.energy < 80.0, "Live warden projectile is absorbed by shield")
	check(combat.block_bolt(Vector3.LEFT), "Front blaster blocked")
	check(not combat.block_bolt(Vector3.RIGHT), "Rear blaster bypasses shield")
	for i in range(4): combat.block_bolt(Vector3.LEFT)
	check(combat.broken > 0.0 and not combat.guarding, "Shield exhausts and breaks")
	Input.action_release("miko8_spell_double")
	await ticks(100)
	check(combat.energy > 20.0 and combat.broken <= 0.0, "Shield recovers")
	var shots: int = actor.abilities.shots_fired
	Input.action_press("miko8_quick_blaster")
	await ticks(85)
	Input.action_release("miko8_quick_blaster")
	check(guard.health == 0, "Three-hit sword combo defeats 150 HP warden")
	await ticks(2)
	check(level.tutorial_course.locks[0].open, "Defeating first warden releases gate")
	check(actor.abilities.shots_fired == shots, "Sword input emits no green bolts")
	while combat.lit > .03: await physics_frame
	check(actor.current_clip == "Idle" and combat.pose_weight == 0.0, "Combat recovery returns to standard idle with blade still visible")
	var saw_retraction := false
	for i in range(25):
		await physics_frame
		if combat.blade_extension > .1 and combat.blade_extension < .9: saw_retraction = true
	check(saw_retraction and not combat.blade.visible and combat.sword.visible, "Blade retracts and leaves hilt visible")
	guard.reset_patrol()
	guard.set_physics_process(false)
	actor.reset_actor()
	actor.position = Vector3(17.25, .02, 0)
	actor.facing = 1
	await ticks(5)
	Input.action_press("miko8_jump")
	Input.action_press("miko8_quick_blaster")
	await ticks(16)
	check(actor.position.y > .15 and guard.health < 150, "Sword connects during jump")
	Input.action_release("miko8_jump")
	Input.action_release("miko8_quick_blaster")
	actor.reset_actor()
	check(not combat.guarding and combat.swing == -1 and combat.energy == 100, "Respawn resets combat")
	guard.reset_patrol()
	guard.set_physics_process(false)
	actor.position = Vector3(17.25, .02, 0)
	actor.facing = 1
	await ticks(5)
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.15, 3, 2)
	collider.shape = box
	wall.add_child(collider)
	level.add_child(wall)
	wall.position = Vector3(17.9, 1.5, 0)
	await ticks(2)
	Input.action_press("miko8_quick_blaster")
	await ticks(30)
	Input.action_release("miko8_quick_blaster")
	check(guard.health == 150, "Solid cover stops sword damage")
	wall.queue_free()
	actor.reset_actor()
	key(KEY_P, true)
	await ticks(35)
	key(KEY_P, false)
	await ticks(25)
	check(actor.abilities.shots_fired > shots, "Remapped plasma still fires for cargo puzzles")
	print("COMBAT_RESULT ", failures)
	quit(0 if failures.is_empty() else 1)

