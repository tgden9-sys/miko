extends SkeletonModifier3D
var actor:CharacterBody3D
var maximum_yaw_error:=0.0
var modification_count:=0
func _process_modification()->void:
	_process_modification_with_delta(get_process_delta_time())
func _process_modification_with_delta(_delta:float)->void:
	modification_count+=1
	var motion:Node=actor.abilities.bpg_motion
	if not motion.active:return
	var weight:=1.0
	if motion.mode in ["bottom_in","top_in"]:weight=smoothstep(0.,.35,motion.elapsed/motion.duration)
	if motion.mode in ["top_out","bottom_out"]:weight=1.-smoothstep(.45,.9,motion.elapsed/motion.duration)
	var rig:=get_skeleton();maximum_yaw_error=0.
	for side:String in ["L","R"]:
		var foot:int=rig.find_bone("DEF-foot."+side);var toe:int=rig.find_bone("DEF-toe."+side)
		var pose:=rig.get_bone_global_pose(foot)
		var direction:Vector3=rig.get_bone_global_pose(toe).origin-pose.origin;direction.y=0.
		if direction.length_squared()<.000001:continue
		var angle:=direction.normalized().signed_angle_to(Vector3(0,0,1),Vector3.UP)
		pose.basis=Basis(Vector3.UP,angle*weight)*pose.basis;rig.set_bone_global_pose(foot,pose)
		# The toe has its own animated rotation; align its forward bone axis too,
		# otherwise the boot tip can still splay after the ankle is corrected.
		var toe_pose:=rig.get_bone_global_pose(toe)
		var toe_forward:Vector3=toe_pose.basis.y;toe_forward.y=0.
		if toe_forward.length_squared()>.000001:
			var toe_angle:=toe_forward.normalized().signed_angle_to(Vector3(0,0,1),Vector3.UP)
			toe_pose.basis=Basis(Vector3.UP,toe_angle*weight)*toe_pose.basis;rig.set_bone_global_pose(toe,toe_pose)
		var corrected:Vector3=rig.get_bone_global_pose(toe).origin-rig.get_bone_global_pose(foot).origin;corrected.y=0.
		maximum_yaw_error=maxf(maximum_yaw_error,absf(corrected.normalized().signed_angle_to(Vector3(0,0,1),Vector3.UP)))
	# The left boot retains a different roll in the retargeted source. Match
	# the accepted right boot's orientation through each bone's own rest basis,
	# preserving the left ankle position and the alternating rung heights.
	for part:String in ["foot","toe"]:
		var left:int=rig.find_bone("DEF-"+part+".L")
		var right:int=rig.find_bone("DEF-"+part+".R")
		var left_pose:=rig.get_bone_global_pose(left)
		var right_pose:=rig.get_bone_global_pose(right)
		var motion_basis:Basis=right_pose.basis*rig.get_bone_global_rest(right).basis.inverse()
		var desired:Basis=Basis(Vector3.UP,deg_to_rad(-12.))*motion_basis*rig.get_bone_global_rest(left).basis
		left_pose.basis=left_pose.basis.orthonormalized().slerp(desired.orthonormalized(),weight)
		rig.set_bone_global_pose(left,left_pose)

