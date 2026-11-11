extends SceneTree
const TRANSFER=preload("res://scripts/miko8_network_transfer.gd")
var failures:=0
func _initialize()->void:call_deferred("_run")
func _ticks(count:int)->void:
	for i in range(count):await physics_frame
func _check(value:bool,label:String)->void:
	print(("PASS " if value else "FAIL ")+label)
	if not value:failures+=1
func _run()->void:
	var level:=load("res://scenes/miko8_level_02.tscn").instantiate() as Node3D
	root.add_child(level);current_scene=level
	var relay:Node3D=level.transfer_relays[0]
	var actor:CharacterBody3D=level.actor
	actor.reset_actor();actor.position=Vector3(73.7,.02,0)
	await _ticks(12)
	_check(relay.can_activate(),"Grounded approach permits transfer")
	actor._state("CrouchIdle")
	_check(not relay.activate(),"Crouching cannot start transfer")
	actor.reset_actor();actor.position=Vector3(73.7,1.,0)
	await _ticks(2)
	_check(not relay.activate(),"Airborne transfer is rejected")
	actor.reset_actor();actor.position=Vector3(73.7,.02,0)
	await _ticks(30)
	var crate:=StaticBody3D.new();var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new()
	shape.size=Vector3(.6,.8,1.);collider.shape=shape;crate.add_child(collider);level.add_child(crate)
	crate.position=Vector3(74.35,.4,0)
	await _ticks(2)
	_check(not relay.activate(),"A crate blocking the contact spot prevents a forced walk through it")
	crate.queue_free();await _ticks(2)
	_check(relay.activate(),"Transfer can start after clearing the approach")
	_check(not relay.activate(),"Repeated activation cannot duplicate the sequence")
	await _ticks(120)
	_check(relay.dissolve>.1 and not actor.ready_for_input,"Departure dissolves Miko while player actions are locked")
	var shared_outline:ShaderMaterial=level.get_node("CelSceneArt").outline
	var world_progress=shared_outline.get_shader_parameter("transfer_progress")
	_check(world_progress==null or world_progress==0.,"World outlines remain unchanged during Miko's dissolve")
	relay.cancel()
	_check(actor.ready_for_input and actor.is_physics_processing() and relay.dissolve==0.,"Cancellation restores the visible, controllable actor")
	_check(not has_meta(relay.TICKET),"Cancellation clears any pending arrival")
	await _ticks(5)
	_check(relay.activate(),"Transfer can be started again after cancellation")
	await _ticks(120)
	await level._restart(false)
	_check(actor.ready_for_input and actor.is_physics_processing() and not relay.busy() and relay.overlay.color.a==0.,"Reset during departure restores input and removes the transfer overlay")
	_check(absf(actor.position.x-2.4)<.05 and not has_meta(TRANSFER.TICKET),"Reset returns to the level start without a delayed scene change")
	actor.reset_actor();actor.position=Vector3(73.7,.02,0)
	await _ticks(12)
	actor.polarity_control.set_polarity(2,true)
	level.set_ambience_muted(true)
	var event:=InputEventAction.new();event.action="miko8_transfer";event.pressed=true
	Input.parse_input_event(event)
	await _ticks(2)
	_check(relay.busy(),"The actual transfer input starts the sequence")
	Input.action_release("miko8_transfer")
	for i in range(700):
		await physics_frame
		if current_scene!=level and is_instance_valid(current_scene) and current_scene.level_index==3 and current_scene.actor.ready_for_input:break
	var destination:Node3D=current_scene
	_check(is_instance_valid(destination) and destination.level_index==3,"Transfer loads Freight District")
	if is_instance_valid(destination) and destination.level_index==3:
		var arrived:CharacterBody3D=destination.actor
		_check(arrived.ready_for_input and arrived.is_physics_processing() and arrived.state=="Locomotion","Arrival returns normal movement and animation")
		_check(absf(arrived.position.x-3.67)<.05 and arrived.position.y<.05,"Miko reconstructs on the destination floor")
		_check(arrived.suit_polarity==2 and destination.ambience_muted,"Suit charge and audio preference survive the transfer")
		_check(not has_meta(TRANSFER.TICKET),"Arrival ticket is consumed exactly once")
		_check(float(arrived.polarity_control.materials[0].get_shader_parameter("transfer_progress"))==0.,"Arrival clears dissolve from the suit")
		var before:=arrived.position.x
		Input.action_press("miko8_right");await _ticks(40);Input.action_release("miko8_right")
		_check(arrived.position.x>before+.7,"Normal walking works after reconstruction")
	print("NETWORK_TRANSFER_RESULT failures=",failures)
	quit(1 if failures else 0)
