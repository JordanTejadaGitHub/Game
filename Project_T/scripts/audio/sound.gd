extends Node

# The game's audio (audio_direction.md), autoloaded as "Sound": buses, voice-limited sound effects,
# adaptive music in synced stems, and the ambience bed. Gameplay scripts don't call this; SoundHooks
# (in main.tscn) listens to their signals. Every button in the game clicks on its own.
# Placeholder sounds come from tools/sound_generator.gd (assets/audio/). A sound id is the file name
# without its variant suffix: attack_stone_01..03.wav are the variants of &"attack_stone".

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const BUSES := [&"Music", &"SFX", &"Ambience", &"UI"]
const LAYERS := [&"base", &"dread1", &"dread2", &"heartbeat", &"boss"]
const TITLE_SCENE := "res://scenes/title.tscn"

const MAX_VOICES := 4  # Per sound id at once; a 40-Warden maze doesn't become noise
const MIN_INTERVAL_MS := 45  # Between two starts of the same id (real time, so 3× speed throttles)
const CROWD_DB := -2.5  # Each voice already playing makes the next one this much quieter
const PITCH_JITTER := 0.05
const MAX_DISTANCE := 2200.0  # Px: positional sounds fade out this far from the screen centre
const LAYER_FADE := 0.8  # Seconds for a music layer to fade fully in or out
const MUFFLED_HZ := 900.0  # Music lowpass on choice screens ("time has stopped")
# The dispel chime climbs this scale (D minor pentatonic, semitones) when dispels land close together.
const COMBO_STEPS := [0, 3, 5, 7, 10, 12, 15, 17]
const COMBO_WINDOW_MS := 700

var _streams := {}  # id -> Array[AudioStream]
var _voices := {}  # id -> Array[Node] (players still playing)
var _last_start := {}  # id -> msec
var _music := {}  # layer -> AudioStreamPlayer
var _music_level := {}  # layer -> current linear volume
var _music_target := {}  # layer -> target linear volume
var _music_set := &""
var _ambience: AudioStreamPlayer
var _muffle: AudioEffectLowPassFilter
var _muffled := false
var _combo := 0
var _combo_time := -100000
var _scene: Node
# Headless (tests, CI) uses the dummy audio driver, which never mixes, so playbacks it starts are
# never released and show up as leaks at exit. Everything runs the same, it just doesn't start.
var _silent := DisplayServer.get_name() == "headless"

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

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene:
		_scene = scene
		if scene != null and scene.scene_file_path == TITLE_SCENE:
			play_music(&"act1", [&"base"])  # The title: the warm theme alone
			stop_ambience()
	for layer in _music:
		var level: float = move_toward(_music_level[layer], _music_target[layer], delta / LAYER_FADE)
		_music_level[layer] = level
		_music[layer].volume_db = linear_to_db(maxf(level, 0.0001))
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
	if variants.is_empty():
		return null
	var now := Time.get_ticks_msec()
	if now - int(_last_start.get(id, -100000)) < MIN_INTERVAL_MS:
		return null
	var playing: Array = _voices.get(id, []).filter(func(p: Node) -> bool: return is_instance_valid(p))
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

# The dispel: shriek and crack, then the warm chime. Chimes landing close together climb the scale.
func play_dispel(at: Vector2, boss := false) -> void:
	if boss:
		play(&"dispel_boss", at, 2.0, 1.0, 0.0)
		return
	var now := Time.get_ticks_msec()
	_combo = _combo + 1 if now - _combo_time < COMBO_WINDOW_MS else 0
	_combo_time = now
	play(&"dispel", at, -3.0)
	var step: int = COMBO_STEPS[mini(_combo, COMBO_STEPS.size() - 1)]
	# The chime has its own throttle, so a dozen at once still reads as one rising run.
	play(&"dispel_chime", at, -6.0, pow(2.0, step / 12.0), 0.0)


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

func play_ambience(set_name: StringName, volume_db := -6.0) -> void:
	var path := "%samb_%s.wav" % [MUSIC_DIR, set_name]
	if not ResourceLoader.exists(path):
		return
	_ambience.stream = _looping(load(path))
	_ambience.volume_db = volume_db
	if not _silent:
		_ambience.play()

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
	HeartwoodMemory.apply_settings()  # Bus volumes now that the buses exist

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
