extends Node
var actor:CharacterBody3D
var active:=false
var elapsed:=0.
var start:=Vector3.ZERO
var goal:=Vector3.ZERO
var body:Node3D
var body_start:=Vector3.ZERO
var saved_mask:=1
func reset()->void:
	if active:actor.collision_mask=saved_mask;actor.model.position=Vector3.ZERO;actor.head_offset.blend_weight=1.
	active=false;body=null
func tick(delta:float,axis:float)->bool:
	if not active:
		if actor.jump_buffer<=0. or absf(axis)<.1 or not actor.is_on_floor() or actor.state not in ["Locomotion","WallBlocked","MoveStart","Brake","GroundStop","SprintEnter","SprintExit"]:return false
		var direction:=Vector3(signf(axis),0,0)
		var ray:=PhysicsRayQueryParameters3D.create(actor.position+Vector3.UP*.35,actor.position+Vector3.UP*.35+direction*.9,5);ray.exclude=[actor.get_rid()]
		var hit:=actor.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() or not hit.collider is RigidBody3D:return false
		if hit.position.distance_to(actor.position+Vector3.UP*.35)>.55:return false
		var down:=PhysicsRayQueryParameters3D.create(Vector3(hit.position.x+direction.x*.35,actor.position.y+1.3,actor.position.z),Vector3(hit.position.x+direction.x*.35,actor.position.y+.15,actor.position.z),5);down.exclude=[actor.get_rid()]
		var top:=actor.get_world_3d().direct_space_state.intersect_ray(down)
		if top.is_empty() or top.collider!=hit.collider:return false
		var rise:float=top.position.y-actor.position.y
		if rise<.45 or rise>1.05:return false
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=actor.body_collision.shape;query.transform=Transform3D(Basis.IDENTITY,top.position+Vector3(0,.93,0));query.collision_mask=5;query.exclude=[actor.get_rid(),hit.collider.get_rid()]
		if not actor.get_world_3d().direct_space_state.intersect_shape(query).is_empty():return false
		body=hit.collider;body_start=body.global_position;start=actor.position;goal=top.position+Vector3.UP*.015;saved_mask=actor.collision_mask;actor.collision_mask=0
		actor.head_offset.blend_weight=0.
		actor.facing=int(signf(axis));actor.visual.rotation.y=actor.facing*PI/2;actor.velocity=Vector3.ZERO;actor.jump_buffer=0.;actor._state("Mantle");actor._play("ClimbLedge",.08);elapsed=0.;active=true
	if not is_instance_valid(body) or body.global_position.distance_to(body_start)>.2:
		actor.position=start;reset();actor._resume_locomotion(0.);return true
	elapsed+=delta
	var duration:float=actor._duration("ClimbLedge");var t:float=clampf(elapsed/duration,0.,1.)
	var rise:float=goal.y-start.y
	actor.position=start.lerp(goal,.2*smoothstep(0.,.4,t)+.8*smoothstep(.65,1.,t));actor.position.y=start.y+maxf(0.,rise-.8)*smoothstep(0.,.35,t)+minf(rise,.8)*smoothstep(.55,1.,t)
	actor.animation_player.advance(delta)
	var data:Dictionary=actor.metadata.clips.ClimbLedge
	actor.model.position=-(actor._sample(data.hip_motion,minf(elapsed,duration),duration)-actor._sample(data.hip_motion,0.,duration))
	if t>.84:actor._play("Idle",.12)
	if t>=1.:
		actor.position=goal;reset();actor.floor_snap_length=.12;actor.walk_plane_floor_y=goal.y;actor._resume_locomotion(0.)
	return true
