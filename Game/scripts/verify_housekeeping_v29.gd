extends SceneTree

var failures: Array[String] = []
var world: Node2D
var crate_scene: PackedScene = preload("res://scenes/crate.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _frames(n: int) -> void:
	for i in range(n):
		await physics_frame

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _reset_world() -> void:
	if is_instance_valid(world):
		world.queue_free()
		await _frames(2)
	world = Node2D.new()
	root.add_child(world)
	var floor_body := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10000, 40)
	collider.shape = shape
	floor_body.position = Vector2(1000, 520)
	floor_body.add_child(collider)
	world.add_child(floor_body)

func _crate(pos: Vector2, pole: int) -> CharacterBody2D:
	var c: CharacterBody2D = crate_scene.instantiate()
	c.position = pos
	c.set("polarity", pole)
	world.add_child(c)
	return c

func _run() -> void:
	# Reproduce the user's blue / red / blue corner stack in both directions,
	# with the opposing crate processed before AND after the repelling pair.
	for mirror in [-1.0, 1.0]:
		for reverse_order in [false, true]:
			await _reset_world()
			var blue_a: CharacterBody2D
			var blue_b: CharacterBody2D
			var red: CharacterBody2D
			if reverse_order:
				red = _crate(Vector2(1000, 482), 1)
			blue_a = _crate(Vector2(1000 - mirror * 75, 482), 2)
			blue_b = _crate(Vector2(1000, 444), 2)
			if not reverse_order:
				red = _crate(Vector2(1000, 482), 1)
			await _frames(600)
			var count: int = blue_a.get("repulsion_count") + blue_b.get("repulsion_count")
			var distance: float = blue_a.position.distance_to(blue_b.position)
			print("THREE_CRATES mirror=", mirror, " reverse=", reverse_order, " impulses=", count, " separation=", distance)
			_check(count == 2, "Three-crate loop repeated: " + str(count))
			_check(distance > 400.0, "Repelled pair did not escape field overlap")
	# Retain ordinary opposing attraction inside the overlapping fields.
	await _reset_world()
	var a := _crate(Vector2(600, 482), 1)
	var b := _crate(Vector2(950, 482), 2)
	await _frames(90)
	_check(a.position.distance_to(b.position) < 345.0, "Ordinary attraction stopped working")
	print("ATTRACTION separation=", a.position.distance_to(b.position))
	# A real moving projectile must discharge, not just the direct method.
	await _reset_world()
	a = _crate(Vector2(650, 482), 1)
	var bolt: Area2D = load("res://scenes/plasma_projectile.tscn").instantiate()
	bolt.position = Vector2(450, 482)
	bolt.set("direction", Vector2.RIGHT)
	world.add_child(bolt)
	await _frames(25)
	_check(a.get("polarity") == 0, "Plasma collision did not neutralize crate")
	_check(a.get_node("Sprite2D").texture == a.TEXTURE_NEUTRAL, "Neutral texture not restored")
	print("PLASMA neutral=", a.get("polarity") == 0)
	# Actual duration, refresh and recharging a discharged crate.
	a.lock_in_color(Color.BLUE)
	await _frames(600)
	_check(a.get("polarity") == 2, "Charge expired before 15 seconds")
	a.lock_in_color(Color.RED)
	await _frames(360)
	_check(a.get("polarity") == 1, "Refresh failed to restart lifetime")
	await _frames(550)
	_check(a.get("polarity") == 0, "Charge did not expire after refreshed 15 seconds")
	print("EXPIRY_AND_REFRESH checked")
	# Walls can prevent escape: charge must still reset instead of looping forever.
	await _reset_world()
	a = _crate(Vector2(1000, 482), 1)
	b = _crate(Vector2(1000, 444), 1)
	for wall_x in [920.0, 1080.0]:
		var wall := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(20, 400)
		collision.shape = shape
		wall.add_child(collision)
		wall.position = Vector2(wall_x, 300)
		world.add_child(wall)
	await _frames(910)
	_check(a.get("polarity") == 0 and b.get("polarity") == 0, "Repulsion refreshed charge indefinitely")
	print("HOUSEKEEPING_RESULT failures=", failures)
	quit(0 if failures.is_empty() else 1)
