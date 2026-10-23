extends TileMapLayer

# Map landmarks (environment_assets.md "Landmarks", user 2026-10-23): about 1 map in 3 gets one, rolled from the map
# seed (a saved run rebuilds it), never on the demo's first map. It sits in the open bowl, at least MIN_GAP cells from
# the start and the Heartwood, off the glade and the opening route's first ROUTE_HEAD cells. It never moves, blocks or
# re-routes anything: the player decides whether to build on it or route through it.
# - Old Waystone (waystone.png): a one-cell site; Tower Code pays its bonus to the Warden planted on it.
# - Dew Pool (dew_pool.png): 2 cells of walkable shallow water, never buildable; Enemy Code slows the walkers on it.
# Drawn as ground (z -1, over the path, under everything standing); hover (or a tap) shows a short info line.
# Made by MapGenerator (map.landmark); no class_name (MapGenerator preloads it).

enum Kind { NONE, WAYSTONE, DEW_POOL }

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const SHARE := 1.0 / 3.0  # Maps that get a landmark
const MIN_GAP := 3  # Cells (Chebyshev) from the start and the Heartwood
const ROUTE_HEAD := 4  # The opening route's first whole cells stay clear
const NAMES := {Kind.WAYSTONE: "Old Waystone", Kind.DEW_POOL: "Dew Pool"}
const INFO := {
	Kind.WAYSTONE: "Old Waystone: a Warden planted here earns +1 Dew for each nightmare it dispels.",
	Kind.DEW_POOL: "Dew Pool: nightmares wading through are slowed 25%. Nothing can be built here.",
}
const TAP_SECONDS := 3.0  # A tap shows the info line this long (touch: no hover)

static var force_kind := -1  # Tests: -1 roll, else a Kind (NONE = no landmark)

var map: Node  # MapGenerator
var kind := Kind.NONE
var cells: Array[Vector2] = []  # Its whole cells (the Waystone 1, the Dew Pool 2)
var _label: Node2D
var _shown_at := Vector2.INF  # Where the info line is drawn (INF: hidden)
var _tap_left := 0.0

# Rolls and places the landmark for `map` (after the route is drawn). `skip_roll`: never one (the demo's first map).
func build(skip_roll: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map.map_seed, "landmark"])  # Its own stream: the obstacles and details never move with it
	var rolled := Kind.NONE
	if rng.randf() < SHARE:
		rolled = Kind.WAYSTONE if rng.randi_range(0, 1) == 0 else Kind.DEW_POOL
	if force_kind >= 0:
		rolled = force_kind
	elif skip_roll:
		rolled = Kind.NONE
	if rolled == Kind.NONE:
		return
	var spots := _spots(rolled)
	if spots.is_empty():
		return
	cells.assign(spots[rng.randi_range(0, spots.size() - 1)])
	kind = rolled
	# One tile on the first cell: the Waystone's 64x64, or the pool's two-cell art (dew_pool.png across W-E,
	# dew_pool_v.png down N-S) drawn over both cells.
	var source := EnvironmentTiles.WAYSTONE
	if kind == Kind.DEW_POOL:
		source = EnvironmentTiles.DEW_POOL if cells[1].y == cells[0].y else EnvironmentTiles.DEW_POOL_V
	set_cell(Vector2i(cells[0]), source, Vector2i(0, 0))

# Every place the landmark fits: [cells] lists (one cell, or two side by side for the pool).
func _spots(of: Kind) -> Array:
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
			if not _open(cell, head):
				continue
			if of == Kind.WAYSTONE:
				spots.append([cell])
				continue
			for step in [Vector2.RIGHT, Vector2.DOWN]:
				if _open(cell + step, head):
					spots.append([cell, cell + step])
	return spots

func _open(cell: Vector2, head: Dictionary) -> bool:
	var objects = map.environment_object_layer
	if not objects.in_bowl(cell) or head.has(cell) or map.obstacles.has(cell):
		return false
	if objects.pond_cells.has(cell) or objects.rubble_cells.has(cell) or map.get_glade_cells().has(cell):
		return false
	for at: Vector2 in [map.startPath, map.endPath]:
		if maxf(absf(cell.x - at.x), absf(cell.y - at.y)) < MIN_GAP:
			return false
	for h in FindPath.halves_of_cell(cell):
		if map.path_layer.is_half_blocked(h):
			return false
	return true

func has_cell(cell: Vector2) -> bool:
	return cells.has(cell)

# The Dew Pool's cells are walkable water: never built on.
func blocks_building(cell: Vector2) -> bool:
	return kind == Kind.DEW_POOL and cells.has(cell)

func info() -> String:
	return INFO.get(kind, "")

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
	if kind == Kind.NONE:
		return
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		if cells.has(_cell_at(get_global_mouse_position() if event is InputEventMouseButton else _to_world(event.position))):
			_tap_left = TAP_SECONDS

func _to_world(screen: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen

func _cell_at(world: Vector2) -> Vector2:
	return MAP_GRID.calculate_grid_coordinates(to_local(world))

func _process(delta: float) -> void:
	if kind == Kind.NONE:
		set_process(false)
		return
	_tap_left = maxf(_tap_left - delta / maxf(Engine.time_scale, 0.01), 0.0)
	var hovered := cells.has(_cell_at(get_global_mouse_position()))
	var at := Vector2.INF
	if hovered or _tap_left > 0.0:
		var centre := Vector2.ZERO
		for cell in cells:
			centre += MAP_GRID.calculate_map_position(cell)
		at = centre / cells.size()
	if at != _shown_at:
		_shown_at = at
		_label.queue_redraw()

func _draw_info() -> void:
	if _shown_at == Vector2.INF:
		return
	WorldLabel.draw_tag(_label, _shown_at.x, _shown_at.y - MAP_GRID.cell_size.y * 0.75, info())
