extends Area2D

@onready var light: PointLight2D = get_node_or_null("PlasmaLight")
@onready var trail: CPUParticles2D = get_node_or_null("PlasmaTrail")
@onready var sparks: CPUParticles2D = get_node_or_null("ImpactSparks")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var shooter: Node2D = null
var direction: Vector2 = Vector2.RIGHT
var speed: float = 1100.0
var velocity: Vector2 = Vector2.ZERO
var life: float = 1.8
var pulse: float = 0.0
var detonated: bool = false
var detonate_time: float = 0.0
var shockwave_radius: float = 8.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if velocity == Vector2.ZERO:
		velocity = direction * speed
	else:
		speed = velocity.length()
		direction = velocity.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if detonated:
		detonate_time += delta
		shockwave_radius += 180.0 * delta
		if light != null:
			light.energy = maxf(0.0, 3.2 * (1.0 - detonate_time / 0.32))
			light.texture_scale = 1.6 + detonate_time * 2.0
		queue_redraw()
		if detonate_time >= 0.35:
			queue_free()
		return

	position += velocity * delta
	life -= delta
	pulse += delta * 18.0
	rotation = velocity.angle()
	
	if light != null:
		light.energy = 2.4 + sin(pulse * 1.5) * 0.4

	queue_redraw()
	if life <= 0.0:
		_detonate()

func _draw() -> void:
	if detonated:
		var alpha: float = clampf(1.0 - detonate_time / 0.32, 0.0, 1.0)
		var shock_col: Color = Color(1.0, 0.65, 1.0, alpha * 0.85)
		draw_arc(Vector2.ZERO, shockwave_radius, 0.0, TAU, 36, shock_col, 3.5)
		draw_circle(Vector2.ZERO, maxf(0.0, 24.0 * (1.0 - detonate_time / 0.2)), Color(1.5, 1.0, 2.0, alpha * 0.7))
		return

	var r: float = 11.0 + 1.2 * sin(pulse)
	
	# Trailing elongated plasma plume
	var tail_pts = PackedVector2Array([
		Vector2(r * 1.2, 0),
		Vector2(0, -r * 0.85),
		Vector2(-r * 3.2, 0),
		Vector2(0, r * 0.85)
	])
	draw_colored_polygon(tail_pts, Color(0.65, 0.20, 1.0, 0.45))
	
	# Outer electric violet aura
	draw_circle(Vector2.ZERO, r * 2.0, Color(0.55, 0.18, 1.0, 0.25))
	draw_circle(Vector2.ZERO, r * 1.4, Color(0.72, 0.32, 1.0, 0.6))
	
	# Inner searing core (HDR bloom values)
	draw_circle(Vector2.ZERO, r * 0.85, Color(1.2, 0.7, 1.4, 0.95))
	draw_circle(Vector2(r * 0.2, 0), r * 0.45, Color(2.4, 2.1, 2.8, 1.0))

func _detonate() -> void:
	if detonated:
		return
	detonated = true
	velocity = Vector2.ZERO
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if trail != null:
		trail.emitting = false
	if sparks != null:
		sparks.restart()
		sparks.emitting = true
	if light != null:
		light.energy = 3.6

func _on_body_entered(body: Node2D) -> void:
	if detonated or body == shooter:
		return
	if body.is_in_group("crates") and body is CharacterBody2D:
		if body.has_method("neutralize"):
			body.neutralize()
		var push_dir: Vector2 = direction if direction != Vector2.ZERO else Vector2.RIGHT
		body.velocity += push_dir * 540.0 + Vector2.UP * 220.0
	_detonate()
