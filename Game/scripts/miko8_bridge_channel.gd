extends Node3D
const CENTRE_X:=33.0
const WIDTH:=12.0
const HEIGHT:=6.0
const REAR_Z:=-3.5
const TOP_Y:=-0.85
const CAMERA_PITCH:=-atan(7.0/18.0)
func _ready()->void:
	name="RecessedServiceChannel"
	var view:=MeshInstance3D.new();view.name="ChannelArtwork"
	var quad:=QuadMesh.new();quad.size=Vector2(WIDTH,HEIGHT)
	# The painting already includes the camera's downward view. Face its card
	# toward that camera so projection does not foreshorten the painting again.
	view.mesh=quad;view.rotation.x=CAMERA_PITCH
	view.position=Vector3(CENTRE_X,TOP_Y,REAR_Z)-view.basis.y*HEIGHT/2
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture=preload("res://art/tutorial/bridge_channel/service_channel_ortho.png")
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	view.material_override=material
	view.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view);view.add_to_group("miko8_budget_visual");view.set_meta("budget_half_width",WIDTH/2)
	var mist:=MeshInstance3D.new();mist.name="SlowChannelMist"
	var mist_quad:=QuadMesh.new();mist_quad.size=Vector2(10.5,3.6)
	mist.mesh=mist_quad;mist.position=Vector3(CENTRE_X,-2.7,-2.8)
	var haze:=ShaderMaterial.new();haze.shader=preload("res://shaders/bridge_channel_mist.gdshader")
	mist.material_override=haze;mist.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mist);mist.add_to_group("miko8_budget_visual");mist.set_meta("budget_half_width",5.25)
