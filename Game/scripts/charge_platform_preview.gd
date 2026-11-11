extends Node2D

const CITY: PackedScene = preload("res://scenes/industrial_city.tscn")

var robot: CharacterBody2D
var fixture: Area2D
var camera: Camera2D
var label: Label
var phase := 0
var phase_time := 0.0

func _ready() -> void:
	var city := CITY.instantiate() as Node2D
	add_child(city)
	robot = city.get_node("Robot") as CharacterBody2D
	fixture = city.get_node("MagneticDrainFixture") as Area2D
	camera = city.get_node("Camera2D") as Camera2D
	camera.target = null
	camera.zoom = Vector2(1.7, 1.7)
	camera.global_position = Vector2(750, 760)
	camera.limit_left = -10000
	camera.limit_right = 10000
	camera.limit_top = -10000
	camera.limit_bottom = 10000
	city.get_node("ParallaxForeground").visible = false
	for crate in city.get_node("Crates").get_children():
		crate.neutralize()
	var layer := CanvasLayer.new()
	add_child(layer)
	label = Label.new()
	label.position = Vector2(38, 30)
	label.add_theme_font_size_override("font_size", 25)
	label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.01, 0.02, 0.05))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)
	_reset_cycle()

func _reset_cycle() -> void:
	phase = 0
	phase_time = 0.0
	fixture.polarity = 1
	fixture._update_appearance()
	robot.global_position = Vector2(750, 725)
	robot.velocity = Vector2.ZERO
	robot.fixture_launch_lockout = 0.0
	robot.fixture_launch_animation_time = 0.0
	robot.pending_fixture_launch = false
	robot.latched_fixture = null
	robot.set_suit_polarity(2)
	robot.sprite.play(&"jump")
	camera.global_position = Vector2(750, 760)
	label.text = "BLUE SUIT → RED PLATFORM   ·   magnetic pull"

func _physics_process(delta: float) -> void:
	phase_time += delta
	match phase:
		0:
			if robot.latched_fixture == fixture and robot.is_on_floor() and robot.sprite.animation == &"charge_attach" and robot.sprite.frame >= 13:
				phase = 1
				phase_time = 0.0
				label.text = "ATTACHED   ·   hands on platform"
		1:
			if phase_time >= 0.8:
				robot.set_suit_polarity(1)
				phase = 2
				phase_time = 0.0
				label.text = "RED SUIT → RED PLATFORM   ·   launch"
		2:
			camera.global_position.y = lerpf(camera.global_position.y, robot.global_position.y - 40.0, 0.075)
			if phase_time >= 1.25:
				phase = 3
				phase_time = 0.0
		3:
			if phase_time >= 0.5:
				_reset_cycle()
