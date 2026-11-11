extends Node
var scene:Node3D
var shader_cache:Dictionary={}
var material_cache:Dictionary={}
var converted:=0
var outline:ShaderMaterial
const ART:="res://art/cel_scene/"
var city_style:OptionButton
var far_paint:ShaderMaterial
func _ready()->void:
	name="CelSceneArt";scene=get_parent();add_to_group("miko8_cel_art")
	outline=ShaderMaterial.new();outline.shader=preload("res://shaders/miko8_cel_outline.gdshader")
	for mesh:MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
		if not mesh.mesh:continue
		var path:=str(mesh.get_path())
		if "/MIKO/" in path:continue
		if mesh==scene.layered_scenery.city_card:continue
		if mesh.material_override:
			mesh.material_override=convert_material(mesh.material_override,path)
		else:
			for i in range(mesh.mesh.get_surface_count()):mesh.set_surface_override_material(i,convert_material(mesh.get_active_material(i),path))
	convert_batches(scene)
	var cards=scene.layered_scenery
	far_paint=ShaderMaterial.new();far_paint.shader=preload("res://shaders/miko8_bokeh_paint.gdshader")
	far_paint.set_shader_parameter("brightness",cards.brightness)
	cards.city_card.material_override=far_paint
	city_style=OptionButton.new();city_style.name="CityArtworkStyle";city_style.focus_mode=Control.FOCUS_NONE
	city_style.add_item("City: Cel bokeh");city_style.add_item("City: Previous")
	city_style.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	city_style.offset_left=-274;city_style.offset_right=-38;city_style.offset_top=264;city_style.offset_bottom=300
	city_style.add_theme_font_size_override("font_size",18);scene.game_size.get_parent().add_child(city_style)
	city_style.item_selected.connect(set_city_style);set_city_style(0)
	for i in range(cards.flat_art.size()):
		var material:StandardMaterial3D=cards.flat_art[i].mesh.material_override
		material.albedo_texture=load(cards.flat_art[i].mesh.get_meta("cel_art_path",ART+("near_yard_v1.png" if i%2==0 else "near_extension_v1.png")))
	if cards.city_mid_card:
		var mid_paint:=ShaderMaterial.new();mid_paint.shader=preload("res://shaders/miko8_mid_skyline.gdshader")
		mid_paint.set_shader_parameter("art",load(ART+"mid_industrial_continuous_v2.png"));mid_paint.set_shader_parameter("brightness",cards.brightness)
		cards.city_mid_card.material_override=mid_paint
	for material:ShaderMaterial in scene.actor.polarity_control.graphic_materials:material.next_pass=outline
	print("CEL_SCENE_READY converted=",converted," far_city=",far_paint.get_shader_parameter("art").resource_path)
func set_city_style(index:int)->void:
	city_style.select(index)
	far_paint.set_shader_parameter("art",load(ART+"city_far_bokeh_v1.png" if index==0 else "res://art/tutorial/side_on_mockup/city_far.png"))
	# The new image is painted already; the previous image retains its old treatment.
	far_paint.set_shader_parameter("paint_strength",0.0 if index==0 else .32)
func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F9:
		set_city_style(1-city_style.selected);get_viewport().set_input_as_handled()
func convert_debris(branch:Node)->void:
	for mesh:MeshInstance3D in branch.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):mesh.set_surface_override_material(i,convert_material(mesh.get_active_material(i),str(mesh.get_path())))
	convert_batches(branch)
func convert_batches(branch:Node)->void:
	for visual:MultiMeshInstance3D in branch.find_children("*","MultiMeshInstance3D",true,false):
		if not visual.multimesh or not visual.multimesh.mesh:continue
		var original:Material=visual.material_override if visual.material_override else visual.multimesh.mesh.surface_get_material(0)
		visual.material_override=convert_material(original,str(visual.get_path()))
func cel_shader(source:Shader)->Shader:
	if shader_cache.has(source):return shader_cache[source]
	var code:String=source.code
	code=code.replace("vec3(2.20,1.75,1.15)","vec3(.84,.86,.89)")
	code=code.replace("texture(base_texture,UV)","textureLod(base_texture,UV,.65)")
	if "render_mode" in code:
		var a:=code.find("render_mode");var b:=code.find(";",a)
		var mode:=code.substr(a,b-a)
		if not "unshaded" in mode:code=code.insert(b,",unshaded")
	else:code=code.replace("shader_type spatial;","shader_type spatial;\nrender_mode unshaded;")
	code=code.replace("shader_type spatial;","shader_type spatial;\n#include \"res://shaders/miko8_cel_scene_common.gdshaderinc\"")
	if "void vertex()" in code:code=code.replace("void vertex(){","void vertex(){cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);").replace("void vertex() {","void vertex() {cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);")
	else:code+="\nvoid vertex(){cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}\n"
	var a:=code.find("void fragment");var b:=code.find("{",a);var depth:=1;var index:=b+1
	while depth>0 and index<code.length():
		if code[index]=="{":depth+=1
		elif code[index]=="}":depth-=1
		index+=1
	if a>=0:
		var finish:="\nALBEDO=cel_paint(ALBEDO)*cel_light(cel_world_normal);METALLIC=0.0;SPECULAR=0.0;\n"
		# Compatibility's unshaded path reads ALBEDO directly. Add the crate's
		# powered fittings after the metal receives its cel lighting.
		if source.resource_path=="res://shaders/miko8_crate.gdshader":
			finish+="ALBEDO+=EMISSION;EMISSION=vec3(0.0);\n"
		code=code.insert(index-1,finish)
	var shader:=Shader.new();shader.code=code;shader_cache[source]=shader;return shader
func convert_material(original:Material,path:String)->Material:
	if not original:return original
	if material_cache.has(original):return material_cache[original]
	if original is StandardMaterial3D:
		if original.albedo_texture and ("moss" in original.albedo_texture.resource_path.to_lower() or "ivy" in original.albedo_texture.resource_path.to_lower()):
			var leaves:=ShaderMaterial.new();leaves.shader=preload("res://shaders/miko8_cel_foliage.gdshader")
			leaves.set_shader_parameter("leaf_texture",original.albedo_texture)
			leaves.set_shader_parameter("uv_scale",Vector2(original.uv1_scale.x,original.uv1_scale.y))
			leaves.set_shader_parameter("uv_offset",Vector2(original.uv1_offset.x,original.uv1_offset.y))
			material_cache[original]=leaves;converted+=1;return leaves
		if original.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED or original.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:return original
		var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_cel_surface.gdshader")
		if "/BridgePlatformModel/" in path:paint.shader=preload("res://shaders/miko8_bridge_platform_cel.gdshader")
		paint.set_shader_parameter("base_texture",original.albedo_texture);paint.set_shader_parameter("base_color",original.albedo_color)
		paint.set_shader_parameter("use_vertex_color",original.vertex_color_use_as_albedo)
		material_cache[original]=paint;converted+=1;return paint
	if original is ShaderMaterial:
		var file:String=original.shader.resource_path.get_file()
		if file=="miko8_side_on_foreground.gdshader":
			original.set_shader_parameter("art",load(ART+"foreground_v1.png"));original.set_shader_parameter("blur_lod",1.0);return original
		if file in ["miko8_loader.gdshader","miko8_crate.gdshader","miko8_ladder_building_skin.gdshader","miko8_restored_paving.gdshader","miko8_shared_concrete.gdshader","miko8_bridge_steel.gdshader","ortho_preview_wear.gdshader","miko8_yard_grass.gdshader","miniature_concrete_facade.gdshader","painted_facade_library.gdshader"]:
			original.shader=cel_shader(original.shader)
			if file=="miko8_loader.gdshader" and "/WorkshopModel/" in path:
				original.set_shader_parameter("base_texture",load(ART+"workshop_atlas_v1.png"))
			if file=="miko8_ladder_building_skin.gdshader":
				original.set_shader_parameter("facade",load(original.get_meta("cel_facade_art",ART+"ladder_facade_v2.png")));original.set_shader_parameter("concrete",load(ART+"concrete_v1.png"))
				original.set_shader_parameter("wall_panels",load(ART+"ladder_panels_v2.png"));original.set_shader_parameter("use_wall_panels",true)
			elif file=="miko8_shared_concrete.gdshader":original.set_shader_parameter("grain",load(ART+"concrete_v1.png"))
			elif file=="miko8_restored_paving.gdshader":original.set_shader_parameter("grain",load(ART+"concrete_v1.png"));original.set_shader_parameter("damp_amount",.12)
			elif file in ["miniature_concrete_facade.gdshader","painted_facade_library.gdshader"]:original.set_shader_parameter("art",load(ART+"foundation_v1.png"))
			material_cache[original]=original;converted+=1
	return original

