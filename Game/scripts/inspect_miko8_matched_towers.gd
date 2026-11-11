extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var scene=load("res://scenes/miko8_level_02.tscn").instantiate();root.add_child(scene)
	await physics_frame
	var tower=scene.get_node("PlatformTowerCourse").towers[0]
	for mesh:MeshInstance3D in tower.model.find_children("*","MeshInstance3D",true,false):
		print("INSPECT_MESH ",mesh.name," ",mesh.get_aabb())
		for i in range(mesh.mesh.get_surface_count()):
			var raw=mesh.mesh.surface_get_material(i)
			var p=mesh.get_active_material(i)
			print("INSPECT_PAINT ",raw.resource_name," kind=",p.get_shader_parameter("surface_kind"))
	quit()
