extends RefCounted
static func install(actor:CharacterBody3D)->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://models/miko8/MIKO8_LadderTop.json"))
	var library:=AnimationLibrary.new()
	var base:Node=actor.animation_player.get_node(actor.animation_player.root_node)
	var path:=str(base.get_path_to(actor.skeleton))
	actor.metadata["ladder_top_standard"]=data.standard
	for label:String in data.clips:
		var clip:Dictionary=data.clips[label];var animation:=Animation.new()
		animation.length=clip.duration;animation.loop_mode=Animation.LOOP_NONE
		for bone:String in clip.frames[0]:
			for kind:String in ["p","q"]:
				var track:=animation.add_track(Animation.TYPE_POSITION_3D if kind=="p" else Animation.TYPE_ROTATION_3D)
				animation.track_set_path(track,NodePath(path+":"+bone))
				for index in range(clip.frames.size()):
					var value:Array=clip.frames[index][bone][kind]
					var time:float=float(index)*clip.duration/(clip.frames.size()-1)
					if kind=="p":animation.position_track_insert_key(track,time,Vector3(value[0],value[1],value[2]))
					else:animation.rotation_track_insert_key(track,time,Quaternion(value[0],value[1],value[2],value[3]))
		library.add_animation(label,animation);actor.clips[label]="LadderTop/"+label
		actor.metadata.clips[label]={"duration":clip.duration,"loop":false,"source":clip.source,"root_motion":clip.motion}
	actor.animation_player.add_animation_library("LadderTop",library)
