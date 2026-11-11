extends "res://scripts/miko8_ortho_repetition.gd"
## Separate playable staging proof. Existing yard and actor are unchanged.
const MOCKUP_LENGTH:=180.0
const PATROL_LEVEL := 4
const LEVEL_NAMES := ["Service Yard", "Pump Works", "Freight District", "Freight Security"]
const LEVEL_SCENES := [
	"res://scenes/miko8_side_on_mockup.tscn",
	"res://scenes/miko8_level_02.tscn",
	"res://scenes/miko8_level_03.tscn",
	"res://scenes/miko7_patrol_yard.tscn",
]
const COURSE := preload("res://scripts/miko8_tutorial_course.gd")
const SECURITY_COURSE := preload("res://scripts/miko8_freight_security_course.gd")
const MOCKUP_HEIGHT:=15.0
const MOCKUP_FOOT_ROW:=0.86
const CAMERA_LOW_LEVEL_HEADROOM:=3.1
var raised_camera:=false
var straight_camera:=false
var camera_focus_x:=0.0
var camera_focus_ready:=false
var camera_lead_x:=1.2
var camera_floor_y:=0.0
var camera_floor_ready:=false
var camera_down_held:=0.0
var camera_look_down:=0.0
@export_range(0.0,15.0) var oblique_angle_degrees:=8.0
var layered_scenery:Node3D
var atmosphere:Node3D
var atmosphere_toggle:CheckButton
var climb_set:Node3D
var foreground:Node3D
var practical_lights:Array[Dictionary]=[]
var miko_style:OptionButton
var mote_style:OptionButton
var impact_time:=0.0
var ambience_muted:=false
@export_range(1,4) var level_index:=1
var coordinate_label:Label
var suit_status_label: Label
var displayed_suit_polarity := -1
const SUIT_STATUS := ["N   NEUTRAL", "+   RED", "−   BLUE"]
const SUIT_STATUS_COLORS := [Color("d9dedc"), Color("ff9a88"), Color("8abfff")]
var level_selector:OptionButton
var transfer_relays:Array[Node3D]=[]
var tutorial_course:Node3D
var tutorial_director:CanvasLayer
var _last_rim_pos:=Vector3.INF
var _last_rim_intensity:=-1.0
func crate_impact_feedback()->void:impact_time=.18
func set_ambience_muted(value:bool)->void:
	ambience_muted=value
	# Keep mute independent of the looping stream's end/restart timing.
	if is_instance_valid(audio):audio.volume_db=-80. if value else -15.
func _ground_length() -> float:
	if level_index == PATROL_LEVEL: return SECURITY_COURSE.LENGTH
	return COURSE.MOVEMENT_LENGTH if level_index == 1 else MOCKUP_LENGTH

func _restart(wake:=true)->void:
	if resetting: return
	if tutorial_director:tutorial_director.reset_stage()
	for relay in transfer_relays:relay.cancel()
	await super._restart(wake and level_index != PATROL_LEVEL)
	if level_index == PATROL_LEVEL:
		for child in get_children():
			if child.has_method("reset_patrol"): child.reset_patrol()
		tutorial_course.restore_encounters()
		var pool: Node = actor.abilities.projectile_pool
		for bolt in pool.active_bolts.duplicate():
			pool.recycle_bolt(bolt)
	camera_focus_ready=false
	camera_floor_ready=false
	camera_lead_x=1.2
	camera_floor_y=0.0
	camera_down_held=0.;camera_look_down=0.
	for crate in get_tree().get_nodes_in_group("miko8_breakable_crates"):crate.reset_crate()
	for debris in get_tree().get_nodes_in_group("miko8_crate_debris"):debris.queue_free()
	for canister in get_tree().get_nodes_in_group("miko8_canisters"):canister.reset_collectible()
	for box in get_tree().get_nodes_in_group("miko8_charge_targets"):
		if box.has_method("reset_charge_body"):box.reset_charge_body()
		elif box.has_method("neutralize"):box.neutralize()

func _restart_position() -> Vector3:
	if level_index == PATROL_LEVEL and tutorial_course.checkpoint_reached:
		return tutorial_course.restart_position()
	return super._restart_position()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if level_index != PATROL_LEVEL or resetting: return
	if actor.state == "Dead" and actor.state_time >= 2.2:
		_restart(false)

func _world()->void:
	super._world()
	# Replace stacked tutorial directional lights with unified key and fill lights.
	for light in get_children():
		if light is DirectionalLight3D:
			light.queue_free()
	var architecture_key:=DirectionalLight3D.new();architecture_key.name="NeutralArchitectureKey"
	architecture_key.rotation_degrees=Vector3(-24,-48,0)
	architecture_key.light_color=Color("fff0d9");architecture_key.light_energy=.64
	architecture_key.light_cull_mask=~0;architecture_key.shadow_enabled=false;add_child(architecture_key)
	var architecture_fill:=DirectionalLight3D.new();architecture_fill.name="NeutralArchitectureFill"
	architecture_fill.rotation_degrees=Vector3(-35,135,0)
	architecture_fill.light_color=Color("fff4e6");architecture_fill.light_energy=.15
	architecture_fill.light_cull_mask=~0;architecture_fill.shadow_enabled=false;add_child(architecture_fill)

func _backgrounds()->void:
	layered_scenery=preload("res://scripts/miko8_side_on_backdrop.gd").new()
	layered_scenery.room_length=_ground_length();add_child(layered_scenery)
	var district := preload("res://scripts/miko8_service_yard_backdrop.gd").new()
	district.district_variant = level_index
	district.cooling_plots = COURSE.COOLING_PLOTS
	district.room_length = _ground_length()
	add_child(district)
	layered_scenery.service_yard = district

func _details()->void:
	# Gameplay props are authored after actor setup.
	pass

func _ready()->void:
	super._ready()
	var room_length := _ground_length()
	add_to_group("miko8_impact_feedback")
	_update_gameplay_antialiasing()
	get_viewport().size_changed.connect(_update_gameplay_antialiasing)
	view_height=MOCKUP_HEIGHT
	title.text="MIKO   /   SUBSTATION 04"
	if level_index > 1: title.text = "MIKO   /   " + LEVEL_NAMES[level_index - 1].to_upper()
	DisplayServer.window_set_title("MIKO7 — " + LEVEL_NAMES[level_index - 1])
	var end:=StaticBody3D.new();end.name="MockupRoomEnd"
	var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.5,5,4)
	collider.shape=shape;end.position=Vector3(room_length+.25,2,0);end.add_child(collider);add_child(end)
	scene_presence.set_room_length(room_length)
	scene_presence.foot_dust_strength=1.5
	_clear_rear_furniture()
	# A narrow rear apron joins the scenery's bottom edge to the actual deck.
	var apron:=MeshInstance3D.new();apron.name="RearServiceApron"
	var mesh:=BoxMesh.new();mesh.size=Vector3(room_length+2,.12,3)
	apron.mesh=mesh;apron.position=Vector3(room_length*.5,-.06,-2.7)
	if level_index<=4:
		mesh.size.z=6.6
		apron.position.z=-4.5
	for material in get_node("OrthographicRepeatedGround").material_cache.values():
		if material is ShaderMaterial and material.shader==preload("res://shaders/miko8_restored_paving.gdshader"):
			apron.material_override=material;break
	apron.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(apron)
	# Keep the existing pavement quiet at the grazing camera angle.
	for visual:MeshInstance3D in get_node("OrthographicRepeatedGround").find_children("*","MeshInstance3D",true,false):
		if not visual.mesh:continue
		for index in range(visual.mesh.get_surface_count()):
			var paving:=visual.get_surface_override_material(index) as ShaderMaterial
			if paving and paving.shader==preload("res://shaders/miko8_restored_paving.gdshader"):
				paving.set_shader_parameter("damp_amount",.15)
	_camera(0,true);visibility_budget.refresh()
	atmosphere=preload("res://scripts/miko8_side_on_atmosphere.gd").new()
	# The former rooftop fixtures were placed for the retired demo buildings.
	# Keep ambient motes; do not spawn hardware at those unsupported heights.
	atmosphere.enable_yard_life=false
	atmosphere.camera=camera;atmosphere.room_length=room_length;add_child(atmosphere)
	if is_instance_valid(mote_style):_mote_style_changed(mote_style.selected)
	tutorial_course=SECURITY_COURSE.new() if level_index == PATROL_LEVEL else COURSE.new()
	tutorial_course.stage=level_index;add_child(tutorial_course)
	climb_set=tutorial_course
	var concrete_theme=preload("res://scripts/miko8_side_on_concrete_theme.gd")
	concrete_theme.apply_to(get_node("OrthographicRepeatedGround"));concrete_theme.apply_to(climb_set)
	actor.movement_only=false
	actor.abilities.magnetic_weapons_enabled = level_index >= 2
	actor.abilities.destructive_weapons_enabled = level_index >= 3
	if level_index == PATROL_LEVEL: actor.set_meta("action_momentum", true)
	actor.polarity_control.set_process_unhandled_input(true)
	actor.launcher_motion.enabled=true
	var fields_layer:=CanvasLayer.new();fields_layer.name="BlockMagneticFields";fields_layer.layer=0;add_child(fields_layer)
	var fields:=preload("res://scripts/miko8_block_fields.gd").new();fields.camera=camera;fields_layer.add_child(fields)
	if level_index==1:
		foreground=preload("res://scripts/miko8_side_on_foreground.gd").new();foreground.camera=camera;add_child(foreground)
	_ground_contacts();_set_atmosphere(atmosphere_toggle.button_pressed)
	add_child(preload("res://scripts/miko8_cel_scene.gd").new())
	if level_index == PATROL_LEVEL:
		for visual: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
			visual.lod_bias = .10
	if "--overhang-review" in OS.get_cmdline_user_args():
		actor.reset_actor();actor.position=Vector3(65.5,.02,0);_camera(0,true)
	elif "--cooling-crossing-review" in OS.get_cmdline_user_args() and level_index==2:
		actor.reset_actor();actor.position=Vector3(63.5,.02,0);_camera(0,true)
	elif "--tower-course-review" in OS.get_cmdline_user_args() and level_index==2:
		actor.reset_actor();actor.position=Vector3(39.,.02,0);_camera(0,true)
	elif "--canister-review" in OS.get_cmdline_user_args() and level_index==2:
		actor.reset_actor();actor.position=Vector3(28.,2.66,0);_camera(0,true)
	elif "--switch-review" in OS.get_cmdline_user_args() and level_index==2:
		actor.reset_actor();actor.position=Vector3(10.3,.02,0);_camera(0,true)
	elif "--platform-review" in OS.get_cmdline_user_args() and level_index==2:
		actor.reset_actor();actor.position=Vector3(18.2,.02,0);_camera(0,true)
	elif "--bridge-review" in OS.get_cmdline_user_args():
		actor.reset_actor();actor.position=Vector3(37.3,5.22,-.81807)
		actor.walk_plane_z=-.81807;actor.walk_plane_floor_y=5.2;_camera(0,true)
	elif "--mag-pad-review" in OS.get_cmdline_user_args():
		actor.reset_actor();actor.position=Vector3(49.5,.02,0);_camera(0,true)
	elif "--launcher-review" in OS.get_cmdline_user_args():
		actor.reset_actor();actor.position=Vector3(10.3,.02,0);_camera(0,true)
	elif "--tall-ladder-review" in OS.get_cmdline_user_args():
		actor.reset_actor();actor.position=Vector3(30.35,.02,0);_camera(0,true)
	elif "--workshop-review" in OS.get_cmdline_user_args():
		actor.reset_actor();actor.position=Vector3(49.5,.02,0);_camera(0,true)
	elif "--ladder-top-review" in OS.get_cmdline_user_args() or "--ladder-wall-review" in OS.get_cmdline_user_args():
		actor.reset_actor();actor.position=Vector3(18.08,.02,0);_camera(0,true)
	_setup_transfers()
	if level_index < PATROL_LEVEL:
		tutorial_director=preload("res://scripts/miko8_tutorial_director.gd").new()
		tutorial_director.level=self;tutorial_director.course=tutorial_course;add_child(tutorial_director)
	print("SIDE_ON_MOCKUP_READY length=",room_length,"m camera_pitch=6deg real_actor_and_crate=true")

func _update_gameplay_antialiasing() -> void:
	var viewport := get_viewport()
	if not "--native-render" in OS.get_cmdline_user_args():
		# Scale only 3D. The HUD and window retain the display resolution.
		viewport.scaling_3d_scale = minf(1.0, 720.0 / maxf(1.0, get_window().size.y))
		viewport.msaa_3d = Viewport.MSAA_DISABLED
		return
	viewport.msaa_3d = Viewport.MSAA_2X if "--msaa" in OS.get_cmdline_user_args() else Viewport.MSAA_DISABLED

func _exit_tree() -> void:
	get_viewport().scaling_3d_scale = 1.0

func _setup_transfers()->void:
	var relay_script:=preload("res://scripts/miko8_network_transfer.gd")
	var exit_relay := relay_script.new()
	exit_relay.required_canister = tutorial_course.canister
	if level_index == PATROL_LEVEL:
		exit_relay.position = SECURITY_COURSE.EXIT_POSITION
		exit_relay.destination_scene = "res://scenes/miko7_title_screen.tscn"
		exit_relay.destination_label = "Safe Network"
		exit_relay.send_arrival_ticket = false
	else:
		exit_relay.position = Vector3(_ground_length()-5.,0,0)
		exit_relay.destination_scene = LEVEL_SCENES[level_index]
		exit_relay.destination_label = LEVEL_NAMES[level_index]
	add_child(exit_relay)
	transfer_relays.append(exit_relay)
	if level_index>1:
		var arrival:=relay_script.new();arrival.arrival_only=true
		arrival.destination_label = LEVEL_NAMES[level_index - 1]
		arrival.position=Vector3(4.4,0,0);add_child(arrival);transfer_relays.append(arrival)
		if get_tree().has_meta(relay_script.TICKET):
			var ticket:Dictionary=get_tree().get_meta(relay_script.TICKET)
			get_tree().remove_meta(relay_script.TICKET)
			if ticket.get("scene","")==scene_file_path:arrival.receive(ticket)
	if "--transfer-review" in OS.get_cmdline_user_args() and level_index==2 and not transfer_relays.back().busy():
		actor.reset_actor();actor.position=Vector3(72.8,.02,0);_camera(0,true)

func _ground_contacts()->void:
	for node in actor.get_children():
		if node.get_script()==preload("res://scripts/miko8_contact_shadow.gd"):
			(node.patch.mesh as PlaneMesh).size=Vector2(.95,1.0)
	for patch:MeshInstance3D in scene_presence.shadows:(patch.mesh as PlaneMesh).size=Vector2(.44,.40)

func _clear_rear_furniture()->void:
	# The mockup is a courtyard: remove the old railing/post geometry that
	# separated the lane from its new ground-level buildings. Source GLBs stay.
	var cache:Dictionary={}
	for old_light in get_node("OrthographicRepeatedGround").get_children():
		if old_light is OmniLight3D:
			old_light.hide();old_light.remove_from_group("miko8_budget_visual")
		elif old_light is Node3D and old_light.get_meta("ortho_connector",false):
			old_light.hide()
	for visual:MeshInstance3D in get_node("OrthographicRepeatedGround").find_children("*","MeshInstance3D",true,false):
		var source:=visual.mesh as ArrayMesh
		if not source:continue
		if not cache.has(source):
			var trimmed:=ArrayMesh.new();var surfaces:Array[int]=[]
			for surface in range(source.get_surface_count()):
				var arrays:=source.surface_get_arrays(surface)
				var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
				var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
				if indices.is_empty():
					for index in range(points.size()):indices.append(index)
				var retained:=PackedInt32Array()
				for index in range(0,indices.size(),3):
					var centre:Vector3=(points[indices[index]]+points[indices[index+1]]+points[indices[index+2]])/3.0
					if centre.y>.022 and centre.z<-.25:continue
					retained.append(indices[index]);retained.append(indices[index+1]);retained.append(indices[index+2])
				if retained.is_empty():continue
				var original_material:=source.surface_get_material(surface)
				if original_material and "coping" in original_material.resource_name.to_lower():
					for point_index in range(points.size()):points[point_index].y*=.45
					arrays[Mesh.ARRAY_VERTEX]=points
				arrays[Mesh.ARRAY_INDEX]=retained
				trimmed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				trimmed.surface_set_material(trimmed.get_surface_count()-1,source.surface_get_material(surface))
				surfaces.append(surface)
			cache[source]={"mesh":trimmed,"surfaces":surfaces}
		var record:Dictionary=cache[source];var overrides:Array[Material]=[]
		for surface:int in record.surfaces:overrides.append(visual.get_active_material(surface))
		visual.mesh=record.mesh
		for index in range(overrides.size()):visual.set_surface_override_material(index,overrides[index])
	# A single thin coping course separates the paving from the wall face.
	for module:Node3D in get_node("OrthographicRepeatedGround").modules:
		var face:=module.get_node_or_null("PaintedFoundationFront") as MeshInstance3D
		if face:
			(face.mesh as QuadMesh).size.y=2.13;face.position.y=-1.185
	# Extra thin lenses were added separately from the exported lamp geometry.
	for visual:MeshInstance3D in get_node("OrthographicRepeatedGround/SurfaceDetailLayers").find_children("*","MeshInstance3D",true,false):
		if visual.position.y>2.0:visual.hide();visual.remove_from_group("miko8_budget_visual")

func _hud()->void:
	super._hud()
	coordinate_label=Label.new();coordinate_label.name="MikoCoordinates";coordinate_label.position=Vector2(32,106);coordinate_label.add_theme_font_size_override("font_size",18);game_size.get_parent().add_child(coordinate_label)
	level_selector=OptionButton.new();level_selector.name="LevelSelector";level_selector.position=Vector2(32,140);level_selector.focus_mode=Control.FOCUS_NONE
	for i in range(LEVEL_NAMES.size()):
		level_selector.add_item("Level %d — %s" % [i + 1, LEVEL_NAMES[i]])
	level_selector.select(level_index-1);level_selector.item_selected.connect(func(index:int):get_tree().call_deferred("change_scene_to_file",LEVEL_SCENES[index]));game_size.get_parent().add_child(level_selector)
	suit_status_label = Label.new()
	suit_status_label.name = "SuitStatus"
	suit_status_label.position = Vector2(38, 177)
	suit_status_label.add_theme_font_size_override("font_size", 17)
	game_size.get_parent().add_child(suit_status_label)
	performance.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	performance.offset_left=38;performance.offset_top=80;performance.offset_right=260;performance.offset_bottom=110
	performance.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	performance.visible=true
	game_size.clear();game_size.add_item("Camera: Gentle 3D");game_size.add_item("Camera: Straight side-on");game_size.add_item("Camera: Earlier raised view")
	game_size.select(0)
	atmosphere_toggle=CheckButton.new();atmosphere_toggle.text="Atmosphere"
	atmosphere_toggle.focus_mode=Control.FOCUS_NONE
	atmosphere_toggle.button_pressed = level_index != PATROL_LEVEL or "--native-render" in OS.get_cmdline_user_args()
	atmosphere_toggle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	atmosphere_toggle.offset_left=-274;atmosphere_toggle.offset_right=-38
	atmosphere_toggle.offset_top=110;atmosphere_toggle.offset_bottom=150
	atmosphere_toggle.add_theme_font_size_override("font_size",18)
	atmosphere_toggle.toggled.connect(_set_atmosphere);game_size.get_parent().add_child(atmosphere_toggle)
	var scenery_label:=Label.new();scenery_label.text="Scenery brightness"
	scenery_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	scenery_label.offset_left=-274;scenery_label.offset_right=-38
	scenery_label.offset_top=156;scenery_label.offset_bottom=180
	scenery_label.add_theme_font_size_override("font_size",18);game_size.get_parent().add_child(scenery_label)
	var scenery_slider:=HSlider.new();scenery_slider.name="SceneryBrightness"
	scenery_slider.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	scenery_slider.offset_left=-274;scenery_slider.offset_right=-38
	scenery_slider.offset_top=184;scenery_slider.offset_bottom=208
	scenery_slider.min_value=25;scenery_slider.max_value=100;scenery_slider.value=50
	scenery_slider.focus_mode=Control.FOCUS_NONE
	scenery_slider.value_changed.connect(func(value:float):layered_scenery.set_brightness(value/100.0))
	game_size.get_parent().add_child(scenery_slider)
	miko_style=OptionButton.new();miko_style.name="MikoShadingStyle";miko_style.focus_mode=Control.FOCUS_NONE
	miko_style.add_item("MIKO: Three-tone");miko_style.add_item("MIKO: Original")
	miko_style.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	miko_style.offset_left=-274;miko_style.offset_right=-38;miko_style.offset_top=220;miko_style.offset_bottom=256
	miko_style.add_theme_font_size_override("font_size",18)
	miko_style.item_selected.connect(_miko_style_changed);game_size.get_parent().add_child(miko_style)
	_miko_style_changed(0)
	mote_style=OptionButton.new();mote_style.name="MoteStyle";mote_style.focus_mode=Control.FOCUS_NONE
	mote_style.add_item("Motes: Bold (100%)");mote_style.add_item("Motes: Moderate (60%)");mote_style.add_item("Motes: Subtle (30%)");mote_style.add_item("Motes: Off (0%)")
	mote_style.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mote_style.offset_left=-274;mote_style.offset_right=-38;mote_style.offset_top=308;mote_style.offset_bottom=344
	mote_style.add_theme_font_size_override("font_size",18)
	mote_style.item_selected.connect(_mote_style_changed);game_size.get_parent().add_child(mote_style)

func _miko_style_changed(index:int)->void:
	actor.polarity_control.set_three_tone(index==0)

func _mote_style_changed(index:int)->void:
	var scales:Array[float]=[1.0,0.6,0.3,0.0]
	if index>=0 and index<scales.size():
		if is_instance_valid(atmosphere) and atmosphere.has_method("set_mote_intensity"):
			atmosphere.set_mote_intensity(scales[index])

func _set_atmosphere(enabled:bool)->void:
	if is_instance_valid(atmosphere):atmosphere.set_effects_enabled(enabled)
	if is_instance_valid(scene_presence):
		scene_presence.ambient_air_enabled = enabled
		for node in scene_presence.get_children():
			if node is MultiMeshInstance3D and node.multimesh==scene_presence.air:node.visible=enabled

func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_M:
		set_ambience_muted(not ambience_muted);return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F8:
		var index:=(miko_style.selected+1)%2;miko_style.select(index);_miko_style_changed(index);return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F10:
		if is_instance_valid(mote_style):
			var index:=(mote_style.selected+1)%mote_style.item_count
			mote_style.select(index);_mote_style_changed(index);return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F6:
		var index:=(game_size.selected+1)%game_size.item_count
		game_size.select(index);_game_size_changed(index);return
	super._unhandled_key_input(event)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F7:
		atmosphere_toggle.button_pressed=not atmosphere_toggle.button_pressed

func _game_size_changed(index:int)->void:
	raised_camera=index==2;straight_camera=index==1;_camera(0,true)

func _camera(delta:float,immediate:=false)->void:
	if not camera:return
	impact_time=maxf(0,impact_time-delta)
	var kick:=pow(impact_time/.18,2)
	camera.h_offset=sin(impact_time*137.)*.035*kick
	camera.v_offset=cos(impact_time*111.)*.022*kick
	var pitch:=atan(7.0/18.0) if raised_camera else deg_to_rad(6.0)
	var yaw:=0.0 if raised_camera or straight_camera else -deg_to_rad(oblique_angle_degrees)
	var height := MOCKUP_HEIGHT
	if "--ladder-top-review" in OS.get_cmdline_user_args(): height = 7.5
	var width:=height*get_viewport().get_visible_rect().size.x/maxf(1,get_viewport().get_visible_rect().size.y)
	var room_length := _ground_length()
	var half:=minf(width*.5/cos(yaw),room_length*.5)
	var facing_dir: float = float(actor.facing) if is_instance_valid(actor) and "facing" in actor else 1.0
	var speed: float = absf(actor.velocity.x) if is_instance_valid(actor) and "velocity" in actor else 0.0
	var desired_lead: float = facing_dir * (1.2 + clampf(speed * 0.35, 0.0, 1.8))
	camera_lead_x = desired_lead if immediate or not camera_focus_ready else lerpf(camera_lead_x, desired_lead, 1.0 - exp(-3.5 * delta))
	var goal:=clampf(actor.position.x + camera_lead_x, half, room_length - half)
	var x:float=goal if immediate or not camera_focus_ready else lerpf(camera_focus_x,goal,1-exp(-4.5*delta))
	camera_focus_x=x;camera_focus_ready=true
	var back:=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
	# A conventional Y-up look_at tilts the projected walkway when yaw and
	# pitch are combined. Align screen-right with the projected movement axis.
	var screen_right:Vector3=(Vector3.RIGHT-back*back.x).normalized()
	var screen_up:=back.cross(screen_right).normalized()
	var feet_y:float=maxf(0.,actor.global_position.y)
	# A single storey fits comfortably above the ground framing. Follow only
	# the height beyond that allowance, keeping the ground visible on low roofs.
	var follow_y:float=maxf(0.,feet_y-CAMERA_LOW_LEVEL_HEADROOM)
	if immediate or not camera_floor_ready:camera_floor_y=follow_y
	else:
		var vertical_goal:float=camera_floor_y
		if follow_y>camera_floor_y+.35:vertical_goal=follow_y-.35
		elif follow_y<camera_floor_y-.35:vertical_goal=follow_y+.35
		if actor.is_on_floor() or follow_y==0.:vertical_goal=follow_y
		camera_floor_y=lerpf(camera_floor_y,vertical_goal,1.-exp(-7.*delta))
	camera_floor_ready = true
	var looking_down:bool=Input.is_action_pressed("miko8_down") and not actor.state.begins_with("Climb")
	camera_down_held=camera_down_held+delta if looking_down else 0.
	var look_goal:float=1.5*smoothstep(.25,.85,camera_down_held)
	camera_look_down=lerpf(camera_look_down,look_goal,1.-exp(-5.*delta))
	# The established ground framing is the lower camera boundary. Higher
	# floors can look down towards it; no input can expose space below the level.
	var framed_height:float=maxf(0.,camera_floor_y-camera_look_down)
	var target_y:=((MOCKUP_FOOT_ROW-.5)*height + framed_height)/screen_up.y
	camera.size=height
	camera.position=Vector3(x,target_y,0)+back*(18./back.z)
	camera.basis=Basis(screen_right,screen_up,back)
	camera.set_meta("walkway_focus_x",x)
	if is_instance_valid(layered_scenery):layered_scenery.update_camera(x)
	for practical:Dictionary in practical_lights:
		practical.node.position=practical.anchor+Vector3((x-16.0)*.05,0,0)
	if immediate and visibility_budget:visibility_budget.refresh()
	# Dynamic practical rim lighting on Miko
	if is_instance_valid(actor) and is_instance_valid(actor.polarity_control):
		var best_dist:=999.0
		var best_pos:=Vector3.ZERO
		for lamp_data:Dictionary in practical_lights:
			var lpos:Vector3=lamp_data.node.global_position
			var d:=actor.global_position.distance_to(lpos)
			if d<best_dist:
				best_dist=d
				best_pos=lpos
		var intensity:=clampf(1.0-best_dist/6.0,0.0,1.0)
		if best_pos.distance_squared_to(_last_rim_pos)>0.0001 or absf(intensity-_last_rim_intensity)>0.002:
			_last_rim_pos=best_pos;_last_rim_intensity=intensity
			for mat:ShaderMaterial in actor.polarity_control.materials:mat.set_shader_parameter("rim_light_pos",best_pos);mat.set_shader_parameter("rim_intensity",intensity*0.70);mat.set_shader_parameter("rim_light_color",Vector3(1.0,0.74,0.49))

func _prompt()->void:
	if not instruction:return
	if coordinate_label:coordinate_label.text="LEVEL %d   X: %.1f m   Y: %.1f m"%[level_index,actor.position.x,actor.position.y]
	if suit_status_label and actor.suit_polarity != displayed_suit_polarity:
		displayed_suit_polarity = actor.suit_polarity
		suit_status_label.text = "SUIT   " + SUIT_STATUS[displayed_suit_polarity]
		suit_status_label.modulate = SUIT_STATUS_COLORS[displayed_suit_polarity]
	for relay in transfer_relays:
		var transfer_prompt:String=relay.prompt()
		if not transfer_prompt.is_empty():
			progress.text="NETWORK TRANSFER";instruction.text=transfer_prompt
			detail.text="R: reset" if relay.busy() else "A / D: move · Space: jump · T: transfer · R: reset"
			return
	if level_index == PATROL_LEVEL:
		progress.text = "LEVEL 4   /   FREIGHT SECURITY"
		instruction.text = tutorial_course.hint_at(actor.position.x) if tutorial_course else "Freight security ahead."
		detail.text = "R / View: return to checkpoint" if tutorial_course and tutorial_course.checkpoint_reached else "R / View: restart"
	elif tutorial_director:tutorial_director.update_hud()
	else:
		progress.text="TRAINING %d / 3"%level_index
		instruction.text="Preparing the service route…";detail.text=""
