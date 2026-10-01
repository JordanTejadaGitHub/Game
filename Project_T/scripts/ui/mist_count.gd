extends Node2D
class_name MistCount

# Nightmares held in the start mist (platforms.md "Calling drifts early stacks them": at most
# EnemyContainer.max_field on the field, the rest wait): a small "+24" tag over the start, from
# DriftDirector.get_waiting_count(), only while some wait. Made by the HUD, in the world.

const REFRESH := 0.25  # Seconds (real time) between counts
const LIFT := 40.0  # Pixels above the start cell's centre

var drift_director: DriftDirector
var map
var waiting := 0  # (tests)
var _clock := 0.0

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	z_index = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	map = drift_director.get_node_or_null("%MapGenerator") if drift_director != null else null

func _process(delta: float) -> void:
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock > 0.0 or drift_director == null or not drift_director.has_method("get_waiting_count"):
		return
	_clock = REFRESH
	var now: int = drift_director.get_waiting_count()
	if now != waiting:
		waiting = now
		queue_redraw()

func _draw() -> void:
	if waiting <= 0 or map == null:
		return
	var at: Vector2 = map.MAP_GRID.calculate_map_position(map.startPath)
	WorldLabel.draw_tag(self, at.x, at.y - LIFT, "+%d" % waiting, UiStyle.INK)
