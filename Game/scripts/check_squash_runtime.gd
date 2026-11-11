extends SceneTree

func _initialize() -> void:
	var scene_res = load("res://scenes/industrial_city.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	var robot = scene.get_node("Robot")
	robot.global_position = Vector2(1780, 830)
	
	for i in range(12):
		await physics_frame
		print("Frame ", i, " squash: ", robot.squash_stretch, " scale: ", robot.sprite.scale)
	quit(0)
