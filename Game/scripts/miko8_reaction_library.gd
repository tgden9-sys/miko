extends RefCounted
static func install(actor:CharacterBody3D)->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://models/miko8/MIKO8_Reactions.json"))
	install_data(actor,data,"Reactions")

static func install_data(actor:CharacterBody3D,data:Dictionary,library_name:String)->void:
	if actor.animation_player.has_animation_library(library_name):return
	var library:=AnimationLibrary.new()
	var base:Node=actor.animation_player.get_node(actor.animation_player.root_node)
	var path:=str(base.get_path_to(actor.skeleton))
	for label:String in data.clips:
		var clip:Dictionary=data.clips[label]
		var animation:=Animation.new()
		animation.length=clip.duration
		animation.loop_mode=Animation.LOOP_LINEAR if clip.loop else Animation.LOOP_NONE
		for bone:String in clip.frames[0]:
			for kind:String in ["p","q"]:
				var track:=animation.add_track(Animation.TYPE_POSITION_3D if kind=="p" else Animation.TYPE_ROTATION_3D)
				animation.track_set_path(track,NodePath(path+":"+bone))
				for i in range(clip.frames.size()):
					var values:Array=clip.frames[i][bone][kind]
					var time:float=float(i)*animation.length/float(clip.frames.size()-1)
					if kind=="p":animation.position_track_insert_key(track,time,Vector3(values[0],values[1],values[2]))
					else:animation.rotation_track_insert_key(track,time,Quaternion(values[0],values[1],values[2],values[3]))
		library.add_animation(label,animation)
		actor.clips[label]=library_name+"/"+label
		var metadata:Dictionary=clip.duplicate()
		metadata.erase("frames")
		actor.metadata.clips[label]=metadata
	actor.animation_player.add_animation_library(library_name,library)
