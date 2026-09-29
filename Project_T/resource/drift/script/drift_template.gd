extends Resource
class_name DriftTemplate

# A kind of rolled drift (run_design.md "Random drifts"): which nightmare types it's made of and how
# the drift's health budget is shared between them. DriftRoller draws one per rollable drift,
# weighted by the act. Files: resource/drift/template/*.tres (the old named drifts became these).

@export var id: StringName = &""
@export var display_name: String = ""  # "Swarm", for the rest report ("This block: Swarm, Mixed…")
@export var weights: Array[float] = [1.0, 1.0, 1.0, 1.0]  # Draw weight in acts 1–4 (0 = never)
# The lead type must carry one of these roll tags (EnemyData.roll_tags); empty = any type.
@export var lead_tags: Array[StringName] = []
# The lead's share of the budget, and how many types the drift mixes in all (each other type gets at
# least DriftRoller.MIN_SHARE).
@export var lead_share_min: float = 0.2
@export var lead_share_max: float = 0.6
@export var min_types: int = 2
@export var max_types: int = 4
# At most one limited template (Swarm, Special) per block.
@export var limited: bool = false
# Elite hunt: this many of the lead type come Deeply Blighted, paid for out of the budget (fewer
# nightmares, more elites).
@export var extra_elites: int = 0
# Arrival gaps × this (Swarm comes thick, Heavy spaced out).
@export var spacing_multiplier: float = 1.0

func get_weight(act: int) -> float:
	return weights[clampi(act, 1, weights.size()) - 1] if not weights.is_empty() else 0.0

# True if `data` may lead this template.
func can_lead(data: EnemyData) -> bool:
	if lead_tags.is_empty():
		return true
	for tag in data.roll_tags:
		if tag in lead_tags:
			return true
	return false
