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
const COZY_CORNERS_BONUS := [0.30, 0.50]
const COZY_CORNERS_REACH := [1, 2]  # Cells from a bend, diagonals included (1 = the 8 around, 2 = 5×5)
const HEDGE_PER_WALLS := [3, 2]
const HEDGE_BONUS_PER := 0.01
const HEDGE_BONUS_MAX := [0.30, 0.45]
const SPORE_CASCADE_TARGETS := [2, 3]
const TENDED_FOREST_PER_CLEAR := 0.02
const TENDED_FOREST_MAX := 0.40
const FERTILE_DISCOUNT := 0.5  # Reclaimed Earth: the first Warden on a cleared cell
const CLEAR_DISCOUNT_MAX := 0.5  # Cleared Ground stacks to −50%
const RECLAIMED_REFUND := 0.4  # Reclaimed Earth: share of the Dew paid for a clear
const BURN_BACK_PER_TREE := 5  # Burn Back: Dew per Withered Tree, paid when taken
const CLEAR_SURCHARGE := 1  # Every clear this run makes later clears +1 Dew
const CLEARING_LOCKED_WEIGHT := 2.0  # Clearing cards are this much likelier until you own one
# Nurture and wide / narrow cards (dream_design.md). [base, Deepened (II)] where it deepens.
const NURTURE_DISCOUNT_MAX := 0.50
const BASE_MAX_RANK := 5
const EXTRA_RANK_COSTS := {6: 130, 7: 180}  # Deeper Rings, before the Warden's tier multiplier
const FREE_RANK_MAX := 7  # Free ranks (Sunlit Rest, seeds, The Old Ones) never go past VII
const ENDLESS_RANK_GROWTH := 1.2  # Endless Rings: each rank past VII costs ×1.2 the one before
const SEEPING_PER := [0.08, 0.12]
const SEEPING_MAX_STATUSES := 5
const VENOM_HIT_PENALTY := 0.15
const KINDRED_PER_RANK := [0.02, 0.03]
const KINDRED_MAX := [0.30, 0.45]
const MEMORY_SEEDS := [1, 2]  # Remembered Care keeps this many seeds
const SUNLIT_WARDENS := [1, 2]  # Sunlit Rest raises this many per rest
const CHOSEN_FEW_BONUS := 0.5  # Rank V+
const CHOSEN_FEW_PENALTY := 0.15  # Below rank III
const MANY_HANDS_PER := 2  # +1% per this many attacking Wardens
const MANY_HANDS_MAX := 0.40
const SPROUT_CHORUS_PER := 0.08
const SPROUT_CHORUS_MAX := 0.60
const CANOPY_STEPS: Array[int] = [20, 30, 40]  # Attacking Wardens planted this run
const CANOPY_BONUS := 0.12
const SOLITUDE_BONUS := 0.45
const SOLITUDE_RANGE := 0.5
const FEW_AND_MIGHTY_BELOW := 12
const FEW_AND_MIGHTY_PER := 0.08
const LAST_LIGHT_MAX := 5
const NEARBY_CELLS := 2  # "Within 2 cells" (Sprout Chorus, Solitude): Chebyshev distance
# Grove cards (dream_design.md 26–44): maze Legendaries and crit cards.
const LONG_WALK_PER := 0.01  # The Long Walk: +1% damage…
const LONG_WALK_TILES := 2  # …per this many path tiles
const MONOCULTURE_BONUS := 1.00
const ROOTBOUND_TOUCHING := 3
const STILL_TARGET_CRIT := [0.25, 0.40]
const STARLIT_AIM_CRIT := 0.25
const FULL_MOON_CRIT := 0.10
const RECKLESS_CRIT := 0.30
const RECKLESS_PENALTY := 0.15
# The 10 card builds (dream_design.md "Pool trim", layer 2): the only tags build weighting reads.
# Tall and overgrowth halve each other once you own OPPOSED_FROM cards of one (round 4).
const ARCHETYPE_TAGS: Array[String] = ["tall", "overgrowth", "daring", "precision", "affliction", "maze",
	"tending", "kinship"]  # Round 2: swarm merged into affliction; round 3: support into tending
const DIRECTION_TAGS: Array[String] = ["nurture", "wide", "narrow", "sprout"]  # Old directions: rules and Needs only
const NOT_BUILD_TAGS: Array[String] = ["bittersweet", "opener"]  # Structural tags, never a build
const SOFT_TAG_NEEDS: Array[String] = ["nurture"]  # requires_tag Needs that only weigh (x0.4), never gate
const OPPOSITE_DIRECTION := {"tall": "overgrowth", "overgrowth": "tall"}
const OPPOSED_FROM := 2
const OPPOSITE_WEIGHT := 0.5
const SOFT_NEED_WEIGHT := 0.4  # A card whose soft Needs are unmet (dream_design.md "Adapt, don't get handed")
const STRAY_FROM_DRIFT := 10  # The Stray Dream: one slot per offer from this rest on (never at boss rests)
const STRAY_IN_BUILD_WEIGHT := 0.25
const HALF_DREAMED_WEIGHT := 1.0  # A combo card whose other family you could still pick
const HALF_DREAMED_WITHIN := 20  # …offered only when the next family pick is at most this many drifts away
const HALF_DREAMED_DECLINED_WEIGHT := 0.3  # …after its missing family was offered at a pick and not taken
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
# Generic Rares (dream_design.md "Generic Rares", 135–141)
const ROOT_NETWORK_PER := [0.06, 0.08]  # Per Sprout in the network (II: diagonals count too)
const ROOT_NETWORK_MAX := [0.60, 0.80]
const FIRST_LIGHT_MULTIPLIER := 3.0
const LAST_STAND_CELLS := 4  # From the Heartwood (Chebyshev)
const LAST_STAND_BONUS := 0.35
const OLD_GROWTH_STEPS := [[15, 0.40], [5, 0.20]]  # [drifts stood, damage], highest first
const HUNTERS_PATIENCE_ELITE := 0.60
const HUNTERS_PATIENCE_BOSS := 0.35
const HERD_PER := 0.02
const HERD_MAX := 0.50
const BITTER_PER := 0.08
const BITTER_MAX := 0.40
const BITTER_TIME := 2.0
# Generic Commons and Uncommons (142–156) and the second batch (157–168)
const GATHERED_DEW_PER := 0.10  # Morning Dew (absorbed Gathered Dew)
const CALL_OF_THE_WILD_CAP := 40
const LASTING_DREAMS_PER := 2.0  # Seconds per stack
const SHORT_ROOTS_RANGE := 2.0
const SHORT_ROOTS_BONUS := 0.35
const FORESTS_EDGE_CELLS := 3  # From the start (Chebyshev)
const FORESTS_EDGE_BONUS := 0.35
const CROWDED_PER := [0.05, 0.07]
const CROWDED_MAX := [0.50, 0.70]
const LONE_HUNTER_BONUS := [0.45, 0.70]
const LONE_HUNTER_CELLS := 2.0
const SKYWARD_BONUS := 0.40  # Hunter's Patience (absorbed Skyward Gaze)
const SKYWARD_RANGE := 1.0  # Against flyers (Tower Code's targeting)
const FRESH_GROWTH_BONUS := [0.50, 0.75]
const UNDERDOG := [[3, 0.40], [4, 0.60]]  # [Wardens, damage] (II)
const HEAVY_AIR_BONUS := 0.40
const SLOW_STATUSES: Array[StringName] = [&"drowsy"]  # Damp and fog no longer slow; frost is a freeze (5821d9f)
const WANDERING_MIND_REROLLS := 2
const WINDING_PATH_TILES := 5  # +1 Dew per this many path tiles at each rest
const SHELTER_BONUS := 0.30
const CLIFFSIDE_RANGE := 1.0
const CLIFFSIDE_BONUS := 0.20  # …and +20% damage (dream_audit.md)
const THICK_BARK_CHARGES := [1, 2]
const SUDDEN_BLOOM_ATTACKS := 3
const LAST_BREATH_SHARE := [0.10, 0.15]
const LAST_BREATH_BOSS_CAP := 0.05
const LAST_BREATH_CELLS := 1.0
const WATCHFUL_REST_TIME := [5.0, 3.0]
const GLIMMER_CHANCE := 0.30
const GLIMMER_DREAMLIGHT_MAX := 3  # Per run, its own cap (not the Great Dreamcatcher's)
const STRAIGHT_TILES := 5
const STRAIGHTAWAY := [[0.30, 0.5], [0.50, 0.5]]  # [damage, range]
const HEART_OF_MAZE_BONUS := 1.00
# Half-dreamed Commons (189–191, stack to 3)
const DAMP_ROT_PER := 0.50  # Poisoned (Spored) ticks on Soaked nightmares
const SPARKING_SPORES_PER := 0.50  # Ignite detonations
const RAIN_ON_GLASS_PER := 0.35  # Light Wardens vs Soaked
# Seed cards (dream_design.md "Seed cards", 169–176)
const DEEP_WELL_RATE := 0.05
const DEEP_WELL_MAX := 40
const KIND_CANOPY_TOUCHING := 3
const KIND_CANOPY_BONUS := 0.20
const SHARED_LIGHT_PER := 0.04
const SHARED_LIGHT_MAX := 0.20
const BRAMBLE_OATH_PER := 0.03  # Per BRAMBLE_OATH_TILES path tiles the walls add
const BRAMBLE_OATH_TILES := 5
const BRAMBLE_OATH_MAX := 0.30
const PATIENT_ROOTS_HELD := 0.5
const GOLDEN_HARVEST_PER := 0.02  # Per 100 Dew harvested / earned as interest
const GOLDEN_HARVEST_MAX := 0.30
# Dreamlight (run_design.md "Dreamlight"): sources and unlock costs.
const FIRST_PICK_DREAMLIGHT := 2  # The default for first_pick_dreamlight (2026-09-30: a final form in act 1)
# Dreamlight with the first family pick (Blight 2 sets it to 0 via MetaRun).
var first_pick_dreamlight := FIRST_PICK_DREAMLIGHT
# The power pass (dream_audit.md, 2026-09-30): old save ids -> the card that absorbed them ("" = cut).
const MERGED_CARDS := {"cheap_hedges": "weathered_walls", "quick_bonds": "old_friends", "wide_bowl": "dew_trail",
	"fair_trade": "", "still_waters": "", "echoing_steps": "",
	# Pool trim (dream_design.md "Pool trim", 2026-09-30)
	"gathered_dew": "morning_dew", "fresh_soil": "reclaimed_earth", "tend_the_forest": "heartwoods_reach",
	"mending_bark": "thick_bark", "heartwoods_fury": "last_stand", "warm_hands": "tender_care",
	"court_of_the_eldest": "endless_rings", "sprout_surge": "seedfall", "close_kin": "extended_family",
	"close_kin_ii": "extended_family", "skyward_gaze": "hunters_patience", "crush": "crowd_breaker", "crush_ii": "crowd_breaker",
	"hurried_harvest": "call_of_the_wild", "borrowed_dew": "", "hungry_roots": "", "overgrown": "", "wild_growth": "",
	"reckless_bloom": "", "overgrowth": "", "borrowed_memory": "", "remembered_care": "", "remembered_care_ii": "",
	"seasoned_eye": "", "many_rings": "", "big_family": "", "sudden_bloom": "", "underdog": "", "underdog_ii": "",
	"cliffside": "", "tangled": "", "patchwork": "", "hedgerow": "", "shelter_of_stones": "", "short_roots": ""}
const BOSS_DREAMLIGHT := 4
# "The Heartwood wakes" (run_design.md Dreamlight sources): every rest from drift 51 frees +1 more.
const WAKE_DREAMLIGHT := 1
const WAKE_FROM_DRIFT := 51
const BRANCH_DREAMLIGHT := 1  # Hidden branch, wall growth (regular branches come free with the family)
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
signal bark_changed(charges: int)  # Thick Bark: leaks it can still save this block (HUD shield)
# The Remember screen should open (after a boss's family pick, from the rest panel or the Warden
# panel). `focus` = the form to highlight, or null.
signal remember_requested(focus: TowerData)

@export var pool: Array[UpgradeData] = []  # Empty = every card in res://resource/dream/
@export var starting_unlocks: Array[String] = ["sprout", "thornwall"]
@export var unlock_everything: bool = false  # Debug/tests: every Warden and evolution available
@export var cards_per_offer: int = 3
@export var skip_dew: int = 15  # "Let it pass"
@export var tag_weight: float = 1.3  # Cards sharing an archetype tag of a card you've taken (1.6 -> 1.3, 2026-09-30: "felt like cards were handed to me")
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
var current_stray: UpgradeData = null  # The Stray Dream card of the current offer (null = none)
var _legendary_next := 0  # Lean Season: Dreams still owed a Legendary
var _owed_families: Array[String] = []  # Half-dreamed cards taken: the next family pick includes one
var _declined_families: Array[String] = []  # Offered at the last family pick, not taken (half-dreamed ×0.3)
var _taken_cache := {}  # include_dormant -> [state key, taken cards] (_taken_cards)
var board_version := 0  # Bumped on every change the Dream rows read (bump_board)
var _bitter_walls := {}  # Nightmare id -> {wall id: clock it passed} (Bitter Hedges)
var _first_hits := {}  # "Warden id:nightmare id" -> true (First Light)
var _herd := {}  # Warden id -> dispels in its range this drift (Thinning the Herd)
var _walls_planted := 0  # Thornwalls planted this run (Weathered Walls: every 10th is free)
var bark_charges := 0  # Thick Bark: leaks it can still save this block
var _straight_cells := {}  # Route tiles in a straight stretch of 5+ (Straightaway)
var _heart_cache := []  # [key, Tower] (get_heart_of_maze)
var _glimmer_rng := RandomNumberGenerator.new()
var last_clear_paid := 0  # Dew the clear being made cost (ObstacleClearer sets it; Reclaimed Earth)
var glimmer_shards := 0  # Glimmering Hunt's shards this run (10 = 1 Dreamlight, own cap)
var _statuses_cache := []  # [state key, owned statuses] (owned_statuses)
var _offer_drift := 0  # The drift of the offer being built (half-dreamed checks)
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
	drift_director.rest_started.connect(_save_discoveries.unbind(4))
	run_state.run_ended.connect(_save_discoveries.unbind(1))
	drift_director.family_pick_requested.connect(func(reason: StringName) -> void:
		if reason == &"first":
			add_dreamlight(first_pick_dreamlight))  # Act 1 can take a final form
	unlocks_changed.connect(grant_free_branches)  # A family pick (screen or sim), a save load
	map_generator.path_changed.connect(_update_bends)
	spawner.enemy_cleansed.connect(_on_enemy_cleansed)
	spawner.child_entered_tree.connect(_stamp_head_start)
	map_generator.obstacle_cleared.connect(_on_obstacle_cleared)
	var placer := get_node_or_null("%TowerPlacer")
	if placer:
		placer.tower_built.connect(_on_tower_built)
	var seller := get_node_or_null("%TowerSeller")
	if seller:
		seller.tower_sold.connect(_on_tower_sold)
	drift_director.drift_started.connect(_on_drift_started)
	# The board version (DreamEffects' shared board and cached rows): any Warden, card, route, rest,
	# drift, leaf or Eldest change bumps it.
	tower_container.child_entered_tree.connect(_on_tower_added)
	tower_container.child_exiting_tree.connect(bump_board.unbind(1))
	for tower in _towers():
		_on_tower_added(tower)
	map_generator.path_changed.connect(bump_board)
	map_generator.obstacle_cleared.connect(bump_board.unbind(2))
	drift_director.rest_started.connect(bump_board.unbind(4))
	drift_director.drift_started.connect(bump_board.unbind(1))
	run_state.leaves_changed.connect(bump_board.unbind(2))
	eldest_changed.connect(bump_board.unbind(1))
	_update_bends()

# Something the Dream rows read changed: DreamEffects rebuilds its board and cached rows on next use.
func bump_board() -> void:
	board_version += 1

# Nurture: only the Warden and those touching it look again (DreamEffects.rank_changed).
func _on_rank_changed(tower: Tower) -> void:
	effects().rank_changed(tower)

func _on_tower_added(node: Node) -> void:
	bump_board()
	if node.has_signal("evolved") and not node.evolved.is_connected(bump_board.unbind(1)):
		node.evolved.connect(bump_board.unbind(1))
	if node.has_signal("nurtured") and not node.nurtured.is_connected(_on_rank_changed):
		node.nurtured.connect(_on_rank_changed)

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
	if card != null and not (card.in_start_pool or grove_cards.has(card.id)) and not _is_regular_final(data):
		return "Memory Grove"
	return ""

# run_design.md "Dreamlight" (2026-09-30): a final form of a family (not a wall growth) needs no Grove node,
# only its branch and 2 Dreamlight.
func _is_regular_final(data: TowerData) -> bool:
	return data.tier == 3 and data.line != "wall"

# Owning a family unlocks its base and both regular branches at once (growing still costs Dew); hidden
# branches (Grove) still cost Dreamlight. Runs on every unlocks_changed (family picks, save loads: an old
# save with a branch not bought gets it, nothing refunded).
func grant_free_branches() -> void:
	var granted := false
	for root in _roster() + _family_roots():
		if not (root is TowerData and root.tier == 1 and root.buildable_directly and root.line != "wall"):
			continue
		if not unlocked.has(root.get_id()):
			continue
		for branch in root.evolves_to:
			var card := _unlock_card_for(branch)
			if not unlocked.has(branch.get_id()) and (card == null or card.in_start_pool):
				unlocked[branch.get_id()] = true
				granted = true
	if granted:
		unlocks_changed.emit()

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
		if ascended != null and not ascended_visible(ascended):
			ascended = null  # No crown and no line to it yet (run_design.md "Playtest fixes")
		trees.append([root, branches, ascended])  # ascended: the family's Ascended form, or null
	return trees

# The Remember tree shows an Ascended crown only once it can be unlocked this run: its Grove node planted
# and drift ASCENDED_FROM_DRIFT reached (or already unlocked; Test Grove shows everything).
func ascended_visible(data: TowerData) -> bool:
	if is_unlocked(data.get_id()):
		return true
	var card := _unlock_card_for(data)
	var planted := card == null or card.in_start_pool or grove_cards.has(card.id)
	return planted and drift_director.drifts_started + 1 >= ASCENDED_FROM_DRIFT

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
	return 1.0 + _sum_stat(tower.tower_data, "soothe_bonus") + _tower_rule_total(tower, "damage")

# Per-Warden attack speed from Dreams (Tower adds it to its multiplier): Sprout Chorus, The Last
# Light, Rootbound.
func get_tower_attack_speed_bonus(tower: Tower) -> float:
	return _tower_rule_total(tower, "speed")

# Performance (3x perf bar, 2026-09-30): a planted Warden reads its cached rows (DreamEffects.rows_cached,
# ~16 us) instead of rebuilding them (~110 us); a Warden not in the tree (tests, previews) rebuilds.
func _tower_rule_total(tower: Tower, key: String) -> float:
	if tower.is_inside_tree():
		return effects().rule_total_cached(tower, key)
	return effects().rule_total(DreamEffects.spot_for(tower), key)

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
	_rule_map()
	if not _any_crit_rule:
		return 0.0  # The common case: no crit card owned (asked on every Warden hit)
	var bonus := 0.0
	bonus += GLINTING_DEW_PER * rule_stacks(&"glinting_dew") * rule_power(&"glinting_dew")  # Glinting Dew
	if _tower != null and _tower.tower_data.line == "stone":  # Heavy Stones: the Pebbling line
		bonus += HEAVY_STONES_PER * rule_stacks(&"heavy_stones") * rule_power(&"heavy_stones")
	if _tower != null and has_rule(&"seasoned_eye"):  # +1% per rank (max +7%: only the Eldest reaches it)
		bonus += minf(SEASONED_EYE_PER * _tower.rank, SEASONED_EYE_MAX) * rule_power(&"seasoned_eye")
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

# Extra crit multiplier on a crit (Tower adds it): Full Moon turns crit chance above 100% (`raw_chance`
# before capping) into multiplier; Sharpened Light / II add a flat +0.5 / +1.0.
func get_crit_overflow_multiplier(raw_chance: float) -> float:
	var extra := maxf(raw_chance - 1.0, 0.0) if has_rule(&"full_moon") else 0.0
	if has_rule(&"sharpened_light"):
		extra += SHARPENED_LIGHT[rule_level(&"sharpened_light")] * rule_power(&"sharpened_light")
	return extra

# Reckless Bloom (bittersweet): hits that don't crit deal this much of their damage.
func get_non_crit_multiplier() -> float:
	return 1.0 - RECKLESS_PENALTY if has_rule(&"reckless_bloom") else 1.0

# Per-Warden range from Dreams, in cells (Tower adds it): Solitude.
func get_tower_range_bonus(tower: Tower) -> float:
	return _tower_rule_total(tower, "range")

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
	_herd.clear()  # Thinning the Herd lasts the rest of the drift
	for tower in _towers():
		_watch_growth(tower)
	_first_hits.clear()
	for tower in _towers():  # Steadfast (old_growth): drifts this Warden has stood (growing keeps the node)
		tower.set_meta(&"drifts_stood", int(tower.get_meta(&"drifts_stood", 0)) + 1)
	if number > 1 and drift_director._arriving.has(number - 1):
		_early_calls += 1
		if has_rule(&"quick_step"):
			_quick_step_until = _game_clock + QUICK_STEP_TIME
			bump_board()
		if has_rule(&"head_start"):
			_head_start_drift = number
		if has_rule(&"hurried_harvest"):
			_hurried_drift = number
			_hurried_paid = 0

# Briar Crown: a nightmare stepping onto a route tile beside a wall takes 25% of the strongest
# attacking Warden touching that wall (its line, area, no crit; once per wall per nightmare per s).
func _process(delta: float) -> void:
	if not get_tree().paused:
		_game_clock += delta  # Murmur's 1 s window
		_sample_drift(delta)
	var briar := has_rule(&"briar_crown")
	var bitter := has_rule(&"bitter_hedges")
	if get_tree().paused or not (briar or bitter):
		return
	_briar_clock += delta
	for enemy in spawner.get_enemies():
		var id: int = enemy.get_instance_id()
		var cell: Vector2 = enemy.get_current_cell()
		if _briar_cells.get(id) == cell:
			continue
		_briar_cells[id] = cell
		if _path_index.has(cell):
			if bitter:
				_bitter_pass(enemy, cell)
			if briar:
				_briar_strike(enemy, cell)
	if _briar_cells.size() > 512:
		_briar_cells.clear()  # Forget long-gone nightmares now and then
		_briar_hits.clear()
		_bitter_walls.clear()

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
			bonus += card.status_strength_bonus * stacks[card.id] * resonance(card)
	if SLOW_STATUSES.has(status) and has_rule(&"heavy_air"):
		bonus += HEAVY_AIR_BONUS * rule_power(&"heavy_air")  # Heavy Air: every slow 20% stronger
	return 1.0 + bonus

# Duration of `status` when `data` applies it (its own duration or the default, plus Dreams).
func get_status_duration(data: TowerData, status: StringName) -> float:
	var duration: float = data.status_duration if data.status_duration > 0.0 else EnemyStatuses.DEFAULT_DURATION[status]
	var multiplier := 1.0
	for card in _taken_cards():
		if card.status_id != status or not _applies_to(card, data):
			continue
		duration += card.status_duration_add * stacks[card.id] * resonance(card)
		multiplier *= pow(card.status_duration_multiplier, stacks[card.id])
	duration += LASTING_DREAMS_PER * rule_stacks(&"lasting_dreams")  # Lasting Dreams: every status +1 s
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
	return _rule_map().has(rule)

# Stacks taken of the cards with rule `rule` (stacking rule cards: Hush, Sharp Beaks, Longer Flight).
func rule_stacks(rule: StringName) -> int:
	return _rule_map().get(rule, 0)

# The rules of the taken cards (rule_id and extra_rules: a merged card grants the absorbed rule) ->
# total stacks, rebuilt only when _taken_cards() rebuilds. Also sets the per-hit early-out flags.
const HIT_RULES: Array[StringName] = [&"last_stand", &"hunters_patience", &"bitter_hedges", &"lone_hunter",
	&"rain_on_glass", &"skyward_gaze", &"deep_grip", &"head_start", &"deep_frost", &"falling_weight", &"murmur",
	&"first_light"]  # Every rule on_hit_multiplier reads
const CRIT_RULES: Array[StringName] = [&"glinting_dew", &"heavy_stones", &"seasoned_eye", &"full_moon",
	&"reckless_bloom", &"still_target", &"starlit_aim"]  # Every rule get_crit_chance_bonus reads
var _rules_of: Array = [null, {}]  # [the _taken_cards() array it was built from, {rule: stacks}]
var _any_hit_rule := false
var _any_crit_rule := false

func _rule_map() -> Dictionary:
	var taken := _taken_cards()
	if is_same(_rules_of[0], taken):
		return _rules_of[1]
	var rules := {}
	for card in taken:
		rules[card.rule_id] = int(rules.get(card.rule_id, 0)) + stacks[card.id]
		for extra in card.extra_rules:
			rules[extra] = int(rules.get(extra, 0)) + stacks[card.id]
	_rules_of = [taken, rules]
	_any_hit_rule = HIT_RULES.any(func(r: StringName) -> bool: return rules.has(r))
	_any_crit_rule = CRIT_RULES.any(func(r: StringName) -> bool: return rules.has(r))
	return rules

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
	if has_rule(&"winding_path"):
		add += roundi(path_length / WINDING_PATH_TILES * rule_power(&"winding_path"))  # Winding Path: +1 Dew per 5 path tiles (resonance scales it)
	return add

# Dew to clear `data` (Cleared Ground: −40% per stack, never below 1 Dew).
# Clearing always costs Dew (dream_design.md "Clearing always costs Dew"): Cleared Ground −25% per
# stack (max −50%), then +CLEAR_SURCHARGE Dew per obstacle cleared this run (dream_design.md "Clear
# prices, raised"); a Heartwood's Reach charge (`half_price`) halves it, and it never goes below half
# the base cost, rounded up (tree 6, boulder 9). Blight 9's ×2 is ObstacleClearer's, on top.
func get_clear_cost(data: ObstacleData, half_price: bool = false) -> int:
	if free_first_clears > 0:
		return 0  # Tend the Forest
	var discount := 0.0
	for card in _taken_cards():
		discount += card.clear_discount * stacks[card.id]
	var cost := roundi(data.clear_cost * (1.0 - minf(discount, CLEAR_DISCOUNT_MAX)))
	cost += CLEAR_SURCHARGE * run_state.tended_cells.size()  # Every clear so far, Burn Back's too
	if half_price:
		cost = ceili(cost / 2.0)
	return maxi(cost, ceili(data.clear_cost / 2.0))

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

# Whether obstacles can be cleared: after the opener (Tend the Forest, tag "opener") or Burn Back
# (dream_design.md "Clearing: one opener, the rest follow"). Taken cards are in the save, so this needs
# no saving of its own. Every card with stacks counts, not only _taken_cards(): taking Heartwood's Reach II
# replaces the base (the opener) there, and clearing must stay open (a flaky test_meta caught it).
func can_clear() -> bool:
	if clearing_open:
		return true
	for card in pool:
		if stacks.get(card.id, 0) > 0 and unlocks_clearing(card):
			return true
	return false

# The cards that unlock clearing: the opener, and Burn Back (it clears the trees itself).
static func unlocks_clearing(card: UpgradeData) -> bool:
	return card.tags.has(OPENER_TAG) or card.clears_obstacle != null

const OPENER_TAG := "opener"


# Make the clearing unlock obvious (dream_design.md "Clearing cards" / "Make the unlock obvious"):
# while clearing is locked, every clearing card leads with these lines and a corner tag; the card
# that opened it says so in Dreams this run and the Codex.
const OPENS_CLEARING_LINE := "Unlocks clearing"
const OPENS_CLEARING_TEXT := "Tend Withered Trees and move Mossy Boulders for Dew (Clear tool, C)."
const OPENS_CLEARING_TAG := "Opens clearing"
const OPENED_CLEARING_LINE := "Unlocked clearing"
var clearing_opened_by := ""  # The card id that unlocked clearing this run (saved)

func opens_clearing(card: UpgradeData) -> bool:
	return card != null and card.tags.has(OPENER_TAG) and not can_clear()

# Tend the Forest: clears that cost nothing, spent before any half-price charge (ObstacleClearer).
var free_first_clears := 0

func use_free_first_clear() -> bool:
	if free_first_clears <= 0:
		return false
	free_first_clears -= 1
	return true

func opened_clearing(card: UpgradeData) -> bool:
	return card != null and clearing_opened_by != "" and card.id == clearing_opened_by

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

# Whether a bend in the path is within `reach` cells of `cell`, diagonals included (Chebyshev: 1 =
# the 8 cells around it, 2 = the 5×5 square; dream_design.md card 21). A Warden inside a U-turn is
# diagonal to its corners, so it counts.
func is_beside_bend(cell: Vector2, reach: int = 1) -> bool:
	for dx in range(-reach, reach + 1):
		for dy in range(-reach, reach + 1):
			if (dx != 0 or dy != 0) and _bend_cells.has(cell + Vector2(dx, dy)):
				return true
	return false

# The plain stat cards' bonus for `data`: "soothe_bonus", "attack_speed_bonus", "range_bonus",
# "splash_bonus", "potency_bonus" (sum over taken cards covering its line / Warden). Rule cards come
# from DreamEffects rows (rule_total_cached) on top.
func get_stat_bonus(data: TowerData, stat: String) -> float:
	return _sum_stat(data, stat)

# Cached per card set (Wardens ask on every stat rebuild; 3x perf bar): cleared when _taken_cards() rebuilds
# or a resonance is locked.
var _stat_sums := {}  # stat -> {TowerData: total}
var _stat_sums_of: Array = [null, -1]  # [the _taken_cards() array, _resonance.size()]

func _sum_stat(data: TowerData, stat: String) -> float:
	var taken := _taken_cards()
	if not is_same(_stat_sums_of[0], taken) or _stat_sums_of[1] != _resonance.size():
		_stat_sums.clear()
		_stat_sums_of = [taken, _resonance.size()]
	var by_data: Dictionary = _stat_sums.get_or_add(stat, {})
	if by_data.has(data):
		return by_data[data]
	var total := 0.0
	for card in taken:
		if _applies_to(card, data):
			total += float(card.get(stat)) * stacks[card.id] * resonance(card)
	by_data[data] = total
	return total

func _applies_to(card: UpgradeData, data: TowerData) -> bool:
	return (card.stat_line == "" or card.stat_line == data.line) \
		and (card.stat_warden == "" or card.stat_warden == data.get_id())

# The cards taken this run whose effect counts (for the Dreams row and reports).
func get_taken_cards() -> Array[UpgradeData]:
	return _taken_cards(true).duplicate()  # Dormant half-dreamed cards too (is_dormant: shown asleep)

# Cards whose effect counts: taken, and not replaced by their Deepened version.
# A taken half-dreamed card whose families aren't all yours yet sleeps (no effect) unless
# `include_dormant`. Cached per state (has_rule and friends run per hit and per pool card in offers);
# the key covers stacks and unlocks, which tests also change directly.
func _taken_cards(include_dormant: bool = false) -> Array[UpgradeData]:
	var key := hash([stacks, unlocked, unlock_everything, pool.size(), _family_roots_seen])
	var cached: Array = _taken_cache.get(include_dormant, [])
	if not cached.is_empty() and cached[0] == key:
		return cached[1]
	var replaced := {}
	for card in pool:
		if card.is_deepened() and stacks.get(card.id, 0) > 0:
			replaced[card.deepens] = true
	var taken: Array[UpgradeData] = []
	for card in pool:
		if stacks.get(card.id, 0) > 0 and not replaced.has(card.id) and (include_dormant or not _is_asleep(card)):
			taken.append(card)
	_taken_cache[include_dormant] = [key, taken]
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
	# Straightaway: tiles of straight stretches of STRAIGHT_TILES+ (a run of equal steps a..b covers
	# tiles a..b+1)
	_straight_cells.clear()
	var run_start := 0
	for step in range(1, path.size()):
		if step == path.size() - 1 or path[step + 1] - path[step] != path[step] - path[step - 1]:
			if step - run_start + 1 >= STRAIGHT_TILES:
				for i in range(run_start, step + 1):
					_straight_cells[path[i]] = true
			run_start = step
	_heart_cache.clear()


# --- Taking cards -------------------------------------------------------------------------------------

func take(card: UpgradeData) -> void:
	if card_stacks(card.id) == 0:  # The first copy this run locks it
		var preview := resonance_preview(card)
		_resonance[card.id] = {"power": 1.0 + preview.bonus, "tag": preview.tag, "count": preview.count}  # Locked when taken
	if unlocks_clearing(card) and not can_clear():
		clearing_opened_by = card.id  # "Unlocked clearing" in Dreams this run and the Codex
	for family in half_dreamed_missing(card):  # The next family pick will include one of them
		if not _owed_families.has(family):
			_owed_families.append(family)
	stacks[card.id] = stacks.get(card.id, 0) + 1
	bump_board()
	_passed_count.erase(card.id)  # Taking a card resets its fade
	_passed_at.erase(card.id)
	if card.rule_id == &"wandering_mind":
		rerolls_left += WANDERING_MIND_REROLLS  # Adds to the Grove perk Second Thoughts
	if card.rule_id == &"thick_bark":
		_refill_bark()
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
	if card.free_first_clears_add > 0:
		free_first_clears += card.free_first_clears_add
	if card.free_clears_add > 0:
		run_state.add_free_clears(card.free_clears_add)
	if card.rule_id == &"court_of_the_eldest" or card.extra_rules.has(&"court_of_the_eldest"):
		_crown_court_eldest()  # Endless Rings absorbed Court of the Eldest (pool trim)
	if card.clears_obstacle != null:  # Burn Back: 2 Dew per tree, paid now (only offered when affordable)
		run_state.spend_dew(BURN_BACK_PER_TREE * count_obstacles(card.clears_obstacle))
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

# Omen reward (Lean Season): the next Dream (from act 2) includes a Legendary.
func add_legendary_dreams(count: int) -> void:
	_legendary_next += count

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
	_second_wind()
	_early_calls = 0  # Restless Night counts per block
	_rest_rules(_perfect)
	add_dreamlight(rest_dreamlight(drift_director.drifts_started))
	if is_boss_rest:
		# The freed light: +4 Dreamlight, and the Remember screen opens before the Dream.
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
	current_stray = null
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
	var was_stray := card == current_stray
	var replacement := _draw_card(drift_director.get_act(current_offer_drift), current_offer, false, was_stray)
	if was_stray:
		current_stray = replacement
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

# Whether `card` is the current offer's Stray Dream (DreamScreen shows the wisp tag).
func is_stray(card: UpgradeData) -> bool:
	return card != null and card == current_stray

func times_passed(card_id: String) -> int:
	return int(_passed_count.get(card_id, 0))

func _offer_counters() -> Dictionary:
	return {"dreams_seen": dreams_seen, "without_rare": _dreams_without_rare,
		"rare_left": _rare_dreams_left, "extra": _extra_cards_next, "entwined": _entwined_offered.duplicate(),
		"legendary": _legendary_next}

func _restore_offer_counters(counters: Dictionary) -> void:
	if counters.is_empty():
		return
	dreams_seen = counters.dreams_seen
	_dreams_without_rare = counters.without_rare
	_rare_dreams_left = counters.rare_left
	_extra_cards_next = counters.extra
	_legendary_next = counters.get("legendary", 0)
	_entwined_offered = counters.entwined.duplicate()

# Builds a Dream offer for after drift `drift_number` (see dream_design.md, "How offers work").
func make_offer(drift_number: int) -> Array[UpgradeData]:
	dreams_seen += 1
	_offer_drift = drift_number
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
	# The Stray Dream: from drift 10's rest (never a boss rest), one slot leans away from the build.
	# Lean Season's reward: one Legendary slot (act 2+), before the Stray and the normal slots.
	if _legendary_next > 0 and act >= 2 and offer.size() < size:
		var legendaries: Array = pool.filter(func(c: UpgradeData) -> bool:
			return c.rarity == UpgradeData.Rarity.LEGENDARY and not offer.has(c) and can_offer(c, act))
		if not legendaries.is_empty():
			offer.append(_weighted_pick(legendaries))
			_legendary_next -= 1
	current_stray = null
	if offer.size() < size and drift_number >= STRAY_FROM_DRIFT and not drift_director.is_boss_drift(drift_number):
		current_stray = _draw_card(act, offer, false, true)
		if current_stray != null:
			offer.append(current_stray)
	var force_rare := drift_director.is_boss_drift(drift_number) or _dreams_without_rare >= pity_after \
		or _rare_dreams_left > 0
	_rare_dreams_left = maxi(_rare_dreams_left - 1, 0)
	var rare_tried := false  # The forced Rare is tried in one slot only (faded Rares: one chance per offer)
	while offer.size() < size:
		var want_rare := force_rare and not rare_tried and not offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better())
		rare_tried = rare_tried or want_rare
		var card := _draw_card(act, offer, want_rare)
		if card == null:
			break
		offer.append(card)
	if offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()):
		_dreams_without_rare = 0
	else:
		_dreams_without_rare += 1
		if force_rare:  # Its Rares were all faded (act 1): the next offer tries for a Rare again
			_rare_dreams_left = maxi(_rare_dreams_left, 1)
	return offer

# Whether `card` could be offered with every Need met (hard and soft): the "offered with 7 Wardens"
# sense, for tests, tools and the Needs text.
func is_eligible(card: UpgradeData, act: int = 1) -> bool:
	return can_offer(card, act) and soft_needs_met(card) and _requires_met(card)

# Whether `card` can be drawn at all (hard Needs). Unmet soft Needs only lower its weight
# (dream_design.md "Adapt, don't get handed").
func can_offer(card: UpgradeData, act: int = 1) -> bool:
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
	if card.tags.has("clearing") and not unlocks_clearing(card) and not can_clear():
		return false  # Clearing follow-ups only once clearing is unlocked (the opener first)
	if card.is_bittersweet() and not allow_bittersweet:
		return false
	# A card never costs the last leaves (Deep Sleep).
	if card.leaves_now < 0 and run_state.leaves + card.leaves_now <= 0:
		return false
	if card.max_leaves_add < 0 and run_state.max_leaves + card.max_leaves_add < 1:
		return false
	# Clearing cards only when the map is still full enough to matter.
	if card.clears_obstacle != null and run_state.dew < BURN_BACK_PER_TREE * count_obstacles(card.clears_obstacle):
		return false  # Burn Back: only when you can pay for every tree
	if card.min_obstacles > 0 and count_obstacles(card.clears_obstacle) < card.min_obstacles:
		return false
	if not _meets_needs(card):
		return false
	if not discovery_met(card):
		return false  # Discovery unlocks: combo, Kinship and Warden cards wait until seen once
	if card.unlocks != null and is_unlocked(card.unlocks.get_id()):
		return false
	if not _requires_met(card) and not is_half_dreamed(card):
		return false  # A half-dreamed combo card may be offered before its families are all yours
	return true

# The hard run-state and card Needs (dream_design.md "Card requirements"). Only gates new offers:
# losing a requirement never takes a card away. A follow-up's rank Needs stay hard.
func _meets_needs(card: UpgradeData) -> bool:
	if card.requires_tag != "" and not SOFT_TAG_NEEDS.has(card.requires_tag) \
			and count_taken_with_tag(card.requires_tag) < card.requires_tag_count:
		return false
	if not card.requires_any.is_empty() and not card.requires_any.any(owns):
		return false
	if card.requires_tag != "" and not _rank_needs_met(card):
		return false
	if card.min_reaction_pairs > 0 and count_reaction_pairs() < card.min_reaction_pairs:
		return false
	if card.requires_status != &"" and not owned_statuses().has(card.requires_status):
		return false
	if not card.requires_any_status.is_empty() and not card.requires_any_status.any(func(s: StringName) -> bool: return owned_statuses().has(s)):
		return false
	if card.max_range_owned > 0.0 and not owns_range_at_most(card.max_range_owned):
		return false
	if card.min_families > 0 and count_owned_families() < card.min_families:
		return false
	if card.max_attackers > 0 and count_attackers() > card.max_attackers:
		return false  # Few and Mighty: never offered to a wide build (a hard Need, playtest #98)
	if card.min_non_attackers > 0 and _towers().size() - count_attackers() < card.min_non_attackers:
		return false
	if card.min_kinships > 0 and count_kinships() < card.min_kinships:
		return false
	if card.min_owned_statuses > 0 and owned_statuses().size() < card.min_owned_statuses:
		return false
	return true

# Soft Needs (×SOFT_NEED_WEIGHT when unmet, never a gate): min_attackers, count_warden, and the
# Nurture openers' rank Needs (cards with no requires_tag).
func soft_needs_met(card: UpgradeData) -> bool:
	if SOFT_TAG_NEEDS.has(card.requires_tag) and count_taken_with_tag(card.requires_tag) < card.requires_tag_count:
		return false  # Nurture follow-ups tempt, they don't wait for a Nurture card (hard board Needs stay)
	if card.requires_tag == "" and not _rank_needs_met(card):
		return false
	if card.min_attackers > 0 and count_attackers() < card.min_attackers:
		return false
	if card.count_warden != "" and count_wardens(card.count_warden) < card.min_warden_count:
		return false
	if card.count_line != "" and _towers().filter(func(t: Tower) -> bool: return t.tower_data.line == card.count_line).size() < card.min_warden_count:
		return false
	return true

func _rank_needs_met(card: UpgradeData) -> bool:
	if card.min_rank_dew > 0 and run_state.rank_dew_spent < card.min_rank_dew:
		return false
	return card.min_rank_count <= 0 or count_ranked(card.min_rank_owned) >= card.min_rank_count

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

# Statuses applied by Wardens unlocked this run (cached per unlock state).
func owned_statuses() -> Dictionary:
	var roster := _roster()
	var key := hash([unlocked, unlock_everything, roster.size(), pool.size()])
	if not _statuses_cache.is_empty() and _statuses_cache[0] == key:
		return _statuses_cache[1]
	var statuses := {}
	var forms := roster.duplicate()
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
	_statuses_cache = [key, statuses]
	return statuses

# Taken cards carrying `tag` (each card once, however many stacks).
func count_taken_with_tag(tag: String) -> int:
	var count := 0
	for card in _taken_cards():
		if card.tags.has(tag):
			count += 1
	return count

func _draw_card(act: int, exclude: Array[UpgradeData], want_rare: bool, stray: bool = false) -> UpgradeData:
	var has_bittersweet := exclude.any(func(c: UpgradeData) -> bool: return c.is_bittersweet())
	var eligible: Array[UpgradeData] = []
	for card in pool:
		if exclude.has(card) or (has_bittersweet and card.is_bittersweet()):
			continue  # At most one bittersweet card per offer
		if card.rarity == UpgradeData.Rarity.COMMON and has_rule(&"lucid_dreaming"):
			continue  # Lucid Dreaming: no Commons
		if want_rare and is_half_dreamed(card):
			continue  # Never in a guaranteed Rare slot (boss rests, pity, owed Rares)
		if can_offer(card, act):
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
			return _weighted_pick(of_rarity.filter(func(c: UpgradeData) -> bool: return get_passed_weight(c) > 0.0), stray)
		tried.append(rarity)
		rarity = _roll_rarity(act, want_rare, tried)
	# Nothing else can fill the slot: faded cards after all (passed over in the offer before only if
	# there's truly nothing else).
	var left := eligible
	if want_rare and eligible.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()):
		left = eligible.filter(func(c: UpgradeData) -> bool: return c.is_rare_or_better())
	var fresh := left.filter(func(c: UpgradeData) -> bool: return get_passed_weight(c) > 0.0)
	return _weighted_pick(fresh if not fresh.is_empty() else left, stray)

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
		# A forced Rare+ slot whose Rares are all faded, where Legendaries can't appear (act 1): Uncommon
		# (make_offer then owes the next offer a Rare).
		if want_rare:
			for i in [UpgradeData.Rarity.RARE, UpgradeData.Rarity.UNCOMMON, UpgradeData.Rarity.COMMON]:
				if not skip.has(i):
					return i
		return -1
	var roll := _rng.randi_range(1, total)
	for i in weights.size():
		roll -= weights[i]
		if roll <= 0:
			return i
	return 0

# The build tags your Dreams have steered you to (dream_design.md "Pool trim", layer 2): the archetype
# tags of the cards you've taken (a Legendary's too). Families, statuses and the old direction tags stay
# on the cards for rules and discovery but never boost (round 3: family lines no longer weigh either).
# Tall and overgrowth push each other away.
func _owned_tags() -> Array:
	var owned := {}
	var opposed := {}
	var counts := {}
	for card in _taken_cards():
		for tag in card.tags:
			if ARCHETYPE_TAGS.has(tag):
				owned[tag] = true
				counts[tag] = int(counts.get(tag, 0)) + 1
	for tag in counts:  # Round 4: the other direction halves only once you own OPPOSED_FROM of this one
		if OPPOSITE_DIRECTION.has(tag) and counts[tag] >= OPPOSED_FROM:
			opposed[OPPOSITE_DIRECTION[tag]] = true
	return [owned, opposed]

# Whether `card` belongs to the build (shares a tag the run has committed to).
func is_in_build(card: UpgradeData) -> bool:
	return _card_in_build(card, _owned_tags()[0])

# Shares a tag the run owns. A cross-family combo card counts its family tags only once all its
# families are yours (while half-dreamed it's a temptation toward a new family, not more of the build).
func _card_in_build(card: UpgradeData, owned: Dictionary) -> bool:
	var families := _combo_families(card)
	var skip := {}
	if families.size() >= 2 and families.keys().any(func(family: String) -> bool: return not is_unlocked(family)):
		for root in _family_roots():
			skip[root.line] = true
	return card.tags.any(func(tag: String) -> bool: return owned.has(tag) and not skip.has(tag))

# Picks one of `cards` by weight: build tags (×tag_weight), unmet soft Needs, opposed directions, the
# clearing boost, the passed-over fade. `stray` turns the build weighting around (the Stray Dream):
# build cards ×STRAY_IN_BUILD_WEIGHT, soft Needs ignored.
func _weighted_pick(cards: Array, stray: bool = false) -> UpgradeData:
	var tags := _owned_tags()
	var owned: Dictionary = tags[0]
	var opposed: Dictionary = tags[1]
	var weights: Array[float] = []
	var total := 0.0
	var clearing_locked := not can_clear()
	for card in cards:
		var in_build := _card_in_build(card, owned)
		var weight := 1.0
		if stray:
			weight = STRAY_IN_BUILD_WEIGHT if in_build else 1.0
		else:
			weight = tag_weight if in_build else 1.0
			if not soft_needs_met(card):
				weight *= SOFT_NEED_WEIGHT
			for tag in opposed:  # e.g. an overgrowth card while you've gone tall
				if card.tags.has(tag) and not card.tags.has(OPPOSITE_DIRECTION[tag]):
					weight *= OPPOSITE_WEIGHT
		if clearing_locked and card.tags.has(OPENER_TAG):
			weight *= CLEARING_LOCKED_WEIGHT  # The opener, until clearing is unlocked
		var half_missing := half_dreamed_missing(card)
		if not half_missing.is_empty():
			var declined := half_missing.any(func(family: String) -> bool: return _declined_families.has(family))
			weight *= HALF_DREAMED_DECLINED_WEIGHT if declined else HALF_DREAMED_WEIGHT
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
		"owed_families": _owed_families.duplicate(), "declined_families": _declined_families.duplicate(),
		"walls_planted": _walls_planted, "glimmer_shards": glimmer_shards,
		"legendary_next": _legendary_next,
		"clearing_opened_by": clearing_opened_by,
		"free_first_clears": free_first_clears,
		"resonance": _resonance.duplicate(),
		"rng_state": str(_rng.state),  # A string: JSON would round a 64-bit int
	}

func load_save(data: Dictionary) -> void:
	unlocked.clear()
	for id in data.get("unlocked", []):
		unlocked[id] = true
	stacks.clear()
	var saved_stacks: Dictionary = data.get("stacks", {})
	for id in saved_stacks:
		var kept: String = MERGED_CARDS.get(id, id)  # Cards cut or merged by the power pass (dream_audit.md)
		if kept != "":
			stacks[kept] = maxi(int(stacks.get(kept, 0)), 1 if kept != id else int(saved_stacks[id]))  # JSON gives floats
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
	_owed_families.assign(data.get("owed_families", []))
	_declined_families.assign(data.get("declined_families", []))
	_passed_count.clear()
	_passed_at.clear()
	for key in ["passed_count", "passed_at"]:
		var saved: Dictionary = data.get(key, {})
		var into: Dictionary = _passed_count if key == "passed_count" else _passed_at
		for id in saved:
			into[id] = int(saved[id])  # JSON gives floats
	_attackers_planted = int(data.get("attackers_planted", 0))
	_walls_planted = int(data.get("walls_planted", 0))
	glimmer_shards = int(data.get("glimmer_shards", 0))
	clearing_opened_by = String(data.get("clearing_opened_by", ""))
	free_first_clears = int(data.get("free_first_clears", 0))
	_resonance = data.get("resonance", {}).duplicate()
	_legendary_next = int(data.get("legendary_next", 0))
	_refill_bark()  # Saved at a rest, where Thick Bark is full again
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
# With none, unranked attacking Wardens get rank I instead.
func sunlit_rest() -> Array[Tower]:
	var raised: Array[Tower] = []
	var seller := get_node_or_null("%TowerSeller")
	var ranked: Array = _towers().filter(func(t: Tower) -> bool:
		return t.rank > 0 and t.rank != 2 and t.rank < mini(FREE_RANK_MAX, get_max_rank_for(t)) and t.can_nurture())  # Free ranks stop at VII (V unless the Eldest)
	if ranked.is_empty():  # An opener (Pool trim round 2): rank I to the attacking Warden nearest the Heartwood
		ranked = _towers().filter(func(t: Tower) -> bool:
			return t.rank == 0 and t.tower_data.can_attack and t.can_nurture())
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
	if tower.tower_data.get_id() == "thornwall":
		_walls_planted += 1  # Weathered Walls
	_mark_fresh(tower)
	_watch_growth(tower)
	_discover_warden(tower)
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
	var paid := last_clear_paid
	last_clear_paid = 0
	if run_state.clearing_without_seeds:
		return
	var dew := 0
	for card in _taken_cards():
		dew += card.dew_per_obstacle_clear * stacks[card.id]
	if has_rule(&"reclaimed_earth"):
		dew += floori(paid * RECLAIMED_REFUND)  # 40% of what the clear cost: never a profit
		run_state.fertile_cells[cell] = true
	if dew > 0:
		run_state.earn_dew_at(dew, map_generator.MAP_GRID.calculate_map_position(cell))

# Spore Cascade: a cleansed creature's Spored stacks spread to the nearest creatures.
func _on_enemy_cleansed(enemy: Node2D) -> void:
	_hurried_harvest(enemy)
	_count_herd(enemy)
	_glimmer(enemy)
	_last_breath(enemy)
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

# Kinships on the map (Tower Code's Kinships; 0 outside a run or before it exists).
# Sims and tools: >= 0 stands in for the Kinships on the map (tools/build_packages.gd).
var sim_kinships := -1

func count_kinships() -> int:
	if sim_kinships >= 0:
		return sim_kinships
	var kinships = Kinships.find(self)
	if kinships == null or not kinships.has_method("count"):
		return 0
	return int(kinships.call("count"))


# --- Half-dreamed combo cards (dream_design.md "Adapt, don't get handed" 5) ------------------------
# A card whose `requires` names Wardens from 2+ families can be offered once you own one of them and
# every missing one can still come from a family pick. It sleeps until all are yours; taking it makes
# the next family pick include (one of) the missing families.

var _family_by_warden := {}  # Warden id -> its family's base id
var _family_roots_seen := -1
var _combo_cache := {}  # Card id -> {family: true} its requires name (_combo_families)

# The family (base Warden id) `warden_id` belongs to; "" for Sprout, Thornwall and non-Wardens.
func family_of(warden_id: String) -> String:
	var roots := _family_roots()
	if roots.size() != _family_roots_seen:  # MetaRun adds Grove families at run start
		_family_roots_seen = roots.size()
		_family_by_warden.clear()
		_combo_cache.clear()
		for root in roots:
			_map_family(root, root.get_id())
	return _family_by_warden.get(warden_id, "")

func _map_family(data: TowerData, family: String) -> void:
	if data == null or _family_by_warden.has(data.get_id()):
		return
	_family_by_warden[data.get_id()] = family
	for next in data.evolves_to:
		_map_family(next as TowerData, family)

# Families the profile can pick (the family pick's roster).
func _family_roots() -> Array:
	var screen := get_node_or_null("%FamilyPickScreen")
	return screen.families if screen != null and "families" in screen else []

func _requires_met(card: UpgradeData) -> bool:
	for requirement in card.requires:
		if not owns(requirement):
			return false
	return true

# The missing families that make `card` half-dreamed ([] = it isn't: not a combo, already whole,
# none of its families yours, or a missing one can't be picked any more).
func half_dreamed_missing(card: UpgradeData) -> Array[String]:
	var missing: Array[String] = []
	if card.requires.size() < 2 or _requires_met(card):
		return missing
	var families := {}
	for id in card.requires:
		var family := family_of(id)
		if family != "":
			families[family] = true
	if families.size() < 2:
		return missing
	var owned_any := false
	for family in families:
		if is_unlocked(family):
			owned_any = true  # A form of an owned family (Stormcap) counts as that family here
		else:
			missing.append(family)
	var pickable: Array = _family_roots().map(func(d: TowerData) -> String: return d.get_id())
	var next_pick := next_family_pick_drift()
	if not owned_any or next_pick < 0 or next_pick - _now_drift() > HALF_DREAMED_WITHIN \
			or missing.any(func(family: String) -> bool: return not pickable.has(family)):
		missing.clear()
	return missing

func is_half_dreamed(card: UpgradeData) -> bool:
	return not half_dreamed_missing(card).is_empty()

# Taken, but asleep until its families are all yours.
func is_dormant(card: UpgradeData) -> bool:
	return card_stacks(card.id) > 0 and _is_asleep(card)

# The drift whose boss is followed by the next family pick (-1 = none left: never after drift 75's).
func next_family_pick_drift() -> int:
	var per: int = drift_director.drifts_per_act
	var now := _now_drift()
	var next := (now / per + 1) * per
	var last := maxi(drift_director.drifts.size(), 4 * per) - per
	return next if next <= last else -1

func _now_drift() -> int:
	return _offer_drift if is_offering() or _offer_drift > drift_director.drifts_started else drift_director.drifts_started

# "Needs Dewdrop: a family you can pick after the Hollow Stag (drift 25)" ("" if not half-dreamed).
func half_dreamed_text(card: UpgradeData) -> String:
	var missing := half_dreamed_missing(card)
	if missing.is_empty():
		return ""
	var drift := next_family_pick_drift()
	var boss := _boss_name(drift)
	if boss.begins_with("The "):
		boss = "the " + boss.substr(4)  # "after the Hollow Stag"
	var when := "after %s (drift %d)" % [boss, drift] if boss != "" else "at the family pick after drift %d" % drift
	# Never a Warden's name (dream_design.md "How Needs are shown on a card"): the missing statuses,
	# else the missing families.
	var owned := owned_statuses()
	var statuses: Array = card.shows_statuses.filter(func(s: StringName) -> bool: return not owned.has(s))
	if not statuses.is_empty():
		var names: Array = statuses.map(func(s: StringName) -> String: return IconInfo.status_name(s))
		return "Needs %s: a family that brings it may come %s" % [" + ".join(names), when]
	var families: Array = missing.map(get_display_name)
	return "Needs the %s %s: you can pick it %s" % [" and ".join(families), "family" if families.size() == 1 else "families", when]

func _boss_name(drift: int) -> String:
	if drift < 1 or drift > drift_director.drifts.size():
		return ""
	for group in drift_director.drifts[drift - 1].groups:
		for entry in group.entries:
			if entry.enemy != null and entry.enemy.is_boss:
				return entry.enemy.display_name
	return ""

# The families taken half-dreamed cards owe the next family pick; clears them (FamilyPickScreen).
func take_owed_families() -> Array[String]:
	var owed := _owed_families.duplicate()
	_owed_families.clear()
	return owed

# A cross-family combo card without all its Wardens (cheap checks first: _taken_cards runs per hit).
func _is_asleep(card: UpgradeData) -> bool:
	if card.requires.size() < 2 or _requires_met(card):
		return false
	return _combo_families(card).size() >= 2

# The families (base Warden ids) a card's `requires` names Wardens from (cached per card).
func _combo_families(card: UpgradeData) -> Dictionary:
	family_of("")  # Refreshes the maps (and this cache) when the family roster changed
	if _combo_cache.has(card.id):
		return _combo_cache[card.id]
	var families := {}
	for id in card.requires:
		var family := family_of(id)
		if family != "":
			families[family] = true
	_combo_cache[card.id] = families
	return families

# A family pick was made (FamilyPickScreen): the families it offered but the player didn't take are
# "declined" until the next pick (their half-dreamed cards ×0.3). `chosen` = "" for a Blessing.
func note_family_pick(offered: Array, chosen: String) -> void:
	_declined_families.clear()
	for id in offered:
		if id != chosen:
			_declined_families.append(id)


# --- Generic Rares (dream_design.md "Generic Rares", 135–141) ---------------------------------------

# Once per hit, from Tower.hit (after get_hit_damage_multiplier): First Light (×3 on a Warden's first
# hit on each nightmare), Last Stand, Hunter's Patience and Bitter Hedges. 1.0 without those cards.
func on_hit_multiplier(tower: Tower, enemy: Node2D) -> float:
	_rule_map()
	if not _any_hit_rule or enemy == null or not is_instance_valid(enemy):
		return 1.0  # The common case: no per-hit card owned (Warden hits are the hot path)
	var bonus := 0.0
	if has_rule(&"last_stand") and is_near_heartwood(enemy):
		bonus += LAST_STAND_BONUS * rule_power(&"last_stand")
	if has_rule(&"hunters_patience"):
		if enemy.elite:
			bonus += HUNTERS_PATIENCE_ELITE * rule_power(&"hunters_patience")
		elif enemy.enemy_data != null and enemy.enemy_data.is_boss:
			bonus += HUNTERS_PATIENCE_BOSS * rule_power(&"hunters_patience")
	bonus += get_bitter_bonus(enemy)
	if has_rule(&"lone_hunter") and _is_alone(enemy):
		bonus += LONE_HUNTER_BONUS[rule_level(&"lone_hunter")] * rule_power(&"lone_hunter")
	if tower != null and tower.tower_data.line == "light" and has_rule(&"rain_on_glass") \
			and enemy.statuses.has(EnemyStatuses.DAMP):
		bonus += RAIN_ON_GLASS_PER * rule_stacks(&"rain_on_glass") * rule_power(&"rain_on_glass")  # Rain on Glass
	if has_rule(&"skyward_gaze") and enemy.enemy_data != null and enemy.enemy_data.trait_kind == EnemyData.Trait.FLYING:
		bonus += SKYWARD_BONUS * rule_power(&"skyward_gaze")
	bonus += _thin_family_hit_bonus(tower, enemy)  # Deep Grip, Murmur
	var multiplier := 1.0 + bonus
	if has_rule(&"first_light") and tower != null:
		var key := "%d:%d" % [tower.get_instance_id(), enemy.get_instance_id()]
		if not _first_hits.has(key):
			_first_hits[key] = true
			multiplier *= FIRST_LIGHT_MULTIPLIER
			if _first_hits.size() > 4096:
				_first_hits.clear()  # Forget long-gone nightmares now and then
	return multiplier

# Last Stand: within LAST_STAND_CELLS of the Heartwood.
func is_near_heartwood(enemy: Node2D) -> bool:
	var cell: Vector2 = enemy.get_current_cell()
	var heart: Vector2 = map_generator.endPath
	return maxf(absf(cell.x - heart.x), absf(cell.y - heart.y)) <= LAST_STAND_CELLS

# Bitter Hedges: +3% per Thornwall passed in the last 2 s (max +15%).
func get_bitter_bonus(enemy: Node2D) -> float:
	var passed: Dictionary = _bitter_walls.get(enemy.get_instance_id(), {})
	var count := 0
	for wall in passed:
		if _briar_clock - passed[wall] <= BITTER_TIME:
			count += 1
	return minf(BITTER_PER * count, BITTER_MAX)

func _bitter_pass(enemy: Node2D, cell: Vector2) -> void:
	for wall in _towers():
		if wall.tower_data.line == "wall" and absf(wall.cell.x - cell.x) + absf(wall.cell.y - cell.y) == 1.0:
			var passed: Dictionary = _bitter_walls.get_or_add(enemy.get_instance_id(), {})
			passed[wall.get_instance_id()] = _briar_clock

# Thinning the Herd: a dispel counts for every attacking Warden with the nightmare in range.
func _count_herd(enemy: Node2D) -> void:
	if not has_rule(&"thinning_the_herd"):
		return
	var cell_size: float = map_generator.MAP_GRID.cell_size.x
	for tower in _towers():
		if tower.tower_data.can_attack \
				and tower.global_position.distance_to(enemy.global_position) <= tower.get_range_cells() * cell_size:
			_herd[tower.get_instance_id()] = int(_herd.get(tower.get_instance_id(), 0)) + 1

func get_herd_bonus(tower: Tower) -> float:
	return minf(HERD_PER * int(_herd.get(tower.get_instance_id(), 0)), HERD_MAX) if tower != null else 0.0

# Steadfast (old_growth): drifts `tower` has stood (a node meta, so growing in place keeps it; RunSaver keeps it
# across a save).
static func drifts_stood(tower: Tower) -> int:
	return int(tower.get_meta(&"drifts_stood", 0)) if tower != null else 0

func get_old_growth_bonus(tower: Tower) -> float:
	var stood := drifts_stood(tower)
	for step in OLD_GROWTH_STEPS:
		if stood >= step[0]:
			return step[1]
	return 0.0


# --- Generic Commons and Uncommons (142–156) and the second batch (157–168) -------------------------
# dream_design.md. Per-Warden damage / range report through DreamEffects; per-hit bonuses are in
# on_hit_multiplier; the rest are hooks other scripts ask (RunState, TowerSeller, DriftDirector).

# Gathered Dew: extra share of dispel Dew (RunState._scaled_dispel_dew adds it to Rich Dew).
func get_dew_gain_bonus() -> float:
	return GATHERED_DEW_PER * rule_stacks(&"gathered_dew") * rule_power(&"gathered_dew")

# The refund share for selling (TowerSeller.get_refund asks). Fair Trade was cut (dream_audit.md), so
# no card changes it now.
func get_refund_share(base: float, _resting: bool) -> float:
	return base

# Call of the Wild: calling a drift early pays double, capped at 20 (DriftDirector.get_call_early_bonus).
func get_call_early_bonus(uncapped: int, cap: int) -> int:
	if not has_rule(&"call_of_the_wild"):
		return mini(uncapped, cap)
	return mini(mini(uncapped, cap) * 2, maxi(CALL_OF_THE_WILD_CAP, cap))

# Thick Bark: RunState.lose_leaves asks this first; true = this leak is saved (whole, even a boss's).
func absorb_leak() -> bool:
	if bark_charges <= 0 or not has_rule(&"thick_bark"):
		return false
	bark_charges -= 1
	bark_changed.emit(bark_charges)
	return true

func _refill_bark() -> void:
	bark_charges = THICK_BARK_CHARGES[rule_level(&"thick_bark")] if has_rule(&"thick_bark") else 0
	bark_changed.emit(bark_charges)

# At each rest: Mending Bark, Thick Bark refills, Fresh Growth ends, Underdog picks its Wardens,
# Echoing Steps ends.
func _rest_rules(perfect: bool) -> void:
	if has_rule(&"deep_well"):  # Deep Well: interest on banked Dew
		run_state.add_dew(deep_well_interest(rule_power(&"deep_well")))
	if perfect and has_rule(&"mending_bark"):
		run_state.regrow_leaves(1)
	_refill_bark()
	for tower in _towers():
		tower.remove_meta(&"fresh_growth")
	_pick_underdogs()

# Fresh Growth: planted or grown during a drift (not at a rest) marks a Warden until the next rest.
func _mark_fresh(tower: Tower) -> void:
	if has_rule(&"fresh_growth") and not drift_director.resting:
		tower.set_meta(&"fresh_growth", true)

func _watch_growth(tower: Tower) -> void:
	if tower.has_signal("evolved") and not tower.evolved.is_connected(_mark_fresh):
		tower.evolved.connect(_mark_fresh)
	if tower.has_signal("evolved") and not tower.evolved.is_connected(_discover_warden):
		tower.evolved.connect(_discover_warden)

func is_fresh(tower: Tower) -> bool:
	return tower != null and tower.get_meta(&"fresh_growth", false)

# Underdog: the attacking Wardens that soothed least this block get a mark for the next block
# (Tower Code's glow reads is_underdog).
func _pick_underdogs() -> void:
	for tower in _towers():
		tower.remove_meta(&"underdog")
	if not has_rule(&"underdog") or DamageLog.instance == null:
		return
	var attackers: Array = _towers().filter(func(t: Tower) -> bool: return t.tower_data.can_attack)
	attackers.sort_custom(func(a: Tower, b: Tower) -> bool:
		return float(DamageLog.instance.get_tower_stats(a).get("block", 0.0)) \
			< float(DamageLog.instance.get_tower_stats(b).get("block", 0.0)))
	var count: int = UNDERDOG[rule_level(&"underdog")][0]
	for i in mini(count, attackers.size()):
		attackers[i].set_meta(&"underdog", true)

func is_underdog(tower: Tower) -> bool:
	return tower != null and tower.get_meta(&"underdog", false)

# Bitter Hedges' live line: Thornwalls touching the path (a nightmare passing them counts each).
func walls_beside_path() -> int:
	var count := 0
	for wall in _towers():
		if wall.tower_data.line != "wall":
			continue
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			if _path_index.has(wall.cell + offset):
				count += 1
				break
	return count

# Deep Well: interest on the Dew banked now (the rest pays it; the card's live line shows it).
func deep_well_interest(power: float = 1.0) -> int:
	return mini(roundi(DEEP_WELL_MAX * power), floori(run_state.dew * DEEP_WELL_RATE * power))

# Live lines for cards whose value only exists during a drift (Crowded Path, Lone Hunter, Last Stand):
# sampled every DRIFT_SAMPLE_EVERY s while nightmares walk; at a rest the cards show the last drift's
# averages (last_drift_stats, empty before drift 1).
const DRIFT_SAMPLE_EVERY := 0.5
var last_drift_stats := {}  # {in_range: avg nightmares in an attacking Warden's range, alone: share, near: share}
var _drift_sums := {"samples": 0, "in_range": 0.0, "alone": 0.0, "near": 0.0}
var _sample_left := 0.0

func _sample_drift(delta: float) -> void:
	if drift_director == null or drift_director.resting:
		if _drift_sums.samples > 0:  # The drift's over: keep its averages for the rest
			var n := float(_drift_sums.samples)
			last_drift_stats = {"in_range": _drift_sums.in_range / n, "alone": _drift_sums.alone / n, "near": _drift_sums.near / n}
			_drift_sums = {"samples": 0, "in_range": 0.0, "alone": 0.0, "near": 0.0}
		return
	_sample_left -= delta
	if _sample_left > 0.0:
		return
	_sample_left = DRIFT_SAMPLE_EVERY
	var enemies: Array = spawner.get_enemies()
	if enemies.is_empty():
		return
	var attackers := _towers().filter(func(t: Tower) -> bool: return t.tower_data.can_attack)
	var in_range := 0.0
	for tower in attackers:
		in_range += count_in_range(tower)
	var alone := enemies.filter(func(e: Node2D) -> bool: return _is_alone(e)).size()
	var near := enemies.filter(func(e: Node2D) -> bool: return is_near_heartwood(e)).size()
	_drift_sums.samples += 1
	_drift_sums.in_range += in_range / maxf(attackers.size(), 1.0)
	_drift_sums.alone += float(alone) / enemies.size()
	_drift_sums.near += float(near) / enemies.size()

# Crowded Path: nightmares in the Warden's range right now.
var _counting := false  # count_in_range asks the range, whose rows ask Crowded Path again

func count_in_range(tower: Tower) -> int:
	if _counting:
		return 0
	_counting = true
	var reach: float = tower.get_range_cells() * map_generator.MAP_GRID.cell_size.x
	var count := 0
	for enemy in spawner.get_enemies():
		if tower.global_position.distance_to(enemy.global_position) <= reach:
			count += 1
	_counting = false
	return count

# Lone Hunter: no other nightmare within 2 cells of `enemy`.
func _is_alone(enemy: Node2D) -> bool:
	var reach: float = LONE_HUNTER_CELLS * map_generator.MAP_GRID.cell_size.x
	for other in spawner.get_enemies():
		if other != enemy and other.global_position.distance_to(enemy.global_position) <= reach:
			return false
	return true

# Glimmering Hunt: a dispelled elite has a 30% chance to drop a Dreamlight shard (10 = 1 Dreamlight),
# up to 3 Dreamlight per run from this card, apart from the Great Dreamcatcher's shards and cap.
func _glimmer(enemy: Node2D) -> void:
	if not has_rule(&"glimmering_hunt") or not enemy.elite or _glimmer_rng.randf() >= GLIMMER_CHANCE \
			or glimmer_shards >= SHARDS_PER_DREAMLIGHT * GLIMMER_DREAMLIGHT_MAX:
		return
	glimmer_shards += 1
	if glimmer_shards % SHARDS_PER_DREAMLIGHT == 0:
		add_dreamlight(1)

# Last Breath: a dispelled nightmare bursts for 10% (II 15%) of its max health on nightmares within
# 1 cell; bosses' bursts are capped at 5% of the boss's max health. Effect damage (tag last_breath);
# a nightmare the burst dispels never bursts itself.
var _bursting := false

func _last_breath(enemy: Node2D) -> void:
	if _bursting or not has_rule(&"last_breath"):
		return
	var share: float = LAST_BREATH_SHARE[rule_level(&"last_breath")]
	if enemy.enemy_data != null and enemy.enemy_data.is_boss:
		share = minf(share, LAST_BREATH_BOSS_CAP)
	var burst: float = enemy.max_health * share
	var reach: float = LAST_BREATH_CELLS * map_generator.MAP_GRID.cell_size.x
	var near: Array = spawner.get_enemies().filter(func(other: Node2D) -> bool:
		return other != enemy and not other.is_cleansed and other.global_position.distance_to(enemy.global_position) <= reach)
	_bursting = true
	for other in near:
		if is_instance_valid(other) and not other.is_cleansed:
			other.take_damage(burst, "", true, false, null, &"last_breath")
	_bursting = false

# Heart of the Maze: the attacking Warden furthest along the path from any other attacking Warden
# (path steps between their closest route tiles; ties go nearer the Heartwood). Cached until the
# route or the Wardens change. null with fewer than 2 attackers.
func get_heart_of_maze() -> Tower:
	if not has_rule(&"heart_of_the_maze"):
		return null  # No card, no heart (DreamMarks draws whatever this returns)
	var attackers: Array = _towers().filter(func(t: Tower) -> bool: return t.tower_data.can_attack)
	var key := hash([attackers.map(func(t: Tower) -> Vector2: return t.cell), path_length])
	if not _heart_cache.is_empty() and _heart_cache[0] == key:
		return _heart_cache[1] if is_instance_valid(_heart_cache[1]) else null
	var best: Tower = null
	if attackers.size() >= 2 and not _path_index.is_empty():
		var steps := {}
		for tower in attackers:
			steps[tower] = _closest_step(tower.cell)
		var best_gap := -1
		for tower in attackers:
			var gap := 1 << 30
			for other in attackers:
				if other != tower:
					gap = mini(gap, absi(steps[tower] - steps[other]))
			if gap > best_gap or (gap == best_gap and steps[tower] > steps[best]):
				best_gap = gap
				best = tower
	_heart_cache = [key, best]
	return best

func _closest_step(cell: Vector2) -> int:
	var best_step := 0
	var best_distance := INF
	for route_cell in _path_index:
		var distance: float = cell.distance_squared_to(route_cell)
		if distance < best_distance:
			best_distance = distance
			best_step = _path_index[route_cell]
	return best_step

# Cliffside: touching the island's rim (the border cells).
func is_on_cliff(cell: Vector2) -> bool:
	var size: Vector2 = map_generator.MAP_GRID.size
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var c: Vector2 = cell + Vector2(dx, dy)
			if (dx != 0 or dy != 0) and (c.x == 0 or c.y == 0 or c.x == size.x - 1 or c.y == size.y - 1):
				return true
	return false

func touches_obstacle(cell: Vector2) -> bool:
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if (dx != 0 or dy != 0) and map_generator.obstacles.has(cell + Vector2(dx, dy)):
				return true
	return false

func beside_straight(cell: Vector2) -> bool:
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if (dx != 0 or dy != 0) and _straight_cells.has(cell + Vector2(dx, dy)):
				return true
	return false

# Short Roots' Need: a Warden you own with range at most `reach`.
func owns_range_at_most(reach: float) -> bool:
	var forms := _roster().duplicate()
	for card in pool:
		if card.unlocks != null:
			forms.append(card.unlocks)
	for data in forms:
		if is_unlocked(data.get_id()) and data.can_attack and data.attack_range <= reach:
			return true
	return false

# Damp Rot: Poisoned (Spored) tick multiplier on `enemy` (enemy.gd's tick asks; 1.0 without it).
func get_spored_tick_multiplier(enemy: Node2D) -> float:
	var n := rule_stacks(&"damp_rot")
	if n == 0 or enemy == null or not enemy.statuses.has(EnemyStatuses.DAMP):
		return 1.0
	return 1.0 + DAMP_ROT_PER * n

# Sparking Spores: Ignite detonation multiplier (Reactions._ignite asks; 1.0 without it).
func get_ignite_multiplier() -> float:
	return 1.0 + SPARKING_SPORES_PER * rule_stacks(&"sparking_spores")


# --- Headless simulation entry points (tools/balance_run.gd, tests) -------------------------------
# A real rest and family pick without the screens or deferred offers, keeping the offer bookkeeping
# (fade, half-dreamed, owed families, Stray, pity, Lucid) exactly as in play.

# Dreamlight a run earns at `kind`: &"first" (the first family pick) or &"boss" (a boss rest).
func sim_dreamlight_for(kind: StringName) -> int:
	return first_pick_dreamlight if kind == &"first" else (BOSS_DREAMLIGHT if kind == &"boss" else 0)

# The rest after drift `drift`: what _on_rest_started does (rest rules, Sunlit Rest, Seedling Gift,
# the boss's +4 Dreamlight) and a real offer. `pick.call(offer: Array) -> UpgradeData` (null = let it
# pass); with Lucid Dreaming it's called again with what's left. Returns the cards taken.
func sim_rest(drift: int, pick: Callable, perfect: bool = true) -> Array[UpgradeData]:
	_early_calls = 0
	_rest_rules(perfect)
	add_dreamlight(rest_dreamlight(drift))
	if drift_director.is_boss_drift(drift):
		add_dreamlight(sim_dreamlight_for(&"boss"))
	if has_rule(&"sunlit_rest"):
		sunlit_rest()
	if has_rule(&"seedling_gift"):
		run_state.add_sprout_charges(1)
	var taken: Array[UpgradeData] = []
	current_offer_drift = drift
	current_offer = make_offer(drift)
	while is_offering():
		var card: UpgradeData = pick.call(current_offer.duplicate())
		if card == null or not current_offer.has(card):
			if can_skip():
				skip()
			else:
				_close_offer()  # Restless Dreams: no skipping, but the sim moves on
			break
		taken.append(card)
		choose(card)
	return taken

# A family pick (&"first" after drift 1, &"boss" before a boss rest) through FamilyPickScreen's real
# offer (owed half-dreamed families included), without leaving the game paused or the screen open.
# `pick.call(offered_ids: Array) -> StringName`; &"" takes a Family Blessing if one is offered.
# Returns the family taken (&"" = none). The first pick also gives its +1 Dreamlight.
func sim_family_pick(kind: StringName, pick: Callable) -> StringName:
	if kind == &"first":
		add_dreamlight(sim_dreamlight_for(&"first"))
	var screen := get_node_or_null("%FamilyPickScreen")
	if screen == null:
		return &""
	var speed := get_node_or_null("%GameSpeed")
	var was_paused: bool = speed.paused if speed else false
	var time_scale := Engine.time_scale  # GameSpeed.set_paused re-applies its own speed; a headless runner's stays
	var was_awaiting := drift_director.awaiting_family_pick
	drift_director.awaiting_family_pick = false  # An empty offer mustn't start a rest in the sim
	screen.show_pick(kind)
	drift_director.awaiting_family_pick = was_awaiting
	var families: Array = screen.offer.filter(func(d) -> bool: return d is TowerData)
	var ids: Array = families.map(func(d: TowerData) -> String: return d.get_id())
	var chosen := StringName(pick.call(ids.duplicate())) if not ids.is_empty() else &""
	if ids.has(String(chosen)):
		unlocked[String(chosen)] = true
		unlocks_changed.emit()
		note_family_pick(ids, String(chosen))
	else:
		chosen = &""
		var blessings: Array = screen.offer.filter(func(d) -> bool: return d is UpgradeData)
		if not blessings.is_empty():
			take(blessings[0])
		note_family_pick(ids, "")
	screen.offer = []
	screen.visible = false
	if speed:
		speed.set_paused(was_paused)
	Engine.time_scale = time_scale
	return chosen


# --- Developer: pick any card, unlock free (demo_scope.md "Pick any card") -------------------------

# Dev tools are on in a dev run (Test Grove, Unlock all families, Dev Grove) of a debug build only.
# Dreamlight every rest after `drift` frees on its own (the boss rest's BOSS_DREAMLIGHT comes on top).
static func rest_dreamlight(drift: int) -> int:
	return WAKE_DREAMLIGHT if drift >= WAKE_FROM_DRIFT else 0

static func dev_tools_on() -> bool:
	return OS.is_debug_build() and MetaRun.is_dev_run()

# "Dev: any card…": takes `card` (any Dream in the game) as this Dream's pick (one of Lucid Dreaming's).
func choose_any(card: UpgradeData) -> bool:
	if card == null or not is_offering() or (card.max_stacks > 0 and card_stacks(card.id) >= card.max_stacks):
		return false
	take(card)
	_taken_this_offer.append(card.id)
	picks_left -= 1
	if picks_left > 0 and current_offer.size() > 1:  # Lucid Dreaming: still one to take
		offer_ready.emit(current_offer, current_offer_drift)
	else:
		_close_offer()
	return true

# "Dev: unlock free": unlocks `form` without Dreamlight or its branch (not base families: those
# come from family picks).
func dev_unlock(form: TowerData) -> bool:
	if form == null or form.buildable_directly or is_unlocked(form.get_id()):
		return false
	unlocked[form.get_id()] = true
	unlocks_changed.emit()
	return true

# Why `card` wouldn't be offered now ("" = it could be): "needs …" for the dev card grid.
func needs_note(card: UpgradeData, act: int = -1) -> String:
	if act < 0:
		act = drift_director.get_act(maxi(drift_director.drifts_started, 1))
	var needs: Array[String] = []
	if not (card.in_start_pool or grove_cards.has(card.id)):
		needs.append("its Memory Grove node")
	if act < card.min_act:
		needs.append("act %d" % card.min_act)
	if card.kind == UpgradeData.Kind.UNLOCK_WARDEN or card.kind == UpgradeData.Kind.UNLOCK_EVOLUTION:
		needs.append("never offered (family picks / Dreamlight)")
	if card.max_stacks > 0 and card_stacks(card.id) >= card.max_stacks:
		needs.append("no more stacks")
	if card.is_deepened() and not has_card(card.deepens):
		needs.append(get_display_name(card.deepens))
	if card.tags.has("clearing") and not unlocks_clearing(card) and not can_clear():
		needs.append("clearing unlocked (Tend the Forest)")
	if card.is_bittersweet() and not allow_bittersweet:
		needs.append("Bittersweet Dreams (Grove)")
	var missing: Array = card.requires.filter(func(id: String) -> bool: return not owns(id))
	if not missing.is_empty():
		needs.append(" + ".join(missing.map(get_display_name)))
	if card.requires_tag != "" and count_taken_with_tag(card.requires_tag) < card.requires_tag_count:
		needs.append("%d %s card%s" % [card.requires_tag_count, card.requires_tag, "" if card.requires_tag_count == 1 else "s"])
	if needs.is_empty() and not is_eligible(card, act):
		needs.append("a board or run state (e.g. Wardens, statuses, obstacles)")
	return "" if needs.is_empty() else "not normally offered: needs " + ", ".join(needs)


# --- Seed cards (dream_design.md "Seed cards: plant now, grow later") --------------------------------

# The families held Seed cards call: the next family pick is guaranteed to offer each one that the
# profile can pick and the run doesn't own yet (FamilyPickScreen).
# The family `card` would call to the next pick, or "" when it can't (already yours, or never pickable):
# then its Seed line hides too (screens_ui.md "Playtest fixes").
func calls_family_now(card: UpgradeData) -> String:
	var family := card.calls_family
	if family == "" or is_unlocked(family):
		return ""
	return family if _family_roots().any(func(d: TowerData) -> bool: return d.get_id() == family) else ""

func get_called_families() -> Array[String]:
	var pickable: Array = _family_roots().map(func(d: TowerData) -> String: return d.get_id())
	var called: Array[String] = []
	for card in _taken_cards(true):
		var family := card.calls_family
		if family != "" and not called.has(family) and pickable.has(family) and not is_unlocked(family):
			called.append(family)
	return called

# Whether a Seed card has grown: a Warden it names is on the map.
func seed_grown(card: UpgradeData) -> bool:
	return card.grows_with.any(func(id: String) -> bool: return count_wardens(id) > 0)

# Patient Roots: seconds added to Held from any source (Tower / Enemy code add it).
func get_held_bonus() -> float:
	return PATIENT_ROOTS_HELD if has_rule(&"patient_roots") else 0.0

# Bramble Oath: path tiles the walls add (the route with walls vs without them), cached per route.
var _walls_tiles_cache := [-1, 0]  # [board_version, tiles]

func walls_added_tiles() -> int:
	if _walls_tiles_cache[0] == board_version:
		return _walls_tiles_cache[1]
	var cells: Array[Vector2] = []
	for tower in _towers():
		if tower.tower_data.line == "wall":
			cells.append(tower.cell)
	var tiles := 0
	if not cells.is_empty():
		var layer = map_generator.path_layer
		for cell in cells:
			layer.set_cell_blocked(cell, false)
		var without: int = layer.find_path_from(map_generator.startPath).size()
		for cell in cells:
			layer.set_cell_blocked(cell, true)
		tiles = maxi(path_length - without, 0)
	_walls_tiles_cache = [board_version, tiles]
	return tiles

# Golden Harvest: Dew the catchers harvested (and Wellspring interest) this run, from RunState.
func dew_harvested() -> int:
	var value = run_state.get("dew_harvested")
	return int(value) if value != null else 0


# --- How Needs are shown on a card (dream_design.md, "Card requirements") ---------------------------
# A card never names a Warden you don't have: combo cards show their statuses (lit if one of your
# Wardens applies it, dim if not), Warden Needs show the family, card ingredients stay by name.

# What a half-dreamed or sleeping card still needs, by damage type (dream_design.md "Named by damage
# type"): [{family: "whirligig", type: "Wind", line: "wind", form: "Samara" or ""}] (form = the
# specific Warden when the card needs one, for its tooltip: "Samara, a Wind Warden").
func missing_needs(card: UpgradeData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in card.requires:
		var family := family_of(id)
		if family == "" or is_unlocked(family) or out.any(func(n: Dictionary) -> bool: return n.family == family):
			continue
		var data := IconInfo.family_data(family)
		var line: String = data.line if data != null else ""
		out.append({"family": family, "line": line, "type": IconInfo.damage_type_name(line),
			"form": get_display_name(id) if id != family else ""})
	return out

# The one line a half-dreamed or sleeping card shows: "Needs Wind" ("" = none; "half-dreamed" stays an
# internal name). The Dream card draws it with the type's emblem and a link.
func missing_families_text(card: UpgradeData) -> String:
	var needs := missing_needs(card)
	return "" if needs.is_empty() else "Needs " + " and ".join(needs.map(func(n: Dictionary) -> String: return n.type))

# {"statuses": [[status id, lit]], "families": [display names], "cards": [display names], "either": bool}
func needs_parts(card: UpgradeData) -> Dictionary:
	var parts := {"statuses": [], "families": [], "cards": [], "either": false}
	if not card.shows_statuses.is_empty():
		var owned := owned_statuses()
		for status in card.shows_statuses:
			parts.statuses.append([status, owned.has(status)])
	var ids: Array = card.requires.duplicate()
	if card.requires.is_empty() and not card.requires_any.is_empty():
		ids = card.requires_any.duplicate()
		parts.either = true
	elif not card.requires_any.is_empty():
		ids.append_array(card.requires_any)
	for id in ids:
		var family := family_name_for(id)
		if family != "":
			if card.shows_statuses.is_empty() and not parts.families.has(family):
				parts.families.append(family)
		elif pool.any(func(c: UpgradeData) -> bool: return c.id == id):
			var name := get_display_name(id)
			if not parts.cards.has(name):
				parts.cards.append(name)
	return parts

# The family (display name) a Warden id belongs to: "Nestling", "Thornwall" for walls; "" when `id`
# isn't a Warden.
func family_name_for(id: String) -> String:
	var family := family_of(id)
	if family == "":
		family = _every_family().get(id, "")  # A family the pick roster doesn't hold (Grove families)
	if family == "wall":
		return "Thornwall"
	return get_display_name(family) if family != "" else ""

# Every Warden id -> its family's base id ("wall" for Thornwall's growths), from all Warden resources.
static var _families_of_all := {}

static func _every_family() -> Dictionary:
	if not _families_of_all.is_empty():
		return _families_of_all
	var dir := "res://resource/tower/"
	for file in ResourceLoader.list_directory(dir):
		if not file.ends_with(".tres"):
			continue
		var data := load(dir + file) as TowerData
		if data == null or data.tier != 1:
			continue
		var family := "wall" if data.line == "wall" else data.get_id()
		var todo: Array = [data]
		while not todo.is_empty():
			var form := todo.pop_back() as TowerData
			if form == null or _families_of_all.has(form.get_id()):
				continue
			_families_of_all[form.get_id()] = family
			todo.append_array(form.evolves_to)
	return _families_of_all

# "Needs: Soaked + Charged", "Needs: Nestling family", "Needs: Pebbling + Firefly Jar families",
# "Needs: Tender Care + Seedling Gift" ("" = no Needs to show).
func needs_text(card: UpgradeData) -> String:
	var parts := needs_parts(card)
	var bits: Array[String] = []
	if not parts.statuses.is_empty():
		bits.append(" + ".join(parts.statuses.map(func(s: Array) -> String: return IconInfo.status_name(s[0]))))
	if not parts.families.is_empty():
		var joiner := " or " if parts.either else " + "
		bits.append(joiner.join(parts.families) + (" family" if parts.families.size() == 1 else " families"))
	if not parts.cards.is_empty():
		bits.append(" + ".join(parts.cards))
	return "" if bits.is_empty() else "Needs: " + " · ".join(bits)


# --- Discovery unlocks (dream_design.md "Discovery unlocks: you dream of what you've seen") ---------
# A card named after a combo, Kinship or Warden enters the pool once it's been discovered, then stays
# (profile). A discovery counts at once, mid-run too; its normal Needs still apply. Explicit keys are
# UpgradeData.discovered_by; cards whose Needs name Wardens (requires / requires_any) also need one
# of them built or grown into once (not combo-status cards; half-dreamed cards skip it). Legendaries
# are never gated. Reactions, Crowned and
# Kinships come from the profile's combos_seen (ComboFeedback); the profile's wardens_built and
# best_chain are saved here. The demo counts the current run only; dev runs have everything
# discovered; tests too, unless a test sets `discovery_profile`.

const WARDENS_BUILT_KEY := "wardens_built"
const BEST_CHAIN_KEY := "best_chain"
const DISCOVERY_CHAIN := 5

# Tests: {"seen": [combo ids], "wardens_built": [ids], "best_chain": n} stands in for the profile.
var discovery_profile = null
var _built_this_run := {}  # Warden id -> true (built or grown into this run)
var _profile_discovery := {}  # Loaded once per run

func _discovery_profile() -> Dictionary:
	if discovery_profile != null:
		return discovery_profile
	if _profile_discovery.is_empty():
		if ResultsScreen.is_demo():
			_profile_discovery = {"seen": [], WARDENS_BUILT_KEY: [], BEST_CHAIN_KEY: 0}
		else:
			var memory := HeartwoodMemory.load_data()
			_profile_discovery = {"seen": ComboFeedback.profile_seen(),
				WARDENS_BUILT_KEY: memory.get(WARDENS_BUILT_KEY, []).duplicate(),
				BEST_CHAIN_KEY: int(memory.get(BEST_CHAIN_KEY, 0))}
	return _profile_discovery

# Everything counts as discovered: dev runs, and tests that don't set a profile.
func _discovers_all() -> bool:
	if MetaRun.is_dev_run():
		return true
	return discovery_profile == null and not _is_real_game()

func _is_real_game() -> bool:
	return is_inside_tree() and get_tree().current_scene == owner

# Combo ids found: the profile's plus this run's (ComboFeedback's run counts).
func _combos_found() -> Array:
	var found: Array = _discovery_profile().get("seen", []).duplicate()
	var feedback := get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback
	if feedback != null:
		for id in feedback.run_counts:
			if not found.has(String(id)):
				found.append(String(id))
	return found

func _best_chain() -> int:
	var best := int(_discovery_profile().get(BEST_CHAIN_KEY, 0))
	var tracker := get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker
	return maxi(best, tracker.longest_chain) if tracker != null else best

func warden_discovered(id: String) -> bool:
	return _built_this_run.has(id) or _discovery_profile().get(WARDENS_BUILT_KEY, []).has(id)

# The keys a card waits on: its discovered_by, plus "warden:<id>" entries for the Wardens its Needs
# name (any one of them, "warden_any:a,b" for requires_any).
func discovery_keys(card: UpgradeData) -> Array[String]:
	if card.rarity == UpgradeData.Rarity.LEGENDARY:
		return []  # Legendaries are never discovery-gated (Grove tips)
	var keys: Array[String] = card.discovered_by.duplicate()
	if not card.shows_statuses.is_empty():
		return keys
	for id in card.requires:
		if _is_warden_id(id):
			keys.append("warden:" + id)
	var any: Array = card.requires_any.filter(_is_warden_id)
	if not any.is_empty():
		keys.append("warden_any:" + ",".join(any))
	return keys

static func _is_warden_id(id: String) -> bool:
	return ResourceLoader.exists("res://resource/tower/%s.tres" % id)

func discovery_met(card: UpgradeData) -> bool:
	if _discovers_all():
		return true
	var keys := discovery_keys(card)
	if is_half_dreamed(card):  # Half-dreamed: only its Reaction gate (the Needs line shows statuses)
		keys = keys.filter(func(key: String) -> bool: return not key.begins_with("warden"))
	if keys.is_empty():
		return true
	var found := _combos_found()
	return keys.all(func(key: String) -> bool: return _key_met(key, found))

func _key_met(key: String, found: Array) -> bool:
	var kind := key.get_slice(":", 0)
	var arg := key.get_slice(":", 1)
	match kind:
		"reaction", "crowned":
			return found.has(arg)
		"kinship":
			return Kinships.KINSHIPS.keys().any(func(id) -> bool: return found.has(String(id)))
		"reactions":
			return Reactions.all().filter(func(r: ReactionData) -> bool: return found.has(String(r.id))).size() >= int(arg)
		"chain":
			return _best_chain() >= int(arg)
		"warden":
			return warden_discovered(arg)
		"warden_any":
			return Array(arg.split(",")).any(warden_discovered)
	return true

# Cards in this run's pool still waiting on a discovery (the Codex / "New Dreams" lines).
func undiscovered_cards() -> Array[UpgradeData]:
	var waiting: Array[UpgradeData] = []
	for card in pool:
		if (card.in_start_pool or grove_cards.has(card.id)) and not discovery_met(card):
			waiting.append(card)
	return waiting

# Names of this pool's cards that a discovery just let in: pass what undiscovered_cards() returned
# before it.
func newly_discovered(before: Array[UpgradeData]) -> Array[String]:
	var names: Array[String] = []
	for card in before:
		if discovery_met(card):
			names.append(card.display_name)
	return names

# A Warden built or grown into: discovered (a toast names the Dreams it lets in, the first time).
func _discover_warden(tower: Tower) -> void:
	var id := tower.tower_data.get_id()
	if _built_this_run.has(id):
		return
	var before := undiscovered_cards() if not _discovers_all() else ([] as Array[UpgradeData])
	_built_this_run[id] = true
	var names := newly_discovered(before)
	if not names.is_empty():
		var hud := owner.get_node_or_null("HUD") if owner != null else null
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast("New Dreams: " + ", ".join(names))

# The profile keeps built Wardens and the best chain (the real game only; not the demo or dev runs).
func _save_discoveries() -> void:
	if not _is_real_game() or ResultsScreen.is_demo() or MetaRun.is_dev_run():
		return
	var memory := HeartwoodMemory.load_data()
	var built: Array = memory.get(WARDENS_BUILT_KEY, []).duplicate()
	for id in _built_this_run:
		if not built.has(id):
			built.append(id)
	memory[WARDENS_BUILT_KEY] = built
	memory[BEST_CHAIN_KEY] = maxi(int(memory.get(BEST_CHAIN_KEY, 0)), _best_chain())
	HeartwoodMemory.save_data(memory)


# --- Thin-family cards 192–203 (dream_design.md "Thin-family cards (2026-09-30)") -----------------
# Deep Grip and Murmur live in on_hit_multiplier; the rest are queries Tower Code (Called Shot, Chorus,
# Homing Instinct, Long Light) and Enemy Code (Root Web, Tangled Release, Lullaby, Bright Marks) read.
# Clear Tones and Lingering Mark are plain stat / status-duration cards.

const DEEP_GRIP_PER := 0.50  # Rootling line vs Held
const MURMUR_BONUS := 0.30  # A bird's hit on a nightmare another bird hit within MURMUR_WINDOW
const MURMUR_WINDOW := 1.0
const TANGLED_RELEASE_TILES: Array[float] = [0.5, 1.0]  # II
const LONG_LIGHT_LINGER := 3.0  # Seconds Rootlight's lit tiles stay lit
const ROOT_WEB_SHARE := 0.5  # Touching nightmares Held for half as long (halved again on bosses)
const ROOT_WEB_BOSS_SHARE := 0.25
const ROOT_WEB_COOLDOWN := 1.0  # Never twice a second on one nightmare; never chains
const LULLABY_LINGER: Array[float] = [1.0, 2.0]  # II
const CHORUS_CELLS := 3.0
const CHORUS_SYNC_WINDOW := 0.3  # Others whose attack is ready within this fire together
const CHORUS_BONUS := 0.30
const BRIGHT_MARKS_PER := 0.20  # Marked nightmares take +20% more (on top of Marked; Beacon too)
const HOMING_SPEED: Array[float] = [1.5, 1.9]  # Swoop return speed (II)

var _game_clock := 0.0
var _bird_hits := {}  # Nightmare id -> [tower id, _game_clock] of the last bird hit (Murmur)
var _called_shots := {}  # "tower:nightmare" -> true once Called Shot fired

func _thin_family_hit_bonus(tower: Tower, enemy: Node2D) -> float:
	if tower == null:
		return 0.0
	var bonus := 0.0
	var line := tower.tower_data.line
	if line == "root" and has_rule(&"deep_grip") and enemy.statuses.has(EnemyStatuses.HELD):
		bonus += DEEP_GRIP_PER * rule_stacks(&"deep_grip") * rule_power(&"deep_grip")
	if has_rule(&"head_start") and float(enemy.get_meta(&"head_start_until", -1.0)) > _game_clock:
		bonus += HEAD_START_BONUS[rule_level(&"head_start")] * rule_power(&"head_start")  # Head Start
	if has_rule(&"deep_frost") and _is_frozen(enemy):  # Deep Frost: Frostfern's freeze (Held by a water Warden)
		bonus += DEEP_FROST_BONUS * rule_power(&"deep_frost")
	if line == "stone" and has_rule(&"falling_weight") and (enemy.statuses.is_held() or enemy.statuses.is_asleep()):
		bonus += FALLING_WEIGHT_BONUS * rule_power(&"falling_weight")
	if line == "wing" and has_rule(&"murmur"):
		var id := enemy.get_instance_id()
		var last: Array = _bird_hits.get(id, [])
		if not last.is_empty() and last[0] != tower.get_instance_id() and _game_clock - last[1] <= MURMUR_WINDOW:
			bonus += MURMUR_BONUS * rule_power(&"murmur")
		if _bird_hits.size() > 2048:
			_bird_hits.clear()
		_bird_hits[id] = [tower.get_instance_id(), _game_clock]
	return bonus

# Called Shot: true once per Warden per nightmare, on its first hit on a Marked nightmare (a
# guaranteed crit; Tower.hit asks before rolling). Adds with First Light.
func called_shot(tower: Tower, enemy: Node2D) -> bool:
	if not has_rule(&"called_shot") or tower == null or enemy == null or not enemy.statuses.has(EnemyStatuses.MARKED):
		return false
	var key := "%d:%d" % [tower.get_instance_id(), enemy.get_instance_id()]
	if _called_shots.has(key):
		return false
	if _called_shots.size() > 4096:
		_called_shots.clear()
	_called_shots[key] = true
	return true

# Tiles a nightmare freed from a hold is pulled back along its route (0 = none).
func get_release_pull() -> float:
	return TANGLED_RELEASE_TILES[rule_level(&"tangled_release")] if has_rule(&"tangled_release") else 0.0

func get_lit_linger() -> float:
	return LONG_LIGHT_LINGER if has_rule(&"long_light") else 0.0

# Root Web: the share of a hold the touching nightmares get (0 = off).
func get_root_web_share(is_boss: bool) -> float:
	if not has_rule(&"root_web"):
		return 0.0
	return ROOT_WEB_BOSS_SHARE if is_boss else ROOT_WEB_SHARE

# Lullaby: seconds a Caught nightmare stays Caught after leaving the Dreamcatcher's range.
func get_caught_linger() -> float:
	return LULLABY_LINGER[rule_level(&"lullaby")] if has_rule(&"lullaby") else 0.0

func has_chorus() -> bool:
	return has_rule(&"chorus")

# Bright Marks: extra Marked bonus (added to EnemyStatuses.MARKED_EXTRA / Beacon's marked_extra).
func get_marked_bonus() -> float:
	return BRIGHT_MARKS_PER * rule_stacks(&"bright_marks") * rule_power(&"bright_marks")

# Homing Instinct: swoop return speed multiplier (1 = none; swoops only, never pecks).
func get_swoop_return_multiplier() -> float:
	return HOMING_SPEED[rule_level(&"homing_instinct")] if has_rule(&"homing_instinct") else 1.0


# --- Tag resonance (dream_audit.md "Builds pay off", 2026-09-30) ------------------------------------
# Each card you own with a tag makes later cards of that tag +RESONANCE_PER stronger (their numbers,
# not their rules), up to +RESONANCE_MAX: counted on the card's best-represented tag and locked when the
# card is taken. Untagged (generic) cards neither resonate nor count. Applied to stat and status
# numbers (_sum_stat, statuses), DreamEffects rows (damage / speed / range) and the per-hit rules
# here; other scripts scale their rule numbers with rule_power(rule_id).
const RESONANCE_PER := 0.10
const RESONANCE_MAX := 0.50
const NOT_RESONANT: Array[String] = ["bittersweet", "opener"]  # Structural tags, not builds

var _resonance := {}  # Card id -> {power, tag, count} locked when it was taken (saved)
var resonance_enabled := true  # Tests of single-card numbers turn it off; test_dreams checks the rule

# The resonance a card would get if taken now: {bonus, tag, count} (bonus 0 = none).
func resonance_preview(card: UpgradeData) -> Dictionary:
	var best := {"bonus": 0.0, "tag": "", "count": 0}
	if card == null or not resonance_enabled:
		return best
	var owned := _taken_cards(true)
	for tag in card.tags:
		if NOT_RESONANT.has(tag):
			continue
		var count := owned.filter(func(c: UpgradeData) -> bool:
			return c.id != card.id and c.id != card.deepens and c.deepens != card.id and c.tags.has(tag)).size()  # Never its own base
		if count > best.count:
			best = {"bonus": minf(RESONANCE_PER * count, RESONANCE_MAX), "tag": tag, "count": count}
	return best

# The multiplier a taken card's numbers get (1.0 = none).
func resonance(card: UpgradeData) -> float:
	if card == null or not _resonance.has(card.id):
		return 1.0
	return float(_resonance[card.id].get("power", 1.0))

# "+20% from 2 spore cards" for a taken card ("" = none): Dreams this run.
func resonance_line(card: UpgradeData) -> String:
	var r: Dictionary = _resonance.get(card.id, {}) if card != null else {}
	return resonance_text(float(r.get("power", 1.0)) - 1.0, str(r.get("tag", "")), int(r.get("count", 0)))

# The strongest resonance among the taken cards with `rule` (for rule code in other scripts).
func rule_power(rule: StringName) -> float:
	var power := 1.0
	for card in _taken_cards():
		if card.rule_id == rule or card.extra_rules.has(rule):
			power = maxf(power, resonance(card))
	return power

# "+20% from 2 Spore cards" (the card face, Dreams this run). "" = none. Tags that are names read capitalised
# (text_style.md "Second pass"), plain categories stay lowercase ("+10% from 1 economy card").
const TAG_NAMES := {"spore": "Spore", "water": "Water", "light": "Light", "stone": "Stone", "root": "Root", "song": "Song",
	"wind": "Wind", "wing": "Wing", "acorn": "Acorn", "kinship": "Kinship", "reaction": "Reaction", "sprout": "Sprout",
	"wall": "Thornwall", "nurture": "Nurture"}

static func resonance_text(bonus: float, tag: String, count: int) -> String:
	if bonus <= 0.0:
		return ""
	return "+%d%% from %d %s card%s" % [roundi(bonus * 100), count, TAG_NAMES.get(tag, tag), "" if count == 1 else "s"]


# --- Catalogue cards 204–226 (dream_design.md "New cards for the catalogue") ----------------------
# Bridges carry two build tags. Here: Seasoned Eye (crit), Falling Weight (per hit), Quick Step and
# Hurried Harvest (calling early), Fresh Soil (cost; its damage is a DreamEffects row), Live Wire
# (a query for the bolt code) and the DreamEffects rows (Many Rings, Hedgerow, Spinning Corners,
# Heartwood's Fury, Patchwork, Mixed Grove). Tower Code reads the rest by rule id (Elder Kin, Big
# Family, Mycelium, Fireflies in the Grass, Spore Kin, Resonance, Thornheart, Ill Wind, Eddy, Warm
# Hearth) with the numbers below.

const ELDER_KIN_SHARE := 0.25  # Ranked Wardens in a Kinship share this much of their rank bonuses
const MANY_RINGS_PER := 0.02  # Per rank on any Warden, for every Sprout
const MANY_RINGS_MAX := 0.50
const BIG_FAMILY_SPEED := 0.45  # Sprouts within BIG_FAMILY_CELLS of a Kinship pair
const BIG_FAMILY_CELLS := 2.0
const MYCELIUM_SPORED := 1  # Poisoned stacks a Sprout touching a Sporeling-line Warden applies on hit
const FIREFLIES_EVERY := 3  # Sprouts touching a Firefly-line Warden add 1 Charged every Nth hit
const SEASONED_EYE_PER := 0.03
const SEASONED_EYE_MAX := 0.21
const HEDGEROW_BONUS := 0.30  # Sprouts touching a Thornwall
const SPORE_KIN_SPORED := 2  # Harmony strikes by Sporeling-line kin
const RESONANCE_CHARGED := 1  # Chime Stone pulses count as lightning: +1 Charged per nightmare hit
const THORNHEART_PER := 0.05  # Bramble thorns, per Bramble you own
const THORNHEART_MAX := 1.0
const ILL_WIND_BONUS := 0.45  # Effect damage of statuses Gust / Zephyr copied
const SPINNING_CORNERS_SPEED := 0.45  # Pinwheel / Windmill beside a bend
const SPINNING_WARDENS: Array[String] = ["pinwheel", "windmill"]
const FALLING_WEIGHT_BONUS := 0.45  # Pebbling line vs Held or Asleep
const WARM_HEARTH_SPROUTS := 0.50  # Aura bonuses on Sprouts
const FRESH_SOIL_BONUS := 0.20  # Reclaimed Earth (absorbed Fresh Soil)  # A Sprout on a cleared cell
const FRESH_SOIL_COST := 7
const QUICK_STEP_SPEED := 0.15  # Per stack, for QUICK_STEP_TIME after calling a drift early
const QUICK_STEP_TIME := 10.0
const HURRIED_HARVEST_CAP := 40  # +1 Dew per nightmare of an early-called drift, per drift
const HURRIED_HARVEST_DEW := 2  # Per nightmare
const FURY_CELLS := 4  # Heartwood's Fury: from the Heartwood (Chebyshev)
const FURY_PER := 0.03  # Last Stand (absorbed Heartwood's Fury)  # Per missing leaf
const FURY_MAX := 0.30
const PATCHWORK_PER := 0.05  # Per family owned
const PATCHWORK_MAX := 0.15
const MIXED_GROVE_PER := 0.15  # Per neighbouring family that isn't the Warden's own
const MIXED_GROVE_MAX := 0.45
const LIVE_WIRE_PER := 0.15  # Charged bolts, per stack (max 3)

var _quick_step_until := -1.0
var _hurried_drift := -1
var _hurried_paid := 0

func quick_step_active() -> bool:
	return has_rule(&"quick_step") and _game_clock < _quick_step_until

# Hurried Harvest: +1 Dew for each nightmare dispelled during a drift you called early (cap per drift).
func _hurried_harvest(enemy: Node2D) -> void:
	if not has_rule(&"hurried_harvest") or drift_director.drifts_started != _hurried_drift or _hurried_paid >= HURRIED_HARVEST_CAP:
		return
	_hurried_paid += HURRIED_HARVEST_DEW
	run_state.earn_dew_at(HURRIED_HARVEST_DEW, enemy.global_position)

# Live Wire: Charged bolts multiplier (Enemy / Reactions bolt code; 1.0 without the card).
func get_bolt_multiplier() -> float:
	return 1.0 + LIVE_WIRE_PER * rule_stacks(&"live_wire") * rule_power(&"live_wire")

# Families you own (Patchwork, Mixed Grove's Need).
func count_owned_families() -> int:
	return _family_roots().filter(func(d: TowerData) -> bool: return is_unlocked(d.get_id())).size()


# --- The 11 catalogue cards specced earlier (dream_design.md crit cards 37–39, new-Warden cards 46–53)
# Mine: Glinting Dew, Heavy Stones (crit chance), Sharpened Light / II (crit multiplier), Deep Frost
# (per hit) and Long Shadows (a DreamEffects row). Tower Code reads the rest by rule id: Patient Aim,
# Ring Dance, Carried on the Wind, Sweet Scent, Shiny Things, Hairpin Winds.
const GLINTING_DEW_PER := 0.08  # All Wardens, per stack (max 3)
const HEAVY_STONES_PER := 0.15  # Pebbling line, per stack (max 3)
const SHARPENED_LIGHT: Array[float] = [0.5, 1.0]  # Crit multiplier (II)
const DEEP_FROST_BONUS := 0.45  # Frozen nightmares
const LONG_SHADOWS_RANGE := 2.0  # Wardens whose range is LONG_SHADOWS_FROM or more
const LONG_SHADOWS_FROM := 5.0
const PATIENT_AIM_PER := 0.15  # Per second a Warden hasn't fired
const PATIENT_AIM_MAX := 0.60
const RING_DANCE_TILES := 2.0  # A Fairy Ring burst sets off rings this close
const SWEET_SCENT_TILES := 2.0  # Honeysuckle's Drowsy reach
const SHINY_THINGS_BONUS := 0.15  # Per stolen buff, SHINY_THINGS_TIME s, max SHINY_THINGS_STACKS
const SHINY_THINGS_TIME := 10.0
const SHINY_THINGS_STACKS := 3
const HAIRPIN_WINDS_EXTRA := 1  # Pinwheel / Windmill: +1 max adjacent path tile

# Frozen = Held by a water Warden (Frostfern's freeze; tower_design.md status jobs).
func _is_frozen(enemy: Node2D) -> bool:
	if not enemy.statuses.is_held():
		return false
	var applier = enemy.statuses.source(EnemyStatuses.HELD)
	return applier != null and is_instance_valid(applier) and "tower_data" in applier and applier.tower_data.line == "water"


# --- Cards 227–234 (dream_design.md "After the catalogue measurement") -----------------------------
# Mine: Head Start (per hit), Second Wind (the next Dream), and the DreamEffects rows for Scarred Bark,
# Desperate Bloom, Odd One Out and Grand Tour. Tower Code reads Crush and Crowd Breaker (area attacks).
const HEAD_START_BONUS: Array[float] = [0.40, 0.60]  # II
const HEAD_START_TIME := 10.0  # After the nightmare arrives
const SECOND_WIND_EXTRA_CARDS := 1  # The next Dream offers 4 cards, one Rare+
const SCARRED_BARK_PER: Array[float] = [0.03, 0.04]  # Per leaf lost this run (II)
const SCARRED_BARK_MAX: Array[float] = [0.45, 0.60]
const DESPERATE_BLOOM_SPEED := 0.50  # Below half the max leaves
const ODD_ONE_OUT_BONUS: Array[float] = [0.45, 0.65]  # The only one of its kind on the map (II)
const GRAND_TOUR_PER := 0.10  # Per different status your Wardens apply
const GRAND_TOUR_MAX := 0.70
const CRUSH_BONUS: Array[float] = [0.30, 0.45]  # Area attacks vs a nightmare touching CRUSH_CROWD+ others (II)
const CRUSH_CROWD := 2
const CROWD_BREAKER_PER := 0.05  # An area attack, per nightmare it hits
const CROWD_BREAKER_MAX := 0.45

var _head_start_drift := -1

# Head Start: nightmares arriving in a drift you called early are marked for HEAD_START_TIME.
func _stamp_head_start(node: Node) -> void:
	if has_rule(&"head_start") and drift_director.drifts_started == _head_start_drift and node is Node2D:
		node.set_meta(&"head_start_until", _game_clock + HEAD_START_TIME)

# Second Wind: every drift of the block after the first was called early -> the next Dream offers one
# more card and a Rare+ one.
func _second_wind() -> void:
	if has_rule(&"second_wind") and _early_calls >= drift_director.drifts_per_block - 1:
		_extra_cards_next += SECOND_WIND_EXTRA_CARDS
		_rare_dreams_left = maxi(_rare_dreams_left, 1)
