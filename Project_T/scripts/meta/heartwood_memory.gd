extends RefCounted
class_name HeartwoodMemory

# The player's lasting save (meta_design.md "Data"): banked Seeds, run counts, and settings.
# One JSON file in user:// (works with Steam Auto-Cloud). The demo writes the same file, so the full
# game finds the demo's Seeds waiting. Versioned so later builds can migrate it.
#
# Static helpers only: every caller loads, changes and saves. The file is tiny.

const PATH := "user://heartwood.json"
const VERSION := 2  # 2: Grove ids match grove_layout.json (MIGRATED_IDS), perk loadout

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
		"loadout": [],  # Perk ids carried into the next run (Memory Grove loadout)
		"memories_seen": 0,  # Memories already opened in the Grove (dream-fruit stay open)
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
			"vsync": true,
			"window_size": 0,  # Index into SettingsPanel.WINDOW_SIZES (windowed mode)
			"high_contrast_route": false,  # RouteLine: bright, thick route previews
			"confirm_sell": true,  # Warden panel: confirm "Sell N" while nightmares walk
			"pause_on_combo": true,  # A first-ever combo discovery pauses the game (off: a 5 s slide-in card)
			"resist_pips": false,  # Resist / weak pips on nightmares always (off: only while placing or with Wardens selected)
			"kinship_effects": 0,  # Kinship visuals: 0 full, 1 subtle, 2 off (rules always apply; read by Tower Code)
			"health_bars": 0,  # Nightmare health bars: 0 once hit, 1 always (read by Enemy via Fx.setting)
			"blight_outline": false,  # Accessibility: outline Deeply Blighted nightmares
			"softer_nightmares": false,  # Accessibility (audio_direction.md): quieter nightmare shrieks and whispers
			"demo_mode": -1,  # Developer (debug builds): -1 = project setting game/demo, 0 = full game, 1 = demo
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
	_migrate(data)
	return data

# Grove ids before version 2 -> the grove_layout.json ids.
const MIGRATED_IDS := {
	"pebbling_line": "pebbling", "rootling_line": "rootling", "bellflower_line": "bellflower",
	"acorn_line": "acorn", "nestling_family": "nestling", "whirligig_family": "whirligig",
	"sporeling_finals": "sporeling_final", "firefly_jar_finals": "firefly_jar_final",
	"dewdrop_finals": "dewdrop_final", "pebbling_finals": "pebbling_final",
	"rootling_finals": "rootling_final", "bellflower_finals": "bellflower_final",
	"acorn_finals": "acorn_final", "nestling_finals": "nestling_final",
	"whirligig_finals": "whirligig_final", "fairy_ring": "sporeling_hidden",
	"frostfern": "dewdrop_hidden", "cairn": "pebbling_hidden", "rootlight": "rootling_hidden",
	"echo_hollow": "bellflower_hidden", "graftling": "acorn_hidden",
	"hummingbird_bower": "nestling_hidden", "samara": "whirligig_hidden",
}

static func _migrate(data: Dictionary) -> void:
	if int(data.get("version", VERSION)) >= 2:
		return
	var unlocks := {}
	for id in data.unlocks:
		unlocks[MIGRATED_IDS.get(id, id)] = data.unlocks[id]
	data.unlocks = unlocks
	data.version = VERSION

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

static var _grove_by_id := {}

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

# The Grove node with this id, or null.
static func get_unlock(id: String) -> UnlockData:
	if _grove_by_id.is_empty():
		for unlock in load_grove():
			_grove_by_id[unlock.id] = unlock
	return _grove_by_id.get(id)

# Levels bought (the profile's raw count; start and milestone growth aren't in it).
static func unlock_level(data: Dictionary, id: String) -> int:
	return int(data.unlocks.get(id, 0))

# Levels a node has grown: bought levels, or all of them for a start node or a reached milestone.
static func node_level(data: Dictionary, unlock: UnlockData) -> int:
	if unlock.start or (unlock.milestone != "" and data.milestones.has(unlock.milestone)):
		return maxi(unlock.get_levels(), 1)
	return unlock_level(data, unlock.id)

static func is_grown(data: Dictionary, unlock: UnlockData) -> bool:
	return node_level(data, unlock) >= maxi(unlock.get_levels(), 1)

# `requirement` is "id" (owned at all) or "id:level".
static func _meets(data: Dictionary, requirement: String) -> bool:
	var parts := requirement.split(":")
	var unlock := get_unlock(parts[0])
	var level := node_level(data, unlock) if unlock != null else unlock_level(data, parts[0])
	return level >= (int(parts[1]) if parts.size() > 1 else 1)

static func requirements_met(data: Dictionary, unlock: UnlockData) -> bool:
	for requirement in unlock.requires_all:
		if not _meets(data, requirement):
			return false
	if not unlock.requires_any.is_empty():
		var owned := unlock.requires_any.filter(func(id: String) -> bool: return _meets(data, id)).size()
		if owned < unlock.requires_any_count:
			return false
	return true

# Why `unlock` can't be bought now ("" = it can).
static func buy_problem(data: Dictionary, unlock: UnlockData) -> String:
	if is_grown(data, unlock):
		return "Grown"
	if unlock.is_free():
		return "Grows by itself"
	if not requirements_met(data, unlock):
		return "Needs another unlock first"
	if data.seeds < unlock.get_cost(unlock_level(data, unlock.id)):
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

# A milestone was just reached (MetaRun, at run end): nodes it grows are now owned, and any Seeds
# already spent on them come back (meta_design.md: free unlocks refund a duplicate purchase).
static func grow_milestone_nodes(data: Dictionary, milestone: String) -> void:
	for unlock in load_grove():
		if unlock.milestone == milestone:
			data.seeds += unlock.get_spent(unlock_level(data, unlock.id))

# The share of the tree grown (0..1), for the canopy stage. Start nodes don't count.
static func grown_share(data: Dictionary) -> float:
	var total := 0
	var grown := 0
	for unlock in load_grove():
		if unlock.start:
			continue
		total += 1
		if node_level(data, unlock) > 0:
			grown += 1
	return float(grown) / maxf(total, 1.0)

# --- Perk loadout ("Carry into the dream") ---

const BASE_LOADOUT_SLOTS := 1

static func loadout_slots(data: Dictionary) -> int:
	var slots := BASE_LOADOUT_SLOTS
	for unlock in load_grove():
		if unlock.loadout_slots > 0:
			slots += unlock.loadout_slots * node_level(data, unlock)
	return slots

# The perk ids carried: owned perks from the saved loadout, at most one per slot.
static func get_loadout(data: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for id in data.get("loadout", []):
		var unlock := get_unlock(str(id))
		if unlock != null and unlock.is_perk() and node_level(data, unlock) > 0 and not result.has(unlock.id):
			result.append(unlock.id)
	return result.slice(0, loadout_slots(data))

static func save_loadout(ids: Array[String]) -> void:
	var data := load_data()
	data.loadout = ids.slice(0, loadout_slots(data))
	save_data(data)

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
	# Softer nightmares: the Sound autoload tones them down (it also reads the setting on start).
	var sound_tree := Engine.get_main_loop() as SceneTree
	var sound := sound_tree.root.get_node_or_null("Sound") if sound_tree and sound_tree.root else null
	if sound and sound.has_method("set_softer_nightmares"):
		sound.set_softer_nightmares(bool(settings.get("softer_nightmares", false)))
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.content_scale_factor = clampf(float(settings.get("ui_scale", 1.0)), 0.5, 2.0)
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		var changed := DisplayServer.window_get_mode() != mode
		if changed:
			DisplayServer.window_set_mode(mode)
		# V-sync always; the window size at startup and when leaving fullscreen.
		SettingsPanel.apply_display(settings, changed)
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
