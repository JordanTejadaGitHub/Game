extends RefCounted
class_name HeartwoodMemory

# The player's lasting save (meta_design.md "Data"): banked Seeds, run counts, and settings.
# One JSON file in user:// (works with Steam Auto-Cloud). The demo writes the same file, so the full
# game finds the demo's Seeds waiting. Versioned so later builds can migrate it.
#
# Static helpers only: every caller loads, changes and saves. The file is tiny.

const PATH := "user://heartwood.json"
const VERSION := 9  # 2: Grove ids match grove_layout.json (MIGRATED_IDS), perk loadout; 3: REFUNDED_V3; 4: REFUNDED_V4; 5: REFUNDED_V5; 6: REFUNDED_V6; 7: REFUNDED_V7; 8–9: nothing (free lean-pool grants dropped: the game isn't out, no players to protect)

# Where the profile lives (tests point this elsewhere so they never touch the player's Seeds).
static var file_path := PATH
# Dev Grove (DevGrove): while set, the profile is a dev one but settings stay in this real file.
static var real_settings_path := ""
# Parsed files, so the many callers don't re-read and re-parse the JSON each time (Tower Code's perf
# pass: settings reads sat on the combat path). {path: [stamp, migrated dict]}; stamp = modified time +
# length, so a file written or deleted behind our back re-reads. Callers always get a deep copy (they
# edit and save it). save_data drops the entry it wrote; forget() drops them all (tests writing directly).
static var _cache := {}

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
			"dps_tags": 0,  # Warden DPS tags: 0 rests only (and paused / build mode), 1 always, 2 off
			"damage_numbers": 0,  # 0 off (default: DPS tags and the drift meter say more), 1 big hits, 2 all
			"reduce_flashes": false,  # Reactions: softer, shorter flashes (accessibility)
			"hitstop": true,  # Reactions: a tiny freeze on big hits
			"vsync": true,
			"window_size": 0,  # Index into SettingsPanel.WINDOW_SIZES (windowed mode)
			"high_contrast_route": false,  # RouteLine: bright, thick route previews
			"confirm_sell": true,  # Warden panel: confirm "Sell N" while nightmares walk
			"pause_on_combo": true,  # A first-ever combo discovery pauses the game (off: a 5 s slide-in card)
			"omens": "ask",  # Omens at rests: "ask" or "never" (always Clear Skies; OmenDirector.MODE_SETTING)
			"resist_pips": false,  # Resist / weak pips on nightmares always (off: only while placing or with Wardens selected)
			"kinship_effects": 0,  # Kinship visuals: 0 full, 1 subtle, 2 off (rules always apply; read by Tower Code)
			"health_bars": 0,  # Nightmare health bars: 0 once hit, 1 always (read by Enemy via Fx.setting)
			"blight_outline": false,  # Accessibility: outline Deeply Blighted nightmares
			"softer_nightmares": false,  # Accessibility (audio_direction.md): quieter nightmare shrieks and whispers
			"demo_mode": -1,  # Developer (debug builds): -1 = project setting game/demo, 0 = full game, 1 = demo
			"keybinds": {},  # {action: [physical keycodes]}; empty = project defaults
		},
	}

# Account knowledge (screens_ui.md, 2026-09-30: "account knowledge always lives on the real profile"):
# what the player has met, discovered and seen. With Dev Grove on these are read from and written to
# the REAL profile (like the settings); only the Grove unlocks, perks and loadout come from the dev one.
const ACCOUNT_KEYS := ["nightmares_seen", "intros_seen", "nightmare_dispels", "boss_records", "combos_seen",
	"combos_seen_dev", "reactions_seen", "chains_seen", "chain_best", "codex_covered", "dreams_seen", "dreams_seen_dev", "dreams_taken",
	"dreams_won", "dreams_viewed", "nightmares_viewed", "whispers_seen", "callouts_seen"]

static func load_data() -> Dictionary:
	var data := _load_file()
	if real_settings_path != "" and real_settings_path != file_path:
		data.settings = _real_settings()  # Dev Grove: settings live in the real profile
		var real := _shared(real_settings_path)
		for key in ACCOUNT_KEYS:  # …and so does account knowledge
			if real.has(key):
				data[key] = real[key].duplicate(true) if real[key] is Array or real[key] is Dictionary else real[key]
			else:
				data.erase(key)
	return data

static func _load_file() -> Dictionary:
	return _shared(file_path).duplicate(true)

# The cached, parsed profile at `path`: shared, so never edit it (callers get copies).
static func _shared(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_cache.erase(path)
		return defaults()
	var stamp := "%d:%d" % [FileAccess.get_modified_time(path), FileAccess.get_size(path)]
	var hit: Array = _cache.get(path, [])
	if not hit.is_empty() and hit[0] == stamp:
		return hit[1]
	var data := defaults()
	var parsed = _parse_file(path)
	if typeof(parsed) != TYPE_DICTIONARY:  # Caught mid-write by another process? Read once more
		parsed = _parse_file(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		# Never fall back to a fresh profile while a good copy exists (a save would then wipe the player's
		# Grove): the last parse, else the backup save_data keeps. Not cached, so the next read tries again.
		if not hit.is_empty():
			push_warning("Heartwood save unreadable; using the last good copy")
			return hit[1]
		var backup = _parse_file(path + ".bak") if FileAccess.file_exists(path + ".bak") else null
		DirAccess.copy_absolute(path, path + ".unreadable")  # Kept for a look, whatever happens next
		if typeof(backup) != TYPE_DICTIONARY:
			push_warning("Heartwood save unreadable; starting fresh (the file is kept as .unreadable)")
			return data
		push_warning("Heartwood save unreadable; using its backup")
		parsed = backup
	_merge(data, parsed)
	_migrate(data)
	_cache[path] = [stamp, data]
	return data

# --- Reset to a new profile (demo_scope.md, Settings → Developer) ---
# The real profile, never a Dev Grove preset (those are rebuilt from presets anyway).
const BACKUPS_KEPT := 5

static func _real_path() -> String:
	return real_settings_path if real_settings_path != "" else file_path

# "<dir>/<name>.backup-" for the real profile: backups sit next to it and follow file_path (tests use temp files).
static func _backup_prefix() -> String:
	var path := _real_path()
	return path.get_base_dir().path_join(path.get_file().get_basename() + ".backup-")

# Copies the real profile to "<name>.backup-YYYYMMDD-HHMMSS.json" beside it and keeps the newest 5.
# Returns the backup's path, or "" when there's no profile yet.
static func backup_profile() -> String:
	var path := _real_path()
	if not FileAccess.file_exists(path):
		return ""
	var t := Time.get_datetime_dict_from_system()
	var stamp := "%04d%02d%02d-%02d%02d%02d" % [t.year, t.month, t.day, t.hour, t.minute, t.second]
	var backup := "%s%s.json" % [_backup_prefix(), stamp]
	var n := 1
	while FileAccess.file_exists(backup):  # Two in one second: keep both
		n += 1
		backup = "%s%s-%d.json" % [_backup_prefix(), stamp, n]
	if DirAccess.copy_absolute(path, backup) != OK:
		push_error("Could not back up %s" % path)
		return ""
	var backups := _backups()
	while backups.size() > BACKUPS_KEPT:
		DirAccess.remove_absolute(backups.pop_front())
	return backup

# Every backup of the real profile, oldest first (the timestamp names sort by time).
static func _backups() -> Array[String]:
	var dir := _real_path().get_base_dir()
	var name := _backup_prefix().get_file()
	var result: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.begins_with(name) and file.ends_with(".json"):
			result.append(dir.path_join(file))
	result.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	return result

static func latest_backup() -> String:
	var backups := _backups()
	return backups.back() if not backups.is_empty() else ""

# A brand-new profile (backed up first): Grove, Seeds, counts, milestones, Blight, account knowledge, whispers,
# loadout and the rest all go; only the settings stay when `keep_settings`.
static func reset_profile(keep_settings := true) -> void:
	var path := _real_path()
	backup_profile()
	var data := defaults()
	if keep_settings and FileAccess.file_exists(path):
		data.settings = _shared(path).settings.duplicate(true)
	_write_atomic(path, JSON.stringify(data, "\t"))
	forget()

# Puts a backup back over the real profile. False when it's missing or unreadable.
static func restore_backup(path: String) -> bool:
	if path == "" or not FileAccess.file_exists(path) or typeof(_parse_file(path)) != TYPE_DICTIONARY:
		return false
	_write_atomic(_real_path(), FileAccess.get_file_as_string(path))
	forget()
	return true

# The JSON in the file at `path`, or null when it doesn't parse (quietly: the callers handle a torn file).
static func _parse_file(path: String) -> Variant:
	var json := JSON.new()
	return json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null

# Drops every cached profile (a test or tool that writes the file without save_data).
static func forget() -> void:
	_cache.clear()

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

# Version 3 (discovery unlocks, dream_design.md "Grove overlap"): Seeds back for Grove nodes that were
# removed (their cards come from discovery now), and for a node whose price dropped. {id: Seeds}
const REFUNDED_V3 := {
	"reactions": 70, "woven_dreams_1": 90, "woven_dreams_2": 90, "kin_lore": 50, "deep_bonds": 70,
}
const PRICE_DROPS_V3 := {"bittersweet_dreams": 8}  # Kept, 8 Seeds back (60 -> 52)
# Version 4 (meta_design.md "Section 1: Perks", 2026-09-29): slots 1–3 are open from the start, so the
# slot_2 / slot_3 nodes are gone and their Seeds come back.
const REFUNDED_V4 := {"slot_2": 40, "slot_3": 80}
# Version 5 (dream_audit.md "Pool trim", 2026-09-30): Reckless and Wild Planting granted only cut cards
# and were removed; Full Moon now grows from Sharpened, Rootbound from Seedbed.
const REFUNDED_V5 := {"reckless": 40, "wild_planting": 50}
# Version 6 (meta_design.md "Final-forms nodes removed", 2026-09-30): owning a family gives its finals in
# runs (2 Dreamlight each), so the nine final-forms nodes are gone and their Seeds come back.
const REFUNDED_V6 := {
	"sporeling_final": 50, "firefly_jar_final": 50, "dewdrop_final": 50, "pebbling_final": 50,
	"rootling_final": 50, "bellflower_final": 50, "acorn_final": 50, "nestling_final": 60, "whirligig_final": 60,
}
# Version 7 (meta_design.md "Section 3: Cards", 2026-09-30): no combo cards in the Grove. These nodes are gone
# (their cards come from discovery or the starting families now) and their Seeds come back.
const REFUNDED_V7 := {"storm_lore": 40, "guiding_lights": 60, "spore_lore": 40, "dawnbreak": 120, "grove_of_kin": 120}

static func _migrate(data: Dictionary) -> void:
	var version := int(data.get("version", VERSION))
	if version < 2:
		var unlocks := {}
		for id in data.unlocks:
			unlocks[MIGRATED_IDS.get(id, id)] = data.unlocks[id]
		data.unlocks = unlocks
	if version < 3:
		for id in REFUNDED_V3:
			if int(data.unlocks.get(id, 0)) > 0:
				data.seeds = int(data.seeds) + REFUNDED_V3[id]
				data.unlocks.erase(id)
		for id in PRICE_DROPS_V3:
			if int(data.unlocks.get(id, 0)) > 0:
				data.seeds = int(data.seeds) + PRICE_DROPS_V3[id]
	if version < 4:
		for id in REFUNDED_V4:
			if int(data.unlocks.get(id, 0)) > 0:
				data.seeds = int(data.seeds) + REFUNDED_V4[id]
				data.unlocks.erase(id)
	if version < 5:
		for id in REFUNDED_V5:
			if int(data.unlocks.get(id, 0)) > 0:
				data.seeds = int(data.seeds) + REFUNDED_V5[id]
				data.unlocks.erase(id)
	if version < 6:
		for id in REFUNDED_V6:
			if int(data.unlocks.get(id, 0)) > 0:
				data.seeds = int(data.seeds) + REFUNDED_V6[id]
				data.unlocks.erase(id)
	if version < 7:
		for id in REFUNDED_V7:
			if int(data.unlocks.get(id, 0)) > 0:
				data.seeds = int(data.seeds) + REFUNDED_V7[id]
				data.unlocks.erase(id)
	data.version = VERSION

static func save_data(data: Dictionary) -> void:
	data["version"] = VERSION
	if real_settings_path != "" and real_settings_path != file_path:
		_save_account_keys(data)  # Dev Grove: account knowledge goes to the real profile
	_cache.erase(file_path)  # The path actually written (save_settings switches it for Dev Grove)
	_write_atomic(file_path, JSON.stringify(data, "\t"))

# Writes `text` to `path` without ever leaving a half-written file (every Godot process shares user://,
# and a crash mid-write would cost the profile): a per-process temp file, renamed over the real one.
# The previous good version is kept as `path`.bak, the fallback when the file can't be read.
static func _write_atomic(path: String, text: String) -> void:
	var temp := "%s.%d.tmp" % [path, OS.get_process_id()]
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s: %s" % [temp, error_string(FileAccess.get_open_error())])
		return
	file.store_string(text)
	var failed := file.get_error() != OK
	file.close()
	if failed:
		push_error("Could not write %s" % temp)
		DirAccess.remove_absolute(temp)
		return
	if FileAccess.file_exists(path) and typeof(_parse_file(path)) == TYPE_DICTIONARY:
		DirAccess.copy_absolute(path, path + ".bak")
	var error := DirAccess.rename_absolute(temp, path)
	if error != OK:
		push_error("Could not replace %s: %s" % [path, error_string(error)])
		DirAccess.remove_absolute(temp)

# Merged, never replaced: account knowledge only grows, so a fresh dev profile being written (Dev
# Grove presets) can't wipe what the player has seen. Lists gain new entries; dictionaries gain or
# update keys (counts, records) but keep the others.
static func _save_account_keys(data: Dictionary) -> void:
	var real := _shared(real_settings_path).duplicate(true)
	var changed := false
	for key in ACCOUNT_KEYS:
		if not data.has(key):
			continue
		var value = data[key]
		if value is Array:
			var merged: Array = real.get(key, []).duplicate() if real.get(key) is Array else []
			for item in value:
				if not merged.has(item):
					merged.append(item)
					changed = true
			real[key] = merged
		elif value is Dictionary:
			var merged: Dictionary = real.get(key, {}).duplicate(true) if real.get(key) is Dictionary else {}
			for item in value:
				if merged.get(item) != value[item]:
					merged[item] = value[item]
					changed = true
			real[key] = merged
		elif real.get(key) != value:
			real[key] = value
			changed = true
	if not changed:
		return
	var path := file_path
	file_path = real_settings_path
	save_data(real)
	file_path = path

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
const MEMORY_MILESTONES: Array[String] = ["first_boss", "first_win", "tend_100", "blight_5", "all_combos"]

static var _grove_by_id := {}

static func load_grove() -> Array[UnlockData]:
	var result: Array[UnlockData] = []
	for file in ResourceLoader.list_directory(GROVE_DIR):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var unlock := load(GROVE_DIR + file) as UnlockData
			if unlock == null:
				continue
			if unlock.memory_warden != "" and not MetaRun.MEMORY_WARDENS_ENABLED:
				continue  # Memory Wardens are parked: their blooms aren't on the tree (saved data kept)
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

const BASE_LOADOUT_SLOTS := 3  # Slots 1–3 are open from the start; 4 and 5 are Perks nodes
const FULL_BLOOM := "full_bloom"  # Milestone: every Grove node at max level (the secret 6th slot)

static func loadout_slots(data: Dictionary) -> int:
	var slots := BASE_LOADOUT_SLOTS
	for unlock in load_grove():
		if unlock.loadout_slots > 0:
			slots += unlock.loadout_slots * node_level(data, unlock)
	if has_sixth_slot(data):
		slots += 1
	return slots

# The secret 6th slot (and its waystone): "The Heartwood in full bloom", or the developer toggle.
static func has_sixth_slot(data: Dictionary) -> bool:
	return data.milestones.has(FULL_BLOOM) or MetaRun.sixth_slot_dev_active()

# Every Grove node at its max level, the free milestone and Memory Warden blooms included.
static func tree_complete(data: Dictionary) -> bool:
	return load_grove().all(func(u: UnlockData) -> bool: return is_grown(data, u))

# Records "The Heartwood in full bloom" in `data` the first time the tree is complete (the caller
# saves). Returns true when it was just reached.
static func check_full_bloom(data: Dictionary) -> bool:
	if data.milestones.has(FULL_BLOOM) or not tree_complete(data):
		return false
	data.milestones[FULL_BLOOM] = true
	return true

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

static func get_settings() -> Dictionary:  # Only the settings are copied (read often)
	return _shared(real_settings_path if real_settings_path != "" else file_path).settings.duplicate(true)

static func save_settings(settings: Dictionary) -> void:
	var path := file_path
	if real_settings_path != "":
		file_path = real_settings_path  # Dev Grove: settings always go to the real profile
	var data := load_data()
	data.settings = settings
	save_data(data)
	file_path = path

static func _real_settings() -> Dictionary:
	return _shared(real_settings_path).settings.duplicate(true)

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
		# "ui_scale" is a share (50–100%) of the largest scale that fits the window (UiStyle.apply_ui_scale:
		# only the UI scales, never past its 1280×720 layout; the camera keeps the map its size).
		UiStyle.apply_ui_scale(tree.root, float(settings.get("ui_scale", 1.0)))
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
