extends Resource
class_name OmenData

# One Omen (documentation/run_design.md, "Omens"): a twist on the next block of drifts, chosen at a
# rest, with a reward paid at the rest after that block. Multipliers are 1.0 = unchanged; bosses
# ignore them (their escorts don't).

@export var id: String = ""
@export var display_name: String = "Omen"
@export_multiline var description: String = ""  # The twist, e.g. "Creatures have 20% more health."
@export var flavor: String = ""  # One line in the Heartwood's voice, shown in the whisper face (run_design.md "Omen voice")
@export var min_drift: int = 0  # Only offered for blocks starting at this drift or later
@export var requires_flyers: bool = false  # Only offered if the next block has flying creatures
@export var requires_coat: bool = false  # Only offered if the next block has a coated nightmare (Hard Bark)
@export var requires_legendary: bool = false  # Only offered if a Legendary can still be offered this run (Lean Season)
@export var requires_clearing: bool = false  # Only offered once clearing is unlocked this run (Shifting Ground: its reward is for clearing)
@export var never_before_boss: bool = false  # Not offered for a block with a boss drift (Leaf Fall: a doubled boss leak would end the run)
@export var requires_grove: String = ""  # Only in the pool once this Grove node is planted (Restless Omens; the full game)
@export var requires_charged_source: bool = false  # Only offered once something this run applies Charged (Static Sky)
# The offer shows 2 Omens of different kinds (run_design.md "More Omens").
enum Kind { NIGHTMARES, YOUR_SIDE, DOUBLE_EDGED, MAP, MAZE }  # MAZE: Omens that test the maze, not the numbers
@export var kind: Kind = Kind.NIGHTMARES
@export var needs_free_cells: int = 0  # Only on maps with this many free cells away from the route (Shifting Ground)
@export var waiting_for_hook: bool = false  # Not offered until its twist is built in Tower / Enemy code

@export_group("Next block")
@export var health_multiplier: float = 1.0
@export var speed_multiplier: float = 1.0
@export var count_multiplier: float = 1.0  # Creatures per drift
@export var flyer_count_multiplier: float = 1.0  # Flying creatures, on top of count_multiplier
@export var coat_multiplier: float = 1.0  # Blight coats
@export var creature_dew_multiplier: float = 1.0
@export var status_duration_multiplier: float = 1.0
@export var arrival_spacing_multiplier: float = 1.0  # < 1 = creatures arrive closer together
@export var warden_range_add: float = 0.0  # Fog Bank: −1 (never below 1 range; Tower asks OmenDirector)
@export var warden_attack_speed_multiplier: float = 1.0  # Wilting: 0.85
@export var no_build_during_drift: bool = false  # Frozen Ground: planting and growing only at rests
@export var leak_multiplier: float = 1.0  # Leaf Fall: every leak costs ×2 leaves (bosses too)
@export var leak_add: int = 0  # Giants' Walk: every leak costs this many more leaves (after leak_multiplier)
@export var rest_bonus_multiplier: float = 1.0  # Lean Season: the block's rest bonus × 0.5
@export var status_immune: Array[StringName] = []  # Sleepless: drowsy, held
@export var always_status: StringName = &""  # Heavy Rain: always Soaked
@export var extra_elites: int = 0  # Elder Night: +1 elite in every drift
@export var all_flyer_drifts: int = 0  # Hollow Wind: the block's first N drifts are all flyers
@export var sprout_obstacles: int = 0  # Shifting Ground: Withered Trees sprout at the block's start
@export var sprouts_beside_path: bool = false  # Shifting Ground: trees may sprout right beside the route (never on it)
# The maze Omens (run_design.md "Omens with teeth"):
@export var trample_thornwall: bool = false  # Tramplers: each drift, the first nightmare to walk past a Thornwall tramples it (Enemy Code)
@export var crumble_thornwall: bool = false  # Second Path: the block's start crumbles the Thornwall that shortens the route most (full refund; no replanting until the rest)
@export var burrow_tiles: int = 0  # Burrowers: at every bend, nightmares burrow this many path tiles ahead (Enemy Code)
@export var burrow_time: float = 0.5  # …untargetable for this long

@export_group("Reward")
# Dew and Seeds scale with the act (OmenDirector.ACT_REWARD_SCALE).
@export var reward_dew: int = 0
@export var reward_seeds: int = 0
@export var reward_leaves: int = 0  # Unused: no Omen heals leaves (run_design.md "Omen rewards: no leaf regrowth")
@export var reward_max_leaves: int = 0  # Unused: no Omen gives leaves of any kind (run_design.md, 2026-10-01)
@export var reward_rare_dreams: int = 0  # The next N Dreams each include a Rare+ card
@export var reward_extra_dream_cards: int = 0  # The next Dream offers N more cards
@export var reward_rest_bonus_multiplier: float = 1.0  # This rest's bonus × N (Dry Spell: 2)
@export var reward_pot_multiplier: float = 0.0  # Dry Spell: at the rest, the block's base Dew pot × this (what it would have earned, and more)
@export var reward_dreamlight: int = 0  # Unused: no Omen gives Dreamlight, it stays in cards (run_design.md, 2026-10-01)
@export var reward_legendary: bool = false  # The next Dream includes a Legendary (act 2+)
@export var reward_tree_seeds: int = 0  # Shifting Ground: each tree cleared from now on gives this many extra Seeds
