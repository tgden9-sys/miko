extends Node3D

signal power_visuals(feed: float, spill: float, surge: float)

const RESTART_TRAVEL := .37
const FIELD_RAMP := .22

enum Pole { RED = 1, BLUE = 2 }

const Kit := preload("res://scripts/lab_art_kit.gd")
const PAINT := Color("53534a")
const EDGE := Color("91846a")
const SHADOW := Color("1c2326")
const WALL := Color("55554b")
const STRUCTURAL_STEEL := Color("666356")
const OPENING_HEIGHT := 2.04
const OPENING_WIDTH := 2.20
const WALL_HEIGHT := 6.0
const APPROACH_DISTANCE := 1.65
const PASSAGE_CLEARANCE := .76
const RETURN_EDGE := 1.15
const CEILING_LINE := 5.67
const ALONG_X := Vector3(0,0,PI*.5)
const TERMINAL_OFFSET := Vector3(-1.02,2.91,.54)

@export var pole: Pole = Pole.RED
@export var arrival := false
@export var sealed := false
@export var return_length := 4.0
@export var service_housing := false
@export var low_profile := false

var steel: ShaderMaterial
var actor: CharacterBody3D
var barrier: CollisionShape3D
var live_field: Node3D
var passable := false
var doorway: Node3D
var field_material: ShaderMaterial
var field_indicator: ShaderMaterial
var field_halos: Array[ShaderMaterial] = []
var field_strength := 1.0
var feed_strength := 1.0
var restart_age := -1.0
var returning := false
var passage_direction := 1.0
var clear_of_return := true

func _ready() -> void:
	if not steel:
		steel = Kit.bulkhead_paint()
	var direction := -passage_direction if arrival else passage_direction
	var portal := Node3D.new()
	doorway = portal
	portal.rotation.y = deg_to_rad(-52.0 * direction)
	add_child(portal)
	if service_housing:
		_build_service_housing(portal,direction)
	else:
		_build_partition(portal,direction)
	_build_passage(direction)
	_build_frame(portal)
	if not service_housing:
		_build_return(direction)
	_add_blocker(portal,"BulkheadCollision",OPENING_HEIGHT,WALL_HEIGHT)
	if arrival and not sealed:
		set_physics_process(false)
		set_process(false)
		return
	if not arrival and not service_housing:
		_build_ceiling_joint(portal,direction)
	barrier = _add_blocker(portal,"ShieldCollision",0,OPENING_HEIGHT)
	_build_field(portal,field_color())

func field_color() -> Color:
	if sealed:
		return Color("f4faff")
	return Color("ff5548") if pole == Pole.RED else Color("59baff")

func open_for_return() -> void:
	returning = true
	clear_of_return = false
	_set_passable(true)

func power_terminal() -> Vector3:
	return doorway.to_global(TERMINAL_OFFSET)

func _build_service_housing(portal: Node3D, direction: float) -> void:
	var kit := Kit.new(portal,steel)
	if low_profile:
		kit.box(Vector3(0,2.37,0),Vector3(2.85,.30,.64),SHADOW)
		kit.plate(Vector3(0,2.44,.35),Vector3(1.21,.26,.13),EDGE.darkened(.28))
		for side in [-1.0,1.0]:
			var x := float(side)*1.52
			kit.plate(Vector3(x,1.14,0),Vector3(.28,2.29,.68),STRUCTURAL_STEEL)
		kit.finish()
		_build_service_return(direction,2.39)
		return
	var paint := Color("4d5858")
	var brace := Color("6e6d5e")
	kit.box(Vector3(0,2.87,0),Vector3(3.52,1.62,.72),paint)
	kit.plate(Vector3(0,2.96,.40),Vector3(2.93,1.18,.19),SHADOW)
	kit.box(Vector3(0,3.62,.34),Vector3(3.77,.16,.43),brace)
	kit.box(Vector3(0,2.36,.38),Vector3(3.41,.10,.23),brace)
	for y in [2.67,2.81,2.95,3.09,3.23]:
		kit.box(Vector3(0,y,.519),Vector3(1.76,.043,.085),paint)
	for side in [-1.0,1.0]:
		var x := float(side)*1.52
		kit.plate(Vector3(x,1.10,0),Vector3(.58,2.20,.86),paint)
		kit.plate(Vector3(x,.18,.27),Vector3(.57,.35,.53),brace)
		kit.box(Vector3(x,1.13,.44),Vector3(.089,1.46,.08),brace)
		for y in [.44,1.83,3.28]:
			kit.cylinder(Vector3(x,y,.55),Vector3(.094,.048,.094),EDGE,Vector3(PI*.5,0,0))
	kit.finish()
	_build_service_return(direction,3.4)

func _build_service_return(direction: float, height: float) -> void:
	var paint := Color("4d5858")
	var brace := Color("6e6d5e")
	var cheek := Kit.new(self,steel)
	var width := return_length-RETURN_EDGE
	var center := direction*(RETURN_EDGE+width*.5)
	# This cheek sits directly on the deck and hides Miko as he clears the threshold.
	cheek.box(Vector3(center,height*.5,1.67),Vector3(width,height,.77),SHADOW)
	cheek.box(Vector3(center,height-.04,1.67),Vector3(width+.11,.17,.83),brace)
	cheek.box(Vector3(center,.21,1.68),Vector3(width+.11,.32,.85),paint)
	var bays := maxi(1,roundi(width/1.4))
	var span := width/float(bays)
	for index in range(bays):
		var x := direction*(RETURN_EDGE+(float(index)+.5)*span)
		_wall_panel(cheek,Vector3(x,1.31,2.065),Vector2(span-.14,1.68),paint)
		if not low_profile:
			cheek.plate(Vector3(x,2.68,2.07),Vector3(span-.14,.62,.16),paint)
	cheek.finish()

func _build_partition(portal: Node3D, direction: float) -> void:
	var kit := Kit.new(portal,steel)
	var center := -.94*direction
	var overhead := WALL_HEIGHT-OPENING_HEIGHT
	kit.box(Vector3(center,OPENING_HEIGHT+overhead*.5,0),Vector3(6.08,overhead,.52),WALL)
	kit.box(Vector3(center,3.29,.276),Vector3(6.08,.095,.065),EDGE.darkened(.31))
	for side in [-1.0,1.0]:
		var wing := float(side)
		var edge := center+wing*3.04
		var jamb := wing*OPENING_WIDTH*.5
		var span := absf(edge-jamb)
		var x := (edge+jamb)*.5
		kit.box(Vector3(x,OPENING_HEIGHT*.5,0),Vector3(span,OPENING_HEIGHT,.52),WALL)
		_wall_panel(kit,Vector3(x,1.06,.32),Vector2(span-.14,1.67),PAINT)
		_wall_panel(kit,Vector3(x,4.31,.32),Vector2(span-.14,1.58),STRUCTURAL_STEEL)
		var post_x := edge-wing*.11
		kit.plate(Vector3(post_x,2.88,.31),Vector3(.23,5.72,.23),STRUCTURAL_STEEL)
		kit.plate(Vector3(post_x,5.39,.46),Vector3(.43,.58,.16),EDGE.darkened(.19))
	var housing_x := -direction*1.02
	kit.box(Vector3(housing_x,2.76,.31),Vector3(.13,.81,.13),SHADOW)
	kit.box(Vector3(housing_x*.5,2.40,.31),Vector3(absf(housing_x),.10,.13),SHADOW)
	kit.plate(Vector3(housing_x,2.91,.36),Vector3(.51,.41,.23),SHADOW)
	kit.plate(Vector3(housing_x,2.91,.50),Vector3(.43,.34,.09),PAINT)
	for index in range(3):
		kit.box(Vector3(housing_x,2.82+float(index)*.085,.55),Vector3(.30,.038,.027),SHADOW)
	kit.finish()

func _build_passage(direction: float) -> void:
	var kit := Kit.new(self,steel)
	var depth := return_length+.74
	var center := direction*(depth*.5-.74)
	kit.box(Vector3(center,1.09,-.96),Vector3(depth,2.18,.30),Color("171e20"))
	kit.box(Vector3(center,.21,-.789),Vector3(depth,.14,.064),Color("282d2a"))
	kit.box(Vector3(center,1.70,-.77),Vector3(depth,.068,.091),Color("34342a"))
	kit.plate(Vector3(direction*.53,.93,-.78),Vector3(1.40,1.18,.096),Color("212724"))
	kit.finish()

func _build_frame(portal: Node3D) -> void:
	var kit := Kit.new(portal,steel)
	var half := OPENING_WIDTH*.5
	var bevel := .29
	var header_y := OPENING_HEIGHT+.14
	var upright_y := header_y-bevel
	kit.box(Vector3(0,.018,0),Vector3(OPENING_WIDTH+.50,.036,.70),PAINT)
	kit.box(Vector3(0,.039,0),Vector3(OPENING_WIDTH-.10,.012,.44),SHADOW)
	kit.box(Vector3(0,header_y,0),Vector3(OPENING_WIDTH-2.0*bevel,.29,.81),SHADOW)
	for side in [-1.0,1.0]:
		var sign_x := float(side)
		var jamb := sign_x*(half+.14)
		var corner := sign_x*(half+.14-bevel*.5)
		var diagonal := Vector3(0,0,-sign_x*PI*.25)
		kit.box(Vector3(jamb,upright_y*.5,0),Vector3(.30,upright_y,.81),SHADOW)
		kit.box(Vector3(corner,header_y-bevel*.5,0),Vector3(bevel*sqrt(2.0)+.13,.29,.81),SHADOW,false,diagonal)
		for face in [-1.0,1.0]:
			var z := float(face)*.43
			kit.box(Vector3(jamb,upright_y*.5,z),Vector3(.20,upright_y-.03,.076),STRUCTURAL_STEEL)
			kit.box(Vector3(corner,header_y-bevel*.5,z),Vector3(bevel*sqrt(2.0)+.08,.18,.076),STRUCTURAL_STEEL,false,diagonal)
			kit.box(Vector3(jamb-sign_x*.063,.98,z*1.10),Vector3(.034,1.46,.023),EDGE)
			for y in [.19,1.72]:
				kit.cylinder(Vector3(jamb,y,z*1.10),Vector3(.079,.039,.079),EDGE,Vector3(PI*.5,0,0))
		kit.box(Vector3(sign_x*(half-.026),.97,0),Vector3(.045,1.59,.15),EDGE.darkened(.41))
	for face in [-1.0,1.0]:
		var z := float(face)*.43
		kit.box(Vector3(0,header_y,z),Vector3(OPENING_WIDTH-2.0*bevel,.19,.076),PAINT)
		kit.plate(Vector3(0,header_y,z*1.13),Vector3(.48,.14,.074),SHADOW)
		kit.box(Vector3(0,header_y,z*1.23),Vector3(.22,.034,.016),Color("938976") if not arrival else Color("a9beab"),true)
	kit.finish()

func _build_return(direction: float) -> void:
	var kit := Kit.new(self,steel)
	var width := return_length-RETURN_EDGE
	var center := direction*(RETURN_EDGE+width*.5)
	# The return joins the near jamb and hides Miko as he clears the threshold.
	kit.box(Vector3(center,2.95,1.91),Vector3(width,6.10,.74),WALL)
	kit.box(Vector3(direction*(RETURN_EDGE+.10),2.95,2.32),Vector3(.20,6.10,.18),STRUCTURAL_STEEL)
	kit.box(Vector3(center,3.29,2.30),Vector3(width,.095,.085),EDGE.darkened(.31))
	kit.box(Vector3(center,.14,2.31),Vector3(width,.28,.14),PAINT)
	var panel_count := maxi(1,roundi(width/1.65))
	var span := width/float(panel_count)
	for index in range(panel_count):
		var x := direction*(RETURN_EDGE+(float(index)+.5)*span)
		_wall_panel(kit,Vector3(x,1.68,2.32),Vector2(span-.18,2.79),PAINT)
		_wall_panel(kit,Vector3(x,4.31,2.32),Vector2(span-.18,1.58),STRUCTURAL_STEEL)
	kit.finish()

func _wall_panel(kit: Kit, at: Vector3, size: Vector2, color: Color) -> void:
	kit.plate(at,Vector3(size.x,size.y,.15),SHADOW)
	kit.plate(at+Vector3(0,.018,.064),Vector3(size.x-.09,size.y-.09,.091),color)
	for side in [-1.0,1.0]:
		for end in [-1.0,1.0]:
			var bolt := at + Vector3(float(side)*(size.x*.35-.013),float(end)*(size.y*.34),.12)
			kit.cylinder(bolt,Vector3(.09,.026,.09),SHADOW,Vector3(PI*.5,0,0))
			kit.cylinder(bolt+Vector3(0,0,.018),Vector3(.052,.022,.052),EDGE,Vector3(PI*.5,0,0))

func _build_ceiling_joint(portal: Node3D, direction: float) -> void:
	var kit := Kit.new(portal,steel)
	var width := 6.08
	var center := -.94*direction
	_ceiling_collar(kit,center,width,.28)
	kit.finish()
	var returned := Kit.new(self,steel)
	var return_width := return_length-RETURN_EDGE
	_ceiling_collar(returned,direction*(RETURN_EDGE+return_width*.5+.06),return_width-.12,2.30)
	# Bridge the angle change with a deeper saddle on top of the corner post.
	var corner := direction*(RETURN_EDGE+.06)
	returned.box(Vector3(corner,5.75,2.03),Vector3(.24,.50,1.12),SHADOW)
	returned.plate(Vector3(corner,5.68,2.58),Vector3(.24,.48,.13),STRUCTURAL_STEEL)
	returned.finish()

func _ceiling_collar(kit: Kit, center: float, width: float, face: float) -> void:
	# The coved seat overlaps the ceiling deck and flares out into its underside.
	kit.box(Vector3(center,5.84,face-.06),Vector3(width,.37,.76),SHADOW)
	kit.box(Vector3(center,CEILING_LINE,face+.10),Vector3(width,.30,.42),STRUCTURAL_STEEL,false,Vector3(-.53,0,0))
	kit.box(Vector3(center,5.82,face+.29),Vector3(width,.15,.16),EDGE.darkened(.18))
	kit.box(Vector3(center,5.51,face+.03),Vector3(width,.054,.22),PAINT)
	kit.cylinder(Vector3(center,5.43,face+.03),Vector3(.078,width,.078),SHADOW,ALONG_X)
	var fasteners := maxi(2,roundi(width/1.5)+1)
	for index in range(fasteners):
		var x := center + lerpf(-width*.5+.12,width*.5-.12,float(index)/float(fasteners-1))
		kit.plate(Vector3(x,5.67,face+.15),Vector3(.20,.57,.32),STRUCTURAL_STEEL)
		kit.cylinder(Vector3(x,5.62,face+.32),Vector3(.069,.037,.069),EDGE,Vector3(PI*.5,0,0))

func _add_blocker(portal: Node3D, label: String, bottom: float, top: float) -> CollisionShape3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position.y = (bottom+top)*.5
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(OPENING_WIDTH,top-bottom,.35)
	collider.shape = shape
	body.add_child(collider)
	portal.add_child(body)
	return collider

func _build_field(portal: Node3D, tint: Color) -> void:
	live_field = Node3D.new()
	live_field.name = "LiveField"
	portal.add_child(live_field)
	field_material = ShaderMaterial.new()
	field_material.shader = preload("res://shaders/lab_polarity_shield.gdshader")
	field_material.set_shader_parameter("pole_color",tint)
	var kit := Kit.new(live_field)
	kit.quad(Vector3(0,OPENING_HEIGHT*.5,0),Vector2(OPENING_WIDTH,OPENING_HEIGHT-.04),field_material)
	field_indicator = ShaderMaterial.new()
	field_indicator.shader = preload("res://shaders/lab_service_lamp.gdshader")
	field_indicator.set_shader_parameter("tint",tint)
	for side in [-1.0,1.0]:
		for y in [.40,.91,1.44]:
			kit.quad(Vector3(float(side)*(OPENING_WIDTH*.5-.043),y,.041),Vector2(.030,.18),field_indicator)
	for face in [-1.0,1.0]:
		var rotation := Vector3(0,PI if face < 0.0 else 0.0,0)
		kit.quad(Vector3(0,OPENING_HEIGHT+.14,float(face)*.555),Vector2(.22,.034),field_indicator,rotation)
	for effect in [
		[Vector3(0,.053,.06),Vector2(2.30,1.34),Vector3(-PI*.5,0,0)],
		[TERMINAL_OFFSET+Vector3(0,0,.04),Vector2(.67,.49),Vector3.ZERO]
	]:
		var glow := ShaderMaterial.new()
		glow.shader = preload("res://shaders/lab_halo.gdshader")
		glow.set_shader_parameter("light_color",tint)
		glow.set_shader_parameter("energy",.35)
		kit.quad(effect[0],effect[1],glow,effect[2])
		field_halos.append(glow)

func _physics_process(_delta: float) -> void:
	if sealed or not is_instance_valid(actor):
		return
	var relative := to_local(actor.global_position)
	relative.x *= passage_direction
	if returning:
		if relative.x > -PASSAGE_CLEARANCE:
			return
		returning = false
		_set_passable(false)
		return
	if not clear_of_return:
		clear_of_return = relative.x < -APPROACH_DISTANCE
		return
	var opposite: bool = actor.suit_polarity != 0 and actor.suit_polarity != pole
	var in_opening := relative.y >= -.14 and relative.y < OPENING_HEIGHT
	var approaching := relative.x >= -APPROACH_DISTANCE and relative.x < 0.0
	# Hold an open field until the body clears it, even if the suit charge changes.
	var crossing := passable and absf(relative.x) < PASSAGE_CLEARANCE
	var should_pass := crossing or (in_opening and approaching and opposite)
	if should_pass != passable:
		_set_passable(should_pass)

func _set_passable(value: bool) -> void:
	passable = value
	barrier.set_deferred("disabled",passable)
	restart_age = -1.0 if passable else 0.0

func _process(delta: float) -> void:
	if passable and is_zero_approx(feed_strength) and is_zero_approx(field_strength):
		return
	if not passable and restart_age < 0.0:
		return
	var surge := -1.0
	if passable:
		feed_strength = move_toward(feed_strength,0.0,delta*7.0)
		field_strength = move_toward(field_strength,0.0,delta*9.0)
	else:
		restart_age += delta
		surge = clampf(restart_age/RESTART_TRAVEL,0.0,1.0)
		feed_strength = move_toward(feed_strength,1.0,delta*3.5)
		var ramp := smoothstep(.19,RESTART_TRAVEL+FIELD_RAMP,restart_age)
		field_strength = move_toward(field_strength,ramp,delta*5.0)
	var light := field_strength
	if restart_age >= 0.0:
		var arrive := smoothstep(RESTART_TRAVEL-.10,RESTART_TRAVEL,restart_age)
		light += arrive*(1.0-smoothstep(RESTART_TRAVEL,RESTART_TRAVEL+.23,restart_age))*.66
	live_field.visible = field_strength > .001
	field_material.set_shader_parameter("field_strength",field_strength)
	field_indicator.set_shader_parameter("lamp_power",field_strength)
	for halo in field_halos:
		halo.set_shader_parameter("energy",light*.38)
	power_visuals.emit(feed_strength,light,surge if restart_age <= RESTART_TRAVEL else -1.0)
	if restart_age >= RESTART_TRAVEL+FIELD_RAMP and field_strength >= .999:
		restart_age = -1.0
