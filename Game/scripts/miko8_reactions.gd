extends Node
const CRAWL_RATE:=1.5
const HIT_DAMAGE := 25
var actor:CharacterBody3D
var toggle_crawl:=false
var crouched:=false
var next_death:=1
var hit_clip:="HitShoulderLeft"
func _ready()->void:
	if not InputMap.has_action("miko8_crawl"):InputMap.add_action("miko8_crawl")
	var button:=InputEventJoypadButton.new()
	button.device=-1;button.button_index=JOY_BUTTON_LEFT_STICK
	InputMap.action_add_event("miko8_crawl",button)
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_Z
	InputMap.action_add_event("miko8_crawl",key)
func _unhandled_input(event:InputEvent)->void:
	if not actor.ready_for_input or not actor.is_physics_processing():return
	if actor.movement_only:return
	if event.is_action_pressed("miko8_crawl"):toggle_crawl=true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_V:sit()
		if event.physical_keycode==KEY_H:take_hit("HitKnockback" if event.alt_pressed else "HitStomach" if event.ctrl_pressed else "HitHead" if event.shift_pressed else "HitShoulderLeft")
		elif event.physical_keycode==KEY_DELETE:die(2 if event.shift_pressed else 1)
func _collider(crawl:bool)->void:
	var collision:CollisionShape3D=actor.body_collision
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.35 if crawl else 0.28
	capsule.height=1.70 if crawl else 1.80
	collision.shape=capsule
	collision.rotation.z=PI/2 if crawl else 0.0
	collision.position=Vector3(0,0.35 if crawl else 0.9,0)
	crouched=crawl
func reset()->void:
	toggle_crawl=false
	if crouched:_collider(false)
	if actor.head_offset:
		actor.head_offset.active=true
		actor.head_offset.blend_weight=1.0
func _can_stand()->bool:
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.28;capsule.height=1.8
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule
	query.transform=Transform3D(Basis.IDENTITY,actor.global_position+Vector3(0,0.92,0))
	query.margin=0
	query.collision_mask=1
	query.exclude=[actor.get_rid()]
	return actor.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func _can_crawl()->bool:
	var capsule:=CapsuleShape3D.new()
	# Leave the same small floor clearance as the standing space check.
	capsule.radius=.35
	capsule.height=1.70
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule
	query.transform=Transform3D(Basis(Vector3.BACK,PI*.5),actor.global_position+Vector3(0,.37,0))
	query.collision_mask=actor.collision_mask
	query.exclude=[actor.get_rid()]
	return actor.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
func sit(start_seated:=false)->void:
	if actor.state=="GroundSitIdle":
		actor._state("GroundSitExit")
		actor.head_offset.active=true
		actor.head_offset.blend_weight=0.0
		actor._play("GroundSitExit",0.12)
	elif start_seated or (actor.is_on_floor() and actor.state in ["Locomotion","GroundStop","WallBlocked"]):
		actor.velocity=Vector3.ZERO
		actor.head_offset.active=true
		actor.head_offset.blend_weight=0.0 if start_seated else 1.0
		actor._state("GroundSitIdle" if start_seated else "GroundSitEnter")
		actor._play("GroundSitIdle" if start_seated else "GroundSitEnter",0.0 if start_seated else 0.12)
func take_hit(reaction:="HitShoulderLeft", combat_bolt := false)->void:
	if actor.state == "Dead": return
	var can_react: bool = actor.state not in ["HitReact", "HitDown"] and not actor.state.begins_with("Climb") and not crouched
	if not can_react and not combat_bolt: return
	if reaction not in ["HitShoulderLeft","HitHead","HitStomach","HitKnockback","HitKnockbackRM"]:return
	actor.health = maxi(0, actor.health - HIT_DAMAGE)
	if actor.health == 0:
		die()
		return
	if not can_react: return
	if actor.get_meta("action_momentum", false):
		actor.velocity.x *= 0.75
		return
	hit_clip=reaction
	actor.abilities.reset()
	actor.velocity.x=0
	actor.head_offset.active=not hit_clip.begins_with("HitKnockback")
	actor._state("HitReact")
	actor._play(hit_clip,0.05)
func die(variant:=1)->void:
	if actor.state=="Dead":return
	actor.health = 0
	actor.abilities.reset()
	var from_crawl:=crouched
	actor.velocity.x=0
	actor.head_offset.active=false
	actor._state("Dead")
	actor._play("Death2" if variant==2 or from_crawl else "Death1",0.08)
	if from_crawl:actor.animation_player.seek(actor._duration("Death2")*0.75,true)
func tick(delta:float,axis:float)->bool:
	if actor.state.begins_with("GroundSit"):
		actor.head_offset.active=true
		var sit_phase:float=actor.state_time/actor._duration(actor.state)
		actor.head_offset.blend_weight=smoothstep(0.05,0.80,sit_phase) if actor.state=="GroundSitExit" else 1.0-smoothstep(0.10,0.80,sit_phase) if actor.state=="GroundSitEnter" else 0.0
		actor.velocity.x=0
		if actor.state=="GroundSitEnter" and actor.state_time>=actor._duration("GroundSitEnter"):
			actor._state("GroundSitIdle")
			actor._play("GroundSitIdle",0.12)
		elif actor.state=="GroundSitIdle" and (absf(axis)>0.12 or actor.jump_buffer>0):
			actor._state("GroundSitExit")
			actor._play("GroundSitExit",0.12)
		elif actor.state=="GroundSitExit" and actor.state_time>=actor._duration("GroundSitExit"):
			actor.head_offset.active=true
			actor.head_offset.blend_weight=1.0
			actor._resume_locomotion(axis)
		actor.jump_buffer=0
		actor.velocity.y=0.0 if actor.is_on_floor() else actor.velocity.y-actor.GRAVITY*delta
		actor.move_and_slide()
		actor.position.z=0
		actor.animation_player.advance(delta)
		return true
	if toggle_crawl:
		toggle_crawl=false
		if actor.state.begins_with("Crawl"):
			if actor.state not in ["CrawlEnter","CrawlExit"] and _can_stand():
				actor._state("CrawlExit")
				actor._play("CrawlExit",0.10,CRAWL_RATE)
		elif actor.is_on_floor() and actor.state in ["Locomotion","GroundStop","WallBlocked","Brake"] and _can_crawl():
			actor.velocity.x=0
			_collider(true)
			actor._state("CrawlEnter")
			actor._play("CrawlEnter",0.10,CRAWL_RATE)
	if actor.state=="HitReact":
		actor.velocity.x=0
		if actor.state_time>=actor._duration(hit_clip):
			if hit_clip.begins_with("HitKnockback"):
				actor._state("HitDown")
				actor.animation_player.seek(actor._duration(hit_clip)-0.0001,true)
				actor.animation_player.speed_scale=0.0
			else:
				actor.head_offset.active=true
				actor._resume_locomotion(axis)
	elif actor.state=="HitDown":
		actor.velocity.x=0
		actor.abilities.hint="Knocked down - R / Reset to recover (get-up animation not supplied)"
	elif actor.state=="Dead":
		actor.velocity.x=0
		if actor.animation_player.current_animation_position>=actor._duration(actor.current_clip):actor.animation_player.seek(actor._duration(actor.current_clip),true)
	elif actor.state.begins_with("Crawl"):
		actor.abilities.hint="Left stick: crawl | L3/Z: stand (requires headroom) | H: hit test | Delete/Shift+Delete: death test"
		actor.velocity.x=0
		if actor.state=="CrawlEnter" and actor.state_time>=actor._duration("CrawlEnter")/CRAWL_RATE:
			actor._state("Crawl")
			actor._play("CrawlIdle",0.12)
		elif actor.state=="CrawlExit" and actor.state_time>=actor._duration("CrawlExit")/CRAWL_RATE:
			if _can_stand():
				_collider(false)
				actor._resume_locomotion(axis)
			else:
				actor._state("Crawl")
				actor._play("CrawlIdle",.12)
		elif actor.state=="Crawl":
			if absf(axis)>0.02:
				actor.facing=1 if axis>0 else -1
				actor.target_facing=actor.facing
				actor.visual.rotation.y=lerp_angle(actor.visual.rotation.y,actor.facing*PI/2,1-exp(-12*delta))
				var speed:float=actor.metadata.clips.CrawlForward.speed*CRAWL_RATE
				var blocked:bool=actor.test_move(actor.global_transform,Vector3(signf(axis)*(speed*delta+.02),0,0))
				actor._play("CrawlIdle" if blocked else "CrawlForward",0.12,1.0 if blocked else CRAWL_RATE)
				if not blocked:actor.velocity.x=speed*signf(axis)
			else:actor._play("CrawlIdle",0.12)
	else:return false
	actor.jump_buffer=0.0
	actor.velocity.y=0.0 if actor.is_on_floor() else actor.velocity.y-actor.GRAVITY*delta
	actor.move_and_slide()
	actor.position.z=actor.walk_plane_z
	actor.animation_player.advance(delta)
	return true

