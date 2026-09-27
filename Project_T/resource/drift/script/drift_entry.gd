extends Resource
class_name DriftEntry

# `count` creatures of one kind, as part of a DriftGroup.

@export var enemy: EnemyData
@export var count: int = 1
@export var elite: bool = false  # Deeply Blighted: ×3 health, ×3 Dew, 2 leaves (acts_1_2.md)

# `count` scaled by Omens (never below 1). Bosses always come alone: they ignore Omens.
func get_count(count_multiplier: float = 1.0, flyer_multiplier: float = 1.0) -> int:
	if enemy == null or enemy.is_boss:
		return count
	var multiplier := count_multiplier
	if enemy.trait_kind == EnemyData.Trait.FLYING:
		multiplier *= flyer_multiplier
	return maxi(roundi(count * multiplier), 1)
