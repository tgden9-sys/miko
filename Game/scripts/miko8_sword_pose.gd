extends SkeletonModifier3D
var combat: Node

func _process_modification_with_delta(_delta: float) -> void:
	if combat.pose_weight <= 0.001: return
	var rig := get_skeleton()
	var clip: Dictionary = combat.data.clips[combat.pose_clip]
	var frames: Array = clip.frames
	var sample: float = clampf(combat.pose_time / float(clip.duration), 0.0, 1.0) * (frames.size() - 1)
	var first := int(sample)
	var second := mini(first + 1, frames.size() - 1)
	for bone: String in frames[first]:
		# Keep locomotion, jump and landing in control of the hips and legs.
		if not (bone.contains("spine") or bone.contains("shoulder") or bone.contains("arm") or bone.contains("hand") or bone.contains("thumb") or bone.contains("DEF-f_")): continue
		var index := rig.find_bone(bone)
		if index < 0: continue
		var a: Array = frames[first][bone].q
		var b: Array = frames[second][bone].q
		var rotation := Quaternion(a[0], a[1], a[2], a[3]).slerp(Quaternion(b[0], b[1], b[2], b[3]), sample - first)
		rig.set_bone_pose_rotation(index, rig.get_bone_pose_rotation(index).slerp(rotation, combat.pose_weight))
