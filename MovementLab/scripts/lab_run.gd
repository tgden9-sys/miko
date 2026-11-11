extends "res://scripts/lab.gd"

const VIEW_HEIGHT := 7.4
const CAMERA_DISTANCE := 48.0
const CAMERA_RISE := .65
const FRAME := Color("2b3640")
const ROOM_NAMES := ["Wake Bay", "East Service Shaft", "Coolant Gallery", "West Service Shaft", "Upper Transfer", "Descent Shaft", "Dispatch"]
const ROOM_HINTS := ["Head right to the service shaft", "Climb to the floor above", "Head LEFT across the first floor", "Climb to the second floor", "Head RIGHT to the descent shaft", "Drop through the staggered landings", "Network relay ahead"]
const CHECKPOINTS := [Vector3(3,.04,0),Vector3(51,.04,0),Vector3(51,6.04,0),Vector3(12,6.04,0),Vector3(12,12.04,0),Vector3(62,12.04,0),Vector3(83,.04,0)]
var active_room := 0
var checkpoint_room := 0
var camera_focus := 10.0
var camera_height := 2.25
var view_height := VIEW_HEIGHT
var direction_hint: Label
var contact_shadow: MeshInstance3D
var shadow_query := PhysicsRayQueryParameters3D.new()
var bulkhead_bounds: Array[AABB] = []
var polarity_crate: RigidBody3D
var step_fx: MultiMeshInstance3D

func _ready() -> void:
	course_title = "MIKO   /   WAKE LAB"
	course_shadows = false
	course_polarity_controls = true
	course_target_model = load("res://models/AgileDroid_Low.glb")
	super._ready()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	actor.sword_bulkheads = bulkhead_bounds
	_add_network_node("ArrivalRelay",4.5)
	_add_network_node("NetworkRelaySocket",90.0)
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.background_color = Color("0e151d")
			child.environment.ambient_light_color = Color("afbdc8")
			child.environment.ambient_light_energy = .58
		elif child is DirectionalLight3D:
			child.light_color = Color("fff0d9")
			child.light_energy = 1.14
	_build_contact_shadow()
	step_fx = preload("res://scripts/lab_step_fx.gd").new()
	step_fx.actor = actor
	add_child(step_fx)
	dummy.home = Vector3(32,6,0)
	polarity_crate = preload("res://scripts/miko8_charge_box.gd").new()
	polarity_crate.name = "PolarityCrate"
	polarity_crate.position = Vector3(17,.4,0)
	add_child(polarity_crate)
	reset_room()

func _add_network_node(node_name: String, x: float) -> void:
	var node := preload("res://scripts/miko8_transfer_visual.gd").new()
	node.name = node_name
	node.actor = actor
	node.camera = camera
	node.position = Vector3(x,0,-.48)
	$Dressing.add_child(node)
	node.update_effect(0.0,0.0,0.0,false)

func _build_course() -> void:
	# Slabs are structural. The seven shaft landings live in the scene tree.
	_slab(0,65,0)
	_slab(0,58,6)
	_slab(6,65,12)
	_slab(0,78,18)
	_slab(65,94,0)
	_slab(78,94,6)
	_bulkhead("WestWall",Vector3(-.3,9,0),Vector3(.6,19,4))
	_bulkhead("EastShaftDivider",Vector3(65.5,5.7,0),Vector3(1.0,12.6,4))
	_bulkhead("DescentOuterWall",Vector3(78.3,12,0),Vector3(.6,12,4))
	_bulkhead("ExitBoundary",Vector3(94.3,3,0),Vector3(.6,7,4))

func _slab(start: float, finish: float, height: float) -> void:
	_block("StoreySlab",Vector3((start+finish)*.5,height-.225,0),Vector3(finish-start,.45,3.7),FRAME,false)
	$Dressing.deck(start,finish,height)

func _bulkhead(label: String, at: Vector3, size: Vector3) -> void:
	_block(label,at,size,FRAME,false)
	$Dressing.column(at,size,label == "EastShaftDivider")
	bulkhead_bounds.append(AABB(at - size*.5, size))

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud_plate(layer,Vector2(34,27),Vector2(460,102))
	_hud_text(layer,Vector2(56,38),course_title,16,Color("efbb7e"))
	status = _hud_text(layer,Vector2(56,57),"",25,Color("e8ebe4"))
	direction_hint = _hud_text(layer,Vector2(56,91),"",15,Color("afc0bd"))
	_hud_plate(layer,Vector2(1504,27),Vector2(382,72))
	diagnostics = _hud_text(layer,Vector2(1525,42),"",17,Color("bfdbd4"))
	_hud_plate(layer,Vector2(34,975),Vector2(1270,75))
	_hud_text(layer,Vector2(54,986),"B  Jump    A  Dash    Y  Sword    X  Parry    Down  Crouch / Look below    View  Reset    R3  Close view",18,Color("e8ebe4"))
	_hud_text(layer,Vector2(54,1015),"LT  Red laser    RT  Blue laser    LB  Charge red    RB  Charge blue    Right stick  Aim",15,Color("b7c4c4"))
	_hud_plate(layer,Vector2(1324,975),Vector2(562,75))
	style_banner = _hud_text(layer,Vector2(1345,989),"",17,Color("8bdad1"))
	_hud_text(layer,Vector2(1345,1015),"Up + Y  Launch     Down + Y in air  Ground pound",15,Color("b7c4c4"))
	var style: Dictionary = actor.SWORD_STYLES[actor.sword_style]
	_on_sword_style_changed(actor.sword_style,style.name,style.desc)

func _hud_plate(layer: CanvasLayer, at: Vector2, size: Vector2) -> void:
	var panel := Panel.new()
	panel.position = at
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color(0.042,0.065,0.082,.92)
	skin.border_color = Color("536767")
	skin.border_width_left = 2
	skin.border_width_bottom = 1
	skin.corner_radius_top_right = 7
	skin.corner_radius_bottom_right = 7
	panel.add_theme_stylebox_override("panel",skin)
	layer.add_child(panel)

func _hud_text(layer: CanvasLayer, at: Vector2, caption: String, height: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.text = caption
	label.modulate = color
	label.add_theme_font_size_override("font_size",height)
	layer.add_child(label)
	return label

func _on_sword_style_changed(index: int, style_name: String, _description: String) -> void:
	style_banner.text = "%02d / 10    %s" % [index+1,style_name.to_upper()]

func reset_room() -> void:
	super.reset_room()
	actor.position = CHECKPOINTS[checkpoint_room]
	if step_fx: step_fx.clear()
	if polarity_crate: polarity_crate.reset_charge_body()
	actor._update_sword_walls()
	camera_focus = actor.position.x
	camera_height = actor.position.y+2.43
	_update_camera(1.0)

func _update_camera(delta: float) -> void:
	var p := actor.position
	if p.x > 78.6 and p.y < 3:
		active_room = 6
	elif p.x > 65.6:
		active_room = 5
	elif p.y >= 11.8:
		active_room = 4
	elif p.x < 12 and p.y >= 5.8:
		active_room = 3
	elif p.y >= 5.8:
		active_room = 2
	elif p.x > 51:
		active_room = 1
	else:
		active_room = 0
	# Checkpoints belong to solid corridor landings, never midair in a shaft.
	if actor.is_on_floor():
		if p.x > 80 and p.y < .2: checkpoint_room = 6
		elif p.y > 11.9 and p.y < 12.2 and p.x > 10 and p.x < 63: checkpoint_room = 4
		elif p.y > 5.9 and p.y < 6.2 and p.x > 11 and p.x < 52: checkpoint_room = 2 if p.x > 30 else 3
		elif p.y < .2 and p.x < 54: checkpoint_room = 1 if p.x > 45 else 0
	view_height = lerpf(view_height,4.5 if zoomed else VIEW_HEIGHT,1-exp(-delta*9))
	camera.fov = rad_to_deg(2.0 * atan(view_height * .5 / CAMERA_DISTANCE))
	var view := get_viewport().get_visible_rect().size
	var half_width := view_height*view.x/maxf(1,view.y)*.5
	var lead := clampf(actor.velocity.x*.28,-2.0,2.0)
	var target := clampf(p.x+lead,half_width,94-half_width)
	camera_focus = lerpf(camera_focus,target,1-exp(-delta*7))
	var floor_y := 12.0 if p.y >= 11.8 else (6.0 if p.y >= 5.8 else 0.0)
	var in_shaft := (p.x > 52 and p.y < 6) or (p.x < 12 and p.y > 6) or (p.x > 65.6 and p.x < 78.6)
	var target_y := p.y+2.25 if in_shaft else floor_y+2.43
	if zoomed: target_y = p.y+1.65
	if actor.look_down_time > .32:
		target_y -= 1.35
	camera_height = lerpf(camera_height,target_y,1-exp(-delta*5))
	var shake := sin(Time.get_ticks_msec()*.11)*trauma*.06
	# The long lens keeps Miko close to the side-on scale while revealing the tops of lower ledges.
	var focus := Vector3(camera_focus,camera_height+shake,0)
	camera.position = focus + Vector3(0,CAMERA_RISE,CAMERA_DISTANCE)
	camera.look_at(focus)

func _update_status() -> void:
	status.text = ROOM_NAMES[active_room]
	direction_hint.text = ROOM_HINTS[active_room]
	diagnostics.text = "L%d  /  HP %d  /  %s  /  %d FPS" % [clampi(int((actor.position.y+.2)/6),0,2),actor.health,["NEUTRAL","RED","BLUE"][actor.suit_polarity],Engine.get_frames_per_second()]





func _build_contact_shadow() -> void:
	shadow_query.collision_mask = 1
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/lab_contact.gdshader")
	contact_shadow = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.42,1.06)
	contact_shadow.mesh = mesh
	contact_shadow.material_override = material
	contact_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	contact_shadow.rotation.x = -PI/2
	add_child(contact_shadow)

func _physics_process(_delta: float) -> void:
	var foot := actor.global_position
	shadow_query.from = foot + Vector3.UP * .06
	shadow_query.to = foot + Vector3.DOWN * 3.0
	var hit := get_world_3d().direct_space_state.intersect_ray(shadow_query)
	contact_shadow.visible = not hit.is_empty()
	if contact_shadow.visible:
		var surface: Vector3 = hit.position
		var height := maxf(0.0,foot.y-surface.y)
		contact_shadow.position = surface + Vector3.UP * .024
		contact_shadow.scale = Vector3.ONE * (1.0 + height*.18)
		contact_shadow.material_override.set_shader_parameter("opacity",.46*maxf(0.0,1.0-height/3.0))
