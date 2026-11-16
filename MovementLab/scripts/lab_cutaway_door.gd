extends "res://scripts/lab_polarity_shield.gd"

const TUNNEL := preload("res://models/props/lab_tunnel_interior.glb")
const TUNNEL_PAINT := preload("res://shaders/lab_tunnel_finish.gdshader")
const MOUNT_PAINT := preload("res://shaders/lab_door_metal.gdshader")
const STEEL_MAP := preload("res://art/lab_bulkhead_steel.png")
const RECESSED_FIELD_DEPTH := -.285
const ELECTRODE_HEIGHTS := [.43, 1.075, 1.72]
var finishes: Array[ShaderMaterial] = []
var previous_field_power := -1.0
var metal_tint := Color.WHITE
var textured_portal := false
var metal_shutter := false
var service_shutter: Node3D
var service_open := false

func field_color() -> Color:
	if not sealed and pole == Pole.BLUE:
		return Color("2c75ff")
	return super.field_color()

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
			paint.set_shader_parameter("textured_portal",textured_portal)
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

func _rounded_contour(half_width: float, bottom: float, top: float, radius: float, depth: float) -> PackedVector3Array:
	var outline := PackedVector3Array()
	var corners := [Vector2(half_width-radius,bottom+radius),Vector2(half_width-radius,top-radius),
		Vector2(-half_width+radius,top-radius),Vector2(-half_width+radius,bottom+radius)]
	for corner in range(corners.size()):
		for step in range(7):
			var angle := (float(corner)-1.0+float(step)/6.0)*PI*.5
			var point: Vector2 = corners[corner]+Vector2.from_angle(angle)*radius
			outline.append(Vector3(point.x,point.y,depth))
	return outline

func _build_mount(portal: Node3D) -> void:
	# The mounting flange fits the shell's 2.5 m opening, behind its Z=.66 cut face.
	# Eight continuous rings give the mouth real bevels, a gasket and an inset throat.
	var material := ShaderMaterial.new()
	material.shader = MOUNT_PAINT
	material.set_shader_parameter("steel_map",STEEL_MAP)
	material.set_shader_parameter("field_color",field_color())
	material.set_shader_parameter("metal_tint",metal_tint)
	material.set_shader_parameter("textured_portal",textured_portal)
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
	if textured_portal:
		# Cast surround, exposed machined lip, a recessed gasket and a stepped tunnel liner.
		profiles = [
			_rounded_contour(1.47,-.035,2.53,.25,-.72),
			_rounded_contour(1.47,-.035,2.53,.25,.015),
			_rounded_contour(1.425,-.023,2.48,.23,.068),
			_rounded_contour(1.36,-.008,2.416,.22,.105),
			_rounded_contour(1.27,.006,2.33,.19,.105),
			_rounded_contour(1.235,.012,2.29,.17,.049),
			_rounded_contour(1.204,.019,2.255,.16,.037),
			_rounded_contour(1.204,.019,2.255,.16,-.091),
			_rounded_contour(1.114,.028,2.16,.15,-.23),
			_rounded_contour(1.114,.028,2.16,.15,-.43),
			_rounded_contour(1.19,.016,2.23,.16,-.81)]
		colors = [Color("283438"),Color("384649"),Color("657370"),Color("465257"),Color("68726b"),
			Color("1a2225"),Color("111b20"),Color("4e6266"),Color("374b52"),Color("1b2a30")]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	for band in range(profiles.size()-1):
		surface.set_smooth_group(band if textured_portal else -1)
		var edge_count: int = profiles[band].size()
		for edge in range(edge_count):
			var next := (edge+1)%edge_count
			var a: Vector3 = profiles[band][edge]
			var b: Vector3 = profiles[band][next]
			var c: Vector3 = profiles[band+1][next]
			var d: Vector3 = profiles[band+1][edge]
			for vertex: Vector3 in [a,c,b,a,d,c]:
				surface.set_color(colors[band])
				surface.add_vertex(vertex)
	surface.generate_normals()
	var mount := MeshInstance3D.new()
	mount.name = "FittedMount"
	mount.mesh = surface.commit()
	mount.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	portal.add_child(mount)
	if textured_portal and not metal_shutter:
		_build_textured_hardware(portal,material)
		return
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

func _build_textured_hardware(portal: Node3D, material: ShaderMaterial) -> void:
	var kit := Kit.new(portal,material)
	kit.box(Vector3(0,1.15,-2.34),Vector3(2.6,2.32,.035),Color("07090a"))
	for side: float in [-1.0,1.0]:
		kit.plate(Vector3(side*1.114,1.075,-.225),Vector3(.095,1.86,.13),Color("1e2a30"))
		kit.plate(Vector3(side*1.145,1.075,-.143),Vector3(.062,1.90,.039),Color("5e6d6d"))
		for y: float in ELECTRODE_HEIGHTS:
			kit.plate(Vector3(side*1.102,y,-.197),Vector3(.115,.155,.175),Color("637272"))
			kit.plate(Vector3(side*1.079,y,-.102),Vector3(.088,.097,.029),Color("24343a"))
			for offset: float in [-.052,.052]:
				kit.plate(Vector3(side*1.10,y+offset,-.108),Vector3(.105,.021,.036),Color("7c8680"))
		for y: float in [.25,1.21,2.145]:
			kit.cylinder(Vector3(side*1.315,y,.106),Vector3(.082,.015,.082),Color("1b282b"),Vector3(PI*.5,0,0))
			kit.cylinder(Vector3(side*1.315,y,.118),Vector3(.043,.017,.043),Color("77817a"),Vector3(PI*.5,0,0))
	kit.plate(Vector3(0,2.372,.116),Vector3(.76,.10,.034),Color("1d292e"))
	for side: float in [-1.0,1.0]:
		for slot in range(3):
			kit.plate(Vector3(side*(.46+slot*.10),2.369,.107),Vector3(.068,.032,.014),Color("293539"))
	# The steel threshold sits just above the deck and continues under the field.
	kit.box(Vector3(0,.009,-.41),Vector3(2.30,.020,1.22),Color("485658"))
	for depth: float in [-.42,-.29,-.16,-.03]:
		kit.box(Vector3(0,.020,depth),Vector3(1.94,.005,.018),Color("1c262b"))
	kit.finish()

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
	field_material.set_shader_parameter("recessed",textured_portal)
	var blue_polarity := not sealed and pole == Pole.BLUE
	field_material.set_shader_parameter("blue_polarity",blue_polarity)
	var kit := Kit.new(live_field)
	var field_depth := RECESSED_FIELD_DEPTH if textured_portal else .035
	kit.quad(Vector3(0,1.075 if textured_portal else 1.04,field_depth),
		Vector2(2.20,2.1) if textured_portal else Vector2(2.16,2.02),field_material)
	field_indicator = ShaderMaterial.new()
	field_indicator.shader = preload("res://shaders/lab_service_lamp.gdshader")
	field_indicator.set_shader_parameter("tint",tint)
	for side in [-1.0,1.0]:
		for y in ELECTRODE_HEIGHTS if textured_portal else [.42,1.04,1.66]:
			var emitter := Vector3(side*1.079,y,-.085) if textured_portal else Vector3(side*1.108,y,.109)
			kit.quad(emitter,Vector2(.043,.104) if blue_polarity else Vector2(.026,.085),field_indicator)
	var header := Vector3(0,2.372,.138) if textured_portal else Vector3(0,2.335,.13)
	kit.quad(header,Vector2(.37,.031) if blue_polarity else Vector2(.37,.021),field_indicator)
	var glow := ShaderMaterial.new()
	glow.shader = preload("res://shaders/lab_halo.gdshader")
	glow.set_shader_parameter("light_color",tint)
	glow.set_shader_parameter("energy",.16)
	kit.quad(Vector3(0,.035,-.16),Vector2(2.13,1.20),glow,Vector3(-PI*.5,0,0))
	field_halos.append(glow)
