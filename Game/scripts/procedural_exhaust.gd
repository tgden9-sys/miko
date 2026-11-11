extends Node2D

# The nozzle landmarks are projected from the saved Blender geometry for every
# exported pose. The effect follows the displayed body, including blue aiming.
var anchors: Dictionary = {}
var plume: ColorRect
var plume_material: ShaderMaterial
var output: float = 0.12
var elapsed: float = 0.0
var nozzle_width: float = 0.0
var anchor_key: String = ""
var engine_light: PointLight2D
var player: CharacterBody2D
var powered: bool = true

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	anchors = JSON.parse_string(FileAccess.get_file_as_string("res://sprites/nozzle_anchors_v29.json"))
	engine_light = player.get_node_or_null("ThrusterLight")
	z_index = 1
	plume = ColorRect.new()
	plume.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plume_material = ShaderMaterial.new()
	plume_material.shader = preload("res://shaders/procedural_exhaust.gdshader")
	plume_material.set_shader_parameter("style", 2)
	plume.material = plume_material
	add_child(plume)
	_update_nozzle()

func _update_nozzle() -> void:
	var art: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	var body: AnimatedSprite2D = player.get_node("BodyLayer")
	if body.visible:
		art = body
	var tex: Texture2D = art.sprite_frames.get_frame_texture(art.animation, art.frame)
	anchor_key = tex.resource_path.trim_prefix("res://")
	if not anchors.has(anchor_key):
		visible = false
		return
	visible = true
	var landmark: Dictionary = anchors[anchor_key]
	var centre := Vector2(float(landmark.centre[0]), float(landmark.centre[1]))
	position = art.position + centre * art.scale
	rotation = float(landmark.angle)
	nozzle_width = float(landmark.width) * absf(art.scale.x)
	# The shader's source covers 20.5% of its canvas width, filling the port.
	var canvas_width: float = nozzle_width / 0.205
	plume.size = Vector2(canvas_width, nozzle_width * 4.1 * absf(art.scale.y / art.scale.x))
	plume.position = Vector2(-canvas_width * 0.5, -1.0)
	if engine_light != null:
		engine_light.position = position + Vector2(0, 4).rotated(rotation)

func _physics_process(_delta: float) -> void:
	if plume == null:
		return
	var axis := Vector2.DOWN.rotated(rotation)
	var query := PhysicsRayQueryParameters2D.create(global_position + axis * 2.0, global_position + axis * plume.size.y, 1)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	var clearance: float = 1.0
	if not hit.is_empty():
		clearance = clampf(global_position.distance_to(hit.position) / maxf(1.0, plume.size.y), 0.01, 1.0)
	plume_material.set_shader_parameter("clearance", clearance)

func _process(delta: float) -> void:
	if not powered:
		visible = false
		output = 0.0
		if engine_light != null:
			engine_light.enabled = false
		return
	if engine_light != null:
		engine_light.enabled = true
	_update_nozzle()
	elapsed += delta
	var target: float = 0.12
	var ladder_state: int = player.get("ladder_state")
	if player.get("latched_fixture") != null:
		target = 0.025
	elif ladder_state != 0:
		if player.velocity.y < -1.0:
			# Short extra engine pushes above a continuous climbing burn.
			var burst: float = pow(maxf(0.0, sin(elapsed * TAU * 1.4)), 4.0)
			target = 0.70 + 0.30 * burst
		else:
			target = 0.18
	elif player.velocity.y < -30.0:
		target = lerpf(0.65, 1.0, clampf(-player.velocity.y / 520.0, 0.0, 1.0))
	elif player.get("dash_left") > 0.0:
		target = 0.75
	elif absf(player.velocity.x) > 10.0:
		target = 0.28
	output = lerpf(output, target, 1.0 - exp(-delta * 12.0))
	plume_material.set_shader_parameter("flow_time", elapsed)
	plume_material.set_shader_parameter("thrust", output)
	plume_material.set_shader_parameter("wind", -player.velocity.x / 340.0 * 0.18)
	plume_material.set_shader_parameter("suit_polarity", int(player.suit_polarity) if player.polarity_enabled else 0)
	if engine_light != null:
		match int(player.suit_polarity) if player.polarity_enabled else 0:
			1: engine_light.color = Color(1.0, 0.18, 0.26)
			2: engine_light.color = Color(0.16, 0.67, 1.0)
			_: engine_light.color = Color(0.32, 0.70, 1.0)
		engine_light.energy = 0.30 + output * 1.25
		engine_light.texture_scale = 0.40 + output * 0.35
