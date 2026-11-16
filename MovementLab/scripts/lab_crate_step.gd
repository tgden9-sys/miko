extends Node3D

const Kit := preload("res://scripts/lab_art_kit.gd")
const SlidingCrate := preload("res://scripts/lab_training_crate.gd")
const DOCK_SOUND := preload("res://audio/impactMetal_heavy_001.ogg")
const CRATE_SIZE := Vector3(.8, .8, .8)
const RAIL_LIFT := .085

var actor: CharacterBody3D
var home: Vector3
var stop_x: float
var landing: Vector3
var precharged: bool
var progress_key: StringName
var hint_layer: CanvasLayer
var crate: SlidingCrate
var sound: AudioStreamPlayer3D
var prompt: PanelContainer
var text: Label

func _ready() -> void:
	_build_track()
	_build_prompt()
	sound = AudioStreamPlayer3D.new()
	sound.stream = DOCK_SOUND
	sound.max_distance = 11.0
	sound.volume_db = -11.0
	sound.position = Vector3(stop_x, home.y+.28, .08)
	add_child(sound)
	crate = SlidingCrate.new()
	crate.name = "GuidedSteelCrate"
	crate.crate_size = CRATE_SIZE
	crate.position = home + Vector3.UP * (CRATE_SIZE.y * .5 + RAIL_LIFT + .008)
	crate.stop_x = stop_x
	crate.charge_squash = false
	crate.docking_changed.connect(_on_docking_changed)
	add_child(crate)
	reset()
	if get_tree().get_meta(progress_key, false):
		crate.restore_at_stop(home.y)

func reset() -> void:
	if crate.at_stop:
		return
	crate.reset_charge_body()
	if precharged:
		crate.restore_charge(1, INF)

func _on_docking_changed(seated: bool) -> void:
	get_tree().set_meta(progress_key, seated)
	if seated:
		sound.play()

func _physics_process(_delta: float) -> void:
	var p := actor.global_position
	var near := absf(p.x - crate.global_position.x) < 3.45 or absf(p.x - stop_x) < 2.4
	if actor.automation or not near or p.y >= landing.y - .06 or p.y < home.y - .25:
		prompt.hide()
		return
	var message := "From the crate, jump again near the top of your first jump"
	if not crate.at_stop:
		if crate.polarity == 0:
			message = "Charge the steel crate  [F / LT] or [G / RT]"
		elif actor.suit_polarity != crate.polarity:
			message = "Match the crate’s red pole  [U / LB]" if crate.polarity == 1 else "Match the crate’s blue pole  [I / RB]"
		else:
			message = "Stand behind the crate to push it to the stop"
	if text.text != message:
		text.text = message
	prompt.show()

func _build_track() -> void:
	var kit := Kit.new(self, Kit.bulkhead_paint())
	var side := signf(stop_x - home.x)
	var seat_edge := stop_x - side * CRATE_SIZE.x * .5
	var slope_start := seat_edge - side * .38
	for z in [-.36, .36]:
		var start := Vector3(home.x - side * .50, home.y + RAIL_LIFT, z)
		var corner := Vector3(slope_start, home.y + RAIL_LIFT, z)
		# Run the ramp into the deck so a returning crate meets a slope, not a lip.
		var seat := Vector3(seat_edge, home.y - .04, z)
		_add_rail(kit, start, corner)
		_add_rail(kit, corner, seat)
		kit.box(Vector3(stop_x, home.y + .024, z * 1.20), Vector3(.85, .045, .052), Color("758380"))
	kit.finish()

func _add_rail(kit: Kit, start: Vector3, end: Vector3) -> void:
	var span := end - start
	var angle := atan2(span.y, span.x) if span.x >= 0.0 else atan2(-span.y, -span.x)
	var center := (start + end) * .5 - Vector3.UP * .034
	var size := Vector3(span.length(), .068, .102)
	var rail := StaticBody3D.new()
	rail.collision_layer = 4
	rail.collision_mask = 0
	rail.position = center
	rail.rotation.z = angle
	add_child(rail)
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	rail.add_child(collider)
	kit.box(center, size, Color("546265"), false, Vector3(0, 0, angle))

func _build_prompt() -> void:
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	center.offset_top = -78
	center.offset_bottom = -28
	prompt = PanelContainer.new()
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(prompt)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.025, .043, .058, .92)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 9
	style.content_margin_bottom = 10
	prompt.add_theme_stylebox_override("panel", style)
	text = Label.new()
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 21)
	text.add_theme_color_override("font_color", Color("e4f1ec"))
	prompt.add_child(text)
	prompt.hide()
