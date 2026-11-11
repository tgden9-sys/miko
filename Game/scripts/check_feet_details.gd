@tool
extends SceneTree

func _init() -> void:
	var f := FileAccess.open("res://models/miko8/MIKO8_Native.json", FileAccess.READ)
	if f:
		var json: Dictionary = JSON.parse_string(f.get_as_text())
		var clips: Dictionary = json.get("clips", {})
		for cname in ["Climb1mRM", "ClimbLedge", "ClimbLedgeRM", "ClimbOff2mRM"]:
			var c = clips[cname]
			print("=== ", cname)
			var hm = c.get("hip_motion", [])
			if not hm.is_empty():
				print("   hip_motion[0]: ", hm[0], " mid: ", hm[hm.size()/2], " end: ", hm[-1])
			var feet = c.get("feet", [])
			if not feet.is_empty():
				print("   feet[0]: ", feet[0])
				print("   feet[mid]: ", feet[feet.size()/2])
				print("   feet[end]: ", feet[-1])
	quit(0)
