extends Node3D

const LIFE := .14
var fighter: CharacterBody3D
var edges: Array[Vector3] = []
var ages: Array[float] = []
var trail := ImmediateMesh.new()
var material := ShaderMaterial.new()

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	var ribbon := MeshInstance3D.new()
	ribbon.mesh = trail
	ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material.shader = preload("res://shaders/blade_trail.gdshader")
	material.set_shader_parameter("style_mode", 3)
	material.set_shader_parameter("effect_tint", Color(1.0, .25, .38))
	ribbon.material_override = material
	add_child(ribbon)
	process_priority = 25

func clear() -> void:
	edges.clear()
	ages.clear()
	trail.clear_surfaces()

func _process(delta: float) -> void:
	trail.clear_surfaces()
	for i in range(ages.size()):
		ages[i] += delta
	while not ages.is_empty() and ages[0] > LIFE:
		ages.pop_front()
		edges.pop_front()
		edges.pop_front()
	if fighter.mode == fighter.Mode.DOWN:
		clear()
		return
	material.set_shader_parameter("wall_left", fighter.actor.sword_wall_left)
	material.set_shader_parameter("wall_right", fighter.actor.sword_wall_right)
	if fighter.mode == fighter.Mode.SWIPE:
		var hand: int = fighter.skeleton.find_bone("DEF-hand.R")
		var transform: Transform3D = fighter.skeleton.global_transform * fighter.skeleton.get_bone_global_pose(hand) * fighter.sword.transform
		edges.append(transform * Vector3(.24, -.015, 0))
		edges.append(transform * Vector3(1.04, -.02, 0))
		ages.append(0.0)
	var count := ages.size()
	if count < 2:
		return
	trail.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for segment in range(count - 1):
		for step in range(6 if segment == count - 2 else 5):
			var fraction := float(step) / 5.0
			var alpha := clampf(1.0 - lerpf(ages[segment], ages[segment+1], fraction) / LIFE, 0, 1)
			var u := (segment + fraction) / float(count-1)
			for edge in range(2):
				var previous := edges[maxi(0, segment-1)*2+edge]
				var start := edges[segment*2+edge]
				var finish := edges[(segment+1)*2+edge]
				var next := edges[mini(count-1, segment+2)*2+edge]
				trail.surface_set_color(Color(1,1,1,alpha))
				trail.surface_set_uv(Vector2(u,float(edge)))
				trail.surface_add_vertex(start.cubic_interpolate(finish, previous, next, fraction))
	trail.surface_end()

