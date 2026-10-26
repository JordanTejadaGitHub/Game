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
# A Charged (Static) bolt struck at `at` for `damage` (Reactions.strike_bolt; ChargedBolt shows it), for Sound.
signal bolt_struck(at: Vector2, damage: float)
# A Reaction's payoff landing after it fired, for Sound (audio_direction.md seventh pass): Smother's stored Poisoned bursting
# when the Root ends (size 1), Pinned's hit piercing the line behind (size = nightmares pierced).
signal reaction_payoff(id: StringName, at: Vector2, size: int)

# A Crowned Reaction went off on `enemy` (owner 2026-10-22, dream_council_review.md 29: an event of its own), for Sound.
# `late` = a late crown (its third status landed within Reactions.CROWN_WINDOW after the base Reaction).
signal crowned_fired(id: StringName, enemy: Node2D, towers: Array, late: bool)

var counts := {}  # Reaction id -> times it fired this run
var crowned_block := 0  # Crowned Reactions this block / run (rest report, run summary); late_run = how many were late crowns
var crowned_run := 0
var late_run := 0
var longest_chain := 0
# > 0 while an echo (Echo Hollow) is going off: Hollows don't echo echoes (Encore: once more).
var echo_depth := 0
# Carried Storm: where Reactions went off in the last moment ({id, at, time, applier}).
var recent_spots: Array = []
var _clock := 0.0

func _ready() -> void:
	add_to_group(GROUP)
	Fx.reset_run()  # A new run's first Reaction: fresh longest chain and settings
	Reactions._crown_field.clear()  # …and late crowns' field cooldowns

func _process(delta: float) -> void:
	_clock += delta
	if not _frost_queue.is_empty():
		_drain_frost()

# Frostburst chains (Reactions.frostburst, section 37): the Frost a burst gives its neighbours lands next frame, in order,
# at most FROST_QUEUE_BUDGET a frame; one that would burst waits while FROST_BURSTS_PER_SECOND chain bursts already went
# off in the last second (never dropped). [enemy, stacks, source, gen, full]
const FROST_QUEUE_BUDGET := 32
var _frost_queue: Array = []
var _chain_bursts: Array[float] = []  # Clock times of the last second's chain bursts

func queue_frost(enemy: Node2D, stacks: int, source: Node, gen: int, full: bool) -> void:
	_frost_queue.append([enemy, stacks, source, gen, full])

func note_chain_burst() -> void:
	_chain_bursts.append(_clock)

func _drain_frost() -> void:
	var now := _frost_queue.slice(0, FROST_QUEUE_BUDGET)
	var later := _frost_queue.slice(FROST_QUEUE_BUDGET)
	_frost_queue = []  # Bursts below queue anew (they land after these)
	var waiting: Array = []
	for entry in now:
		if not is_instance_valid(entry[0]) or entry[0].is_cleansed:
			continue
		var enemy: Node2D = entry[0]
		if _clock < float(enemy.get_meta(Reactions.FROST_LOCK_META, -INF)):
			continue  # It burst a moment ago: burst-given Frost passes it by
		var s: EnemyStatuses = enemy.statuses
		if bool(entry[4]) and s.stacks(EnemyStatuses.FROST) + int(entry[1]) >= s.get_max_stacks(EnemyStatuses.FROST):
			while not _chain_bursts.is_empty() and _clock - _chain_bursts[0] >= 1.0:
				_chain_bursts.remove_at(0)
			if _chain_bursts.size() >= Reactions.FROST_BURSTS_PER_SECOND:
				waiting.append(entry)  # Over the field's bursts a second: it waits
				continue
		Reactions.apply_chain_frost(enemy, int(entry[1]), entry[2] if is_instance_valid(entry[2]) else null, int(entry[3]), bool(entry[4]))
	_frost_queue = waiting + later + _frost_queue

# Remembers where Reaction `id` went off (a Samara seed passing through within the window carries it).
func note_spot(id: StringName, at: Vector2, applier: Node) -> void:
	recent_spots = recent_spots.filter(func(r: Dictionary) -> bool:
		return _clock - r.time <= Reactions.CARRIED_WINDOW)
	recent_spots.append({"id": id, "at": at, "time": _clock, "applier": applier})

# The newest Reaction within `reach` pixels of `at` in the last CARRIED_WINDOW seconds, or {}.
func spot_near(at: Vector2, reach: float) -> Dictionary:
	for i in range(recent_spots.size() - 1, -1, -1):
		var r: Dictionary = recent_spots[i]
		if _clock - r.time <= Reactions.CARRIED_WINDOW and r.at.distance_to(at) <= reach:
			return r
	return {}

func record(id: StringName, enemy: Node2D, chain: int, towers: Array) -> void:
	counts[id] = counts.get(id, 0) + 1
	longest_chain = maxi(longest_chain, chain)
	reaction_fired.emit(id, enemy, chain, towers)
	if chain >= 2:
		# Badge from ×2, hitstop + surge at ×5, Dawnburst at ×10 (Fx), then anyone else listening.
		Fx.chain(chain, enemy.global_position, get_parent(), towers)
		chain_reached.emit(chain, enemy.global_position, towers)

# A Crowned one (Reactions calls it after record(), instant or late).
func record_crowned(id: StringName, enemy: Node2D, towers: Array, late: bool) -> void:
	crowned_block += 1
	crowned_run += 1
	if late:
		late_run += 1
	crowned_fired.emit(id, enemy, towers, late)

# The rest starts a new block's count (RestReport reads crowned_block first).
func reset_block() -> void:
	crowned_block = 0

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
