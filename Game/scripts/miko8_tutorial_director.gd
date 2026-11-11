extends CanvasLayer
## Paused, skippable lessons. Progress is local to this stage and survives a card.
var level:Node3D
var course:Node3D
var actor:CharacterBody3D
var lessons:Array[Dictionary]=[]
var next_lesson:=0
var shown:=false
var finished:=false
var elapsed:=0.
var opened_at:=0
var panel:Control
var heading:Label
var body:Label
var eyebrow:Label
var continue_button:Button
var replay_button:Button
var current_hint:="Follow the service route to the right."
var current_title:="SYSTEM READY"
var current_controls:=""
var achievements:Dictionary={}
var last_charge:=0
var controls_label:Label

func _ready()->void:
	name="TutorialDirector";layer=40;process_mode=Node.PROCESS_MODE_ALWAYS
	actor=level.actor
	_build_lessons();_build_card()
	course.canister.collected.connect(func():achievements["cell"]=true;current_hint="Power cell secured. Follow the route to the transfer link.")

func _lesson(x:float,title:String,text:String,controls:String,min_height:float=-INF,end_x:float=INF,number:=0)->void:
	lessons.append({"x":x,"title":title,"text":text,"controls":controls,"min_height":min_height,"end_x":end_x,"number":number if number>0 else lessons.size()+1})

func _build_lessons()->void:
	var pad:=not Input.get_connected_joypads().is_empty()
	match level.level_index:
		1:
			_lesson(0.,"Link offline","Find the power cell on the terminal roof. First, move through the service yard.","Left stick: walk / run" if pad else "A / D: run   ·   Ctrl: walk   ·   Shift: sprint")
			_lesson(10.,"Clear the cargo","Jump while moving. Hold Jump for height; release for a shorter hop.","A / Circle: jump" if pad else "Space: jump",-INF,15.)
			_lesson(26.,"Roof access","This building blocks the route. Stand beside its side ladder and climb onto the roof.","Hold Up at the ladder" if pad else "Hold W / Up at the ladder",-INF,31.)
			_lesson(34.,"Cross the service gap","Jump near the roof edge. If you miss, use either wall's maintenance ladder.","Move + hold A / Circle" if pad else "Move + hold Space",2.8,38.2)
			# Keep the original message IDs when a lesson is removed.
			_lesson(63.,"Low clearance","The cooling duct crosses the whole walkway. Crouch, then move beneath it.","Hold Down + move right" if pad else "Hold S / Down + D",-INF,69.5,6)
			_lesson(142.,"Choose your landings","Climb the first tower. Land before jumping again. The ground route leads to the terminal's side ladder if you fall.","Up at the first tower   ·   Hold A / Circle for higher decks" if pad else "Up at the first tower   ·   Hold Space for higher decks",-INF,147.,9)
			_lesson(191.,"Recover the cell","The cell is on the far terminal roof. Climb, cross the roofs and collect it.","Combine your movement skills",-INF,197.,10)
		2:
			_lesson(0.,"Charge the cargo","Aim at the metal crates. Hold a red or blue shot, then release to charge. Opposite colours draw crates together; matching colours push them apart.","Right stick: aim   ·   L1 / R1: hold red / blue, release to fire" if pad else "I J K L: aim   ·   Hold Q / E: red / blue, release to fire")
			_lesson(12.,"Become the other pole","Give Miko the opposite charge to draw a crate towards him; match its charge to push it away. Walk while attracting it to bring it with you.","X / Triangle: red suit   ·   Y / Square: blue suit   ·   Press again: neutral" if pad else "1: red suit   ·   2: blue suit   ·   0: neutral suit")
			_lesson(19.,"Let the wall do the pulling","Charge the wall pad and give the crate the opposite charge. The pad pulls the crate towards it. Matching colours repel. Jump the low housing to continue.","Stationary magnets move crates, never Miko. Charges fade after 15 seconds.")
			_lesson(28.,"Leave a weight behind","Move a crate onto the green pressure plate. Purple means it is pressed and the shutter is open. Neutralise Miko so the crate stays behind while you pass.","Attract or repel the crate into place   ·   Suit neutral: press its colour again" if pad else "1 / 2: move the charged crate   ·   0: leave Miko neutral")
			_lesson(48.,"Lift the heavy cargo","Heavy cargo cannot be pulled by Miko. Charge the ceiling pad and the cargo with opposite colours. Wait until there is room, then walk underneath.","Right stick: aim up at the pad, then at the cargo" if pad else "I / K: aim up / down   ·   Q / E: charge pad and cargo")
			_lesson(63.,"Carry the solution","The next plate is farther from its crate. Draw the crate along with you, place it on the plate, then leave Miko neutral before crossing.","Only ceiling magnets hold cargo up; all other cargo falls")
			_lesson(93.,"Two weights, one lock","The next shutter needs both plates pressed. Fill the farther plate first. Let that crate's charge fade, then bring the other to the nearer plate so they don't pull each other out of place.","Both plates must glow purple together")
			_lesson(120.,"Lift, transport, release","Pass the suspended cargo, then move another crate onto the next plate. You now have the tools to solve the remaining route.","Opposites attract   ·   Matching charges repel   ·   Neutral releases")
			_lesson(151.,"Recover the power cell","Lift the final heavy load to reach the cell behind it. Collect the cell and carry it to the transfer link.","Refresh fading charges before going beneath cargo")
		3:
			_lesson(0.,"Green sabre","Hold attack to chain three sword strikes. Close the distance and slash wooden crates while moving or jumping.","Hold L2: green bolts   ·   Right stick: aim" if pad else "Hold G: green bolts   ·   I J K L: aim")
			_lesson(25.,"Plasma breaks and discharges","Hold plasma, aim, then release to destroy the wooden obstruction. Plasma also removes charge from metal crates and magpads; released cargo falls.","Hold R3, release to fire plasma" if pad else "Hold P, release to fire plasma")
			_lesson(33.,"Try a clean discharge","Charge this metal crate, then hit it with plasma. It returns to neutral instead of breaking. Jump past it when ready.","L1 / R1: charge   ·   R3: plasma" if pad else "Q / E: charge   ·   P: plasma")
			_lesson(43.,"Use the magnetic launcher","Charge the launcher, give Miko the opposite charge, then walk into its centre and stop. He will brace his hands on the caps.","Opposite colours: brace   ·   Same colour: launch")
			_lesson(48.,"Switch and launch","Once Miko is braced, match the launcher's colour. He launches automatically. Steer right in the air onto the high roof.","X / Triangle or Y / Square: change suit, then steer right" if pad else "1 / 2: match the launcher, then hold D in the air")
			_lesson(70.,"Clear a path on the move","Break through the stacked cargo. Slash the supports and the crates above will fall. Crouch to clear the remaining low crates.","Sword in close; plasma for distant obstructions")
			_lesson(83.,"Launch, land, jump","Use the next launcher to reach the higher deck, then carry your momentum to the smaller landing beyond it.","Brace first. Switch colour. Steer right after launching.")
			_lesson(104.,"Choose the right tool","Leave a metal crate on the pressure plate. Beyond the shutter, lift the heavy cargo. Plasma can remove an unwanted charge, but never use it on cargo while beneath it.","Charge for movement   ·   Plasma for discharge")
			_lesson(136.,"Final approach","Clear the timber, charge the last launcher and reach the high roof. The power cell is waiting there. The final duct leads to your transfer link.","Combine shooting, polarity, launching and crouching")
	_lesson(level.transfer_relays[0].position.x-5.,"Ready to transfer","Once you have the power cell, stand beside the link and activate it.","B / Cross: transfer" if pad else "T: transfer",-INF,INF,12 if level.level_index==1 else 0)

func _build_card()->void:
	panel=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(panel)
	var dim:=ColorRect.new();dim.color=Color(.005,.018,.03,.48);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_child(dim)
	var projection:=preload("res://scripts/miko8_tutorial_interface.gd").new()
	projection.actor=actor;projection.camera=level.camera;projection.stage=level.level_index
	projection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_child(projection)
	var centre:=CenterContainer.new();centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_child(centre)
	var card:=PanelContainer.new();card.custom_minimum_size=Vector2(850,0);centre.add_child(card);projection.plate=card
	var style:=StyleBoxEmpty.new()
	style.content_margin_left=32;style.content_margin_right=32;style.content_margin_top=26;style.content_margin_bottom=24;card.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",17);card.add_child(column)
	eyebrow=Label.new();eyebrow.add_theme_font_size_override("font_size",14);eyebrow.modulate=Color("84bdbb");column.add_child(eyebrow)
	heading=Label.new();heading.add_theme_font_size_override("font_size",38);column.add_child(heading)
	body=Label.new();body.custom_minimum_size.x=780;body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_theme_font_size_override("font_size",24);body.modulate=Color("d0dde1");column.add_child(body)
	controls_label=Label.new();controls_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;controls_label.add_theme_font_size_override("font_size",20);controls_label.modulate=Color("98ddcb");column.add_child(controls_label)
	continue_button=Button.new();continue_button.text="RESUME  //  ENTER  ·  ANY PAD BUTTON";continue_button.custom_minimum_size.y=48;continue_button.pressed.connect(dismiss);column.add_child(continue_button)
	var button_style:=StyleBoxFlat.new();button_style.bg_color=Color("19333d");button_style.border_width_left=3;button_style.border_color=Color("87d6c5");button_style.content_margin_left=16
	continue_button.add_theme_stylebox_override("normal",button_style);continue_button.add_theme_stylebox_override("focus",StyleBoxEmpty.new());continue_button.add_theme_font_size_override("font_size",20)
	replay_button=Button.new();replay_button.text="Replay tutorial";replay_button.pressed.connect(_replay);column.add_child(replay_button);replay_button.hide()
	panel.hide()

func _process(delta:float)->void:
	if shown or get_tree().paused:return
	elapsed+=delta
	_track()
	if next_lesson>=lessons.size() or level.resetting or elapsed<2.:return
	while next_lesson < lessons.size() and actor.position.x > float(lessons[next_lesson].end_x):
		next_lesson += 1
	if next_lesson >= lessons.size():
		return
	var lesson:Dictionary=lessons[next_lesson]
	if actor.position.x<float(lesson.x) or actor.position.y<float(lesson.min_height):return
	if not actor.is_on_floor() or actor.state not in ["Locomotion","MoveStart","GroundStop","Brake","WallBlocked","GroundSitIdle","LauncherHold"]:return
	for relay in level.transfer_relays:
		if relay.busy():return
	current_hint=lesson.text;current_title=lesson.title;current_controls=lesson.controls
	_show(lesson.title,lesson.text,lesson.number)
	next_lesson+=1

func _track()->void:
	if level.walk_distance>1.:achievements["walk"]=true
	if level.run_distance>2.:achievements["run"]=true
	if level.jumped:achievements["jump"]=true
	if actor.state.begins_with("Climb"):achievements["climb"]=true
	if actor.state.begins_with("Crouch"):achievements["crouch"]=true
	if actor.suit_polarity!=0:achievements["suit"]=true
	if course.practice_crate and course.practice_crate.polarity!=0:achievements["crate"]=true
	if course.wall_pad and course.wall_pad.polarity!=0:achievements["pad"]=true
	if course.switch and course.switch.pressed:achievements["plate"]=true
	if course.cargo and course.cargo.global_position.y>2.:achievements["lift"]=true
	if actor.launcher_motion.launch_count>0:achievements["launch"]=true
	if course.practice_crate:
		if last_charge!=0 and course.practice_crate.polarity==0:achievements["discharge"]=true
		last_charge=course.practice_crate.polarity

func _show(title:String,text:String,number:=0)->void:
	shown=true;opened_at=Time.get_ticks_msec()
	eyebrow.text="MIKO  //  ONBOARD GUIDANCE     /     %02d–%02d     /     TIME HELD"%[level.level_index,number if number>0 else next_lesson+1]
	heading.text=title;body.text=text;controls_label.text=current_controls;panel.show();get_tree().paused=true
	continue_button.grab_focus()

func _input(event:InputEvent)->void:
	if not shown:return
	var pressed:=false
	if event is InputEventKey:pressed=event.pressed and not event.echo
	elif event is InputEventJoypadButton or event is InputEventMouseButton:pressed=event.pressed
	elif event is InputEventJoypadMotion:
		pressed=event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT] and event.axis_value>.6
	if pressed:
		get_viewport().set_input_as_handled()
		if Time.get_ticks_msec()-opened_at<150:return
		# Consume the dismissal press, including polling-based abilities and jump.
		for action:StringName in InputMap.get_actions():
			if event.is_action(action):Input.action_release(action)
		dismiss()


func dismiss()->void:
	if not shown or Time.get_ticks_msec()-opened_at<150:return
	panel.hide();shown=false;get_tree().paused=false
	# A dismissed card must not leave a buffered jump in the next frame.
	actor.jump_buffer=0.
	if finished:
		for relay in level.transfer_relays:relay.cancel()
		actor.position.x=171.;level._camera(0,true)

func update_hud()->void:
	level.progress.text="TRAINING %d / 3   ·   POWER CELL: %s"%[level.level_index,"SECURED" if course.canister.is_collected else "NOT COLLECTED"]
	level.instruction.text="MIKO // CELL SECURED — REACH THE TRANSFER LINK" if course.canister.is_collected else "MIKO // "+current_title.to_upper()
	level.instruction.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	level.instruction.add_theme_font_size_override("font_size",20)
	level.detail.text=current_controls+"   ·   R / View: restart stage"
	level.detail.add_theme_font_size_override("font_size",16)

func reset_stage()->void:
	get_tree().paused=false;panel.hide();shown=false;finished=false;elapsed=0.;next_lesson=0;achievements.clear();last_charge=0
	current_hint=lessons[0].text;current_title=lessons[0].title;current_controls=lessons[0].controls
	continue_button.text="RESUME  //  ENTER  ·  ANY PAD BUTTON";replay_button.hide()
	course.reset_course()

func finish()->void:
	finished=true;replay_button.show();continue_button.text="Explore this stage"
	_show("Training complete","Movement. Magnetism. Power.\n\nAll three service routes are ready for Miko's journey. Your final cell has powered the transfer.")

func _replay()->void:
	get_tree().paused=false;get_tree().call_deferred("change_scene_to_file","res://scenes/miko8_side_on_mockup.tscn")

func _exit_tree()->void:
	if shown:get_tree().paused=false
