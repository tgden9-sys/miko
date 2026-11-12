extends Node

# High-Quality Game Sound Effects Manager for Miko & Agile Droids
# Solid robotic impacts (zero maracas, zero xylophone) and smooth energy blade swings (no whip crack)

const POOL_SIZE := 12

enum ImpactProfile {
	SOLID_PUNCH,     # Deep heavy punch impacts (punch_heavy_000, 001, 002) - thick, solid, punchy
	SOLID_BLUNT,     # Heavy blunt crack (impactWood_heavy + impact_heavy) - solid hard-surface thud
	VISCERAL_BLADE,  # Visceral cutting impacts (slashcut + knife-stab) - sharp blade slice
	BALANCED_HYBRID  # Best-of-both: heavy punch body + sharp slice transient
}

var current_profile: ImpactProfile = ImpactProfile.SOLID_PUNCH

var _players: Array[AudioStreamPlayer] = []
var _pool_index := 0

var laser_swing_wav: AudioStreamWAV
var laser_clash_wav: AudioStreamWAV
var force_field_ogg: AudioStreamOggVorbis

# Sound banks for profiles
var punch_streams: Array[AudioStream] = []
var blunt_streams: Array[AudioStream] = []
var blade_streams: Array[AudioStream] = []
var solid_impact_streams: Array[AudioStream] = []

static var _instance: Node = null

static func get_instance(caller: Node = null) -> Node:
	if _instance and is_instance_valid(_instance):
		return _instance
	if caller and is_instance_valid(caller):
		var tree := caller.get_tree()
		if tree and tree.root:
			var found = tree.root.find_child("Miko8Sound", true, false)
			if found:
				_instance = found
				return _instance
	if not _instance or not is_instance_valid(_instance):
		_instance = preload("res://scripts/miko8_sound.gd").new()
		_instance.name = "Miko8Sound"
		if caller and is_instance_valid(caller):
			var tree := caller.get_tree()
			if tree and tree.root:
				tree.root.call_deferred("add_child", _instance)
			elif caller.is_inside_tree():
				caller.call_deferred("add_child", _instance)
	return _instance

func _init() -> void:
	_init_players()
	_load_audio_assets()

func _enter_tree() -> void:
	_instance = self

func _ready() -> void:
	_instance = self

func _init_players() -> void:
	if not _players.is_empty():
		return
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		add_child(p)
		_players.append(p)

func _load_audio_assets() -> void:
	# 1. Energy Swords (Miko toned-down + Droid full-power)
	if FileAccess.file_exists("res://audio/droid_laser_swing.wav"):
		laser_swing_wav = AudioStreamWAV.load_from_file("res://audio/droid_laser_swing.wav")
	if FileAccess.file_exists("res://audio/laser_clash.wav"):
		laser_clash_wav = AudioStreamWAV.load_from_file("res://audio/laser_clash.wav")
	if FileAccess.file_exists("res://audio/forceField_000.ogg"):
		force_field_ogg = AudioStreamOggVorbis.load_from_file("res://audio/forceField_000.ogg")

	# 2. Bank: Solid Heavy Punches (Zero maracas, zero xylophone)
	for f in ["res://audio/impactPunch_heavy_000.ogg", "res://audio/impactPunch_heavy_001.ogg", "res://audio/impactPunch_heavy_002.ogg"]:
		if FileAccess.file_exists(f):
			var s = AudioStreamOggVorbis.load_from_file(f)
			if s: punch_streams.append(s)
	if FileAccess.file_exists("res://audio/punch.wav"):
		var p = AudioStreamWAV.load_from_file("res://audio/punch.wav")
		if p: punch_streams.append(p)
	solid_impact_streams = punch_streams

	# 3. Bank: Solid Blunt Impacts
	for f in ["res://audio/impactWood_heavy_000.ogg", "res://audio/impact_heavy.ogg", "res://audio/impactPlate_heavy_000.ogg"]:
		if FileAccess.file_exists(f):
			var s = AudioStreamOggVorbis.load_from_file(f)
			if s: blunt_streams.append(s)

	# 4. Bank: Visceral Blade Cuts
	if FileAccess.file_exists("res://audio/slashcut.wav"):
		var s = AudioStreamWAV.load_from_file("res://audio/slashcut.wav")
		if s: blade_streams.append(s)
	if FileAccess.file_exists("res://audio/knife-stab.wav"):
		var s = AudioStreamWAV.load_from_file("res://audio/knife-stab.wav")
		if s: blade_streams.append(s)

func _play_stream(stream: AudioStream, volume_db: float = -6.0, pitch_scale: float = 1.0) -> void:
	if not stream or _players.is_empty():
		return
	var player: AudioStreamPlayer = _players[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func play_miko_swing(combo_idx: int = 0, is_slam: bool = false) -> void:
	# Toned down version of the droid laser sword sound for Miko (smooth sci-fi energy whoosh, no whip crack)
	if not laser_swing_wav:
		return
	var pitch := 1.0
	var vol := -8.5
	if is_slam:
		pitch = randf_range(0.78, 0.84)
		vol = -6.5
	elif combo_idx == 2:
		pitch = randf_range(0.88, 0.94)
		vol = -7.5
	elif combo_idx == 1:
		pitch = randf_range(0.97, 1.04)
		vol = -8.0
	else:
		pitch = randf_range(1.06, 1.14)
		vol = -8.5
	_play_stream(laser_swing_wav, vol, pitch)

func play_contact(impact_strength: float = 0.5) -> void:
	# Select stream based on chosen active profile
	var pool: Array[AudioStream] = []
	match current_profile:
		ImpactProfile.SOLID_PUNCH:
			pool = punch_streams
		ImpactProfile.SOLID_BLUNT:
			pool = blunt_streams
		ImpactProfile.VISCERAL_BLADE:
			pool = blade_streams
		ImpactProfile.BALANCED_HYBRID:
			pool = punch_streams + blade_streams

	if pool.is_empty():
		pool = punch_streams if not punch_streams.is_empty() else blunt_streams
	if pool.is_empty():
		return

	var stream = pool[randi() % pool.size()]
	var vol := lerpf(-5.0, -1.5, clampf(impact_strength, 0.0, 1.0))
	var pitch := randf_range(0.96, 1.06)
	_play_stream(stream, vol, pitch)

func play_parry() -> void:
	if laser_clash_wav:
		_play_stream(laser_clash_wav, -3.5, randf_range(0.97, 1.03))
	elif force_field_ogg:
		_play_stream(force_field_ogg, -4.0, randf_range(0.95, 1.05))

func play_droid_sword() -> void:
	# Full-energy droid laser sword swipe
	if laser_swing_wav:
		_play_stream(laser_swing_wav, -4.5, randf_range(0.94, 1.06))
