extends "res://scripts/miko8_miniature_2d.gd"
## Two adjoining painted screens with one continuous physical floor.
## Stage cards are world geometry: only the distant city follows the camera.
const SCREEN_WIDTH := WIDTH
const TOTAL_WIDTH := SCREEN_WIDTH * 2.0
const SECOND_CRATE_X := 40.0
const CAMERA_LOOK_AHEAD := 3.0
const CAMERA_FOLLOW_RATE := 4.5
const CITY_PARALLAX_FACTOR := 0.15
const CITY_OVERSCAN := 1.20

var stage_b: MeshInstance3D
var cards_anchored := false
var stage_a_anchor := Transform3D.IDENTITY
var stage_b_anchor := Transform3D.IDENTITY
var city_anchor := Transform3D.IDENTITY

func _ready() -> void:
	# The inherited setup calls our camera/card methods before making its cards.
	# Keep those calls harmless until both stage tiles can be anchored together.
	super._ready()
	stage.name = "WorldStageBridge"
	stage.material_override=_joined_material("bridge_stage_ortho.png",Vector3(.505,.54,.645),.98,.5)
	stage_b = _card("WorldStageService", "res://art/tutorial/miniature_2d/service_stage.png", true, 1.0)
	stage_b.material_override=_joined_material("service_stage.png",Vector3(.495,.54,.605),.953,.5)
	(stage_b.material_override as ShaderMaterial).set_shader_parameter("register_upper",true)
	var city_mesh := city.mesh as QuadMesh
	city_mesh.size = Vector2(SCREEN_WIDTH, SCENE_HEIGHT) * CITY_OVERSCAN
	_anchor_cards()
	for x:float in [SCREEN_WIDTH+SCREEN_WIDTH*.15,SCREEN_WIDTH+SCREEN_WIDTH*.835]:
		var lamp:=OmniLight3D.new();lamp.position=Vector3(x,2.6,1.0);lamp.light_color=Color("ffb864");lamp.light_energy=1.4;lamp.omni_range=4;add_child(lamp)
	title.text = "MIKO   /   SUBSTATION 04"
	progress.text = ""
	DisplayServer.window_set_title("MIKO — Miniature 2D / Two-screen walk")
	print("MINIATURE_TWO_SCREENS_READY: ", TOTAL_WIDTH, "m / fixed world stage cards / continuous floor / 15% city parallax")

func _joined_material(file:String,rows:Vector3,width_ratio:float,vx:float)->ShaderMaterial:
	var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/miniature_joined_plate.gdshader")
	mat.set_shader_parameter("art",load("res://art/tutorial/miniature_2d/"+file))
	mat.set_shader_parameter("source_rows",rows);mat.set_shader_parameter("back_width_ratio",width_ratio);mat.set_shader_parameter("vanishing_x",vx)
	return mat

func _details() -> void:
	var crate := preload("res://scripts/miko8_charge_box.gd").new()
	crate.name = "TutorialChargeCrate"
	crate.position = Vector3(SECOND_CRATE_X, 0.4, 0)
	crate.freeze = true
	add_child(crate)

func _floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "InvisibleGameplayFloor"
	var collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(TOTAL_WIDTH, 0.5, 2.8)
	collision.shape = floor_shape
	floor_body.position = Vector3(TOTAL_WIDTH / 2.0, -0.25, 0)
	floor_body.add_child(collision)
	add_child(floor_body)
	floor_body.add_to_group("tutorial_solids")
	for x: float in [-0.25, TOTAL_WIDTH + 0.25]:
		var wall := StaticBody3D.new()
		wall.name = "LeftLevelBoundary" if x < 0 else "RightLevelBoundary"
		var wall_collision := CollisionShape3D.new()
		var wall_shape := BoxShape3D.new()
		wall_shape.size = Vector3(0.5, 5, 4)
		wall_collision.shape = wall_shape
		wall.position = Vector3(x, 2, 0)
		wall.add_child(wall_collision)
		add_child(wall)

func _camera(delta: float, immediate := false) -> void:
	var target_y := (FOOT_ROW - 0.5) * SCENE_HEIGHT / cos(deg_to_rad(19.0))
	var goal := clampf(actor.position.x + CAMERA_LOOK_AHEAD, SCREEN_WIDTH / 2.0, TOTAL_WIDTH - SCREEN_WIDTH / 2.0)
	var x := goal if immediate else lerpf(camera.position.x, goal, 1.0 - exp(-CAMERA_FOLLOW_RATE * delta))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = SCENE_HEIGHT
	camera.position = Vector3(x, target_y + 16.0 * tan(deg_to_rad(19.0)), 16)
	camera.look_at(Vector3(x, target_y, 0))
	_cards()
	if immediate and visibility_budget:
		visibility_budget.refresh()

func _anchor_cards() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var centre := viewport_size / 2.0
	var art_shift := Vector2(0, (FOOT_ROW - ART_FOOT_ROW) * viewport_size.y)
	stage_a_anchor = Transform3D(camera.global_basis, camera.project_position(centre + art_shift, 24))
	stage_b_anchor = stage_a_anchor
	stage_b_anchor.origin += Vector3.RIGHT * SCREEN_WIDTH
	stage.global_transform = stage_a_anchor
	stage_b.global_transform = stage_b_anchor
	city_anchor = Transform3D(camera.global_basis, camera.project_position(centre, 28))
	# Centre the small city drift inside its overscan, keeping both end views covered.
	city_anchor.origin.x += (TOTAL_WIDTH - SCREEN_WIDTH) * CITY_PARALLAX_FACTOR * 0.5
	city.global_transform = city_anchor
	cards_anchored = true
	_cards()

func _cards() -> void:
	if not cards_anchored:
		return
	# Natural distant scenery traverses only 15% as far across the frame.
	# The near stage transforms above never change when the camera follows.
	var city_transform := city_anchor
	city_transform.origin.x += (camera.position.x - SCREEN_WIDTH / 2.0) * (1.0 - CITY_PARALLAX_FACTOR)
	city.global_transform = city_transform
