extends Area2D

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null
var speed: float = 980.0
var age: float = 0.0
var impact_time: float = -1.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	queue_redraw()

func _draw() -> void:
	if impact_time >= 0.0:
		var fade: float = clampf(1.0 - impact_time / 0.14, 0.0, 1.0)
		draw_circle(Vector2.ZERO, 6.0 + impact_time * 35.0, Color(0.12, 1.0, 0.23, fade * 0.16))
		draw_arc(Vector2.ZERO, 2.0 + impact_time * 65.0, 0.0, TAU, 16, Color(0.45, 1.0, 0.35, fade), 1.6)
		for angle in [0.0, 1.25, 2.5, 3.75, 5.0]:
			var ray: Vector2 = Vector2.from_angle(angle)
			draw_line(ray * 3.0, ray * (6.0 + impact_time * 54.0), Color(0.65, 1.0, 0.45, fade), 1.0)
		return
	# A tiny high-speed flechette: crisp white-green nose and tapered luminous wake.
	# The hot core stays about a quarter of the large plasma bolt's diameter.
	draw_colored_polygon(PackedVector2Array([Vector2(-16, 0), Vector2(-4, -4), Vector2(5, -3), Vector2(10, 0), Vector2(5, 3), Vector2(-4, 4)]), Color(0.03, 0.95, 0.18, 0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 0), Vector2(-3, -2.4), Vector2(5, -2.2), Vector2(10, 0), Vector2(5, 2.2), Vector2(-3, 2.4)]), Color(0.09, 1.0, 0.22, 0.88))
	draw_line(Vector2(-9, 0), Vector2(7, 0), Color(0.78, 1.0, 0.68), 1.4, true)
	draw_circle(Vector2(4.0, 0), 2.5, Color(0.88, 1.4, 0.72))

func _physics_process(delta: float) -> void:
	if impact_time >= 0.0:
		impact_time += delta
		queue_redraw()
		if impact_time >= 0.14:
			queue_free()
		return
	var travel: Vector2 = direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + travel, 1)
	query.exclude = [shooter.get_rid()] if shooter is CollisionObject2D else []
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_impact(hit.get("collider"))
		return
	position += travel
	age += delta
	if age >= 1.1:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body != shooter:
		_impact(body)

func _impact(body: Object) -> void:
	if impact_time >= 0.0:
		return
	if body != null and body.has_method("take_damage"):
		body.take_damage(direction * 140.0)
	impact_time = 0.0
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("BoltWake"):
		$BoltWake.emitting = false
	queue_redraw()
