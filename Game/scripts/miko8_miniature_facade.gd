extends RefCounted
## A single photograph repeated only by the restored preview's opt-in route.
const ID:="miniature_concrete_repeat_v1"
const TEXTURE_PATH:="res://art/tutorial/facade_library/miniature_concrete_repeat_v1.png"
static var shared_material:ShaderMaterial
static var warned_missing:=false

static func material()->ShaderMaterial:
	if shared_material:return shared_material
	if not ResourceLoader.exists(TEXTURE_PATH):
		if not warned_missing:
			push_warning("Miniature facade image is not imported yet; retaining the original facade library.")
			warned_missing=true
		return null
	var texture:=load(TEXTURE_PATH) as Texture2D
	if not texture:return null
	shared_material=ShaderMaterial.new()
	shared_material.shader=preload("res://shaders/miniature_concrete_facade.gdshader")
	shared_material.set_shader_parameter("art",texture)
	return shared_material
