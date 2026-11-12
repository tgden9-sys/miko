extends CanvasLayer

var sfx: Node
var panel: PanelContainer
var active_profile_label: Label

var _preview_players: Array[AudioStreamPlayer] = []
var _preview_idx := 0
var _cached_streams: Dictionary = {}

func _init() -> void:
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.name = "SuitePlayer_%d" % i
		add_child(p)
		_preview_players.append(p)
	_cache_all_streams()

func _ready() -> void:
	layer = 10
	sfx = preload("res://scripts/miko8_sound.gd").get_instance(self)
	_build_ui()
	hide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			toggle_suite()

func toggle_suite() -> void:
	if visible:
		hide()
	else:
		show()
		if not sfx or not is_instance_valid(sfx):
			sfx = preload("res://scripts/miko8_sound.gd").get_instance(self)
		_update_profile_label()

func _cache_all_streams() -> void:
	var paths := {
		"droid_laser_swing": "res://audio/droid_laser_swing.wav",
		"laser_clash": "res://audio/laser_clash.wav",
		"forceField_000": "res://audio/forceField_000.ogg",
		"impactPunch_heavy_000": "res://audio/impactPunch_heavy_000.ogg",
		"impactPunch_heavy_001": "res://audio/impactPunch_heavy_001.ogg",
		"impactPunch_heavy_002": "res://audio/impactPunch_heavy_002.ogg",
		"punch": "res://audio/punch.wav",
		"impactWood_heavy_000": "res://audio/impactWood_heavy_000.ogg",
		"impact_heavy": "res://audio/impact_heavy.ogg",
		"knife-stab": "res://audio/knife-stab.wav",
		"slashcut": "res://audio/slashcut.wav"
	}
	for key in paths:
		var p: String = paths[key]
		if FileAccess.file_exists(p):
			if p.ends_with(".ogg"):
				_cached_streams[key] = AudioStreamOggVorbis.load_from_file(p)
			else:
				_cached_streams[key] = AudioStreamWAV.load_from_file(p)

func _play_clip(stream: AudioStream, vol: float = -4.0, pitch: float = 1.0) -> void:
	if not stream or _preview_players.is_empty():
		return
	var p: AudioStreamPlayer = _preview_players[_preview_idx]
	_preview_idx = (_preview_idx + 1) % _preview_players.size()
	p.stream = stream
	p.volume_db = vol
	p.pitch_scale = pitch
	if p.is_inside_tree():
		p.play()

func _build_ui() -> void:
	var bg_dim := ColorRect.new()
	bg_dim.color = Color(0, 0, 0, 0.55)
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_dim.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg_dim)
	
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(920, 680)
	panel.offset_left = -460
	panel.offset_top = -340
	panel.offset_right = 460
	panel.offset_bottom = 340
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("11171f")
	style.border_color = Color("3f5869")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	margin.add_child(root_vbox)

	# --- Title Row ---
	var title_hbox := HBoxContainer.new()
	root_vbox.add_child(title_hbox)
	
	var title_lbl := Label.new()
	title_lbl.text = "MIKO 8  /  AUDIO SUITE & COMBAT SOUND LAB"
	title_lbl.modulate = Color("efbb7e")
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "  [X] CLOSE (F3)  "
	close_btn.pressed.connect(hide)
	title_hbox.add_child(close_btn)

	# Active Profile Status Banner
	active_profile_label = Label.new()
	active_profile_label.modulate = Color("8bdad1")
	active_profile_label.add_theme_font_size_override("font_size", 15)
	root_vbox.add_child(active_profile_label)
	_update_profile_label()

	root_vbox.add_child(HSeparator.new())

	# --- SECTION 1: Miko Sword Swings ---
	_add_header(root_vbox, "1. MIKO SWORD (TONED-DOWN CYBER ENERGY BLADE)")
	var miko_row := HBoxContainer.new()
	miko_row.add_theme_constant_override("separation", 10)
	root_vbox.add_child(miko_row)

	_add_sound_button(miko_row, "▶ Combo 1 Slice", func():
		_play_clip(_cached_streams.get("droid_laser_swing"), -8.5, 1.10)
		if sfx: sfx.play_miko_swing(0)
	)
	_add_sound_button(miko_row, "▶ Combo 2 Mid", func():
		_play_clip(_cached_streams.get("droid_laser_swing"), -8.0, 1.00)
		if sfx: sfx.play_miko_swing(1)
	)
	_add_sound_button(miko_row, "▶ Combo 3 Heavy", func():
		_play_clip(_cached_streams.get("droid_laser_swing"), -7.5, 0.90)
		if sfx: sfx.play_miko_swing(2)
	)
	_add_sound_button(miko_row, "▶ Aerial Slam / Launch", func():
		_play_clip(_cached_streams.get("droid_laser_swing"), -6.5, 0.80)
		if sfx: sfx.play_miko_swing(0, true)
	)

	root_vbox.add_child(HSeparator.new())

	# --- SECTION 2: Agile Droid Sword ---
	_add_header(root_vbox, "2. AGILE DROID SWORD")
	var droid_row := HBoxContainer.new()
	droid_row.add_theme_constant_override("separation", 10)
	root_vbox.add_child(droid_row)
	_add_sound_button(droid_row, "▶ Full Cyber Laser Swing", func():
		_play_clip(_cached_streams.get("droid_laser_swing"), -4.5, 1.0)
		if sfx: sfx.play_droid_sword()
	)

	root_vbox.add_child(HSeparator.new())

	# --- SECTION 3: Solid Combat Impacts ---
	_add_header(root_vbox, "3. SOLID ROBOTIC IMPACTS (ZERO MARACAS / ZERO XYLOPHONE)")
	var desc_lbl := Label.new()
	desc_lbl.text = "Select an active impact profile for live gameplay, or audition individual sounds:"
	desc_lbl.modulate = Color("9cb3b0")
	desc_lbl.add_theme_font_size_override("font_size", 13)
	root_vbox.add_child(desc_lbl)

	# Profile selection buttons
	var profiles_grid := GridContainer.new()
	profiles_grid.columns = 2
	profiles_grid.add_theme_constant_override("h_separation", 16)
	profiles_grid.add_theme_constant_override("v_separation", 8)
	root_vbox.add_child(profiles_grid)

	_add_profile_card(profiles_grid, "PROFILE A: Solid Heavy Punches (Recommended)", "Deep blunt body crunches (punch_heavy_000, 001, 002)", 0)
	_add_profile_card(profiles_grid, "PROFILE B: Solid Blunt Crack", "Hard chassis crack (impactWood_heavy, impact_heavy)", 1)
	_add_profile_card(profiles_grid, "PROFILE C: Visceral Blade Cut", "Sharp cutting slice (slashcut, knife-stab)", 2)
	_add_profile_card(profiles_grid, "PROFILE D: Balanced Hybrid", "Combined punch body + blade slice transient", 3)

	# Individual Sound Audition Row
	var ind_lbl := Label.new()
	ind_lbl.text = "Audition Specific Source Audio Files:"
	ind_lbl.modulate = Color("afc0bd")
	ind_lbl.add_theme_font_size_override("font_size", 12)
	root_vbox.add_child(ind_lbl)

	var ind_row1 := HBoxContainer.new()
	ind_row1.add_theme_constant_override("separation", 8)
	root_vbox.add_child(ind_row1)
	_add_raw_button(ind_row1, "Punch Heavy 0", "impactPunch_heavy_000")
	_add_raw_button(ind_row1, "Punch Heavy 1", "impactPunch_heavy_001")
	_add_raw_button(ind_row1, "Punch Heavy 2", "impactPunch_heavy_002")
	_add_raw_button(ind_row1, "Punch Transient", "punch")
	
	var ind_row2 := HBoxContainer.new()
	ind_row2.add_theme_constant_override("separation", 8)
	root_vbox.add_child(ind_row2)
	_add_raw_button(ind_row2, "Solid Wood/Chassis", "impactWood_heavy_000")
	_add_raw_button(ind_row2, "Heavy Metal Impact", "impact_heavy")
	_add_raw_button(ind_row2, "Knife Stab", "knife-stab")
	_add_raw_button(ind_row2, "Slash Cut", "slashcut")

	root_vbox.add_child(HSeparator.new())

	# --- SECTION 4: Parry & Defense ---
	_add_header(root_vbox, "4. PARRY & CLASH")
	var def_row := HBoxContainer.new()
	def_row.add_theme_constant_override("separation", 10)
	root_vbox.add_child(def_row)
	_add_sound_button(def_row, "▶ Laser Parry Clash", func():
		_play_clip(_cached_streams.get("laser_clash"), -3.5, 1.0)
		if sfx: sfx.play_parry()
	)
	_add_raw_button(def_row, "Force Field Deflect", "forceField_000")

func _add_header(parent: Node, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = Color("e8ebe4")
	lbl.add_theme_font_size_override("font_size", 14)
	parent.add_child(lbl)

func _add_sound_button(parent: Node, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _add_raw_button(parent: Node, text: String, key: String) -> void:
	var btn := Button.new()
	btn.text = "♪ " + text
	btn.pressed.connect(func():
		var stream = _cached_streams.get(key)
		if stream:
			_play_clip(stream, -4.0, 1.0)
	)
	parent.add_child(btn)

func _play_profile_impact(profile_id: int) -> void:
	match profile_id:
		0: # SOLID_PUNCH
			var keys = ["impactPunch_heavy_000", "impactPunch_heavy_001", "impactPunch_heavy_002"]
			var k = keys[randi() % keys.size()]
			_play_clip(_cached_streams.get(k), -3.5, randf_range(0.96, 1.06))
		1: # SOLID_BLUNT
			var keys = ["impactWood_heavy_000", "impact_heavy"]
			var k = keys[randi() % keys.size()]
			_play_clip(_cached_streams.get(k), -3.5, randf_range(0.96, 1.06))
		2: # VISCERAL_BLADE
			_play_clip(_cached_streams.get("slashcut"), -3.5, randf_range(0.96, 1.06))
		3: # BALANCED_HYBRID
			_play_clip(_cached_streams.get("impactPunch_heavy_000"), -4.0, 1.0)
			_play_clip(_cached_streams.get("slashcut"), -5.0, 1.08)

func _add_profile_card(parent: Node, title: String, subtitle: String, profile_id: int) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var set_btn := Button.new()
	set_btn.text = "SET ACTIVE"
	set_btn.pressed.connect(func():
		if not sfx or not is_instance_valid(sfx):
			sfx = preload("res://scripts/miko8_sound.gd").get_instance(self)
		if sfx:
			sfx.current_profile = profile_id
		_update_profile_label()
		_play_profile_impact(profile_id)
		if sfx:
			sfx.play_contact(0.7)
	)
	hbox.add_child(set_btn)

	var test_btn := Button.new()
	test_btn.text = "▶"
	test_btn.pressed.connect(func():
		_play_profile_impact(profile_id)
		if sfx:
			var old = sfx.current_profile
			sfx.current_profile = profile_id
			sfx.play_contact(0.7)
			sfx.current_profile = old
	)
	hbox.add_child(test_btn)

	var vbox := VBoxContainer.new()
	var t_lbl := Label.new()
	t_lbl.text = title
	t_lbl.modulate = Color("f5f7f5")
	t_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(t_lbl)

	var s_lbl := Label.new()
	s_lbl.text = subtitle
	s_lbl.modulate = Color("7a9299")
	s_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(s_lbl)
	
	hbox.add_child(vbox)
	parent.add_child(hbox)

func _update_profile_label() -> void:
	if not active_profile_label:
		return
	var prof_idx := 0
	if sfx and is_instance_valid(sfx):
		prof_idx = int(sfx.current_profile)
	var p_name := "SOLID HEAVY PUNCHES"
	match prof_idx:
		0: p_name = "SOLID HEAVY PUNCHES (Non-Tonal, Meaty Body Hit)"
		1: p_name = "SOLID BLUNT CRACK (Hard Armor Surface Impact)"
		2: p_name = "VISCERAL BLADE CUT (Sharp Cutting Slice)"
		3: p_name = "BALANCED HYBRID (Punch Body + Blade Slice)"
	active_profile_label.text = "CURRENT IN-GAME IMPACT PROFILE:  " + p_name
