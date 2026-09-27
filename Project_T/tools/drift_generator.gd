extends SceneTree

# Builds drifts 51–100 (resource/drift/demo/drift_51..100.tres) from the tables in
# documentation/acts_3_4.md. Nightmares that aren't in code yet use a stand-in (an existing kind
# that plays a similar role; bosses: a renamed copy of an act 1–2 boss with the spec's health and
# Dew). Re-run it whenever a new resource/enemy/*.tres lands, then `--import`:
#   godot --headless --path . --script res://tools/drift_generator.gd
# Drifts 1–50 are hand-tuned files and are never touched.

const OUT_DIR := "res://resource/drift/demo/"
const ENEMY_DIR := "res://resource/enemy/"
const MIX_SECONDS := 30.0  # A mixed drift spreads its arrivals over this long…
const MIN_GAP := 0.3  # …but never closer together than this (big act 4 drifts run longer)

# Abbreviation -> [file, stand-in file while the real one doesn't exist].
const KINDS := {
	"SH": ["leaf_bug", ""], "HU": ["bark_beetle", ""], "MO": ["puffcap", ""],
	"PH": ["dandelion_seed", ""], "NH": ["hedgehog", ""], "PR": ["mother_duck", ""],
	"LU": ["dusk_moth", ""], "SW": ["wandering_hare", ""], "WI": ["mother_spider", ""],
	"WW": ["will_o_wisp", "dandelion_seed"], "GC": ["gravecrawler", "bark_beetle"],
	"DO": ["drowned_one", "bark_beetle"], "BW": ["barrow_wight", "bark_beetle"],
	"WA": ["watcher", "puffcap"], "AC": ["ash_crawler", "hedgehog"],
	"SB": ["shellbound", "bark_beetle"], "WS": ["whisper_swarm", "leaf_bug"],
	"DT": ["dream_thief", "hedgehog"], "WE": ["weeper", "puffcap"],
}
# Boss stand-ins: [file, copy of, display name, base health, Dew, flies, speed ×, cleanse line,
# trait text].
const BOSSES := {
	"QUEEN": ["moth_queen", "old_stag", "The Moth Queen", 16000, 80, true, 1.0,
		"The Moth Queen is gone, and the light comes back.", "Flies over the maze toward the Heartwood."],
	"OAK": ["hollow_oak", "great_toad", "The Hollow Oak", 30000, 100, false, 0.6,
		"The Hollow Oak is still. Somewhere beyond the dream, the Hollow remembers.",
		"Walks very slowly along the maze."],
}
# Every non-boss kind but the Shade (drift 96's "6 of every other kind").
const OTHERS := ["HU", "MO", "PH", "NH", "PR", "LU", "WW", "GC", "SW", "DO", "BW", "WA", "AC", "WI",
	"SB", "WS", "DT", "WE"]

var _stand_ins: Array[String] = []

func _initialize() -> void:
	var rows := _rows()
	for number in rows:
		var drift := DriftData.new()
		for group in rows[number]:
			drift.groups.append(group)
		var path := OUT_DIR + "drift_%02d.tres" % number
		var error := ResourceSaver.save(drift, path)
		if error != OK:
			printerr("couldn't save %s (%d)" % [path, error])
	print("drifts 51–100 written; stand-ins for: %s" % (", ".join(_stand_ins) if not _stand_ins.is_empty() else "none"))
	quit()

func _rows() -> Dictionary:
	return {
		51: [_mix([["SH", 30], ["HU", 10], ["NH", 6], ["PR", 2]])],
		52: [_intro("LU", 6, 2.0)],
		53: [_mix([["SH", 30], ["HU", 8], ["LU", 6]])],
		54: [_intro("WW", 3, 2.0), _mix([["LU", 8]], 3.0)],
		55: [_mix([["SH", 20], ["LU", 14], ["WW", 2]])],
		56: [_intro("GC", 4, 3.0)],
		57: [_mix([["SH", 32], ["HU", 8], ["GC", 6]])],
		58: [_intro("SW", 5, 2.0)],
		59: [_mix([["SH", 30], ["NH", 8], ["SW", 6], ["PH", 6]])],
		60: [_mix([["GC", 12], ["HU", 10], ["SH", 10]])],
		61: [_intro("DO", 4, 2.5)],
		62: [_mix([["SH", 32], ["HU", 10], ["DO", 8]])],
		63: [_intro("BW", 2, 5.0)],
		64: [_mix([["SH", 34], ["BW", 3], ["MO", 8], ["LU", 6]])],
		65: [_mix([["DO", 16], ["NH", 8]])],
		66: [_intro("WA", 3, 3.0), _mix([["SH", 10]], 3.0)],
		67: [_mix([["SH", 34], ["HU", 10], ["WA", 4], ["PR", 3]])],
		68: [_intro("AC", 3, 3.0)],
		69: [_mix([["SH", 34], ["AC", 6], ["MO", 8], ["GC", 6]])],
		70: [_mix([["WA", 6], ["SH", 24], ["MO", 8], ["BW", 4]])],
		71: [_mix([["SH", 36], ["HU", 12], ["NH", 8], ["DO", 6], ["WA", 4]])],
		72: [_mix([["SH", 36], ["LU", 10], ["WW", 4], ["GC", 6], ["PR", 3]])],
		73: [_mix([["AC", 10], ["SH", 30]])],
		74: [_mix([["SH", 40], ["HU", 12], ["NH", 10], ["DO", 8], ["BW", 4], ["PH", 6]])],
		75: [_group([["LU", 12]], 1.0, 0.0), _boss("QUEEN"), _group([["NH", 6]], 1.5, 3.0)],
		76: [_mix([["SH", 36], ["HU", 12], ["DO", 8], ["LU", 6], ["PR", 3]])],
		77: [_intro("WI", 3, 3.0)],
		78: [_mix([["SH", 38], ["HU", 12], ["WI", 4], ["AC", 6]])],
		79: [_intro("SB", 3, 4.0)],
		80: [_mix([["WI", 8], ["SH", 12], ["SB", 4]])],
		81: [_intro("WS", 2, 5.0)],
		82: [_mix([["SH", 38], ["WS", 4], ["NH", 10], ["GC", 6]])],
		83: [_intro("DT", 4, 2.0)],
		84: [_mix([["SH", 40], ["DT", 6], ["HU", 10], ["WA", 6]])],
		85: [_mix([["DT", 12], ["SH", 20], ["NH", 6]])],
		86: [_intro("WE", 3, 3.0), _mix([["SH", 12]], 3.0)],
		87: [_mix([["SH", 40], ["WE", 4], ["HU", 12], ["BW", 6]])],
		88: [_mix([["SH", 40], ["WI", 6], ["SB", 6], ["LU", 8], ["WW", 4]])],
		89: [_mix([["SH", 42], ["WS", 6], ["DO", 8], ["AC", 6], ["PR", 4]])],
		90: [_mix([["WE", 6], ["MO", 12], ["HU", 10]])],
		91: [_mix([["SH", 44], ["HU", 14], ["NH", 10], ["WI", 6], ["DT", 6]])],
		92: [_mix([["SH", 44], ["SB", 8], ["WE", 6], ["WA", 6], ["PH", 8]])],
		93: [_mix([["SH", 44], ["WS", 8], ["DO", 10], ["GC", 6], ["SW", 6]])],
		94: [_mix([["SH", 46], ["HU", 14], ["BW", 8], ["LU", 10], ["WW", 4], ["PR", 4]])],
		95: [_mix([["SB", 10], ["WI", 4], ["WE", 6]])],
		96: [_mix([["SH", 30]] + OTHERS.map(func(kind: String) -> Array: return [kind, 6]))],
		97: [_mix([["SH", 48], ["HU", 16], ["NH", 10], ["DT", 8], ["WS", 8]])],
		98: [_group([["SH", 80]], 0.2, 0.0)],
		99: [_mix([["SH", 50], ["MO", 12], ["NH", 12], ["LU", 12], ["DO", 12], ["WI", 6], ["SB", 6],
			["WE", 6], ["AC", 6], ["PR", 4]])],
		100: [_mix([["PR", 3], ["MO", 8], ["WE", 4]]), _boss("OAK")],
	}

# An intro: one kind alone, with its own spacing.
func _intro(kind: String, count: int, spacing: float) -> DriftGroup:
	return _group([[kind, count]], spacing, 0.0)

# Several kinds mixed evenly, spread over MIX_SECONDS (gaps at least MIN_GAP).
func _mix(kinds: Array, delay: float = 0.0) -> DriftGroup:
	var total := 0
	for pair in kinds:
		total += pair[1]
	return _group(kinds, maxf(MIX_SECONDS / total, MIN_GAP) if total > 1 else 1.0, delay)

func _group(kinds: Array, spacing: float, delay: float) -> DriftGroup:
	var group := DriftGroup.new()
	group.spacing = spacing
	group.delay = delay
	for pair in kinds:
		var entry := DriftEntry.new()
		entry.enemy = _enemy(pair[0])
		entry.count = pair[1]
		group.entries.append(entry)
	return group

func _enemy(kind: String) -> EnemyData:
	var files: Array = KINDS[kind]
	if ResourceLoader.exists(ENEMY_DIR + files[0] + ".tres"):
		return load(ENEMY_DIR + files[0] + ".tres")
	if not _stand_ins.has(files[0]):
		_stand_ins.append(files[0])
	return load(ENEMY_DIR + files[1] + ".tres")

# The boss alone, 3 s after the escort ahead of it.
func _boss(key: String) -> DriftGroup:
	var spec: Array = BOSSES[key]
	var group := DriftGroup.new()
	group.spacing = 1.0
	group.delay = 3.0
	var entry := DriftEntry.new()
	if ResourceLoader.exists(ENEMY_DIR + spec[0] + ".tres"):
		entry.enemy = load(ENEMY_DIR + spec[0] + ".tres")
	else:
		# A renamed copy of an act 1–2 boss, saved inside the drift until the real one exists.
		_stand_ins.append(spec[0])
		var data := (load(ENEMY_DIR + spec[1] + ".tres") as EnemyData).duplicate() as EnemyData
		data.display_name = spec[2]
		data.health = spec[3]
		data.dew_reward = spec[4]
		data.leaf_cost = 5
		data.is_boss = true
		data.trait_kind = EnemyData.Trait.FLYING if spec[5] else EnemyData.Trait.NONE
		data.speed *= spec[6]
		data.cleanse_line = spec[7]
		data.trait_text = spec[8]
		entry.enemy = data
	entry.count = 1
	group.entries.append(entry)
	return group
