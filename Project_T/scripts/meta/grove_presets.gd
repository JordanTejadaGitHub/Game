extends RefCounted
class_name GrovePresets

# Grove profiles for the balance simulation (balance_simulation.md "Profiles"): a whole
# HeartwoodMemory profile standing for a player's progress, written to a temp file so the real
# profile is never touched. Load one with MetaRun.load_preset(&"half") before the run scene starts.
#   fresh: nothing (first runs, a new demo player)
#   early: ~5 cheap unlocks, 3 slots (~3 hours in)
#   half:  about half the tree by Seed cost, 3 slots (~15 hours in)
#   full:  everything, all 6 slots (endgame, Blight 0)
#   demo_full: the demo Grove grown (DemoGrove.NODES), 3 slots; run it with the demo on (ResultsScreen.demo_override = 1)

const PRESETS: Array[StringName] = [&"fresh", &"early", &"half", &"full", &"demo_full"]
const PATH := "user://sim_heartwood.json"
static var file_path := PATH  # Tests use a per-process name (every checkout shares user://)
# Early: Morning Stores I, Deep Taproot I, one family, two card bundles.
const EARLY := {"morning_stores": 1, "deep_taproot": 1, "pebbling": 1, "sharpened": 1, "tending_hands": 1}
# Perks carried, best first (the loadout takes as many as there are slots).
const LOADOUT_PRIORITY: Array[String] = ["morning_stores", "deep_taproot", "rich_dew", "second_thoughts",
	"wider_dreams", "sprout_bed", "rested_roots", "early_bloom", "clear_sight", "first_care", "kindling",
	"seed_pouch", "omen_reader", "early_light", "let_go"]

# The profile for `preset` (a full HeartwoodMemory dictionary).
static func profile(preset: StringName) -> Dictionary:
	var data := HeartwoodMemory.defaults()
	data.grove_welcome_shown = true
	match preset:
		&"fresh":
			pass
		&"early":
			data.runs_played = 3
			data.unlocks = EARLY.duplicate()
		&"half":
			data.runs_played = 15
			data.runs_won = 1
			data.highest_blight_won = 0
			data.unlocks = _half()
		&"full":
			data.runs_played = 30
			data.runs_won = 5
			data.highest_blight_won = 0
			for unlock in HeartwoodMemory.load_grove():
				if not unlock.is_free():  # Every node, The Heartwood's Crown (the 6th slot) too
					data.unlocks[unlock.id] = unlock.get_levels()
		&"demo_full":
			data.runs_played = 5
			data.unlocks = DemoGrove.NODES.duplicate()
		_:
			push_error("Unknown Grove preset %s" % preset)
	data.loadout = _loadout(data)
	return data

# Writes `preset` to a temp profile and points HeartwoodMemory at it. Returns the path.
static func load_preset(preset: StringName, path: String = "") -> String:
	if path == "":
		path = file_path
	HeartwoodMemory.file_path = path
	HeartwoodMemory.save_data(profile(preset))
	return path

# Back to the player's real profile.
static func unload() -> void:
	HeartwoodMemory.file_path = HeartwoodMemory.PATH

# About half the tree by Seed cost: the cheapest next level anywhere, loadout slot nodes aside
# (so the tree fills out broad and shallow, like a player buying something every run).
static func _half() -> Dictionary:
	var grove := HeartwoodMemory.load_grove()
	var total := 0
	for unlock in grove:
		total += unlock.get_spent(unlock.get_levels())
	var data := HeartwoodMemory.defaults()
	data.seeds = 1 << 30  # Buying is only limited by requirements here
	var spent := 0  # Slots 1–3 are open from the start, so no slot nodes here
	while spent < total / 2:
		var best: UnlockData = null
		for unlock in grove:
			if unlock.loadout_slots > 0 or HeartwoodMemory.buy_problem(data, unlock) != "":
				continue
			var cost := unlock.get_cost(HeartwoodMemory.unlock_level(data, unlock.id))
			if best == null or cost < best.get_cost(HeartwoodMemory.unlock_level(data, best.id)):
				best = unlock
		if best == null:
			break
		spent += _grow(data, best)
	return data.unlocks

static func _grow(data: Dictionary, unlock: UnlockData) -> int:
	var cost := unlock.get_cost(HeartwoodMemory.unlock_level(data, unlock.id))
	data.unlocks[unlock.id] = HeartwoodMemory.unlock_level(data, unlock.id) + 1
	return cost

static func _loadout(data: Dictionary) -> Array[String]:
	var carried: Array[String] = []
	var slots := HeartwoodMemory.loadout_slots(data)
	for id in LOADOUT_PRIORITY:
		var unlock := HeartwoodMemory.get_unlock(id)
		if carried.size() < slots and unlock != null and HeartwoodMemory.node_level(data, unlock) > 0:
			carried.append(id)
	return carried
