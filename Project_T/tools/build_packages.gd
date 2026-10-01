extends SceneTree

# Build packages and the catalogue (dream_design.md "Build packages", "Your Dreams steer your Dreams,
# not your family picks", "The build catalogue", "New cards for the catalogue"). A measurement, not a
# feature: offer simulation (DreamState.sim_rest, no combat), full Grove (Bittersweet included),
# everything discovered. Never touches the player's saves.
#
#   Chasing:   -- --mode=chase --build=B7 --runs=300    (or --build=all)
#     The bot owns the build's families and board from drift 1 (forms its cards name, the board it
#     needs: ranks, Sprouts, walls, a Kinship…), takes a package card whenever one is offered (else
#     Balanced's best). Prints 3+ by drift 50 and 5+ by drift 100 (targets ~35–55% / ~30–50%).
#   Any mode: --tag_weight=1.8 overrides DreamState.tag_weight (Pool trim tuning).
#   Emergence: -- --mode=emerge --runs=1000
#     A no-plan bot: random families (a pick after drift 1 and after the drift 25 boss), a small board
#     of them, Balanced's best card each rest. At drift 50: % of runs with 3+ cards of some package
#     (~70%+) and each build's share of those runs (none above ~15%). Adapt: % of offers with a card
#     usable now that shares no tag with the cards taken (~70%+). Own-family share (reference only).

# Package = enhancers by display name (Legendaries are capstones, not package cards). Bridge cards are
# listed under both builds. Names that aren't cards in the pool are reported and skipped.
const PACKAGES := {
	"B1 Storm Grid": ["Rolling Thunder", "Rain on Glass", "Soaked Through", "Heavy Dew", "Brighter Jars", "Charged Field", "Conductive Soil", "Fireflies in the Grass", "Live Wire"],
	"B2 The Long Walk": ["Cozy Corners", "Hedge Maze", "Straightaway", "Winding Path", "Bitter Hedges", "Heart of the Maze", "Thornheart", "Eddy", "Spinning Corners", "Last Stand", "Mixed Grove"],
	"B3 Spore Bomb": ["Soft Spores", "Lingering Spores", "Spore Cascade", "Chain Bloom", "Damp Rot", "Twin Puff", "Mushroom Rain", "Mycelium", "Spore Kin"],
	"B4 Sniper's Rest": ["Long Shadows", "Patient Aim", "Starlit Aim", "Called Shot", "Sharpened Light", "Solitude", "Watchful Rest", "Hunter's Patience"],
	"B5 Full Moon": ["Glinting Dew", "Sharpened Light", "Still Target", "Shattering Blow", "Deep Frost", "Shiny Things"],
	"B6 Gale": ["Carried on the Wind", "Lasting Dreams", "Ill Wind", "Eddy"],
	"B7 Fairy Mines": ["Ring Dance", "Sweet Scent", "Scented Hedge", "Deep Grip", "Root Web", "Lingering Spores"],
	"B8 Hairpin Mill": ["Hairpin Winds", "Cozy Corners", "Hedge Maze", "Crowded Path", "Spinning Corners"],
	"B9 Sleepy Hollow": ["Heavy Eyelids", "Hush", "Bad Dreams", "Many Threads", "Lullaby", "Clear Tones", "Chorus", "Heavy Air"],
	"B10 Storm Corridor": ["Windborne Rain", "Straightaway", "Longer Flight", "Rolling Thunder", "Rain on Glass", "Heavy Dew"],
	"B11 Thousand Cuts": ["Charged Feathers", "Thousand Cuts", "Sharp Beaks", "Needle Point", "Called Shot", "Bright Marks"],
	"B12 Encore": ["Encore", "Quick Reactions", "Seeping", "Kin and Kindling", "Rolling Thunder", "Wildfire Spores", "Sparking Spores", "Mushroom Rain", "Damp Rot", "Deep Water"],
	"B13 Rockfall": ["Loose Stones", "Shattering Blow", "Heavy Stones", "Crowded Path", "Falling Weight"],
	"B14 Deep Poison": ["Seeping", "Bitter Sap", "Venom Bloom", "Soft Spores", "Lingering Spores", "Damp Rot", "Lasting Dreams", "Ill Wind"],
	"B15 Thunder Chimes": ["Clear Tones", "Charged Field", "Brighter Jars", "Chorus", "Resonance"],
	"B16 Bramble Maze": ["Hedge Maze", "Bitter Hedges", "Weathered Walls", "Living Walls", "Thorn Snare", "Bramble Oath", "Thornheart"],
	"B17 The Grove": ["Grandfather Stump", "Kind Canopy", "Shared Light", "Hedgerow Roots", "Warm Hearth"],
	"B18 Greedy Gardener": ["Dew Bowl", "Harvest Moon", "Deep Well", "Overflowing Well", "Dew Trail", "Morning Dew", "Call of the Wild"],
	# The 10 card builds (dream_design.md "Pool trim" rounds 2–3 + the Grove branches Swift and Wide Reach): enhancers only, Legendaries are capstones.
	"C1 Tall": ["Tender Care", "Kindred Roots", "Sunlit Rest", "Deeper Rings", "Chosen Few", "Elder Kin", "Solitude", "Few and Mighty"],
	"C2 Overgrowth": ["Seedfall", "Sprout Chorus", "Root Network", "Seedling Gift", "Canopy", "Many Hands", "Mixed Grove", "Odd One Out", "Grand Tour", "Warm Hearth"],
	"C3 Daring": ["Call of the Wild", "Fresh Growth", "Head Start", "Quick Step", "Second Wind", "Scarred Bark", "Desperate Bloom", "Thin Bark", "Last Stand"],
	"C4 Precision": ["Glinting Dew", "Sharpened Light", "Shattering Blow", "Still Target", "First Light", "Lone Hunter", "Hunter's Patience", "Watchful Rest", "Heavy Stones", "Called Shot"],
	"C5 Affliction": ["Bitter Sap", "Seeping", "Venom Bloom", "Lasting Dreams", "Heavy Air", "Crowd Breaker", "Crowded Path", "Last Breath", "Thinning the Herd"],
	"C6 Maze": ["Cozy Corners", "Straightaway", "Winding Path", "Heart of the Maze", "Forest's Edge", "Hedge Maze", "Bitter Hedges", "Thornheart", "Weathered Walls"],
	"C7 Tending": ["Heartwood's Reach", "Tended Stumps", "Hollow Ground", "Reclaimed Earth", "Tended Forest", "Burn Back the Dead Wood", "Morning Dew", "Living Walls", "Scented Hedge", "Thorn Snare"],
	"C8 Kinship": ["Family Ties", "Sweet Harmony", "Old Friends", "Rooted Bond", "Extended Family", "Kin and Kindling", "Blood Is Thicker", "Elder Kin"],
	"C9 Swift": ["Momentum", "Quickening", "Flurry", "Restless Roots", "Hummingheart", "Drumbeat", "Quick Step"],  # Grove build branch
	"C10 Wide Reach": ["Broad Splash", "Lingering Splash", "Far Reach", "Spillover", "Overlap", "Crowd Breaker", "Last Breath", "Shattering Blow"],  # Grove build branch
}
# Board extras the chasing bot needs for some builds (ranks, Sprouts, walls, a Kinship, clearing…).
const EXTRAS := {
	"C1 Tall": {"ranks": true},
	"C2 Overgrowth": {"wide": true, "families": ["sporeling", "firefly_jar", "dewdrop", "pebbling"]},
	"C8 Kinship": {"kinship": true},
	"C10 Wide Reach": {"families": ["acorn", "dewdrop"]},  # Area attackers (pulses)
	"C6 Maze": {"walls": true},
	"B2 The Long Walk": {"walls": true},
	"B8 Hairpin Mill": {"walls": true, "families": ["whirligig"]},
	"B16 Bramble Maze": {"walls": true, "families": ["rootling"], "forms": ["bramble"]},
	"C7 Tending": {"clearing": true, "walls": true},
	"B6 Gale": {"families": ["whirligig", "sporeling"]},
	"B17 The Grove": {"families": ["acorn"], "forms": ["grove_heart", "elder_stump"]},
	"B18 Greedy Gardener": {"families": ["acorn"], "forms": ["dewcatcher", "wellspring"]},
}
const DEFAULT_FAMILIES := ["sporeling", "firefly_jar"]

var main: Node
var dreams: DreamState
var director: DriftDirector
var ids := {}  # Build -> Array of card ids
var missing := {}  # Display name -> true (named in the catalogue, not a card)
var _planted: Array[Tower] = []
var _policy: DreamSimPolicy
var use_run_pool := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var mode := "chase"
	var only := "all"
	var runs := 300
	var picker := "balanced"
	var tag_weight := -1.0
	var preset := "full"  # full: the whole Grove, everything discovered; fresh: a new account (start pool, nothing discovered)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--build="):
			only = arg.trim_prefix("--build=")
		elif arg.begins_with("--runs="):
			runs = int(arg.trim_prefix("--runs="))
		elif arg.begins_with("--picker="):
			picker = arg.trim_prefix("--picker=")  # balanced / random / mixed (emergence)
		elif arg.begins_with("--preset="):
			preset = arg.trim_prefix("--preset=")
		elif arg == "--run_pool":
			use_run_pool = true  # Each run draws its own pool (dream_design.md "Exact rules")
		elif arg.begins_with("--tag_weight="):
			tag_weight = float(arg.trim_prefix("--tag_weight="))  # Tuning: overrides DreamState.tag_weight
	MetaRun.force_all_families = true  # Full Grove: every family in the picks (Grove families' cards can be eligible)
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	director = main.get_node("%DriftDirector")
	dreams.unlock_everything = false
	if preset == "fresh":
		dreams.grove_cards.clear()  # A new account: the start pool only
	else:
		dreams.grove_cards.assign(dreams.pool.map(func(c: UpgradeData) -> String: return c.id))  # Full Grove
	dreams.allow_bittersweet = true
	if tag_weight > 0.0:
		dreams.tag_weight = tag_weight
	dreams.discovery_profile = {"seen": [], "wardens_built": [], "best_chain": 0} if preset == "fresh" else null  # fresh: nothing discovered
	dreams.allow_bittersweet = preset != "fresh"
	dreams.run_pool_forced = use_run_pool
	_policy = DreamSimPolicy.new(dreams, DreamSimPolicy.Style.BALANCED)
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()
	_resolve()
	if mode == "emerge":
		_emerge(runs, picker)
	else:
		for build in PACKAGES:
			if only == "all" or Array(only.split(",")).has(build.get_slice(" ", 0)):
				_chase(build, runs)
	if not missing.is_empty():
		print("not cards (skipped): " + ", ".join(missing.keys()))
	quit(0)

func _resolve() -> void:
	var by_name := {}
	for card in dreams.pool:
		by_name[card.display_name.to_lower()] = card.id
	for build in PACKAGES:
		var list: Array = []
		for name in PACKAGES[build]:
			var id: String = by_name.get(String(name).to_lower(), "")
			if id == "":
				missing[name] = true
			elif not list.has(id):
				list.append(id)
		ids[build] = list

# --- Chasing ------------------------------------------------------------------------------------------

func _chase(build: String, runs: int) -> void:
	var package: Array = ids[build]
	var extras: Dictionary = EXTRAS.get(build, {})
	var three := 0
	var three_75 := 0  # Late builds (Tall) are judged at drift 75
	var five := 0
	var total := 0.0
	for run in runs:
		_reset(run)
		_build_chase_board(package, extras)
		for drift in range(5, 101, 5):
			director.drifts_started = drift
			dreams.sim_rest(drift, func(offer: Array) -> UpgradeData:
				var fresh := offer.filter(func(c: UpgradeData) -> bool: return package.has(c.id) and not dreams.has_card(c.id))
				if not fresh.is_empty():
					return fresh[0]
				return _policy.pick_dream(offer))
			_spend_dreamlight()
			var count := _count(package)
			if drift == 50 and count >= 3:
				three += 1
			if drift == 75 and count >= 3:
				three_75 += 1
			if drift == 100:
				five += 1 if count >= 5 else 0
				total += count
	print("CHASE | %s | %d | %d%% | %d%% | %.1f | 3+ by 75: %d%% |" % [build, package.size(), roundi(100.0 * three / runs), roundi(100.0 * five / runs), total / runs, roundi(100.0 * three_75 / runs)])

# The build's families (from what its cards name, or the defaults), the forms its cards name, and
# its extras, planted off the map (no touching, no Kinships unless asked).
func _build_chase_board(package: Array, extras: Dictionary) -> void:
	var families := {}
	var forms := {}
	for id in package:
		var card := _card(id)
		for need in Array(card.requires) + Array(card.requires_any):
			var family := dreams.family_of(need)
			if family != "":
				families[family] = true
				if need != family:
					forms[need] = true
	for family in extras.get("families", []):
		families[family] = true
	for form in extras.get("forms", []):
		forms[form] = true
	if families.is_empty():
		for family in DEFAULT_FAMILIES:
			families[family] = true
	var plant: Array = []
	for family in families:
		dreams.unlocked[family] = true
		plant.append_array([family, family])
	for form in forms:
		dreams.unlocked[form] = true
		plant.append(form)
	dreams.add_dreamlight(dreams.sim_dreamlight_for(&"first"))
	_spend_dreamlight()
	if extras.get("wide", false):
		for i in 10:
			plant.append(families.keys()[i % families.size()])
		plant.append_array(["sprout", "sprout", "sprout", "sprout", "sprout", "sprout"])
	if extras.get("walls", false):
		for i in 8:
			plant.append("thornwall")
	_plant(plant)
	if extras.get("ranks", false) and _planted.size() >= 2:
		_planted[0].rank = 5
		_planted[1].rank = 3
	dreams.sim_kinships = 1 if extras.get("kinship", false) else 0
	dreams.clearing_open = extras.get("clearing", false)
	dreams.bump_board()

# --- Emergence ----------------------------------------------------------------------------------------

func _emerge(runs: int, picker: String = "balanced") -> void:
	var some := 0
	var per_build := {}
	var offers := [0, 0, 0]  # [offers, with a usable card sharing no tag, …a tagged one]
	var shown := [0, 0]  # [cards offered, own-family cards]
	for run in runs:
		_reset(run)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7000 + run
		var policy := _policy  # Balanced; "mixed" = a random style each run; "random" = any card
		if picker == "mixed":
			policy = DreamSimPolicy.new(dreams, DreamSimPolicy.Style.values()[rng.randi_range(0, DreamSimPolicy.Style.size() - 1)])
		var roots: Array = dreams._family_roots().map(func(d: TowerData) -> String: return d.get_id())
		var owned: Array = []
		for drift in range(5, 51, 5):
			director.drifts_started = drift
			if drift == 5 or drift == 30:  # The family picks (after drift 1, after the drift 25 boss)
				var left := roots.filter(func(r: String) -> bool: return not owned.has(r))
				var family: String = left[rng.randi_range(0, left.size() - 1)]
				owned.append(family)
				dreams.unlocked[family] = true
				if drift == 5:
					dreams.add_dreamlight(dreams.sim_dreamlight_for(&"first"))
				_plant([family, family, family, "sprout", "thornwall"])
				dreams.bump_board()
			var lines := {}
			for family in owned:
				var data := IconInfo.family_data(family)
				if data != null:
					lines[data.line] = true
			dreams.sim_rest(drift, func(offer: Array) -> UpgradeData:
				offers[0] += 1
				var taken_tags := {}
				for c in dreams.get_taken_cards():
					for tag in c.tags:
						taken_tags[tag] = true
				var fresh := offer.filter(func(c: UpgradeData) -> bool:
					return not dreams.is_half_dreamed(c) and not c.tags.any(func(t: String) -> bool: return taken_tags.has(t)))
				offers[1] += 1 if not fresh.is_empty() else 0
				offers[2] += 1 if fresh.any(func(c: UpgradeData) -> bool: return not c.tags.is_empty()) else 0
				for c in offer:
					shown[0] += 1
					if c.tags.any(func(t: String) -> bool: return lines.has(t)):
						shown[1] += 1
				return offer[rng.randi_range(0, offer.size() - 1)] if picker == "random" else policy.pick_dream(offer))
			_spend_dreamlight()
		var hit := false
		for build in PACKAGES:
			if _count(ids[build]) >= 3:
				per_build[build] = int(per_build.get(build, 0)) + 1
				hit = true
		some += 1 if hit else 0
	print("EMERGE (%s picker) 3+ cards of some package by drift 50: %d%% of %d runs" % [picker, roundi(100.0 * some / runs), runs])
	var order: Array = per_build.keys()
	order.sort_custom(func(a, b) -> bool: return per_build[a] > per_build[b])
	print("EMERGE each build's share of those runs: " + ", ".join(order.map(func(b: String) -> String:
		return "%s %d%%" % [b, roundi(100.0 * per_build[b] / maxi(some, 1))])))
	print("ADAPT offers with a usable card sharing no tag with your cards: %d%% (%d%% counting tagged cards only)" % [
		roundi(100.0 * offers[1] / maxi(offers[0], 1)), roundi(100.0 * offers[2] / maxi(offers[0], 1))])
	print("OWNFAMILY own-family share of offered cards (reference): %d%%" % roundi(100.0 * shown[1] / maxi(shown[0], 1)))

# --- Shared ---------------------------------------------------------------------------------------------

func _count(package: Array) -> int:
	return package.filter(func(id: String) -> bool: return dreams.has_card(id)).size()

func _card(id: String) -> UpgradeData:
	for c in dreams.pool:
		if c.id == id:
			return c
	return null

func _plant(list: Array) -> void:
	var container := main.get_node("%TowerContainer")
	for id in list:
		var path := "res://resource/tower/%s.tres" % id
		if not ResourceLoader.exists(path):
			continue
		var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
		tower.tower_data = load(path)
		var n := _planted.size()
		tower.cell = Vector2(200 + (n % 12) * 2, 200 + (n / 12) * 2)  # Off the map, 1 cell apart
		tower.position = tower.MAP_GRID.calculate_map_position(tower.cell)
		container.add_child(tower)
		tower.set_process(false)
		_planted.append(tower)

# A player spends Dreamlight as it comes: final forms of the owned families first (the costliest that
# fits), then hidden branches and wall growths.
func _spend_dreamlight() -> void:
	while true:
		var best: TowerData = null
		for tree in dreams.get_remember_trees():
			for form in _tree_forms(tree):
				if dreams.can_unlock(form) and (best == null or form.tier > best.tier):
					best = form
		if best == null or not dreams.unlock_with_dreamlight(best):
			return
		_plant([best.get_id()])  # A player grows what they buy (round 5: a card's Warden must have stood on the map)
		dreams.bump_board()

func _tree_forms(tree: Array) -> Array:
	var forms: Array = []
	for branch in tree[1]:
		forms.append(branch[0])
		forms.append_array(branch[1])
	if tree[2] != null:
		forms.append(tree[2])
	return forms

func _reset(run: int) -> void:
	for tower in _planted:
		tower.free()
	_planted.clear()
	dreams.stacks.clear()
	dreams._resonance.clear()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.dreamlight = 0
	dreams.grown_wardens.clear()
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
	dreams.sim_kinships = 0
	dreams.clearing_open = false
	dreams._rng.seed = 1000 + run
	if use_run_pool:
		dreams.run_pool.clear()  # Drawn again at the run's first offer (seeded by the run)
		main.get_node("MapGenerator").map_seed = 424242 + run
	dreams.bump_board()
