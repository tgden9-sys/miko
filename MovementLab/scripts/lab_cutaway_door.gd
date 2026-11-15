extends "res://scripts/lab_polarity_shield.gd"

const TUNNEL := preload("res://models/props/lab_tunnel_interior.glb")
const TUNNEL_PAINT := preload("res://shaders/lab_tunnel_finish.gdshader")
const MOUNT_PAINT := preload("res://shaders/lab_door_metal.gdshader")
const STEEL_MAP := preload("res://art/lab_bulkhead_steel.png")
var finishes: Array[ShaderMaterial] = []
var previous_field_power := -1.0
var metal_tint := Color.WHITE
var metal_shutter := false
var service_shutter: Node3D
var service_open := false

func _process(delta: float) -> void:
	super._process(delta)
	if not is_equal_approx(previous_field_power,field_strength):
		for material in finishes:
			material.set_shader_parameter("field_power",field_strength)
		for halo in field_halos:
			halo.set_shader_parameter("energy",field_strength*.16)
		previous_field_power = field_strength

func _physics_process(delta: float) -> void:
	if not sealed and is_instance_valid(actor) and not returning:
		var relative := actor.position-position
		relative.x *= passage_direction
		if relative.x > 0 and relative.x < APPROACH_DISTANCE and absf(relative.y) < .2 and actor.suit_polarity != 0 and actor.suit_polarity != pole:
			open_for_return()
	super._physics_process(delta)

func _build_partition(portal: Node3D,direction: float) -> void:
	portal.rotation.y = -PI*.5*direction
	# Align the near wall of the tunnel with the cutaway face at Z = .66.
	portal.position.z = -.83

func _build_return(_direction: float) -> void:
	# The shared shell builds the continuous cut face and its mitred perimeter.
	pass

func _build_passage(_direction: float) -> void:
	pass

func _build_ceiling_joint(_portal: Node3D,_direction: float) -> void:
	pass

func _build_frame(portal: Node3D) -> void:
	# The service bay exposes the side of this passage. Use a finished sleeve
	# there, since the shared tunnel mesh is trimmed to hide inside solid walls.
	if metal_shutter:
		_build_mount(portal)
		return
	var tunnel := TUNNEL.instantiate() as Node3D
	tunnel.scale.z = 1.12
	portal.add_child(tunnel)
	for mesh: MeshInstance3D in tunnel.find_children("*","MeshInstance3D",true,false):
		for index in range(mesh.mesh.get_surface_count()):
			var source := mesh.get_active_material(index) as StandardMaterial3D
			var paint := ShaderMaterial.new()
			paint.shader = TUNNEL_PAINT
			paint.set_shader_parameter("base_texture",source.albedo_texture)
			paint.set_shader_parameter("steel_map",STEEL_MAP)
			paint.set_shader_parameter("field_color",field_color())
			paint.set_shader_parameter("metal_tint",metal_tint)
			if arrival and not sealed:
				paint.set_shader_parameter("field_power",0.0)
			mesh.set_surface_override_material(index,paint)
			finishes.append(paint)
	_build_mount(portal)

func _contour(half: float, bottom: float, top: float, bevel: float, depth: float) -> PackedVector3Array:
	return PackedVector3Array([
		Vector3(-half+bevel,bottom,depth),Vector3(half-bevel,bottom,depth),
		Vector3(half,bottom+bevel,depth),Vector3(half,top-bevel,depth),
		Vector3(half-bevel,top,depth),Vector3(-half+bevel,top,depth),
		Vector3(-half,top-bevel,depth),Vector3(-half,bottom+bevel,depth)])

func _build_mount(portal: Node3D) -> void:
	# The mounting flange fits the shell's 2.5 m opening, behind its Z=.66 cut face.
	# Eight continuous rings give the mouth real bevels, a gasket and an inset throat.
	var material := ShaderMaterial.new()
	material.shader = MOUNT_PAINT
	material.set_shader_parameter("steel_map",STEEL_MAP)
	material.set_shader_parameter("field_color",field_color())
	material.set_shader_parameter("metal_tint",metal_tint)
	if metal_shutter or (arrival and not sealed):
		material.set_shader_parameter("field_power",0.0)
	finishes.append(material)
	var profiles := [
		_contour(1.47,0,2.50,.035,-.82),
		_contour(1.485,0,2.50,.035,.02),
		_contour(1.45,.01,2.45,.07,.09),
		_contour(1.30,.00,2.28,.18,.09),
		_contour(1.26,.015,2.24,.18,.055),
		_contour(1.22,.025,2.20,.18,.055),
		_contour(1.10,.025,2.07,.18,-.09),
		_contour(1.10,.025,2.07,.18,-.82)]
	var colors := [Color("263437"),Color("65726f"),Color("354449"),
		Color("111a1e"),Color("657873"),Color("42585d"),Color("17282e")]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	for band in range(profiles.size()-1):
		for edge in range(8):
			var next := (edge+1)%8
			var a: Vector3 = profiles[band][edge]
			var b: Vector3 = profiles[band][next]
			var c: Vector3 = profiles[band+1][next]
			var d: Vector3 = profiles[band+1][edge]
			for vertex: Vector3 in [a,c,b,a,d,c]:
				surface.set_color(colors[band])
				surface.set_smooth_group(-1)
				surface.add_vertex(vertex)
	surface.generate_normals()
	var mount := MeshInstance3D.new()
	mount.name = "FittedMount"
	mount.mesh = surface.commit()
	mount.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	portal.add_child(mount)
	var detail := Kit.new(portal,material)
	# End the visible passage in shadow. The player continues behind the cut wall.
	if not metal_shutter:
		detail.box(Vector3(0,1.15,-2.34),Vector3(2.6,2.32,.035),Color("07090a"))
	else:
		for side in [-1.0, 1.0]:
			detail.plate(Vector3(side * 1.30, 1.12, -.42), Vector3(.30, 2.23, .76), Color("303e41"))
			detail.box(Vector3(side * 1.462, 1.12, -.72), Vector3(.025, 2.21, .11), Color("566568"))
			for y in [.41, 1.08, 1.75]:
				detail.plate(Vector3(side * 1.458, y, -.36), Vector3(.025, .10, .38), Color("455355"))
		detail.plate(Vector3(0, 2.20, -.46), Vector3(2.64, .25, .82), Color("465253"))
	for side in [-1.0,1.0]:
		# Recessed electrode cartridges, held by a continuous machined channel.
		detail.box(Vector3(side*1.105,1.04,-.22),Vector3(.07,1.68,.12),Color("0c151a"))
		for y in [.42,1.04,1.66]:
			detail.plate(Vector3(side*1.16,y,.025),Vector3(.13,.14,.14),Color("394c50"))
		for y in [.19,2.13]:
			detail.cylinder(Vector3(side*1.40,y,.102),Vector3(.075,.026,.075),Color("151e22"),Vector3(PI*.5,0,0))
			detail.cylinder(Vector3(side*1.40,y,.118),Vector3(.036,.013,.036),Color("68746e"),Vector3(PI*.5,0,0))
	detail.plate(Vector3(0,2.335,.105),Vector3(.56,.10,.035),Color("121e24"))
	# Threshold is level with the deck; its bevel hides the reconstruction's ragged bottom.
	detail.box(Vector3(0,.013,-.24),Vector3(2.16,.026,.70),Color("354349"))
	detail.finish()
	if metal_shutter:
		_build_metal_shutter(portal,material)

func _build_metal_shutter(portal: Node3D, material: ShaderMaterial) -> void:
	# The shutter fills the throat behind the inner bevel at Z=-.09.
	service_shutter = Node3D.new()
	service_shutter.name = "ServiceShutter"
	portal.add_child(service_shutter)
	var metal := Kit.new(service_shutter, material)
	metal.box(Vector3(0, 1.045, -.36), Vector3(2.20, 2.05, .18), Color("2c3437"))
	for side: float in [-1.0, 1.0]:
		var x := side * .55
		metal.plate(Vector3(x, 1.07, -.235), Vector3(1.066, 1.94, .08), Color("555d5b"))
		metal.plate(Vector3(x, 1.57, -.188), Vector3(.82, .63, .036), Color("d6ab32"))
		metal.plate(Vector3(x, .53, -.188), Vector3(.82, .69, .036), Color("454f50"))
		metal.box(Vector3(x, .995, -.19), Vector3(.89, .133, .034), Color("353f43"))
		for y: float in [.24, .80, 1.34, 1.84]:
			metal.cylinder(Vector3(x + side * .34,y,-.162), Vector3(.063,.022,.063),
				Color("7a7b6d"),Vector3(PI*.5,0,0))
	metal.plate(Vector3(0, 1.04, -.155), Vector3(.26, .42, .043), Color("222b30"))
	metal.box(Vector3(0, 1.04, -.129), Vector3(.10, .040, .012), Color("b47839"), true)
	metal.finish()

func unlock_service_shutter(animated: bool) -> void:
	if service_open:
		return
	service_open = true
	if animated:
		var lift := create_tween()
		lift.tween_property(service_shutter, "position:y", 2.17, .72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		lift.tween_callback(func() -> void: barrier.set_deferred("disabled", true))
	else:
		service_shutter.position.y = 2.17
		barrier.set_deferred("disabled", true)

func _build_field(portal: Node3D,tint: Color) -> void:
	if metal_shutter:
		set_process(false)
		set_physics_process(false)
		return
	live_field = Node3D.new()
	live_field.name = "LiveField"
	portal.add_child(live_field)
	field_material = ShaderMaterial.new()
	field_material.shader = preload("res://shaders/lab_door_field.gdshader")
	field_material.set_shader_parameter("pole_color",tint)
	var kit := Kit.new(live_field)
	kit.quad(Vector3(0,1.04,.035),Vector2(2.16,2.02),field_material)
	field_indicator = ShaderMaterial.new()
	field_indicator.shader = preload("res://shaders/lab_service_lamp.gdshader")
	field_indicator.set_shader_parameter("tint",tint)
	for side in [-1.0,1.0]:
		for y in [.42,1.04,1.66]:
			kit.quad(Vector3(side*1.108,y,.109),Vector2(.026,.085),field_indicator)
	kit.quad(Vector3(0,2.335,.13),Vector2(.37,.021),field_indicator)
	var glow := ShaderMaterial.new()
	glow.shader = preload("res://shaders/lab_halo.gdshader")
	glow.set_shader_parameter("light_color",tint)
	glow.set_shader_parameter("energy",.16)
	kit.quad(Vector3(0,.035,-.16),Vector2(2.13,1.20),glow,Vector3(-PI*.5,0,0))
	field_halos.append(glow)
