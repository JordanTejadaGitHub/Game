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
const MILESTONE_COSMETICS := {
	"flawless_win": "golden_leaf", "blight_10_win": "blossoms", "all_combos": "gilded_pages", "all_dreams": "starlit_backs",
}

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

# "Dream of everything" (meta_design.md, milestone `all_dreams`, every Dream card seen): starlit card
# backs on Dream offers + 1 Dream reroll per run on top of Second Thoughts (full game). The developer
# toggle (settings, debug builds only) grants both for testing without recording or writing anything.
const ALL_DREAMS := "all_dreams"
const ALL_DREAMS_SETTING := "all_dreams_rewards"
const ALL_DREAMS_REROLLS := 1
static var force_all_dreams := false  # Tests

static func all_dreams_dev_active() -> bool:
	if not TestGrove.is_available():
		return false
	if force_all_dreams:
		return true
	if OS.get_cmdline_args().has("--script"):
		return false
	return bool(HeartwoodMemory.get_settings().get(ALL_DREAMS_SETTING, false))

# Dream offer cards get the night-sky frame (DreamScreen).
static func starlit_backs() -> bool:
	if all_dreams_dev_active():
		return true
	return not ResultsScreen.is_demo() and HeartwoodMemory.load_data().milestones.has(ALL_DREAMS)

# Developer toggle (settings, debug builds only): the secret 6th loadout slot for testing, without
# recording "The Heartwood in full bloom" or writing the profile.
const SIXTH_SLOT_SETTING := "sixth_slot"
static var force_sixth_slot := false  # Tests

static func sixth_slot_dev_active() -> bool:
	if not TestGrove.is_available():
		return false
	if force_sixth_slot:
		return true
	if OS.get_cmdline_args().has("--script"):
		return false
	return bool(HeartwoodMemory.get_settings().get(SIXTH_SLOT_SETTING, false))

# PARKED (user decision 2026-09-29, tower_design.md / meta_design.md): Memory Wardens are switched off.
# Their blooms are left out of the Grove (HeartwoodMemory.load_grove), so none grows or shows and the
# boss pick never offers one. Code, art and resources stay; boss first-dispels are still recorded
# quietly, so turning this back on restores the blooms a player has earned.
const MEMORY_WARDENS_ENABLED := false

# Memory Wardens (tower_design.md): a boss's first dispel records milestone "boss_<kind>", which grows
# its bloom on the Families limb; in later runs its Warden is offered in the pick after that boss.
const MEMORY_BOSS_PREFIX := "boss_"
# The Memory Warden card's flavour line (screens_ui.md "Memory Warden card"), by Warden id.
const MEMORY_FLAVOUR := {
	"white_stag": "The Hollow Stag's light remembers you.",
	"pond_keeper": "The Mire Hag's still water remembers you.",
	"moon_moth": "The Moth Queen's moonlight remembers you.",
}

# Balance simulation: play the next run with a Grove profile preset (&"fresh" / &"early" / &"half" /
# &"full", GrovePresets) from a temp file; the real profile is untouched. GrovePresets.unload() undoes it.
static func load_preset(preset: StringName) -> String:
	return GrovePresets.load_preset(preset)

# A developer run (Test Grove, Unlock all families, Dev Grove or the Dream of everything toggle):
# nothing is banked or recorded.
static func is_dev_run() -> bool:
	return TestGrove.is_active() or all_families_active() or DevGrove.is_active() or all_dreams_dev_active() \
		or sixth_slot_dev_active()

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
var _bosses_this_run: Array[String] = []  # Boss kinds dispelled this run (Memory Warden milestones)
var memory_wardens := {}  # Boss kind -> its Memory Warden (TowerData), for blooms the Grove has grown

func _ready() -> void:
	active = not ResultsScreen.is_demo()
	records = active and get_tree().current_scene == owner and not is_dev_run()
	if DevGrove.is_active():
		_add_dev_tag.call_deferred()
	# Family Blessings are Rare Dream cards (meta_design.md "Replaced 2026-09-30"): one per family, offered
	# like any card once you own that family. MetaRun keeps them in the pool (their own folder).
	for blessing in load_blessings():
		if not dream_state.pool.has(blessing):
			dream_state.pool.append(blessing)
	if all_dreams_dev_active():  # Also in the demo build's debug runs
		dream_state.rerolls_left += ALL_DREAMS_REROLLS
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
		var kind: String = enemy.enemy_data.resource_path.get_file().get_basename()
		if kind == SHADE_KIND:
			_shades_this_run += 1
		if enemy.enemy_data.is_boss and not enemy.is_echo:  # Echoes (Remembering Oak) aren't bosses met
			_on_boss_dispelled(kind))
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
		if unlock.memory_warden != "":
			var warden := _family(unlock.memory_warden)
			if warden != null:
				memory_wardens[unlock.memory_boss] = warden
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
	if memory.milestones.has(ALL_DREAMS) and not all_dreams_dev_active():
		rerolls += ALL_DREAMS_REROLLS  # Dream of everything: on top of Second Thoughts
	if "rerolls_left" in dream_state:
		dream_state.rerolls_left += rerolls
	if "banishes_left" in dream_state:
		dream_state.banishes_left += banishes
	# Clear Sight's Heartwood's Reach, then Kindling's random Commons (a resumed run's save replaces them).
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
	if level >= 2:  # The first family pick gives no Dreamlight (was "starting Dew −20": drift 1 unwinnable)
		if "first_pick_dreamlight" in dream_state:
			dream_state.first_pick_dreamlight = 0
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
	for kind in _bosses_this_run:  # A first dispel grows that boss's Memory Warden bloom
		reached.append(MEMORY_BOSS_PREFIX + kind)
	for id in reached:
		if not memory.milestones.has(id):
			memory.milestones[id] = true
			HeartwoodMemory.grow_milestone_nodes(memory, id)  # Refunds a node it grows, if bought
	HeartwoodMemory.check_full_bloom(memory)  # Milestone blooms can complete the tree
	# Every milestone's cosmetic, including ones set elsewhere mid-run (Discover every combo: the Codex).
	for id in memory.milestones:
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

# "Dev Grove: Full" in a corner of the HUD, so a dev run is never mistaken for a real one.
func _add_dev_tag() -> void:
	var hud := owner.get_node_or_null("HUD") if owner else null
	if hud == null:
		return
	var tag := Label.new()
	tag.name = "DevGroveTag"
	tag.text = DevGrove.tag()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_color", Color(Palette.GOLD, 0.85))
	tag.add_theme_color_override("font_outline_color", Palette.VOID)
	tag.add_theme_constant_override("outline_size", 4)
	hud.add_child(tag)
	tag.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 6)

# A boss was dispelled: remember it for its Memory Warden milestone, and if the Grove has grown that
# boss's bloom, the pick after it can offer the Warden (FamilyPickScreen.pending_memory_warden).
func _on_boss_dispelled(kind: String) -> void:
	if not _bosses_this_run.has(kind):
		_bosses_this_run.append(kind)
	if memory_wardens.has(kind) and "pending_memory_warden" in family_screen:
		family_screen.pending_memory_warden = memory_wardens[kind]
