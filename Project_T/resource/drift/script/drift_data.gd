extends Resource
class_name DriftData

# One drift (wave): groups of creatures arriving one after another.

@export var groups: Array[DriftGroup] = []

# When each creature arrives, in seconds from the drift's start: [[time, EnemyData], ...] sorted by time.
func get_schedule() -> Array:
	var schedule: Array = []
	var time := 0.0
	for g in groups.size():
		var group := groups[g]
		if g > 0:
			time += group.spacing + group.delay
		var order := group.get_arrival_order()
		for i in order.size():
			if i > 0:
				time += group.spacing
			schedule.append([time, order[i]])
	return schedule

func get_creature_count() -> int:
	var total := 0
	for group in groups:
		for entry in group.entries:
			total += entry.count
	return total
