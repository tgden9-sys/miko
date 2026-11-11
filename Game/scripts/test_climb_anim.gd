@tool
extends SceneTree

func _init() -> void:
	var glb: PackedScene = load("res://models/miko8/MIKO8_Native.glb")
	var inst: Node3D = glb.instantiate()
	root.add_child(inst)
	var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var skel: Skeleton3D = inst.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var foot_l = skel.find_bone("DEF-foot.L")
	var foot_r = skel.find_bone("DEF-foot.R")
	var hips = skel.find_bone("DEF-hips")

	ap.play("MIKO8_Climb1mRM")
	for i in range(10):
		ap.advance(0.066)
		var t = i * 0.066
		var fl_pos = skel.get_bone_global_pose(foot_l).origin
		var fr_pos = skel.get_bone_global_pose(foot_r).origin
		var h_pos = skel.get_bone_global_pose(hips).origin
		print("t=%.3f: foot_l=(%.2f, %.2f, %.2f) foot_r=(%.2f, %.2f, %.2f) hips=(%.2f, %.2f, %.2f)" % [
			t, fl_pos.x, fl_pos.y, fl_pos.z,
			fr_pos.x, fr_pos.y, fr_pos.z,
			h_pos.x, h_pos.y, h_pos.z
		])
	inst.free()
	quit(0)
