extends SkeletonModifier3D
var actor:CharacterBody3D
var quick_clip:Animation
var quick_arm_tracks:Dictionary={}

func _ready()->void:
	var rig:=get_skeleton()
	var upper:=rig.find_bone("DEF-upper_arm.L")
	quick_clip=actor.animation_player.get_animation(actor.clips.SpellSingleIdle)
	for track in range(quick_clip.get_track_count()):
		if quick_clip.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
		var path:=quick_clip.track_get_path(track)
		if path.get_subname_count()==0:continue
		var bone:=rig.find_bone(path.get_subname(0))
		var parent:=bone
		while parent>=0 and parent!=upper:parent=rig.get_bone_parent(parent)
		if parent==upper:quick_arm_tracks[bone]=track

func _process(delta:float)->void:
	if is_instance_valid(actor) and actor.abilities and actor.abilities.quick_pose_active():
		influence=actor.abilities.quick_pose_weight
		return
	var low_aim: bool = is_instance_valid(actor) and actor.abilities and actor.abilities.crouch_tagging
	var active:bool=is_instance_valid(actor) and (low_aim or actor.state in ["SpellEnter","SpellHold","SpellShoot"])
	influence=move_toward(influence,1.0 if active else 0.0,delta*(18.0 if low_aim else 7.0))
func _process_modification_with_delta(_delta:float)->void:
	if not is_instance_valid(actor) or not actor.abilities:return
	var rig:=get_skeleton()
	var quick: bool = actor.abilities.quick_pose_active()
	if quick or actor.abilities.crouch_tagging:
		# Sample just the firing arm. The AnimationPlayer keeps playing the gait.
		var shot_time:=quick_clip.length*.22
		for bone:int in quick_arm_tracks:
			rig.set_bone_pose_rotation(bone,quick_clip.rotation_track_interpolate(quick_arm_tracks[bone],shot_time))
		var direction: Vector3 = actor.abilities.quick_direction() if quick else actor.abilities.aim_direction()
		var target := rig.global_basis.inverse() * direction
		_aim_arm(rig,"L",target.normalized())
		if not quick: return
		var upper:=rig.find_bone("DEF-upper_arm.L")
		var recoil:float=actor.abilities.quick_recoil
		var pose:=rig.get_bone_global_pose(upper)
		pose.origin-=target.normalized()*.025*recoil
		rig.set_bone_global_pose(upper,pose)
		return
	if actor.state not in ["SpellEnter","SpellHold","SpellShoot"]:return
	var pitch:float=actor.abilities.aim_elevation
	var desired:=Vector3(0,sin(pitch),cos(pitch))
	# Rotate the existing arm pose as a unit; keep its elbow bend and hand shape.
	for side:String in actor.abilities.spell_sides():
		_aim_arm(rig,side,desired)

func _aim_arm(rig:Skeleton3D,side:String,desired:Vector3)->void:
	var upper:=rig.find_bone("DEF-upper_arm."+side)
	var fore:=rig.find_bone("DEF-forearm."+side)
	var hand:=rig.find_bone("DEF-hand."+side)
	var direction:=rig.get_bone_global_pose(hand).origin-rig.get_bone_global_pose(fore).origin
	if direction.length()<.001:return
	var pose:=rig.get_bone_global_pose(upper)
	pose.basis=Basis(Quaternion(direction.normalized(),desired))*pose.basis
	rig.set_bone_global_pose(upper,pose)
