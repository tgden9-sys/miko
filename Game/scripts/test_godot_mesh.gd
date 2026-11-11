extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	var err = gltf.append_from_file("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb", state)
	var scene = gltf.generate_scene(state)
	root.add_child(scene)
	
	print("--- GODOT MESH INSPECTION ---")
	for child in scene.get_children():
		print("Child: ", child.name, " class: ", child.get_class())
		if child is MeshInstance3D:
			var aabb = child.get_aabb()
			print("  AABB: pos=", aabb.position, " size=", aabb.size)
	quit(0)
