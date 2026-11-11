extends RefCounted
static func install(actor: CharacterBody3D) -> float:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://models/miko8/VanillaLoop_Ladder_Trial.json"))
	var library := AnimationLibrary.new()
	var base: Node = actor.animation_player.get_node(actor.animation_player.root_node)
	var skeleton_path: String = str(base.get_path_to(actor.skeleton))
	for label: String in ["StockLadderUp","StockLadderDown","StockLadderHold"]:
		var animation := Animation.new()
		animation.length = float(data.duration)
		animation.loop_mode = Animation.LOOP_LINEAR
		for bone: String in data.frames[0]:
			for kind: String in ["p","q"]:
				var track := animation.add_track(Animation.TYPE_POSITION_3D if kind=="p" else Animation.TYPE_ROTATION_3D)
				animation.track_set_path(track,NodePath(skeleton_path+":"+bone))
				for i in range(data.frames.size()):
					var index: int = data.frames.size()-1-i if label=="StockLadderDown" else 0 if label=="StockLadderHold" else i
					var value: Array = data.frames[index][bone][kind]
					var time := float(i)*animation.length/float(data.frames.size()-1)
					if kind=="p": animation.position_track_insert_key(track,time,Vector3(value[0],value[1],value[2]))
					else: animation.rotation_track_insert_key(track,time,Quaternion(value[0],value[1],value[2],value[3]))
		library.add_animation(label,animation)
		actor.clips[label] = "StockLadder/"+label
		actor.metadata.clips[label] = {"duration":animation.length,"loop":true,"speed":float(data.rise)/animation.length,"source":data.source}
	actor.animation_player.add_animation_library("StockLadder",library)
	return float(data.rise)/float(data.duration)
