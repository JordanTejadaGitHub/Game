extends Node
class_name AreaHitQueue

# Perf (platforms.md, stacked late drifts): a pulse, splash or cloud tick on a dense crowd lands 20+ hits
# at once, and a few of them in one frame made the p99 frames (~21 ms at 3×). Area hits past BUDGET in one
# frame wait here and land at the start of the next frame (in order, with the same numbers), so a burst is
# spread over a couple of frames instead of one. Single-target hits are never queued. Made in the run's
# scene on first use (like ReactionTracker); Tower.hit asks `defer`.

const GROUP := &"area_hit_queue"
const BUDGET := 24  # Area hits per frame before the rest wait a frame

var _frame := -1
var _count := 0
var _queue: Array = []  # [tower, enemy, multiplier, crit, combo]
var flushing := false

static func find(near: Node) -> AreaHitQueue:
	if near == null or not near.is_inside_tree():
		return null
	var queue := near.get_tree().get_first_node_in_group(GROUP) as AreaHitQueue
	if queue == null:
		queue = AreaHitQueue.new()
		queue.name = "AreaHitQueue"
		var scene := near
		while scene.get_parent() != null and scene.get_parent() != near.get_tree().root:
			scene = scene.get_parent()
		scene.add_child(queue)
	return queue

func _ready() -> void:
	add_to_group(GROUP)
	process_priority = -100  # Before the Wardens: last frame's overflow lands first

# Counts an area hit this frame; true = over the budget: it was queued and the caller does nothing now.
func defer(tower: Node, enemy: Node2D, multiplier: float, crit: int, combo: StringName) -> bool:
	if flushing:
		return false
	var frame := Engine.get_process_frames()
	if frame != _frame:
		_frame = frame
		_count = 0
	_count += 1
	if _count <= BUDGET:
		return false
	_queue.append([tower, enemy, multiplier, crit, combo])
	return true

func pending() -> int:
	return _queue.size()

func _process(_delta: float) -> void:
	if _queue.is_empty():
		return
	var now := _queue.slice(0, BUDGET)  # This frame's share; the rest waits again
	_queue = _queue.slice(BUDGET)
	flushing = true
	for entry in now:
		var tower: Node = entry[0]
		var enemy: Node2D = entry[1]
		if is_instance_valid(tower) and is_instance_valid(enemy) and not enemy.is_cleansed:
			tower.hit(enemy, entry[2], true, entry[3], entry[4])
	flushing = false
	_frame = Engine.get_process_frames()
	_count = now.size()  # The flushed hits use up this frame's budget
