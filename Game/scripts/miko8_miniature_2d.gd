extends "res://scripts/miko8_tutorial.gd"
const SCENE_HEIGHT:=15.0
const WIDTH:=SCENE_HEIGHT*16.0/9.0
const FOOT_ROW:=2.0/3.0
const ART_FOOT_ROW:=0.54
const START_X:=WIDTH*.07
const CRATE_X:=WIDTH*.85
var stage:MeshInstance3D
var city:MeshInstance3D
func _world()->void:
	var world:=WorldEnvironment.new();var env:=Environment.new();world.environment=env
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("152033")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("9ba7bd");env.ambient_light_energy=.45
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;add_child(world)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-40,-30,0);key.light_color=Color("e7e6df");key.light_energy=.62;add_child(key)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-35,140,0);fill.light_color=Color("a6bbdc");fill.light_energy=.22;add_child(fill)
	for x:float in [WIDTH*.15,WIDTH*.835]:
		var lamp:=OmniLight3D.new();lamp.position=Vector3(x,2.6,1.0);lamp.light_color=Color("ffb864");lamp.light_energy=1.4;lamp.omni_range=4;add_child(lamp)
func _backgrounds()->void:pass
func _foreground()->void:pass
func _details()->void:
	var crate:=preload("res://scripts/miko8_charge_box.gd").new();crate.name="TutorialChargeCrate";crate.position=Vector3(CRATE_X,.4,0);crate.freeze=true;add_child(crate)
func _ready()->void:
	super._ready()
	var old:=get_node("PaintedGroundKit");remove_child(old);old.queue_free()
	_floor()
	actor.position=Vector3(START_X,.02,0);_camera(0,true)
	stage=_card("NearScenery", "res://art/tutorial/miniature_2d/bridge_stage.png",true,1.0)
	city=_card("CityParallax", "res://art/tutorial/miniature_2d/city_backdrop.png",false,1.045)
	_cards()
	get_viewport().msaa_3d=Viewport.MSAA_2X
	title.text="MIKO   /   SUBSTATION 04";progress.text=""
	DisplayServer.window_set_title("MIKO — Miniature 2D / One-screen proof")
	print("MINIATURE_2D_READY: two image layers, invisible collision, 3D MIKO/crate; foot row=",FOOT_ROW)
func _card(label:String,path:String,alpha:bool,scale_value:float)->MeshInstance3D:
	var card:=MeshInstance3D.new();card.name=label;var q:=QuadMesh.new();q.size=Vector2(WIDTH,SCENE_HEIGHT)*scale_value;card.mesh=q
	if alpha:
		var material:=ShaderMaterial.new();material.shader=preload("res://shaders/miniature_plate.gdshader");material.set_shader_parameter("art",load(path));card.material_override=material
	else:
		var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_texture=load(path);material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR;material.disable_fog=true;card.material_override=material
	card.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(card);return card
func _floor()->void:
	var floor:=StaticBody3D.new();floor.name="InvisibleGameplayFloor";var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(WIDTH,.5,2.8);collision.shape=box;floor.position=Vector3(WIDTH/2,-.25,0);floor.add_child(collision);add_child(floor);floor.add_to_group("tutorial_solids")
	for x:float in [-.25,WIDTH+.25]:
		var wall:=StaticBody3D.new();var shape:=CollisionShape3D.new();var block:=BoxShape3D.new();block.size=Vector3(.5,5,4);shape.shape=block;wall.position=Vector3(x,2,0);wall.add_child(shape);add_child(wall)
func _camera(_delta:float,_immediate:=false)->void:
	var target_y:=(FOOT_ROW-.5)*SCENE_HEIGHT/cos(deg_to_rad(19.0))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=SCENE_HEIGHT
	camera.position=Vector3(WIDTH/2,target_y+16*tan(deg_to_rad(19.0)),16);camera.look_at(Vector3(WIDTH/2,target_y,0))
	_cards()
func _cards()->void:
	if not is_instance_valid(stage):return
	var centre:=get_viewport().get_visible_rect().size/2
	var art_shift:=Vector2(0,(FOOT_ROW-ART_FOOT_ROW)*get_viewport().get_visible_rect().size.y)
	stage.global_transform=Transform3D(camera.global_basis,camera.project_position(centre+art_shift,24))
	var drift:=clampf((actor.position.x-WIDTH/2)*1.2,-12,12)
	city.global_transform=Transform3D(camera.global_basis,camera.project_position(centre+Vector2(-drift,0),28))
func _prompt()->void:
	instruction.text="After the last light." if actor.state.begins_with("GroundSit") else "Find your feet."
	detail.text="Left stick: move · A / Circle: jump · View: reset" if not Input.get_connected_joypads().is_empty() else "A / D: move · Ctrl: walk · Shift: sprint · Space: jump · R: reset"
func _physics_process(_delta:float)->void:
	if not resetting and actor.position.y< -3:_restart(true)
func _restart(wake:=false)->void:
	if resetting:return
	resetting=true;actor.set_physics_process(false)
	var tween:=create_tween();tween.tween_property(fade,"color:a",1.0,.25);await tween.finished
	actor.reset_actor();actor.position=Vector3(START_X,.02,0)
	if wake:actor.reactions.sit(true)
	_camera(0,true);actor.set_physics_process(true)
	tween=create_tween();tween.tween_property(fade,"color:a",0.0,.4);await tween.finished;resetting=false
