extends "res://scripts/lab_dressing.gd"
## Reuse the same geometry with different atlas bays per scene instance.

@export var lower_bays: Array[int] = [Machine.PUMP, Machine.EMPTY, Machine.PISTON]
@export var middle_bays: Array[int] = [Machine.VALVES, Machine.PRESSURE, Machine.EMPTY]
@export var upper_bays: Array[int] = [Machine.EMPTY, Machine.EMPTY, Machine.VALVES]
@export var wall_tint := Color(.80,.84,.84)

const SHADE := Color("10191d")
const FRAME_PAINT := Color("282e2d")
const RIM := Color("625c4b")
const BACKDROP := preload("res://shaders/lab_room_backdrop.gdshader")
const POWER_LINE := preload("res://shaders/lab_relay_power.gdshader")
const LAMP_LIGHT := preload("res://shaders/lab_service_lamp.gdshader")
const AIR_DUST := preload("res://shaders/lab_light_dust.gdshader")
const Rooms := preload("res://scripts/lab_relay_rooms.gd")
const LAMP_DUST_VOLUME := Vector3(3.5,4.0,.56)
const SHAFT_DUST_COUNT := 24
const VENTS := [Vector3(6.6,0,-1.04),Vector3(18.8,0,-1.04),Vector3(16.0,6,-1.04),Vector3(24.3,12,-1.04)]
const FIXED_LIGHTS := {
	1: [Vector3(.91,.96,1.01), Vector4(4.5,2.4,6.2,5.6), Vector3(.49,.29,.11),
		Vector4(10.7,19.5,6.0,5.1), Vector3(.12,.27,.37)],
	2: [Vector3(.89,.85,.81), Vector4(20.8,3.1,13.0,5.8), Vector3(.36,.24,.12),
		Vector4(35.2,2.9,7.4,5.2), Vector3(.09,.18,.24)],
	3: [Vector3(.88,.96,1.04), Vector4(14.8,3.3,13.0,5.1), Vector3(.10,.23,.31),
		Vector4(27.5,8.2,6.0,4.2), Vector3(.35,.23,.09)],
}

var lighting: Array
var room_steel: ShaderMaterial
var room_deck: ShaderMaterial
var relay_current: ShaderMaterial
var floor_lights: Array[Array] = [[],[],[]]
var floor_exposure := Vector3(1.0,.26,.45)
var fan_rotor: Node3D
var fan_speed := .55
var vents: Array[Vector3] = []

func _build_layout() -> void:
	var room: int = get_parent().room_index
	lighting = FIXED_LIGHTS.get(room,[])
	room_steel = Kit.bulkhead_paint().duplicate() as ShaderMaterial
	room_deck = Kit.deck_paint().duplicate() as ShaderMaterial
	for material in [room_steel,room_deck]:
		material.set_shader_parameter("room_lighting",1.0)
		apply_room_lighting(material)
	var mist := ShaderMaterial.new()
	mist.shader = preload("res://shaders/lab_vent_mist.gdshader")
	var width: float = Rooms.LAYOUTS[room].width
	var roof: float = Rooms.LAYOUTS[room].roof
	_build_shell(width,roof)
	if room == 0:
		_build_polarity_works()
		var vent_names := ["ArrivalVent","LowerVent","MiddleVent","UpperVent"]
		for index in range(VENTS.size()):
			_add_vent(VENTS[index],mist,vent_names[index])
	else:
		_build_linked_room(room,width,roof,mist)
	if not has_fixed_lighting():
		_apply_floor_exposure()
	set_process(false)

func has_fixed_lighting() -> bool:
	return not lighting.is_empty()

func apply_room_lighting(material: ShaderMaterial) -> void:
	if not has_fixed_lighting():
		return
	material.set_shader_parameter("fixed_room_lighting",true)
	material.set_shader_parameter("fixed_ambient",lighting[0])
	material.set_shader_parameter("first_light_pool",lighting[1])
	material.set_shader_parameter("first_light_tint",lighting[2])
	material.set_shader_parameter("second_light_pool",lighting[3])
	material.set_shader_parameter("second_light_tint",lighting[4])

func _build_polarity_works() -> void:
	_hall("Lower",0,27,0,lower_bays)
	_hall("Middle",8,27,6,middle_bays)
	_hall("Upper",8,36,12,upper_bays)
	_shaft_backdrop("EastTurn",27,36,-.2,12)
	_shaft_backdrop("WestTurn",0,8,5.8,18)
	_frame_junction(27,0,11.8)
	_frame_junction(8,5.8,17.8)
	_ceiling_seat("UpperCeiling",8,36,18)
	_service_light("ArrivalLamp",Vector3(5.7,5.17,-1.52),Color("f8c385"),0)
	_service_light("CoolantLamp",Vector3(21.8,11.17,-1.52),Color("9acbe3"),1)
	_service_light("LiftLamp",Vector3(9.6,11.17,-1.52),Color("9acbe3"),1)
	_service_light("RelayLamp",Vector3(23.4,17.17,-1.52),Color("c9d9b6"),2)

func _build_linked_room(room: int, width: float, roof: float, mist: ShaderMaterial) -> void:
	match room:
		1:
			wall_tint = Color("e0e6e4")
			_shaft_backdrop("PressureMains",0,width,-.4,roof+.15,preload("res://art/lab_pressure_riser.png"),false)
			_ceiling_seat("RiserCap",0,width,roof)
			_frame_junction(.50,-.3,roof)
			_frame_junction(width-.50,-.3,roof)
			_riser_door_recess(0,5.6,0,preload("res://art/relay_distribution_plenum.png"))
			_riser_door_recess(10.05,16,18,preload("res://art/relay_pump_access.png"))
			_riser_bracing()
			_catwalk_rail(8.2,11.4,18.0)
			_service_light("IntakeWorkLight",Vector3(5.45,4.6,-1.95),Color("f7ce98"),0)
			_service_light("ServiceDeckLight",Vector3(3.85,12.4,-2.3),Color("bde6ed"),1)
			_service_light("DischargeWorkLight",Vector3(10.5,22.05,-1.85),Color("afddec"),2)
			_add_vent(Vector3(6,0,-1.04),mist)
			_add_vent(Vector3(3.1,9,-1.04),mist)
		2:
			wall_tint = Color("e8e0d4")
			_back_wall("WestServiceBay",0,9,-.25,roof,preload("res://art/relay_distribution_plenum.png"),-3.72,.12)
			_back_wall("ObservationWindows",9,33,-.25,roof,preload("res://art/lab_observation_gallery.png"),-3.72,.06)
			_back_wall("EastServiceBay",33,width,-.25,roof,preload("res://art/relay_pump_access.png"),-3.72,.12)
			_door_enclosure(Vector3(2.35,0,0),-1.0,7.1)
			_door_enclosure(Vector3(38,0,0),1.0,34.5)
			_ceiling_seat("GalleryCeiling",0,width,roof)
			_overhead_pipe(5.5,width-4,roof-.49)
			for x in [8.96,33.04]:
				_frame_junction(x,0,roof)
			_catwalk_rail(9.44,12.56,2.1)
			_catwalk_rail(31.44,34.56,2.1)
			_service_light("ObservationLamp",Vector3(15.6,6.6,-2.9),Color("f5d0a3"),0)
			_service_light("ServiceLamp",Vector3(31.8,6.63,-2.85),Color("d8e8df"),0)
			_add_vent(Vector3(9.6,0,-1.04),mist)
			_add_vent(Vector3(29.7,0,-1.04),mist)
		3:
			wall_tint = Color("e1edf0")
			var chamber := _back_wall("CoolantVessels",0,width,-.4,roof,preload("res://art/lab_coolant_exchange.png"),-5.9,.10)
			var air := _dust_cloud("ExchangeDust",chamber.parent,Vector3(0,0,2.2),Vector3(29,12,1.3),Color("a7cad6"),SHAFT_DUST_COUNT)
			air.set_shader_parameter("lamp_cone",false)
			_door_enclosure(Vector3(2.35,0,0),-1.0,6.8)
			_door_enclosure(Vector3(27.8,6.6,0),1.0,25.2)
			_ceiling_seat("ExchangeCeiling",0,width,roof)
			_catwalk_rail(17.27,20.73,3.2)
			_catwalk_rail(25.2,26.55,6.6)
			_deck_trestle(18.7,3.2,2.15)
			_deck_trestle(28.0,6.6,3.8)
			_service_light("ExchangeLamp",Vector3(13.4,7.16,-2.5),Color("bce5ed"),1)
			_service_light("SwitchgearLamp",Vector3(26.5,10.77,-1.8),Color("f1c386"),2)
			_add_vent(Vector3(7.7,0,-1.04),mist)
			_add_vent(Vector3(26.0,0,-1.04),mist)
		4:
			wall_tint = Color("b8c9b7")
			_hall("VaultApproach",0,24,0,[Machine.EMPTY,Machine.PRESSURE,Machine.PUMP])
			_feature_wall("NodeAlcove",0,10.2,6,preload("res://art/relay_pump_access.png"))
			_hall("VaultMezzanine",10.2,24,6,[Machine.EMPTY,Machine.VALVES])
			_shaft_backdrop("VaultRiser",24,width,-.2,roof,preload("res://art/relay_switchyard_sump.png"))
			_frame_junction(10.2,6,roof)
			_frame_junction(24,0,roof)
			_ceiling_seat("VaultCeiling",0,width,roof)
			_service_light("NodeLamp",Vector3(4.2,11.17,-1.52),Color("b8e6d0"),1)
			_add_vent(Vector3(9.3,0,-1.04),mist)
			_add_vent(Vector3(18.4,6,-1.04),mist)
			_node_alcove()

func _feature_wall(label: String, left: float, right: float, floor_y: float, texture: Texture2D) -> void:
	_back_wall(label,left,right,floor_y-.2,floor_y+5.8,texture,-3.56,.14)

func _back_wall(label: String, left: float, right: float, bottom: float, top: float,
		texture: Texture2D, depth: float, recession: float) -> Kit:
	var size := Vector2(right-left,top-bottom)
	var crop := _cover_crop(texture,size)
	var material := _backdrop_material(texture,(Vector2.ONE-crop)*.5,crop,recession)
	if not has_fixed_lighting():
		floor_lights[roundi((bottom+.2)/6.0)].append(material)
	var kit := _section(label,Vector3((left+right)*.5,(bottom+top)*.5,depth))
	kit.quad(Vector3.ZERO,size,material)
	return kit

func _riser_door_recess(left: float, right: float, floor_y: float, texture: Texture2D) -> void:
	var width := right-left
	var center := (left+right)*.5
	var rear := -2.98
	_back_wall("RiserRecess",left,right,floor_y-.08,floor_y+3.52,texture,rear,.07)
	# Keep the casing in the rear wall plane and clear of the playable lane.
	var frame := _section("RiserRecessFrame",Vector3(center,floor_y,rear))
	frame.surface_material = room_steel
	var trim := Color("484944")
	frame.box(Vector3(0,3.48,.01),Vector3(width+.22,.20,.22),trim)
	frame.box(Vector3(0,.07,.01),Vector3(width+.22,.15,.19),trim)
	for side in [-1.0,1.0]:
		var x := float(side)*width*.5
		frame.box(Vector3(x,1.74,.02),Vector3(.24,3.48,.27),trim)
		for y in [.30,3.20]:
			frame.plate(Vector3(x,y,.18),Vector3(.31,.22,.08),RIM)
	frame.finish()

func _door_enclosure(door: Vector3, direction: float, jamb_x: float) -> void:
	var wall_x: float = 0.0 if direction < 0.0 else Rooms.LAYOUTS[get_parent().room_index].width
	var span := absf(wall_x-jamb_x)
	var center := (wall_x+jamb_x)*.5
	var kit := _section("DoorBay",Vector3(center,door.y,0))
	kit.surface_material = room_steel
	var interior := Color("384c50")
	var frame := Color("777b6f")
	# Recess the service lining behind the portal and cap it with a low ribbed soffit.
	kit.box(Vector3(0,1.93,-2.87),Vector3(span,3.86,.34),interior)
	kit.box(Vector3(0,.33,-2.66),Vector3(span,.60,.14),FRAME_PAINT)
	kit.box(Vector3(0,2.92,-2.67),Vector3(span,.15,.22),RIM)
	kit.box(Vector3(0,3.80,-.47),Vector3(span,.29,4.53),FRAME_PAINT)
	kit.box(Vector3(0,3.69,1.80),Vector3(span,.29,.28),frame)
	for x in [-span*.47,span*.47]:
		kit.box(Vector3(x,1.93,-2.58),Vector3(.23,3.86,.35),frame)
		kit.box(Vector3(x,3.54,-.40),Vector3(.22,.22,4.43),frame)
		kit.plate(Vector3(x,3.64,1.96),Vector3(.35,.38,.13),RIM)
	var inspection_x := door.x-center-direction*1.68
	kit.plate(Vector3(inspection_x,1.85,-2.635),Vector3(1.52,1.06,.21),frame)
	kit.plate(Vector3(inspection_x,1.85,-2.507),Vector3(1.34,.85,.14),SHADE)
	for row in range(6):
		kit.box(Vector3(inspection_x,1.55+row*.12,-2.415),Vector3(1.21,.046,.075),interior)
	kit.box(Vector3(inspection_x,3.47,-1.82),Vector3(.89,.086,.26),SHADE)
	kit.box(Vector3(inspection_x,3.42,-1.82),Vector3(.69,.024,.15),Color("dfc994"),true)
	kit.finish()

func _riser_bracing() -> void:
	var kit := _section("RiserSteel",Vector3(0,0,-3.15))
	kit.surface_material = room_steel
	var upright := Color("4a6064")
	var rake := Vector3(0,0,-.68)
	kit.box(Vector3(1.15,12.1,0),Vector3(.47,23.4,.62),upright)
	kit.box(Vector3(14.85,12.1,0),Vector3(.47,23.4,.62),upright)
	kit.box(Vector3(3.15,8.7,-.15),Vector3(.23,9.4,.28),RIM)
	kit.box(Vector3(3.60,8.7,-.15),Vector3(.23,9.4,.28),RIM)
	for y in [4.5,8.9,13.4,17.55,22.8]:
		kit.plate(Vector3(1.15,y,.34),Vector3(.69,.56,.19),upright.lightened(.16))
		kit.plate(Vector3(14.85,y,.34),Vector3(.69,.56,.19),upright.lightened(.16))
	for y in [5.7,7.5,9.3,11.1,12.9]:
		kit.box(Vector3(3.375,y,.06),Vector3(.87,.12,.16),upright)
	kit.box(Vector3(3.25,7.75,-.15),Vector3(.24,5.12,.32),upright,false,rake)
	kit.box(Vector3(12.08,16.58,-.02),Vector3(.29,4.22,.41),upright,false,rake)
	kit.finish()

func _catwalk_rail(left: float, right: float, floor_y: float) -> void:
	var width := right-left
	var kit := _section("RearCatwalkRail",Vector3((left+right)*.5,floor_y,-1.49))
	kit.surface_material = room_steel
	var rail := Color("87806b")
	kit.cylinder(Vector3(0,.85,0),Vector3(.081,width,.081),rail,ALONG_X)
	kit.cylinder(Vector3(0,.46,0),Vector3(.059,width,.059),rail.darkened(.30),ALONG_X)
	var bays := maxi(1,ceili(width/1.55))
	for i in range(bays+1):
		var x := lerpf(-width*.5+.08,width*.5-.08,float(i)/bays)
		kit.box(Vector3(x,.42,0),Vector3(.079,.84,.076),rail)
		kit.box(Vector3(x,.04,0),Vector3(.24,.08,.18),SHADE)
	kit.finish()

func _deck_trestle(x: float, floor_y: float, width: float) -> void:
	var kit := _section("DeckTrestle",Vector3(x,0,-1.2))
	kit.surface_material = room_steel
	var steel := Color("516467")
	var diagonal_length := Vector2(width,floor_y-.47).length()
	var angle := atan2(width,floor_y-.47)
	for side in [-1.0,1.0]:
		var post := float(side)*width*.5
		kit.box(Vector3(post,floor_y*.5,0),Vector3(.26,floor_y,.34),steel)
		kit.plate(Vector3(post,.12,.01),Vector3(.52,.23,.40),RIM)
	kit.box(Vector3(0,(floor_y-.47)*.5,.02),Vector3(.16,diagonal_length,.27),steel,false,Vector3(0,0,angle))
	kit.box(Vector3(0,floor_y-.49,0),Vector3(width+.42,.27,.48),steel)
	kit.finish()

func _cover_crop(texture: Texture2D, size: Vector2) -> Vector2:
	var pixels := Vector2(texture.get_size())
	return size/(pixels*maxf(size.x/pixels.x,size.y/pixels.y))

func _hall(title: String, start: float, end: float, level: float, machines: Array[int]) -> void:
	var width := (end-start)/machines.size()
	for index in range(machines.size()):
		var x := start + width*(float(index)+.5)
		var source := bay_materials[machines[index]]
		var kit := _section(title+"Bay",Vector3(x,level,-3.55))
		var material := _backdrop_material(source.albedo_texture,Vector2(source.uv1_offset.x,source.uv1_offset.y),
			Vector2(source.uv1_scale.x,source.uv1_scale.y),.22)
		floor_lights[roundi(level/6.0)].append(material)
		kit.quad(Vector3(0,2.80,0),Vector2(width,6.0),material)

func _backdrop_material(texture: Texture2D, offset: Vector2, scale: Vector2, depth: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = BACKDROP
	material.set_shader_parameter("backdrop",texture)
	material.set_shader_parameter("atlas_offset",offset)
	material.set_shader_parameter("atlas_scale",scale)
	material.set_shader_parameter("backdrop_tint",wall_tint)
	material.set_shader_parameter("recession",depth)
	apply_room_lighting(material)
	return material

func _shaft_backdrop(label: String, left: float, right: float, bottom: float, top: float,
		texture: Texture2D = null, add_pipes := true) -> void:
	var height := top-bottom
	var width := right-left
	var kit := _section(label,Vector3((left+right)*.5,(bottom+top)*.5,-6.1))
	var image := texture if texture else shaft_material.albedo_texture
	var size := Vector2(width+1.5,height)
	var crop := _cover_crop(image,size)
	var recession := .16 if not add_pipes else (.29 if texture else .55)
	var material := _backdrop_material(image,(Vector2.ONE-crop)*.5,crop,recession)
	material.set_shader_parameter("shaft_haze",.47 if texture else .64)
	kit.quad(Vector3.ZERO,size,material)
	if add_pipes:
		_shaft_pipes(label,kit.parent.position,width,height)
	# Leave the motes behind the playable lane and clear of the bordering rooms.
	var air := _dust_cloud("ShaftDust",kit.parent,Vector3(0,0,3.0),
		Vector3(width-.85,height-.7,1.6),Color("a7bbc0"),SHAFT_DUST_COUNT)
	air.set_shader_parameter("lamp_cone",false)
	air.set_shader_parameter("dust_opacity",1.0)

func _shaft_pipes(label: String, center: Vector3, width: float, height: float) -> void:
	var service := _section(label+"Pipes",center+Vector3(0,0,1.3))
	service.surface_material = room_steel
	for index in range(3):
		var x := width*(.14+float(index)*.105)
		var diameter := .29+float(index)*.14
		service.cylinder(Vector3(x,0,0),Vector3(diameter,height,diameter),Color("24353a"))
		for y in [-height*.31,height*.11,height*.36]:
			service.cylinder(Vector3(x,y,0),Vector3(diameter+.15,.18,diameter+.15),Color("48534b"))
	service.finish()

func light_floors(approach: Vector3, weight: float) -> void:
	var standby := Vector3(.56,.26,.45)
	var target := standby+(Vector3.ONE-standby)*approach
	if floor_exposure.distance_squared_to(target) < .000004:
		return
	floor_exposure = floor_exposure.lerp(target,weight)
	_apply_floor_exposure()

func _apply_floor_exposure() -> void:
	for floor_index in range(floor_lights.size()):
		for material: ShaderMaterial in floor_lights[floor_index]:
			material.set_shader_parameter("lamp_power",floor_exposure[floor_index])
	for material in [room_steel,room_deck]:
		material.set_shader_parameter("gallery_power",floor_exposure.y)

func by_vent(point: Vector3) -> bool:
	for vent in vents:
		if absf(point.y-vent.y) < .28 and point.x > vent.x-.4 and point.x < vent.x+4.3:
			return true
	return false

func _build_shell(width: float, roof: float) -> void:
	var shell := _section("RoomShell",Vector3(width*.5,roof*.5,-7.1))
	shell.surface_material = room_steel
	shell.box(Vector3.ZERO,Vector3(width+1,roof+10,.68),SHADE)
	shell.box(Vector3(0,-roof*.5-1.03,4.85),Vector3(width,1.24,9.9),SHADE)
	shell.box(Vector3(0,roof*.5+.38,4.85),Vector3(width,1.0,9.9),SHADE)
	for x in [-width*.5,width*.5]:
		shell.box(Vector3(x,0,4.85),Vector3(.56,roof,9.9),FRAME_PAINT)
		shell.box(Vector3(x*.994,0,9.76),Vector3(.10,roof,.08),RIM)
	shell.finish()

func _frame_junction(x: float, bottom: float, top: float) -> void:
	var height := top-bottom
	var kit := _section("ShaftJamb",Vector3(x,(bottom+top)*.5,-2.92))
	kit.surface_material = room_steel
	kit.box(Vector3(0,0,-.14),Vector3(.53,height,1.05),FRAME_PAINT)
	kit.box(Vector3(-.17,0,.41),Vector3(.065,height,.061),RIM)
	for y in [-height*.25,0.0,height*.25]:
		kit.plate(Vector3(0,y,.43),Vector3(.55,.30,.14),RIM.darkened(.19))
	kit.finish()

func _ceiling_seat(section_name: String, left: float, right: float, level: float) -> void:
	var width := right-left
	var kit := _section(section_name,Vector3((left+right)*.5,level,0))
	kit.surface_material = room_steel
	# Meet the back wall and the doorway's angled collar at the underside of the deck.
	kit.box(Vector3(0,-.12,-1.43),Vector3(width,.26,3.44),FRAME_PAINT)
	kit.box(Vector3(0,-.245,-2.74),Vector3(width,.18,.54),RIM.darkened(.19),false,Vector3(-.31,0,0))
	kit.box(Vector3(0,-.20,.26),Vector3(width,.24,.18),Color("605f52"))
	kit.box(Vector3(0,-.322,.24),Vector3(width,.033,.15),RIM.darkened(.19))
	var bay_count := ceili(width/3.2)
	for index in range(1,bay_count):
		var x := width*(float(index)/float(bay_count)-.5)
		kit.box(Vector3(x,-.249,-1.36),Vector3(.19,.16,3.28),RIM.darkened(.21))
		kit.plate(Vector3(x,-.176,.38),Vector3(.27,.35,.11),Color("626052"))
	kit.finish()

func deck(start: float, end: float, level: float, _surface: ShaderMaterial = null) -> void:
	super.deck(start,end,level,room_deck)
	if is_equal_approx(level,6.0):
		_lower_ceiling(start,end,level)
		return
	var frame := _section("DeckGirder",Vector3((start+end)*.5,level,-.26))
	frame.surface_material = room_steel
	frame.box(Vector3(0,-.38,0),Vector3(end-start,.44,3.23),SHADE)
	frame.box(Vector3(0,-.54,1.6),Vector3(end-start,.10,.13),FRAME_PAINT)
	frame.finish()

func _lower_ceiling(start: float, end: float, level: float) -> void:
	var width := end-start
	var kit := _section("LowerCeiling",Vector3((start+end)*.5,level,0))
	kit.surface_material = room_steel
	# Carry the soffit from the back wall to the camera-side wall return.
	kit.box(Vector3(0,-.37,-.28),Vector3(width,.24,5.76),FRAME_PAINT)
	kit.box(Vector3(0,-.31,2.54),Vector3(width,.38,.20),Color("4d4d44"))
	kit.box(Vector3(0,-.49,2.45),Vector3(width,.16,.26),Color("656257"),false,Vector3(-.46,0,0))
	kit.box(Vector3(0,-.16,2.65),Vector3(width,.055,.09),RIM)
	kit.box(Vector3(0,-.48,-2.93),Vector3(width,.14,.29),RIM.darkened(.25))
	var sections := ceili(width/4.1)
	for index in range(sections):
		var x := width*((float(index)+.5)/float(sections)-.5)
		kit.box(Vector3(x,-.49,-.16),Vector3(.19,.17,5.33),Color("3a3d36"))
		kit.plate(Vector3(x,-.33,2.65),Vector3(.24,.40,.15),RIM.darkened(.15))
		for y in [-.45,-.22]:
			kit.cylinder(Vector3(x,y,2.74),Vector3(.055,.031,.055),RIM,Vector3(PI*.5,0,0))
	kit.finish()

func _add_vent(at: Vector3, mist: ShaderMaterial, label := "") -> void:
	var vent_name := label if not label.is_empty() else "Floor%dVent" % vents.size()
	vents.append(at)
	_floor_vent(vent_name,at,mist)

func _overhead_pipe(left: float, right: float, y: float) -> void:
	var kit := _section("OverheadMain",Vector3((left+right)*.5,y,-2.14))
	kit.surface_material = room_steel
	var along := Vector3(0,0,PI*.5)
	kit.cylinder(Vector3.ZERO,Vector3(.23,right-left,.23),Color("415251"),along)
	for fraction in [-.44,-.26,-.05,.22,.43]:
		var x := (right-left)*float(fraction)
		kit.cylinder(Vector3(x,0,0),Vector3(.32,.16,.32),RIM,along)
		kit.box(Vector3(x,.15,-.03),Vector3(.14,.29,.19),FRAME_PAINT)
	kit.finish()

func _node_alcove() -> void:
	var kit := _section("NetworkAlcove",Vector3(4.2,6,-1.78))
	kit.surface_material = room_steel
	kit.plate(Vector3(0,1.58,-.29),Vector3(3.16,2.85,.24),Color("344644"))
	kit.plate(Vector3(0,1.58,-.14),Vector3(2.66,2.44,.13),SHADE)
	kit.box(Vector3(0,.14,0),Vector3(2.83,.24,.62),FRAME_PAINT)
	for side in [-1.0,1.0]:
		var x := float(side)*1.12
		kit.box(Vector3(x,1.39,.02),Vector3(.19,2.27,.23),RIM)
		kit.box(Vector3(x,1.03,.15),Vector3(.075,.43,.035),Color("5a9c8d"),true)
		kit.cylinder(Vector3(x,2.5,.08),Vector3(.19,.26,.19),Color("7a8070"))
	kit.finish()

func _floor_vent(vent_name: String, at: Vector3, mist: ShaderMaterial) -> void:
	var kit := _section(vent_name,at)
	kit.surface_material = room_steel
	kit.box(Vector3(0,.014,0),Vector3(.91,.028,.53),RIM)
	kit.box(Vector3(0,.028,0),Vector3(.78,.014,.39),SHADE)
	for index in range(6):
		var x := (float(index)-2.5)*.118
		kit.box(Vector3(x,.044,0),Vector3(.059,.033,.38),Color("696b5e"),false,Vector3(0,0,-.22))
	for x in [-.40,.40]:
		kit.cylinder(Vector3(x,.034,0),Vector3(.053,.026,.053),FRAME_PAINT)
	kit.finish()
	kit.quad(Vector3(1.65,.52,.19),Vector2(6.2,1.04),mist)
	kit.quad(Vector3(1.12,.36,.68),Vector2(4.75,.72),mist)

func mount_landing(at: Vector3, width: float) -> void:
	var kit := _section("LandingMount",at)
	kit.surface_material = room_steel
	for side in [-1.0,1.0]:
		var x := float(side)*width*.30
		kit.plate(Vector3(x,-.61,-2.99),Vector3(.53,1.21,.21),FRAME_PAINT)
		kit.box(Vector3(x,-.65,-.98),Vector3(.21,.21,4.05),FRAME_PAINT,false,Vector3(-.22,0,0))
		kit.box(Vector3(x,-.31,.96),Vector3(.29,.21,.59),RIM.darkened(.38))
	kit.finish()

func _service_light(light_name: String, at: Vector3, tint: Color, floor_index: int) -> void:
	var kit := _section(light_name,at)
	kit.surface_material = room_steel
	kit.plate(Vector3.ZERO,Vector3(1.24,.24,.37),Color("4b4c42"))
	kit.box(Vector3(0,-.028,.202),Vector3(.86,.082,.044),Color("2d3537"))
	for side in [-1.0,1.0]:
		var x := float(side)*.49
		kit.box(Vector3(x,.28,-.065),Vector3(.15,.52,.21),FRAME_PAINT)
		kit.plate(Vector3(x,.115,.14),Vector3(.22,.17,.11),RIM)
	kit.finish()
	var emissive := Node3D.new()
	emissive.name = "Emissive"
	kit.parent.add_child(emissive)
	var lamp := Kit.new(emissive)
	var tube := ShaderMaterial.new()
	tube.shader = LAMP_LIGHT
	tube.set_shader_parameter("tint",tint)
	lamp.quad(Vector3(0,-.028,.237),Vector2(.85,.078),tube)
	var beam := tube.duplicate() as ShaderMaterial
	beam.set_shader_parameter("beam",true)
	lamp.quad(Vector3(0,-2.18,.14),Vector2(4.25,4.35),beam)
	var dust := _dust_cloud("LampDust",emissive,Vector3(0,-2.22,.19),LAMP_DUST_VOLUME,tint,36)
	floor_lights[floor_index].append_array([tube,beam,dust])

func _dust_cloud(label: String, parent: Node3D, at: Vector3, volume: Vector3, tint: Color, count: int) -> ShaderMaterial:
	var dust := MeshInstance3D.new()
	dust.name = label
	dust.position = at
	var vertices := PackedVector3Array()
	var random := RandomNumberGenerator.new()
	random.seed = int(parent.global_position.x*470.0)
	for index in range(count):
		vertices.append(Vector3(random.randf(),random.randf(),random.randf()))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var points := ArrayMesh.new()
	points.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS,arrays)
	dust.mesh = points
	dust.custom_aabb = AABB(-volume*.5,volume).grow(.10)
	var paint := ShaderMaterial.new()
	paint.shader = AIR_DUST
	paint.set_shader_parameter("dust_color",tint)
	paint.set_shader_parameter("drift_volume",volume)
	dust.material_override = paint
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(dust)
	return paint

func build_relay(at: Vector3, terminal: Vector3, spill_origin: Vector3, tint: Color) -> void:
	var kit := _section("ShieldTransformer",at)
	kit.surface_material = room_steel
	relay_current = ShaderMaterial.new()
	relay_current.shader = POWER_LINE
	relay_current.set_shader_parameter("pole_color",tint)
	for material in [room_steel,room_deck]:
		material.set_shader_parameter("relay_position",spill_origin)
		material.set_shader_parameter("relay_color",tint)
	var current := Kit.new(kit.parent,relay_current)
	kit.plate(Vector3(0,2.42,-.31),Vector3(5.15,4.40,.59),Color("474b43"))
	kit.plate(Vector3(0,2.50,.015),Vector3(4.72,3.96,.26),Color("141f25"))
	kit.box(Vector3(0,.43,.29),Vector3(4.23,.44,.68),Color("363d39"))
	kit.box(Vector3(0,3.43,.24),Vector3(3.96,.28,.66),Color("535447"))
	for side in [-1.0,1.0]:
		var x := float(side)*2.20
		kit.plate(Vector3(x,2.10,.19),Vector3(.25,2.65,.25),Color("363d39"))
		for y in [1.01,2.15,3.23]:
			kit.cylinder(Vector3(x,y,.34),Vector3(.094,.057,.094),RIM,Vector3(PI*.5,0,0))
	for index in range(3):
		var x := (float(index)-1.0)*1.24
		kit.cylinder(Vector3(x,2.02,.43),Vector3(.78,2.48,.78),Color("252c2d"))
		for y in [.90,2.88]:
			kit.cylinder(Vector3(x,y,.43),Vector3(.95,.17,.95),Color("77705a"))
		for turn in range(22):
			var y := 1.06+float(turn)*.074
			var copper := Color("b77b50").lerp(Color("69432e"),.44+.39*sin(float(turn)*1.79+float(index)))
			kit.cylinder(Vector3(x,y,.43),Vector3(.89,.051,.89),copper)
		current.box(Vector3(x,2.79,.93),Vector3(.58,.056,.043),Color("ed9875"))
		kit.cylinder(Vector3(x,3.25,.43),Vector3(.39,.53,.39),Color("81725a"))
		for y in [3.14,3.26,3.38]:
			kit.cylinder(Vector3(x,y,.43),Vector3(.53,.067,.53),Color("3c3833"))
	for x in [-1.83,1.83]:
		kit.box(Vector3(x,1.61,.65),Vector3(.12,1.67,.10),RIM.darkened(.25))
	kit.plate(Vector3(1.80,3.08,.63),Vector3(.53,.51,.28),RIM)
	current.box(Vector3(1.80,3.08,.79),Vector3(.25,.13,.038),Color("f9ab8c"))
	var points := PackedVector3Array([
		Vector3(1.91,3.08,.75),Vector3(2.34,3.08,.75),Vector3(2.73,2.91,.75),
		Vector3(3.30,2.91,.92),terminal-at
	])
	for index in range(points.size()-1):
		var start := points[index]
		var finish := points[index+1]
		var axis := finish-start
		var rotation := Basis(Quaternion(Vector3.UP,axis.normalized())).get_euler()
		var middle := (start+finish)*.5
		kit.cylinder(middle,Vector3(.16,axis.length()+.045,.16),Color("2f393b"),rotation)
		current.cylinder(middle+Vector3(0,.015,.085),Vector3(.049,axis.length()+.038,.049),Color("ce8569"),rotation)
		if axis.length() > 1.0:
			for fraction in [.28,.64]:
				var clamp_at := start.lerp(finish,fraction)
				kit.cylinder(clamp_at+Vector3(0,0,.024),Vector3(.24,.15,.24),RIM,rotation)
				kit.box(clamp_at+Vector3(0,0,-.35),Vector3(.16,.17,.63),FRAME_PAINT)
	kit.finish()
	current.finish()
	relay_current.set_shader_parameter("feed_start",at.x+points[0].x)
	relay_current.set_shader_parameter("feed_finish",terminal.x)
	_relay_fan(at+Vector3(0,3.93,.39))
	set_process(true)

func _relay_fan(at: Vector3) -> void:
	var casing := _section("RelayCoolingFan",at)
	casing.surface_material = room_steel
	casing.plate(Vector3.ZERO,Vector3(.93,.61,.20),Color("4a4f43"))
	casing.cylinder(Vector3(0,0,.116),Vector3(.52,.036,.52),SHADE,Vector3(PI*.5,0,0))
	for y in [-.19,-.065,.065,.19]:
		casing.box(Vector3(0,y,.23),Vector3(.51-absf(y)*.65,.026,.028),Color("57594c"))
	casing.finish()
	fan_rotor = Node3D.new()
	fan_rotor.position.z = .162
	casing.parent.add_child(fan_rotor)
	var rotor := Kit.new(fan_rotor,room_steel)
	for index in range(5):
		var angle := float(index)*TAU/5.0
		var blade := Vector3(cos(angle),sin(angle),0)
		rotor.box(blade*.12,Vector3(.19,.071,.029),Color("697065"),false,Vector3(0,0,angle+.26))
	rotor.cylinder(Vector3(0,0,.018),Vector3(.13,.026,.13),RIM,Vector3(PI*.5,0,0))
	rotor.finish()

func _process(delta: float) -> void:
	fan_rotor.rotate_z(delta*fan_speed)

func set_shield_light(origin: Vector3, tint: Color) -> void:
	for material in [room_steel,room_deck]:
		material.set_shader_parameter("relay_position",origin)
		material.set_shader_parameter("relay_color",tint)

func set_relay_power(feed: float, spill: float, surge: float) -> void:
	room_steel.set_shader_parameter("relay_power",spill)
	room_deck.set_shader_parameter("relay_power",spill)
	if relay_current:
		relay_current.set_shader_parameter("powered",feed)
		relay_current.set_shader_parameter("surge",surge)
		fan_speed = lerpf(.14,1.12,feed)

