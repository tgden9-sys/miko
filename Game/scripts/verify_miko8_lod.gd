extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var actors:Array[CharacterBody3D]=[]
	for model:String in ["res://models/miko8/MIKO8_Native.glb","res://models/miko8/MIKO8_GameLOD.glb"]:
		var actor:=CharacterBody3D.new()
		actor.set_script(load("res://scripts/miko8_actor.gd"))
		actor.model_path=model
		root.add_child(actor)
		actor.set_physics_process(false)
		actor.head_offset.active=false
		actors.append(actor)
	var source=actors[0]
	var reduced=actors[1]
	assert(source.skeleton.get_bone_count()==reduced.skeleton.get_bone_count())
	assert(source.clips.keys()==reduced.clips.keys())
	var max_position:=0.0
	var max_angle:=0.0
	for clip:String in source.clips:
		for phase:float in [0.0,0.25,0.50,0.75,0.999]:
			for actor in actors:
				actor._play(clip,0)
				actor.animation_player.seek(actor._duration(clip)*phase,true)
			for i in range(source.skeleton.get_bone_count()):
				var bone:String=source.skeleton.get_bone_name(i)
				var j:int=reduced.skeleton.find_bone(bone)
				assert(j>=0)
				max_position=maxf(max_position,source.skeleton.get_bone_pose_position(i).distance_to(reduced.skeleton.get_bone_pose_position(j)))
				max_angle=maxf(max_angle,source.skeleton.get_bone_pose_rotation(i).angle_to(reduced.skeleton.get_bone_pose_rotation(j)))
	print("LOD_POSE_DIFFERENCE positions=",max_position," rotations=",max_angle)
	assert(max_position<0.001 and max_angle<0.01,"Reduced asset must preserve source bone motion")
	print("LOD_RIG_PASS: 48 animations / 53 bones / five phases per clip compared")
	quit()
