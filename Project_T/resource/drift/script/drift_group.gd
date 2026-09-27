extends Resource
class_name DriftGroup

# Creatures that arrive together, one every `spacing` seconds. Several entries are mixed evenly
# (e.g. 20 Leaf Bugs + 5 Bark Beetles = a beetle every 5th creature).

@export var entries: Array[DriftEntry] = []
@export var spacing: float = 1.0  # Seconds between creatures
@export var delay: float = 0.0  # Extra seconds after the previous group's last creature before this group starts

# The group's creatures in arrival order, with evenly mixed kinds. Omens scale the counts:
# `count_multiplier` for every non-boss entry, `flyer_multiplier` on top for flying creatures.
func get_arrival_order(count_multiplier: float = 1.0, flyer_multiplier: float = 1.0) -> Array[EnemyData]:
	var order: Array[EnemyData] = []
	for slot in get_arrivals(count_multiplier, flyer_multiplier):
		order.append(slot[0])
	return order

# Like get_arrival_order, but each item is [EnemyData, elite: bool].
func get_arrivals(count_multiplier: float = 1.0, flyer_multiplier: float = 1.0) -> Array:
	var slots: Array = []  # [position 0..1, EnemyData, elite]
	for entry in entries:
		var count := entry.get_count(count_multiplier, flyer_multiplier)
		for i in count:
			slots.append([(i + 0.5) / count, entry.enemy, entry.elite])
	slots.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return slots.map(func(slot: Array) -> Array: return [slot[1], slot[2]])
