extends StaticBody3D
## Reusable supplied block; dimensions and the facade can be changed per instance.
@export var dimensions:=Vector3(5.44,2.83364,2.55)
@export_file("*.png") var facade_art:="res://art/cel_scene/ladder_facade_v2.png"
func _ready()->void:
	collision_layer=1;collision_mask=1;add_to_group("tutorial_solids");add_to_group("miko8_budget_visual");set_meta("budget_half_width",dimensions.x*.5+1.0)
	var model:Node3D=preload("res://models/environment/plain_block/plain_block.glb").instantiate();model.name="ReusableBlockModel";add_child(model)
	var bounds:=AABB();var first:=true
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var box:AABB=(model.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds=box if first else bounds.merge(box);first=false
	var fit:=dimensions/bounds.size;model.scale=fit
	model.position=Vector3(-bounds.get_center().x*fit.x,-bounds.position.y*fit.y,-bounds.get_center().z*fit.z)
	var skin:=ShaderMaterial.new();skin.shader=preload("res://shaders/miko8_ladder_building_skin.gdshader")
	skin.set_meta("cel_facade_art",facade_art)
	skin.set_shader_parameter("facade",load(facade_art));skin.set_shader_parameter("concrete",preload("res://art/cel_scene/concrete_v1.png"))
	skin.set_shader_parameter("wall_panels",preload("res://art/cel_scene/ladder_panels_v2.png"));skin.set_shader_parameter("use_wall_panels",true)
	skin.set_shader_parameter("building_origin",global_position);skin.set_shader_parameter("building_height",dimensions.y);skin.set_shader_parameter("facade_height",dimensions.y)
	skin.set_shader_parameter("facade_start_x",-dimensions.x*.5);skin.set_shader_parameter("facade_width",dimensions.x)
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		mesh.layers=4
		for i in range(mesh.mesh.get_surface_count()):mesh.set_surface_override_material(i,skin)
	var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=dimensions;collider.shape=shape;collider.position.y=dimensions.y*.5;add_child(collider)
	var contact:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(dimensions.x+.8,dimensions.z+.8);contact.mesh=plane;contact.position.y=.009
	var gradient:=Gradient.new();gradient.set_color(0,Color(0,0,0,.65));gradient.set_color(1,Color(0,0,0,0))
	var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
	var shade:=StandardMaterial3D.new();shade.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;shade.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;shade.albedo_texture=texture
	contact.material_override=shade;contact.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(contact)
