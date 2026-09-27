extends Resource
class_name DriftData

# One drift (wave): groups of creatures arriving one after another.

@export var groups: Array[DriftGroup] = []

# When each creature arrives, in seconds from the drift's start: [[time, EnemyData, elite], ...]
# sorted by time.
# Omens: `count_multiplier` / `flyer_multiplier` scale the counts (see DriftEntry.get_count),
# `spacing_multiplier` scales all the gaps (Restless Wind: 0.7 = 30% closer together).
func get_schedule(count_multiplier: float = 1.0, flyer_multiplier: float = 1.0, spacing_multiplier: float = 1.0) -> Array:
	var schedule: Array = []
	var time := 0.0
	for g in groups.size():
		var group := groups[g]
		if g > 0:
			time += (group.spacing + group.delay) * spacing_multiplier
		var arrivals := group.get_arrivals(count_multiplier, flyer_multiplier)
		for i in arrivals.size():
			if i > 0:
				time += group.spacing * spacing_multiplier
			schedule.append([time, arrivals[i][0], arrivals[i][1]])
	return schedule

func get_creature_count() -> int:
	var total := 0
	for group in groups:
		for entry in group.entries:
			total += entry.count
	return total

# Whether any creature in this drift flies (Moth Night only comes when flyers do).
func has_flyers() -> bool:
	for group in groups:
		for entry in group.entries:
			if entry.enemy != null and entry.enemy.trait_kind == EnemyData.Trait.FLYING:
				return true
	return false
