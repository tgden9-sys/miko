@tool
extends SceneTree

func _init() -> void:
	var actor = preload("res://scripts/miko8_actor.gd").new()
	root.add_child(actor)
	await process_frame
	for name in ["ClimbLedge", "ClimbLedgeRM", "Climb1mRM", "Climb2mRM"]:
		if actor.clips.has(name):
			var anim = actor.animation_player.get_animation(actor.clips[name])
			print("--- ", name, " --- length=", anim.length)
			for t in range(anim.get_track_count()):
				var path = str(anim.track_get_path(t))
				if "root" in path.to_lower() or "hip" in path.to_lower():
					print("  track: ", path, " type: ", anim.track_get_type(t), " keys: ", anim.track_get_key_count(t))
					if anim.track_get_type(t) == Animation.TYPE_POSITION_3D and anim.track_get_key_count(t) > 0:
						print("    first key: ", anim.track_get_key_value(t, 0), " last key: ", anim.track_get_key_value(t, anim.track_get_key_count(t)-1))
	quit(0)
