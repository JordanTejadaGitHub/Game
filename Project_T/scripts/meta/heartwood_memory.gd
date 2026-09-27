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
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"fullscreen": false,
			"whispers": true,  # Heartwood whispers (first-run hints)
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
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(settings.master_volume, 0.0001)))
	AudioServer.set_bus_mute(master, settings.master_volume <= 0.0)
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

# Copies keys from `source` into `target`, recursing into dictionaries, so new defaults survive
# loading an older save.
static func _merge(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key) and typeof(target[key]) == TYPE_DICTIONARY and typeof(source[key]) == TYPE_DICTIONARY:
			_merge(target[key], source[key])
		else:
			target[key] = source[key]
