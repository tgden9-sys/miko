extends Node3D
var camera:Camera3D
var pieces:Array[Dictionary]=[]
func _ready()->void:
	name="DefocusedForeground"
	_piece(Vector3(7,-.45,3.2),Vector2(3.0,3.2),Rect2(0,0,.31,1),3.3)
	_piece(Vector3(40,-1.05,3.5),Vector2(4.3,3.4),Rect2(.66,0,.34,1),3.5)
	_piece(Vector3(60,-.75,3.2),Vector2(2.4,3.0),Rect2(0,0,.31,1),3.2)
	# Keep only ground-mounted foreground fixtures. The isolated hanging cable
	# cutouts expose their unsupported ends when the camera follows a climb.
	_process(0)
func _piece(at:Vector3,size:Vector2,region:Rect2,blur:float)->void:
	var node:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=size;node.mesh=quad
	var material:=ShaderMaterial.new();material.shader=preload("res://shaders/miko8_side_on_foreground.gdshader")
	material.set_shader_parameter("art",preload("res://art/tutorial/side_on_mockup/foreground_cutouts.png"))
	material.set_shader_parameter("region",Vector4(region.position.x,region.position.y,region.size.x,region.size.y))
	material.set_shader_parameter("blur_lod",blur);node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)
	pieces.append({"node":node,"anchor":at})
func _process(_delta:float)->void:
	if not is_instance_valid(camera):return
	var camera_x:float=camera.get_meta("walkway_focus_x",camera.global_position.x)
	for piece:Dictionary in pieces:
		var at:Vector3=piece.anchor+Vector3((camera_x-16.0)*(-.12),0,0)
		# Godot culls the actual projected quad, including its depth and yaw.
		piece.node.global_transform=Transform3D(camera.global_basis,at)
