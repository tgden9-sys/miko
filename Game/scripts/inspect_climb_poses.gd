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

	for anim_name in ["MIKO8_Climb1mRM", "MIKO8_ClimbLedge", "MIKO8_ClimbLedgeRM"]:
		if ap.has_animation(anim_name):
			print("--- Testing ", anim_name, " ---")
			ap.play(anim_name)
			var a = ap.get_animation(anim_name)
			for t in [0.0, 0.2, 0.4, 0.6, a.length]:
				ap.seek(t, true)
				skel.force_update_all_bone_transforms()
				var fl_pos = skel.get_bone_global_pose(foot_l).origin
				var fr_pos = skel.get_bone_global_pose(foot_r).origin
				var h_pos = skel.get_bone_global_pose(hips).origin
				print("t=%.2f: foot_l.y=%.3f, foot_r.y=%.3f, hips.y=%.3f" % [t, fl_pos.y, fr_pos.y, h_pos.y])
	inst.free()
	quit(0)
