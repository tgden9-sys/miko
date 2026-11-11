@tool
extends SceneTree

func _init() -> void:
	var f := FileAccess.open("res://models/miko8/MIKO8_Native.json", FileAccess.READ)
	if f:
		var json: Dictionary = JSON.parse_string(f.get_as_text())
		var clips: Dictionary = json.get("clips", {})
		print("All clips matching vault, climb, step, ledge, mantle, jump:")
		for k in clips.keys():
			var lk = k.to_lower()
			if "climb" in lk or "vault" in lk or "step" in lk or "ledge" in lk or "mantle" in lk or "hop" in lk:
				print(" - ", k, ": ", clips[k])
	quit(0)
