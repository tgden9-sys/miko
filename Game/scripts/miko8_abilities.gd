extends Node
var actor:CharacterBody3D
var ladder:Node3D
var saved_mask:=5
var combat: Node
var transition_from:=Vector3.ZERO
var transition_to:=Vector3.ZERO
var transition_duration:=0.0
var mounting_from_top:=false
var top_access_points:Array[Vector3]=[]
var ladder_yaw:=PI
# Scale travel to the approved loop; descent reverses the same poses.
const CLIMB_RATE:=3.0
var climb_speed:=0.36766
var spell_kind:="Single"
var laser_mode:="Red"
var spell_fired:=false
var magnetic_weapons_enabled := true
var destructive_weapons_enabled := true
var crouch_tagging := false
var shots_fired:=0
var hand_indices:Dictionary={}
var last_shot_positions:Array[Vector3]=[]
var aim_elevation:=0.0
var target_aim_elevation:=0.0
var aim_facing:=1
var aim_engaged:=false
var lasers:Node3D
const TAG_REACH:=200.0*1.9/96.0
var locked_target:Node3D
var has_snapped_initial:=false
var laser_flash:=0.0
var posed_hands:Dictionary={}
var posed_directions:Dictionary={}
var hint:=""
var top_motion:Node
var bpg_motion:Node
var projectile_pool:Node
var quick_cooldown:=0.0
const QUICK_SHOT_INTERVAL:=.25
var quick_recoil:=0.0
var quick_sound:AudioStreamPlayer
const QUICK_FIRE_STATES:=[ "Locomotion","MoveStart","GroundStop","WallBlocked","SprintEnter","SprintExit","Brake","Turn","JumpGather","JumpStart","Air","Land","CrouchEnter","Crouch","CrouchExit" ]
var quick_pose_weight:=0.
var quick_pitch:=0.0
var quick_palm_local:=Vector3.ZERO
var quick_palm_ready:=false
var palm_bones:=Vector2i(-1,-1)
var _reusable_ray_query: PhysicsRayQueryParameters3D
var _cached_charge_targets: Array[Node] = []
var _cached_ladders: Array[Node] = []

func _ready()->void:
	combat = preload("res://scripts/miko8_sword_combat.gd").new()
	combat.actor = actor
	add_child(combat)
	_create_blaster_sound()
	projectile_pool=preload("res://scripts/miko8_projectile_pool.gd").new()
	add_child(projectile_pool)
	_reusable_ray_query = PhysicsRayQueryParameters3D.new()
	_reusable_ray_query.collide_with_areas = true
	_reusable_ray_query.collision_mask = 5
	_reusable_ray_query.exclude = [actor.get_rid()]
	bpg_motion=preload("res://scripts/miko8_bpg_ladder_motion.gd").new();bpg_motion.actor=actor;add_child(bpg_motion)
	top_motion=preload("res://scripts/miko8_ladder_top_motion.gd").new();top_motion.actor=actor;add_child(top_motion)
	lasers=preload("res://scripts/miko8_hand_lasers.gd").new()
	add_child(lasers)
	actor.skeleton.skeleton_updated.connect(_update_lasers)
	for item in [["aim_left",JOY_AXIS_RIGHT_X,-1.0,KEY_J],["aim_right",JOY_AXIS_RIGHT_X,1.0,KEY_L],["aim_up",JOY_AXIS_RIGHT_Y,-1.0,KEY_I],["aim_down",JOY_AXIS_RIGHT_Y,1.0,KEY_K]]:
		var action:String="miko8_"+item[0]
		if not InputMap.has_action(action):InputMap.add_action(action,0.12)
		var motion:=InputEventJoypadMotion.new()
		motion.device=-1
		motion.axis=item[1]
		motion.axis_value=item[2]
		InputMap.action_add_event(action,motion)
		var key:=InputEventKey.new()
		key.physical_keycode=item[3]
		InputMap.action_add_event(action,key)
	if not InputMap.has_action("miko8_plasma"):
		InputMap.add_action("miko8_plasma", .35)
		var plasma_key := InputEventKey.new()
		plasma_key.physical_keycode = KEY_P
		InputMap.action_add_event("miko8_plasma", plasma_key)
		var plasma_button := InputEventJoypadButton.new()
		plasma_button.device = -1
		plasma_button.button_index = JOY_BUTTON_RIGHT_STICK
		InputMap.action_add_event("miko8_plasma", plasma_button)
	climb_speed=actor.metadata.clips.StockLadderUp.speed*CLIMB_RATE
	for side:String in ["L","R"]:hand_indices[side]=actor.skeleton.find_bone("DEF-hand."+side)
	palm_bones=Vector2i(actor.skeleton.find_bone("DEF-f_index.01.L"),actor.skeleton.find_bone("DEF-f_pinky.01.L"))
	for action:String in ["miko8_up","miko8_down","miko8_spell_single","miko8_spell_blue","miko8_spell_double"]:
		if not InputMap.has_action(action):InputMap.add_action(action,0.25)
	for pair in [["miko8_up",JOY_AXIS_LEFT_Y,-1.0],["miko8_down",JOY_AXIS_LEFT_Y,1.0],["miko8_spell_double",JOY_AXIS_TRIGGER_RIGHT,1.0]]:
		var e:=InputEventJoypadMotion.new()
		e.device=-1
		e.axis=pair[1]
		e.axis_value=pair[2]
		InputMap.action_add_event(pair[0],e)
	for pair in [["miko8_spell_single",JOY_BUTTON_LEFT_SHOULDER],["miko8_spell_blue",JOY_BUTTON_RIGHT_SHOULDER]]:
		var button:=InputEventJoypadButton.new()
		button.device=-1
		button.button_index=pair[1]
		InputMap.action_add_event(pair[0],button)
	for pair in [["miko8_up",KEY_W],["miko8_up",KEY_UP],["miko8_down",KEY_S],["miko8_down",KEY_DOWN],["miko8_spell_single",KEY_Q],["miko8_spell_blue",KEY_E],["miko8_spell_double",KEY_F]]:
		var e:=InputEventKey.new()
		e.physical_keycode=pair[1]
		InputMap.action_add_event(pair[0],e)
	if not InputMap.has_action("miko8_quick_blaster"):
		InputMap.add_action("miko8_quick_blaster",.35)
		var trigger:=InputEventJoypadMotion.new()
		trigger.device=-1
		trigger.axis=JOY_AXIS_TRIGGER_LEFT
		trigger.axis_value=1.
		InputMap.action_add_event("miko8_quick_blaster",trigger)
		var key:=InputEventKey.new()
		key.physical_keycode=KEY_G
		InputMap.action_add_event("miko8_quick_blaster",key)

func reset()->void:
	if combat: combat.reset()
	quick_cooldown=0.
	crouch_tagging = false
	cancel_quick_pose()
	if actor.launcher_motion:actor.launcher_motion.reset()
	if bpg_motion:bpg_motion.cancel()
	if top_motion:top_motion.cancel()
	top_access_points.clear()
	_cached_charge_targets.clear()
	_cached_ladders.clear()
	_clear_target()
	has_snapped_initial=false
	aim_elevation=0.0
	target_aim_elevation=0.0
	aim_engaged=false
	laser_flash=0.0
	if lasers:lasers.hide_beams()
	actor.animation_player.speed_scale=1.0
	actor.collision_mask=saved_mask
	ladder=null
	spell_fired=false
	hint=""
	actor.model.position=Vector3.ZERO

func _vertical()->float:return Input.get_axis("miko8_down","miko8_up")

func _held_color()->String:
	if destructive_weapons_enabled and Input.is_action_pressed("miko8_plasma"): return "Plasma"
	return _held_tag()

func _held_tag() -> String:
	if not magnetic_weapons_enabled: return ""
	if Input.is_action_pressed("miko8_spell_blue"):return "Blue"
	if Input.is_action_pressed("miko8_spell_single"):return "Red"
	return ""

func _held_spell()->String:
	var color:=_held_color()
	return "Double" if color=="Plasma" else "Single" if color!="" else ""

func _get_ladders() -> Array[Node]:
	if _cached_ladders.is_empty():
		_cached_ladders = get_tree().get_nodes_in_group("miko8_ladders")
	return _cached_ladders

func _get_charge_targets() -> Array[Node]:
	if _cached_charge_targets.is_empty():
		_cached_charge_targets = get_tree().get_nodes_in_group("miko8_charge_targets")
	else:
		for node in _cached_charge_targets:
			if not is_instance_valid(node):
				_cached_charge_targets = get_tree().get_nodes_in_group("miko8_charge_targets")
				break
	return _cached_charge_targets

func _near_ladder()->Node3D:
	for candidate:Node3D in _get_ladders():
		var near_top:bool=absf(actor.position.y-candidate.top_y)<0.25
		if candidate.get("side_mount")==true:
			var target:Vector3=candidate.top_entry_position() if near_top else candidate.motion_origin()
			# The two sides of a wall are distinct access points, not an X-only snap zone.
			if absf(actor.position.x-target.x)<.34 and absf(actor.position.z-target.z)<.30 and (near_top or absf(actor.position.y-candidate.bottom_y)<.22):
				return candidate
			continue
		var reach:float=.42 if candidate.get_meta("direct_entry",false) and near_top else (1.45 if near_top else .58)
		var target_x:float=candidate.get_meta("top_entry_x",candidate.climb_x) if near_top else candidate.climb_x
		if near_top and candidate.get_meta("standard_top_transition",false):reach=.24
		if absf(actor.position.x-target_x)<reach and actor.position.y>=candidate.bottom_y-0.2 and actor.position.y<=candidate.top_y+0.25:return candidate
	return null

func tick(delta:float,axis:float)->bool:
	if combat.tick(delta, axis): return true
	quick_cooldown=maxf(0.,quick_cooldown-delta)
	laser_flash=maxf(0.0,laser_flash-delta)
	var stick:=Input.get_vector("miko8_aim_left","miko8_aim_right","miko8_aim_up","miko8_aim_down",0.12)
	update_aim(stick,delta)
	if (crouch_tagging or actor.state in ["SpellEnter","SpellHold"]) and laser_mode in ["Red","Blue"]:_refresh_target()
	elif actor.state!="SpellShoot":_clear_target();has_snapped_initial=false
	var vertical:=_vertical()
	if actor.state.begins_with("Climb"):
		if actor.jump_buffer>0:
			_jump_off(axis)
			actor.move_and_slide()
			actor.animation_player.advance(delta)
			return true
		_climb_tick(delta,vertical)
		return true
	if actor.state.begins_with("Spell"):
		if actor.jump_buffer>0 and actor.is_on_floor():
			actor._begin_jump()
			return false
		_spell_tick(delta,axis)
		return true
	if actor.state in ["CrouchEnter", "Crouch", "CrouchExit"]:
		if _tick_crouch_tag(delta): return false
	elif crouch_tagging:
		crouch_tagging = false
		_clear_target()
		lasers.hide_beams()
	var nearby:=_near_ladder()
	hint="Up / down: grab ladder" if nearby else "Ladder at +18 m — use the Ladder button to review"
	var ladder_mask: int = (
		(1 << actor.State.LOCOMOTION) |
		(1 << actor.State.MOVE_START) |
		(1 << actor.State.GROUND_STOP) |
		(1 << actor.State.WALL_BLOCKED) |
		(1 << actor.State.SPRINT_ENTER) |
		(1 << actor.State.SPRINT_EXIT) |
		(1 << actor.State.BRAKE) |
		(1 << actor.State.AIR) |
		(1 << actor.State.LAND)
	)
	if nearby and absf(vertical)>0.2 and ((1 << actor.state_id) & ladder_mask) != 0:
		var at_top:bool=absf(actor.position.y-nearby.top_y)<0.25
		if vertical>0 and not at_top or vertical<0 and at_top:
			cancel_quick_pose()
			_mount(nearby,at_top)
			_climb_tick(delta,vertical)
			return true
	var spell_mask: int = (
		(1 << actor.State.LOCOMOTION) |
		(1 << actor.State.MOVE_START) |
		(1 << actor.State.GROUND_STOP) |
		(1 << actor.State.WALL_BLOCKED) |
		(1 << actor.State.SPRINT_ENTER) |
		(1 << actor.State.SPRINT_EXIT) |
		(1 << actor.State.BRAKE) |
		(1 << actor.State.LAND)
	)
	var standing_spell := _held_spell()
	if standing_spell != "" and Input.get_action_strength("miko8_down") < .65 and actor.is_on_floor() and ((1 << actor.state_id) & spell_mask) != 0:
		cancel_quick_pose()
		spell_kind=standing_spell
		laser_mode=_held_color()
		# Fresh targeting always starts level in the body's current heading.
		aim_facing=actor.facing
		aim_elevation=0.0
		target_aim_elevation=0.0
		aim_engaged=true
		spell_fired=false
		actor._state("SpellEnter")
		actor._play("Spell"+spell_kind+"Enter",0.12)
		_spell_tick(delta,axis)
		return true
	cancel_quick_pose()
	return false

func _tick_crouch_tag(delta: float) -> bool:
	var held := _held_tag()
	if held.is_empty():
		if not crouch_tagging: return false
		crouch_tagging = false
		spell_fired = true
		_fire_spell()
		lasers.hide_beams()
		return true
	cancel_quick_pose()
	laser_mode = held
	if not crouch_tagging:
		crouch_tagging = true
		aim_facing = actor.facing
		aim_elevation = 0.
		target_aim_elevation = 0.
		aim_engaged = true
		spell_fired = false
		_refresh_target()
	actor.facing = aim_facing
	actor.target_facing = aim_facing
	actor.visual.rotation.y = lerp_angle(actor.visual.rotation.y, aim_facing * PI * .5, 1. - exp(-20. * delta))
	return true

func cancel_quick_pose()->void:
	quick_recoil=0.
	quick_pose_weight=0.
	quick_palm_ready=false

func quick_pose_active()->bool:
	return quick_pose_weight>.001 and actor.state in QUICK_FIRE_STATES and actor.ready_for_input and actor.is_physics_processing()

func quick_direction()->Vector3:
	# Follow the visible body during a turn, rather than firing backwards
	# before the arm has turned. Project onto the gameplay plane.
	var heading:float=actor.visual.global_basis.z.x
	return Vector3((1. if heading>=0. else -1.)*cos(quick_pitch),sin(quick_pitch),0.)

func _tick_quick_fire(delta:float,stick:Vector2)->void:
	quick_recoil=move_toward(quick_recoil,0.,delta*10.)
	if not destructive_weapons_enabled or actor.state not in QUICK_FIRE_STATES:
		cancel_quick_pose()
		return
	var held:=Input.is_action_pressed("miko8_quick_blaster")
	quick_pose_weight=move_toward(quick_pose_weight,1. if held else 0.,delta*30.)
	if not held:
		if quick_pose_weight==0.:quick_palm_ready=false
		return
	laser_mode="Green"
	# Green fire uses direct, responsive elevation; puzzle beams retain
	# their slower precision adjustment. Releasing the stick eases to level.
	var requested:float=clampf(atan2(-stick.y,absf(stick.x)),deg_to_rad(-65.),deg_to_rad(85.)) if stick.length()>=.12 else 0.
	quick_pitch=move_toward(quick_pitch,requested,delta*8.)
	if quick_pose_weight>=.99 and quick_palm_ready and quick_cooldown<=.0001:
		_fire_spell()
		quick_cooldown=QUICK_SHOT_INTERVAL

func _palm_center()->Vector3:
	var rig:Skeleton3D=actor.skeleton
	var wrist:=rig.get_bone_global_pose(hand_indices.L).origin
	if palm_bones.x<0 or palm_bones.y<0:return rig.to_global(wrist)
	var knuckles:=rig.get_bone_global_pose(palm_bones.x).origin.lerp(rig.get_bone_global_pose(palm_bones.y).origin,.5)
	return rig.to_global(wrist.lerp(knuckles,.58))

func _quick_origin()->Vector3:
	var point:Vector3=actor.visual.to_global(quick_palm_local) if quick_palm_ready else _palm_center()
	var obstruction:=_segment_hit(actor.global_position+Vector3(0,1.1,0),point,false)
	return obstruction.position-quick_direction()*.07 if not obstruction.is_empty() else point

func _mount(value:Node3D,from_top:bool)->void:
	mounting_from_top=from_top
	ladder=value
	top_access_points.clear()
	saved_mask=actor.collision_mask
	actor.collision_mask=0
	actor.velocity=Vector3.ZERO
	if ladder.get_meta("bpg_ladder",false):
		bpg_motion.mount(ladder,from_top);return
	if from_top and ladder.get_meta("standard_top_transition",false):
		top_motion.begin(ladder,true);return
	if ladder.get_meta("direct_entry",false):
		actor.position=Vector3(ladder.climb_x,ladder.top_y-.03 if from_top else maxf(ladder.bottom_y,actor.position.y),0)
		actor.visual.rotation.y=ladder_yaw
		actor.model.position=Vector3.ZERO
		actor.animation_player.speed_scale=1.0
		actor._state("ClimbHold")
		actor._play("StockLadderDown" if from_top else "StockLadderUp",.10,CLIMB_RATE)
		return
	transition_from=actor.position
	transition_to=Vector3(ladder.climb_x,ladder.top_y-0.45 if from_top else maxf(ladder.bottom_y,actor.position.y),0)
	# A wraparound landing can opt into a supported path in front of its well.
	if from_top and ladder.has_meta("front_access_z"):
		var access_z:float=ladder.get_meta("front_access_z")
		if absf(actor.position.z-access_z)>.015:
			top_access_points.append(Vector3(actor.position.x,actor.position.y,access_z))
		top_access_points.append(Vector3(ladder.climb_x,actor.position.y,access_z))
		_begin_access_step(top_access_points.pop_front())
		return
	# Finish the short approach in a walking pose before grabbing the rails.
	if absf(actor.position.x-ladder.climb_x)>0.035:
		transition_to.y=actor.position.y
		actor._state("ClimbAlign")
		transition_duration=maxf(0.12,absf(actor.position.x-ladder.climb_x)/actor._speed("Walk"))
		actor.facing=1 if ladder.climb_x>actor.position.x else -1
		actor.visual.rotation.y=actor.facing*PI/2
		actor.animation_player.speed_scale=1.0
		actor._play("Walk",0.10)
		return
	actor._state("ClimbTopEnter" if from_top else "ClimbEnter")
	var clip:="StockLadderDown" if from_top else "StockLadderHold"
	transition_duration=0.45 if from_top else 0.45
	actor.current_clip=""
	actor.animation_player.speed_scale=1.0
	actor._play(clip,0.28,CLIMB_RATE if from_top else 1.0)
	actor.animation_player.seek(0.0,true)

func _begin_access_step(destination:Vector3)->void:
	transition_from=actor.position;transition_to=destination
	var travel:=destination-actor.position
	transition_duration=maxf(.12,travel.length()/actor._speed("Walk"))
	actor._state("ClimbAlign")
	if travel.length()>.015:actor.visual.rotation.y=atan2(travel.x,travel.z)
	actor.animation_player.speed_scale=1.0;actor._play("Walk",.10)

func _root_offset(clip:String,time:float)->void:
	var data:Dictionary=actor.metadata.clips[clip]
	if not data.has("hip_motion"):return
	var now:Vector3=actor._sample(data.hip_motion,time,data.duration)
	var first:Array=data.hip_motion[0]
	actor.model.position=-(now-Vector3(first[0],first[1],first[2]))

func _climb_tick(delta:float,vertical:float)->void:
	if bpg_motion.active:
		bpg_motion.tick(delta,vertical);return
	if top_motion.active:
		top_motion.tick(delta);return
	hint="Stick up/down: climb • release: hold • A / Circle: jump off"
	actor.velocity=Vector3.ZERO
	if actor.state=="ClimbAlign":
		var t:=clampf(actor.state_time/transition_duration,0,1)
		actor.position=transition_from.lerp(transition_to,t)
		actor.animation_player.advance(delta)
		if t>=1:
			actor.position=transition_to
			if not top_access_points.is_empty():
				_begin_access_step(top_access_points.pop_front())
				return
			actor.position.x=ladder.climb_x
			transition_from=actor.position
			transition_to=actor.position
			transition_duration=0.45 if mounting_from_top else 0.30
			if mounting_from_top:transition_to=Vector3(ladder.climb_x,ladder.top_y-.45,0)
			actor._state("ClimbTopEnter" if mounting_from_top else "ClimbEnter")
			actor._play("StockLadderDown" if mounting_from_top else "StockLadderHold",0.22,CLIMB_RATE if mounting_from_top else 1.0)
		return
	actor.visual.rotation.y=lerp_angle(actor.visual.rotation.y,ladder_yaw,1-exp(-14*delta))
	if actor.state in ["ClimbEnter","ClimbTopEnter","ClimbTopExit","ClimbExit"]:
		var t:=clampf(actor.state_time/transition_duration,0,1)
		var ease:=t*t*(3-2*t)
		if actor.state in ["ClimbTopExit","ClimbExit"]:
			actor.visual.rotation.y=lerp_angle(ladder_yaw,actor.facing*PI/2,smoothstep(0.22 if actor.state=="ClimbTopExit" else 0.0,0.72 if actor.state=="ClimbTopExit" else 1.0,t))
		var position_value:=transition_from.lerp(transition_to,ease)
		# Clear the platform lip during the pull-up / reverse pull-up.
		if actor.state=="ClimbTopExit":
			# Ease out of the climb, but finish with a walking step instead of stopping.
			var u:=clampf((t-0.12)/0.88,0.0,1.0)
			var end_step:float=actor._speed("Walk")*actor.facing*transition_duration*0.88
			position_value.x=transition_from.x+(transition_to.x-transition_from.x)*(-2*u*u*u+3*u*u)+end_step*(u*u*u-u*u)
			position_value.y=lerpf(transition_from.y,transition_to.y+0.04,smoothstep(0,0.50,t)) if t<0.50 else lerpf(transition_to.y+0.04,transition_to.y,smoothstep(0.50,1,t))
			if ladder.has_meta("front_access_z"):
				# Clear the rear opening vertically before stepping onto the apron.
				var access_z:float=ladder.get_meta("front_access_z")
				position_value.z=access_z*smoothstep(.28,.48,t)*(1.0-smoothstep(.70,1.0,t))
		actor.position=position_value
		if actor.state=="ClimbTopExit" and t>0.32:
			actor._play("Walk",0.26,1.0)
		actor.animation_player.advance(delta)
		actor.model.position=Vector3.ZERO
		if t>=1:
			actor.model.position=Vector3.ZERO
			if actor.state in ["ClimbTopExit","ClimbExit"]:
				actor.collision_mask=saved_mask
				actor.position=transition_to
				var top_exit:bool=actor.state=="ClimbTopExit"
				ladder=null
				var axis:float=actor._axis()
				if top_exit:
					actor.velocity.x=actor._speed("Walk")*actor.facing
					actor._state("Locomotion")
					if absf(axis)<0.02:
						actor._state("GroundStop")
					elif axis*actor.facing>0:
						actor._play(actor._gait(axis),0.14)
						actor.animation_player.speed_scale=clampf(absf(actor.velocity.x)/actor._speed(actor._gait(axis)),0.10,1.0)
				else:
					actor._resume_locomotion(axis)
			else:
				var descending:bool=actor.state=="ClimbTopEnter"
				actor._state("ClimbHold")
				if not descending:actor._play("StockLadderHold",0.20)
		return
	actor.model.position=Vector3.ZERO
	actor.position.x=ladder.climb_x
	if absf(vertical)>0.15:
		actor.animation_player.speed_scale=1.0
		var clip:="StockLadderUp" if vertical>0 else "StockLadderDown"
		if actor.current_clip!=clip:
			var phase:float=actor.animation_player.current_animation_position/actor._duration(actor.current_clip)
			var reverse:bool=actor.current_clip in ["StockLadderUp","StockLadderDown"]
			actor._play(clip,0.14,CLIMB_RATE)
			actor.animation_player.seek((1.0-phase)*actor._duration(clip) if reverse else 0.0,true)
		actor.position.y+=climb_speed*delta*(1.0 if vertical>0 else -1.0)
		var exit_y:float=ladder.top_y if ladder.get_meta("direct_entry",false) else ladder.top_y-.45
		if ladder.get_meta("standard_top_transition",false):exit_y=ladder.top_y-.95
		if vertical>0 and actor.position.y>=exit_y:_exit_ladder(true)
		elif vertical<0 and actor.position.y<=ladder.bottom_y+0.03:_exit_ladder(false)
		if top_motion.active:return # Its pose/root clocks start together on the next tick.
	else:
		# Keep the exact planted pose when the stick is released.
		actor.animation_player.speed_scale=0.0
	actor.animation_player.advance(delta)

func _exit_ladder(top:bool)->void:
	if top and ladder.get_meta("standard_top_transition",false):
		top_motion.begin(ladder,false);return
	if ladder.get_meta("direct_entry",false):
		actor.position=Vector3(ladder.climb_x,ladder.top_y+.01 if top else ladder.bottom_y+.01,0)
		actor.collision_mask=saved_mask
		actor.model.position=Vector3.ZERO
		actor.animation_player.speed_scale=1.0
		ladder=null
		actor._resume_locomotion(actor._axis())
		return
	if top:
		actor.facing=int(ladder.dismount_side)
		actor.target_facing=actor.facing
	transition_from=actor.position
	transition_to=Vector3(ladder.climb_x+ladder.dismount_side*1.1,ladder.top_y+0.01,0) if top else Vector3(ladder.climb_x,ladder.bottom_y+0.01,0)
	actor._state("ClimbTopExit" if top else "ClimbExit")
	var clip:="StockLadderUp" if top else "Idle"
	transition_duration=1.10 if top else 0.40
	actor.animation_player.speed_scale=1.0
	actor._play(clip,0.24,actor._duration(clip)/transition_duration)

func _jump_off(axis:float)->void:
	if bpg_motion.active:
		actor.walk_plane_z=actor.position.z;actor.walk_plane_floor_y=actor.position.y;bpg_motion.cancel()
	if top_motion:top_motion.cancel()
	top_access_points.clear()
	actor.animation_player.speed_scale=1.0
	var away:int=-ladder.dismount_side
	actor.collision_mask=saved_mask
	ladder=null
	actor.model.position=Vector3.ZERO
	actor.jump_buffer=0
	actor.facing=1 if axis>0 else -1 if axis<0 else away
	actor.target_facing=actor.facing
	actor.velocity=Vector3(actor.facing*3.5,4.8,0)
	actor.floor_snap_length=0
	actor.launched=true
	actor.landing_contact=false
	actor._state("Air")
	actor._play("JumpAir",0.12)

func _spell_tick(delta:float,axis:float)->void:
	hint="Right stick/IJKL: aim | L1/Q red | R1/E blue | R3/P plasma | L2/G sword | R2/F shield"
	actor.velocity.y-=actor.GRAVITY*delta if not actor.is_on_floor() else 0
	actor.velocity.x=move_toward(actor.velocity.x,0,actor.STOP_DECELERATION*delta)
	if aim_engaged:actor.facing=aim_facing
	elif absf(axis)>0.05:actor.facing=1 if axis>0 else -1
	actor.visual.rotation.y=lerp_angle(actor.visual.rotation.y,actor.facing*PI/2,1-exp(-20*delta))
	var held:=_held_color()
	if spell_kind=="Single" and held in ["Red","Blue"]:
		laser_mode=held
		if actor.state in ["SpellShoot","SpellExit"]:
			spell_fired=false
			actor._state("SpellHold")
			actor._play("SpellSingleIdle",0.05)
	var prefix:="Spell"+spell_kind
	match actor.state:
		"SpellEnter":
			if _held_color()!=laser_mode:
				actor._state("SpellShoot")
				actor._play(prefix+"Shoot",0.04,actor._duration(prefix+"Shoot")/0.14)
			elif actor.state_time>=actor._duration(prefix+"Enter"):
				actor._state("SpellHold")
				actor._play(prefix+"Idle",0.1)
		"SpellHold":
			if _held_color()!=laser_mode:
				actor._state("SpellShoot")
				actor._play(prefix+"Shoot",0.04,actor._duration(prefix+"Shoot")/0.14)
		"SpellShoot":
			if not spell_fired and actor.state_time>=0.025:
				_fire_spell()
				spell_fired=true
			if actor.state_time>=0.14:
				actor._state("SpellExit")
				actor._play(prefix+"Exit",0.05,actor._duration(prefix+"Exit")/0.10)
		"SpellExit":
			if actor.state_time>=0.10:
				actor._resume_locomotion(axis)
	actor.animation_player.advance(delta)
	actor.move_and_slide()
	actor.position.z=actor.walk_plane_z

func update_aim(stick:Vector2,delta:float)->void:
	if stick.length()<0.002:
		target_aim_elevation=aim_elevation
		return
	set_aim(stick)
	var strength:=clampf(stick.length(),0.0,1.0)
	aim_elevation=move_toward(aim_elevation,target_aim_elevation,delta*1.8*strength*strength)

func set_aim(stick:Vector2)->void:
	if stick.length()<0.002:return
	aim_engaged=true
	if absf(stick.x)>0.25:aim_facing=1 if stick.x>0 else -1
	var requested:=clampf(atan2(-stick.y,absf(stick.x)),deg_to_rad(-45.0),PI/2.0)
	target_aim_elevation=requested

func _free_aim_direction()->Vector3:
	var side:int=aim_facing if aim_engaged else actor.facing
	return Vector3(side*cos(aim_elevation),sin(aim_elevation),0).normalized()

func aim_direction()->Vector3:
	return _free_aim_direction()

func _clear_target()->void:
	if is_instance_valid(locked_target):locked_target.set_locked_on(false,Vector3.ZERO,Color.WHITE)
	locked_target=null

func _refresh_target()->void:
	var origin:Vector3=_hand_origin("L")
	var direction:=_free_aim_direction()
	if not has_snapped_initial:
		var initial_best:Node3D=null
		var best_dot:=0.50
		for candidate:Node3D in _get_charge_targets():
			var to_cand:=candidate.global_position-origin
			var d:=to_cand.length()
			if d<0.2 or d>TAG_REACH:continue
			var dot:=to_cand.normalized().dot(direction)
			if dot>best_dot:
				var hit:=_segment_hit(origin,candidate.global_position)
				if hit.get("collider")==candidate:
					best_dot=dot
					initial_best=candidate
		if initial_best:
			has_snapped_initial=true
			var ray:Vector3=(initial_best.global_position-origin).normalized()
			var target_pitch:=atan2(ray.y,absf(ray.x))
			aim_elevation=target_pitch
			target_aim_elevation=target_pitch
			direction=_free_aim_direction()
			if locked_target!=initial_best:_clear_target();locked_target=initial_best
			if is_instance_valid(locked_target):locked_target.set_locked_on(true,locked_target.global_position,Color("ff3038") if laser_mode=="Red" else Color("309cff"))
			return
		else:
			has_snapped_initial=true
	var nearest:Node3D=null
	var best_perp:=0.85
	for candidate:Node3D in _get_charge_targets():
		var offset:=candidate.global_position-origin
		var dist_along:=offset.dot(direction)
		if dist_along<0.2 or dist_along>TAG_REACH:continue
		var perp_dist:=(offset-direction*dist_along).length()
		if perp_dist<best_perp:
			var hit:=_segment_hit(origin,candidate.global_position)
			if hit.get("collider")==candidate:
				best_perp=perp_dist
				nearest=candidate
	if locked_target!=nearest:_clear_target();locked_target=nearest
	if is_instance_valid(locked_target):locked_target.set_locked_on(true,locked_target.global_position,Color("ff3038") if laser_mode=="Red" else Color("309cff"))

func spell_sides()->Array[String]:
	var sides:Array[String]=[]
	if laser_mode=="Plasma":sides.assign(["L","R"])
	else:sides.append("L")
	return sides

func _hand_origin(side:String)->Vector3:
	var point:Vector3=posed_hands.get(side,actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(hand_indices[side]).origin))+aim_direction()*0.06
	var shoulder_height := .79 if actor.crouch_motion.low_collider else 1.1
	var obstruction:=_segment_hit(actor.global_position+Vector3(0,shoulder_height,0),point,false)
	if not obstruction.is_empty():return obstruction.position-aim_direction()*0.015
	return point

func _plasma_origin()->Vector3:
	var middle:Vector3=(_hand_origin("L")+_hand_origin("R"))*0.5
	var point:=middle+aim_direction()*0.22
	var obstruction:=_segment_hit(actor.global_position+Vector3(0,1.1,0),point,false)
	if not obstruction.is_empty():return obstruction.position-aim_direction()*0.13
	return point

func _single_origin()->Vector3:
	var direction:=aim_direction()
	var point:=_hand_origin("L")+direction*.12
	var obstruction:=_segment_hit(actor.global_position+Vector3(0,1.1,0),point,false)
	if not obstruction.is_empty():return obstruction.position-direction*.085
	return point

func _laser_hit(origin:Vector3)->Dictionary:
	return _laser_trace(origin).hit

func _laser_trace(origin:Vector3)->Dictionary:
	var direction:=aim_direction()
	var endpoint:=origin+direction*24.0
	for launcher in get_tree().get_nodes_in_group("miko8_launchers"):
		if not launcher.has_method("muzzle_target_distance"):continue
		var distance:float=launcher.muzzle_target_distance(actor.global_position+Vector3.UP*.65,origin,direction)
		if distance>0.:
			endpoint=origin+direction*maxf(.10,distance)
			var solid_hit:=_segment_hit(origin,endpoint,false)
			var hit := solid_hit if not solid_hit.is_empty() else {"collider":launcher,"position":endpoint}
			return {"hit": hit, "direction": direction}
	var hit := _segment_hit(origin, endpoint)
	if laser_mode in ["Red", "Blue"] and not hit.is_empty():
		var collider: Node3D = hit.collider
		if collider.has_meta("miko8_open_end_bay"):
			var through := _trace_open_end(origin, direction, hit, collider.get_meta("miko8_open_end_bay"))
			if not through.is_empty():
				return through
	return {"hit": hit, "direction": direction}

func _trace_open_end(origin: Vector3, direction: Vector3, frame_hit: Dictionary, bay: AABB) -> Dictionary:
	if absf(direction.x) < .01:
		return {}
	var side := signf(direction.x)
	var entrance_x := bay.position.x if side > 0. else bay.end.x
	# Only resolve the end frame when approaching the bay from outside.
	if (entrance_x - origin.x) * side <= 0. or absf(frame_hit.position.x - entrance_x) > .20:
		return {}
	var camera := actor.get_viewport().get_camera_3d()
	if not camera or camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		return {}
	var view_depth := camera.global_basis.z
	if absf(view_depth.z) < .01:
		return {}
	# Camera depth does not move the guide on screen. Aim into the middle
	# of the bay just past its mouth, keeping the player's screen angle.
	var depth_offset := view_depth * ((bay.get_center().z - origin.z) / view_depth.z)
	var inside_x := entrance_x + side * .55
	var inside := origin + depth_offset + direction * ((inside_x - origin.x - depth_offset.x) / direction.x)
	var through := (inside - origin).normalized()
	var entry := origin + through * ((entrance_x - origin.x) / through.x)
	if entry.y < bay.position.y or entry.y > bay.end.y or absf(entry.z - bay.get_center().z) > bay.size.z * .32:
		return {}
	var hit := _segment_hit(origin, origin + through * 24.)
	if not hit.is_empty() and (hit.position.x - entrance_x) * side < .08:
		return {}
	return {"hit": hit, "direction": through}

func _segment_hit(origin:Vector3,end:Vector3,include_targets:=true)->Dictionary:
	if not _reusable_ray_query:
		_reusable_ray_query = PhysicsRayQueryParameters3D.new()
		_reusable_ray_query.collide_with_areas = true
		_reusable_ray_query.collision_mask = 5
		_reusable_ray_query.exclude = [actor.get_rid()]
	_reusable_ray_query.from = origin
	_reusable_ray_query.to = end
	# A walk-through target must not pull the muzzle back into Miko's arm.
	_reusable_ray_query.collide_with_areas=include_targets
	return actor.get_world_3d().direct_space_state.intersect_ray(_reusable_ray_query)

func _update_lasers()->void:
	# The skeleton can emit one final update as a transferred scene is removed.
	if not lasers or not is_inside_tree() or not actor.skeleton.is_inside_tree():return
	for side:String in ["L","R"]:
		var hand:Vector3=actor.skeleton.get_bone_global_pose(hand_indices[side]).origin
		var fore:Vector3=actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("DEF-forearm."+side)).origin
		posed_hands[side]=actor.skeleton.to_global(hand)
		posed_directions[side]=(actor.skeleton.global_basis*(hand-fore)).normalized()
	lasers.hide_beams()
	if laser_mode=="Green":
		if quick_pose_active() and quick_pose_weight>=.99:
			quick_palm_local=actor.visual.to_local(_palm_center())
			quick_palm_ready=true
		return
	if not crouch_tagging and actor.state not in ["SpellEnter","SpellHold","SpellShoot"] and laser_flash<=0:return
	if laser_mode=="Plasma":
		var left:=_hand_origin("L")
		var right:=_hand_origin("R")
		var middle:Vector3=_plasma_origin()
		var hit:=_laser_hit(middle)
		var endpoint:Vector3=hit.get("position",middle+aim_direction()*24.0)
		if not spell_fired:
			lasers.hold_plasma(middle)
			lasers.draw_beam("C",middle,endpoint,true)
	else:
		for side:String in spell_sides():
			var origin:=_single_origin()
			var trace := _laser_trace(origin)
			if not spell_fired:
				lasers.hold_charge(origin,laser_mode)
				lasers.draw_beam(side,origin,trace.hit.get("position",origin+trace.direction*24.0),false,laser_mode=="Blue")

func _fire_spell()->void:
	if laser_mode in ["Red", "Blue"] and not magnetic_weapons_enabled: return
	if laser_mode in ["Green", "Plasma"] and not destructive_weapons_enabled: return
	last_shot_positions.clear()
	laser_flash=0.04
	var origin:Vector3=_quick_origin() if laser_mode=="Green" else _plasma_origin() if laser_mode=="Plasma" else _single_origin()
	var direction:=quick_direction() if laser_mode=="Green" else aim_direction()
	if laser_mode in ["Red", "Blue"]:
		direction = _laser_trace(origin).direction
	var speed: float = 19.4 if laser_mode=="Green" else 18.0 if laser_mode=="Plasma" else 14.0
	var power: int = 2 if laser_mode=="Plasma" else 1
	var bolt: Node3D = projectile_pool.spawn_bolt(actor, origin, direction * speed, laser_mode, power)
	last_shot_positions.append(origin);shots_fired+=1
	if laser_mode=="Green":
		quick_recoil=1.
		quick_sound.play()
		var muzzle:Node3D=projectile_pool.spawn_impact(origin,Color("58ff71"))
		muzzle.scale=Vector3.ONE*.30
		muzzle.duration=.09
	_clear_target()
	has_snapped_initial=false
	_update_lasers()

func _create_blaster_sound()->void:
	# Build once, then reuse: a short electrical crack with a descending body.
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	var data:=PackedByteArray()
	data.resize(3528*2)
	var rng:=RandomNumberGenerator.new()
	rng.seed=701
	for i in range(3528):
		var t:=float(i)/22050.
		var attack:=minf(t/.002,1.)
		var body:=sin(TAU*(620.*t-1250.*t*t))*exp(-t*32.)*.55
		var crack:=rng.randf_range(-1.,1.)*exp(-t*180.)*.35
		var tail:=sin(TAU*145.*t)*exp(-t*40.)*.18
		data.encode_s16(i*2,int(clampf((body+crack+tail)*attack,-1.,1.)*25000.))
	stream.data=data
	quick_sound=AudioStreamPlayer.new()
	quick_sound.stream=stream
	quick_sound.volume_db=-14.
	add_child(quick_sound)
