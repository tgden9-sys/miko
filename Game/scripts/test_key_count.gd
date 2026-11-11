@tool
extends SceneTree

func _init() -> void:
	var glb: PackedScene = load("res://models/miko8/MIKO8_Native.glb")
	var inst: Node3D = glb.instantiate()
	var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for anim_name in ["MIKO8_Climb1mRM", "MIKO8_ClimbLedge", "MIKO8_ClimbLedgeRM", "MIKO8_ClimbUp", "MIKO8_ClimbDown"]:
		if ap.has_animation(anim_name):
			var a: Animation = ap.get_animation(anim_name)
			print(anim_name, " keys in track 0: ", a.track_get_key_count(0), " track 1: ", a.track_get_key_count(1), " track 44 (thigh): ", a.track_get_key_count(44))
	inst.free()
	quit(0)
