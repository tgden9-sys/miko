extends SkeletonModifier3D

@export var lift_degrees := 30.0
@export_range(0.0,1.0) var blend_weight:=1.0
var applied_angle := 0.0
var last_before := Quaternion.IDENTITY
var last_after := Quaternion.IDENTITY
var elevation_change := 0.0

func _process_modification_with_delta(_delta: float) -> void:
	var rig := get_skeleton()
	var head := rig.find_bone("DEF-head")
	if head < 0: return
	var before := rig.get_bone_pose_rotation(head)
	var rest := rig.get_bone_global_rest(head).basis
	var before_forward := rig.get_bone_global_pose(head).basis * rest.inverse() * Vector3.BACK
	var after := before * Quaternion(Vector3.RIGHT, deg_to_rad(-lift_degrees*blend_weight))
	rig.set_bone_pose_rotation(head, after)
	var after_forward := rig.get_bone_global_pose(head).basis * rest.inverse() * Vector3.BACK
	elevation_change = rad_to_deg(asin(clampf(after_forward.normalized().y,-1,1))-asin(clampf(before_forward.normalized().y,-1,1)))
	applied_angle = before.angle_to(after)
	last_before = before
	last_after = after
