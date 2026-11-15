extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool,message: String) -> void:
	print("PASS " if value else "FAIL ",message)
	if not value:
		failures += 1

func frames(count: int) -> void:
	for frame in range(count):
		await physics_frame

func run() -> void:
	var room = load("res://lab_cutaway.tscn").instantiate()
	room.connect_exit = false
	root.add_child(room)
	current_scene = room
	var miko = room.actor
	miko.automation = true
	await frames(30)
	for pole in [0,1,2]:
		miko.position = room.Layout.ENTRANCE+Vector3(1.1,.04,0)
		miko._set_suit_pole(pole)
		miko.command_axis = -1
		await frames(35)
		check(miko.position.x > room.Layout.ENTRANCE.x,"White entrance seals polarity %d" % pole)
	miko.command_axis = 0
	miko.position = room.Layout.EXIT+Vector3(-1.4,.04,0)
	miko._set_suit_pole(2)
	miko.command_axis = 1
	await frames(40)
	check(miko.position.x < room.Layout.EXIT.x and not room.gate.passable,"Blue field blocks matching polarity")
	miko._set_suit_pole(1)
	await frames(12)
	check(room.gate.passable and room.gate.field_strength < .2,"Opposite polarity dissipates field and opens passage")
	# Retreat before committing to the exit; the field must recover smoothly.
	miko.command_axis = -1
	await frames(70)
	check(room.gate.field_strength > .99 and not room.gate.barrier.disabled,"Field recharges after retreat")
	miko.command_axis = 0
	miko._set_suit_pole(0)
	miko.position = room.Layout.EXIT+Vector3(-1.4,.04,0)
	miko.command_axis = 1
	await frames(35)
	check(miko.position.x < room.Layout.EXIT.x,"Neutral suit remains blocked")
	miko._set_suit_pole(1)
	await frames(130)
	check(room.leaving and not room.suit_readout.visible,"Miko enters the concealed passage without a floating HUD")
	await frames(120)
	check(room.complete and miko.position.x > room.Layout.EXIT.x+2.9,"Miko clears tunnel before completion")
	room.reset_room()
	await frames(20)
	check(not room.complete and not room.leaving and room.suit_readout.visible,"Reset restores the playable view")
	quit(1 if failures else 0)
