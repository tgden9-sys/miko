extends Area2D

var direction := Vector2.DOWN
var speed := 700.0
var age := 0.0
var impact_time := -1.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	queue_redraw()

func _draw() -> void:
	if impact_time >= 0.0:
		var fade: float = 1.0 - impact_time / 0.13
		draw_arc(Vector2.ZERO, 4.0 + impact_time * 100.0, 0.0, TAU, 18, Color(1.0, 0.14, 0.07, fade), 2.2)
		return
	# Fast, sharp crimson energy dart with a bright hot core and a tapered tail.
	draw_colored_polygon(PackedVector2Array([Vector2(-27, 0), Vector2(-7, -5), Vector2(9, -4), Vector2(16, 0), Vector2(9, 4), Vector2(-7, 5)]), Color(0.85, 0.025, 0.02, 0.30))
	draw_colored_polygon(PackedVector2Array([Vector2(-21, 0), Vector2(-4, -2.5), Vector2(10, -2.2), Vector2(15, 0), Vector2(10, 2.2), Vector2(-4, 2.5)]), Color(1.0, 0.11, 0.055, 0.93))
	draw_line(Vector2(-12, 0), Vector2(11, 0), Color(1.8, 0.82, 0.55, 1.0), 1.8, true)

func _physics_process(delta: float) -> void:
	if impact_time >= 0.0:
		impact_time += delta
		queue_redraw()
		if impact_time >= 0.13:
			queue_free()
		return
	var travel := direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + travel, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_impact(hit.get("collider"))
		return
	position += travel
	age += delta
	if age > 2.2:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	_impact(body)

func _impact(body: Object) -> void:
	if impact_time >= 0.0:
		return
	if body != null and body.has_method("take_damage"):
		body.take_damage(direction * 210.0 + Vector2.UP * 120.0)
	impact_time = 0.0
	$CollisionShape2D.set_deferred("disabled", true)
	queue_redraw()
