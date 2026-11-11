extends SceneTree
func _initialize()->void:call_deferred("run")
func winding(mesh:Mesh)->float:
	var a:=mesh.surface_get_arrays(0)
	var index:PackedInt32Array=a[Mesh.ARRAY_INDEX]
	var p:PackedVector3Array=a[Mesh.ARRAY_VERTEX]
	var normals:PackedVector3Array=a[Mesh.ARRAY_NORMAL]
	var face:Vector3=(p[index[1]]-p[index[0]]).cross(p[index[2]]-p[index[0]])
	return face.normalized().dot(normals[index[0]])
func run()->void:
	var bay=preload("res://scripts/miko8_service_bay.gd").new();root.add_child(bay)
	print("REFERENCE_WINDING ",winding(CylinderMesh.new()))
	for part:Dictionary in bay.parts:
		if part.mesh is ArrayMesh:
			print("TUBE_WINDING ",winding(part.mesh))
			assert(winding(part.mesh)< -0.8,"Service tubes must use Godot's clockwise front faces")
	assert(bay.geometry[0].get_surface_count()<=6)
	print("SERVICE_MESH_PASS: pipe winding, smooth normals and batched geometry")
	quit()
