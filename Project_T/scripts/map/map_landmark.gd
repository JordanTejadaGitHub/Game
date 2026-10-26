extends TileMapLayer

# Map landmarks (environment_assets.md "Landmarks"): every map has an Old Waystone (user 2026-10-25: "there should be a
# waystone, at least 1 in every map generation", the demo's first map too), and about 1 map in POOL_SHARE also a Dew
# Pool (never on the demo's first map). Both rolled from the map seed (a saved run rebuilds them), in the open bowl, at
# least MIN_GAP cells from the start and the Heartwood, off the glade and the opening route's first ROUTE_HEAD cells, and
# apart from each other. They never move, block or re-route anything: the player decides whether to build on the stone
# or route through the pool.
# - Old Waystone (waystone.png): a one-cell site; Tower Code pays its bonus to the Warden planted on it (tower/waystone.gd
#   reads MapGenerator.landmark_kind / landmark_cell).
# - Dew Pool (dew_pool.png across two cells, dew_pool_v.png down two): walkable shallow water, never buildable; Enemy
#   Code slows the walkers on it (MapGenerator.dew_pool_cells).
# Drawn as ground (z -1, over the path, under everything standing); hover (or a tap) shows a short info line.
# Made by MapGenerator (map.landmark); no class_name (MapGenerator preloads it).

enum Kind { NONE, WAYSTONE, DEW_POOL }

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const POOL_SHARE := 1.0 / 3.0  # Maps that also get a Dew Pool
const MIN_GAP := 3  # Cells (Chebyshev) from the start and the Heartwood
const APART := 2  # Cells (Chebyshev) between the Waystone and the pool
const ROUTE_HEAD := 4  # The opening route's first whole cells stay clear
const NAMES := {Kind.WAYSTONE: "Old Waystone", Kind.DEW_POOL: "Dew Pool"}
const INFO := {
	Kind.WAYSTONE: "Old Waystone: a Warden planted here earns +1 Dew for each nightmare it dispels.",
	Kind.DEW_POOL: "Dew Pool: nightmares wading through are slowed 25%. Nothing can be built here.",
}
const TAP_SECONDS := 3.0  # A tap shows the info line this long (touch: no hover)

static var force_pool := -1  # Tests: -1 roll, 0 no pool, 1 a pool

var map: Node  # MapGenerator
var waystone_cell := Vector2(-1, -1)  # The Old Waystone's cell ((-1, -1): no room on this map)
var pool_cells: Array[Vector2] = []  # The Dew Pool's two cells (west / north first), empty without one
var cells: Array[Vector2] = []  # Every landmark cell
var _label: Node2D
var _shown := Kind.NONE  # Whose info line is showing
var _shown_at := Vector2.INF  # Where it's drawn (INF: hidden)
var _tap_kind := Kind.NONE
var _tap_left := 0.0

# Places the landmarks for `map` (after the route is drawn). `no_pool`: no Dew Pool (the demo's first map).
func build(no_pool: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map.map_seed, "landmark"])  # Its own stream: the obstacles and details never move with it
	var pool := rng.randf() < POOL_SHARE
	if force_pool >= 0:
		pool = force_pool == 1
	elif no_pool:
		pool = false
	var none: Array[Vector2] = []
	var stones := _spots(Kind.WAYSTONE, none)
	if not stones.is_empty():
		waystone_cell = stones[rng.randi_range(0, stones.size() - 1)][0]
		cells.append(waystone_cell)
		set_cell(Vector2i(waystone_cell), EnvironmentTiles.WAYSTONE, Vector2i(0, 0))
	if pool:
		var spots := _spots(Kind.DEW_POOL, cells)
		if not spots.is_empty():
			pool_cells.assign(spots[rng.randi_range(0, spots.size() - 1)])
			cells.append_array(pool_cells)
			# One tile on the first cell: dew_pool.png across W-E or dew_pool_v.png down N-S, drawn over both cells.
			var source := EnvironmentTiles.DEW_POOL if pool_cells[1].y == pool_cells[0].y else EnvironmentTiles.DEW_POOL_V
			set_cell(Vector2i(pool_cells[0]), source, Vector2i(0, 0))

# Every place a landmark of kind `of` fits, APART from `taken`: [cells] lists (one cell, or two side by side for the pool).
func _spots(of: Kind, taken: Array[Vector2]) -> Array:
	var head := {}
	var whole: Array[Vector2] = []
	for point in map.path_layer.current_path:
		var cell := (Vector2(FindPath.point_to_node(point)) / 2.0).floor()
		if whole.is_empty() or whole[whole.size() - 1] != cell:
			whole.append(cell)
		if whole.size() > ROUTE_HEAD:
			break
	for cell in whole.slice(0, ROUTE_HEAD):
		head[cell] = true
	var spots := []
	for y in int(MAP_GRID.size.y):
		for x in int(MAP_GRID.size.x):
			var cell := Vector2(x, y)
			if not _open(cell, head, taken):
				continue
			if of == Kind.WAYSTONE:
				spots.append([cell])
				continue
			for step in [Vector2.RIGHT, Vector2.DOWN]:
				if _open(cell + step, head, taken):
					spots.append([cell, cell + step])
	return spots

func _open(cell: Vector2, head: Dictionary, taken: Array[Vector2]) -> bool:
	var objects = map.environment_object_layer
	if not objects.in_bowl(cell) or head.has(cell) or map.obstacles.has(cell):
		return false
	if objects.pond_cells.has(cell) or objects.rubble_cells.has(cell) or map.get_glade_cells().has(cell):
		return false
	for at: Vector2 in [map.startPath, map.endPath]:
		if maxf(absf(cell.x - at.x), absf(cell.y - at.y)) < MIN_GAP:
			return false
	for at in taken:
		if maxf(absf(cell.x - at.x), absf(cell.y - at.y)) < APART:
			return false
	for h in FindPath.halves_of_cell(cell):
		if map.path_layer.is_half_blocked(h):
			return false
	return true

func has_cell(cell: Vector2) -> bool:
	return cells.has(cell)

func kind_at(cell: Vector2) -> Kind:
	if cell == waystone_cell:
		return Kind.WAYSTONE
	return Kind.DEW_POOL if pool_cells.has(cell) else Kind.NONE

# The Dew Pool's cells are walkable water: never built on.
func blocks_building(cell: Vector2) -> bool:
	return pool_cells.has(cell)

func info(of: Kind) -> String:
	return INFO.get(of, "")

# --- The info line: hover on PC, a tap on touch ---------------------------------------------------------------------

func _ready() -> void:
	z_index = -1  # Ground: over the path (added after it), under everything standing
	process_mode = Node.PROCESS_MODE_ALWAYS  # Readable while paused
	_label = Node2D.new()
	_label.name = "LandmarkInfo"
	_label.z_as_relative = false
	_label.z_index = 20  # Over the trees, Wardens and ambience
	_label.draw.connect(_draw_info)
	add_child(_label)

func _unhandled_input(event: InputEvent) -> void:
	if cells.is_empty():
		return
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		var tapped := kind_at(_cell_at(get_global_mouse_position() if event is InputEventMouseButton else _to_world(event.position)))
		if tapped != Kind.NONE:
			_tap_kind = tapped
			_tap_left = TAP_SECONDS

func _to_world(screen: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen

func _cell_at(world: Vector2) -> Vector2:
	return MAP_GRID.calculate_grid_coordinates(to_local(world))

func _process(delta: float) -> void:
	if cells.is_empty():
		set_process(false)
		return
	_tap_left = maxf(_tap_left - delta / maxf(Engine.time_scale, 0.01), 0.0)
	var showing := kind_at(_cell_at(get_global_mouse_position()))
	if showing == Kind.NONE and _tap_left > 0.0:
		showing = _tap_kind
	var at := Vector2.INF
	if showing == Kind.WAYSTONE:
		at = MAP_GRID.calculate_map_position(waystone_cell)
	elif showing == Kind.DEW_POOL:
		at = (MAP_GRID.calculate_map_position(pool_cells[0]) + MAP_GRID.calculate_map_position(pool_cells[1])) / 2.0
	if at != _shown_at or showing != _shown:
		_shown_at = at
		_shown = showing
		_label.queue_redraw()

func _draw_info() -> void:
	if _shown_at == Vector2.INF:
		return
	WorldLabel.draw_tag(_label, _shown_at.x, _shown_at.y - MAP_GRID.cell_size.y * 0.75, info(_shown))
