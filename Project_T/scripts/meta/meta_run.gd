extends Node
class_name MetaRun

# Brings the meta (meta_design.md) into a run and back out:
# - Run start: the Memory Grove perks carried in the loadout (starting Dew, Dew gain, rest bonus,
#   max leaves, Dream rerolls / banishes / cards per offer, Omens, starting Dreams, Sprouts, free
#   Nurture, Seed bonus, Early Bloom), every owned node's families (family picks) and Dream cards
#   (pool), Family Blessings are made available, and the chosen Blight Level's modifiers.
# - Run end (the real full game only, never tests / Test Grove / the demo): lifetime counters,
#   milestones (and what they unlock), the highest Blight Level won.
# The demo has no meta (demo_scope.md): nothing is applied or recorded there.

const TOWER_DIR := "res://resource/tower/"
const BLESSING_DIR := "res://resource/meta/blessing/"
const SHADE_KIND := "leaf_bug"
# Milestones (meta_design.md "Milestones"): id -> the cosmetic it grows. Grove nodes with a
# `milestone` grow by themselves (HeartwoodMemory.node_level; Sunpetal, One Line, The Long Walk).
const MILESTONE_COSMETICS := {"flawless_win": "golden_leaf", "blight_10_win": "blossoms"}

# Chosen on the title screen before a run (0 = none); saved with the run.
static var blight_level := 0

# Developer option "Unlock all families" (settings, debug builds only): a normal run whose family
# picks and Dream pool act as if the Grove's Warden root were fully grown. The profile's real
# unlocks are untouched (turning it off undoes it), and the run banks no Seeds and records nothing.
const ALL_FAMILIES_SETTING := "all_families"
static var force_all_families := false  # Tests

static func all_families_active() -> bool:
	if not TestGrove.is_available():
		return false
	if force_all_families:
		return true
	# Headless test scripts ignore the developer's saved setting, as with Test Grove.
	if OS.get_cmdline_args().has("--script"):
		return false
	return bool(HeartwoodMemory.get_settings().get(ALL_FAMILIES_SETTING, false))

# A developer run (Test Grove or Unlock all families): nothing is banked or recorded.
static func is_dev_run() -> bool:
	return TestGrove.is_active() or all_families_active()

@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var dream_state: DreamState = %DreamState
@onready var omen_director: OmenDirector = %OmenDirector
@onready var family_screen: Control = %FamilyPickScreen
@onready var spawner = %EnemyContainer

var active := false  # Meta applies (full game)
var records := false  # Run end writes to the profile (real full game)
var seed_bonus := 0.0
var _shades_this_run := 0

func _ready() -> void:
	active = not ResultsScreen.is_demo()
	records = active and get_tree().current_scene == owner and not is_dev_run()
	# Family Blessings are in the Dream pool (never offered; the family pick grants them), so their
	# effects count and saved runs find them.
	for blessing in load_blessings():
		if not dream_state.pool.has(blessing):
			dream_state.pool.append(blessing)
	var all_families := all_families_active() and not TestGrove.is_active()
	if not active:
		if all_families:  # Also in the demo build's debug runs
			_apply_all_families()
		return
	var memory := HeartwoodMemory.load_data()
	_apply_grove(memory)
	if all_families:
		_apply_all_families()
	_apply_blight(blight_level)
	run_state.seed_bonus = seed_bonus
	spawner.enemy_cleansed.connect(func(enemy: Node2D) -> void:
		if enemy.enemy_data.resource_path.get_file().get_basename() == SHADE_KIND:
			_shades_this_run += 1)
	run_state.run_ended.connect(_on_run_ended)

# A family's base Warden, or null while it isn't built yet (a Grove node can name a coming family).
static func _family(id: String) -> TowerData:
	var path := TOWER_DIR + id + ".tres"
	return load(path) as TowerData if ResourceLoader.exists(path) else null

static func load_blessings() -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	for file in ResourceLoader.list_directory(BLESSING_DIR):
		if file.ends_with(".tres") or file.ends_with(".res"):
			result.append(load(BLESSING_DIR + file))
	return result

# Obstacles cost twice as much from Blight Level 9.
static func clear_cost_multiplier() -> float:
	return 2.0 if blight_level >= 9 else 1.0

# Unlock all families: every family and Warden Dream card from the Grove's Warden root join this
# run (on top of whatever the profile has), without perks.
func _apply_all_families() -> void:
	for unlock in HeartwoodMemory.load_grove():
		if unlock.root != UnlockData.Root.WARDENS:
			continue
		for id in unlock.families:
			var data := _family(id)
			if data != null and not family_screen.families.has(data):
				family_screen.families.append(data)
		if "grove_cards" in dream_state:
			for id in unlock.dream_cards:
				if not dream_state.grove_cards.has(id):
					dream_state.grove_cards.append(id)

# Owned Grove nodes: families join the picks and Dream cards join the pool (every owned node);
# perks work only while carried in the loadout, at their highest owned level.
func _apply_grove(memory: Dictionary) -> void:
	var cards: Array[String] = []
	var carried := HeartwoodMemory.get_loadout(memory)
	var dew := 0
	var leaves := 0
	var rerolls := 0
	var banishes := 0
	var extra_cards := 0
	var dreamlight := 0
	var start_cards: Array[String] = []
	var random_commons := 0
	var sprouts := 0
	var nurtures := 0
	for unlock in HeartwoodMemory.load_grove():
		var level := HeartwoodMemory.node_level(memory, unlock)
		if level == 0:
			continue
		for id in unlock.families:
			var data := _family(id)
			if data != null and not family_screen.families.has(data):
				family_screen.families.append(data)
		for id in unlock.dream_cards:
			if not cards.has(id):
				cards.append(id)
		if unlock.allows_bittersweet:
			dream_state.allow_bittersweet = true
		if not unlock.is_perk() or not carried.has(unlock.id):
			continue
		dew += unlock.starting_dew * level
		run_state.dew_gain_bonus += unlock.dew_gain * level
		drift_director.rest_bonus_perk_multiplier += unlock.rest_bonus * level
		leaves += unlock.max_leaves * level
		rerolls += unlock.dream_rerolls * level
		banishes += unlock.dream_banishes * level
		extra_cards += unlock.extra_dream_cards * level
		omen_director.omens_per_offer += unlock.extra_omens * level
		seed_bonus += unlock.seed_bonus * level
		dreamlight += unlock.starting_dreamlight * level
		start_cards.append_array(unlock.starting_cards)
		random_commons += unlock.random_common_cards * level
		sprouts += unlock.sprout_charges * level
		nurtures += unlock.free_nurtures * level
		if unlock.early_bloom:
			family_screen.offer_all_first = true
	run_state.add_dew(dew)
	run_state.max_leaves += leaves
	run_state.leaves += leaves
	run_state.leaves_changed.emit(run_state.leaves, run_state.max_leaves)
	if sprouts > 0:  # Sprout Bed
		run_state.add_sprout_charges(sprouts)
	run_state.free_nurtures += nurtures  # First Care
	# Dream hooks (DreamState owns the Dream rules; these names are its public knobs).
	if "grove_cards" in dream_state:
		dream_state.grove_cards.assign(cards)
	dream_state.cards_per_offer += extra_cards
	if dreamlight > 0:  # Early Light
		dream_state.add_dreamlight(dreamlight)
	if "rerolls_left" in dream_state:
		dream_state.rerolls_left += rerolls
	if "banishes_left" in dream_state:
		dream_state.banishes_left += banishes
	# Clear Sight's Cleared Ground, then Kindling's random Commons (a resumed run's save replaces them).
	for id in start_cards:
		var card := _card(id)
		if card != null:
			dream_state.take(card)
	for i in random_commons:
		var commons := dream_state.pool.filter(func(c: UpgradeData) -> bool:
			return c.rarity == UpgradeData.Rarity.COMMON and not c.is_bittersweet() and dream_state.is_eligible(c))
		if not commons.is_empty():
			dream_state.take(commons.pick_random())

func _card(id: String) -> UpgradeData:
	for card in dream_state.pool:
		if card.id == id:
			return card
	return null

# Blight Levels (meta_design.md): each level includes the ones below it. +10% Seeds per level.
func _apply_blight(level: int) -> void:
	if level <= 0:
		return
	seed_bonus += 0.1 * level
	if level >= 1:
		drift_director.blight_health_multiplier = 1.1
	if level >= 2:
		run_state.dew = maxi(run_state.dew - 20, 0)
		run_state.dew_changed.emit(run_state.dew)
	if level >= 3:
		drift_director.blight_boss_health_multiplier = 1.25
	if level >= 4:
		drift_director.blight_rest_bonus_multiplier = 0.75
	if level >= 5:
		drift_director.blight_elites_per_drift = 1
	if level >= 6:
		drift_director.act_break_leaves = 0  # No leaves regrow at act breaks (normally +1)
	if level >= 7:
		drift_director.blight_speed_multiplier = 1.1
	if level >= 8:
		dream_state.skip_dew = 0  # Let it pass gives no Dew
		if "lean_common" in dream_state:
			dream_state.lean_common = true
	# Level 9's doubled clear costs: clear_cost_multiplier(); its extra ridge is in the map generator
	# (EnvironmentObjectGenerator.blight_extra_ridges). Level 10's Hollow
	# Oak phase needs the act 4 boss.

# Lifetime counters, milestones and the highest Blight Level won.
func _on_run_ended(won: bool) -> void:
	if not records:
		return
	var memory := HeartwoodMemory.load_data()
	var counters: Dictionary = memory.counters
	counters.shades_dispelled = int(counters.get("shades_dispelled", 0)) + _shades_this_run
	counters.tended_total = int(counters.get("tended_total", 0)) + run_state.obstacles_tended
	var reached := []
	if drift_director.bosses_cleansed > 0:
		reached.append("first_boss")
	if won:
		reached.append("first_win")
		memory.highest_blight_won = maxi(int(memory.highest_blight_won), blight_level)
		if run_state.leaves_lost == 0:
			reached.append("flawless_win")
		if _one_family_only():
			reached.append("one_line_win")
		if blight_level >= 10:
			reached.append("blight_10_win")
	if counters.shades_dispelled >= 500:
		reached.append("shades_500")
	if run_state.longest_path >= 300:
		reached.append("path_300")
	if counters.tended_total >= 100:
		reached.append("tend_100")
	if blight_level >= 5:
		reached.append("blight_5")
	for id in reached:
		if not memory.milestones.has(id):
			memory.milestones[id] = true
			HeartwoodMemory.grow_milestone_nodes(memory, id)  # Refunds a node it grows, if bought
			if MILESTONE_COSMETICS.has(id) and not memory.cosmetics.has(MILESTONE_COSMETICS[id]):
				memory.cosmetics.append(MILESTONE_COSMETICS[id])
	HeartwoodMemory.save_data(memory)

# Won with every attacking Warden from one family line (Sprouts and walls don't count).
func _one_family_only() -> bool:
	var lines := {}
	for tower in (%TowerContainer as Node).get_children():
		if tower is Tower and tower.tower_data.can_attack and tower.tower_data.line not in ["sprout", "wall", "memory"]:
			lines[tower.tower_data.line] = true
	return lines.size() == 1
