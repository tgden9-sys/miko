extends Node3D
## Authored layouts. Coordinates are in metres; all obstacles share the walk lane.
const MOVEMENT_LENGTH := 250.0
const COOLING_PLOTS := [68.0, 134.0, 180.0, 234.0]
const TOWER := preload("res://scripts/miko8_platform_tower.gd")
const BRIDGE_DECK := preload("res://models/environment/bridge_platforms/deck.glb")
var stage:=1
var canister:Area3D
var switch:Node3D
var shutter:Node3D
var wall_pad:Node3D
var ceiling_pad:Node3D
var cargo:RigidBody3D
var launcher:Node3D
var practice_crate:RigidBody3D
var switch_crate:RigidBody3D
var woods:Array[Node3D]=[]
var yard:Node3D
var extra_shutters:Array[Node3D]=[]

func _ready()->void:
	name="TutorialCourse"
	if stage > 3: return
	yard=preload("res://scripts/miko8_yard_props.gd").new();yard.build_demo=false;add_child(yard)
	match stage:
		1:_movement()
		2:_magnetism()
		3:_power()
	var weeds:=preload("res://scripts/miko8_yard_foliage.gd").new()
	var verge: Array[float] = [7.4,12.2,18.4,26.2,33.6,39.5,44.2,50.1,56.8,61.7,67.2,72.,79.,87.3,98.,108.,119.,130.2,142.,153.,163.,171.]
	for x: float in verge:
		if stage == 1 and x > MOVEMENT_LENGTH - 2.0:
			break
		for offset:float in [-.16,0.,.19]:weeds.custom_locations.append(Vector3(x+offset,.012,1.05))
	add_child(weeds)

func _movement()->void:
	# The complete route and recovery graph are documented in Docs/LEVEL1_REBUILD.md.
	for x:float in [14.,22.,80.,87.]:_secured_cargo(x)
	_service_roof("IntakeAccess",30.,38.,3.0)
	_service_roof("IntakeMiddle",40.,48.,3.0)
	_service_roof("IntakeExit",50.,58.,3.35)
	_crossing(68.,3.0)
	_service_roof("CableWest",94.,103.,3.8)
	_service_roof("CableMiddle",105.,114.,3.8)
	_service_roof("CableEast",115.8,123.8,4.15)
	_crossing(134.,3.8)
	# Optional precision route connects to the next building. Ground access
	# remains a deliberate recovery route; the required first climb is solid.
	for data:Array in [[146.,0,true],[149.6,0,false],[153.3,1,false],[157.,1,false],[161.,2,true]]:
		_movement_tower("TransferTower%d"%int(data[0]),data[0],data[1],data[2])
	_service_roof("TowerTerminal",163.,171.,4.3)
	_crossing(180.,3.8)
	_service_roof("CellApproach",196.,204.,4.0)
	_service_roof("CellBridge",206.1,214.1,4.3)
	_service_roof("CellTerminal",216.,224.,4.3)
	_collectible(Vector3(221.,4.31,0))
	_crossing(234.,2.8)

func _secured_cargo(x:float)->void:
	var crate:=_crate(Vector3(x,.4,0))
	crate.name="SecuredCargo%d"%int(x)
	crate.freeze=true;crate.suit_movable=false;crate.block_movable=false
	crate.set_meta("budget_always_simulate",true)
	# These bolted transport cases teach jumping, not the next stage's magnets.
	crate.remove_from_group("miko8_charge_targets")
	var patch:=MeshInstance3D.new();var plate:=BoxMesh.new();plate.size=Vector3(.92,.045,.94)
	patch.mesh=plate;patch.position.y=-.38;patch.layers=4
	var metal:=StandardMaterial3D.new();metal.albedo_color=Color("333c3f");metal.roughness=.9;patch.material_override=metal;crate.add_child(patch)

func _service_roof(label:String,left:float,right:float,height:float)->void:
	var building:=_block(label,Vector3((left+right)*.5,0,-.35),Vector3(right-left,height,2.55))
	_side_access(label, left, height, -1)
	_side_access(label, right, height, 1)
	building.set_meta("tutorial_roof",true)
	if label=="TowerTerminal":building.set_meta("walk_lane_z",0.)

func _side_access(label: String, wall_x: float, height: float, side: int) -> void:
	var ladder := preload("res://scripts/miko8_ladder.gd").new()
	ladder.name = label + ("WestAccess" if side < 0 else "EastAccess")
	ladder.side_mount = true
	ladder.rotation.y = side * PI * .5
	ladder.position = Vector3(wall_x + side * .12, 0, 0)
	ladder.height = height
	ladder.above_platform = 0.
	ladder.curved_top = true
	ladder.extended_rungs = false
	ladder.gameplay_detail = stage == 4
	ladder.rung_spacing = .2648
	ladder.rung_offset = -.08
	ladder.rail_half_width = .28
	ladder.dismount_side = -side
	ladder.set_meta("bpg_ladder", true)
	ladder.set_meta("direct_entry", true)
	add_child(ladder)
	# Paired steel receivers carry the standoffs into the side wall.
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("343f42")
	steel.roughness = .8
	for z: float in [-ladder.rail_half_width, ladder.rail_half_width]:
		var rail := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(.025, height - .2, .075)
		rail.mesh = box
		rail.position = Vector3(wall_x + side * .01, height * .5, z)
		rail.material_override = steel
		rail.layers = 4
		rail.add_to_group("miko8_budget_visual")
		rail.set_meta("budget_half_width", 2.0)
		add_child(rail)
	var sign := Label3D.new()
	sign.text = "SERVICE ACCESS"
	sign.font_size = 36
	sign.pixel_size = .0035
	sign.position = Vector3(wall_x + side * .024, 1.55, -.58)
	sign.rotation.y = side * PI * .5
	sign.modulate = Color("b7c8bf")
	sign.outline_size = 4
	sign.add_to_group("miko8_budget_visual")
	sign.set_meta("budget_half_width", 2.0)
	add_child(sign)

func _movement_tower(label: String, x: float, variant: int, has_ladder: bool) -> void:
	var tower := TOWER.new()
	tower.name = label
	tower.position.x = x
	tower.variant = variant
	tower.deck_height = [2.8, 3.55, 4.3][variant]
	tower.front_ladder = has_ladder
	tower.reverse_face = not has_ladder
	add_child(tower)

func _movement_bridge(west_tower: float, east_tower: float, height: float) -> void:
	var span := east_tower - west_tower - 1.92 + .04
	var deck := StaticBody3D.new()
	deck.name = "GantrySpan%d" % int(west_tower)
	deck.position = Vector3((west_tower + east_tower) * .5, height, TOWER.CENTRE_Z)
	add_child(deck)

	var model: Node3D = BRIDGE_DECK.instantiate()
	# The source deck surface sits .44156 m above the model origin.
	model.position.y = -.44156
	model.scale = Vector3(span / (2.5 / 1.30), 1., 1.75)
	deck.add_child(model)
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 4

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(span, .14, 1.54)
	collision.shape = shape
	collision.position.y = -.07
	deck.add_child(collision)

func _magnetism()->void:
	practice_crate=_crate(Vector3(14.,.4,0))
	_crate(Vector3(17.,.4,0))
	# A wall magnet on the left face of a low service housing, at crate height.
	_block("MagnetHousing",Vector3(24.,0,-.25),Vector3(2.4,1.15,2.1))
	wall_pad=preload("res://scripts/miko8_wall_mag_pad.gd").new()
	wall_pad.position=Vector3(22.8,.65,0);wall_pad.rotation.y=PI;wall_pad.scale=Vector3.ONE*.75;add_child(wall_pad)
	# This low housing can be jumped after experimenting with the pad.
	switch_crate=_crate(Vector3(31.,.4,0))
	switch=preload("res://scenes/reusable_pressure_switch.tscn").instantiate();switch.position.x=35.;add_child(switch)
	shutter=preload("res://scripts/miko8_tutorial_shutter.gd").new();shutter.position.x=40.;shutter.refined=true;add_child(shutter)
	switch.pressed_changed.connect(shutter.set_open)
	# Existing overhang artwork, complete with its fitted ceiling pad and heavy cargo.
	var bay:=preload("res://scripts/miko8_overhang_bay.gd").new()
	# Turn the cantilever across the walkway: its support is behind the lane,
	# not a solid wall blocking the player after walking underneath the cargo.
	bay.rotation.y=PI*.5;bay.position=Vector3(54.2,0,69.2);add_child(bay)
	ceiling_pad=bay.get_node("CeilingMagPad");cargo=bay.get_node("HeavyCargo")
	# Repeat with less scaffolding: transport a crate, then solve a two-plate lock.
	_crate(Vector3(68.,.4,0));_pressure_gate(75.,80.)
	_crossing(88.,2.8)
	_crate(Vector3(96.,.4,0));_crate(Vector3(99.,.4,0))
	_pressure_gate(104.,114.,109.)
	_lift_bay(124.)
	_crate(Vector3(135.,.4,0));_pressure_gate(141.,147.)
	_lift_bay(156.)
	_collectible(Vector3(163.,0,0))

func _power()->void:
	# Two rows make the obstruction taller than an ordinary jump.
	for x:float in [15.,16.]:
		for y:float in [0.,.8]:_wood(Vector3(x,y,0))
	for y:float in [0.,.8,1.6]:_wood(Vector3(30.,y,0))
	practice_crate=_crate(Vector3(35.,.4,0))
	launcher=yard.add_launcher(Vector3(48.5,-.12,0)).get_node("ChargeTarget")
	_block("LauncherLanding",Vector3(53.5,0,-.35),Vector3(6.,2.8,2.55))
	_crossing(65.)
	for x:float in [75.,77.,79.]:
		for y:float in [0.,.8,1.6]:_wood(Vector3(x,y,0))
	yard.add_launcher(Vector3(87.5,-.12,0))
	_block("HighDeckB",Vector3(92.5,0,-.35),Vector3(6.,3.,2.55))
	_block("HighDeckLanding",Vector3(99.,0,-.35),Vector3(3.2,2.7,2.55))
	_side_access("HighDeckLanding", 97.4, 2.7, -1)
	_crate(Vector3(108.,.4,0));_pressure_gate(113.,119.)
	_lift_bay(130.)
	for x:float in [140.,142.]:
		for y:float in [0.,.8,1.6]:_wood(Vector3(x,y,0))
	yard.add_launcher(Vector3(151.5,-.12,0))
	_block("CellRoof",Vector3(156.5,0,-.35),Vector3(6.,3.05,2.55))
	_collectible(Vector3(157.,3.06,0))
	_crossing(166.,3.)

func _lift_bay(x:float)->void:
	var bay:=preload("res://scripts/miko8_overhang_bay.gd").new()
	bay.rotation.y=PI*.5;bay.position=Vector3(x,0,69.2);add_child(bay)

func _pressure_gate(plate_x:float,gate_x:float,second_plate_x:=-1.)->void:
	var plate:=preload("res://scenes/reusable_pressure_switch.tscn").instantiate();plate.position.x=plate_x;add_child(plate)
	var gate:=preload("res://scripts/miko8_tutorial_shutter.gd").new();gate.position.x=gate_x;gate.refined=stage>=2;gate.conduit_length=gate_x-plate_x;add_child(gate);extra_shutters.append(gate)
	if second_plate_x<0.:
		plate.pressed_changed.connect(gate.set_open)
	else:
		var second:=preload("res://scenes/reusable_pressure_switch.tscn").instantiate();second.position.x=second_plate_x;add_child(second)
		plate.pressed_changed.connect(func(_on:bool):gate.set_open(plate.pressed and second.pressed))
		second.pressed_changed.connect(func(_on:bool):gate.set_open(plate.pressed and second.pressed))

func _base(x:float)->void:
	var base:=preload("res://scripts/miko8_charge_base.gd").new();base.position=Vector3(x,.4,0);add_child(base)

func _crate(at:Vector3)->RigidBody3D:
	var crate:=preload("res://scripts/miko8_charge_box.gd").new();crate.position=at;add_child(crate);return crate

func _wood(at:Vector3)->void:
	var crate:StaticBody3D=yard._prop("WoodenCrate","res://models/props/wooden_crate.glb",at,Vector3(.8,.8,.8))
	crate.settle_stack=true;woods.append(crate)

func _block(label:String,at:Vector3,size:Vector3)->Node3D:
	var block:=preload("res://scenes/reusable_plain_block.tscn").instantiate()
	block.name=label;block.dimensions=size;block.position=at;add_child(block);return block

func _crossing(x:float,length:=2.2)->void:
	var crossing := preload("res://scenes/reusable_cooling_station.tscn").instantiate()
	crossing.position.x = x
	crossing.passage_length = length
	if stage <= 3:
		crossing.include_building = true
		crossing.wall_z = -2.0
	add_child(crossing)

func _collectible(at:Vector3)->void:
	canister=preload("res://scripts/miko8_collectible_canister.gd").new();canister.position=at;add_child(canister)

func reset_course()->void:
	if shutter:shutter.reset_shutter()
	for gate in extra_shutters:gate.reset_shutter()
