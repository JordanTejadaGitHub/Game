extends Resource
class_name DriftEntry

# `count` creatures of one kind, as part of a DriftGroup.

@export var enemy: EnemyData
@export var count: int = 1
@export var elite: bool = false  # Deeply Blighted: ×3 health, ×3 Dew, 2 leaves (acts_1_2.md)

# Kinds with fewer than this many stay as listed under the difficulty's extra nightmares (lone
# specials like a Lantern Bearer are the drift's key threat; doubling them isn't the point).
const EXTRA_MIN_COUNT := 3

# `count` scaled by the difficulty's extra nightmares (`extra`, rounded up, only for common kinds
# of 3+ and never elites; run_design.md "Difficulty pass v1"), then by Omens (never below 1).
# Bosses always come alone: they ignore both.
func get_count(count_multiplier: float = 1.0, flyer_multiplier: float = 1.0, extra: float = 1.0) -> int:
	if enemy == null or enemy.is_boss:
		return count
	var base := count
	if count >= EXTRA_MIN_COUNT and not elite:
		base = ceili(count * extra - 0.0001)
	var multiplier := count_multiplier
	if enemy.trait_kind == EnemyData.Trait.FLYING:
		multiplier *= flyer_multiplier
	return maxi(roundi(base * multiplier), 1)
