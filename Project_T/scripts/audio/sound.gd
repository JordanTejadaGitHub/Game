extends Node

# The game's audio (audio_direction.md), autoloaded as "Sound": buses, voice-limited sound effects,
# adaptive music in synced stems, and the ambience bed. Gameplay scripts don't call this; SoundHooks
# (in main.tscn) listens to their signals. Every button in the game clicks on its own.
# Placeholder sounds come from tools/sound_generator.gd (assets/audio/). A sound id is the file name
# without its variant suffix: attack_stone_01..03.wav are the variants of &"attack_stone".

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const BUSES := [&"Music", &"SFX", &"Ambience", &"UI"]
const LAYERS := [&"base", &"dread1", &"dread2", &"heartbeat", &"boss", &"boss_stag", &"boss_stag_warm", &"boss_hag",
	&"boss_hag_warm", &"boss_moth", &"boss_moth_warm", &"boss_oak", &"boss_oak_warm"]
const TITLE_SCENE := "res://scenes/title.tscn"

const MAX_VOICES := 4  # Per sound id at once; a 40-Warden maze doesn't become noise
const MIN_INTERVAL_MS := 45  # Between two starts of the same id (real time, so 3× speed throttles)
const CROWD_DB := -2.5  # Each voice already playing makes the next one this much quieter
const PITCH_JITTER := 0.05
const MAX_DISTANCE := 2200.0  # Px: positional sounds fade out this far from the screen centre
const LAYER_FADE := 0.8  # Seconds for a music layer to fade fully in or out
const MUFFLED_HZ := 900.0  # Music lowpass on choice screens ("time has stopped")
# Mix (audio_direction.md "Mix rules", after the first listen): music sits ~10 dB under the sound
# effects and the ambience ~10 dB under the music. Dread layers are quieter than the warm base, and
# the stems are trimmed so adding layers never makes the music louder overall.
const MUSIC_DB := -6.0
const DRIFT_MUSIC_DB := -3.0  # During drifts, relative to rests: combat owns the space
const AMBIENCE_DB := -16.0
const LAYER_GAIN := {&"base": 1.0, &"dread1": 0.55, &"dread2": 0.45, &"heartbeat": 0.6, &"boss": 0.7,
	&"boss_stag": 0.7, &"boss_hag": 0.7, &"boss_moth": 0.65, &"boss_oak": 0.7, &"boss_stag_warm": 0.6, &"boss_hag_warm": 0.6,
	&"boss_moth_warm": 0.6, &"boss_oak_warm": 0.6}
# Softer nightmares (accessibility setting): nightmare shrieks and whispers play this much quieter,
# muffled, and the whispering dread layer is halved.
const SOFTER_DB := -8.0
const SOFTER_IDS := [&"dispel", &"dispel_boss", &"hound_howl", &"hag_rise", &"hag_sink", &"drift_start"]
const SOFTER_DREAD2 := 0.5
const LEVEL_SMOOTHING := 1.5  # Phase and ambience changes ease in over a second or two
const DUCK_ATTACK := 150.0  # dB per second
const DUCK_RELEASE := 16.0
const SOFTEN_SHELF_HZ := 6000.0
const SOFTEN_SHELF_DB := -6.0
const SOFTEN_CEILING_DB := -1.5
const LOOP_DB := -14.0  # Continuous Warden loops sit quietly under the hits
const LOOP_FADE := 0.6  # Seconds to fade a loop fully in or out
# Muffled SFX: resisted hits, and a Graftling copying another Warden "through bark" (Grafted Elder
# less so). Both send into SFX, so the Sounds slider and the softening still apply.
const MUFFLED_BUSES := {&"SFXMuffled": 1000.0, &"SFXBark": 2200.0}
# Dispels landing this close together blend into one softer swell (third listen: no climbing combo,
# a dispel is a nightmare ending, never a reward sound). Each one in a cluster is this much quieter.
const DISPEL_CLUSTER_MS := 700
const ELITE_BREATH_PITCH := 0.85  # Deeply Blighted: a slower, deeper last breath
const FIFTH := 1.4983  # A fifth up: the Deeply Blighted's second rising voice
const DISPEL_CLUSTER_DB := -1.5
const DISPEL_CLUSTER_MAX_DB := -6.0

var _streams := {}  # id -> Array[AudioStream]
var _voices := {}  # id -> Array[Node] (players still playing)
var _last_start := {}  # id -> msec
var _music := {}  # layer -> AudioStreamPlayer
var _music_level := {}  # layer -> current linear volume
var _music_target := {}  # layer -> target linear volume
var _music_set := &""
var _phase_db := 0.0  # Music offset for the phase (0 at rests, DRIFT_MUSIC_DB in drifts), eased
var _phase_target := 0.0
var _ambience: AudioStreamPlayer
var _ambience_db := AMBIENCE_DB
var _ambience_trim := 0.0  # Thinner with many nightmares, fuller at rests (eased)
var _ambience_trim_target := 0.0
var _duck_db := 0.0  # Current dip of music and ambience
var _duck_depth := 0.0
var _duck_until := 0
var _muffle: AudioEffectLowPassFilter
var _muffled := false
var _dispel_cluster := 0  # Dispels in the current cluster before this one
var _dispel_time := -100000
var _scene: Node
# Headless (tests, CI) uses the dummy audio driver, which never mixes, so playbacks it starts are
# never released and show up as leaks at exit. Everything runs the same, it just doesn't start.
var _silent := DisplayServer.get_name() == "headless"
var _loops := {}  # loop id -> {player, level, target}
var _softer := false  # Softer nightmares (settings)

# Set up in _init, not _ready: a test script's _init can add main.tscn (and so SoundHooks) before
# the autoloads are ready.
func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_load_sfx()
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = &"Ambience"
	add_child(_ambience)

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	set_softer_nightmares(bool(HeartwoodMemory.get_settings().get("softer_nightmares", false)))

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene:
		_scene = scene
		if scene != null and scene.scene_file_path == TITLE_SCENE:
			play_music(&"act1", [&"base"])  # The title: the warm theme alone
			stop_ambience()
	delta /= maxf(Engine.time_scale, 0.01)  # Mixing runs in real time, whatever the game speed
	var smooth := 1.0 - exp(-LEVEL_SMOOTHING * delta)
	_phase_db = lerpf(_phase_db, _phase_target, smooth)
	_ambience_trim = lerpf(_ambience_trim, _ambience_trim_target, smooth)
	var duck_target := _duck_depth if Time.get_ticks_msec() < _duck_until else 0.0
	_duck_db = move_toward(_duck_db, duck_target, delta * (DUCK_ATTACK if duck_target > _duck_db else DUCK_RELEASE))

	var energy := 0.0
	for layer in _music:
		var level: float = move_toward(_music_level[layer], _music_target[layer], delta / LAYER_FADE)
		_music_level[layer] = level
		energy += pow(level * _layer_gain(layer), 2.0)
	# More layers playing: all of them come down together, so the total stays about as loud as the base.
	var trim := -10.0 * log(maxf(energy, 1.0)) / log(10.0)
	var music_db := MUSIC_DB + _phase_db + trim - _duck_db
	for layer in _music:
		var gain: float = _music_level[layer] * _layer_gain(layer)
		_music[layer].volume_db = linear_to_db(maxf(gain, 0.0001)) + music_db
	_ambience.volume_db = _ambience_db + _ambience_trim - _duck_db
	_update_loops(delta)
	if _muffle:
		var target := MUFFLED_HZ if _muffled else 20000.0
		_muffle.cutoff_hz = lerpf(_muffle.cutoff_hz, target, 1.0 - exp(-6.0 * delta))


# --- Sound effects --------------------------------------------------------------------------------

# Plays a random variant of `id`. With `at` (a world position) it's positional: panned by where it
# is on screen and quieter far away. Returns the player, or null if missing, throttled or out of
# voices. `jitter` randomises pitch (off for sounds that must stay in key).
func play(id: StringName, at: Variant = null, volume_db := 0.0, pitch := 1.0, jitter := PITCH_JITTER,
		bus := &"SFX") -> Node:
	var variants: Array = _streams.get(id, [])
	if _softer and (SOFTER_IDS.has(id) or String(id).begins_with("sig_")):
		volume_db += SOFTER_DB  # Softer nightmares: quieter and muffled
		if bus == &"SFX":
			bus = &"SFXMuffled"
	if variants.is_empty():
		return null
	var now := Time.get_ticks_msec()
	if now - int(_last_start.get(id, -100000)) < MIN_INTERVAL_MS:
		return null
	# Untyped on purpose: a freed player can't be passed to a typed `Node` parameter. Pruned right away,
	# so the list never grows past the players still sounding.
	var playing: Array = _voices.get(id, []).filter(func(p) -> bool: return is_instance_valid(p))
	_voices[id] = playing
	if playing.size() >= MAX_VOICES:
		return null
	_last_start[id] = now

	var player: Node
	if at is Vector2 and _scene is Node2D:
		var player_2d := AudioStreamPlayer2D.new()
		player_2d.max_distance = MAX_DISTANCE
		player_2d.attenuation = 1.0
		player_2d.position = at
		player = player_2d
		_scene.add_child(player_2d)  # In the world, so it pauses with the game
	else:
		var flat := AudioStreamPlayer.new()
		flat.process_mode = Node.PROCESS_MODE_ALWAYS
		player = flat
		add_child(flat)
	player.stream = variants.pick_random()
	player.bus = bus
	player.volume_db = volume_db + CROWD_DB * playing.size()
	player.pitch_scale = pitch * (1.0 + randf_range(-jitter, jitter))
	player.finished.connect(player.queue_free)
	if _silent:
		player.queue_free()
		return null
	player.play()
	playing.append(player)
	_voices[id] = playing
	return player

func ui(id: StringName, volume_db := 0.0) -> void:
	play(id, null, volume_db, 1.0, 0.03, &"UI")

func has_sound(id: StringName) -> bool:
	return _streams.has(id)

# The dispel: sigh and dissolve, then the release (a warm exhale / low hum in D). Several close
# together blend into one softer swell: each is a little quieter, never higher.
# Releasing a soul (audio_direction.md ecc238a4): the last breath and the unbinding (`dispel`), then one
# warm sung voice rising a fourth onto a D chord note (`dispel_release`, its own lead-in baked in).
# `size_pitch` < 1 for bigger nightmares: a lower, slower breath (the voice stays in key). Deeply
# Blighted (`elite`): slower and deeper still, and two voices a fifth apart. Close together they become
# a soft chorus, each quieter (never stepping up). Normal dispels don't duck; the boss's does.
func play_dispel(at: Vector2, boss := false, size_pitch := 1.0, elite := false) -> void:
	if boss:
		duck(8.0, 1.0)
		play(&"dispel_boss", at, 2.0, 1.0, 0.0)
		return
	var now := Time.get_ticks_msec()
	_dispel_cluster = _dispel_cluster + 1 if now - _dispel_time < DISPEL_CLUSTER_MS else 0
	_dispel_time = now
	var cluster_db := maxf(DISPEL_CLUSTER_DB * _dispel_cluster, DISPEL_CLUSTER_MAX_DB)
	play(&"dispel", at, -3.0 + cluster_db, size_pitch * (ELITE_BREATH_PITCH if elite else 1.0))
	play(&"dispel_release", at, -6.0 + cluster_db, 1.0, 0.0)
	if elite:
		_last_start.erase(&"dispel_release")  # The second voice isn't a repeat: let it through
		play(&"dispel_release", at, -9.0 + cluster_db, FIFTH, 0.0)


# --- Music and ambience ---------------------------------------------------------------------------

# Starts the stems of music set `set_name` (mus_<set>_<layer>.wav) together; `layers` start audible.
# Calling it again with the same set only changes which layers are audible.
func play_music(set_name: StringName, layers: Array = [&"base"]) -> void:
	if set_name != _music_set:
		stop_music()
		_music_set = set_name
		for layer in LAYERS:
			var path := "%smus_%s_%s.wav" % [MUSIC_DIR, set_name, layer]
			if not ResourceLoader.exists(path):
				continue
			var player := AudioStreamPlayer.new()
			player.stream = _looping(load(path))
			player.bus = &"Music"
			player.process_mode = Node.PROCESS_MODE_ALWAYS
			player.volume_db = -80.0
			add_child(player)
			_music[layer] = player
			_music_level[layer] = 0.0
			_music_target[layer] = 0.0
		for player in _music.values():
			if not _silent:
				player.play()  # Same frame: the stems stay in sync
	for layer in _music:
		_music_target[layer] = 1.0 if layers.has(layer) else 0.0

func set_layer(layer: StringName, on: bool) -> void:
	if _music_target.has(layer):
		_music_target[layer] = 1.0 if on else 0.0

func stop_music() -> void:
	for player in _music.values():
		player.queue_free()
	_music.clear()
	_music_level.clear()
	_music_target.clear()
	_music_set = &""

# Lowpasses the music (choice screens, pause).
func set_muffled(on: bool) -> void:
	_muffled = on

# Dips the music and ambience by `depth_db` for `seconds` (dispel ~4 dB / 0.5 s; a lost leaf and boss
# moments ~8 dB / 1 s). Overlapping ducks keep the deeper dip and the later end.
func duck(depth_db: float, seconds: float) -> void:
	var now := Time.get_ticks_msec()
	_duck_depth = depth_db if now >= _duck_until else maxf(_duck_depth, depth_db)
	_duck_until = maxi(_duck_until, now + int(seconds * 1000.0))

# Music a little lower during drifts than at rests (`drifting`), eased.
func set_drifting(drifting: bool) -> void:
	_phase_target = DRIFT_MUSIC_DB if drifting else 0.0

# The ambience's offset from its level: negative thins it out, positive swells it (eased).
func set_ambience_trim(db: float) -> void:
	_ambience_trim_target = db

func play_ambience(set_name: StringName, volume_db := AMBIENCE_DB) -> void:
	var path := "%samb_%s.wav" % [MUSIC_DIR, set_name]
	if not ResourceLoader.exists(path):
		return
	_ambience.stream = _looping(load(path))
	_ambience_db = volume_db
	if not _silent:
		_ambience.play()

# Continuous Warden sounds (beams, fog, blades, auras, lit tiles): one quiet loop per id
# (loop_<warden>.wav), faded toward `level` (0 = silent, 1 = full). Callers set the level every frame
# they're active and 0 when idle; a silent loop stops playing.
func set_loop(id: StringName, level: float) -> void:
	if not _loops.has(id):
		if level <= 0.0 or not _streams.has(id):
			return
		var player := AudioStreamPlayer.new()
		player.stream = _looping(_streams[id][0])
		player.bus = &"SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.volume_db = -80.0
		add_child(player)
		_loops[id] = {"player": player, "level": 0.0, "target": 0.0}
	_loops[id].target = clampf(level, 0.0, 1.0)

func stop_loops() -> void:
	for loop in _loops.values():
		loop.player.queue_free()
	_loops.clear()

func _update_loops(delta: float) -> void:
	for loop in _loops.values():
		loop.level = move_toward(loop.level, loop.target, delta / LOOP_FADE)
		var player: AudioStreamPlayer = loop.player
		player.volume_db = LOOP_DB + linear_to_db(maxf(loop.level, 0.0001))
		if loop.level > 0.0 and not player.playing and not _silent:
			player.play()
		elif loop.level <= 0.0 and player.playing:
			player.stop()

func stop_ambience() -> void:
	_ambience.stop()


# --- Setup ----------------------------------------------------------------------------------------

func _setup_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, &"Master")
	var music := AudioServer.get_bus_index(&"Music")
	if AudioServer.get_bus_effect_count(music) == 0:
		var reverb := AudioEffectReverb.new()
		reverb.room_size = 0.7
		reverb.damping = 0.6
		reverb.wet = 0.2
		AudioServer.add_bus_effect(music, reverb)
		_muffle = AudioEffectLowPassFilter.new()
		_muffle.cutoff_hz = 20000.0
		AudioServer.add_bus_effect(music, _muffle)
	var sfx := AudioServer.get_bus_index(&"SFX")
	if AudioServer.get_bus_effect_count(sfx) == 0:
		var reverb := AudioEffectReverb.new()
		reverb.room_size = 0.45
		reverb.damping = 0.7
		reverb.wet = 0.12
		AudioServer.add_bus_effect(sfx, reverb)
		_add_softening(sfx)
	var ui_bus := AudioServer.get_bus_index(&"UI")
	if AudioServer.get_bus_effect_count(ui_bus) == 0:
		_add_softening(ui_bus)
	for bus_name in MUFFLED_BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, &"SFX")
		var lowpass := AudioEffectLowPassFilter.new()
		lowpass.cutoff_hz = MUFFLED_BUSES[bus_name]
		AudioServer.add_bus_effect(index, lowpass)
	HeartwoodMemory.apply_settings()  # Bus volumes now that the buses exist

# The SFX/UI safety net (audio_direction.md "Mix rules"): a gentle high shelf (−6 dB above ~6 kHz)
# and a soft limiter, so stacked hits can't turn sharp. Not a substitute for rounded sounds.
static func _add_softening(bus: int) -> void:
	var shelf := AudioEffectHighShelfFilter.new()
	shelf.cutoff_hz = SOFTEN_SHELF_HZ
	shelf.gain = db_to_linear(SOFTEN_SHELF_DB)
	AudioServer.add_bus_effect(bus, shelf)
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = SOFTEN_CEILING_DB
	limiter.release = 0.15
	AudioServer.add_bus_effect(bus, limiter)

func _load_sfx() -> void:
	if not DirAccess.dir_exists_absolute(SFX_DIR):
		return
	for file in ResourceLoader.list_directory(SFX_DIR):
		if not file.ends_with(".wav"):
			continue
		var id := file.get_basename()
		var suffix := id.get_slice("_", id.get_slice_count("_") - 1)
		if suffix.is_valid_int() and suffix.length() == 2:
			id = id.substr(0, id.length() - 3)  # attack_stone_02 -> attack_stone
		if not _streams.has(StringName(id)):
			_streams[StringName(id)] = []
		_streams[StringName(id)].append(load(SFX_DIR + file))

static func _looping(stream: AudioStream) -> AudioStream:
	var wav := stream as AudioStreamWAV
	if wav != null and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(round(wav.get_length() * wav.mix_rate))
	return stream

# Every button clicks.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(ui.bind(&"ui_click", -4.0))

# Softer nightmares (Settings; HeartwoodMemory.apply_settings calls this when it changes).
func set_softer_nightmares(on: bool) -> void:
	_softer = on

func _layer_gain(layer: StringName) -> float:
	var gain: float = LAYER_GAIN.get(layer, 1.0)
	return gain * SOFTER_DREAD2 if _softer and layer == &"dread2" else gain
