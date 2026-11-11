extends "res://scripts/miko8_tutorial.gd"
const PREVIEW_LENGTH:=60.0
var view_height:=VIEW_HEIGHT
var game_size:OptionButton
func _enhanced_art()->bool:return not "--restored-baseline" in OS.get_cmdline_user_args()
func _continuous_yard()->bool:return _enhanced_art() and not "--keep-bridge" in OS.get_cmdline_user_args()
func _ground_length()->float:return PREVIEW_LENGTH
func _world()->void:
	super._world()
	for node in get_children():
		if node is WorldEnvironment:
			node.environment.ambient_light_energy=0.36

func _ready()->void:
	if _enhanced_art() and not "--original-view" in OS.get_cmdline_user_args():view_height=15.0
	if "--wide-view" in OS.get_cmdline_user_args():view_height=15.0
	super._ready()
	get_viewport().msaa_3d=Viewport.MSAA_2X
	var old:=get_node("PaintedGroundKit");remove_child(old);old.queue_free()
	var ground:=preload("res://scripts/miko8_ortho_repetition_ground.gd").new()
	ground.enhanced_finish=_enhanced_art();ground.enhanced_paving=_enhanced_art()
	ground.miniature_facades=_enhanced_art();ground.continuous_yard=_continuous_yard()
	ground.room_length=_ground_length();add_child(ground)
	title.text="MIKO   /   SUBSTATION 04" if _enhanced_art() else "MIKO   /   ORTHOGRAPHIC MODULE TEST"
	DisplayServer.window_set_title("MIKO — Substation Yard" if _continuous_yard() else "MIKO — 5 concrete / bridge / 4 concrete")
	visibility_budget.refresh()
	if _enhanced_art():
		scene_presence.set_room_length(PREVIEW_LENGTH)
		call_deferred("_local_reflections")

func _hud()->void:
	super._hud()
	if not _enhanced_art():return
	var layer:=CanvasLayer.new();layer.layer=5;add_child(layer)
	var root:=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(root)
	game_size=OptionButton.new();game_size.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	game_size.offset_left=-274;game_size.offset_right=-38;game_size.offset_top=68;game_size.offset_bottom=104
	game_size.add_item("View: Original");game_size.add_item("View: Wide (75% MIKO)")
	game_size.focus_mode=Control.FOCUS_NONE;game_size.add_theme_font_size_override("font_size",18)
	game_size.select(1 if view_height>12 else 0);game_size.item_selected.connect(_game_size_changed);root.add_child(game_size)
func _game_size_changed(index:int)->void:
	view_height=15.0 if index==1 else VIEW_HEIGHT
	_camera(0,true)
func _unhandled_key_input(event:InputEvent)->void:
	super._unhandled_key_input(event)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F6 and game_size:
		var index:=1-game_size.selected;game_size.select(index);_game_size_changed(index)

func _local_reflections()->void:
	var t: SceneTree = get_tree()
	if not t or not is_inside_tree(): return
	await t.process_frame
	if not is_inside_tree(): return
	t = get_tree()
	if not t: return
	await t.process_frame
	if not is_inside_tree() or not is_instance_valid(actor): return
	# Capture static rails/lamp housings once; omit the moving character.
	for visual:GeometryInstance3D in actor.find_children("*","GeometryInstance3D",true,false):visual.layers=2
	var probe:=ReflectionProbe.new();probe.name="StaticWalkwayReflections"
	probe.position=Vector3(_ground_length()*.5,1.5,0);probe.size=Vector3(_ground_length()+4,8,8)
	probe.update_mode=ReflectionProbe.UPDATE_ONCE;probe.max_distance=50
	probe.box_projection=false;probe.enable_shadows=false;probe.ambient_mode=ReflectionProbe.AMBIENT_DISABLED
	probe.intensity=.55;probe.blend_distance=2;probe.cull_mask=1;add_child(probe)

func _backgrounds()->void:
	if _enhanced_art():
		add_child(preload("res://scripts/miko8_restored_backdrop.gd").new())
		_plane("BG4_Reserved",0.70)
		return
	_plane("BG1_Dusk",0.0)
	_art(_plane("BG2_City",0.10),"res://art/tutorial/far_skyline_haze.png",Vector3(30,8,-25),110,2.4,0.88)
	var city:=_plane("BG3_Apartments",0.28)
	_art(city,"res://art/tutorial/mid_apartments.png",Vector3(30,7,-16),85,1.3,0.75)
	_plane("BG4_Reserved",0.70)

func _foreground()->void:_plane("FG_Reserved",1.15)

func _details()->void:
	var crate:=preload("res://scripts/miko8_charge_box.gd").new()
	crate.name="TutorialChargeCrate";crate.position=Vector3(54,0.4,0);crate.freeze=true;add_child(crate)

func _camera(delta:float,immediate:=false)->void:
	var width:=view_height*get_viewport().get_visible_rect().size.x/maxf(1,get_viewport().get_visible_rect().size.y)
	var goal:=clampf(actor.position.x+1.5,width/2,PREVIEW_LENGTH-width/2)
	var x:float=goal if immediate else lerpf(camera.position.x,goal,1-exp(-4.5*delta))
	var target_y:=2.0*view_height/VIEW_HEIGHT
	# Wide view sits about 80px lower at 1080p, covering the old bottom gap.
	if view_height>12.0 and _enhanced_art():target_y+=1.2
	camera.size=view_height;camera.position=Vector3(x,target_y+7.0,18);camera.look_at(Vector3(x,target_y,0))
	for plane:Dictionary in parallax:plane.node.position.x=(x-width/2)*(1-plane.factor)
	if immediate and visibility_budget:visibility_budget.refresh()

func _prompt()->void:
	var pad:=not Input.get_connected_joypads().is_empty()
	progress.text="SUBSTATION 04    /    SERVICE YARD" if _continuous_yard() else "CONCRETE ×5    →    BRIDGE    →    CONCRETE ×4"
	instruction.text="After the last light." if actor.state.begins_with("GroundSit") else "Explore the repeated sections."
	detail.text="Left stick: move · A / Circle: jump · View: reset" if pad else "A / D: move · Ctrl: walk · Shift: sprint · Space: jump · R: reset"

func _physics_process(_delta:float)->void:
	if resetting:return
	if actor.position.y< -3:_restart(true)
