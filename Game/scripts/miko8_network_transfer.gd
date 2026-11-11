extends Node3D
## Reusable section exit. Arrival tickets exist for one scene change only.
const TICKET := &"miko8_transfer_arrival"
const INTERACT := preload("res://scripts/miko8_reaction_library.gd")
const CONTACT_TIME := 22.0 / 30.0
enum Stage { IDLE, ALIGN, CONTACT, DEPART, FADE_OUT, ARRIVE, RELEASE, DONE }
@export var destination_scene := ""
@export var destination_label := ""
@export var arrival_only := false
@export var send_arrival_ticket := true
var completes_tutorial:=false
var required_canister:Area3D
var level:Node3D
var actor:CharacterBody3D
var effect:Node3D
var overlay:ColorRect
var stage := Stage.IDLE
var stage_time := 0.0
var dissolve := 0.0
var charge := 0.0
var origin := Vector3.ZERO
var align_duration := .35
var align_yaw := 0.0
var floor_height := 0.0
var contact_shadow:Node3D
var error_message := ""

func _ready()->void:
	level=get_parent();actor=level.actor
	name="ArrivalRelay" if arrival_only else "NetworkTransfer"
	INTERACT.install_data(actor,JSON.parse_string(FileAccess.get_file_as_string("res://models/miko8/MIKO8_Interact.json")),"Interaction")
	for child in actor.get_children():
		if child.get_script()==preload("res://scripts/miko8_contact_shadow.gd"):contact_shadow=child
	effect=preload("res://scripts/miko8_transfer_visual.gd").new()
	effect.actor=actor;effect.camera=level.camera;add_child(effect)
	var canvas:=CanvasLayer.new();canvas.layer=20;add_child(canvas)
	overlay=ColorRect.new();overlay.color=Color(0,0,0,0)
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.add_child(overlay)
	if not InputMap.has_action("miko8_transfer"):
		InputMap.add_action("miko8_transfer")
		var key:=InputEventKey.new();key.physical_keycode=KEY_T
		InputMap.action_add_event("miko8_transfer",key)
		var button:=InputEventJoypadButton.new();button.device=-1;button.button_index=JOY_BUTTON_A
		InputMap.action_add_event("miko8_transfer",button)

func busy()->bool:
	return stage not in [Stage.IDLE,Stage.DONE]

func near()->bool:
	return not arrival_only and absf(actor.global_position.x-global_position.x)<2.3 and absf(actor.global_position.y-global_position.y)<.25 and absf(actor.global_position.z-global_position.z)<.25

func can_activate()->bool:
	if busy() or arrival_only or (destination_scene.is_empty() and not completes_tutorial) or level.resetting:return false
	if required_canister and not required_canister.is_collected:return false
	if not near() or not actor.ready_for_input or not actor.is_on_floor():return false
	if actor.state not in ["Locomotion","MoveStart","GroundStop","Brake","WallBlocked"]:return false
	# Both the short approach and the final standing space must be clear.
	var target:=global_position+Vector3(-.73,actor.global_position.y-global_position.y,0)
	var motion:=target-actor.global_position
	if motion.length()>.015 and actor.test_move(actor.global_transform,motion):return false
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=actor.body_collision.shape;query.collision_mask=actor.collision_mask
	query.transform=Transform3D(Basis.IDENTITY,target+Vector3(0,.92,0))
	query.exclude=[actor.get_rid()];query.margin=.005
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func _unhandled_input(event:InputEvent)->void:
	if event.is_action_pressed("miko8_transfer") and not event.is_echo() and activate():
		get_viewport().set_input_as_handled()

func _enter(next:Stage)->void:
	stage=next;stage_time=0.

func _lock()->void:
	actor.ready_for_input=false;actor.set_physics_process(false)
	actor.abilities.reset();actor.velocity=Vector3.ZERO
	actor.jump_buffer=0.;actor.jump_held=false;actor.turn_queue.clear()
	actor._state("NetworkTransfer")
	level.level_selector.disabled=true
	for patch in level.scene_presence.shadows:patch.hide()
	floor_height=actor.global_position.y

func activate()->bool:
	if not can_activate():return false
	error_message=""
	origin=actor.global_position;align_yaw=actor.visual.rotation.y
	align_duration=maxf(.28,absf(global_position.x-.73-origin.x)/2.2)
	_lock();_enter(Stage.ALIGN)
	actor.current_clip="";actor._play("Walk",.12)
	return true

func _contact_pose()->void:
	actor.facing=1;actor.target_facing=1;actor.visual.rotation.y=PI*.5
	actor.current_clip="";actor._play("RelayInteract",.12)

func receive(ticket:Dictionary)->void:
	actor.reset_actor();actor.position=global_position+Vector3(-.73,.02,0)
	actor.health = clampi(int(ticket.get("health", actor.MAX_HEALTH)), 0, actor.MAX_HEALTH)
	actor.polarity_control.set_polarity(int(ticket.get("polarity",0)),true)
	actor.polarity_control.set_three_tone(bool(ticket.get("three_tone",true)))
	level.set_ambience_muted(bool(ticket.get("muted",false)))
	_lock();_contact_pose();actor.animation_player.seek(CONTACT_TIME,true)
	dissolve=1.;charge=1.;overlay.color.a=1.
	_apply_actor_effect();_enter(Stage.ARRIVE)
	level.elapsed=2.;level.fade.color.a=0.
	level.camera_focus_ready=false;level._camera(0,true)

func _physics_process(delta:float)->void:
	if not busy():return
	stage_time+=delta
	match stage:
		Stage.ALIGN:
			var weight:=smoothstep(0.,1.,stage_time/align_duration)
			var target:=Vector3(global_position.x-.73,origin.y,origin.z)
			var next:=origin.lerp(target,weight)
			var collision:=actor.move_and_collide(next-actor.global_position)
			if collision:
				cancel();error_message="Clear the space beside the relay.";return
			actor.visual.rotation.y=lerp_angle(align_yaw,PI*.5,smoothstep(0.,.3,stage_time))
			actor.animation_player.advance(delta)
			if stage_time>=align_duration:_contact_pose();_enter(Stage.CONTACT)
		Stage.CONTACT:
			actor.animation_player.advance(minf(delta,maxf(0.,CONTACT_TIME-actor.animation_player.current_animation_position)))
			charge=smoothstep(.25,.85,stage_time)
			if stage_time>=1.05:_enter(Stage.DEPART)
		Stage.DEPART:
			dissolve=smoothstep(0.,1.,stage_time/1.65)
			if stage_time>=1.8:_enter(Stage.FADE_OUT)
		Stage.FADE_OUT:
			overlay.color.a=smoothstep(0.,.38,stage_time)
			if stage_time>=.40:
				_enter(Stage.DONE)
				if completes_tutorial:
					level.tutorial_director.finish()
					return
				if send_arrival_ticket:
					get_tree().set_meta(TICKET,{"scene":destination_scene,"polarity":actor.suit_polarity,"health":actor.health,
						"three_tone":actor.polarity_control.three_tone_enabled,"muted":level.ambience_muted})
				call_deferred("_change_section")
		Stage.ARRIVE:
			overlay.color.a=1.-smoothstep(0.,.45,stage_time)
			dissolve=1.-smoothstep(.32,1.77,stage_time)
			if stage_time>=1.95:_enter(Stage.RELEASE)
		Stage.RELEASE:
			actor.animation_player.advance(delta)
			charge=1.-smoothstep(0.,1.,stage_time)
			if stage_time>=1.30:cancel();_enter(Stage.DONE)
	_apply_actor_effect()

func _change_section()->void:
	# A cancelled/reset sequence must never change scenes on a later frame.
	if stage!=Stage.DONE or (send_arrival_ticket and not get_tree().has_meta(TICKET)):return
	var result:=get_tree().change_scene_to_file(destination_scene)
	if result!=OK:
		get_tree().remove_meta(TICKET);cancel();error_message="Transfer unavailable. Try again."
		push_error("Network transfer could not load "+destination_scene)

func _apply_actor_effect()->void:
	actor.polarity_control.set_transfer(dissolve,charge,floor_height)
	if contact_shadow:contact_shadow.transfer_visibility=1.-smoothstep(0.,.16,dissolve)

func _process(delta:float)->void:
	# An idle arrival emitter must not replace the departure's actor effect.
	effect.update_effect(delta,dissolve,charge,stage in [Stage.CONTACT,Stage.DEPART,Stage.ARRIVE,Stage.RELEASE],stage==Stage.ARRIVE)

func prompt()->String:
	if busy():
		return "Arriving in "+destination_label+"…" if stage in [Stage.ARRIVE,Stage.RELEASE] else "Transfer linked — "+destination_label
	if near():
		if not error_message.is_empty():return error_message
		if required_canister and not required_canister.is_collected:
			if level.level_index == 1:
				return "Cell required. Return left to the terminal roof at X 221. Use its side access ladder."
			return "Power cell required — collect this stage's cell to enable the link."
		return "Transfer to "+destination_label+" — "+("B / Cross" if not Input.get_connected_joypads().is_empty() else "T") if can_activate() else "Stand beside the relay to transfer."
	return ""

func cancel()->void:
	if not busy() and stage!=Stage.DONE:return
	if get_tree().has_meta(TICKET):get_tree().remove_meta(TICKET)
	dissolve=0.;charge=0.;overlay.color.a=0.;_apply_actor_effect()
	actor.ready_for_input=true;actor.set_physics_process(true)
	actor.velocity=Vector3.ZERO;actor.jump_buffer=0.;actor.jump_held=false
	actor._state("Locomotion");actor.current_clip="";actor._play("Idle",.18)
	level.level_selector.disabled=false
	_enter(Stage.IDLE)
