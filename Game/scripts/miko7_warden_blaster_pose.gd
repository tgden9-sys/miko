extends SkeletonModifier3D
## Lift the existing right-arm pose and aim the blaster attached to the forearm.
var guard: CharacterBody3D
var upper_arm: int
var forearm: int
var muzzle_local: Vector3
var bore_local: Vector3

func _ready() -> void:
	var rig := get_skeleton()
	upper_arm = rig.find_bone("DEF-upper_arm.R")
	forearm = rig.find_bone("DEF-forearm.R")
	var hand := rig.find_bone("DEF-hand.R")
	var rest := rig.get_bone_global_rest(forearm)
	var muzzle: Vector3 = guard.model.to_global(Vector3(-0.538, 0.968, 0.114))
	muzzle_local = rest.affine_inverse() * rig.to_local(muzzle)
	bore_local = rest.basis.inverse() * (rig.get_bone_global_rest(hand).origin - rest.origin).normalized()

func _process_modification_with_delta(_delta: float) -> void:
	var rig := get_skeleton()
	if guard.aim_weight > 0.001:
		var elbow := rig.get_bone_global_pose(forearm)
		var shoulder := rig.get_bone_global_pose(upper_arm)
		var bore := (elbow.basis * bore_local).normalized()
		var aim: Vector3 = rig.to_local(guard.aim_target) - elbow.origin
		aim += rig.global_basis.inverse() * Vector3.UP * guard.recoil * 0.12
		if aim.length_squared() > 0.0001:
			var lift := Quaternion.IDENTITY.slerp(Quaternion(bore, aim.normalized()), guard.aim_weight)
			shoulder.basis = Basis(lift) * shoulder.basis
			rig.set_bone_global_pose(upper_arm, shoulder)
	guard.muzzle_position = rig.to_global(rig.get_bone_global_pose(forearm) * muzzle_local)
