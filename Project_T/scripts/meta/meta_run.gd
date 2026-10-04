extends Node
class_name MetaRun

# Brings the meta (meta_design.md) into a run and back out:
# - Run start: the Memory Grove perks carried in the loadout (starting Dew, Dew gain, rest bonus,
#   max leaves, Dream rerolls / banishes / cards per offer, Omens, starting Dreams, Sprouts, free
#   Nurture, Seed bonus, Early Bloom), every owned node's families (family picks) and Dream cards
#   (pool), Family Blessings are made available, and the chosen Blight Level's modifiers.
# - Run end (the real full game only, never tests / Test Grove / the demo): lifetime counters,
#   milestones (each pays a one-time Seed bonus, RunState's Seed breakdown), the highest Blight Level won.
# The demo has no meta (demo_scope.md): nothing is applied or recorded there.

const TOWER_DIR := "res://resource/tower/"
const BLESSING_DIR := "res://resource/meta/blessing/"
const SHADE_KIND := "leaf_bug"
# Milestones only give bonus Seeds (meta_design.md "Milestones", user 2026-10-04): a one-time bonus at the run end
# it's reached, its own line in the Seed breakdown. Never a node, refund, cosmetic or Memory. Ids stay (Steam
# achievements). Balancing Discussion tunes the bonuses and thresholds here: id -> [Seeds, the results line].
const MILESTONE_SEEDS := {
	"first_boss": [20, "Dispel your first boss"],
	"first_win": [60, "Win a run"],
	"shades_500": [25, "Dispel 3,000 Shades"],
	"path_300": [30, "Build a 130-tile path"],
	"tend_100": [25, "Tend 120 obstacles"],
	"flawless_win": [100, "Win without losing a leaf"],
	"one_line_win": [80, "Win with only one Warden family"],
	"blight_5": [50, "Reach Blight Level 5"],
	"blight_10_win": [150, "Win at Blight Level 10"],
	"all_combos": [60, "Discover every combo"],
	"all_dreams": [60, "See every Dream card"],
	"all_nightmares": [40, "Meet every nightmare"],
}
const SHADES_MILESTONE := 3000  # Shades dispelled in total (id shades_500 kept)
const PATH_MILESTONE := 130  # Tiles in one run's longest path (id path_300 kept)
const TENDS_MILESTONE := 120  # Obstacles tended in total (id tend_100 kept)
const GROUP := &"meta_run"

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

# Dream offers' starlit card backs are parked (no longer the "See every Dream card" reward; art kept).
static func starlit_backs() -> bool:
	return false

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

# Spire experiment "sidegrade perks" (meta_design.md, experiment/spire-difficulty): Grove perks become
# trade-offs, not raw power. Same costs, levels and prerequisites; each carried perk keeps its upside and
# adds a downside (SIDEGRADE_*). Developer setting "Perk style" (0 Power / 1 Sidegrade); since the Spire merge
# (2026-10-02, Balancing Discussion) the full game defaults to Sidegrade, Power stays as the developer switch.
const PERK_STYLE_SETTING := "perk_style"
const SIDEGRADE_LEAF_CAP := 2  # Deep Taproot's leaves in sidegrade mode (its level III adds nothing more)
static var force_sidegrade := -1  # Tests: 0 Power, 1 Sidegrade, -1 = the setting

static func sidegrade_active() -> bool:
	if force_sidegrade >= 0:
		return force_sidegrade == 1
	return int(HeartwoodMemory.get_settings().get(PERK_STYLE_SETTING, 1)) == 1

# Clear Sight's sidegrade cost, read by the map generator before the run starts: one extra ridge (like
# Blight 9's) while it's carried. The full game only. A resumed run uses the count it was saved with
# (RunSaver sets `resumed_extra_ridges`), so changing the loadout in the Grove never reshapes a saved map.
static var resumed_extra_ridges := -1  # -1 = a new run: read the loadout
static var run_extra_ridges := 0  # What this run's map was built with (saved with the run)

static func perk_extra_ridges() -> int:
	run_extra_ridges = resumed_extra_ridges if resumed_extra_ridges >= 0 else _loadout_extra_ridges()
	return run_extra_ridges

static func _loadout_extra_ridges() -> int:
	if not sidegrade_active() or ResultsScreen.is_demo():
		return 0
	var memory := HeartwoodMemory.load_data()
	var unlock := HeartwoodMemory.get_unlock("clear_sight")
	if unlock == null or not HeartwoodMemory.get_loadout(memory).has("clear_sight") or HeartwoodMemory.node_level(memory, unlock) == 0:
		return 0
	return 1

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
	return TestGrove.is_active() or all_families_active() or DevGrove.is_active() \
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
var _milestones_at_start := {}  # The profile's milestones when the run began: only new ones pay
var _counters_at_start := {}
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
	var all_families := all_families_active() and not TestGrove.is_active()
	if not active:
		if all_families:  # Also in the demo build's debug runs
			_apply_all_families()
		return
	add_to_group(GROUP)
	var memory := HeartwoodMemory.load_data()
	_milestones_at_start = memory.milestones.duplicate()
	_counters_at_start = memory.counters.duplicate()
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
		leaves += unlock.max_leaves * (mini(level, SIDEGRADE_LEAF_CAP) if sidegrade_active() else level)  # Hades-style: Deep Taproot tops out at +2
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
		if unlock.wider_roots and "wider_roots" in dream_state:  # The first-picked family offers 3 (DreamState's draw)
			dream_state.wider_roots = true
		if sidegrade_active():
			dew += _apply_sidegrade(unlock.id, level)
	if dew >= 0:
		run_state.add_dew(dew)
	else:  # Sidegrade Sprout Bed: less starting Dew (add_dew ignores negatives)
		run_state.dew = maxi(run_state.dew + dew, 0)
		run_state.dew_changed.emit(run_state.dew)
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

# Sidegrade perks: the downside of carried perk `id` at `level`, on top of
# its normal effect. Returns the starting Dew it changes. Seed Pouch, Second Thoughts, Let Go, Omen Reader
# and the slots are unchanged.
# Hades-style (user, 2026-10-02): Morning Stores, Rested Roots and Deep Taproot stay honest power (Deep Taproot
# capped at +2 leaves, SIDEGRADE_LEAF_CAP), so struggling new players get a little help.
func _apply_sidegrade(id: String, level: int) -> int:
	match id:
		"rich_dew":  # Rest bonus −10% per level
			drift_director.rest_bonus_perk_multiplier -= 0.1 * level
		"sprout_bed":  # −30 starting Dew
			return -30
		"first_care":  # After the free ranks, Nurture costs +15% this run
			if "nurture_perk_multiplier" in dream_state:
				dream_state.nurture_perk_multiplier *= 1.15
		"early_bloom":  # The drift 25 family pick shows one fewer
			if "first_boss_pick_fewer" in family_screen:
				family_screen.first_boss_pick_fewer += 1
		"early_light":  # The first family pick gives no Dreamlight
			if "first_pick_dreamlight" in dream_state:
				dream_state.first_pick_dreamlight = 0
		"kindling":  # The first Dream offer has 2 cards
			if "first_offer_cards" in dream_state:
				dream_state.first_offer_cards = 2
		"wider_dreams":  # Let it pass gives no Dew
			dream_state.skip_dew = 0
		# clear_sight: one extra ridge, in the map generator (perk_extra_ridges)
	return 0

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
	for id in milestones_reached(won):  # Each one's Seeds are already in the breakdown (milestone_seed_lines)
		memory.milestones[id] = true
	for kind in _bosses_this_run:  # A first dispel records that boss (its Memory Warden bloom, parked)
		memory.milestones[MEMORY_BOSS_PREFIX + kind] = true
	if won:
		memory.highest_blight_won = maxi(int(memory.highest_blight_won), blight_level)
	HeartwoodMemory.save_data(memory)

# The milestones this run reaches for the first time, in MILESTONE_SEEDS order: the ones judged at run end (from
# the counters as they stood at run start plus this run) and the ones the Codex records mid-run (every combo,
# Dream card, nightmare). None outside real full-game runs. Pure: the Seed breakdown and the run end both ask.
func milestones_reached(won: bool) -> Array[String]:
	var result: Array[String] = []
	if not records:
		return result
	var now := {}
	if drift_director.bosses_cleansed > 0:
		now["first_boss"] = true
	if won:
		now["first_win"] = true
		if run_state.leaves_lost == 0:
			now["flawless_win"] = true
		if _one_family_only():
			now["one_line_win"] = true
		if blight_level >= 10:
			now["blight_10_win"] = true
	if int(_counters_at_start.get("shades_dispelled", 0)) + _shades_this_run >= SHADES_MILESTONE:
		now["shades_500"] = true
	if run_state.longest_path >= PATH_MILESTONE:
		now["path_300"] = true
	if int(_counters_at_start.get("tended_total", 0)) + run_state.obstacles_tended >= TENDS_MILESTONE:
		now["tend_100"] = true
	if blight_level >= 5:
		now["blight_5"] = true
	for id in HeartwoodMemory.load_data().milestones:  # Recorded mid-run by the Codex
		now[id] = true
	for id in MILESTONE_SEEDS:
		if now.has(id) and not _milestones_at_start.has(id):
			result.append(id)
	return result

# The Seed breakdown's milestone lines: [["Milestone · <name>", Seeds], …] (RunState.get_seed_breakdown).
func milestone_seed_lines(won: bool) -> Array:
	var lines: Array = []
	for id in milestones_reached(won):
		lines.append(["Milestone · %s" % MILESTONE_SEEDS[id][1], int(MILESTONE_SEEDS[id][0])])
	return lines

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
