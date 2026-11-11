extends SceneTree
var lab: Node3D
var actor: CharacterBody3D
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func check(label: String, condition: bool, detail: Variant = null) -> void:
	results.append({"test":label,"passed":condition,"detail":detail})
	print("PASS " if condition else "FAIL ",label," ",detail)

func reset() -> void:
	lab.reset_room()
	actor.command_axis = 0
	actor.command_vertical = 0
	actor.command_held = false
	await frames(4)

func apex() -> float:
	var highest := actor.position.y
	for i in range(100):
		await frames(1)
		highest = maxf(highest,actor.position.y)
	return highest

func run() -> void:
	lab = (load("res://lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	actor = lab.actor
	actor.automation = true
	await reset()
	check("canonical skeleton retained", actor.skeleton.get_bone_count() == 53)
	check("empty room has one platform and one dummy", lab.has_node("JumpPlatform") and lab.has_node("Dummy") and not lab.has_node("Abilities"))
	actor.command_held = true
	actor.press("jump")
	await frames(1)
	check("jump takes off on next physics tick",actor.velocity.y > 8,actor.velocity.y)
	var full := await apex()
	await reset()
	actor.command_held = true
	actor.press("jump")
	await frames(2)
	actor.command_held = false
	var tap := await apex()
	check("tap jump is lower than held jump",tap < full*.65,{"held":full,"tap":tap})
	await reset()
	actor.command_held = true
	actor.press("jump")
	await frames(20)
	actor.press("jump")
	await frames(1)
	check("double jump launches",actor.jumps == 2 and actor.velocity.y>8)
	await frames(5)
	actor.press("jump")
	await frames(1)
	check("third jump rejected",actor.jumps == 2 and actor.velocity.y<8.5)
	var double_height := await apex()
	check("double jump adds useful height", double_height>full+1.0,double_height)
	await reset()
	actor.command_held = true
	actor.press("jump")
	await frames(5)
	var attack_apex := actor.position.y
	var landed_tick := -1
	var descent_seen := false
	var upward_reversal := false
	for tick in range(140):
		if tick%7 == 0: actor.press("attack")
		await frames(1)
		attack_apex = maxf(attack_apex,actor.position.y)
		if actor.velocity.y < -.1: descent_seen = true
		if descent_seen and actor.velocity.y > .1: upward_reversal = true
		if actor.is_on_floor(): landed_tick = tick; break
	check("air attack spam cannot gain height",attack_apex<full+.15,{"normal_apex":full,"attack_apex":attack_apex})
	check("air attack spam still lands",landed_tick>=0 and landed_tick<90,landed_tick)
	check("air attacks never reverse falling velocity",not upward_reversal)
	await reset()
	actor.command_held = true
	actor.press("jump")
	await frames(5)
	actor.press("attack")
	await frames(3)
	check("air attacks use dedicated aerial clip",actor.pose_name.ends_with("/AirA"),actor.pose_name)
	await reset()
	actor.command_held = true
	actor.press("jump")
	await frames(8)
	actor.press("jump")
	await frames(3)
	check("double jump uses supplied flip",actor.pose_name.ends_with("/DoubleJump"),actor.pose_name)
	await frames(90)
	check("air attack pose releases on landing",actor.is_on_floor() and not actor.pose_name.ends_with("/AirA"))
	await reset()
	actor.command_axis = 1
	await frames(12)
	actor.command_axis = -1
	await frames(10)
	check("responsive reversal",actor.velocity.x < -6,actor.velocity.x)
	await reset()
	var start := actor.position.x
	actor.press("dash")
	await frames(10)
	check("ground dash fixed distance",actor.position.x-start>2.2 and actor.position.x-start<2.9,actor.position.x-start)
	await reset()
	actor.command_held = true
	actor.press("jump")
	await frames(8)
	actor.press("dash")
	await frames(11)
	check("air dash consumed once",actor.air_dash_used)
	await frames(10)
	actor.press("dash")
	await frames(1)
	check("second air dash rejected",actor.state != "dash")
	await reset()
	actor.position = Vector3(-4,.13,0)
	actor.velocity.y = -4
	actor.jumps = 2
	await frames(1)
	actor.command_held = true
	actor.press("jump")
	await frames(4)
	check("jump buffered across landing",actor.velocity.y > 6,actor.velocity.y)
	await reset()
	actor.position = Vector3(6.3,1.46,0)
	await frames(5)
	actor.command_axis = 1
	var guard := 0
	while actor.is_on_floor() and guard<30:
		await frames(1)
		guard += 1
	await frames(2)
	actor.command_held = true
	actor.press("jump")
	await frames(1)
	check("coyote jump preserves double jump",actor.jumps == 1 and actor.velocity.y>8,{"jumps":actor.jumps,"vy":actor.velocity.y})
	await reset()
	actor.position.x = lab.dummy.position.x-1.0
	actor.press("attack")
	await frames(20)
	check("one hit per swing",lab.dummy.hits == 1,lab.dummy.hits)
	actor.press("attack")
	await frames(8)
	actor.press("attack")
	await frames(40)
	check("three-part buffered combo",lab.dummy.hits == 3,lab.dummy.hits)
	await reset()
	actor.position.x = lab.dummy.position.x-1.0
	actor.press("attack")
	await frames(12)
	actor.press("dash")
	await frames(5)
	check("dash cancels attack recovery",actor.state == "dash",actor.state)
	await reset()
	actor.position.x = lab.dummy.position.x-1.0
	actor.command_vertical = 1
	actor.press("attack")
	await frames(12)
	check("launcher lifts dummy",lab.dummy.velocity.y>4,lab.dummy.velocity.y)
	await reset()
	actor.position = Vector3(lab.dummy.position.x,3,0)
	await frames(2)
	actor.command_vertical = -1
	actor.press("attack")
	await frames(35)
	check("slam lands and hits once",lab.dummy.hits == 1 and actor.is_on_floor(),lab.dummy.hits)
	await reset()
	actor.press("parry")
	await frames(4)
	check("timed frontal parry succeeds",actor.receive_attack(actor.position.x+1))
	check("parry counts success",actor.parry_count == 1)
	await reset()
	actor.press("parry")
	await frames(4)
	check("parry does not protect behind",not actor.receive_attack(actor.position.x-1) and actor.health==90)
	await reset()
	actor.position = Vector3(2.3,.03,0)
	actor.press("dash")
	await frames(12)
	check("dash respects platform wall",actor.position.x<2.8,actor.position.x)
	await reset()
	actor.position = Vector3(2.0,.03,0)
	actor.command_held = true
	actor.press("jump")
	await frames(13)
	actor.command_axis = 1
	await frames(20)
	actor.command_axis = 0
	await frames(50)
	check("land on raised platform",actor.is_on_floor() and actor.position.y>1.4,actor.position)
	actor.position.z = .3
	await frames(1)
	check("movement stays in plane",is_zero_approx(actor.position.z))
	var all_finite := true
	for i in range(actor.skeleton.get_bone_count()):
		all_finite = all_finite and actor.skeleton.get_bone_global_pose(i).is_finite()
	check("animated bones stay finite",all_finite)
	await reset()
	actor.automation = false
	var button := InputEventJoypadButton.new()
	button.device = 0
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	Input.parse_input_event(button)
	await frames(2)
	check("controller A maps to jump",actor.velocity.y>8,actor.velocity.y)
	button.pressed = false
	Input.parse_input_event(button)
	await frames(70)
	button = InputEventJoypadButton.new()
	button.device = 0
	button.button_index = JOY_BUTTON_B
	button.pressed = true
	Input.parse_input_event(button)
	await frames(2)
	check("controller B maps to dash",actor.state=="dash",actor.state)
	button.pressed = false
	Input.parse_input_event(button)
	actor.automation = true
	var failures := results.filter(func(r: Dictionary): return not r.passed).size()
	var file := FileAccess.open("res://../Builds/Validation/MovementLab/gameplay_checks.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"failures":failures,"tests":results},"\t"))
	print("LAB_TESTS_COMPLETE failures=",failures," total=",results.size())
	quit(1 if failures else 0)
