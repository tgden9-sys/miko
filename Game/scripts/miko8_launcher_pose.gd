extends SkeletonModifier3D
## Two-bone arm solve; source idle/jump animation still drives body and legs.
var actor:CharacterBody3D
var maximum_hand_error:=0.0
func _process_modification_with_delta(_delta:float)->void:
	if not actor.launcher_motion:return
	var motion:Node=actor.launcher_motion
	if motion.grip_weight<=.0001:return
	var rig:=get_skeleton();maximum_hand_error=0.
	for side:String in ["L","R"]:
		if not motion.hand_targets.has(side):continue
		var upper:int=rig.find_bone("DEF-upper_arm."+side)
		var fore:int=rig.find_bone("DEF-forearm."+side)
		var hand:int=rig.find_bone("DEF-hand."+side)
		var shoulder:Vector3=rig.get_bone_global_pose(upper).origin
		var elbow:Vector3=rig.get_bone_global_pose(fore).origin
		var wrist:Vector3=rig.get_bone_global_pose(hand).origin
		var target:Vector3=rig.to_local(motion.hand_targets[side])
		target=wrist.lerp(target,motion.grip_weight)
		var a:float=shoulder.distance_to(elbow);var b:float=elbow.distance_to(wrist)
		var direction:Vector3=(target-shoulder).normalized()
		var distance:float=clampf(shoulder.distance_to(target),absf(a-b)+.002,a+b-.003)
		var along:float=(a*a-b*b+distance*distance)/(2.*distance)
		var height:float=sqrt(maxf(0.,a*a-along*along))
		var pole:=Vector3(0,-.8,-.5)
		var bend:Vector3=(pole-direction*pole.dot(direction)).normalized()
		_aim(rig,upper,fore,shoulder+direction*along+bend*height)
		_aim(rig,fore,hand,shoulder+direction*distance)
		var pose:Transform3D=rig.get_bone_global_pose(hand)
		# Mirrored hand bones have opposite palm axes. Both palms face down,
		# fingertips forward, with a slight relaxed wrist flex over the cap.
		var palm_x:=Vector3.DOWN if side=="L" else Vector3.UP
		var fingers:=Vector3(0,-.12,1).normalized()
		var palm_z:Vector3=palm_x.cross(fingers).normalized()
		var palm_y:Vector3=palm_z.cross(palm_x).normalized()
		var planted:=Basis(palm_x,palm_y,palm_z)
		pose.basis=pose.basis.orthonormalized().slerp(planted,motion.grip_weight)
		rig.set_bone_global_pose(hand,pose)
		maximum_hand_error=maxf(maximum_hand_error,rig.to_global(pose.origin).distance_to(motion.hand_targets[side]))
func _aim(rig:Skeleton3D,bone:int,child:int,target:Vector3)->void:
	var pose:=rig.get_bone_global_pose(bone)
	var current:Vector3=rig.get_bone_global_pose(child).origin-pose.origin
	var desired:Vector3=target-pose.origin
	if current.length_squared()<.000001 or desired.length_squared()<.000001:return
	pose.basis=Basis(Quaternion(current.normalized(),desired.normalized()))*pose.basis
	rig.set_bone_global_pose(bone,pose)
