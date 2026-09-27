extends RefCounted
class_name HeartwoodMemory

# The player's lasting save (meta_design.md "Data"): banked Seeds, run counts, and settings.
# One JSON file in user:// (works with Steam Auto-Cloud). The demo writes the same file, so the full
# game finds the demo's Seeds waiting. Versioned so later builds can migrate it.
#
# Static helpers only: every caller loads, changes and saves. The file is tiny.

const PATH := "user://heartwood.json"
const VERSION := 1

# Where the profile lives (tests point this elsewhere so they never touch the player's Seeds).
static var file_path := PATH

static func defaults() -> Dictionary:
	return {
		"version": VERSION,
		"seeds": 0,  # Banked, spendable in the full game's Memory Grove
		"seeds_earned_total": 0,
		"runs_played": 0,
		"runs_won": 0,
		"best_drift": 0,
		"whispers_seen": [],  # Heartwood whisper ids already shown (onboarding)
		"nightmares_seen": [],  # Nightmare kinds (resource file names) met in any run ("New" tag)
		"reactions_seen": [],  # Reaction ids discovered in any run (discovery card, Codex)
		# Meta (meta_design.md): Grove unlocks {id: level}, milestones reached {id: true}, lifetime
		# counters, the highest Blight Level won (-1 = none), cosmetics, and one-time messages.
		"unlocks": {},
		"milestones": {},
		"counters": {"shades_dispelled": 0, "tended_total": 0},
		"highest_blight_won": -1,
		"cosmetics": [],
		"grove_welcome_shown": false,
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.55,  # audio_direction.md: music sits well under the sound effects
			"sfx_volume": 1.0,
			"fullscreen": false,
			"whispers": true,  # Heartwood whispers (first-run hints)
			"ui_scale": 1.0,
			"auto_drift": true,  # Auto-drift toggle's default at run start
			"reduced_motion": false,  # No camera glide, shakes or hops in the UI
			"damage_numbers": 1,  # 0 off, 1 big hits, 2 all (read by the combat feedback)
			"reduce_flashes": false,  # Reactions: softer, shorter flashes (accessibility)
			"hitstop": true,  # Reactions: a tiny freeze on big hits
			"keybinds": {},  # {action: [physical keycodes]}; empty = project defaults
		},
	}

static func load_data() -> Dictionary:
	var data := defaults()
	if not FileAccess.file_exists(file_path):
		return data
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Heartwood save unreadable; starting fresh")
		return data
	_merge(data, parsed)
	return data

static func save_data(data: Dictionary) -> void:
	data["version"] = VERSION
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s: %s" % [file_path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data, "\t"))

# Records a finished run and banks its Seeds. Returns the new banked total.
static func record_run(seeds: int, won: bool, drift_reached: int) -> int:
	var data := load_data()
	data.seeds += seeds
	data.seeds_earned_total += seeds
	data.runs_played += 1
	if won:
		data.runs_won += 1
	data.best_drift = maxi(data.best_drift, drift_reached)
	save_data(data)
	return data.seeds

static func is_first_run() -> bool:
	return load_data().runs_played == 0


# --- Meta: the Memory Grove, milestones, Memories, Blight Levels ------------------------------

const GROVE_DIR := "res://resource/meta/grove/"
const UNLOCKS_PER_MEMORY := 3
# The 10 Memories (meta_design.md "The Hollow's story"), read in order.
const MEMORIES: Array[String] = [
	"Before the Heartwood, there were two trees, and both of them dreamed.",
	"The Heartwood and the Hollow shared their roots, and one dream grew between them: the forest.",
	"A long drought came. The Heartwood's roots went deep; the Hollow's couldn't reach.",
	"The forest's creatures followed the Heartwood's shade. The Hollow was left alone, still dreaming.",
	"The Hollow tried to keep the last creatures inside its dream, and closed it around them. The dream broke.",
	"Its leaves fell, one by one, and nobody came.",
	"It dreamed alone in the dark for so long that its dreams turned: the first nightmares.",
	"The creatures once carved waystones to mark the path between the two trees.",
	"The Heartwood remembers it promised to come back.",
	"The path to the Hollow is still there, under the nightmares.",
]
# Milestones that reveal a Memory (the rest reward cards, Wardens or cosmetics).
const MEMORY_MILESTONES: Array[String] = ["first_boss", "first_win", "tend_100", "blight_5"]

static func load_grove() -> Array[UnlockData]:
	var result: Array[UnlockData] = []
	for file in ResourceLoader.list_directory(GROVE_DIR):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var unlock := load(GROVE_DIR + file) as UnlockData
			if unlock != null:
				result.append(unlock)
	result.sort_custom(func(a: UnlockData, b: UnlockData) -> bool:
		return a.root < b.root or (a.root == b.root and a.order < b.order))
	return result

static func unlock_level(data: Dictionary, id: String) -> int:
	return int(data.unlocks.get(id, 0))

# Why `unlock` can't be bought now ("" = it can).
static func buy_problem(data: Dictionary, unlock: UnlockData) -> String:
	var level := unlock_level(data, unlock.id)
	if level >= unlock.get_levels():
		return "Grown"
	for id in unlock.requires_all:
		if unlock_level(data, id) == 0:
			return "Needs another unlock first"
	if not unlock.requires_any.is_empty():
		var owned := unlock.requires_any.filter(func(id: String) -> bool: return unlock_level(data, id) > 0).size()
		if owned < unlock.requires_any_count:
			return "Needs another unlock first"
	if data.seeds < unlock.get_cost(level):
		return "Not enough Seeds"
	return ""

# Buys the next level of `unlock`. Returns false (nothing changes) if it can't.
static func buy(unlock: UnlockData) -> bool:
	var data := load_data()
	if buy_problem(data, unlock) != "":
		return false
	data.seeds -= unlock.get_cost(unlock_level(data, unlock.id))
	data.unlocks[unlock.id] = unlock_level(data, unlock.id) + 1
	save_data(data)
	return true

static func total_unlock_levels(data: Dictionary) -> int:
	var total := 0
	for id in data.unlocks:
		total += int(data.unlocks[id])
	return total

# How many Memories are revealed: the first after your first run, one per 3 Grove unlocks, and one
# per Memory milestone.
static func memories_unlocked(data: Dictionary) -> int:
	if data.runs_played == 0:
		return 0
	var count := 1 + total_unlock_levels(data) / UNLOCKS_PER_MEMORY
	for id in MEMORY_MILESTONES:
		if data.milestones.has(id):
			count += 1
	return mini(count, MEMORIES.size())

# Blight Levels open after the first win; you can pick up to one above your best.
static func max_blight_level(data: Dictionary) -> int:
	if data.runs_won == 0:
		return 0
	return mini(int(data.highest_blight_won) + 1, 10)

static func get_settings() -> Dictionary:
	return load_data().settings

static func save_settings(settings: Dictionary) -> void:
	var data := load_data()
	data.settings = settings
	save_data(data)

# Applies settings to the engine: volume, window mode and key rebinds.
static func apply_settings(settings: Dictionary = {}) -> void:
	if settings.is_empty():
		settings = get_settings()
	# Buses are made by the Sound autoload; Ambience follows the music slider, UI the sounds slider.
	_set_bus_volume("Master", settings.master_volume)
	_set_bus_volume("Music", settings.music_volume)
	_set_bus_volume("Ambience", settings.music_volume)
	_set_bus_volume("SFX", settings.sfx_volume)
	_set_bus_volume("UI", settings.sfx_volume)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.content_scale_factor = clampf(float(settings.get("ui_scale", 1.0)), 0.5, 2.0)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED)
	for action in settings.keybinds:
		if not InputMap.has_action(action):
			continue
		# Replace this action's keys; mouse buttons from the project defaults stay.
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		for keycode in settings.keybinds[action]:
			var key := InputEventKey.new()
			key.physical_keycode = int(keycode)
			InputMap.action_add_event(action, key)

static func _set_bus_volume(bus_name: String, volume: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus == -1:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus, volume <= 0.0)

# Copies keys from `source` into `target`, recursing into dictionaries, so new defaults survive
# loading an older save.
static func _merge(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key) and typeof(target[key]) == TYPE_DICTIONARY and typeof(source[key]) == TYPE_DICTIONARY:
			_merge(target[key], source[key])
		else:
			target[key] = source[key]
