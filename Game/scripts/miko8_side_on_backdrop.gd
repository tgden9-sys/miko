extends Node3D
## Camera-facing scenery for the separate side-on mockup. No collision or lights.
const CITY_TEXTURE:Texture2D=preload("res://art/tutorial/miniature_2d/city_backdrop.png")
const CITY_FAR_PATH:="res://art/tutorial/side_on_mockup/city_far.png"
const CITY_MID_PATH:="res://art/tutorial/side_on_mockup/city_mid.png"
const MIN_CITY_WIDTH:=28.0
const TOP_OVERSCAN_FRACTION:=40.0/1080.0
const SPLIT_CITY_EDGE_MARGIN:=0.20
@export var room_length:=60.0
@export_range(0.0,1.0) var city_parallax_factor:=0.15
@export_range(0.0,1.0) var far_city_parallax_factor:=0.10
@export_range(0.0,1.0) var mid_city_parallax_factor:=0.40
@export var city_depth:=55.0
@export var mid_city_depth:=35.0
@export var mid_city_height_offset:=2.4
var city_card:MeshInstance3D
var city_mid_card:MeshInstance3D
var city_mesh:QuadMesh
var city_layers_active:=false
var flat_art:Array[Dictionary]=[]
var city_asset_poll:=0.0
var service_yard:Node3D
@export_range(.25,1.0) var brightness:=.50

func set_brightness(value:float)->void:
	brightness=clampf(value,.25,1.0)
	for card:MeshInstance3D in get_children():
		if card.material_override is StandardMaterial3D:
			card.material_override.albedo_color=Color(brightness,brightness,brightness,1)
		elif card.material_override is ShaderMaterial and (card==city_card or card==city_mid_card):
			card.material_override.set_shader_parameter("brightness",brightness)
	if is_instance_valid(service_yard):
		service_yard.set_brightness(brightness)

func _ready()->void:
	name="SideOnParallaxBackdrop"
	city_mesh=QuadMesh.new()
	city_card=_make_card("DistantCity",CITY_TEXTURE,city_mesh,false)
	# This card always covers the camera. A reset must not briefly cull it
	# against the previous frame's position before its parallax update runs.
	city_card.remove_from_group("miko8_budget_visual")
	try_enable_city_layers()
	var camera:=_active_camera()
	if camera:update_camera(float(camera.get_meta("walkway_focus_x",camera.global_position.x)))

func try_enable_city_layers()->bool:
	if city_layers_active:return true
	if not is_instance_valid(city_card):return false
	# Switch only as a complete pair. The approved unsplit photograph must not
	# remain behind a second copy of its skyline while one import is pending.
	if not ResourceLoader.exists(CITY_FAR_PATH) or not ResourceLoader.exists(CITY_MID_PATH):return false
	var far_texture:=load(CITY_FAR_PATH) as Texture2D
	var mid_texture:=load(CITY_MID_PATH) as Texture2D
	if not far_texture or not mid_texture:return false
	_enable_city_layers(far_texture,mid_texture)
	return true

func _enable_city_layers(far_texture:Texture2D,mid_texture:Texture2D)->void:
	(city_card.material_override as StandardMaterial3D).albedo_texture=far_texture
	city_mid_card=_make_card("MidCity",mid_texture,QuadMesh.new(),true)
	city_mid_card.remove_from_group("miko8_budget_visual")
	city_layers_active=true

func _active_camera()->Camera3D:
	if not is_inside_tree():return null
	return get_viewport().get_camera_3d()

func _fallback_basis()->Basis:
	return Basis.from_euler(Vector3(-deg_to_rad(6.0),0,0))

func _make_card(label:String,texture:Texture2D,quad:QuadMesh,transparent:bool)->MeshInstance3D:
	var card:=MeshInstance3D.new()
	card.name=label
	card.mesh=quad
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA if transparent else BaseMaterial3D.TRANSPARENCY_DISABLED
	material.cull_mode=BaseMaterial3D.CULL_BACK
	material.albedo_texture=texture
	material.albedo_color=Color(brightness,brightness,brightness,1)
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	card.material_override=material
	card.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(card)
	card.add_to_group("miko8_budget_visual")
	card.set_meta("budget_half_width",quad.size.x*0.5)
	return card

func _art_texture(path:String)->Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("Side-on scenery is not imported: "+path)
		return null
	return load(path) as Texture2D

func add_flat_art(path:String,center:Vector3,size:Vector2,factor:=0.8)->MeshInstance3D:
	var texture:=_art_texture(path)
	if not texture:return null
	return _add_art(texture,center,size,factor,false)

func add_grounded_art(path:String,bottom_center:Vector3,width:float,factor:=0.85,height_override:=0.0,origin_x:=INF)->MeshInstance3D:
	var texture:=_art_texture(path)
	if not texture:return null
	var height:float=height_override if height_override>0.0 else width*float(texture.get_height())/float(texture.get_width())
	return _add_art(texture,bottom_center,Vector2(width,height),factor,true,origin_x)

func _add_art(texture:Texture2D,anchor:Vector3,size:Vector2,factor:float,grounded:bool,origin_x:=INF)->MeshInstance3D:
	var quad:=QuadMesh.new()
	quad.size=size
	var card:=_make_card("GroundedScenery" if grounded else "FlatScenery",texture,quad,true)
	# These few wide quads are already frustum-culled by the renderer. Their
	# parallax bounds must never be hidden by the narrow prop activity budget.
	card.remove_from_group("miko8_budget_visual")
	var record:={"mesh":card,"anchor":anchor,"size":size,"factor":clampf(factor,0,1),"grounded":grounded}
	if is_finite(origin_x):record["origin_x"]=origin_x
	flat_art.append(record)
	var camera:=_active_camera()
	var facing:Basis=camera.global_basis if camera else _fallback_basis()
	_place_art(record,facing,float(camera.get_meta("walkway_focus_x",camera.global_position.x)) if camera else room_length*0.5)
	return card

func _place_art(record:Dictionary,facing:Basis,camera_x:float)->void:
	var card:MeshInstance3D=record.mesh
	if not is_instance_valid(card):return
	var center:Vector3=record.anchor
	# World-upright yard elevations share the actual walkway's vanishing
	# direction. Camera-facing lower edges would float above the sloping deck.
	var art_basis:Basis=Basis.IDENTITY if record.grounded else facing
	if record.grounded:center+=art_basis.y*record.size.y*0.5
	# Anchors describe the composition at the middle of the room. Factor1.0
	# stays fixed in the world; smaller factors move more slowly across view.
	center+=art_basis.x*(camera_x-float(record.get("origin_x",room_length*.5)))*(1.0-record.factor)
	if card.is_inside_tree():card.global_transform=Transform3D(art_basis,center)
	else:card.transform=Transform3D(art_basis,center)

var _last_update_camera_x:float=-9999.0
var _last_camera_transform:=Transform3D.IDENTITY
var _last_view_size:=Vector2.ZERO
var _last_camera_size:=0.0
func update_camera(camera_x:float)->void:
	var camera:=_active_camera()
	if not camera:return
	var viewport_size:=get_viewport().get_visible_rect().size
	if is_equal_approx(camera_x,_last_update_camera_x) and camera.global_transform.is_equal_approx(_last_camera_transform) and viewport_size==_last_view_size and is_equal_approx(camera.size,_last_camera_size):return
	_last_update_camera_x=camera_x
	_last_camera_transform=camera.global_transform
	_last_view_size=viewport_size
	_last_camera_size=camera.size
	var aspect:float=viewport_size.x/maxf(1.0,viewport_size.y)
	var view_height:float=camera.size
	var view_width:float=view_height*aspect
	if camera.keep_aspect==Camera3D.KEEP_WIDTH:
		view_width=camera.size
		view_height=view_width/maxf(0.001,aspect)
	var first_camera_x:=minf(view_width*0.5,room_length*0.5)
	var travel:=maxf(0.0,room_length-view_width)
	var image_aspect:=float(CITY_TEXTURE.get_width())/float(CITY_TEXTURE.get_height())
	var width:=maxf(MIN_CITY_WIDTH,view_width+travel*city_parallax_factor+2.0)
	if city_layers_active:
		# The current 32m composition already has enough room for the mid city.
		# Expand both cards together only when a longer room or changed factor
		# would otherwise expose an edge; their image framing always matches.
		var coverage_factor:=maxf(far_city_parallax_factor,mid_city_parallax_factor)
		width=maxf(width,view_width+travel*coverage_factor+SPLIT_CITY_EDGE_MARGIN*2.0)
	width=maxf(width,view_height*(1.0+TOP_OVERSCAN_FRACTION*2.0)*image_aspect)
	# Preserve the established 80m composition's scale on longer routes.
	# Extra distance requires horizontal coverage, not skyscrapers growing taller.
	var reference_travel:=maxf(0.,minf(room_length,80.)-view_width)
	var reference_width:=maxf(view_height*(1.+TOP_OVERSCAN_FRACTION*2.)*image_aspect,view_width+reference_travel*maxf(far_city_parallax_factor,mid_city_parallax_factor)+SPLIT_CITY_EDGE_MARGIN*2.)
	width=maxf(reference_width,view_width+travel*(far_city_parallax_factor if city_layers_active else city_parallax_factor)+2.)
	var height:=reference_width/image_aspect
	if city_card.material_override is ShaderMaterial:city_card.material_override.set_shader_parameter("horizontal_fill",width/reference_width)
	var size:=Vector2(width,height)
	if not city_mesh.size.is_equal_approx(size):
		city_mesh.size=size
		city_card.set_meta("budget_half_width",width*0.5)
	var layers:Array[Dictionary]=[{"card":city_card,"factor":far_city_parallax_factor if city_layers_active else city_parallax_factor,"depth":city_depth}]
	if city_layers_active:layers.append({"card":city_mid_card,"factor":mid_city_parallax_factor,"depth":mid_city_depth})
	var screen_up:=view_height*(0.5+TOP_OVERSCAN_FRACTION)-height*0.5
	for layer:Dictionary in layers:
		var center_x:float=first_camera_x+travel*layer.factor*0.5+(camera_x-first_camera_x)*(1.0-layer.factor)
		var center:Vector3=camera.global_position-camera.global_basis.z*layer.depth+camera.global_basis.y*screen_up
		if layer.card==city_mid_card:
			# Give the continuous skyline independent framing above the near roofs.
			var mid_mesh:QuadMesh=city_mid_card.mesh
			var mid_width:float=view_width+travel*mid_city_parallax_factor+3.
			var reference_mid_width:=view_width+reference_travel*mid_city_parallax_factor+3.
			var skyline_height:float=reference_mid_width/5.4
			# Extend the opaque lower walls beneath the courtyard sightline.
			# Moving the roofline upward must never leave floating bases in alleys.
			mid_mesh.size=Vector2(mid_width,skyline_height+4.)
			center.y=skyline_height*.5-1.9
			if city_mid_card.material_override is ShaderMaterial:
				city_mid_card.material_override.set_shader_parameter("vertical_fill",(skyline_height+4.)/skyline_height)
				city_mid_card.material_override.set_shader_parameter("horizontal_fill",mid_width/reference_mid_width)
		center+=camera.global_basis.x*(center_x-camera_x)
		(layer.card as MeshInstance3D).global_transform=Transform3D(camera.global_basis,center)
	for record:Dictionary in flat_art:_place_art(record,camera.global_basis,camera_x)

func _process(delta:float)->void:
	if not city_layers_active:
		city_asset_poll-=delta
		if city_asset_poll<=0.0:
			city_asset_poll=0.75
			try_enable_city_layers()
	var camera:=_active_camera()
	if camera:update_camera(float(camera.get_meta("walkway_focus_x",camera.global_position.x)))
