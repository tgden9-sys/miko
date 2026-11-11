extends RefCounted
## One mutual nearest neighbour per direction in the gameplay plane.
const RANGE:=400.*1.9/96.
static func is_block(node:Node)->bool:
	return node is RigidBody3D or node.is_in_group("miko8_fixed_magnets")
static func _direction(offset:Vector3)->int:
	if absf(offset.x)>=absf(offset.y):return 0 if offset.x<0. else 1
	return 2 if offset.y<0. else 3
static func _nearest(a:Node3D,b:Node3D,candidates:Array[Node])->bool:
	var delta:Vector3=b.global_position-a.global_position
	var direction:int=_direction(delta)
	var distance:float=Vector2(delta.x,delta.y).length_squared()
	for candidate:Node in candidates:
		if candidate==a or candidate==b or not is_block(candidate) or candidate.get("polarity")==0:continue
		var other:Vector3=(candidate as Node3D).global_position-a.global_position
		if absf(other.z)>.85 or _direction(other)!=direction:continue
		var squared:float=Vector2(other.x,other.y).length_squared()
		if squared<distance-.00001:return false
		if absf(squared-distance)<=.00001 and candidate.get_instance_id()<b.get_instance_id():return false
	return true
static func connected(a:Node3D,b:Node3D)->bool:
	if a==b or not is_block(a) or not is_block(b) or a.get("polarity")==0 or b.get("polarity")==0:return false
	var delta:Vector3=b.global_position-a.global_position
	if absf(delta.z)>.85 or Vector2(delta.x,delta.y).length()>RANGE:return false
	if a.get("breakaway_remaining")>0. or b.get("breakaway_remaining")>0.:return false
	if a.has_method("can_reach_block") and not a.can_reach_block(b):return false
	if b.has_method("can_reach_block") and not b.can_reach_block(a):return false
	var candidates:Array[Node]=a.get_tree().get_nodes_in_group("miko8_charge_targets")
	return _nearest(a,b,candidates) and _nearest(b,a,candidates)
