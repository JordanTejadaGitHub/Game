extends Node2D
class_name StartArrows

# Start arrows (user 2026-10-01: "add arrows at the beginning of the wave, so we know the direction"): when a drift
# starts, chevrons on the first ARROW_CELLS cells of the route from the start point along it, marching for SHOW_TIME
# and fading out. They follow a re-route while they show. Reduced motion: steady, then fade. Made by the HUD; drawn
# above the ground and the start mist.

const ARROW_CELLS := 4  # Route cells from the start that get a chevron
const SHOW_TIME := 3.5  # Game seconds
const FADE_TIME := 0.8  # The last part of SHOW_TIME
const MARCH_SPEED := 2.5  # Chevrons lit per second, start to end
const COLOR := Palette.WRAITHLIGHT  # Cold: the nightmares' way in
const OUTLINE := Palette.DREAD
const SIZE := 20.0  # Half the chevron's width, px (cells are 64)

var _map: Node
var _age := -1.0  # < 0 = hidden
var _cells: Array[Vector2] = []  # World centres of the route's first cells, then the one after (for the last direction)
var _still := false

func _ready() -> void:
	z_index = 1  # Over the start mist (the first chevron sits in it); brief, so over the first nightmares too
	var main := get_parent()
	_map = main.get_node_or_null("%MapGenerator")
	var director := main.get_node_or_null("%DriftDirector")
	if director != null:
		director.drift_started.connect(func(_number: int) -> void: show_arrows())
	if _map != null and _map.has_signal("path_changed"):
		_map.path_changed.connect(func() -> void:
			if _age >= 0.0:
				_read_route())

func is_showing() -> bool:
	return _age >= 0.0

func show_arrows() -> void:
	_still = bool(Fx.setting("reduced_motion", false))
	_read_route()
	_age = 0.0 if _cells.size() >= 2 else -1.0
	queue_redraw()

# The route from the start: ARROW_CELLS cells plus the next one (so the last chevron knows where it points).
func _read_route() -> void:
	_cells.clear()
	if _map == null:
		return
	var route: PackedVector2Array = _map.get_path_from(_map.startPath)
	for i in mini(route.size(), ARROW_CELLS + 1):
		_cells.append(_map.MAP_GRID.calculate_map_position(route[i]))

func _process(delta: float) -> void:
	if _age < 0.0:
		return
	_age += delta
	if _age >= SHOW_TIME:
		_age = -1.0
	queue_redraw()

func _draw() -> void:
	if _age < 0.0 or _cells.size() < 2:
		return
	var fade := clampf((SHOW_TIME - _age) / FADE_TIME, 0.0, 1.0)
	var count := mini(ARROW_CELLS, _cells.size() - 1)
	for i in count:
		var dir := (_cells[i + 1] - _cells[i]).normalized()
		var lit := 1.0
		if not _still:  # The march: each chevron brightens in turn, start to end
			var phase := fposmod(_age * MARCH_SPEED - i, float(count))
			lit = 0.45 + 0.55 * clampf(1.0 - phase, 0.0, 1.0)
		_draw_chevron(_cells[i], dir, lit * fade)

func _draw_chevron(centre: Vector2, dir: Vector2, alpha: float) -> void:
	var side := Vector2(-dir.y, dir.x) * SIZE
	var tip := centre + dir * SIZE * 0.7
	var back := centre - dir * SIZE * 0.5
	var points := PackedVector2Array([back + side, tip, back - side])
	draw_polyline(points, Color(OUTLINE, 0.85 * alpha), 12.0, true)
	draw_polyline(points, Color(COLOR, alpha), 7.0, true)
