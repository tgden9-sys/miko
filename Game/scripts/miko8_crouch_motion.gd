extends Node
const TRANSITION_RATE:=1.5
const WALK_RATE:=1.25
const HEIGHT:=1.20
var actor:CharacterBody3D
var low_collider:=false
var down_time:=0.0
var last_tick:=-1
func _collider(low:bool)->void:
	var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=HEIGHT if low else 1.8
	actor.body_collision.shape=capsule;actor.body_collision.rotation=Vector3.ZERO;actor.body_collision.position=Vector3(0,capsule.height*.5,0);low_collider=low
func reset()->void:
	down_time=0.
	if low_collider:_collider(false)
func can_stand()->bool:
	var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.8
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,actor.global_position+Vector3(0,.92,0));query.collision_mask=1;query.margin=0.;query.exclude=[actor.get_rid()]
	return actor.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
func tick(delta:float,axis:float)->bool:
	var active:bool=actor.state.begins_with("Crouch")
	var held:=Input.is_action_pressed("miko8_down")
	var frame:=Engine.get_physics_frames()
	if frame!=last_tick+1:down_time=0.
	last_tick=frame
	if not active:
		if low_collider:reset()
		if Input.get_action_strength("miko8_down")<.65 or not actor.is_on_floor() or actor.state not in ["Locomotion","GroundStop","WallBlocked","MoveStart","Brake","SprintEnter","SprintExit","Land","Turn"]:
			down_time=0.
			return false
		down_time+=delta
		if down_time<.22:return false
		down_time=0.
		actor.turn_queue.clear();actor.model.position=Vector3.ZERO;_collider(true);actor._state("CrouchEnter");actor._play("CrouchEnter",.12,TRANSITION_RATE)
	# A deliberate jump exits crouch immediately when the full capsule fits.
	# Under a duct, retain the low collider and consume the blocked jump.
	if actor.jump_buffer>0. and actor.is_on_floor() and can_stand():
		_collider(false)
		down_time=0.
		actor._begin_jump()
		return false
	actor.jump_buffer=0.
	if actor.state!="Crouch":actor.velocity.x=move_toward(actor.velocity.x,0.,delta*actor.STOP_DECELERATION)
	if actor.state=="CrouchEnter":
		if actor.state_time>=actor._duration("CrouchEnter")/TRANSITION_RATE:actor._state("Crouch");actor._play("CrouchIdle",.10)
	elif actor.state=="CrouchExit":
		if actor.state_time>=actor._duration("CrouchExit")/TRANSITION_RATE:
			actor._resume_locomotion(axis);return false
	else:
		if not held and can_stand():
			actor.velocity.x=0.
			_collider(false);actor._state("CrouchExit");actor._play("CrouchExit",.10,TRANSITION_RATE)
		elif absf(axis)>.02:
			actor.facing=1 if axis>0 else -1;actor.target_facing=actor.facing
			actor.visual.rotation.y=lerp_angle(actor.visual.rotation.y,actor.facing*PI/2.,1.-exp(-9.*delta))
			var native_speed:float=actor.metadata.clips.CrouchForward.speed
			var desired:float=native_speed*WALK_RATE*clampf(absf(axis)/.65,.15,1.)*signf(axis)
			actor.velocity.x=move_toward(actor.velocity.x,desired,delta*6.)
			actor._play("CrouchForward",.12,1.);actor.animation_player.speed_scale=clampf(absf(actor.velocity.x)/native_speed,.12,WALK_RATE)
		else:
			actor.velocity.x=move_toward(actor.velocity.x,0.,delta*8.)
			actor._play("CrouchIdle",.10);actor.animation_player.speed_scale=1.
	actor.velocity.y=0. if actor.is_on_floor() else actor.velocity.y-actor.GRAVITY*delta
	actor.move_and_slide();actor.position.z=actor.walk_plane_z;actor.animation_player.advance(delta)
	return true
