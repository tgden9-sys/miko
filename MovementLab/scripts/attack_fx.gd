extends Node3D

var age := 0.0
var duration := 0.090
var slam := false
var direction := 1
var variant := 0
var floor_height := 0.0

var crescent_mesh: ImmediateMesh
var crescent_instance: MeshInstance3D
var crescent_mat: ShaderMaterial

# Crescent geometry definition
var start_angle := 0.0
var end_angle := 0.0
var r_max := 1.35
var width_max := 0.38
var crescent_color := Color("38ffca") # Vibrant Cel Mint

# Ground slam display
var display_slam: MeshInstance3D
var slam_material: ShaderMaterial

func _ready() -> void:
	if slam:
		duration = 0.72
		display_slam = MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(8.0, 3.0)
		display_slam.mesh = quad
		display_slam.position = Vector3(0.0, 1.0, 0.18)
		slam_material = ShaderMaterial.new()
		slam_material.shader = preload("res://shaders/ground_impact.gdshader")
		display_slam.material_override = slam_material
		display_slam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(display_slam)
		return

	# Calibrated variant parameters for Clean Vector Crescent (Direction 1)
	match variant:
		0: # SwordA / AirA: chest-height horizontal slice
			duration = 0.085
			start_angle = deg_to_rad(26.0)
			end_angle = deg_to_rad(-18.0)
			r_max = 1.35
			width_max = 0.38
			crescent_color = Color("38ffca")
		1: # SwordB / AirCombo: rising diagonal slash across torso & head
			duration = 0.090
			start_angle = deg_to_rad(-22.0)
			end_angle = deg_to_rad(38.0)
			r_max = 1.40
			width_max = 0.40
			crescent_color = Color("38ffca")
		2: # SwordC: heavy combo finisher (massive high-impact cleave)
			duration = 0.110
			start_angle = deg_to_rad(52.0)
			end_angle = deg_to_rad(-32.0)
			r_max = 1.65
			width_max = 0.52
			crescent_color = Color("ffd030") # Royal Amber-Gold
		3: # Launcher (Uppercut): vertical ground-to-sky rise
			duration = 0.095
			start_angle = deg_to_rad(-25.0)
			end_angle = deg_to_rad(80.0)
			r_max = 1.50
			width_max = 0.44
			crescent_color = Color("38ffca")

	crescent_mesh = ImmediateMesh.new()
	crescent_instance = MeshInstance3D.new()
	crescent_instance.mesh = crescent_mesh
	crescent_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	crescent_mat = ShaderMaterial.new()
	crescent_mat.shader = preload("res://shaders/blade_trail.gdshader")
	crescent_instance.material_override = crescent_mat
	add_child(crescent_instance)
	
	_draw_crescent()

func _process(delta: float) -> void:
	age += delta
	if slam:
		if age >= duration:
			queue_free()
			return
		if slam_material:
			slam_material.set_shader_parameter("age", age)
		return

	if age >= duration:
		queue_free()
		return
	_draw_crescent()

func _draw_crescent() -> void:
	if not crescent_mesh:
		return
	crescent_mesh.clear_surfaces()
	var t := clampf(age / duration, 0.0, 1.0)
	
	# Kinetic Snap:
	# Leading cutting edge sweeps out to full arc in the first 35% of duration
	var head_p := 1.0 - pow(1.0 - clampf(t / 0.35, 0.0, 1.0), 3.0)
	var head_ang := lerpf(start_angle, end_angle, head_p)
	
	# Trailing edge follows, snapping forward from t=0.20 to t=1.0
	var tail_p := pow(clampf((t - 0.20) / 0.80, 0.0, 1.0), 2.0)
	var tail_ang := lerpf(start_angle, end_angle, tail_p)
	
	var span := head_ang - tail_ang
	if absf(span) < deg_to_rad(1.5):
		return
	
	var steps := 32
	# Solid vibrant cel opacity during strike, fast clean dissolve at the end
	var alpha := 1.0 if t < 0.65 else clampf((1.0 - t) / 0.35, 0.0, 1.0)
	var col := Color(crescent_color.r, crescent_color.g, crescent_color.b, alpha)
	
	crescent_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(steps + 1):
		var s := float(i) / float(steps) # 0.0 at tail, 1.0 at cutting head
		var theta := tail_ang + span * s
		
		# Outer cutting edge is pinned to the smooth circle carved by the blade tip
		# Inner edge tapers smoothly, leaving clean negative space inside
		var env := pow(sin(s * PI), 0.65)
		var cur_out := r_max
		var cur_in := r_max - width_max * env
		
		var cos_t := cos(theta)
		var sin_t := sin(theta)
		
		var pin := Vector3(cos_t * cur_in * float(direction), sin_t * cur_in, 0.0)
		var pout := Vector3(cos_t * cur_out * float(direction), sin_t * cur_out, 0.0)
		
		crescent_mesh.surface_set_color(col)
		crescent_mesh.surface_set_uv(Vector2(s, 0.0))
		crescent_mesh.surface_add_vertex(pin)
		
		crescent_mesh.surface_set_color(col)
		crescent_mesh.surface_set_uv(Vector2(s, 1.0))
		crescent_mesh.surface_add_vertex(pout)
	
	crescent_mesh.surface_end()
