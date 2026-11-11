extends Node3D
## Quiet first room: wake, cross the bridge, jump one real crate.
const ACTOR=preload("res://scripts/miko8_actor.gd")
const ROOM_LENGTH:=32.0
const VIEW_HEIGHT:=11.25
@export var use_game_lod:=true
@export_file("*.glb") var game_lod_path := "res://models/miko8/MIKO8_FastLOD.glb"
var actor:CharacterBody3D
var camera:Camera3D
var parallax:Array[Dictionary]=[]
var title:Label
var instruction:Label
var detail:Label
var progress:Label
var performance:Label
var fps_reported:=false
var fade:ColorRect
var phase:=0
var elapsed:=0.0
var walk_distance:=0.0
var run_distance:=0.0
var previous_x:=2.4
var jumped:=false
var completed:=false
var resetting:=false
var audio:AudioStreamPlayer
var scene_presence:Node3D
var visibility_budget:Node

func _ready()->void:
	get_viewport().msaa_3d=Viewport.MSAA_DISABLED
	DisplayServer.window_set_title("MIKO â€” Blue hour / Substation 04")
	_world();_backgrounds()
	add_child(preload("res://scripts/miko8_tutorial_ground.gd").new())
	_details();_foreground()
	actor=CharacterBody3D.new();actor.name="MIKO";actor.set_script(ACTOR)
	if use_game_lod and not "--full-mesh" in OS.get_cmdline_user_args():actor.model_path=game_lod_path
	actor.movement_only=true;add_child(actor)
	actor.polarity_control.set_process_unhandled_input(false)
	for material:ShaderMaterial in actor.polarity_control.materials:
		material.set_shader_parameter("scene_tint",Color(0.94,0.965,1.0))
		material.set_shader_parameter("scene_roughness_bias",0.12)
	actor.position=Vector3(2.4,0.02,0);actor.reactions.sit(true)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect=Camera3D.KEEP_HEIGHT;camera.size=VIEW_HEIGHT;camera.current=true
	add_child(camera)
	scene_presence=preload("res://scripts/miko8_scene_presence.gd").new()
	scene_presence.actor=actor;scene_presence.camera=camera;add_child(scene_presence)
	_camera(0,true);_hud();_sound()
	visibility_budget=preload("res://scripts/miko8_visibility_budget.gd").new()
	visibility_budget.camera=camera;add_child(visibility_budget)
	print("SUBSTATION_READY: 32m / four ground modules / continuous bridge / one crate / 48 clips")

func _world()->void:
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("17243d")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("7386b6");env.ambient_light_energy=0.48
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-24,-48,0)
	sun.light_color=Color("a5b9ef");sun.light_energy=0.42;sun.shadow_enabled=true;add_child(sun)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-35,135,0)
	fill.light_color=Color("a1b8da");fill.light_energy=0.13;add_child(fill)

func _plane(label:String,factor:float)->Node3D:
	var node:=Node3D.new();node.name=label;add_child(node)
	parallax.append({"node":node,"factor":factor});return node

func _art(parent:Node3D,path:String,at:Vector3,width:float,blur:=0.0,mist:=0.0)->Sprite3D:
	var sprite:=Sprite3D.new();sprite.texture=load(path)
	sprite.pixel_size=width/float(sprite.texture.get_width());sprite.position=at
	sprite.shaded=false;sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var material:=ShaderMaterial.new();material.shader=preload("res://shaders/tutorial_depth_art.gdshader")
	material.set_shader_parameter("art",sprite.texture);material.set_shader_parameter("blur_lod",blur)
	material.set_shader_parameter("mist",mist)
	if "far_skyline" in path or "mid_apartments" in path:
		material.set_shader_parameter("scene_tint",Vector3(0.28,0.31,0.48))
		material.set_shader_parameter("mist_color",Color("273653"))
	sprite.material_override=material;sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(sprite);sprite.add_to_group("miko8_budget_visual")
	sprite.set_meta("budget_half_width",width/2);return sprite

func _backgrounds()->void:
	var sky:=_plane("BG1_Dusk",0.0)
	var quad:=MeshInstance3D.new();var q:=QuadMesh.new();q.size=Vector2(80,35)
	quad.mesh=q;quad.position=Vector3(8,7,-30)
	var material:=ShaderMaterial.new();material.shader=preload("res://shaders/tutorial_dawn.gdshader")
	quad.material_override=material;sky.add_child(quad)
	_art(_plane("BG2_FarMegablocks",0.10),"res://art/tutorial/far_skyline_haze.png",Vector3(12,6.5,-20),56,2.4,0.84)
	_art(_plane("BG3_ApartmentLayers",0.28),"res://art/tutorial/mid_apartments.png",Vector3(15,5.4,-12),32,0,0.20)
	var rear:=_plane("BG4_Substation",0.70)
	_art(rear,"res://art/tutorial/substation_dusk_panorama.png",Vector3(14.4,4.8,-2.4),28.8)
	_atmosphere(rear)

func _atmosphere(rear:Node3D)->void:
	for z:float in [-8.0,-3.5]:
		var mist:=MeshInstance3D.new();var q:=QuadMesh.new();q.size=Vector2(42,4)
		mist.mesh=q;mist.position=Vector3(15,1.7,z)
		var m:=ShaderMaterial.new();m.shader=preload("res://shaders/tutorial_mist.gdshader")
		m.set_shader_parameter("strength",0.10 if z< -5 else 0.035)
		mist.material_override=m;mist.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;rear.add_child(mist)
	for x:float in [6.0,21.0]:
		var ray:=MeshInstance3D.new();var q:=QuadMesh.new();q.size=Vector2(5,6)
		ray.mesh=q;ray.position=Vector3(x,3,-1.15)
		var m:=ShaderMaterial.new()
		m.shader=preload("res://shaders/tutorial_lightshaft.gdshader")
		ray.material_override=m;ray.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;rear.add_child(ray)

func _details()->void:
	var crate:=preload("res://scripts/miko8_charge_box.gd").new()
	crate.name="TutorialChargeCrate";crate.position=Vector3(28,0.40,0);crate.freeze=true;add_child(crate)
	for x:float in [2.0,6.3,12.1,18.2,23.5,29.4]:
		var practical:=OmniLight3D.new();practical.position=Vector3(x,1.75,-0.9)
		practical.light_color=Color("ffc58c");practical.light_energy=1.25
		practical.omni_range=3.7;practical.omni_attenuation=1.4;add_child(practical)
	for x:float in [9.0,20.5,27.0]:
		var electric:=OmniLight3D.new();electric.position=Vector3(x,1.1,-0.9)
		electric.light_color=Color("70cbdc");electric.light_energy=0.55;electric.omni_range=2.6;add_child(electric)
	var spill:=OmniLight3D.new();spill.position=Vector3(1.8,3.2,-1.8)
	spill.light_color=Color("f3bd79");spill.light_energy=0.85;spill.omni_range=5;add_child(spill)
	for x:float in [7.3,18.0,27.3]:
		var steam:=MeshInstance3D.new();var q:=QuadMesh.new();q.size=Vector2(1.7,1.35)
		steam.mesh=q;steam.position=Vector3(x,0.75,-1.1)
		var m:=ShaderMaterial.new();m.shader=preload("res://shaders/tutorial_steam.gdshader")
		steam.material_override=m;steam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(steam)

func _foreground()->void:
	var backing:=MeshInstance3D.new();var wall:=QuadMesh.new();wall.size=Vector2(80,6)
	backing.mesh=wall;backing.position=Vector3(16,-3.1,-4)
	var shade:=StandardMaterial3D.new();shade.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	shade.albedo_color=Color("111c24");backing.material_override=shade;add_child(backing)
	var fg:=_plane("FG_Defocused",1.15)
	for upper:bool in [true,false]:
		var card:=MeshInstance3D.new();var q:=QuadMesh.new();q.size=Vector2(40,2.5 if upper else 2.0)
		card.mesh=q;card.position=Vector3(16,8.5 if upper else -2.65,3)
		var m:=ShaderMaterial.new();m.shader=preload("res://shaders/tutorial_foreground.gdshader")
		m.set_shader_parameter("art",preload("res://art/tutorial/foreground_defocus.png"))
		m.set_shader_parameter("vertical_crop",Vector2(0,0.32) if upper else Vector2(0.64,1))
		card.material_override=m;card.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;fg.add_child(card)

func _hud()->void:
	var layer:=CanvasLayer.new();add_child(layer)
	var health_bar := preload("res://scripts/miko8_health_bar.gd").new()
	health_bar.actor = actor
	layer.add_child(health_bar)
	var root:=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(root)
	title=Label.new();title.position=Vector2(38,28);title.text="BLUE HOUR   /   SUBSTATION 04"
	title.add_theme_font_size_override("font_size",24);title.modulate=Color("e0d8c9");root.add_child(title)
	progress=Label.new();progress.position=Vector2(38,54);progress.add_theme_font_size_override("font_size",18)
	progress.modulate=Color("b2c0c8");root.add_child(progress)
	performance=Label.new();performance.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	performance.offset_left=-350;performance.offset_right=-38;performance.offset_top=28;performance.offset_bottom=58
	performance.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;performance.add_theme_font_size_override("font_size",20)
	performance.modulate=Color("e0d8c9");performance.visible="--show-fps" in OS.get_cmdline_user_args();root.add_child(performance)
	var panel:=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left=0;panel.offset_right=0;panel.offset_top=-108;panel.offset_bottom=0
	var style:=StyleBoxFlat.new();style.bg_color=Color(0.035,0.055,0.075,0.94)
	style.border_width_top=1;style.border_color=Color(0.38,0.44,0.48,0.45)
	style.content_margin_top=12;style.content_margin_bottom=12;style.content_margin_left=24;style.content_margin_right=24
	panel.add_theme_stylebox_override("panel",style);root.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",5);panel.add_child(column)
	instruction=Label.new();instruction.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size",28);instruction.modulate=Color("e8dfcf");column.add_child(instruction)
	detail=Label.new();detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size",20);detail.modulate=Color("adbdc9");column.add_child(detail)
	fade=ColorRect.new();fade.color=Color.BLACK;fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(fade);_prompt()

func _sound()->void:
	audio=AudioStreamPlayer.new();audio.stream=load("res://art/tutorial/substation_ambience.wav")
	audio.volume_db=-15;add_child(audio);audio.play();audio.finished.connect(audio.play)

func _camera(delta:float,immediate:=false)->void:
	var width:=VIEW_HEIGHT*get_viewport().get_visible_rect().size.x/maxf(1,get_viewport().get_visible_rect().size.y)
	var goal:=clampf(actor.position.x+1.5,width/2,ROOM_LENGTH-width/2)
	var x:float=goal if immediate else lerpf(camera.position.x,goal,1-exp(-4.5*delta))
	camera.position=Vector3(x,5.10,16);camera.look_at(Vector3(x,2.55,0))
	for plane:Dictionary in parallax:plane.node.position.x=(x-width/2)*(1-plane.factor)
	if immediate and visibility_budget:visibility_budget.refresh()

func _prompt()->void:
	var pad:=not Input.get_connected_joypads().is_empty()
	var prompts:Array=[
		["After the last light.","Move the left stick to get up" if pad else "Press A / D to get up"],
		["Find your feet.","Move right across the bridge Â· tilt gently to walk" if pad else "Move right across the bridge Â· Ctrl + D to walk"],
		["Over the crate.","A / Circle to jump Â· keep moving right" if pad else "Space to jump Â· D to move right"],
		["You're ready, MIKO.","Room complete Â· View / Select to wake again" if pad else "Room complete Â· R to wake again"]]
	instruction.text=prompts[phase][0];detail.text=prompts[phase][1]
	progress.text="WAKE  %s     WALK  %s     JUMP  %s" % ["âœ“" if phase>0 else "Â·","âœ“" if actor.position.x>22.5 else "Â·","âœ“" if completed else "Â·"]

func _process(delta:float)->void:
	elapsed+=delta
	if is_instance_valid(performance) and performance.visible:
		var size:=DisplayServer.window_get_size()
		performance.text="%d FPS  /  %d Ã— %d" % [Engine.get_frames_per_second(),size.x,size.y]
		if not fps_reported and elapsed>10:
			fps_reported=true;print("LIVE_FPS ",Engine.get_frames_per_second()," window=",size," render=",get_viewport().get_texture().get_size())
	_camera(delta)
	if not resetting:fade.color.a=maxf(0,1-elapsed/1.8)
	_prompt()

func _physics_process(_delta:float)->void:
	if resetting:return
	var travel:=absf(actor.position.x-previous_x);previous_x=actor.position.x
	if actor.state=="Locomotion" and actor.current_clip=="Walk":walk_distance+=travel
	if actor.state=="Locomotion" and actor.current_clip in ["Run","Sprint"]:run_distance+=travel
	if actor.state in ["JumpStart","Air"]:jumped=true
	if phase==0 and not actor.state.begins_with("GroundSit"):phase=1
	if phase==1 and actor.position.x>22.5:phase=2
	if phase==2 and actor.position.x>29.2 and jumped and actor.is_on_floor():completed=true;phase=3
	if actor.position.y< -2:_restart(false)

func _restart(wake:=true)->void:
	if resetting:return
	resetting=true;actor.set_physics_process(false)
	var tween:=create_tween();tween.tween_property(fade,"color:a",1.0,0.25);await tween.finished
	actor.reset_actor();actor.position=_restart_position();previous_x=actor.position.x
	if wake:
		phase=0;walk_distance=0;run_distance=0;jumped=false;completed=false;actor.reactions.sit(true)
	_camera(0,true);actor.set_physics_process(true)
	tween=create_tween();tween.tween_property(fade,"color:a",0.0,0.4);await tween.finished;resetting=false

func _restart_position() -> Vector3:
	return Vector3(2.4, .02, 0)

func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_R:_restart()
		if event.physical_keycode==KEY_M:audio.stream_paused=not audio.stream_paused
		if event.physical_keycode==KEY_F3:performance.visible=not performance.visible

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_BACK:_restart()


