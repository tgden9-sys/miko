@tool
extends SceneTree

func _init() -> void:
	var f := FileAccess.open("res://models/miko8/MIKO8_Native.json", FileAccess.READ)
	if f:
		var json: Dictionary = JSON.parse_string(f.get_as_text())
		var clips: Dictionary = json.get("clips", {})
		for k in clips.keys():
			if "Climb" in k:
				var c: Dictionary = clips[k]
				print(k, " -> duration: ", c.get("duration"), " speed: ", c.get("speed"), " delta: ", c.get("delta"))
				if c.has("feet"):
					var feet: Array = c.get("feet", [])
					if not feet.is_empty():
						print("   first feet: ", feet[0], " last feet: ", feet[-1])
	quit(0)
