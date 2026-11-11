@tool
extends SceneTree

func _init() -> void:
	var f := FileAccess.open("res://models/miko8/MIKO8_Native.json", FileAccess.READ)
	if f:
		var json: Dictionary = JSON.parse_string(f.get_as_text())
		var clips: Dictionary = json.get("clips", {})
		print("All clips (", clips.size(), "):")
		var keys = clips.keys()
		keys.sort()
		for k in keys:
			var c = clips[k]
			print(" - ", k, " (dur=", c.get("duration"), " loop=", c.get("loop"), ")")
	quit(0)
