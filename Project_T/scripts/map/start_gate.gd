class_name StartGate
extends Node2D

# The way in (the user's pick, Environment Assets b10f169b; mock start_mock.png): the nightmares come out of a black
# fog in the void, cross a rope bridge on the lane's line and step onto the island at the start.
# - rope_bridge_lane.png (128×64; column 0 east-west, 1 north-south): a 20 px deck centred in the cell. Drawn
#   BRIDGE_CELLS cells out from the start, shifted ±16 px across so it sits on the lane's half row (the route's
#   first half). With the island edge outside the grid, its first plank lands on the lip.
# - nightmare_fog.png (4 frames of 192×192): centred on the cell past the bridge's far end, over the last plank, so
#   the bridge vanishes into it.
# Both shared (dream/). Sits on the start cell's centre (MapGenerator is the y-sort root). Shifting Mist moves it
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

func _ready() -> void:
	_bridge = load(EnvironmentTiles.shared_path("rope_bridge_lane"))
	_fog = load(EnvironmentTiles.shared_path("nightmare_fog"))
	_follow_route()

# Shifting Mist: the bridge and fog go to the new start.
func set_start(cell: Vector2i) -> void:
	start = cell
	position = MAP_GRID.calculate_map_position(Vector2(cell))
	_follow_route()

func _follow_route() -> void:
	position = MAP_GRID.calculate_map_position(Vector2(start))
	var route: PackedVector2Array = map.path_layer.current_path if map != null else PackedVector2Array()
	var new_lane := lane_offset(start, route[0] if not route.is_empty() else Vector2(start))
	if new_lane != lane:
		lane = new_lane
		queue_redraw()

func _process(delta: float) -> void:
	_follow_route()  # Every redraw of the route (not all of them emit path_changed); one lookup
	_frame_time = fmod(_frame_time + delta * EnvironmentTiles.FPS, FOG_FRAMES)
	if int(_frame_time) != _frame:
		_frame = int(_frame_time)
		queue_redraw()  # Only the fog moves

func _draw() -> void:
	draw_gate(self, start, lane, _frame, _bridge, _fog, Vector2.ZERO)

# Draws the bridge and fog for start `cell` on `canvas`, with `origin` at the cell's centre in the canvas's space
# (the node itself: zero; the gift screen's ghost: the cell's map position). `tint` is a multiplier on the art.
static func draw_gate(canvas: CanvasItem, cell: Vector2i, lane_px: float, frame: int, bridge: Texture2D, fog: Texture2D,
		origin: Vector2, tint := Color.WHITE) -> void:
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
	var centre := origin + out * size * (BRIDGE_CELLS + 1) + across * lane_px
	if fog != null:
		var frame_size := Vector2(fog.get_width() / float(FOG_FRAMES), fog.get_height())
		canvas.draw_texture_rect_region(fog, Rect2(centre - frame_size / 2.0, frame_size), Rect2(Vector2(frame * frame_size.x, 0), frame_size), tint)
	else:  # Placeholder fog
		canvas.draw_circle(centre, 80.0, Color(Palette.VOID, 0.9 * tint.a))

# The way in for a nightmare (user 2026-10-07: "mobs just spawning out of nowhere"): from the fog's centre straight
# along the bridge's lane to the start cell's lane point (its route half), in MapGenerator's space (pixels). Three
# points: the fog, where the bridge lands on the island's edge, the start. The spawner walks it before the route.
func walk_in() -> PackedVector2Array:
	return walk_in_for(start, lane)

static func walk_in_for(cell: Vector2i, lane_px: float) -> PackedVector2Array:
	var size := Vector2(MAP_GRID.cell_size)
	var out := Vector2(outward(cell))
	var across := Vector2(absf(out.y), absf(out.x)) * lane_px
	var centre := MAP_GRID.calculate_map_position(Vector2(cell))
	return PackedVector2Array([centre + out * size * (BRIDGE_CELLS + 1) + across, centre + out * size / 2.0 + across, centre + across])

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
