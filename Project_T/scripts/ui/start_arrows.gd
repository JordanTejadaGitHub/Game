extends Node2D
class_name StartArrows

# Route arrows at the start of a run (screens_ui.md "In the world"; user 2026-10-01: "the arrows are for the beginning
# of every run so we know where to place towers … put them for the whole path but only display at the start of a
# run", then "can you animate the arrows, also can't see the arrows and make them look better"): chunky pixel-art
# chevrons (a 16×16 sprite drawn ×2, Heartwood 32: dark outline, warm gold fill, a lighter top edge) about one every
# SPACING_CELLS cells along the route, sliding continuously toward the Heartwood at MARCH_SPEED, each fading in at the
# start and out at the Heartwood, and turning smoothly with the route at corners. Under reduced motion they stand still,
# evenly spaced. Shown from the run's start (the opening rest, before drift 1; a resumed run still before drift 1 too),
# following re-routes live as Wardens are planted or obstacles cleared; when the first drift starts they fade out and
# never return. Made by the HUD; drawn over the path tiles, under the build ghost's route preview (TowerPlacer, z 0),
# the Wardens and the nightmares.

const CELL := 64.0
const SPACING_CELLS := 3.0  # About one chevron per this many route cells (evened out over the route's length)
const SPRITE := 16  # The chevron sprite's side, px
const SCALE := 2.0  # Drawn ×2: 32 px, half a cell, chunky pixels
const SIZE := SPRITE * SCALE / 2.0  # Half the drawn chevron's width
const TURN_SAMPLE := 0.45 * CELL  # Heading = the route's direction this far either side: a smooth turn at corners
const MARCH_SPEED := 1.0 * CELL  # px per second along the route
const EDGE_FADE := 0.6 * CELL  # Fade in after the start / out before the Heartwood over this distance
const ALPHA := 0.85
const FADE_TIME := 0.8  # Game seconds, once the first drift starts
const OUTLINE := Palette.DREAD
const FILL := Palette.GOLD
const TOP := Palette.GLOW  # The lighter top edge
const SHADE := Palette.OAK  # The lower edge

var _map: Node
var _director: Node
var _cells: Array[Vector2] = []  # World centres of the whole route, start to Heartwood
var _span := 0.0  # Route length to the last cell before the Heartwood
var _spacing := 0.0
var _age := 0.0
var _fade := -1.0  # >= 0: fading out (the first drift started)
var _done := false  # Faded out: never shown again this run
var _still := false
var _sprite: ImageTexture = null  # Built once per instance (never a static resource: exit crash)

func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite = ImageTexture.create_from_image(make_chevron())
	var main := get_parent()
	_map = main.get_node_or_null("%MapGenerator")
	_director = main.get_node_or_null("%DriftDirector")
	if _director != null:
		_director.drift_started.connect(func(_number: int) -> void: _on_first_drift())
	if _map != null and _map.has_signal("path_changed"):
		_map.path_changed.connect(_read_route)
	_still = bool(Fx.setting("reduced_motion", false))
	_read_route.call_deferred()  # After the map is built

# The 16×16 chevron, pointing right: a chunky ">" (arms 5 px thick), a 1-px dark outline all round, a lighter top
# edge and a darker lower edge on the fill.
static func make_chevron() -> Image:
	var image := Image.create(SPRITE, SPRITE, false, Image.FORMAT_RGBA8)
	var fill := {}
	for y in range(2, SPRITE - 2):
		var offset := absf(y - (SPRITE - 1) / 2.0)  # 0.5 at the middle rows, 5.5 at the ends
		var start := roundi(2.0 + (5.5 - offset))
		for x in range(start, mini(start + 5, SPRITE - 1)):
			fill[Vector2i(x, y)] = true
	for p in fill:
		var top := not fill.has(p + Vector2i.UP)
		var bottom := not fill.has(p + Vector2i.DOWN)
		image.set_pixelv(p, TOP if top else (SHADE if bottom else FILL))
	for y in SPRITE:
		for x in SPRITE:
			var p := Vector2i(x, y)
			if fill.has(p):
				continue
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
				if fill.has(p + d):
					image.set_pixelv(p, OUTLINE)
					break
	return image

# Shown while the run hasn't started its first drift (a resumed run before drift 1 counts).
func is_showing() -> bool:
	return not _done and _cells.size() >= 3 and (_fade >= 0.0 or _director == null or _director.drifts_started == 0)

# The chevrons at rest (reduced motion, and the march's starting layout): even spacing along the route, one on the
# start and one on the last cell before the Heartwood.
func mark_count() -> int:
	return 0 if _cells.size() < 3 else maxi(1, roundi(_span / (SPACING_CELLS * CELL))) + 1

func mark_position(i: int) -> Vector2:
	return _point_at(_spacing * i)

func _on_first_drift() -> void:
	if not _done and _fade < 0.0:
		_fade = 0.0

func _read_route() -> void:
	_cells.clear()
	if _map == null:
		return
	for cell in _map.get_path_from(_map.startPath):
		_cells.append(_map.MAP_GRID.calculate_map_position(cell))
	_span = _length_to(_cells.size() - 2) if _cells.size() >= 3 else 0.0
	_spacing = _span / maxf(mark_count() - 1, 1.0)
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

func _heading_at(distance: float) -> Vector2:
	return (_point_at(distance + TURN_SAMPLE) - _point_at(maxf(distance - TURN_SAMPLE, 0.0))).normalized()

func _process(delta: float) -> void:
	if _done:
		return
	_age += delta
	if _fade >= 0.0:
		_fade += delta
		if _fade >= FADE_TIME:
			_done = true
			_cells.clear()
	if not _still or _fade >= 0.0:
		queue_redraw()

func _draw() -> void:
	if not is_showing():
		return
	var fade := 1.0 - clampf(_fade / FADE_TIME, 0.0, 1.0) if _fade >= 0.0 else 1.0
	var count := mark_count()
	if _still:
		for i in count:
			_draw_chevron(mark_position(i), _heading_at(_spacing * i), ALPHA * fade)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	# The march: the same layout sliding toward the Heartwood; one spacing of travel loops it seamlessly
	var shift := fposmod(_age * MARCH_SPEED, _spacing) if _spacing > 0.0 else 0.0
	for i in count + 1:
		var d := _spacing * i + shift - _spacing
		if d < 0.0 or d > _span:
			continue
		var edge := clampf(minf(d, _span - d) / EDGE_FADE, 0.0, 1.0)  # In at the start, out at the Heartwood
		_draw_chevron(_point_at(d), _heading_at(d), ALPHA * fade * edge)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_chevron(centre: Vector2, dir: Vector2, alpha: float) -> void:
	if alpha <= 0.0:
		return
	draw_set_transform(centre.round(), dir.angle(), Vector2(SCALE, SCALE))
	draw_texture(_sprite, -Vector2(SPRITE, SPRITE) / 2.0, Color(1, 1, 1, alpha))  # multiplier: the fade
