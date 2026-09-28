extends Resource
class_name UnlockData

# One Memory Grove node (meta_design.md "The Memory Grove: a tech tree"): bought with Seeds between
# runs, a spot on one of the Heartwood's three limbs (Perks, Families, Cards). Where it sits and what
# its branch looks like come from assets/meta/grove/grove_layout.json (same `id`). Effects are data:
# families joining the family picks, Dream cards joining the Dream pool, a loadout slot, or a perk
# (per level) that only works while it's carried in the loadout.

enum Root { WARDENS, DREAMS, PERKS, FORESTS }  # Limbs: Families, Cards, Perks (Forests: later)

@export var id: String = ""
@export var display_name: String = "Unlock"
@export_multiline var description: String = ""
@export var root: Root = Root.WARDENS
@export var costs: Array[int] = [50]  # Seeds per level (its size = the number of levels)
# Prerequisites: every id in `requires_all` ("id" or "id:level"), and at least
# `requires_any_count` of `requires_any`.
@export var requires_all: Array[String] = []
@export var requires_any: Array[String] = []
@export var requires_any_count: int = 1
@export var order: int = 0  # Order in lists (the loadout's perk list)
@export var icon: int = -1  # Frame in its limb's icon sheet (assets/meta/icons/), -1 = none
@export var start := false  # Grown from the start (Sporeling, Firefly Jar, Dewdrop), never bought
# Grows free when this milestone is reached (refunding it if it was bought). With no `costs` it can
# only be grown this way (Firefly Jar's hidden branch).
@export var milestone: String = ""
@export var legendary := false  # A Legendary tip on the Cards limb

@export_group("Unlocks")
@export var families: Array[String] = []  # Base Warden ids that join the family picks
@export var dream_cards: Array[String] = []  # Dream card ids (in_start_pool = false) that join the pool
@export var loadout_slots: int = 0  # Loadout slot nodes: +N perk slots

@export_group("Perk (per level, while carried)")
@export var starting_dew: int = 0
@export var dew_gain: float = 0.0  # Rich Dew: +share of Dew from dispelled nightmares
@export var rest_bonus: float = 0.0  # Rested Roots: +share of the rest bonus
@export var max_leaves: int = 0
@export var dream_rerolls: int = 0
@export var dream_banishes: int = 0
@export var extra_dream_cards: int = 0  # Wider Dreams: cards per offer +N
@export var extra_omens: int = 0  # Omen Reader: Omens per offer +N
@export var seed_bonus: float = 0.0  # 0.10 = +10% Seeds
@export var early_bloom: bool = false  # The first family pick offers every family you own
@export var starting_dreamlight: int = 0  # Early Light: Dreamlight at run start
@export var starting_cards: Array[String] = []  # Clear Sight: Dream cards taken at run start
@export var random_common_cards: int = 0  # Kindling: random Common Dreams taken at run start
@export var sprout_charges: int = 0  # Sprout Bed: free Sprouts
@export var free_nurtures: int = 0  # First Care: free Nurture ranks

func get_levels() -> int:
	return costs.size()

# Seeds for the next level after owning `level` (0 = the first), or -1 when maxed.
func get_cost(level: int) -> int:
	return costs[level] if level < costs.size() else -1

# Seeds for every level up to `level`.
func get_spent(level: int) -> int:
	var total := 0
	for i in mini(level, costs.size()):
		total += costs[i]
	return total

# A perk: carried in the loadout to work (not the loadout slot nodes themselves).
func is_perk() -> bool:
	return root == Root.PERKS and loadout_slots == 0

# Grown without buying it, from the start or only by a milestone.
func is_free() -> bool:
	return start or (milestone != "" and costs.is_empty())

func get_section() -> String:
	return ["families", "cards", "perks", "forests"][root]
