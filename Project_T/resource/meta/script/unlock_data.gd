extends Resource
class_name UnlockData

# One Memory Grove unlock (meta_design.md "The Memory Grove"): bought with Seeds between runs, grows
# as a plant on one of 4 roots. Effects are data: families joining the family picks, Dream cards
# joining the Dream pool, or a capped perk (starting Dew, leaves, rerolls, …) per level.

enum Root { WARDENS, DREAMS, PERKS, FORESTS }

@export var id: String = ""
@export var display_name: String = "Unlock"
@export_multiline var description: String = ""
@export var root: Root = Root.WARDENS
@export var costs: Array[int] = [50]  # Seeds per level (its size = the number of levels)
# Prerequisites: every id in `requires_all`, and at least `requires_any_count` of `requires_any`.
@export var requires_all: Array[String] = []
@export var requires_any: Array[String] = []
@export var requires_any_count: int = 1
@export var order: int = 0  # Position on its root (lower = closer to the trunk)

@export_group("Unlocks")
@export var families: Array[String] = []  # Base Warden ids that join the family picks
@export var dream_cards: Array[String] = []  # Dream card ids (in_start_pool = false) that join the pool

@export_group("Perk (per level)")
@export var starting_dew: int = 0
@export var max_leaves: int = 0
@export var dream_rerolls: int = 0
@export var dream_banishes: int = 0
@export var extra_dream_cards: int = 0  # Wider Dreams: cards per offer +N
@export var seed_bonus: float = 0.0  # 0.10 = +10% Seeds
@export var early_bloom: bool = false  # The first family pick offers every family you own
@export var starting_dreamlight: int = 0  # Early Light: Dreamlight at run start

func get_levels() -> int:
	return costs.size()

# Seeds for the next level after owning `level` (0 = the first), or -1 when maxed.
func get_cost(level: int) -> int:
	return costs[level] if level < costs.size() else -1
