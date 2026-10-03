extends Resource
class_name UpgradeData

# One Dream card (documentation/dream_design.md). Effects are data: unlock a Warden, change stats
# for a line (or all Wardens), change a status, give economy/leaves, or switch on a rule by id.

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }
enum Kind { UNLOCK_WARDEN, UNLOCK_EVOLUTION, STAT, RULE, ECONOMY }

@export var id: String = ""
@export var display_name: String = "Dream"
@export_multiline var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var kind: Kind = Kind.STAT
@export var tags: Array[String] = []  # Warden lines this card belongs to (tag weighting)
@export var requires: Array[String] = []  # Warden ids / card ids that must be owned first
@export var max_stacks: int = 1  # 0 = stacks without limit (stat cards)
@export var min_act: int = 1  # Legendary: 2
@export var in_start_pool: bool = true  # false = unlocked in the Memory Grove (meta)
# Deepened card ("II"): the id of the base card it upgrades. Only offered once the base is owned;
# taking it replaces the base card's effect (the base stops counting), so this card carries the
# whole new effect.
@export var deepens: String = ""
# Entwined card: `requires` lists its ingredients. Once all are owned it's guaranteed in the next
# Dream offer (once; after that it's drawn normally).
@export var entwined: bool = false
# Woven (Legendary): an Entwined card with 3 ingredients (`requires`, plus `requires_any` as one
# "either" ingredient). Same guarantee; shown with a triple vine.
@export var woven: bool = false
# Bittersweet cards (tag "bittersweet"): the lasting cost, shown on its own line in plum.
@export_multiline var cost_description: String = ""

@export_group("Unlock")
@export var unlocks: TowerData  # UNLOCK_WARDEN / UNLOCK_EVOLUTION

@export_group("Stats")
# Applies to Wardens whose `line` is `stat_line` (empty = all Wardens). `stat_warden` narrows it to
# one Warden id (e.g. only Sprouts, not the whole line).
@export var stat_line: String = ""
@export var stat_warden: String = ""
@export var soothe_bonus: float = 0.0  # +0.10 = +10% soothe
@export var attack_speed_bonus: float = 0.0
@export var range_bonus: float = 0.0  # Cells
@export var splash_bonus: float = 0.0  # +0.25 = +25% splash radius
@export var potency_bonus: float = 0.0  # +0.08 = +8% Potency (effect damage)

@export_group("Status")
@export var status_id: StringName = &""
@export var status_strength_bonus: float = 0.0
@export var status_duration_add: float = 0.0  # Seconds
@export var status_duration_multiplier: float = 1.0
@export var status_max_stacks_add: int = 0

@export_group("Economy")
@export var dew_now: int = 0
@export var dreamlight_now: int = 0  # Sudden Insight, Borrowed Memory
@export var dew_per_clear: int = 0
@export var max_leaves_add: int = 0  # Negative = the Heartwood holds fewer (Deep Sleep)
@export var leaves_now: int = 0  # Negative = lose leaves now (never offered if it would end the run)
@export var evolve_discount: float = 0.0  # 0.25 = evolving costs 25% less
# Warden id whose build cost becomes `set_cost` (below its cost: a discount, the cheapest wins;
# above it: a surcharge, the highest wins and beats discounts).
@export var set_cost_warden: String = ""
@export var set_cost: int = 0
@export var rest_bonus_add: int = 0  # Every rest (drift-clear) bonus; negative = Borrowed Dew
@export var creature_health_bonus: float = 0.0  # +0.10 = creatures +10% health (Wild Growth)
@export var rare_dreams_add: int = 0  # The next N Dreams each include a Rare+ card
@export var creature_speed_bonus: float = 0.0  # +0.10 = nightmares +10% speed (Burn Back)

@export_group("Needs")
# Card requirements (dream_design.md "Card requirements"); all must hold for the card to be offered.
@export var requires_tag: String = ""  # Own this many taken cards with the tag (e.g. "nurture")
@export var requires_tag_count: int = 1
@export var requires_any: Array[String] = []  # Own any one of these Wardens / cards
@export var excludes: Array[String] = []  # Card ids this one rules out: taking it removes them from the run (an exclusive pair)
@export var min_rank_dew: int = 0  # Dew spent on Nurture ranks this run
@export var min_rank_count: int = 0  # Own this many Wardens at rank `min_rank_owned` or higher
@export var min_rank_owned: int = 1
@export var min_attackers: int = 0  # Attacking Wardens on the map (never Thornwalls); 0 = no check
@export var max_attackers: int = 0  # 0 = no check
@export var count_warden: String = ""  # Own `min_warden_count` of this Warden on the map (Sprouts)
@export var min_warden_count: int = 0
@export var count_line: String = ""  # Own `min_warden_count` Wardens of this line on the map (Chorus: 2 song; soft)
@export var min_families: int = 0  # Own this many families (Mixed Grove: 2; hard)
# A placement card's map picture (dream_design.md "Placement cards show a diagram"): rows of 7 characters,
# drawn by CardDiagram. Legend: . grass, P path, + path outlined gold, 1–9 numbered route steps (outlined),
# W a Warden that qualifies (glows), w one that doesn't (dimmed, ✗), a another Warden, T Thornwall, X a
# Thornwall outlined gold, O obstacle, Q a qualifying Warden on a cleared cell (a moved hollow), U a tended stump,
# * a grass cell in range
# (outlined), H the Heartwood, S the start. `diagram_caption`: one short line under it.
@export_multiline var diagram: String = ""
@export var diagram_caption: String = ""
@export var extra_rules: Array[StringName] = []  # Rules this card also grants (pool trim merges: an absorbed card's rule id)
# Reactions you can set off: pairs of statuses your owned Wardens apply (Quick Reactions: 2).
@export var min_reaction_pairs: int = 0
@export var requires_status: StringName = &""  # Own any Warden applying this status (e.g. Drowsy)
@export var min_owned_statuses: int = 0  # Own Wardens applying this many different statuses (Seeping: 2)
@export var min_kinships: int = 0  # Kinships on the map at offer time (Kinship cards; hard Need)
@export var requires_any_status: Array[StringName] = []  # Own a Warden applying any of these (Heavy Air: a slow)
@export var max_range_owned: float = 0.0  # Own an attacking Warden with range at most this (Short Roots: 2); 0 = no check
# Seed cards (dream_design.md "Seed cards"): offered without their Wardens. `description` is the "Now"
# effect; `grows_text` the bigger one once you have a Warden in `grows_with` (ids). (They no longer call a family
# into a family pick: user, "make it predictable", 7d3c6672.)
@export var grows_with: Array[String] = []
@export var grows_text: String = ""
@export var min_non_attackers: int = 0  # Non-attacking Wardens (walls, catchers, auras…) on the map; hard Need
# The statuses a combo card works with, shown as its Needs line (dream_design.md "How Needs are shown
# on a card"): the card never names a Warden you don't have.
@export var shows_statuses: Array[StringName] = []
# Discovery unlocks (dream_design.md "Discovery unlocks"): offered only once every entry is discovered
# ("reaction:<id>", "crowned:<id>", "chain:5", "kinship:any", "warden:<id>", "reactions:2"). Cards
# whose Needs name Wardens also need them built once (implicit), except combo and Legendary cards.
@export var discovered_by: Array[String] = []

@export_group("Nurture")
@export var nurture_discount: float = 0.0  # 0.15 = ranks cost 15% less (all cards together max 45%)
@export var rank_damage_bonus: float = 0.0  # Extra damage per rank (Warm Hands 0.03)
@export var rank_crit_bonus: float = 0.0  # Crit chance per rank (The Old Ones 0.02)
# Max Nurture rank: above 5 raises it (Deeper Rings 7), below 5 caps it (Wild Growth 1; a cap wins).
@export var max_rank_set: int = 0
@export var plant_discount: float = 0.0  # 0.3 = planting any Warden costs 30% less (Wild Growth)

@export_group("Clearing")
# Offered only with at least this many obstacles left (of `clears_obstacle`'s kind if set).
@export var min_obstacles: int = 0
@export var clear_discount: float = 0.0  # 0.4 = clearing costs 40% less (stacks, min 1 Dew)
@export var free_clears_add: int = 0  # Free clears gained now (Heartwood's Reach)
@export var free_first_clears_add: int = 0  # Clears that cost nothing (Tend the Forest: the first 2)
@export var dew_per_obstacle_clear: int = 0  # Dew for every clear from now on (Reclaimed Earth)
# One-shot: clears every obstacle of this kind now, without Seeds (Burn Back the Dead Wood).
@export var clears_obstacle: ObstacleData

@export_group("Rule")
# cozy_corners, hedge_maze, conductive_soil, spore_cascade, overgrown (no selling while creatures
# walk), restless_dreams (no "Let it pass"), reclaimed_earth (cleared cells turn fertile),
# tended_forest (+1% damage per clear this run); Nurture: kindred_roots, remembered_care,
# sunlit_rest, old_ones, chosen_few, nursery; wide / narrow: many_hands, sprout_chorus, canopy,
# solitude, few_and_mighty, last_light
@export var rule_id: StringName = &""

func is_rare_or_better() -> bool:
	return rarity >= Rarity.RARE

func is_bittersweet() -> bool:
	return tags.has("bittersweet")

func is_deepened() -> bool:
	return deepens != ""

static func rarity_name(value: Rarity) -> String:
	return ["Common", "Uncommon", "Rare", "Legendary"][value]

static func rarity_color(value: Rarity) -> Color:
	return UiStyle.rarity_color(value)  # ui_style.md
