@tool
extends SceneTree

func _init() -> void:
	var glb: PackedScene = load("res://models/miko8/MIKO8_Native.glb")
	var inst: Node3D = glb.instantiate()
	var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var a: Animation = ap.get_animation("MIKO8_Climb1mRM")
	print("Climb1mRM tracks:")
	for i in range(a.get_track_count()):
		print(i, ": ", a.track_get_path(i))
	inst.free()
	quit(0)
