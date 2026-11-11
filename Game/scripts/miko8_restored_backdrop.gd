extends Node3D
## One distant photographic city behind the restored physical bridge and facades.
## The elevated camera needs a depth-compensated, camera-facing painting.
const CITY_TEXTURE:Texture2D=preload("res://art/tutorial/miniature_2d/city_backdrop.png")
const MIN_CARD_WIDTH:=28.0
const CARD_Z:=-22.0
const CAMERA_RISE:=7.0
const CAMERA_RUN:=18.0
const ROOM_LENGTH:=60.0
const DEFAULT_VIEW_HEIGHT:=11.25
const TOP_OVERSCAN_FRACTION:=40.0/1080.0
@export_range(0.0,1.0) var parallax_factor:=0.15
var city_card:MeshInstance3D
var card_mesh:QuadMesh

func _ready()->void:
	name="RestoredDistantCity"
	city_card=MeshInstance3D.new()
	city_card.name="CityPanorama"
	card_mesh=QuadMesh.new()
	city_card.mesh=card_mesh
	city_card.rotation.x=-atan(CAMERA_RISE/CAMERA_RUN)
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.albedo_texture=CITY_TEXTURE
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	city_card.material_override=material
	city_card.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(city_card)
	city_card.add_to_group("miko8_budget_visual")
	update_camera(10.0)

func update_camera(camera_x:float)->void:
	if not is_instance_valid(city_card):return
	var camera:=get_viewport().get_camera_3d()
	var viewport_size:=get_viewport().get_visible_rect().size
	var aspect:float=viewport_size.x/maxf(1.0,viewport_size.y)
	var view_height:float=camera.size if camera else DEFAULT_VIEW_HEIGHT
	var view_width:float=view_height*aspect
	if camera and camera.keep_aspect==Camera3D.KEEP_WIDTH:
		view_width=camera.size
		view_height=view_width/maxf(0.001,aspect)
	var first_camera_x:=view_width*0.5
	var travel:=maxf(0.0,ROOM_LENGTH-view_width)
	# Cover the current viewport plus its full parallax journey, leaving at
	# least 1m beyond either edge. The original view keeps its 28m painting.
	var width:=maxf(MIN_CARD_WIDTH,view_width+travel*parallax_factor+2.0)
	var image_aspect:=float(CITY_TEXTURE.get_width())/float(CITY_TEXTURE.get_height())
	width=maxf(width,view_height*(1.0+TOP_OVERSCAN_FRACTION*2.0)*image_aspect)
	var height:=width/image_aspect
	var mesh_size:=Vector2(width,height)
	if not card_mesh.size.is_equal_approx(mesh_size):
		card_mesh.size=mesh_size
		city_card.set_meta("budget_half_width",width*0.5)
	# Keep the image top 40px above a 1080px view, including when the optional
	# wider game camera changes its size or the elevation of its look target.
	var target_y:float=camera.global_position.y-camera.global_position.z*CAMERA_RISE/CAMERA_RUN if camera else 2.0
	var view_centre_y:=view_height*(0.5+TOP_OVERSCAN_FRACTION)-height*0.5
	city_card.position=Vector3(0,CARD_Z*CAMERA_RISE/CAMERA_RUN+target_y+view_centre_y/cos(city_card.rotation.x),CARD_Z)
	position.x=first_camera_x+travel*parallax_factor*0.5+(camera_x-first_camera_x)*(1.0-parallax_factor)

func _process(_delta:float)->void:
	var camera:=get_viewport().get_camera_3d()
	if camera:update_camera(camera.global_position.x)
