extends SkeletonModifier3D
## Side-ladder contact correction after the existing boot-orientation modifier.
## Keep the authored step heights while fitting each boot between the rails.
const TOE_RUNG_DEPTH := 0.045
## The toe pivot sits inboard of the boot's outer edge. Allow room for
## the boot shell, rail thickness and cel outline around it.
const TOE_RAIL_CLEARANCE := 0.185
var actor:CharacterBody3D
func _process_modification()->void:
	_process_modification_with_delta(get_process_delta_time())
func _process_modification_with_delta(_delta:float)->void:
	var motion:Node=actor.abilities.bpg_motion
	if not motion.active or not motion.ladder.side_mount:return
	var weight:=1.0
	var phase:float=motion.elapsed/maxf(motion.duration,.001)
	if motion.mode=="bottom_in":weight=smoothstep(.15,.65,phase)
	elif motion.mode=="top_in":weight=smoothstep(.45,.95,phase)
	elif motion.mode=="top_out":weight=1.-smoothstep(.12,.50,phase)
	elif motion.mode=="bottom_out":weight=1.-smoothstep(.15,.75,phase)
	if weight<.001:return
	var rig:=get_skeleton()
	var ladder:Node3D=motion.ladder
	for side:String in ["L","R"]:
		for part:String in ["hand","foot"]:
			var end:=rig.find_bone("DEF-"+part+"."+side)
			var contact:=end if part=="hand" else rig.find_bone("DEF-toe."+side)
			var pose:=rig.get_bone_global_pose(end)
			var local_contact:=ladder.to_local(rig.to_global(rig.get_bone_global_pose(contact).origin))
			# Wrists keep their grip depth. The boot extends beyond its toe pivot
			# in both directions, so fit the shell rather than the bone alone.
			var depth := .045 if part == "hand" else TOE_RUNG_DEPTH
			var sideways := 0.0
			if part == "foot":
				var limit := maxf(0.0, ladder.rail_half_width - TOE_RAIL_CLEARANCE)
				sideways = clampf(local_contact.x, -limit, limit) - local_contact.x
			var adjustment := Vector3(sideways, 0, clampf(depth - local_contact.z, -.18, .18))
			var world_delta := ladder.global_basis * adjustment * weight
			var target:=pose.origin+rig.global_basis.inverse()*world_delta
			_solve(rig,"DEF-"+("upper_arm" if part=="hand" else "thigh")+"."+side,"DEF-"+("forearm" if part=="hand" else "shin")+"."+side,end,target)
func _aim(rig:Skeleton3D,bone:int,child:int,target:Vector3)->void:
	var pose:=rig.get_bone_global_pose(bone)
	var from:=rig.get_bone_global_pose(child).origin-pose.origin
	var to:=target-pose.origin
	if from.length_squared()<.000001 or to.length_squared()<.000001:return
	pose.basis=Basis(Quaternion(from.normalized(),to.normalized()))*pose.basis
	rig.set_bone_global_pose(bone,pose)
func _solve(rig:Skeleton3D,upper_name:String,lower_name:String,end:int,target:Vector3)->void:
	var upper:=rig.find_bone(upper_name);var lower:=rig.find_bone(lower_name)
	var root:=rig.get_bone_global_pose(upper).origin
	var mid:=rig.get_bone_global_pose(lower).origin
	var old:=rig.get_bone_global_pose(end)
	var a:=root.distance_to(mid);var b:=mid.distance_to(old.origin)
	var axis:Vector3=(target-root).normalized()
	var distance:=clampf(root.distance_to(target),absf(a-b)+.002,a+b-.002)
	var along:float=(a*a-b*b+distance*distance)/(2.*distance)
	var bend:Vector3=mid-root-axis*(mid-root).dot(axis)
	if bend.length_squared()<.000001:return
	var joint:=root+axis*along+bend.normalized()*sqrt(maxf(0.,a*a-along*along))
	_aim(rig,upper,lower,joint)
	_aim(rig,lower,end,root+axis*distance)
	var pose:=rig.get_bone_global_pose(end);pose.basis=old.basis
	rig.set_bone_global_pose(end,pose)
