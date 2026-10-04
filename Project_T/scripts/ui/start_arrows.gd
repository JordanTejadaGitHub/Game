extends Node2D
class_name StartArrows

# The run-start route mist (screens_ui.md "Route mist", user 2026-10-01: the gold chevrons didn't "fit the theme"): at
# the run's start the whole route shows a ribbon of cold mist (a Line2D, RouteLine-styled so the high-contrast setting
# still applies), with ROUTE_WISPS brighter wisps drifting along it toward the Heartwood. Environment Assets' art is
# picked up when it's there (MIST_TEXTURE, a seamless strip tiled along the line and flowing slowly; WISP_TEXTURE, a
# row of WISP_FRAMES frames); until then the mist is a soft translucent line and the wisps soft drawn glows. Shown from
# the run's start (the opening rest, before drift 1; a resumed run still before drift 1 too), following re-routes live
# as Wardens are planted or obstacles cleared; when the first drift starts it fades out and never returns. Under reduced
# motion the mist doesn't flow and the wisps stand still. Made by the HUD; drawn over the path tiles, under the build
# ghost's route preview (TowerPlacer, z 0), the Wardens and the nightmares.

const CELL := 64.0
const MIST_TEXTURE := "res://assets/environment/dream/route_mist.png"
const WISP_TEXTURE := "res://assets/environment/dream/route_wisp.png"
const START_CAP := "res://assets/environment/dream/route_mist_start.png"  # 32×24: fades in, its right edge meets the strip
const END_CAP := "res://assets/environment/dream/route_mist_end.png"  # 32×24: curls forward, its left edge meets the strip
const WISP_FRAMES := 6
const WISP_ANCHOR := Vector2(15, 12)  # The wisp's head in its 24×24 frame (the tail trails to the left)
const TURN_SAMPLE := 0.45 * CELL  # Wisps face the route's heading this far either side: a smooth turn at corners
const WISP_FPS := 8.0
const MIST_COLOR := Color(Palette.WRAITHLIGHT, 0.32)  # The fallback ribbon: faint cold light
const MIST_WIDTH := 22.0
const ROUTE_WISPS := 3
const WISP_SPEED := 1.0 * CELL  # px per second along the route
const EDGE_FADE := 0.8 * CELL  # Wisps fade in after the start and out before the Heartwood
const FADE_TIME := 0.8  # Game seconds, once the first drift starts

var _map: Node
var _director: Node
var _cells: Array[Vector2] = []  # World centres of the whole route, start to Heartwood
var _span := 0.0  # Route length to the Heartwood
var _age := 0.0
var _fade := -1.0  # >= 0: fading out (the first drift started)
var _done := false  # Faded out: never shown again this run
var _still := false
var _mist := Line2D.new()
var _wisp: Texture2D = null
var _start_cap: Texture2D = null
var _end_cap: Texture2D = null

func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mist.name = "RouteMist"
	_mist.joint_mode = Line2D.LINE_JOINT_ROUND
	_mist.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_mist.end_cap_mode = Line2D.LINE_CAP_ROUND
	_mist.show_behind_parent = true  # The wisps (drawn by this node) over the ribbon
	RouteLine.apply(_mist, MIST_COLOR, MIST_WIDTH)
	if ResourceLoader.exists(MIST_TEXTURE) and not RouteLine.is_high_contrast():
		# The shared mist look (RouteLine): flows in 2-texel steps on TIME (a sub-texel scroll flickered, and 1-texel
		# steps flipped the strip's checker-dither edges), texture repeat, sharp joints
		RouteLine.style_mist(_mist)
	add_child(_mist)
	if ResourceLoader.exists(WISP_TEXTURE):
		_wisp = load(WISP_TEXTURE)
	if _mist.texture != null:  # Caps replace the round line ends
		_mist.begin_cap_mode = Line2D.LINE_CAP_NONE
		_mist.end_cap_mode = Line2D.LINE_CAP_NONE
		if ResourceLoader.exists(START_CAP):
			_start_cap = load(START_CAP)
		if ResourceLoader.exists(END_CAP):
			_end_cap = load(END_CAP)
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

# How many wisps drift along the route (fewer on a very short route).
func wisp_count() -> int:
	return 0 if _cells.size() < 3 else mini(ROUTE_WISPS, maxi(1, floori(_span / (3.0 * CELL))))

func _on_first_drift() -> void:
	if not _done and _fade < 0.0:
		_fade = 0.0

func _read_route() -> void:
	_cells.clear()
	if _map != null:
		for cell in _map.get_path_from(_map.startPath):
			_cells.append(_map.MAP_GRID.calculate_map_position(cell))
	_span = _length_to(_cells.size() - 1) if _cells.size() >= 2 else 0.0
	_mist.points = PackedVector2Array(_cells)
	_mist.visible = is_showing()
	queue_redraw()

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
	var alpha := 1.0
	if _fade >= 0.0:
		_fade += delta
		alpha = 1.0 - clampf(_fade / FADE_TIME, 0.0, 1.0)
		if _fade >= FADE_TIME:
			_done = true
			_cells.clear()
			_mist.points = PackedVector2Array()
	_mist.visible = is_showing()
	_mist.modulate.a = alpha  # multiplier: the fade
	if not _still or _fade >= 0.0:
		queue_redraw()

func _draw() -> void:
	if not is_showing():
		return
	var fade := 1.0 - clampf(_fade / FADE_TIME, 0.0, 1.0) if _fade >= 0.0 else 1.0
	_draw_caps(fade)
	var count := wisp_count()
	if count == 0:
		return
	var spacing := _span / count
	var shift := 0.0 if _still else fposmod(_age * WISP_SPEED, spacing)
	for i in count:
		var d := spacing * i + shift + spacing * 0.5 * float(_still)
		if d > _span:
			d -= _span
		var edge := clampf(minf(d, _span - d) / EDGE_FADE, 0.0, 1.0)
		_draw_wisp(_point_at(d), fade * edge, i, d)

# The strip's two caps, just beyond its ends and unscrolled (Environment Assets): the start cap's right edge meets the
# strip's start, the end cap's left edge its end, each turned to the route's first / last heading.
func _draw_caps(alpha: float) -> void:
	if _cells.size() < 2:
		return
	if _start_cap != null:
		var dir := (_cells[1] - _cells[0]).normalized()
		draw_set_transform(_cells[0].round(), dir.angle())
		draw_texture(_start_cap, Vector2(-_start_cap.get_width(), -_start_cap.get_height() / 2.0), Color(1, 1, 1, alpha))  # multiplier: the fade
	if _end_cap != null:
		var dir := (_cells[-1] - _cells[-2]).normalized()
		draw_set_transform(_cells[-1].round(), dir.angle())
		draw_texture(_end_cap, Vector2(0, -_end_cap.get_height() / 2.0), Color(1, 1, 1, alpha))  # multiplier: the fade
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _heading_at(distance: float) -> Vector2:
	return (_point_at(minf(distance + TURN_SAMPLE, _span)) - _point_at(maxf(distance - TURN_SAMPLE, 0.0))).normalized()

# One wisp: the art's frames if they're in (facing along the route, its head on the route), else a soft cold glow.
func _draw_wisp(at: Vector2, alpha: float, index: int, distance: float = 0.0) -> void:
	if alpha <= 0.0:
		return
	if _wisp != null:
		var frame_w := _wisp.get_width() / WISP_FRAMES
		var frame := (int(_age * WISP_FPS) + index * 2) % WISP_FRAMES if not _still else 0
		var region := Rect2(frame * frame_w, 0, frame_w, _wisp.get_height())
		draw_set_transform(at.round(), _heading_at(distance).angle())
		draw_texture_rect_region(_wisp, Rect2(-WISP_ANCHOR, region.size), region, Color(1, 1, 1, alpha))  # multiplier: the fade
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	for ring in 4:  # Soft fallback: a few faint layers, brightest in the middle
		draw_circle(at, 14.0 - ring * 3.0, Color(Palette.MOONLIGHT, alpha * (0.12 + ring * 0.1)))
