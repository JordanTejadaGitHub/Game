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
const WISP_FRAMES := 6
const WISP_FPS := 8.0
const MIST_COLOR := Color(Palette.WRAITHLIGHT, 0.32)  # The fallback ribbon: faint cold light
const MIST_WIDTH := 22.0
const MIST_FLOW := 0.5  # Cells per second the strip's texture flows toward the Heartwood
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
var _mist_material: ShaderMaterial = null

func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mist.name = "RouteMist"
	_mist.joint_mode = Line2D.LINE_JOINT_ROUND
	_mist.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_mist.end_cap_mode = Line2D.LINE_CAP_ROUND
	_mist.show_behind_parent = true  # The wisps (drawn by this node) over the ribbon
	RouteLine.apply(_mist, MIST_COLOR, MIST_WIDTH)
	if ResourceLoader.exists(MIST_TEXTURE):
		_mist.texture = load(MIST_TEXTURE)
		_mist.texture_mode = Line2D.LINE_TEXTURE_TILE
		_mist.default_color = Color.WHITE  # multiplier: the art carries the colour
		_mist.width = float(_mist.texture.get_height())
		_mist_material = ShaderMaterial.new()
		_mist_material.shader = _flow_shader()
		_mist.material = _mist_material
	add_child(_mist)
	if ResourceLoader.exists(WISP_TEXTURE):
		_wisp = load(WISP_TEXTURE)
	var main := get_parent()
	_map = main.get_node_or_null("%MapGenerator")
	_director = main.get_node_or_null("%DriftDirector")
	if _director != null:
		_director.drift_started.connect(func(_number: int) -> void: _on_first_drift())
	if _map != null and _map.has_signal("path_changed"):
		_map.path_changed.connect(_read_route)
	_still = bool(Fx.setting("reduced_motion", false))
	_read_route.call_deferred()  # After the map is built

# The strip flows toward the Heartwood (UV scroll); `flow` 0 holds it (reduced motion).
func _flow_shader() -> Shader:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float flow = 0.0;\nvoid fragment() {\n\tCOLOR = texture(TEXTURE, vec2(UV.x - flow, UV.y)) * COLOR;\n}\n"
	return shader

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
	if _mist_material != null and not _still:
		_mist_material.set_shader_parameter("flow", _age * MIST_FLOW)
	if not _still or _fade >= 0.0:
		queue_redraw()

func _draw() -> void:
	if not is_showing():
		return
	var fade := 1.0 - clampf(_fade / FADE_TIME, 0.0, 1.0) if _fade >= 0.0 else 1.0
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
		_draw_wisp(_point_at(d), fade * edge, i)

# One wisp: the art's frames if they're in, else a soft cold glow.
func _draw_wisp(at: Vector2, alpha: float, index: int) -> void:
	if alpha <= 0.0:
		return
	if _wisp != null:
		var frame_w := _wisp.get_width() / WISP_FRAMES
		var frame := (int(_age * WISP_FPS) + index * 2) % WISP_FRAMES if not _still else 0
		var region := Rect2(frame * frame_w, 0, frame_w, _wisp.get_height())
		draw_texture_rect_region(_wisp, Rect2(at.round() - region.size / 2.0, region.size), region, Color(1, 1, 1, alpha))  # multiplier: the fade
		return
	for ring in 4:  # Soft fallback: a few faint layers, brightest in the middle
		draw_circle(at, 14.0 - ring * 3.0, Color(Palette.MOONLIGHT, alpha * (0.12 + ring * 0.1)))
