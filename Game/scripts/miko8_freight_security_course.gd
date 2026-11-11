extends "res://scripts/miko8_tutorial_course.gd"
## Level 4 uses the established metre-scale kit. See Docs/LEVEL4_WARDEN_RUN.md.
const LENGTH := 180.0
const CHECKPOINT_X := 55.5
const CHECKPOINTS := [55.5, 123.5]
const EXIT_POSITION := Vector3(178.0, 0.0, 0.0)
const STATIC_MESH_BATCH := preload("res://scripts/miko8_static_mesh_batch.gd")
const ROOFS := [
	["InspectionRoof", 25.0, 34.0, 3.0],
	["SwitchRoof", 35.6, 44.6, 3.6],
	["FreightWest", 59.0, 67.0, 3.0],
	["FreightMiddle", 68.6, 77.0, 3.0],
	["FreightEast", 78.6, 87.0, 3.6],
	["IntakeRoof", 96.0, 104.0, 3.0],
	["DispatchWest", 126.0, 135.0, 3.8],
	["DispatchEast", 136.6, 146.0, 4.15],
	["RelayWest", 156.0, 164.0, 3.0],
	["RelayEast", 165.6, 176.0, 3.35],
]
var checkpoint_reached := false
var checkpoint_index := -1
var checkpoint_signs: Array[Label3D] = []
var saved_defeats: Array[StringName] = []
var locks: Array[Dictionary] = []
var approach_shutters: Array[Node3D] = []

func _ready() -> void:
	name = "FreightSecurityCourse"
	# Full-size .8 m cases form two-sided steps, never scaled platform models.
	_cargo_steps(11.4, 0.0)
	for roof: Array in ROOFS:
		_service_roof(roof[0], roof[1], roof[2], roof[3])
	# One vault keeps this roof flowing and leaves both ladder exits clear.
	var roof_case := _crate(Vector3(73.0, 3.4, 0))
	roof_case.freeze = true
	roof_case.suit_movable = false
	roof_case.block_movable = false
	roof_case.set_meta("budget_always_simulate", true)
	roof_case.remove_from_group("miko8_charge_targets")
	_secured_cargo(151.5)
	var cooling := preload("res://scenes/reusable_cooling_station.tscn").instantiate()
	cooling.position.x = 119.0
	cooling.passage_length = 2.2
	cooling.wall_z = -2.0
	add_child(cooling)
	_collectible(Vector3(175.4, 3.365, 0))
	_warden_lock(23.0, 0.0, "GateWarden")
	_warden_lock(174.0, 3.35, "RelayWarden")
	# Existing full-size security shutters interrupt roof-to-roof firing lines.
	# They latch open on approach from either side, before Miko reaches them.
	for at: Vector3 in [Vector3(36.7, 3.6, 0), Vector3(79.7, 3.6, 0), Vector3(138.0, 4.15, 0), Vector3(167.0, 3.35, 0)]:
		var gate := preload("res://scripts/miko8_tutorial_shutter.gd").new()
		gate.position = at
		gate.refined = true
		gate.conduit_length = 1.0
		add_child(gate)
		gate.name = "ApproachShutter%d" % int(at.x)
		gate.indicator.albedo_color = Color("e7b878")
		approach_shutters.append(gate)
	_wall_sign("L2 / G: SABRE   R2 / F: SHIELD", Vector3(15.5, 2.9, -2.0), 4.8)
	_wall_sign("BLOCK THE BURST / CLOSE IN / STRIKE", Vector3(20.0, 3.6, -2.0), 4.8)
	_wall_sign("01 / INSPECTION", Vector3(17.5, 4.55, -3.08), 3.4)
	_wall_sign("02 / FREIGHT ROOFS", Vector3(65.0, 5.15, -3.42), 3.7)
	_wall_sign("03 / COOLING INTAKE", Vector3(110.8, 4.50, -3.22), 3.8)
	_wall_sign("04 / DISPATCH", Vector3(140.0, 5.20, -3.52), 3.4)
	_wall_sign("05 / NETWORK RELAY", Vector3(169.5, 5.90, -3.22), 3.8)
	for x: float in CHECKPOINTS:
		checkpoint_signs.append(_wall_sign("SERVICE / RECHARGE", Vector3(x, 2.3, -2.0), 3.1))
		_checkpoint_marker(x)
	var foliage := preload("res://scripts/miko8_yard_foliage.gd").new()
	for x: float in [6., 15., 23.8, 34.8, 46., 54., 58., 68., 78., 88., 94., 105., 114., 122., 125., 136., 147., 154., 165., 177.]:
		for offset: float in [-.14, 0., .19]:
			foliage.custom_locations.append(Vector3(x + offset, .012, 1.05))
	add_child(foliage)
	_batch_kit()

func _batch_kit() -> void:
	for ladder in get_tree().get_nodes_in_group("miko8_ladders"):
		if ladder.get_parent() != self: continue
		var parts: Array[MeshInstance3D] = []
		parts.assign(ladder.find_children("*", "MeshInstance3D", true, false))
		STATIC_MESH_BATCH.bake(ladder, parts)
	var gates := approach_shutters.duplicate()
	for lock in locks: gates.append(lock.gate)
	for gate in gates:
		var frame_parts: Array[MeshInstance3D] = []
		for child in gate.get_children():
			if child is MeshInstance3D and child not in gate.slats: frame_parts.append(child)
		STATIC_MESH_BATCH.bake(gate, frame_parts)
		for slat in gate.slats:
			var slat_parts: Array[MeshInstance3D] = [slat]
			slat_parts.append_array(slat.find_children("*", "MeshInstance3D", true, false))
			STATIC_MESH_BATCH.bake(slat, slat_parts)

func _cargo_steps(x: float, floor_y: float) -> void:
	for data: Vector2 in [Vector2(x - 1.6, .4), Vector2(x, .4), Vector2(x, 1.2), Vector2(x + 1.6, .4)]:
		var crate := _crate(Vector3(data.x, floor_y + data.y, 0))
		crate.name = "SecuredCase_%d_%d" % [int(data.x * 10), int(data.y * 10)]
		crate.freeze = true
		crate.suit_movable = false
		crate.block_movable = false
		crate.set_meta("budget_always_simulate", true)
		crate.remove_from_group("miko8_charge_targets")

func _warden_lock(x: float, floor_y: float, guard_name: String) -> void:
	var gate := preload("res://scripts/miko8_tutorial_shutter.gd").new()
	gate.position = Vector3(x, floor_y, 0)
	gate.refined = true
	gate.conduit_length = 2.0
	add_child(gate)
	gate.name = guard_name + "Lock"
	gate.indicator.albedo_color = Color("f1af66")
	var label := _wall_sign("WARDEN LINK", Vector3(x, floor_y + 4.65, 0), 2.5)
	locks.append({"gate": gate, "guard": guard_name, "label": label, "open": false})

func _physics_process(_delta: float) -> void:
	var level := get_parent()
	if not is_instance_valid(level.actor) or level.resetting: return
	for lock: Dictionary in locks:
		var guard := level.get_node(NodePath(lock.guard))
		var cleared: bool = guard.health <= 0
		if cleared != lock.open:
			lock.open = cleared
			lock.gate.set_open(cleared)
			lock.gate.indicator.albedo_color = Color("80e8bd") if cleared else Color("f1af66")
			lock.label.text = "ACCESS OPEN" if cleared else "WARDEN LINK"
			lock.label.modulate = Color("9fe5c4") if cleared else Color("efc18c")
	var player: CharacterBody3D = level.actor
	if player.health <= 0 or not player.ready_for_input or not player.is_on_floor(): return
	for gate in approach_shutters:
		if not gate.opened and absf(player.position.x - gate.position.x) < 4.8 and absf(player.position.y - gate.position.y) < 1.5:
			gate.set_open(true)
			gate.indicator.albedo_color = Color("80e8bd")
	if checkpoint_index + 1 >= CHECKPOINTS.size(): return
	var next_x: float = CHECKPOINTS[checkpoint_index + 1]
	if player.position.x >= next_x and player.position.x < next_x + 3.0 and absf(player.position.y) < .15:
		activate_checkpoint()

func activate_checkpoint() -> void:
	if checkpoint_index + 1 >= CHECKPOINTS.size(): return
	checkpoint_index += 1
	checkpoint_reached = true
	checkpoint_signs[checkpoint_index].text = "CHECKPOINT / LINKED"
	checkpoint_signs[checkpoint_index].modulate = Color("a8e6c6")
	get_parent().actor.health = get_parent().actor.MAX_HEALTH
	saved_defeats.clear()
	for guard in get_tree().get_nodes_in_group("level4_wardens"):
		if guard.health <= 0: saved_defeats.append(guard.name)

func restart_position() -> Vector3:
	return Vector3(CHECKPOINTS[checkpoint_index] if checkpoint_reached else 2.4, .02, 0)

func restore_encounters() -> void:
	for gate in approach_shutters:
		gate.reset_shutter()
		gate.indicator.albedo_color = Color("e7b878")
	for guard in get_tree().get_nodes_in_group("level4_wardens"):
		if guard.name in saved_defeats: guard.restore_defeated()

func _checkpoint_marker(x: float) -> void:
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("333f43")
	steel.roughness = .85
	for offset: float in [-1.25, 1.25]:
		var post := MeshInstance3D.new()
		var column := BoxMesh.new()
		column.size = Vector3(.065, 2.22, .065)
		post.mesh = column
		post.position = Vector3(x + offset, 1.11, -2.02)
		post.material_override = steel
		post.layers = 4
		add_child(post)
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = Color("83b4ab")
	for offset: float in [-.65, .65]:
		var mesh := MeshInstance3D.new()
		var strip := BoxMesh.new()
		strip.size = Vector3(.08, .012, 1.7)
		mesh.mesh = strip
		mesh.position = Vector3(x + offset, .012, 0)
		mesh.material_override = paint
		add_child(mesh)

func _wall_sign(text: String, at: Vector3, width: float) -> Label3D:
	var bracket := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(width, .36, .08)
	bracket.mesh = plate
	bracket.position = at
	bracket.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("253237")
	metal.roughness = .85
	bracket.material_override = metal
	add_child(bracket)
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = .0033
	label.position.z = .044
	label.modulate = Color("d8c6a3")
	label.outline_size = 0
	bracket.add_child(label)
	return label

func hint_at(x: float) -> String:
	if x < 14.0: return "Vault the freight. Wardens fire two shots, then lower their blasters."
	if x < 24.0: return "Block the burst with R2 / F, close in, then strike with L2 / G. Three hits open the gate."
	if x < 46.0: return "Take the service ladder. Jump the roof gap and fire on the move."
	if x < 55.5: return "Drop into the loading yard. The recharge point is just beyond the patrol."
	if x < 89.0: return "Cross the freight roofs. Missed a jump? Both walls have service ladders."
	if x < 105.0: return "Up and over the intake roof. Watch the landing below."
	if x < 122.0: return "Clear the intake patrol, then crouch beneath the cooling duct."
	if x < 149.0: return "Checkpoint linked. Climb to dispatch and keep moving across the roof gap."
	if x < 174.0: return "Final relay ahead. Defeat its Warden to release the power cell."
	return "Collect the power cell, drop to the network relay, and transfer out."
