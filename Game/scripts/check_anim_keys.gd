@tool
extends SceneTree

func _init() -> void:
	var glb: PackedScene = load("res://models/miko8/MIKO8_Native.glb")
	var inst: Node3D = glb.instantiate()
	var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for anim_name in ["MIKO8_Climb1mRM", "MIKO8_ClimbLedge"]:
		var a = ap.get_animation(anim_name)
		print("=== Animation: ", anim_name)
		for tr in range(a.get_track_count()):
			var p = str(a.track_get_path(tr))
			if "hips" in p or "foot" in p or "root" in p:
				var k0 = a.track_get_key_value(tr, 0)
				var km = a.track_get_key_value(tr, a.track_get_key_count(tr)/2)
				var k1 = a.track_get_key_value(tr, a.track_get_key_count(tr)-1)
				print("Track ", tr, " (", p, "):")
				print("   t=0: ", k0)
				print("   t=mid: ", km)
				print("   t=end: ", k1)
	inst.free()
	quit(0)
