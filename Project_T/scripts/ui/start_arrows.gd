extends Node2D
class_name StartArrows

# Route arrows at the start of a run (screens_ui.md "In the world", user 2026-10-01: "the arrows are for the beginning
# of every run so we know where to place towers … put them for the whole path but only display at the start of a
# run"; then "make the arrows more subtle and better looking, spread them out more"): small thin soft-gold chevrons
# (Moonlit Thread) spaced evenly along the route's length, about one every SPACING_CELLS cells, from the start to the
# last cell before the Heartwood. Each turns smoothly with the route around corners. A gentle shimmer moves start →
# Heartwood every SHIMMER_PERIOD s; steady under reduced motion. Shown from the run's start (the opening rest, before
# drift 1; a resumed run still before drift 1 too), following re-routes live as Wardens are planted or obstacles
# cleared; when the first drift starts they fade out and never return. Made by the HUD; drawn over the path tiles,
# under the build ghost's route preview (TowerPlacer, z 0), the Wardens and the nightmares.

const CELL := 64.0
const SPACING_CELLS := 3.0  # About one chevron per this many route cells (evened out over the route's length)
const SIZE := 0.4 * CELL / 2.0  # Half the chevron's width: the chevron spans ~40% of a cell
const TURN_SAMPLE := 0.45 * CELL  # Direction = the route's heading this far either side: a smooth turn at corners
const BASE_ALPHA := 0.4  # Resting opacity
const LIT_ALPHA := 0.7  # As the shimmer passes
const STILL_ALPHA := 0.5  # Reduced motion
const SHIMMER_PERIOD := 2.5  # Seconds for the shimmer to travel start → Heartwood
const SHIMMER_WIDTH := 1.2  # Chevron spacings the shimmer's glow spans
const FADE_TIME := 0.8  # Game seconds, once the first drift starts
const CORE := Palette.GOLD
const GLOW := Palette.GLOW

var _map: Node
var _director: Node
var _cells: Array[Vector2] = []  # World centres of the whole route, start to Heartwood
var _marks: Array[Vector2] = []  # [position, heading] pairs flattened: even indices positions, odd headings
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

# How many chevrons show now.
func mark_count() -> int:
	return _marks.size() / 2

func mark_position(i: int) -> Vector2:
	return _marks[i * 2]

func _on_first_drift() -> void:
	if not _done and _fade < 0.0:
		_fade = 0.0

func _read_route() -> void:
	_cells.clear()
	_marks.clear()
	if _map == null:
		return
	for cell in _map.get_path_from(_map.startPath):
		_cells.append(_map.MAP_GRID.calculate_map_position(cell))
	_place_marks()
	queue_redraw()

# Even spacing along the route's length, from the start to the last cell before the Heartwood (both always marked).
func _place_marks() -> void:
	if _cells.size() < 3:
		return
	var span := _length_to(_cells.size() - 2)
	var gaps := maxi(1, roundi(span / (SPACING_CELLS * CELL)))
	for i in gaps + 1:
		var d := span * i / gaps
		_marks.append(_point_at(d))
		_marks.append((_point_at(d + TURN_SAMPLE) - _point_at(maxf(d - TURN_SAMPLE, 0.0))).normalized())

func _length_to(index: int) -> float:
	var total := 0.0
	for i in index:
		total += _cells[i].distance_to(_cells[i + 1])
	return total

func _point_at(distance: float) -> Vector2:
	for i in _cells.size() - 1:
		var step := _cells[i].distance_to(_cells[i + 1])
		if distance <= step:
			return _cells[i].lerp(_cells[i + 1], distance / step)
		distance -= step
	return _cells[-1]

func _process(delta: float) -> void:
	if _done:
		return
	_age += delta
	if _fade >= 0.0:
		_fade += delta
		if _fade >= FADE_TIME:
			_done = true
			_cells.clear()
			_marks.clear()
	if not _still or _fade >= 0.0:
		queue_redraw()

func _draw() -> void:
	if not is_showing():
		return
	var fade := 1.0 - clampf(_fade / FADE_TIME, 0.0, 1.0) if _fade >= 0.0 else 1.0
	var count := mark_count()
	# The shimmer's place along the chevrons (0 .. count-1), with room to enter and leave
	var shimmer := fposmod(_age / SHIMMER_PERIOD, 1.0) * (count - 1 + 2.0 * SHIMMER_WIDTH) - SHIMMER_WIDTH
	for i in count:
		var alpha := STILL_ALPHA
		if not _still:
			var t := clampf(1.0 - absf(shimmer - i) / SHIMMER_WIDTH, 0.0, 1.0)
			alpha = lerpf(BASE_ALPHA, LIT_ALPHA, t * t * (3.0 - 2.0 * t))  # Smoothstep: a shimmer, not a blink
		_draw_chevron(_marks[i * 2], _marks[i * 2 + 1], alpha * fade)

# A thin chevron with a faint 1 px glow around its stroke, centred on whole pixels.
func _draw_chevron(centre: Vector2, dir: Vector2, alpha: float) -> void:
	centre = centre.round()
	var side := Vector2(-dir.y, dir.x) * SIZE
	var tip := centre + dir * SIZE * 0.55
	var back := centre - dir * SIZE * 0.45
	var points := PackedVector2Array([back + side, tip, back - side])
	draw_polyline(points, Color(GLOW, 0.25 * alpha), 4.0, true)
	draw_polyline(points, Color(CORE, alpha), 2.0, true)
