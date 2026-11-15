extends "res://scripts/lab_dressing.gd"

const WALL_Z := -3.04
const RECESS_Z := -6.0
const HATCH := 0
const INTAKE := 1
const TRANSFORMER := 2
const STRUCTURE := Color("333d43")
const RECESSED_STEEL := Color("273338")
const PILOT := Color("8bc6bd")
var custom_panels: Array[StandardMaterial3D] = []
var recessed_panels: Array[StandardMaterial3D] = []

func _build_layout() -> void:
	_load_custom_panels()
	_build_shell()
	_panel("ArrivalHatch",0,4,-.2,5.8,HATCH)
	_hall("Arrival",4,16,0,[Machine.EMPTY,Machine.PUMP])
	_hall("PumpApproach",16,32,0,[Machine.PISTON,Machine.EMPTY])
	_hall("CoolantReturn",14,34,6,[Machine.FAN,Machine.EMPTY,Machine.PRESSURE])
	# The hall only starts above a real deck. The west lift has one continuous
	# shaft wall through the opening beside the upper exchange.
	var west_lift := Rect2(0,5.8,14,12)
	_shaft_wall("WestLift",0,10,5.8,17.8,west_lift)
	_shaft_wall("WestLiftReturn",10,14,5.8,11.8,west_lift)
	_hall("UpperExchange",10,25,12,[Machine.VALVES,Machine.EMPTY])
	_hall("UpperTransfer",25,50,12,[Machine.PISTON,Machine.EMPTY,Machine.FAN])
	# The gallery overlaps the upper left of the shaft and hides that corner
	# of the continuous backdrop at a separate depth.
	_fitted_panel("PumpStair", Rect2(32,-8.2,11,20), preload("res://art/relay_pump_stair.png"), .5, -3.16)
	_intake_chamber("Cascade",50,62,-5.0,17.8)
	_intake_chamber("CascadeReturn",62,69,5.8,17.8,TRANSFORMER)
	_hall("LowerService",62,73,0,[Machine.PUMP,Machine.EMPTY])
	_shaft_wall("ServiceStair",73,79,-3.5,9.8)
	_hall("DistributionGallery",79,96,4,[Machine.EMPTY,Machine.VALVES])
	_fitted_panel("DistributionPlenum", Rect2(79,9.8,17,9.2), preload("res://art/relay_distribution_plenum.png"), 1.0)
	_fitted_panel("DistributionUndercroft", Rect2(79,-5.8,17,9.6), preload("res://art/relay_distribution_undercroft.png"), 0.0)
	_panel("SwitchyardDrop",96,102,-.2,11.8,INTAKE)
	_fitted_panel("SwitchyardDropSump", Rect2(96,-8.2,6,8), preload("res://art/relay_switchyard_sump.png"), 0.0)
	_panel("SwitchyardTransformer",102,113,-.2,5.8,TRANSFORMER)
	_hall("SwitchyardAccess",113,119,0,[Machine.PRESSURE])
	var east_riser := Rect2(119,-3.5,11,15.3)
	_shaft_wall("EastRiser",121,130,-3.5,11.8,east_riser)
	_shaft_wall("RiserFoot",119,121,-3.5,5.8,east_riser)
	_panel("RelayVault",102,108,5.8,11.8,HATCH)
	_hall("RelayMezzanine",108,121,6,[Machine.EMPTY,Machine.VALVES])
	_pump_stair_jamb()
	_bent("GalleryJamb",14,5.8,11.8,.32)
	_bent("LiftHeadJamb",10,11.8,17.8,.36)
	_bent("ServiceJamb",73,-.7,5.8,.38)
	_bent("DistributionJamb",79,3.8,9.8,.34)
	_bent("SwitchyardJamb",102,5.8,11.8,.36)
	_bent("EastRiserJamb",121,5.8,11.8,.34)
	_bent("RiserFootJamb",119,-.5,5.8,.32)
	_overhead_structure()
	_room_threshold("ArrivalThreshold",16.0,0.0)
	_room_threshold("CascadeThreshold",45.2,12.0)
	_underdeck("ArrivalFooting",0,32,0,4.2)
	_underdeck("ServiceFooting",62,73,0,3.4)
	_underdeck("SwitchyardFooting",101,119,0,4.1)
	_closure("WestEndReturn",-.45,-5.0,22.0,1.0)
	_closure("EastEndReturn",130.45,-5.0,17.0,-1.0)
	_sign("PumpRoute",30.2,2.45,"PUMP STAIR  ›")
	_sign("CoolantRoute",32.1,8.45,"‹  COOLANT GALLERY")
	_sign("UpperRoute",12.6,14.45,"UPPER EXCHANGE  ›")
	_sign("CascadeRoute",48.1,14.45,"CASCADE  ›")
	_sign("DistributionRoute",94.0,6.45,"SWITCHYARD  ›")
	_sign("RiserRoute",116.6,2.45,"EAST RISER  ›")
	_sign("RelayRoute",114.7,8.45,"‹  NETWORK RELAY")

func _load_custom_panels() -> void:
	var atlas := preload("res://art/relay_works_panels.png")
	var padding := Vector2(4,4) / Vector2(atlas.get_size())
	for slot in range(3):
		var material := _scenery_material(atlas)
		material.uv1_scale = Vector3(1.0/3.0-2.0*padding.x,1.0-2.0*padding.y,1)
		material.uv1_offset = Vector3(slot/3.0+padding.x,padding.y,0)
		custom_panels.append(material)
		var recessed := material.duplicate() as StandardMaterial3D
		recessed.albedo_color = Color(.72,.82,.84)
		recessed_panels.append(recessed)

func _panel(label: String, left: float, right: float, bottom: float, top: float, panel: int, depth := WALL_Z) -> void:
	var kit := _section(label,Vector3((left+right)*.5,(bottom+top)*.5,depth))
	var materials := custom_panels if depth == WALL_Z else recessed_panels
	kit.quad(Vector3.ZERO,Vector2(right-left,top-bottom),materials[panel])

func _fitted_panel(label: String, bounds: Rect2, texture: Texture2D, vertical_anchor := .5, depth := WALL_Z) -> void:
	var material := _scenery_material(texture)
	var texture_size := Vector2(texture.get_size())
	var fill_scale := maxf(bounds.size.x / texture_size.x, bounds.size.y / texture_size.y)
	# Sample the opening from a uniformly scaled image. A small crop anchors
	# the important edge to the wall seam even if the image ratio differs.
	var visible_uv := bounds.size / (texture_size * fill_scale)
	material.uv1_scale = Vector3(visible_uv.x, visible_uv.y, 1.0)
	material.uv1_offset = Vector3((1.0 - visible_uv.x) * .5, (1.0 - visible_uv.y) * vertical_anchor, 0.0)
	var center := bounds.get_center()
	var kit := _section(label, Vector3(center.x, center.y, depth))
	kit.quad(Vector3.ZERO, bounds.size, material)

func _shaft_wall(label: String, left: float, right: float, bottom: float, top: float, full_wall := Rect2()) -> void:
	var kit := _section(label,Vector3((left+right)*.5,(bottom+top)*.5,WALL_Z))
	var size := Vector2(right-left,top-bottom)
	var material := shaft_material
	# Cropped extensions use the same coordinates as the main shaft. Pipes line
	# up across the seam and the gallery can start exactly at its floor edge.
	if full_wall.has_area():
		material = shaft_material.duplicate() as StandardMaterial3D
		material.uv1_scale = Vector3(size.x/full_wall.size.x,size.y/full_wall.size.y,1)
		material.uv1_offset = Vector3((left-full_wall.position.x)/full_wall.size.x,(full_wall.end.y-top)/full_wall.size.y,0)
	kit.quad(Vector3.ZERO,size,material)

func _build_shell() -> void:
	# The open parts of the course are inside a larger building. A distant
	# backing wall and spars keep geometry in frame during jumps and falls.
	var shell_wall := _section("FacilityShell",Vector3(65,7,-12))
	shell_wall.box(Vector3.ZERO,Vector3(174,41,1),Color("202c31"))
	for span in [Vector2(-4,32),Vector2(32,62),Vector2(62,96),Vector2(96,134)]:
		var width: float = span.y-span.x
		var root := _section("ShellSpan",Vector3((span.x+span.y)*.5,0,-10))
		root.box(Vector3(0,-7,0),Vector3(width,.7,1.7),RECESSED_STEEL)
		root.box(Vector3(0,19,0),Vector3(width,.65,2.3),STRUCTURE)
		root.box(Vector3(0,22.2,.6),Vector3(width,.52,1.7),RECESSED_STEEL)
		root.box(Vector3(-width*.5+.4,7,0),Vector3(.8,30,2.3),STRUCTURE)
		root.cylinder(Vector3(0,20.4,.5),Vector3(.5,width,.5),RECESSED_STEEL,ALONG_X)
		root.box(Vector3(-width*.3,20.5,0),Vector3(.4,3.4,1.6),STRUCTURE)
		root.box(Vector3(width*.25,20.5,0),Vector3(.4,3.4,1.6),STRUCTURE)
		root.finish()
	shell_wall.finish()
	_panel("UpperExchangeUndercroft",43,50,-2,11.8,INTAKE,RECESS_Z)
	_panel("UtilityRiser",69,79,5.8,17.8,TRANSFORMER,-8.0)
	_panel("EastRiserSump",118,131,-9,-.2,INTAKE,RECESS_Z)

func _intake_chamber(label: String, left: float, right: float, bottom: float, top: float, panel := INTAKE) -> void:
	_panel(label,left,right,bottom,top,panel,RECESS_Z)
	var width := right-left
	var height := top-bottom
	var kit := _section(label + "Frame",Vector3((left+right)*.5,(bottom+top)*.5,-3.65))
	kit.box(Vector3(-width*.5+.20,0,0),Vector3(.40,height,1.2),STRUCTURE)
	kit.box(Vector3(width*.5-.20,0,0),Vector3(.40,height,1.2),STRUCTURE)
	kit.box(Vector3(0,height*.5-.07,0),Vector3(width,.18,1.2),RECESSED_STEEL)
	kit.cylinder(Vector3(-width*.5+.79,0,-.2),Vector3(.32,height,.32),RECESSED_STEEL)
	kit.cylinder(Vector3(width*.5-.68,0,-.2),Vector3(.21,height,.21),RECESSED_STEEL)
	kit.finish()

func _bent(label: String, x: float, bottom: float, top: float, width: float) -> void:
	var kit := _section(label,Vector3(x,(bottom+top)*.5,-2.95))
	var height := top-bottom
	kit.box(Vector3.ZERO,Vector3(width,height,.42),STRUCTURE)
	kit.box(Vector3(0,0,.23),Vector3(width*.52,height,.08),STEEL)
	kit.box(Vector3(0,height*.5-.15,.28),Vector3(width+.18,.26,.14),STRUCTURE)
	kit.box(Vector3(0,-height*.5+.15,.28),Vector3(width+.18,.26,.14),STRUCTURE)
	kit.finish()

func _underdeck(label: String, left: float, right: float, floor_y: float, height: float) -> void:
	var width := right-left
	var kit := _section(label,Vector3((left+right)*.5,floor_y,0))
	kit.box(Vector3(0,-.32,-.38),Vector3(width,.62,2.4),STRUCTURE)
	kit.box(Vector3(0,-height*.5,-2.9),Vector3(width,height,.45),RECESSED_STEEL)
	kit.cylinder(Vector3(0,-1.12,.05),Vector3(.37,width,.37),STEEL,ALONG_X)
	kit.cylinder(Vector3(0,-1.78,-.35),Vector3(.23,width,.23),RECESSED_STEEL,ALONG_X)
	for fraction in [-.43,-.18,.11,.40]:
		var x := width*float(fraction)
		kit.box(Vector3(x,-height*.5,.05),Vector3(.45,height,.63),STRUCTURE)
		kit.box(Vector3(x,-.55,.41),Vector3(.77,.29,.26),STEEL)
		kit.cylinder(Vector3(x,-1.12,.05),Vector3(.53,.24,.53),STRUCTURE,ALONG_X)
	kit.finish()

func _room_threshold(label: String, x: float, floor_height: float) -> void:
	# The jamb is behind Miko, and the crown stays within the existing
	# overhead space. Dark steel frames the wall join at the room transition.
	var kit := _section(label,Vector3(x,floor_height,0))
	var shadow := Color("20282a")
	var edge := Color("595747")
	kit.box(Vector3(0,2.84,-2.91),Vector3(.49,5.66,.38),shadow)
	kit.box(Vector3(-.20,2.82,-2.69),Vector3(.045,5.61,.08),edge)
	kit.box(Vector3(0,5.67,-.63),Vector3(.67,.26,4.89),shadow)
	kit.box(Vector3(0,5.52,1.77),Vector3(.57,.05,.17),edge)
	kit.box(Vector3(0,5.44,1.69),Vector3(.27,.047,.12),AMBER,true)
	kit.finish()

func _closure(label: String, x: float, bottom: float, top: float, inward: float) -> void:
	var height := top-bottom
	var kit := _section(label,Vector3(x,(bottom+top)*.5,-3.3))
	kit.box(Vector3(-inward*.6,0,0),Vector3(1.9,height,13.0),STRUCTURE)
	kit.box(Vector3(inward*.25,0,.7),Vector3(.65,height,1.5),STEEL)
	kit.cylinder(Vector3(inward*.55,0,-.45),Vector3(.26,height,.26),RECESSED_STEEL)
	kit.finish()

func _overhead_structure() -> void:
	var portal := _section("SwitchyardPortal",Vector3(99.9,5.3,0))
	var shadow := Color("151c20")
	var edge := Color("39413f")
	# The dark side of the roof opening traces the solid lintel. Its recessed
	# return joins the relay wall and leaves the lower passage readable.
	portal.box(Vector3(0,3.35,-.53),Vector3(.65,6.7,5.06),shadow)
	portal.box(Vector3(-.255,3.395,2.025),Vector3(.12,6.61,.05),edge)
	portal.box(Vector3(0,.045,2.025),Vector3(.65,.09,.05),edge)
	portal.box(Vector3(1.18,3.26,-2.74),Vector3(2.43,6.52,.59),shadow)
	portal.box(Vector3(1.18,.135,-2.39),Vector3(2.43,.24,.16),edge)
	portal.box(Vector3(1.16,2.28,-2.41),Vector3(1.94,.055,.08),RECESSED_STEEL)
	portal.box(Vector3(1.16,4.42,-2.41),Vector3(1.94,.055,.08),RECESSED_STEEL)
	portal.finish()
	var roof := _section("SwitchyardRoofTruss",Vector3(113,13.1,-4.2))
	roof.box(Vector3(0,0,0),Vector3(34,.34,1.6),STRUCTURE)
	roof.cylinder(Vector3(0,.78,-.25),Vector3(.38,34,.38),RECESSED_STEEL,ALONG_X)
	for x in [-12.0,-5.0,3.0,10.0,16.0]:
		roof.box(Vector3(x,.6,0),Vector3(.32,1.8,1.2),STEEL)
	roof.finish()

func landing_support(label: String, x: float, y: float, width: float) -> void:
	if label == "PumpLower" or label == "PumpUpper":
		_pump_stair_mount(label,x,y,width)
		return
	# Brackets sit behind the play lane and visibly carry the cantilevered deck.
	var kit := _section(label + "Brackets",Vector3(x,y,-2.56))
	for offset in [-width*.31,width*.31]:
		kit.box(Vector3(offset,-.38,.58),Vector3(.23,.26,1.72),STEEL)
		kit.box(Vector3(offset,-.68,-.21),Vector3(.43,1.06,.23),STRUCTURE)
		kit.box(Vector3(offset,-.74,.49),Vector3(.16,.18,1.52),STRUCTURE,false,Vector3(-.48,0,0))
	kit.finish()

func _pump_stair_jamb() -> void:
	var jamb := _section("PumpStairJamb",Vector3(32,-1.2,-2.63))
	jamb.box(Vector3(-.13,0,0),Vector3(.35,14.0,1.04),Color("232b2b"))
	jamb.box(Vector3(.047,0,.42),Vector3(.028,14.0,.18),Color("625b4a"))
	jamb.finish()

func _pump_stair_mount(label: String, x: float, y: float, width: float) -> void:
	var mount := _section(label + "WallMount",Vector3(x,y,0))
	var dark_steel := Color("252e2b")
	var worn_steel := Color("4b4b3e")
	for offset in [-width*.30,width*.30]:
		mount.plate(Vector3(offset,-.57,-3.02),Vector3(.56,1.10,.24),dark_steel)
		mount.box(Vector3(offset,-.27,-1.97),Vector3(.26,.24,2.44),dark_steel)
		mount.box(Vector3(offset,-.64,-.86),Vector3(.19,.22,4.19),dark_steel,false,Vector3(-.19,0,0))
		mount.box(Vector3(offset,-.30,1.00),Vector3(.31,.22,.51),dark_steel)
		for height in [-.17,-.93]:
			mount.cylinder(Vector3(offset,height,-2.885),Vector3(.095,.06,.095),worn_steel,Vector3(PI*.5,0,0))
	mount.finish()

func _sign(label: String, x: float, y: float, caption: String) -> void:
	var kit := _section(label,Vector3(x,y,-2.50))
	var width := maxf(1.85,caption.length()*.111+.40)
	kit.plate(Vector3.ZERO,Vector3(width,.39,.12),Color("202a2c"))
	kit.box(Vector3(-width*.5+.13,0,.075),Vector3(.04,.21,.03),PILOT,true)
	kit.text(Vector3(.055,0,.078),caption,Color("e7d2a9"),.185)
	kit.finish()
