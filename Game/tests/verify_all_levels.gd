extends SceneTree

const SCENES := [
	"res://scenes/miko8_side_on_mockup.tscn",
	"res://scenes/miko8_level_02.tscn",
	"res://scenes/miko8_level_03.tscn",
	"res://scenes/miko7_patrol_yard.tscn"
]

func _initialize() -> void:
	call_deferred("test_all")

func test_all() -> void:
	print("=== VERIFYING ALL 4 LEVELS LOAD CLEANLY ===")
	for i in range(SCENES.size()):
		var path: String = SCENES[i]
		var scene: Node = load(path).instantiate()
		root.add_child(scene)
		current_scene = scene
		for frame in range(10):
			await physics_frame
		print("PASS Level ", i + 1, " (", scene.name, ") length=", scene._ground_length(), "m")
		root.remove_child(scene)
		scene.free()
	print("=== ALL 4 LEVELS VERIFIED SUCCESSFULLY ===")
	quit(0)
