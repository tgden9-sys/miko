extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var world:=Node3D.new();root.add_child(world)
	var cam:=Camera3D.new();cam.position=Vector3(0,1,4);cam.look_at_from_position(cam.position,Vector3.ZERO);world.add_child(cam)
	var attr:=CameraAttributesPractical.new();attr.dof_blur_far_enabled=true;attr.dof_blur_far_distance=5;attr.dof_blur_amount=.15;cam.attributes=attr
	var mesh:=MeshInstance3D.new();mesh.mesh=SphereMesh.new();world.add_child(mesh)
	for i in range(8):await process_frame
	print("DIORAMA_RENDERER ",RenderingServer.get_current_rendering_method()," ",RenderingServer.get_video_adapter_name())
	quit()
