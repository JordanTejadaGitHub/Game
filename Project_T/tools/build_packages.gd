extends SceneTree

# Build packages: do the cards come? (dream_design.md "Build packages: do the cards come? (2026-09-30)").
# A measurement, not a feature: offer simulation (DreamState.sim_rest, no combat) with a full Grove and
# everything discovered. The bot owns each build's families and board from the stated drift, takes a
# package card whenever one is offered (else its style's best) and counts package cards (stacks once).
# Prints, per build: % of runs with 3+ / 5+ package cards by drift 25 / 50 / 75 / 100, the average
# count, and the share of offers with a package card. Never touches the player's saves.
#   godot --headless --path . --script res://tools/build_packages.gd --fixed-fps 60 -- --runs=1000

const PACKAGES := {
	"Storm Grid": ["rolling_thunder", "rain_on_glass", "soaked_through", "heavy_dew", "brighter_jars", "static_field", "conductive_soil"],
	"Spore Bomb": ["soft_spores", "lingering_spores", "spore_cascade", "chain_bloom", "sparking_spores", "twin_puff"],
	"Eldest": ["tender_care", "warm_hands", "kindred_roots", "deeper_rings", "sunlit_rest", "chosen_few"],
	"Wide Sprouts": ["seedfall", "sprout_surge", "sprout_chorus", "root_network", "seedling_gift", "many_hands"],
	"Kinship": ["quick_bonds", "family_ties", "sweet_harmony", "close_kin", "old_friends", "rooted_bond", "extended_family"],
}
const CHECKPOINTS := [25, 50, 75, 100]

var main: Node
var dreams: DreamState
var director: DriftDirector
var _stages: Array = []  # [[from drift, Array[Tower], {unlocks}, rank V?, kinships]]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var runs := 1000
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = int(arg.trim_prefix("--runs="))
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	director = main.get_node("%DriftDirector")
	dreams.unlock_everything = false
	dreams.grove_cards.assign(dreams.pool.map(func(c: UpgradeData) -> String: return c.id))  # Full Grove
	dreams.discovery_profile = null  # Not the real game: everything discovered
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()
	print("build packages: %d runs per build, full Grove, everything discovered" % runs)
	print("| Build | 3+ by 25 / 50 / 75 / 100 | 5+ by 25 / 50 / 75 / 100 | avg by 100 | offers with one |")
	print("|---|---|---|---|---|")
	for build in PACKAGES:
		_measure(build, runs)
	quit(0)

func _measure(build: String, runs: int) -> void:
	var package: Array = PACKAGES[build]
	for id in package:
		if not dreams.pool.any(func(c: UpgradeData) -> bool: return c.id == id):
			printerr("%s: no card %s" % [build, id])
	_build_board(build)
	var style := _style(build)
	var policy := DreamSimPolicy.new(dreams, style)
	var three := [0, 0, 0, 0]
	var five := [0, 0, 0, 0]
	var total := 0.0
	var tally := [0, 0]  # [offers, offers with a package card] (an Array: lambdas capture ints by value)
	var eligible := {}  # Card id -> rests where it could be offered (not owned yet)
	var open := {}  # Card id -> rests where it wasn't owned yet
	for run in runs:
		_reset(run)
		var stage := -1
		for drift in range(5, 101, 5):
			var want := _stage_for(drift)
			if want != stage:
				_apply_stage(want)
				stage = want
			director.drifts_started = drift
			for id in package:
				var c := _card(id)
				if c != null and not dreams.has_card(id):
					open[id] = int(open.get(id, 0)) + 1
				if c != null and not dreams.has_card(id) and dreams.can_offer(c, director.get_act(drift)):
					eligible[id] = int(eligible.get(id, 0)) + 1
			dreams.sim_rest(drift, func(offer: Array) -> UpgradeData:
				tally[0] += 1
				var fresh := offer.filter(func(c: UpgradeData) -> bool: return package.has(c.id) and not dreams.has_card(c.id))
				var any := offer.filter(func(c: UpgradeData) -> bool: return package.has(c.id))
				if not any.is_empty():
					tally[1] += 1
				if not fresh.is_empty():
					return fresh[0]
				if not any.is_empty():
					return any[0]
				return policy.pick_dream(offer))
			var i := CHECKPOINTS.find(drift)
			if i >= 0:
				var count := _count(package)
				three[i] += 1 if count >= 3 else 0
				five[i] += 1 if count >= 5 else 0
				if drift == 100:
					total += count
	var pct := func(a: Array) -> String:
		return " / ".join(a.map(func(n: int) -> String: return "%d%%" % roundi(100.0 * n / runs)))
	print("| %s | %s | %s | %.1f | %d%% |" % [build, pct.call(three), pct.call(five), total / runs,
		roundi(100.0 * tally[1] / maxi(tally[0], 1))])
	print("  eligible (share of rests, while not owned): " + ", ".join(package.map(func(id: String) -> String:
		return "%s %d%%" % [id, roundi(100.0 * int(eligible.get(id, 0)) / maxi(int(open.get(id, 0)), 1))])))

func _count(package: Array) -> int:
	return package.filter(func(id: String) -> bool: return dreams.has_card(id)).size()

func _style(build: String) -> DreamSimPolicy.Style:
	match build:
		"Eldest":
			return DreamSimPolicy.Style.NARROW
		"Wide Sprouts":
			return DreamSimPolicy.Style.SPROUT
		"Kinship":
			return DreamSimPolicy.Style.COMBO
	return DreamSimPolicy.Style.BALANCED

# The board by drift (dream_design.md): stage 0 from drift 1, stage 1 from the build's drift.
func _build_board(build: String) -> void:
	for stage in _stages:
		for tower in stage[1]:
			if tower.get_parent() != null:
				tower.get_parent().remove_child(tower)
			tower.free()
	_stages.clear()
	match build:
		"Storm Grid":
			_stages.append([1, _plant(["firefly_jar", "firefly_jar", "dewdrop", "dewdrop", "sprout"]), ["firefly_jar", "dewdrop"], false, 0])
			_stages.append([25, _plant(["stormcap", "stormcap", "rain_lily", "rain_lily"]), ["stormcap", "rain_lily"], false, 0])
		"Spore Bomb":
			_stages.append([1, _plant(["sporeling", "sporeling", "sporeling", "driftspore", "sprout"]), ["sporeling", "driftspore"], false, 0])
			_stages.append([25, _plant(["dewdrop", "mistveil", "puffball"]), ["dewdrop", "mistveil", "puffball"], false, 0])
		"Eldest":
			_stages.append([1, _plant(["sporeling", "sporeling", "firefly_jar"]), ["sporeling", "firefly_jar"], false, 0])
			_stages.append([20, _plant(["stormcap"]), ["stormcap"], true, 0])
		"Wide Sprouts":
			_stages.append([1, _plant(["sporeling", "sporeling", "sprout", "sprout", "sprout"]), ["sporeling"], false, 0])
			_stages.append([15, _plant(["sporeling", "sporeling", "sporeling", "firefly_jar", "firefly_jar", "dewdrop", "dewdrop",
				"sprout", "sprout", "sprout", "driftspore"]), ["firefly_jar", "dewdrop", "driftspore"], false, 0])
		"Kinship":
			_stages.append([1, _plant(["sporeling", "sporeling", "sprout"]), ["sporeling"], false, 0])
			_stages.append([10, _plant(["driftspore", "bloomcap"]), ["driftspore", "bloomcap"], false, 1])
	for stage in _stages:
		for tower in stage[1]:
			if tower.get_parent() != null:
				tower.get_parent().remove_child(tower)

func _stage_for(drift: int) -> int:
	var at := 0
	for i in _stages.size():
		if drift >= _stages[i][0]:
			at = i
	return at

# Puts stages 0..`index` on the map (and their unlocks, rank V, Kinships); the rest off.
func _apply_stage(index: int) -> void:
	var container := main.get_node("%TowerContainer")
	dreams.sim_kinships = 0
	for i in _stages.size():
		var on := i <= index
		for tower in _stages[i][1]:
			if on and tower.get_parent() == null:
				container.add_child(tower)
				tower.set_process(false)
			elif not on and tower.get_parent() != null:
				container.remove_child(tower)
			if _stages[i][3]:
				tower.rank = 5 if on else 0
		if on:
			for id in _stages[i][2]:
				dreams.unlocked[id] = true
			dreams.sim_kinships = maxi(dreams.sim_kinships, _stages[i][4])
	dreams.bump_board()

func _plant(ids: Array) -> Array[Tower]:
	var out: Array[Tower] = []
	var container := main.get_node("%TowerContainer")
	for id in ids:
		var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
		tower.tower_data = load("res://resource/tower/%s.tres" % id)
		var n := container.get_child_count() + _stages.size() * 20 + out.size()
		tower.cell = Vector2(200 + (n % 10) * 2, 200 + (n / 10) * 2)  # Off the map, 1 cell apart (no Kinships, no touching)
		tower.position = tower.MAP_GRID.calculate_map_position(tower.cell)
		container.add_child(tower)
		tower.set_process(false)
		out.append(tower)
	return out

func _reset(run: int) -> void:
	for stage in _stages:
		for tower in stage[1]:
			if tower.get_parent() != null:
				tower.get_parent().remove_child(tower)
			tower.rank = 0
	dreams.stacks.clear()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.dreams_seen = 0
	dreams._dreams_without_rare = 0
	dreams._rare_dreams_left = 0
	dreams._extra_cards_next = 0
	dreams._entwined_offered.clear()
	dreams._offer_drift = 0
	dreams._owed_families.clear()
	dreams._declined_families.clear()
	dreams._passed_count.clear()
	dreams._passed_at.clear()
	dreams._banished.clear()
	dreams._legendary_next = 0
	dreams.current_stray = null
	dreams._rng.seed = 1000 + run
	dreams.bump_board()

func _card(id: String) -> UpgradeData:
	for c in dreams.pool:
		if c.id == id:
			return c
	return null
