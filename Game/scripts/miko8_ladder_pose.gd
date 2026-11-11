extends SkeletonModifier3D
var actor:CharacterBody3D
var preview_enabled:=false
var last_knee_width:=0.0
var last_foot_width:=0.0
var last_hand_width:=0.0
var maximum_attachment_error:=0.0

func _process(delta:float)->void:
	if not is_instance_valid(actor):return
	var target:=0.0
	if preview_enabled:target=1.0
	if actor.state.begins_with("Climb") and not actor.clips.has("StockLadderUp"):
		target=1.0
		if actor.state in ["ClimbEnter","ClimbTopEnter"]:
			target=smoothstep(0.0,0.35,actor.state_time)
		elif actor.state in ["ClimbExit","ClimbTopExit"]:
			var t:float=actor.state_time/maxf(actor.abilities.transition_duration,0.01)
			target=1.0-smoothstep(0.5,1.0,t)
	influence=move_toward(influence,target,delta*10.0)

func _aim(rig:Skeleton3D,index:int,child:int,target:Vector3)->void:
	var pose:=rig.get_bone_global_pose(index)
	var current:Vector3=rig.get_bone_global_pose(child).origin-pose.origin
	var desired:=target-pose.origin
	if current.length()<0.001 or desired.length()<0.001:return
	pose.basis=Basis(Quaternion(current.normalized(),desired.normalized()))*pose.basis
	rig.set_bone_global_pose(index,pose)

func _solve(rig:Skeleton3D,upper_name:String,lower_name:String,end_name:String,target:Vector3,pole:Vector3)->void:
	var upper:=rig.find_bone(upper_name)
	var lower:=rig.find_bone(lower_name)
	var end:=rig.find_bone(end_name)
	var root:Vector3=rig.get_bone_global_pose(upper).origin
	var mid:Vector3=rig.get_bone_global_pose(lower).origin
	var old_end:=rig.get_bone_global_pose(end)
	var a:=root.distance_to(mid)
	var b:=mid.distance_to(old_end.origin)
	var direction:Vector3=(target-root).normalized()
	var distance:=clampf(root.distance_to(target),absf(a-b)+0.002,a+b-0.004)
	var along:float=(a*a-b*b+distance*distance)/(2.0*distance)
	var height:=sqrt(maxf(0.0,a*a-along*along))
	var bend:Vector3=(pole-direction*pole.dot(direction)).normalized()
	var knee:=root+direction*along+bend*height
	var solved_end:=root+direction*distance
	_aim(rig,upper,lower,knee)
	_aim(rig,lower,end,solved_end)
	var final_pose:=rig.get_bone_global_pose(end)
	maximum_attachment_error=maxf(maximum_attachment_error,final_pose.origin.distance_to(solved_end))
	final_pose.basis=old_end.basis
	if end_name.begins_with("DEF-foot"):
		# Wall-climb feet point outwards. Keep ladder boots facing into the rungs.
		var rest_basis:=rig.get_bone_global_rest(end).basis
		var motion:Vector3=(old_end.basis*rest_basis.inverse()).get_euler()
		final_pose.basis=Basis(Vector3.RIGHT,clampf(motion.x*0.25,-0.20,0.20)-0.08)*rest_basis
	rig.set_bone_global_pose(end,final_pose)

func _process_modification_with_delta(_delta:float)->void:
	var rig:=get_skeleton()
	if not rig or influence<0.001:return
	maximum_attachment_error=0.0
	var center:Vector3=rig.get_bone_global_pose(rig.find_bone("DEF-hips")).origin
	for side:String in ["L","R"]:
		var sign_value:=1.0 if side=="L" else -1.0
		var foot:Vector3=rig.get_bone_global_pose(rig.find_bone("DEF-foot."+side)).origin
		foot.x=center.x+sign_value*0.115
		foot.z=0.22
		_solve(rig,"DEF-thigh."+side,"DEF-shin."+side,"DEF-foot."+side,foot,Vector3(sign_value*0.035,0,1))
		var hand:Vector3=rig.get_bone_global_pose(rig.find_bone("DEF-hand."+side)).origin
		hand.x=center.x+sign_value*0.255
		hand.z=0.28
		_solve(rig,"DEF-upper_arm."+side,"DEF-forearm."+side,"DEF-hand."+side,hand,Vector3(sign_value*0.025,-1,-0.2))
	last_knee_width=absf(rig.get_bone_global_pose(rig.find_bone("DEF-shin.L")).origin.x-rig.get_bone_global_pose(rig.find_bone("DEF-shin.R")).origin.x)
	last_foot_width=absf(rig.get_bone_global_pose(rig.find_bone("DEF-foot.L")).origin.x-rig.get_bone_global_pose(rig.find_bone("DEF-foot.R")).origin.x)
	last_hand_width=absf(rig.get_bone_global_pose(rig.find_bone("DEF-hand.L")).origin.x-rig.get_bone_global_pose(rig.find_bone("DEF-hand.R")).origin.x)
