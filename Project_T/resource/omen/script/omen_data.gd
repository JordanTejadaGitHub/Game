extends Resource
class_name OmenData

# One Omen (documentation/run_design.md, "Omens"): a twist on the next block of drifts, chosen at a
# rest, with a reward paid at the rest after that block. Multipliers are 1.0 = unchanged; bosses
# ignore them (their escorts don't).

@export var id: String = ""
@export var display_name: String = "Omen"
@export_multiline var description: String = ""  # The twist, e.g. "Creatures have 20% more health."
@export var min_drift: int = 0  # Only offered for blocks starting at this drift or later
@export var requires_flyers: bool = false  # Only offered if the next block has flying creatures

@export_group("Next block")
@export var health_multiplier: float = 1.0
@export var speed_multiplier: float = 1.0
@export var count_multiplier: float = 1.0  # Creatures per drift
@export var flyer_count_multiplier: float = 1.0  # Flying creatures, on top of count_multiplier
@export var coat_multiplier: float = 1.0  # Blight coats
@export var creature_dew_multiplier: float = 1.0
@export var status_duration_multiplier: float = 1.0
@export var arrival_spacing_multiplier: float = 1.0  # < 1 = creatures arrive closer together

@export_group("Reward")
# Dew and Seeds scale with the act (OmenDirector.ACT_REWARD_SCALE).
@export var reward_dew: int = 0
@export var reward_seeds: int = 0
@export var reward_leaves: int = 0  # Regrow now
@export var reward_max_leaves: int = 0  # The Heartwood holds more (and regrows them)
@export var reward_rare_dreams: int = 0  # The next N Dreams each include a Rare+ card
@export var reward_extra_dream_cards: int = 0  # The next Dream offers N more cards
@export var reward_rest_bonus_multiplier: float = 1.0  # This rest's bonus × N (Dry Spell: 2)
