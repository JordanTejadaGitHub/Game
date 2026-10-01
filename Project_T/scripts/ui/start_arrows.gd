extends Node2D
class_name StartArrows

# Route arrows at the start of a run (screens_ui.md "In the world", user 2026-10-01: "the arrows are for the beginning
# of every run so we know where to place towers … put them for the whole path but only display at the start of a
# run"): chevrons along the whole route, start to Heartwood, shown from the run's start (the opening rest, before
# drift 1; a resumed run still before drift 1 too), following re-routes live as Wardens are planted or obstacles
# cleared. When the first drift starts they fade out and never return. A soft light travels along them toward the
# Heartwood; steady under reduced motion. Made by the HUD; drawn over the path tiles, under the build ghost's route
# preview (TowerPlacer, z 0), the Wardens and the nightmares.

const FADE_TIME := 0.8  # Game seconds, once the first drift starts
const MARCH_SPEED := 8.0  # Route cells per second the travelling light moves
const MARCH_WINDOW := 3.0  # Cells the light spans
const COLOR := Palette.WRAITHLIGHT  # Cold: the nightmares' way in
const OUTLINE := Palette.DREAD
const SIZE := 16.0  # Half the chevron's width, px (cells are 64)
const BASE_ALPHA := 0.55  # Every chevron's brightness; the travelling light adds the rest

var _map: Node
var _director: Node
var _cells: Array[Vector2] = []  # World centres of the whole route, start to Heartwood
var _age := 0.0
var _fade := -1.0  # >= 0: fading out (the first drift started)
var _done := false  # Faded out: never shown again this run
var _still := false

func _ready() -> void:
	z_index = -1
	var main := get_parent()
	_map = main.get_node_or_null("%MapGenerator")
	_director = main.get_node_or_null("%DriftDirector")
	if _director != null:
		_director.drift_started.connect(func(_number: int) -> void: _on_first_drift())
	if _map != null and _map.has_signal("path_changed"):
		_map.path_changed.connect(_read_route)
	_still = bool(Fx.setting("reduced_motion", false))
	_read_route.call_deferred()  # After the map is built

# Shown while the run hasn't started its first drift (a resumed run before drift 1 counts).
func is_showing() -> bool:
	return not _done and _cells.size() >= 2 and (_fade >= 0.0 or _director == null or _director.drifts_started == 0)

func _on_first_drift() -> void:
	if not _done and _fade < 0.0:
		_fade = 0.0

func _read_route() -> void:
	_cells.clear()
	if _map == null:
		return
	for cell in _map.get_path_from(_map.startPath):
		_cells.append(_map.MAP_GRID.calculate_map_position(cell))
	queue_redraw()

func _process(delta: float) -> void:
	if _done:
		return
	_age += delta
	if _fade >= 0.0:
		_fade += delta
		if _fade >= FADE_TIME:
			_done = true
			_cells.clear()
	queue_redraw()

func _draw() -> void:
	if not is_showing():
		return
	var alpha := 1.0 - clampf(_fade / FADE_TIME, 0.0, 1.0) if _fade >= 0.0 else 1.0
	var count := _cells.size() - 1  # No chevron on the Heartwood's own cell
	var light := fposmod(_age * MARCH_SPEED, float(count) + MARCH_WINDOW)
	for i in count:
		var lit := BASE_ALPHA
		if not _still:  # A soft light travelling toward the Heartwood
			lit += (1.0 - BASE_ALPHA) * clampf(1.0 - absf(light - i) / MARCH_WINDOW, 0.0, 1.0)
		else:
			lit = 0.8
		_draw_chevron(_cells[i], (_cells[i + 1] - _cells[i]).normalized(), lit * alpha)

func _draw_chevron(centre: Vector2, dir: Vector2, alpha: float) -> void:
	var side := Vector2(-dir.y, dir.x) * SIZE
	var tip := centre + dir * SIZE * 0.7
	var back := centre - dir * SIZE * 0.5
	var points := PackedVector2Array([back + side, tip, back - side])
	draw_polyline(points, Color(OUTLINE, 0.85 * alpha), 10.0, true)
	draw_polyline(points, Color(COLOR, alpha), 6.0, true)
