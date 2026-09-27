extends Resource
class_name DriftGroup

# Creatures that arrive together, one every `spacing` seconds. Several entries are mixed evenly
# (e.g. 20 Leaf Bugs + 5 Bark Beetles = a beetle every 5th creature).

@export var entries: Array[DriftEntry] = []
@export var spacing: float = 1.0  # Seconds between creatures
@export var delay: float = 0.0  # Extra seconds after the previous group's last creature before this group starts

# The group's creatures in arrival order, with evenly mixed kinds.
func get_arrival_order() -> Array[EnemyData]:
	var slots: Array = []  # [position 0..1, EnemyData]
	for entry in entries:
		for i in entry.count:
			slots.append([(i + 0.5) / entry.count, entry.enemy])
	slots.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var order: Array[EnemyData] = []
	for slot in slots:
		order.append(slot[1])
	return order
