extends Node
class_name DreamState

# Dreams (in-run upgrades, documentation/dream_design.md): which Wardens are unlocked this run,
# which cards were taken (stat cards stack), and the Dream offer at every rest (boss rests: Rare+).
# Wardens ask this node for their effective stats; the Dream screen shows `offer_ready` offers.
# Base Wardens come from the family pick (it sets `unlocked`), never from Dreams.

const GROUP := &"dream_state"
const DREAM_DIR := "res://resource/dream/"
# Rarity weights (Common, Uncommon, Rare, Legendary) by act.
const RARITY_WEIGHTS := [[65, 28, 7, 0], [50, 32, 15, 3], [38, 34, 22, 6]]
# Rule numbers: [base, Deepened (II)].
const COZY_CORNERS_BONUS := [0.15, 0.25]
const COZY_CORNERS_REACH := [1, 2]  # Tiles from a bend (orthogonal steps)
const HEDGE_PER_WALLS := [5, 4]
const HEDGE_BONUS_PER := 0.01
const HEDGE_BONUS_MAX := [0.20, 0.30]
const SPORE_CASCADE_TARGETS := [2, 3]
const TENDED_FOREST_PER_CLEAR := 0.01
const TENDED_FOREST_MAX := 0.25
const FERTILE_DISCOUNT := 0.5  # Reclaimed Earth: the first Warden on a cleared cell
const CLEARING_LOCKED_WEIGHT := 2.0  # Clearing cards are this much likelier until you own one
# Nurture and wide / narrow cards (dream_design.md). [base, Deepened (II)] where it deepens.
const NURTURE_DISCOUNT_MAX := 0.45
const BASE_MAX_RANK := 5
const EXTRA_RANK_COSTS := {6: 130, 7: 180}  # Deeper Rings, before the Warden's tier multiplier
const FREE_RANK_MAX := 7  # Free ranks (Sunlit Rest, seeds, The Old Ones) never go past VII
const ENDLESS_RANK_GROWTH := 1.2  # Endless Rings: each rank past VII costs ×1.2 the one before
const SEEPING_PER := [0.05, 0.07]
const SEEPING_MAX_STATUSES := 6
const VENOM_HIT_PENALTY := 0.15
const KINDRED_PER_RANK := [0.02, 0.03]
const KINDRED_MAX := [0.30, 0.45]
const MEMORY_SEEDS := [1, 2]  # Remembered Care keeps this many seeds
const SUNLIT_WARDENS := [1, 2]  # Sunlit Rest raises this many per rest
const CHOSEN_FEW_BONUS := 0.5  # Rank V+
const CHOSEN_FEW_PENALTY := 0.15  # Below rank III
const MANY_HANDS_PER := 4  # +1% per this many attacking Wardens
const MANY_HANDS_MAX := 0.25
const SPROUT_CHORUS_PER := 0.05
const SPROUT_CHORUS_MAX := 0.40
const CANOPY_STEPS: Array[int] = [20, 30, 40]  # Attacking Wardens planted this run
const CANOPY_BONUS := 0.08
const SOLITUDE_BONUS := 0.30
const SOLITUDE_RANGE := 0.5
const FEW_AND_MIGHTY_BELOW := 12
const FEW_AND_MIGHTY_PER := 0.08
const LAST_LIGHT_MAX := 5
const NEARBY_CELLS := 2  # "Within 2 cells" (Sprout Chorus, Solitude): Chebyshev distance
# Grove cards (dream_design.md 26–44): maze Legendaries and crit cards.
const LONG_WALK_PER := 0.01  # The Long Walk: +1% damage…
const LONG_WALK_TILES := 4  # …per this many path tiles
const MONOCULTURE_BONUS := 0.60
const ROOTBOUND_TOUCHING := 3
const STILL_TARGET_CRIT := [0.15, 0.25]
const STARLIT_AIM_CRIT := 0.25
const FULL_MOON_CRIT := 0.10
const RECKLESS_CRIT := 0.20
const RECKLESS_PENALTY := 0.15
# Build directions: owning one makes its tag count as a family (2×); wide and narrow halve each other.
const DIRECTION_TAGS: Array[String] = ["nurture", "wide", "narrow"]
const OPPOSITE_DIRECTION := {"wide": "narrow", "narrow": "wide"}
const OPPOSITE_WEIGHT := 0.5
# Passed-over cards fade (dream_design.md "How Dream offers work"): left out of the next offer, then
# weight ×0.6 per time passed this run (floor ×0.1); taking the card resets it.
const PASSED_FADE := 0.6
const PASSED_FLOOR := 0.1
const NO_CELL := Vector2(-1, -1)
# New Legendaries (dream_design.md "New Legendaries", 113–123).
const CROSSROADS_BONUS := 0.40
const CROSSROADS_STEPS := 6
const BRIAR_SHARE := 0.25
const BRIAR_COOLDOWN := 1.0  # Seconds, per wall per nightmare
const MENAGERIE_PER := 0.08
const MENAGERIE_MAX := 0.80
const RESTLESS_PER := 0.08
const RESTLESS_MAX := 0.40
const LAST_LEAF_PER := 0.06
const LAST_LEAF_MAX := 0.60
const LUCID_EXTRA_CARDS := 1  # 3 → 4
const LUCID_PICKS := 2
const COURT_SHARE := 0.25  # Of the Eldest's rank bonuses, for Wardens touching it
const HUNTERS_SPREAD := 2
const HUNTERS_RANGE := 3.0  # Cells
const HUNTERS_DURATION := 3600.0  # Marked "never expires" (EnemyStatuses keeps it; this is the fallback)
const WILDWOOD_BASE := 0.30
const WILDWOOD_PER_CLEAR := 0.02
const WILDWOOD_MAX := 0.60
# Dreamlight (run_design.md "Dreamlight"): sources and unlock costs.
const FIRST_PICK_DREAMLIGHT := 1
const BOSS_DREAMLIGHT := 3
const BRANCH_DREAMLIGHT := 1  # Branch, hidden branch, wall growth
const FINAL_DREAMLIGHT := 2  # Final form (needs its branch)
# Ascended forms (tower_design.md): tier 4, grown from any of the family's final forms.
const ASCENDED_TIER := 4
const ASCENDED_DREAMLIGHT := 3
const ASCENDED_FROM_DRIFT := 51  # Unlockable from the rest before drift 51
const SHARDS_PER_DREAMLIGHT := 10  # Great Dreamcatcher: shards from Caught nightmares
const SHARD_DREAMLIGHT_MAX := 2  # Per run
const NURSERY_RANK := 2  # Seedling Gift Sprouts with Nursery
# Wardens that hold nightmares in place (Held) without a freeze: the Rootling line's roots.
const HELD_SOURCES: Array[String] = ["tangleroot", "snugroot"]

signal unlocks_changed
signal card_taken(card: UpgradeData)
# A Dream is ready to be chosen (`cards` has up to 3). The Dream screen pauses and shows it.
signal offer_ready(cards: Array[UpgradeData], drift_number: int)
signal offer_closed
signal dreamlight_changed(dreamlight: int)
# The Eldest changed (null = the title is free). Tower Code shows its crown and panel line.
signal eldest_changed(tower: Tower)
# The Remember screen should open (after a boss's family pick, from the rest panel or the Warden
# panel). `focus` = the form to highlight, or null.
signal remember_requested(focus: TowerData)

@export var pool: Array[UpgradeData] = []  # Empty = every card in res://resource/dream/
@export var starting_unlocks: Array[String] = ["sprout", "thornwall"]
@export var unlock_everything: bool = false  # Debug/tests: every Warden and evolution available
@export var cards_per_offer: int = 3
@export var skip_dew: int = 15  # "Let it pass"
@export var tag_weight: float = 2.0  # Cards tagged with a line you own are this much likelier
@export var pity_after: int = 3  # Dreams in a row without Rare+ before one is guaranteed
# Bittersweet cards stay out of the pool until leaves are tuned (dream_design.md). Act 2+ only,
# at most one per offer.
@export var allow_bittersweet: bool = false
# Blight Level 8 ("Dream offers lean Common"): half of the Rare+ weight goes to Common.
@export var lean_common: bool = false

# Memory Grove (set at run start by MetaRun): Grove cards owned (in_start_pool = false cards that
# may now be offered), Dream rerolls (Second Thoughts) and banishes (Let Go) left this run.
var grove_cards: Array[String] = []
# Clearing obstacles is locked until a clearing Dream is taken (dream_design.md "Clearing cards");
# Test Grove and tests open it from the start.
var clearing_open := false
var rerolls_left := 0
var banishes_left := 0

var unlocked := {}  # Warden id -> true
var stacks := {}  # Card id -> times taken
var dreams_seen := 0
# Dreamlight (run_design.md): spent to unlock branches, final forms and wall growths for the run.
var dreamlight := 0
var dreamlight_shards := 0  # Shards gathered this run (Great Dreamcatcher)
var _remember_open := false  # The boss-rest Remember screen is open: the Dream waits for it
var current_offer: Array[UpgradeData] = []
var current_offer_drift := 0

var _dreams_without_rare := 0
var _rare_dreams_left := 0  # Restless Dreams / Omens: the next N offers each include a Rare+
var _extra_cards_next := 0  # Omens (Thick Blight): the next offer has this many more cards
var _entwined_offered := {}  # Entwined card id -> true once its guaranteed offer happened
var _banished := {}  # Card id -> true: Let Go took it out of this run's pool
var _passed_count := {}  # Card id -> times offered and not taken this run
var _passed_at := {}  # Card id -> the offer number (dreams_seen) it was last passed over in
var _taken_this_offer: Array[String] = []
var _guaranteed_id := ""  # The Entwined guaranteed card of the current offer (never fades)
var _before_offer := {}  # Offer counters from before the current offer (a reroll rolls them back)
var _attackers_planted := 0  # Attacking Wardens planted this run (Canopy)
var picks_left := 1  # Cards still to take from the current offer (Lucid Dreaming: 2)
var _early_calls := 0  # Drifts called early this block (Restless Night)
var _path_index := {}  # Route cell -> its step along the route (Crossroads, Briar Crown)
var _eldest_cell := NO_CELL  # The Eldest's cell (NO_CELL = no Eldest yet)
var _court_pending := false  # Court of the Eldest with nothing ranked: the next nurtured one
var _briar_clock := 0.0
var _briar_cells := {}  # Nightmare instance id -> the cell it was last seen on (Briar Crown)
var _briar_hits := {}  # "nightmare id:wall id" -> clock of its last Briar Crown hit
var _pending_drifts: Array[int] = []
var _bend_cells := {}  # Path cells where the route turns (Cozy Corners)
var path_length := 0  # Tiles in the current route (The Long Walk); updated with the bends
var _rng := RandomNumberGenerator.new()
var _effects: DreamEffects = null  # effects(): card rows per Warden

@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer
@onready var spawner = %EnemyContainer

func _ready() -> void:
	add_to_group(GROUP)
	_rng.randomize()
	if pool.is_empty():
		pool = load_pool()
	for id in starting_unlocks:
		unlocked[id] = true
	drift_director.rest_started.connect(_on_rest_started)
	drift_director.family_pick_requested.connect(func(reason: StringName) -> void:
		if reason == &"first":
			add_dreamlight(FIRST_PICK_DREAMLIGHT))  # Act 1 can take one branch
	map_generator.path_changed.connect(_update_bends)
	spawner.enemy_cleansed.connect(_on_enemy_cleansed)
	map_generator.obstacle_cleared.connect(_on_obstacle_cleared)
	var placer := get_node_or_null("%TowerPlacer")
	if placer:
		placer.tower_built.connect(_on_tower_built)
	var seller := get_node_or_null("%TowerSeller")
	if seller:
		seller.tower_sold.connect(_on_tower_sold)
	drift_director.drift_started.connect(_on_drift_started)
	_update_bends()

static func load_pool() -> Array[UpgradeData]:
	var cards: Array[UpgradeData] = []
	# list_directory also sees resources in exported builds (where files are remapped).
	for file in ResourceLoader.list_directory(DREAM_DIR):
		var path: String = DREAM_DIR + file
		if path.ends_with(".tres") or path.ends_with(".res"):
			var card := load(path) as UpgradeData
			if card != null:
				cards.append(card)
	return cards


# --- Unlocks and costs ------------------------------------------------------------------------------

func is_unlocked(warden_id: String) -> bool:
	return unlock_everything or unlocked.has(warden_id)

func has_card(card_id: String) -> bool:
	return stacks.get(card_id, 0) > 0

func card_stacks(card_id: String) -> int:
	return stacks.get(card_id, 0)

# Warden ids and card ids the player owns (for card prerequisites).
func owns(id: String) -> bool:
	return is_unlocked(id) or has_card(id)

# Wardens that can be planted from the tower bar right now.
func is_buildable(data: TowerData) -> bool:
	return data.buildable_directly and is_unlocked(data.get_id())

# Discounts (Cheap Hedges) take the cheapest; a surcharge (Hungry Roots) wins over them.
func get_build_cost(data: TowerData) -> int:
	var cost := data.cost
	var surcharge := 0
	for card in _taken_cards():
		if card.set_cost_warden != data.get_id():
			continue
		if card.set_cost < data.cost:
			cost = mini(cost, card.set_cost)
		else:
			surcharge = maxi(surcharge, card.set_cost)
	cost = maxi(cost, surcharge)
	var plant_discount := 0.0
	for card in _taken_cards():
		plant_discount += card.plant_discount * stacks[card.id]
	if plant_discount > 0.0:
		cost = maxi(roundi(cost * maxf(1.0 - plant_discount, 0.0)), 1)  # Wild Growth
	return cost

# Discounts apply to the Warden grown into, if the card covers its line (Family Blessings: one family).
func get_evolve_cost(to: TowerData) -> int:
	var discount := 0.0
	for card in _taken_cards():
		if _applies_to(card, to):
			discount += card.evolve_discount * stacks[card.id]
	return roundi(to.evolve_cost * maxf(1.0 - discount, 0.0))

# --- Dreamlight (run_design.md "Dreamlight: choosing your build paths") -------------------------------

func add_dreamlight(amount: int) -> void:
	dreamlight = maxi(dreamlight + amount, 0)
	dreamlight_changed.emit(dreamlight)

# Great Dreamcatcher: one shard per Caught nightmare dispelled; 10 shards = 1 Dreamlight, at most
# 2 Dreamlight a run this way.
func add_dreamlight_shard() -> void:
	if dreamlight_shards >= SHARDS_PER_DREAMLIGHT * SHARD_DREAMLIGHT_MAX:
		return
	dreamlight_shards += 1
	if dreamlight_shards % SHARDS_PER_DREAMLIGHT == 0:
		add_dreamlight(1)

# Dreamlight to unlock `data` for the run: 1 for a branch, hidden branch or wall growth, 2 for a
# final form. 0 = already unlocked.
func get_unlock_cost(data: TowerData) -> int:
	if is_unlocked(data.get_id()):
		return 0
	if data.tier >= ASCENDED_TIER:
		return ASCENDED_DREAMLIGHT
	return FINAL_DREAMLIGHT if data.tier >= 3 else BRANCH_DREAMLIGHT

# Why `data` can't be unlocked yet ("" = it can, given enough Dreamlight): its parent form isn't
# unlocked, or it's a hidden branch the Memory Grove hasn't opened. Ascended forms: from drift 51,
# once the family has any final form, and with the Grove's Ascension node.
func get_unlock_blocker(data: TowerData) -> String:
	if data.buildable_directly:
		return "family pick"  # Base families (and Memory Wardens) aren't bought with Dreamlight
	if data.tier >= ASCENDED_TIER:
		if drift_director.drifts_started + 1 < ASCENDED_FROM_DRIFT:
			return "from drift %d" % ASCENDED_FROM_DRIFT
		if not _has_unlocked_final(data):
			return "needs a final form"
	var parent := get_parent_form(data) if data.tier < ASCENDED_TIER else null
	if parent != null and not is_unlocked(parent.get_id()):
		return "needs %s" % parent.display_name
	var card := _unlock_card_for(data)
	if card != null and not (card.in_start_pool or grove_cards.has(card.id)):
		return "Memory Grove"
	return ""

func can_unlock(data: TowerData) -> bool:
	var cost := get_unlock_cost(data)
	return cost > 0 and cost <= dreamlight and get_unlock_blocker(data) == ""

# Spends Dreamlight to make `data` available for the run (evolving each Warden still costs Dew).
func unlock_with_dreamlight(data: TowerData) -> bool:
	if not can_unlock(data):
		return false
	add_dreamlight(-get_unlock_cost(data))
	unlocked[data.get_id()] = true
	unlocks_changed.emit()
	return true

# Opens the Remember screen (the rest panel's button, the Warden panel's locked forms).
func open_remember(focus: TowerData = null) -> void:
	remember_requested.emit(focus)

# The Remember screen closed: a Dream waiting behind the boss-rest Remember screen can show now.
func remember_closed() -> void:
	if _remember_open:
		_remember_open = false
		_show_next_offer.call_deferred()

# The form `data` grows from (the Warden whose evolves_to has it), or null.
func get_parent_form(data: TowerData) -> TowerData:
	for card in pool:
		if card.unlocks != null and card.unlocks.evolves_to.has(data):
			return card.unlocks
	for tower in _roster():
		if tower.evolves_to.has(data):
			return tower
	return null

# The old unlock card for a form (hidden branches' cards are Grove-only), or null.
func _unlock_card_for(data: TowerData) -> UpgradeData:
	for card in pool:
		if card.unlocks == data:
			return card
	return null

# Plantable Wardens (the tower bar's roster).
func _roster() -> Array:
	var placer := get_node_or_null("%TowerPlacer")
	return placer.towers if placer else []

# The Remember screen's trees: [[root TowerData, [[branch, [finals...]], ...]], ...] for each owned
# family, plus Thornwall's wall growths.
func get_remember_trees() -> Array:
	var trees := []
	for root in _roster():
		var is_family: bool = root.tier == 1 and root.buildable_directly and is_unlocked(root.get_id())
		var is_wall: bool = root.line == "wall" and is_unlocked(root.get_id())
		if not (is_family or is_wall) or root.evolves_to.is_empty():
			continue
		var branches := []
		var ascended: TowerData = null
		for branch in root.evolves_to:
			var finals := []
			for final in branch.evolves_to:
				finals.append(final)
				for next in final.evolves_to:
					if next.tier >= ASCENDED_TIER:
						ascended = next
			branches.append([branch, finals])
		trees.append([root, branches, ascended])  # ascended: the family's Ascended form, or null
	return trees

# Whether any final form that grows into Ascended `data` is unlocked this run.
func _has_unlocked_final(data: TowerData) -> bool:
	var forms := _roster().duplicate()
	for card in pool:
		if card.unlocks != null:
			forms.append(card.unlocks)
	for form in forms:
		if form.tier == 3 and form.evolves_to.has(data) and is_unlocked(form.get_id()):
			return true
	return false

# `data`'s evolutions this run: [[TowerData, available: bool], ...].
func get_evolutions(data: TowerData) -> Array:
	var result: Array = []
	for next in data.evolves_to:
		result.append([next, is_unlocked(next.get_id())])
	return result


# --- Stats for Wardens --------------------------------------------------------------------------------

# Dream stat bonuses are sums of DreamEffects rows (the same rows the Warden panel and ghost show):
# plain stat cards from their fields, rule cards from their reporters.
func get_soothe_multiplier(tower: Tower) -> float:
	return 1.0 + _sum_stat(tower.tower_data, "soothe_bonus") + effects().rule_total(DreamEffects.spot_for(tower), "damage")

# Per-Warden attack speed from Dreams (Tower adds it to its multiplier): Sprout Chorus, The Last
# Light, Rootbound.
func get_tower_attack_speed_bonus(tower: Tower) -> float:
	return effects().rule_total(DreamEffects.spot_for(tower), "speed")

# The card reporter (built on first use).
func effects() -> DreamEffects:
	if _effects == null:
		_effects = DreamEffects.new(self)
	return _effects

# "Dream bonuses on Wardens" (screens_ui.md): every taken card touching `data` on `cell` (see
# DreamEffects for the row fields). `tower` = that planted Warden; null = a hypothetical one (the
# build ghost; whatever stands on `cell` is ignored). `ghost` {cell, data} = pretend one more Warden
# stands there (a ghost's effect on a planted Warden's cards).
func get_card_effects(data: TowerData, cell: Vector2, tower: Tower = null, ghost: Dictionary = {}) -> Array[Dictionary]:
	return effects().rows(DreamEffects.spot_at(data, cell, tower), ghost)

# Dream parts of one stat ("damage", "attack_speed", "range", "cost") for a Warden: {base, final,
# parts: [{name, amount, card}]} with amounts as fractions (damage, speed), cells (range) or Dew
# (cost). Only Dreams: Nurture and Focus come from Tower. base = the TowerData value.
func get_stat_parts(data: TowerData, cell: Vector2, stat: String, tower: Tower = null, ghost: Dictionary = {}) -> Dictionary:
	var key: String = DreamEffects.STAT_KEYS.get(StringName(stat), stat)
	var parts := []
	var total := 0.0
	for row in get_card_effects(data, cell, tower, ghost):
		if row.active and row.get(key, 0) != 0:
			parts.append({"name": row.name, "amount": row[key], "card": row.card})
			total += row[key]
	var base: float
	var final: float
	match key:
		"damage":
			base = data.damage
			final = base * (1.0 + total)
		"speed":
			base = data.attacks_per_second
			final = base * (1.0 + total)
		"range":
			base = data.attack_range
			final = base + total
		_:
			base = data.cost
			final = get_build_cost_at(data, cell) if tower == null else get_build_cost(data)
	return {"base": base, "final": final, "parts": parts}

# The largest area (cells) of any taken card, so the ghost knows how far its effect on others reaches.
func max_card_radius() -> float:
	var radius := 0.0
	for card in _taken_cards():
		match card.rule_id:
			&"cozy_corners":
				radius = maxf(radius, COZY_CORNERS_REACH[rule_level(&"cozy_corners")])
			&"solitude", &"sprout_chorus":
				radius = maxf(radius, NEARBY_CELLS)
			&"kindred_roots", &"rootbound", &"court_of_the_eldest", &"old_ones", &"crossroads":
				radius = maxf(radius, 1.0)
	return radius

# Range from Dreams for `data` planted on `cell` (card fields + Solitude), for the ghost's circle.
func get_range_bonus_at(data: TowerData, cell: Vector2, ghost: Dictionary = {}) -> float:
	return get_range_bonus(data) + effects().rule_total(DreamEffects.spot_at(data, cell), "range", ghost)

# Solitude's check for a hypothetical `data` on `cell` (whatever stands there is ignored).
func is_solitary_at(data: TowerData, cell: Vector2, ghost: Dictionary = {}) -> bool:
	if not data.can_attack:
		return false
	var spot := DreamEffects.spot_at(data, cell)
	for other in effects()._others(spot, ghost):
		if other.data.can_attack and DreamEffects._cheb(other.cell, cell) <= NEARBY_CELLS:
			return false
	return true

# Monoculture: every attacking Warden is of one line.
func is_monoculture() -> bool:
	var lines := {}
	for tower in _towers():
		if tower.tower_data.can_attack:
			lines[tower.tower_data.line] = true
	return lines.size() == 1

# --- Crits from Dreams (Tower adds these in its crit roll) --------------------------------------------

# Extra crit chance for `tower` against `enemy` (null = no target): Still Target (Drowsy / Held),
# Starlit Aim (Marked), Full Moon, Reckless Bloom.
func get_crit_chance_bonus(_tower: Tower, enemy: Node2D = null) -> float:
	var bonus := 0.0
	if has_rule(&"full_moon"):
		bonus += FULL_MOON_CRIT
	if has_rule(&"reckless_bloom"):
		bonus += RECKLESS_CRIT
	if enemy != null and is_instance_valid(enemy):
		if has_rule(&"still_target") and (enemy.statuses.has(EnemyStatuses.DROWSY) or enemy.statuses.is_held()):
			bonus += STILL_TARGET_CRIT[rule_level(&"still_target")]
		if has_rule(&"starlit_aim") and enemy.statuses.has(EnemyStatuses.MARKED):
			bonus += STARLIT_AIM_CRIT
	return bonus

# Full Moon: crit chance above 100% (`raw_chance` before capping) becomes extra crit multiplier.
func get_crit_overflow_multiplier(raw_chance: float) -> float:
	return maxf(raw_chance - 1.0, 0.0) if has_rule(&"full_moon") else 0.0

# Reckless Bloom (bittersweet): hits that don't crit deal this much of their damage.
func get_non_crit_multiplier() -> float:
	return 1.0 - RECKLESS_PENALTY if has_rule(&"reckless_bloom") else 1.0

# Per-Warden range from Dreams, in cells (Tower adds it): Solitude.
func get_tower_range_bonus(tower: Tower) -> float:
	return effects().rule_total(DreamEffects.spot_for(tower), "range")

# Solitude: an attacking Warden with no other attacking Warden within 2 cells.
func is_solitary(tower: Tower) -> bool:
	return is_solitary_at(tower.tower_data, tower.cell) if tower.tower_data.can_attack else false

func canopy_steps_reached() -> int:
	var steps := 0
	for step in CANOPY_STEPS:
		if _attackers_planted >= step:
			steps += 1
	return steps

# Attacking Wardens on the map (Thornwalls never count).
func count_attackers() -> int:
	var count := 0
	for tower in _towers():
		if tower.tower_data.can_attack:
			count += 1
	return count

func count_wardens(warden_id: String) -> int:
	var count := 0
	for tower in _towers():
		if tower.tower_data.get_id() == warden_id:
			count += 1
	return count

# Wardens at `min_rank` or higher.
func count_ranked(min_rank: int) -> int:
	var count := 0
	for tower in _towers():
		if tower.rank >= min_rank:
			count += 1
	return count

func _towers() -> Array[Tower]:
	var result: Array[Tower] = []
	for child in tower_container.get_children():
		if child is Tower and not child.is_queued_for_deletion():
			result.append(child)
	return result

# Wardens sharing an edge with `tower`.
# --- The Eldest (dream_design.md "The Eldest") ----------------------------------------------------------
# Ranks above V belong to one Warden per run. Tower asks get_max_rank_for(tower); when a Warden at
# rank V would buy VI and there's no Eldest yet, its panel confirms, then calls make_eldest(tower).

func eldest_available() -> bool:
	return get_max_rank() > BASE_MAX_RANK or has_rule(&"court_of_the_eldest")

func get_eldest() -> Tower:
	if _eldest_cell == NO_CELL:
		return null
	for tower in _towers():
		if tower.cell == _eldest_cell:
			return tower
	return null

func is_eldest(tower: Tower) -> bool:
	return tower != null and _eldest_cell != NO_CELL and tower.cell == _eldest_cell

# `tower`'s rank cap: past V only for the Eldest (or anyone, until there's an Eldest: buying VI names it).
func get_max_rank_for(tower: Tower) -> int:
	var cap := get_max_rank()
	if cap <= BASE_MAX_RANK or tower == null:
		return cap
	var eldest := get_eldest()
	return cap if eldest == null or eldest == tower else BASE_MAX_RANK

# Buying rank VI for `tower` would make it the Eldest (the panel asks first).
func needs_eldest_confirm(tower: Tower) -> bool:
	return tower != null and tower.rank == BASE_MAX_RANK and get_max_rank() > BASE_MAX_RANK and get_eldest() == null

func make_eldest(tower: Tower) -> bool:
	var eldest := get_eldest()
	if tower == null or (eldest != null and eldest != tower):
		return false
	set_eldest(tower)
	return true

# Sets (or clears, with null) the Eldest. Selling it frees the title (its ranks above V go with it).
func set_eldest(tower: Tower) -> void:
	_eldest_cell = tower.cell if tower != null else NO_CELL
	_court_pending = _court_pending and tower == null
	eldest_changed.emit(tower)

# Court of the Eldest: the highest-rank Warden becomes the Eldest now (ties: nearest the Heartwood);
# with nothing ranked, the next Warden nurtured.
func _crown_court_eldest() -> void:
	if get_eldest() != null:
		return
	var ranked: Array = _towers().filter(func(t: Tower) -> bool: return t.rank > 0)
	if ranked.is_empty():
		_court_pending = true
		for tower in _towers():
			_watch_nurture(tower)
		return
	var seller := get_node_or_null("%TowerSeller")
	if seller and seller.has_method("sort_by_heartwood"):
		ranked = seller.sort_by_heartwood(ranked)
	var best: Tower = ranked[0]
	for tower in ranked:
		if tower.rank > best.rank:
			best = tower
	set_eldest(best)

func _watch_nurture(tower: Tower) -> void:
	if tower.has_signal("nurtured") and not tower.nurtured.is_connected(_on_tower_nurtured):
		tower.nurtured.connect(_on_tower_nurtured)

func _on_tower_nurtured(tower: Tower) -> void:
	if _court_pending and get_eldest() == null and is_instance_valid(tower):
		set_eldest(tower)

# Court of the Eldest: rank-equivalents a Warden touching the Eldest gets (25% of its rank), for
# Tower's per-rank damage, attack speed and range (not the Focus).
func get_court_rank_share(tower: Tower) -> float:
	if not has_rule(&"court_of_the_eldest"):
		return 0.0
	var eldest := get_eldest()
	if eldest == null or eldest == tower or not _touching(tower).has(eldest):
		return 0.0
	return COURT_SHARE * eldest.rank


# --- New Legendaries: damage ------------------------------------------------------------------------

# Crossroads: +40% for a Warden touching two route tiles at least 6 steps apart (0 otherwise).
func get_crossroads_bonus(tower: Tower) -> float:
	return CROSSROADS_BONUS if tower.tower_data.can_attack and crossroads_at(tower.cell) else 0.0

# Whether `cell` touches two route tiles at least CROSSROADS_STEPS apart along the route.
func crossroads_at(cell: Vector2) -> bool:
	var low := 1 << 30
	var high := -1
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var step: int = _path_index.get(cell + Vector2(dx, dy), -1)
			if step >= 0:
				low = mini(low, step)
				high = maxi(high, step)
	return high - low >= CROSSROADS_STEPS

# Restless Night: a real call early = the previous drift was still arriving.
func _on_drift_started(number: int) -> void:
	if number > 1 and drift_director._arriving.has(number - 1):
		_early_calls += 1

# Briar Crown: a nightmare stepping onto a route tile beside a wall takes 25% of the strongest
# attacking Warden touching that wall (its line, area, no crit; once per wall per nightmare per s).
func _process(delta: float) -> void:
	if get_tree().paused or not has_rule(&"briar_crown"):
		return
	_briar_clock += delta
	for enemy in spawner.get_enemies():
		var id: int = enemy.get_instance_id()
		var cell: Vector2 = enemy.get_current_cell()
		if _briar_cells.get(id) == cell:
			continue
		_briar_cells[id] = cell
		if _path_index.has(cell):
			_briar_strike(enemy, cell)
	if _briar_cells.size() > 512:
		_briar_cells.clear()  # Forget long-gone nightmares now and then
		_briar_hits.clear()

func _briar_strike(enemy: Node2D, cell: Vector2) -> void:
	for wall in _towers():
		if wall.tower_data.line != "wall" or absf(wall.cell.x - cell.x) + absf(wall.cell.y - cell.y) != 1.0:
			continue
		var key := "%d:%d" % [enemy.get_instance_id(), wall.get_instance_id()]
		if _briar_clock - _briar_hits.get(key, -INF) < BRIAR_COOLDOWN:
			continue
		var strongest: Tower = null
		for other in _touching(wall):
			if other.tower_data.can_attack and (strongest == null or other.get_damage() > strongest.get_damage()):
				strongest = other
		if strongest == null:
			continue
		_briar_hits[key] = _briar_clock
		enemy.take_damage(strongest.get_damage() * BRIAR_SHARE, strongest.tower_data.line, true, false,
			strongest, &"briar_crown")
		if enemy.is_cleansed:
			return

# Hunter's Moon: a dispelled Marked nightmare Marks the 2 nearest within 3 cells.
func _hunters_spread(enemy: Node2D) -> void:
	if not has_rule(&"hunters_moon") or not enemy.statuses.has(EnemyStatuses.MARKED):
		return
	var reach: float = HUNTERS_RANGE * map_generator.MAP_GRID.cell_size.x
	var others := get_tree().get_nodes_in_group(Tower.ENEMY_GROUP).filter(func(e: Node2D) -> bool:
		return e != enemy and e.global_position.distance_to(enemy.global_position) <= reach)
	others.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(enemy.global_position) \
			< b.global_position.distance_squared_to(enemy.global_position))
	for i in mini(HUNTERS_SPREAD, others.size()):
		others[i].apply_status(EnemyStatuses.MARKED, 1, HUNTERS_DURATION, 0.0, 0, "",
			enemy.statuses.source(EnemyStatuses.MARKED))

# Wardens touching `tower`: the 8 cells around it (dream_design.md, as for Rootbound).
func _touching(tower: Tower) -> Array[Tower]:
	var result: Array[Tower] = []
	for other in _towers():
		if other != tower and maxf(absf(other.cell.x - tower.cell.x), absf(other.cell.y - tower.cell.y)) == 1.0:
			result.append(other)
	return result

# Other attacking Wardens within `cells` (Chebyshev distance).
func _attackers_near(tower: Tower, cells: int) -> Array[Tower]:
	var result: Array[Tower] = []
	for other in _towers():
		if other != tower and other.tower_data.can_attack \
				and maxf(absf(other.cell.x - tower.cell.x), absf(other.cell.y - tower.cell.y)) <= cells:
			result.append(other)
	return result


# --- Nurture ranks (Tower reads these; warden_stats.md "Ranks: Nurture") ------------------------------

# Multiplies the Dew for a rank: Tender Care (−15% per stack, max −45%), Nursery (Sprouts half price).
func get_nurture_cost_multiplier(tower: Tower = null) -> float:
	var discount := 0.0
	for card in _taken_cards():
		discount += card.nurture_discount * stacks[card.id]
	var multiplier := 1.0 - minf(discount, NURTURE_DISCOUNT_MAX)
	if has_rule(&"nursery") and tower != null and tower.tower_data.get_id() == "sprout":
		multiplier *= 0.5
	return multiplier

# Extra damage per rank on top of the base (Warm Hands).
func get_rank_damage_bonus() -> float:
	var bonus := 0.0
	for card in _taken_cards():
		bonus += card.rank_damage_bonus * stacks[card.id]
	return bonus

# Crit chance per rank (The Old Ones).
func get_rank_crit_bonus() -> float:
	var bonus := 0.0
	for card in _taken_cards():
		bonus += card.rank_crit_bonus * stacks[card.id]
	return bonus

# Highest rank: 5, raised by Deeper Rings (7), capped by Wild Growth (1; a cap wins over a raise).
func get_max_rank() -> int:
	var raised := BASE_MAX_RANK
	var capped := BASE_MAX_RANK
	for card in _taken_cards():
		if card.max_rank_set > BASE_MAX_RANK:
			raised = maxi(raised, card.max_rank_set)
		elif card.max_rank_set > 0:
			capped = mini(capped, card.max_rank_set)
	return capped if capped < BASE_MAX_RANK else raised

# Base Dew for rank `rank` (the one being bought) above V, before the tier multiplier; 0 = not allowed.
func get_extra_rank_cost(rank: int) -> int:
	if rank > get_max_rank():
		return 0
	if rank > FREE_RANK_MAX:  # Endless Rings: each rank ×1.2 the one before (VIII 216, IX 259, …)
		return roundi(EXTRA_RANK_COSTS[FREE_RANK_MAX] * pow(ENDLESS_RANK_GROWTH, rank - FREE_RANK_MAX))
	return EXTRA_RANK_COSTS.get(rank, 0)

# The rank a Warden's stats use: The Old Ones counts one higher beside a rank V+ Warden (stats only;
# it never chains, since it reads real ranks).
func get_effective_rank(tower: Tower) -> int:
	if has_rule(&"old_ones") and tower.rank > 0 and tower.rank < FREE_RANK_MAX:  # Never lifts past VII
		for other in _touching(tower):
			if other.rank >= 5:
				return tower.rank + 1
	return tower.rank

# A short live value for a card's icon in the Dreams row ("" = none): Few and Mighty, The Last
# Light, Many Hands, Canopy.
func get_live_bonus_text(card: UpgradeData) -> String:
	match card.rule_id:
		&"few_and_mighty":
			return "+%d%%" % roundi(100 * FEW_AND_MIGHTY_PER * maxi(FEW_AND_MIGHTY_BELOW - count_attackers(), 0))
		&"last_light":
			return "×2" if count_attackers() <= LAST_LIGHT_MAX else "off"
		&"many_hands":
			return "+%d%%" % roundi(100 * minf(0.01 * (count_attackers() / MANY_HANDS_PER), MANY_HANDS_MAX))
		&"canopy":
			return "+%d%%" % roundi(100 * CANOPY_BONUS * canopy_steps_reached())
	return ""

func get_attack_speed_multiplier(data: TowerData) -> float:
	return 1.0 + _sum_stat(data, "attack_speed_bonus")

func get_range_bonus(data: TowerData) -> float:
	return _sum_stat(data, "range_bonus")

func get_splash_multiplier(data: TowerData) -> float:
	return 1.0 + _sum_stat(data, "splash_bonus")

# Potency from Dreams (Bitter Sap, Venom Bloom, Nightshade), added to the Warden's 100%.
func get_potency_bonus(data: TowerData) -> float:
	return _sum_stat(data, "potency_bonus")

# Seeping: effect damage (Spored ticks, bolts, clouds, Reactions…) +5% per status `enemy` carries
# (II: +7%), capped at 6 statuses. 0 without the card.
func get_effect_bonus(enemy: Node2D) -> float:
	if not has_rule(&"seeping") or enemy == null or not is_instance_valid(enemy):
		return 0.0
	var level := rule_level(&"seeping")
	return minf(SEEPING_PER[level] * enemy.statuses.active_ids().size(), SEEPING_PER[level] * SEEPING_MAX_STATUSES)

# Venom Bloom (bittersweet): every hit (not effects) deals this much of its damage.
func get_hit_damage_multiplier() -> float:
	return 1.0 - VENOM_HIT_PENALTY if has_rule(&"venom_bloom") else 1.0

func get_status_strength_multiplier(status: StringName) -> float:
	var bonus := 0.0
	for card in _taken_cards():
		if card.status_id == status:
			bonus += card.status_strength_bonus * stacks[card.id]
	return 1.0 + bonus

# Duration of `status` when `data` applies it (its own duration or the default, plus Dreams).
func get_status_duration(data: TowerData, status: StringName) -> float:
	var duration: float = data.status_duration if data.status_duration > 0.0 else EnemyStatuses.DEFAULT_DURATION[status]
	var multiplier := 1.0
	for card in _taken_cards():
		if card.status_id != status or not _applies_to(card, data):
			continue
		duration += card.status_duration_add * stacks[card.id]
		multiplier *= pow(card.status_duration_multiplier, stacks[card.id])
	return duration * multiplier

# Stack cap of `status` when `data` applies it: its own cap (0 = the status default) plus Dreams
# (Lingering Spores II). 0 when no Dream changes it, so the Warden's own rule applies.
func get_status_max_stacks(data: TowerData, status: StringName) -> int:
	var extra := 0
	for card in _taken_cards():
		if card.status_id == status and _applies_to(card, data):
			extra += card.status_max_stacks_add * stacks[card.id]
	if extra == 0:
		return data.status_max_stacks
	var base: int = data.status_max_stacks if data.status_max_stacks > 0 else EnemyStatuses.DEFAULT_MAX_STACKS[status]
	return base + extra

func has_rule(rule: StringName) -> bool:
	for card in _taken_cards():
		if card.rule_id == rule:
			return true
	return false

# Stacks taken of the cards with rule `rule` (stacking rule cards: Hush, Sharp Beaks, Longer Flight).
func rule_stacks(rule: StringName) -> int:
	var total := 0
	for card in _taken_cards():
		if card.rule_id == rule:
			total += stacks[card.id]
	return total

# 0 = the base rule, 1 = its Deepened (II) version (index into the rule-number constants).
func rule_level(rule: StringName) -> int:
	for card in _taken_cards():
		if card.rule_id == rule and card.is_deepened():
			return 1
	return 0

func get_dew_per_clear() -> int:
	var dew := 0
	for card in _taken_cards():
		dew += card.dew_per_clear * stacks[card.id]
	return dew

# Added to every rest (drift-clear) bonus; negative after Borrowed Dew. The bonus never goes below 0.
func get_rest_bonus_add() -> int:
	var add := 0
	for card in _taken_cards():
		add += card.rest_bonus_add * stacks[card.id]
	return add

# Dew to clear `data` (Cleared Ground: −40% per stack, never below 1 Dew).
func get_clear_cost(data: ObstacleData) -> int:
	var discount := 0.0
	for card in _taken_cards():
		discount += card.clear_discount * stacks[card.id]
	return maxi(roundi(data.clear_cost * maxf(1.0 - discount, 0.0)), 1)

# Cost to plant `data` on `cell`: a Seedling Gift charge makes a Sprout free; Reclaimed Earth halves
# the first Warden on a fertile cell.
func get_build_cost_at(data: TowerData, cell: Vector2) -> int:
	if data.get_id() == "sprout" and run_state.sprout_charges > 0:
		return 0  # The charge is used in _on_tower_built
	var cost := get_build_cost(data)
	if run_state.fertile_cells.has(cell):
		cost = roundi(cost * FERTILE_DISCOUNT)
	return cost

# Nightmare speed multiplier from Dreams (Burn Back the Dead Wood).
func get_creature_speed_multiplier() -> float:
	var bonus := 0.0
	for card in _taken_cards():
		bonus += card.creature_speed_bonus * stacks[card.id]
	return 1.0 + bonus

# Whether obstacles can be cleared: after any clearing Dream (tag "clearing"). Taken cards are in
# the save, so this needs no saving of its own.
func can_clear() -> bool:
	if clearing_open:
		return true
	for card in _taken_cards():
		if card.tags.has("clearing"):
			return true
	return false

# Obstacles left on the map, of `kind` only if given.
func count_obstacles(kind: ObstacleData = null) -> int:
	if kind == null:
		return map_generator.obstacles.size()
	var count := 0
	for cell in map_generator.obstacles:
		if map_generator.obstacles[cell] == kind:
			count += 1
	return count

# Creature health multiplier from Dreams (Wild Growth).
func get_creature_health_multiplier() -> float:
	var bonus := 0.0
	for card in _taken_cards():
		bonus += card.creature_health_bonus * stacks[card.id]
	return 1.0 + bonus

func count_walls() -> int:
	var count := 0
	for tower in tower_container.get_children():
		if tower is Tower and tower.tower_data.line == "wall" and not tower.is_queued_for_deletion():
			count += 1
	return count

# Whether a bend in the path is within `reach` orthogonal steps of `cell`.
func is_beside_bend(cell: Vector2, reach: int = 1) -> bool:
	for dx in range(-reach, reach + 1):
		var rest := reach - absi(dx)
		for dy in range(-rest, rest + 1):
			if (dx != 0 or dy != 0) and _bend_cells.has(cell + Vector2(dx, dy)):
				return true
	return false

func _sum_stat(data: TowerData, stat: String) -> float:
	var total := 0.0
	for card in _taken_cards():
		if _applies_to(card, data):
			total += float(card.get(stat)) * stacks[card.id]
	return total

func _applies_to(card: UpgradeData, data: TowerData) -> bool:
	return (card.stat_line == "" or card.stat_line == data.line) \
		and (card.stat_warden == "" or card.stat_warden == data.get_id())

# The cards taken this run whose effect counts (for the Dreams row and reports).
func get_taken_cards() -> Array[UpgradeData]:
	return _taken_cards()

# Cards whose effect counts: taken, and not replaced by their Deepened version.
func _taken_cards() -> Array[UpgradeData]:
	var replaced := {}
	for card in pool:
		if card.is_deepened() and stacks.get(card.id, 0) > 0:
			replaced[card.deepens] = true
	var taken: Array[UpgradeData] = []
	for card in pool:
		if stacks.get(card.id, 0) > 0 and not replaced.has(card.id):
			taken.append(card)
	return taken

func _update_bends() -> void:
	_bend_cells.clear()
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	path_length = path.size()
	_path_index.clear()
	for i in path.size():
		_path_index[path[i]] = i  # Crossroads, Briar Crown
	for i in range(1, path.size() - 1):
		if path[i] - path[i - 1] != path[i + 1] - path[i]:
			_bend_cells[path[i]] = true


# --- Taking cards -------------------------------------------------------------------------------------

func take(card: UpgradeData) -> void:
	stacks[card.id] = stacks.get(card.id, 0) + 1
	_passed_count.erase(card.id)  # Taking a card resets its fade
	_passed_at.erase(card.id)
	if card.unlocks != null:
		unlocked[card.unlocks.get_id()] = true
		unlocks_changed.emit()
	if card.dew_now > 0:
		run_state.add_dew(card.dew_now)
	if card.max_leaves_add != 0:
		run_state.max_leaves = maxi(run_state.max_leaves + card.max_leaves_add, 1)
	if card.leaves_now < 0:
		run_state.lose_leaves(-card.leaves_now)  # Deep Sleep (never offered if it would end the run)
	if card.leaves_now != 0 or card.max_leaves_add != 0:
		run_state.regrow_leaves(maxi(card.leaves_now, 0))  # Also clamps to a lower maximum
	add_rare_dreams(card.rare_dreams_add)
	if card.dreamlight_now > 0:
		add_dreamlight(card.dreamlight_now)
	if card.free_clears_add > 0:
		run_state.add_free_clears(card.free_clears_add)
	if card.rule_id == &"court_of_the_eldest":
		_crown_court_eldest()
	if card.clears_obstacle != null:
		_clear_all(card.clears_obstacle)
	if card.set_cost_warden != "":
		unlocks_changed.emit()  # Tower bar prices change
	card_taken.emit(card)

# Restless Dreams and Omen rewards: the next `count` Dreams each include a Rare+ card.
func add_rare_dreams(count: int) -> void:
	_rare_dreams_left += count

# Omen reward (Thick Blight): the next Dream offers `count` more cards.
func add_extra_cards(count: int) -> void:
	_extra_cards_next += count

# Restless Dreams (bittersweet) takes "Let it pass" away for the rest of the run.
func can_skip() -> bool:
	return not has_rule(&"restless_dreams")

# Name of a Warden id or card id, for Entwined ingredient lists.
func get_display_name(id: String) -> String:
	for card in pool:
		if card.id == id:
			return card.display_name
		if card.unlocks != null and card.unlocks.get_id() == id:
			return card.unlocks.display_name
	return id.capitalize()


# --- Offers -----------------------------------------------------------------------------------------

func is_offering() -> bool:
	return not current_offer.is_empty()

# An offer is queued but not built yet (built deferred, so rest rewards like Omens land first).
func has_pending_offer() -> bool:
	return not _pending_drifts.is_empty()

func _on_rest_started(_block: int, is_boss_rest: bool, _bonus: int, _perfect: bool) -> void:
	if not drift_director.has_next_drift() or run_state.is_over:
		return
	_early_calls = 0  # Restless Night counts per block
	if is_boss_rest:
		# The freed light: +3 Dreamlight, and the Remember screen opens before the Dream.
		add_dreamlight(BOSS_DREAMLIGHT)
		_remember_open = true
		remember_requested.emit(null)
	if has_rule(&"sunlit_rest"):
		sunlit_rest()
	if has_rule(&"seedling_gift"):
		run_state.add_sprout_charges(1)
	_pending_drifts.append(drift_director.drifts_started)
	if not is_offering():
		_show_next_offer.call_deferred()

func _show_next_offer() -> void:
	if _pending_drifts.is_empty() or is_offering() or _remember_open:
		return
	current_offer_drift = _pending_drifts.pop_front()
	_before_offer = _offer_counters()
	current_offer = make_offer(current_offer_drift)
	if current_offer.is_empty():
		_show_next_offer()
		return
	offer_ready.emit(current_offer, current_offer_drift)

func choose(card: UpgradeData) -> void:
	if not current_offer.has(card):
		return
	take(card)
	_taken_this_offer.append(card.id)
	picks_left -= 1
	if picks_left > 0 and current_offer.size() > 1:  # Lucid Dreaming: take a second card
		current_offer.erase(card)
		offer_ready.emit(current_offer, current_offer_drift)
		return
	_close_offer()

# "Let it pass": no card, a little Dew instead.
func skip() -> void:
	if not is_offering() or not can_skip():
		return
	run_state.add_dew(skip_dew)
	_close_offer()

func _close_offer() -> void:
	_note_passed(current_offer, dreams_seen)
	current_offer = []
	offer_closed.emit()
	_show_next_offer()

# Second Thoughts (Grove): a new offer for the same Dream. It counts as the same Dream (pity, Omen
# rewards and Entwined guarantees are rolled back first), so only the cards change.
func reroll() -> bool:
	if not is_offering() or rerolls_left <= 0:
		return false
	rerolls_left -= 1
	_restore_offer_counters(_before_offer)
	# The replaced cards count as passed over, as if in the offer before, so the new one leaves them out.
	_note_passed(current_offer, dreams_seen)
	current_offer = make_offer(current_offer_drift)
	offer_ready.emit(current_offer, current_offer_drift)
	return true

# Let Go (Grove): `card` leaves this run's pool for good; another card takes its place in the offer.
func banish(card: UpgradeData) -> bool:
	if not current_offer.has(card) or banishes_left <= 0:
		return false
	banishes_left -= 1
	_banished[card.id] = true
	var index := current_offer.find(card)
	current_offer.remove_at(index)
	var replacement := _draw_card(drift_director.get_act(current_offer_drift), current_offer, false)
	if replacement != null:
		current_offer.insert(index, replacement)
	if current_offer.is_empty():
		_close_offer()
	else:
		offer_ready.emit(current_offer, current_offer_drift)
	return true

# Passed-over cards fade: every card of `offer` not taken counts as passed over in offer `offer_number`.
# The Entwined guaranteed card is unaffected.
func _note_passed(offer: Array[UpgradeData], offer_number: int) -> void:
	for card in offer:
		if _taken_this_offer.has(card.id) or card.id == _guaranteed_id:
			continue
		_passed_count[card.id] = int(_passed_count.get(card.id, 0)) + 1
		_passed_at[card.id] = offer_number
	_taken_this_offer.clear()

# Weight multiplier for `card` in the current offer (0 = left out: passed over in the one before).
func get_passed_weight(card: UpgradeData) -> float:
	var passed := times_passed(card.id)
	if passed == 0:
		return 1.0
	if int(_passed_at.get(card.id, -1)) == dreams_seen - 1:
		return 0.0
	return maxf(pow(PASSED_FADE, passed), PASSED_FLOOR)

func times_passed(card_id: String) -> int:
	return int(_passed_count.get(card_id, 0))

func _offer_counters() -> Dictionary:
	return {"dreams_seen": dreams_seen, "without_rare": _dreams_without_rare,
		"rare_left": _rare_dreams_left, "extra": _extra_cards_next, "entwined": _entwined_offered.duplicate()}

func _restore_offer_counters(counters: Dictionary) -> void:
	if counters.is_empty():
		return
	dreams_seen = counters.dreams_seen
	_dreams_without_rare = counters.without_rare
	_rare_dreams_left = counters.rare_left
	_extra_cards_next = counters.extra
	_entwined_offered = counters.entwined.duplicate()

# Builds a Dream offer for after drift `drift_number` (see dream_design.md, "How offers work").
func make_offer(drift_number: int) -> Array[UpgradeData]:
	dreams_seen += 1
	var size := cards_per_offer + _extra_cards_next
	picks_left = 1
	if has_rule(&"lucid_dreaming"):  # 4 cards, take 2, no Commons
		size += LUCID_EXTRA_CARDS
		picks_left = LUCID_PICKS
	_extra_cards_next = 0
	var offer: Array[UpgradeData] = []
	var act := drift_director.get_act(drift_number)
	_guaranteed_id = ""
	_taken_this_offer.clear()
	# Entwined: a combo whose ingredients just came together gets one guaranteed slot.
	if offer.size() < size:
		for card in pool:
			if card.entwined and not _entwined_offered.has(card.id) and is_eligible(card, act):
				_entwined_offered[card.id] = true
				_guaranteed_id = card.id
				offer.append(card)
				break
	var force_rare := drift_director.is_boss_drift(drift_number) or _dreams_without_rare >= pity_after \
		or _rare_dreams_left > 0
	_rare_dreams_left = maxi(_rare_dreams_left - 1, 0)
	while offer.size() < size:
		var want_rare := force_rare and not offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better())
		var card := _draw_card(act, offer, want_rare)
		if card == null:
			break
		offer.append(card)
	if offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()):
		_dreams_without_rare = 0
	else:
		_dreams_without_rare += 1
	return offer

func is_eligible(card: UpgradeData, act: int = 1) -> bool:
	if not (card.in_start_pool or grove_cards.has(card.id)) or _banished.has(card.id):
		return false
	if act < card.min_act or card.kind == UpgradeData.Kind.UNLOCK_WARDEN:
		return false  # Base Wardens come from the family pick
	if card.kind == UpgradeData.Kind.UNLOCK_EVOLUTION:
		return false  # Branches and final forms are unlocked with Dreamlight now
	if card.max_stacks > 0 and card_stacks(card.id) >= card.max_stacks:
		return false
	if card.is_deepened() and not has_card(card.deepens):
		return false
	if card.is_bittersweet() and not allow_bittersweet:
		return false
	# A card never costs the last leaves (Deep Sleep).
	if card.leaves_now < 0 and run_state.leaves + card.leaves_now <= 0:
		return false
	if card.max_leaves_add < 0 and run_state.max_leaves + card.max_leaves_add < 1:
		return false
	# Clearing cards only when the map is still full enough to matter.
	if card.min_obstacles > 0 and count_obstacles(card.clears_obstacle) < card.min_obstacles:
		return false
	if not _meets_needs(card):
		return false
	if card.unlocks != null and is_unlocked(card.unlocks.get_id()):
		return false
	for requirement in card.requires:
		if not owns(requirement):
			return false
	return true

# The run-state and card Needs (dream_design.md "Card requirements"). Only gates new offers: losing
# a requirement never takes a card away.
func _meets_needs(card: UpgradeData) -> bool:
	if card.requires_tag != "" and count_taken_with_tag(card.requires_tag) < card.requires_tag_count:
		return false
	if not card.requires_any.is_empty() and not card.requires_any.any(owns):
		return false
	if card.min_rank_dew > 0 and run_state.rank_dew_spent < card.min_rank_dew:
		return false
	if card.min_rank_count > 0 and count_ranked(card.min_rank_owned) < card.min_rank_count:
		return false
	if card.min_attackers > 0 or card.max_attackers > 0:
		var attackers := count_attackers()
		if attackers < card.min_attackers or (card.max_attackers > 0 and attackers > card.max_attackers):
			return false
	if card.count_warden != "" and count_wardens(card.count_warden) < card.min_warden_count:
		return false
	if card.min_reaction_pairs > 0 and count_reaction_pairs() < card.min_reaction_pairs:
		return false
	if card.requires_status != &"" and not owned_statuses().has(card.requires_status):
		return false
	if card.min_owned_statuses > 0 and owned_statuses().size() < card.min_owned_statuses:
		return false
	return true

# How many Reactions (Reactions.all(), dream_design.md "Reaction numbers") your owned Wardens could
# set off together: the first status and the second (or one of its alternatives, e.g. Pinned's
# Drowsy) each applied by a Warden you own.
func count_reaction_pairs() -> int:
	var statuses := owned_statuses()
	var count := 0
	for reaction in Reactions.all():
		if reaction.statuses.size() < 2 or not statuses.has(reaction.statuses[0]):
			continue
		var seconds: Array[StringName] = [reaction.statuses[1]]
		seconds.append_array(reaction.alternatives)
		if seconds.any(func(s: StringName) -> bool: return statuses.has(s)):
			count += 1
	return count

# Statuses applied by Wardens unlocked this run.
func owned_statuses() -> Dictionary:
	var statuses := {}
	var forms := _roster().duplicate()
	for card in pool:
		if card.unlocks != null:
			forms.append(card.unlocks)
	for data in forms:
		if not is_unlocked(data.get_id()):
			continue
		if data.applies_status != &"":
			statuses[data.applies_status] = true
		if data.extra_status != &"":  # A second status (Lullaby Bell's Drowsy)
			statuses[data.extra_status] = true
		if data.freeze_duration > 0.0 or HELD_SOURCES.has(data.get_id()):
			statuses[EnemyStatuses.HELD] = true
	for id in HELD_SOURCES:  # Also when only unlocked by id (not in the roster or a card yet)
		if is_unlocked(id) and not unlock_everything:
			statuses[EnemyStatuses.HELD] = true
	return statuses

# Taken cards carrying `tag` (each card once, however many stacks).
func count_taken_with_tag(tag: String) -> int:
	var count := 0
	for card in _taken_cards():
		if card.tags.has(tag):
			count += 1
	return count

func _draw_card(act: int, exclude: Array[UpgradeData], want_rare: bool) -> UpgradeData:
	var has_bittersweet := exclude.any(func(c: UpgradeData) -> bool: return c.is_bittersweet())
	var eligible: Array[UpgradeData] = []
	for card in pool:
		if exclude.has(card) or (has_bittersweet and card.is_bittersweet()):
			continue  # At most one bittersweet card per offer
		if card.rarity == UpgradeData.Rarity.COMMON and has_rule(&"lucid_dreaming"):
			continue  # Lucid Dreaming: no Commons
		if is_eligible(card, act):
			eligible.append(card)
	if eligible.is_empty():
		return null
	# Passed-over cards fade across rarities (dream_design.md): when every card of the rolled rarity is
	# faded, keep that rarity with a chance equal to their best weight, else re-roll among the others
	# (a forced Rare+ slot falls through to Legendary).
	var tried: Array[int] = []
	var rarity := _roll_rarity(act, want_rare)
	while rarity >= 0:
		var of_rarity := eligible.filter(func(c: UpgradeData) -> bool: return c.rarity == rarity)
		if tried.is_empty():  # The first roll keeps the old fallbacks when its rarity has no card
			if of_rarity.is_empty() and want_rare:
				of_rarity = eligible.filter(func(c: UpgradeData) -> bool: return c.is_rare_or_better())
			if of_rarity.is_empty():
				of_rarity = eligible
		var best := 0.0
		for card in of_rarity:
			best = maxf(best, get_passed_weight(card))
		if best >= 1.0 or (best > 0.0 and _rng.randf() < best):
			return _weighted_pick(of_rarity.filter(func(c: UpgradeData) -> bool: return get_passed_weight(c) > 0.0))
		tried.append(rarity)
		rarity = _roll_rarity(act, want_rare, tried)
	# Nothing else can fill the slot: faded cards after all (passed over in the offer before only if
	# there's truly nothing else).
	var left := eligible
	if want_rare and eligible.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()):
		left = eligible.filter(func(c: UpgradeData) -> bool: return c.is_rare_or_better())
	var fresh := left.filter(func(c: UpgradeData) -> bool: return get_passed_weight(c) > 0.0)
	return _weighted_pick(fresh if not fresh.is_empty() else left)

# A rarity for the next card (-1 = every rarity is in `skip`).
func _roll_rarity(act: int, want_rare: bool, skip: Array[int] = []) -> int:
	var weights: Array = RARITY_WEIGHTS[clampi(act, 1, RARITY_WEIGHTS.size()) - 1].duplicate()
	if lean_common:
		for i in [UpgradeData.Rarity.RARE, UpgradeData.Rarity.LEGENDARY]:
			var moved: int = weights[i] / 2
			weights[i] -= moved
			weights[UpgradeData.Rarity.COMMON] += moved
	if want_rare:
		weights[0] = 0
		weights[1] = 0
	for i in skip:
		weights[i] = 0
	var total := 0
	for w in weights:
		total += w
	if total <= 0:
		if want_rare:  # Falls through to Legendary even where its weight is 0 (act 1)
			for i in [UpgradeData.Rarity.RARE, UpgradeData.Rarity.LEGENDARY]:
				if not skip.has(i):
					return i
		return -1
	var roll := _rng.randi_range(1, total)
	for i in weights.size():
		roll -= weights[i]
		if roll <= 0:
			return i
	return 0

# Picks one of `cards` by tag weighting (owned families and build directions, the clearing boost).
func _weighted_pick(cards: Array) -> UpgradeData:
	var owned_lines := {}
	for card in _taken_cards():  # A taken Legendary's archetype counts as a family (Legendary rules)
		if card.rarity == UpgradeData.Rarity.LEGENDARY:
			for tag in card.tags:
				owned_lines[tag] = true
	for tower_id in unlocked:
		var line := _line_of(tower_id)
		if line != "":
			owned_lines[line] = true
	# Build directions you've started count like families; wide and narrow push each other away.
	var opposed := {}
	for tag in DIRECTION_TAGS:
		if count_taken_with_tag(tag) > 0:
			owned_lines[tag] = true
			if OPPOSITE_DIRECTION.has(tag):
				opposed[OPPOSITE_DIRECTION[tag]] = true
	var weights: Array[float] = []
	var total := 0.0
	var clearing_locked := not can_clear()
	for card in cards:
		var weight := 1.0
		for tag in card.tags:
			if owned_lines.has(tag):
				weight = tag_weight
				break
		if clearing_locked and card.tags.has("clearing"):
			weight *= CLEARING_LOCKED_WEIGHT  # Until the first one unlocks clearing
		for tag in opposed:  # e.g. a narrow card while you've gone wide
			if card.tags.has(tag) and not card.tags.has(OPPOSITE_DIRECTION[tag]):
				weight *= OPPOSITE_WEIGHT
		weight *= get_passed_weight(card)  # Passed-over cards fade (all 0 = a plain random pick below)
		weights.append(weight)
		total += weight
	if total <= 0.0:
		return cards[_rng.randi_range(0, cards.size() - 1)]
	var roll := _rng.randf() * total
	for i in cards.size():
		roll -= weights[i]
		if roll <= 0.0:
			return cards[i]
	return cards[-1]

var _lines_by_id := {}

func _line_of(tower_id: String) -> String:
	if _lines_by_id.is_empty():
		for card in pool:
			if card.unlocks != null:
				_lines_by_id[card.unlocks.get_id()] = card.unlocks.line
		_lines_by_id["sprout"] = "sprout"
		_lines_by_id["thornwall"] = "wall"
	return _lines_by_id.get(tower_id, "")


# --- Save -------------------------------------------------------------------------------------------

# Everything a resumed run needs (saved at a rest, so there's no open offer to keep).
func to_save() -> Dictionary:
	return {
		"unlocked": unlocked.keys(), "stacks": stacks.duplicate(), "dreams_seen": dreams_seen,
		"dreams_without_rare": _dreams_without_rare, "rare_dreams_left": _rare_dreams_left,
		"extra_cards_next": _extra_cards_next, "entwined_offered": _entwined_offered.keys(),
		"rerolls_left": rerolls_left, "banishes_left": banishes_left, "banished": _banished.keys(),
		"attackers_planted": _attackers_planted, "dreamlight": dreamlight,
		"dreamlight_shards": dreamlight_shards, "sprout_charges": run_state.sprout_charges,
		"eldest_cell": [_eldest_cell.x, _eldest_cell.y], "court_pending": _court_pending,
		"passed_count": _passed_count.duplicate(), "passed_at": _passed_at.duplicate(),
		"rng_state": str(_rng.state),  # A string: JSON would round a 64-bit int
	}

func load_save(data: Dictionary) -> void:
	unlocked.clear()
	for id in data.get("unlocked", []):
		unlocked[id] = true
	stacks.clear()
	var saved_stacks: Dictionary = data.get("stacks", {})
	for id in saved_stacks:
		stacks[id] = int(saved_stacks[id])  # JSON gives floats
	dreams_seen = int(data.get("dreams_seen", 0))
	_dreams_without_rare = int(data.get("dreams_without_rare", 0))
	_rare_dreams_left = int(data.get("rare_dreams_left", 0))
	_extra_cards_next = int(data.get("extra_cards_next", 0))
	_entwined_offered.clear()
	for id in data.get("entwined_offered", []):
		_entwined_offered[id] = true
	if data.has("rerolls_left"):  # Else keep what MetaRun set at run start
		rerolls_left = int(data.rerolls_left)
		banishes_left = int(data.banishes_left)
	_banished.clear()
	for id in data.get("banished", []):
		_banished[id] = true
	_passed_count.clear()
	_passed_at.clear()
	for key in ["passed_count", "passed_at"]:
		var saved: Dictionary = data.get(key, {})
		var into: Dictionary = _passed_count if key == "passed_count" else _passed_at
		for id in saved:
			into[id] = int(saved[id])  # JSON gives floats
	_attackers_planted = int(data.get("attackers_planted", 0))
	dreamlight = int(data.get("dreamlight", 0))
	dreamlight_changed.emit(dreamlight)
	dreamlight_shards = int(data.get("dreamlight_shards", 0))
	var eldest: Array = data.get("eldest_cell", [-1, -1])
	_eldest_cell = Vector2(eldest[0], eldest[1])
	_court_pending = bool(data.get("court_pending", false))
	run_state.add_sprout_charges(int(data.get("sprout_charges", 0)) - run_state.sprout_charges)
	if data.has("rng_state"):
		_rng.state = str(data.rng_state).to_int()
	unlocks_changed.emit()


# --- Rules ------------------------------------------------------------------------------------------

# Burn Back the Dead Wood: clears every obstacle of `kind` now. These clears give no Seeds.
func _clear_all(kind: ObstacleData) -> void:
	var cells: Array = map_generator.obstacles.keys().filter(
		func(cell: Vector2) -> bool: return map_generator.obstacles[cell] == kind)
	run_state.clearing_without_seeds = true
	for cell in cells:
		map_generator.clear_obstacle(cell)
	run_state.clearing_without_seeds = false

# Sunlit Rest: the ranked Warden(s) nearest the Heartwood that can still gain a rank get one free
# (II: two). Wardens at rank II are skipped: rank III asks for a Focus, which is the player's choice.
func sunlit_rest() -> Array[Tower]:
	var raised: Array[Tower] = []
	var seller := get_node_or_null("%TowerSeller")
	var ranked: Array = _towers().filter(func(t: Tower) -> bool:
		return t.rank > 0 and t.rank != 2 and t.rank < mini(FREE_RANK_MAX, get_max_rank_for(t)) and t.can_nurture())  # Free ranks stop at VII (V unless the Eldest)
	if seller and seller.has_method("sort_by_heartwood"):
		ranked = seller.sort_by_heartwood(ranked)  # Same order as group Nurture
	for tower in ranked:
		if raised.size() >= SUNLIT_WARDENS[rule_level(&"sunlit_rest")]:
			break
		tower.nurture(0)  # A free rank (adds no Dew to what it's worth)
		raised.append(tower)
	return raised

# Remembered Care: selling a ranked Warden leaves a memory seed (II: keeps two, highest first).
func _on_tower_sold(tower: Tower, _refund: int) -> void:
	if is_eldest(tower):
		set_eldest(null)  # The title is free again; its ranks above V are lost
	if not has_rule(&"remembered_care") or tower.rank <= 0:
		return
	run_state.memory_seeds.append(mini(tower.rank, BASE_MAX_RANK))  # A seed holds at most rank V
	run_state.memory_seeds.sort()
	run_state.memory_seeds.reverse()
	run_state.memory_seeds.resize(mini(run_state.memory_seeds.size(), MEMORY_SEEDS[rule_level(&"remembered_care")]))

# The next Warden planted uses the highest memory seed (it still costs its normal Dew). Canopy
# counts attacking Wardens planted.
func _on_tower_built(tower: Tower) -> void:
	if tower.tower_data.can_attack:
		_attackers_planted += 1
	_watch_nurture(tower)
	# Seedling Gift: a free Sprout (0 Dew) used a charge; with Nursery it arrives at rank II.
	if tower.tower_data.get_id() == "sprout" and tower.invested_dew == 0 and run_state.sprout_charges > 0:
		run_state.add_sprout_charges(-1)
		if has_rule(&"nursery"):
			tower.rank = maxi(tower.rank, mini(NURSERY_RANK, get_max_rank()))
	if run_state.memory_seeds.is_empty() or not tower.tower_data.can_attack:
		return
	tower.rank = mini(run_state.memory_seeds.pop_front(), mini(get_max_rank_for(tower), FREE_RANK_MAX))
	if tower.has_signal("nurtured"):
		tower.nurtured.emit(tower)

# Reclaimed Earth: every clear gives Dew and leaves the cell fertile. Not Burn Back's mass clear
# (it would flood the Dew economy, same as its no-Seeds rule).
func _on_obstacle_cleared(cell: Vector2, _data: ObstacleData) -> void:
	if run_state.clearing_without_seeds:
		return
	var dew := 0
	for card in _taken_cards():
		dew += card.dew_per_obstacle_clear * stacks[card.id]
	if dew > 0:
		run_state.earn_dew_at(dew, map_generator.MAP_GRID.calculate_map_position(cell))
	if has_rule(&"reclaimed_earth"):
		run_state.fertile_cells[cell] = true

# Spore Cascade: a cleansed creature's Spored stacks spread to the nearest creatures.
func _on_enemy_cleansed(enemy: Node2D) -> void:
	_hunters_spread(enemy)
	if not has_rule(&"spore_cascade") or not enemy.statuses.has(EnemyStatuses.SPORED):
		return
	var spores: int = enemy.statuses.stacks(EnemyStatuses.SPORED)
	var potency: float = enemy.statuses.potency(EnemyStatuses.SPORED)
	var duration: float = enemy.statuses.time_left(EnemyStatuses.SPORED)
	var line: String = enemy.statuses.spore_line()
	var others := get_tree().get_nodes_in_group(Tower.ENEMY_GROUP)
	others.erase(enemy)
	others.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(enemy.global_position) \
			< b.global_position.distance_squared_to(enemy.global_position))
	for i in mini(SPORE_CASCADE_TARGETS[rule_level(&"spore_cascade")], others.size()):
		others[i].apply_status(EnemyStatuses.SPORED, spores, duration, potency, 0, line,
			enemy.statuses.source(EnemyStatuses.SPORED))
