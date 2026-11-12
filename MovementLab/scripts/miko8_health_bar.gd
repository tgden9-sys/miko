extends Node2D
## Screen-space suit readout anchored to the animated head.
var actor: CharacterBody3D
var hostile := false
var head_height := 1.60
var head_bone := -1
var displayed_health := 1.0
var displayed_polarity := -1
var hud_material: ShaderMaterial

func _ready() -> void:
	name = "WardenHealthBar" if hostile else "MikoHealthBar"
	process_priority = 20
	var skeleton := actor.get("skeleton") as Skeleton3D
	if skeleton:
		head_bone = skeleton.find_bone("DEF-head")
	hud_material = ShaderMaterial.new()
	hud_material.shader = preload("res://shaders/miko8_health_hud.gdshader")
	hud_material.set_shader_parameter("hostile", hostile)
	var panel := ColorRect.new()
	panel.name = "SuitReadout"
	panel.size = Vector2(48, 22) if hostile else Vector2(54, 24)
	panel.position = -panel.size * .5
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.material = hud_material
	add_child(panel)

func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera or not actor.is_visible_in_tree() or (hostile and actor.health <= 0) or (not hostile and actor.get("state") == "NetworkTransfer"):
		hide()
		return
	var head := actor.global_position + Vector3.UP * head_height
	if head_bone >= 0 and actor.get("skeleton"):
		head = actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(head_bone).origin)
	var anchor := head + Vector3.UP * .55
	position = camera.unproject_position(anchor)
	visible = not camera.is_position_behind(anchor)

	var max_hp: float = float(actor.MAX_HEALTH) if "MAX_HEALTH" in actor else 100.0
	var health := float(actor.health) / max_hp
	var fill := move_toward(displayed_health, health, delta * 2.8)
	var polarity: int = 0 if hostile else int(actor.get("suit_polarity"))
	if fill != displayed_health or polarity != displayed_polarity:
		displayed_health = fill
		displayed_polarity = polarity
		hud_material.set_shader_parameter("health", displayed_health)
		hud_material.set_shader_parameter("polarity", displayed_polarity)
