class_name StartGate
extends Node2D

# The way in (the user's pick, Environment Assets b10f169b; mock start_mock.png): the nightmares come out of a black
# fog in the void, cross a rope bridge on the lane's line and step onto the island at the start.
# - rope_bridge_lane.png (128×64; column 0 east-west, 1 north-south): a 20 px deck centred in the cell. Drawn
#   BRIDGE_CELLS cells out from the start, shifted ±16 px across so it sits on the lane's half row (the route's
#   first half). With the island edge outside the grid, its first plank lands on the lip.
# - nightmare_fog.png (4 frames of 192×192): centred on the cell past the bridge's far end, over the last plank, so
#   the bridge vanishes into it.
# Both shared (dream/). Sits on the start cell's centre: the deck at z -1, the fog (child "Fog") at z 1. Shifting Mist moves it
# (set_start); a re-route whose first half crosses to the other half row moves the bridge.

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const BRIDGE_CELLS := 3  # As EnvironmentObjectGenerator.BRIDGE_CELLS
const FOG_FRAMES := 4

var map: Node  # MapGenerator
var start: Vector2i
var lane := 0.0  # px across the bridge from the start cell's centre (±16, 0 without a route)
var _bridge: Texture2D
var _fog: Texture2D
var _frame := 0
var _frame_time := 0.0
var _fog_layer: Node2D

func _ready() -> void:
	_bridge = load(EnvironmentTiles.shared_path("rope_bridge_lane"))
	_fog = load(EnvironmentTiles.shared_path("nightmare_fog"))
	# Layers (user: "they're coming from underneath the bridge"): the deck at ground level (z -1, over the lip, which comes
	# first among MapGenerator's children), so nightmares crossing it always draw on top whichever side the start is on;
	# the fog above them (z 1), so they come out of it.
	z_index = -1
	_fog_layer = Node2D.new()
	_fog_layer.name = "Fog"
	_fog_layer.z_index = 2  # Relative: 1
	_fog_layer.draw.connect(func() -> void: draw_fog(_fog_layer, start, lane, _frame, _fog, Vector2.ZERO))
	add_child(_fog_layer)
	_follow_route()

# Shifting Mist: the bridge and fog go to the new start.
func set_start(cell: Vector2i) -> void:
	start = cell
	position = MAP_GRID.calculate_map_position(Vector2(cell))
	_follow_route()

func _follow_route() -> void:
	position = MAP_GRID.calculate_map_position(Vector2(start))
	var new_lane := lane_offset(start, _first_point())
	if new_lane != lane:
		lane = new_lane
		queue_redraw()
		if _fog_layer != null:
			_fog_layer.queue_redraw()

func _process(delta: float) -> void:
	_follow_route()  # Every redraw of the route (not all of them emit path_changed); one lookup
	_frame_time = fmod(_frame_time + delta * EnvironmentTiles.FPS, FOG_FRAMES)
	if int(_frame_time) != _frame:
		_frame = int(_frame_time)
		if _fog_layer != null:
			_fog_layer.queue_redraw()  # Only the fog moves

func _draw() -> void:
	draw_bridge(self, start, lane, _bridge, Vector2.ZERO)

# Draws the bridge and fog for start `cell` on `canvas`, with `origin` at the cell's centre in the canvas's space
# (the node itself: zero; the gift screen's ghost: the cell's map position). `tint` is a multiplier on the art.
static func draw_gate(canvas: CanvasItem, cell: Vector2i, lane_px: float, frame: int, bridge: Texture2D, fog: Texture2D,
		origin: Vector2, tint := Color.WHITE) -> void:
	draw_bridge(canvas, cell, lane_px, bridge, origin, tint)
	draw_fog(canvas, cell, lane_px, frame, fog, origin, tint)

# The bridge's planks, BRIDGE_CELLS cells out from the start on the lane.
static func draw_bridge(canvas: CanvasItem, cell: Vector2i, lane_px: float, bridge: Texture2D, origin: Vector2, tint := Color.WHITE) -> void:
	var size := Vector2(MAP_GRID.cell_size)
	var out := Vector2(outward(cell))
	var across := Vector2(absf(out.y), absf(out.x))
	var column := 1 if out.x == 0 else 0  # North-south or east-west planks
	for i in range(1, BRIDGE_CELLS + 1):
		var at := origin + out * size * i + across * lane_px - size / 2.0
		if bridge != null:
			canvas.draw_texture_rect_region(bridge, Rect2(at, size), Rect2(Vector2(column * size.x, 0), size), tint)
		else:  # Placeholder deck
			canvas.draw_rect(Rect2(at + across * (size - Vector2(20, 20)) / 2.0, size - across * (size - Vector2(20, 20))), Color(Palette.ROOT, tint.a))

# The nightmare fog at the bridge's far end, over its last plank.
static func draw_fog(canvas: CanvasItem, cell: Vector2i, lane_px: float, frame: int, fog: Texture2D, origin: Vector2, tint := Color.WHITE) -> void:
	var size := Vector2(MAP_GRID.cell_size)
	var out := Vector2(outward(cell))
	var across := Vector2(absf(out.y), absf(out.x))
	var centre := origin + out * size * (BRIDGE_CELLS + 1) + across * lane_px
	if fog != null:
		var frame_size := Vector2(fog.get_width() / float(FOG_FRAMES), fog.get_height())
		canvas.draw_texture_rect_region(fog, Rect2(centre - frame_size / 2.0, frame_size), Rect2(Vector2(frame * frame_size.x, 0), frame_size), tint)
	else:  # Placeholder fog
		canvas.draw_circle(centre, 80.0, Color(Palette.VOID, 0.9 * tint.a))

# The way in for a nightmare (user 2026-10-07: "mobs just spawning out of nowhere"): from the fog's centre straight
# along the bridge's lane to the route's first point, in MapGenerator's space (pixels). Three points on one straight
# line: the fog, where the bridge lands on the island's edge, the route's first point. The spawner walks it before the
# route. It ends ON the route's first point, a half's centre (user 2026-10-12: ending on the start cell's centre, 16 px
# further in or out, made nightmares run to the start and then back a bit). `to`: where this nightmare's route begins
# (pixels; a flyer's differs from the drawn route's); left out, the drawn route's first point.
func walk_in(to := Vector2.INF) -> PackedVector2Array:
	if to == Vector2.INF:
		to = MAP_GRID.calculate_map_position(_first_point())
	return walk_in_to(start, to)

# Where every route from the start begins (route point, full-cell units): the map's fixed start half (the start cell's
# outer half on the bridge's lane, PathGenerator.start_half), so the bridge never changes lane when the route does.
# Without one (an older map object): the drawn route's first point, else the start cell.
func _first_point() -> Vector2:
	if map == null:
		return Vector2(start)
	var half: Vector2i = map.path_layer.start_half
	if half.x >= 0 and Vector2i((Vector2(half) / 2.0).floor()) == start:
		return FindPath.node_to_point(half)
	var route: PackedVector2Array = map.path_layer.current_path
	return route[0] if not route.is_empty() else Vector2(start)

# The route's fixed start half for start `cell` (half-cell coordinates): the outer half (touching the island's edge,
# where the bridge lands), on the side of the cell nearer `toward` (the Heartwood's cell). Only the two cells decide
# it, so a save or Shifting Mist's replay rebuilds the same one.
static func start_half_for(cell: Vector2i, toward: Vector2) -> Vector2i:
	var out := outward(cell)
	var half := cell * 2
	if out.x != 0:
		half += Vector2i(1 if out.x > 0 else 0, 1 if toward.y > cell.y else 0)
	else:
		half += Vector2i(1 if toward.x > cell.x else 0, 1 if out.y > 0 else 0)
	return half

# The way in to `to` (pixels) for start `cell`: the fog's cell on `to`'s lane, `to` projected onto the island's edge, `to`.
static func walk_in_to(cell: Vector2i, to: Vector2) -> PackedVector2Array:
	var size := Vector2(MAP_GRID.cell_size)
	var out := Vector2(outward(cell))
	var centre := MAP_GRID.calculate_map_position(Vector2(cell))
	var inside := (to - centre).dot(out)  # How far `to` sits toward the edge from the cell's centre (negative: further in)
	var landing := to + out * (size.x / 2.0 - inside)
	return PackedVector2Array([landing + out * size * (BRIDGE_CELLS + 0.5), landing, to])

# The way in for a start whose route isn't known: it ends on the start cell's centre, `lane_px` across.
static func walk_in_for(cell: Vector2i, lane_px: float) -> PackedVector2Array:
	var out := Vector2(outward(cell))
	return walk_in_to(cell, MAP_GRID.calculate_map_position(Vector2(cell)) + Vector2(absf(out.y), absf(out.x)) * lane_px)

# The lane's offset across the bridge: the route's first half against the start cell's centre (±16 px).
static func lane_offset(cell: Vector2i, first_point: Vector2) -> float:
	var out := Vector2(outward(cell))
	var across := Vector2(absf(out.y), absf(out.x))
	var offset := (MAP_GRID.calculate_map_position(first_point) - MAP_GRID.calculate_map_position(Vector2(cell))).dot(across)
	var limit := MAP_GRID.cell_size.x / 4.0
	return clampf(offset, -limit, limit)

# The direction off the island from an edge cell.
static func outward(cell: Vector2i) -> Vector2i:
	var last := Vector2i(MAP_GRID.size) - Vector2i.ONE
	if cell.y <= 0:
		return Vector2i.UP
	if cell.y >= last.y:
		return Vector2i.DOWN
	return Vector2i.LEFT if cell.x <= 0 else Vector2i.RIGHT
