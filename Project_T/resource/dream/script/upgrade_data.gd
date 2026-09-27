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

@export_group("Status")
@export var status_id: StringName = &""
@export var status_strength_bonus: float = 0.0
@export var status_duration_add: float = 0.0  # Seconds
@export var status_duration_multiplier: float = 1.0

@export_group("Economy")
@export var dew_now: int = 0
@export var dew_per_clear: int = 0
@export var max_leaves_add: int = 0
@export var leaves_now: int = 0
@export var evolve_discount: float = 0.0  # 0.25 = evolving costs 25% less
@export var set_cost_warden: String = ""  # Warden id whose build cost becomes `set_cost`
@export var set_cost: int = 0

@export_group("Rule")
@export var rule_id: StringName = &""  # cozy_corners, hedge_maze, conductive_soil, spore_cascade

func is_rare_or_better() -> bool:
	return rarity >= Rarity.RARE

static func rarity_name(value: Rarity) -> String:
	return ["Common", "Uncommon", "Rare", "Legendary"][value]

static func rarity_color(value: Rarity) -> Color:
	return [Color(0.75, 0.8, 0.75), Color(0.5, 0.85, 0.55), Color(0.5, 0.7, 1.0), Color(1.0, 0.75, 0.3)][value]
