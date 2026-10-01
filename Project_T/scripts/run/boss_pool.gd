extends RefCounted
class_name BossPool

# Boss pools (documentation/enemy_design.md, "Bosses: a pool of 3 per act", 2026-09-29): every act
# has a pool of great nightmares in resource/boss/act_N/ (act 4: the Hollow Oak's three variations).
# At run start one is drawn per act from the run's seed and its drift replaces the act's boss drift.
#
#   - A player's first run ever meets each act's default (`BossData.is_default`).
#   - The demo (demo_scope.md) always meets the defaults in acts 1–2.
#   - Otherwise random, and last run's boss in that act is half as likely (profile "last_bosses").
#   - A resumed run keeps the bosses it drew (RunSaver stores the ids).

const DIR := "res://resource/boss/act_%d/"
const ACTS := 4
const DEMO_FIXED_ACTS := 2  # Acts 1–2 in the demo are always the Hollow Stag and the Mire Hag
const REPEAT_WEIGHT := 0.5  # Last run's boss in an act, relative to the others
const PROFILE_KEY := "last_bosses"
const SEED_SALT := 0x5b055  # So the draw doesn't mirror the map's own random numbers

static var force_draw := false  # Tests: draw as a real run would (tests otherwise meet the defaults)
# {act: Array of resource paths} (sorted by id, so draws are reproducible). Only paths: a static that
# holds the resources themselves keeps them alive into the engine's teardown, which can crash on quit.
# load() hits the resource cache, so loading them again per call is cheap.
static var _pools := {}

static func get_pool(act: int) -> Array[BossData]:
	if not _pools.has(act):
		var found: Array[BossData] = []
		var dir := DIR % act
		for file in ResourceLoader.list_directory(dir):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var data := load(dir.path_join(file)) as BossData
				if data != null and data.boss != null and data.drift != null:
					found.append(data)
		found.sort_custom(func(a: BossData, b: BossData) -> bool: return a.get_id() < b.get_id())
		_pools[act] = found.map(func(data: BossData) -> String: return data.resource_path)
	var pool: Array[BossData] = []
	for path: String in _pools[act]:
		pool.append(load(path) as BossData)
	return pool

static func find(act: int, id: String) -> BossData:
	for data in get_pool(act):
		if data.get_id() == id:
			return data
	return null

static func get_default(act: int) -> BossData:
	var pool := get_pool(act)
	for data in pool:
		if data.is_default:
			return data
	return pool[0] if not pool.is_empty() else null

# One BossData per act (index 0 = act 1), null where an act has no pool.
# `first_run`: everyone meets the defaults. `demo`: acts 1–2 are the defaults. `last`: ids met in
# each act last run (index 0 = act 1), made half as likely.
static func draw(run_seed: int, first_run: bool = false, demo: bool = false, last: Array = []) -> Array[BossData]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, SEED_SALT])
	var result: Array[BossData] = []
	for act in range(1, ACTS + 1):
		var pool := get_pool(act)
		var pick: BossData = null
		if first_run or (demo and act <= DEMO_FIXED_ACTS):
			pick = get_default(act)
		elif not pool.is_empty():
			var previous: String = String(last[act - 1]) if act - 1 < last.size() else ""
			var weights := PackedFloat32Array()
			for data in pool:
				weights.append(REPEAT_WEIGHT if data.get_id() == previous and pool.size() > 1 else 1.0)
			pick = pool[rng.rand_weighted(weights)]
		result.append(pick)
	return result

# Puts the drawn bosses' drifts into the run (drift 25 × act). Acts past the run's length are skipped.
static func apply(director: Node, bosses: Array[BossData]) -> void:
	for i in bosses.size():
		var number: int = (i + 1) * director.drifts_per_act
		if bosses[i] != null and number <= director.drifts.size():
			director.drifts[number - 1] = bosses[i].drift

static func ids(bosses: Array[BossData]) -> Array:
	return bosses.map(func(b: BossData) -> String: return b.get_id() if b != null else "")

static func from_ids(saved: Array) -> Array[BossData]:
	var result: Array[BossData] = []
	for act in range(1, ACTS + 1):
		var id: String = String(saved[act - 1]) if act - 1 < saved.size() else ""
		var data := find(act, id)
		result.append(data if data != null else get_default(act))
	return result

static func last_from_profile() -> Array:
	return HeartwoodMemory.load_data().get(PROFILE_KEY, [])

# Real game only: the next run weighs against these.
static func remember(bosses: Array[BossData]) -> void:
	var memory := HeartwoodMemory.load_data()
	memory[PROFILE_KEY] = ids(bosses)
	HeartwoodMemory.save_data(memory)
