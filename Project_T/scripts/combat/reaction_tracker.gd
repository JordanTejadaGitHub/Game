extends Node
class_name ReactionTracker

# One per run (created in the running scene the first time a Reaction fires; group
# "reaction_tracker"). Counts Reactions and chains for the rest report and results, and tells the UI
# and effects what happened. The rules themselves are in Reactions.

const GROUP := &"reaction_tracker"

# A Reaction fired on `enemy`. `chain` is its link in a chain (1 = not caused by another Reaction).
# `towers` are the Wardens whose statuses or hit made it happen (light threads, Dawnburst flares).
signal reaction_fired(id: StringName, enemy: Node2D, chain: int, towers: Array)
# A chain reached `count` links (2, 3, …) at `where` (chain badge from ×2, surge at ×5, Dawnburst at ×10).
signal chain_reached(count: int, where: Vector2, towers: Array)

var counts := {}  # Reaction id -> times it fired this run
var longest_chain := 0

func _ready() -> void:
	add_to_group(GROUP)
	Fx.reset_run()  # A new run's first Reaction: fresh longest chain and settings

func record(id: StringName, enemy: Node2D, chain: int, towers: Array) -> void:
	counts[id] = counts.get(id, 0) + 1
	longest_chain = maxi(longest_chain, chain)
	reaction_fired.emit(id, enemy, chain, towers)
	if chain >= 2:
		# Badge from ×2, hitstop + surge at ×5, Dawnburst at ×10 (Fx), then anyone else listening.
		Fx.chain(chain, enemy.global_position, get_parent(), towers)
		chain_reached.emit(chain, enemy.global_position, towers)

func total() -> int:
	var sum := 0
	for id in counts:
		sum += counts[id]
	return sum

# The run's tracker, made on first use inside the scene `near` belongs to.
static func find(near: Node) -> ReactionTracker:
	if near == null or not near.is_inside_tree():
		return null
	var tracker := near.get_tree().get_first_node_in_group(GROUP) as ReactionTracker
	if tracker == null:
		tracker = ReactionTracker.new()
		tracker.name = "ReactionTracker"
		# The top-level scene `near` is in (the run's main scene), so it goes away with the run.
		var scene := near
		while scene.get_parent() != null and scene.get_parent() != near.get_tree().root:
			scene = scene.get_parent()
		scene.add_child(tracker)
	return tracker
