extends RefCounted
## Only lab actions are installed. Physics owns the body's world translation.
static func install(player: AnimationPlayer, rig: Skeleton3D, file: String) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file))
	var library := AnimationLibrary.new()
	var path := str(player.get_node(player.root_node).get_path_to(rig))
	for label: String in data.clips:
		var clip: Dictionary = data.clips[label]
		var animation := Animation.new()
		animation.length = clip.duration
		animation.loop_mode = Animation.LOOP_LINEAR if label in ["SwordIdle", "ShieldIdle", "CrouchForward"] else Animation.LOOP_NONE
		for bone: String in clip.frames[0]:
			var position_track := animation.add_track(Animation.TYPE_POSITION_3D)
			var rotation_track := animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(position_track, NodePath(path + ":" + bone))
			animation.track_set_path(rotation_track, NodePath(path + ":" + bone))
			for i in range(clip.frames.size()):
				var sample: Dictionary = clip.frames[i][bone]
				var time: float = float(i) * animation.length / float(clip.frames.size() - 1)
				var p := Vector3(sample.p[0], sample.p[1], sample.p[2])
				# Root-motion templates retain local body compression; remove horizontal
				# hips travel only. In this rig hips-local Z is world vertical.
				if bone == "DEF-hips" and label in ["Dash", "GroundPound"]:
					p.x = float(clip.frames[0][bone].p[0])
					p.y = float(clip.frames[0][bone].p[1])
				animation.position_track_insert_key(position_track, time, p)
				animation.rotation_track_insert_key(rotation_track, time, Quaternion(sample.q[0], sample.q[1], sample.q[2], sample.q[3]).normalized())
		library.add_animation(label, animation)
	player.add_animation_library(file.get_file().get_basename(), library)
