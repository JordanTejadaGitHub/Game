extends Node2D

# Emitted after the enemy path changes (e.g. a tower was built). Enemies re-route when they hear it.
signal path_changed
# Emitted when the player clears an obstacle (before path_changed).
signal obstacle_cleared(cell: Vector2, data: ObstacleData)

@onready var ground_layer: GroundGenerator = %GroundTileMapLayer
@onready var path_layer: PathGenerator = %PathTileMapLayer
@onready var environment_object_layer: EnvironmentObjectGenerator = %EnvironmentObjectTileMapLayer
const MAP_GRID = preload("res://resource/map/map_grid.tres")
# How much more a route through an obstacle costs than open ground when carving a guaranteed route.
# High, so carving takes long detours before clearing anything, and prefers stray obstacles over
# breaking a ridge (which would undo the zig-zag the ridges create).
const CARVE_OBSTACLE_WEIGHT := 100.0
const CARVE_RIDGE_WEIGHT := 1000.0


# Set per seed by the map's layout (MapLayout: corner, side or inlet), before anything reads them.
var startPath: Vector2 = Vector2(1, 0)
var endPath: Vector2 = Vector2(MAP_GRID.size.x - 2, MAP_GRID.size.y - 1)
var layout: MapLayout
# Tests force a layout (MapLayout.Kind), the short side (1) or a feature (MapLayout.Feature); -1 = roll.
@export var force_layout := -1
@export var force_short := -1
@export var force_feature := -1
# Starting-route cap, generation only (nothing caps the route in play): environment_assets.md "Map layouts".
@export var max_route_length := 57
# And its floor (Room to maze): the start→Heartwood Manhattan distance + 4, set per map in _ready(). Nothing
# lengthens a short route any more (that filled the open bowl); the spurs give it its bend.
var min_route_length := 0
@export var map_seed: int = 0  # 0 = new random map every run; anything else reproduces a map
var unwalkable_cells: PackedVector2Array
# Clearable trees/rocks still on the map: {cell (Vector2): ObstacleData}.
var obstacles: Dictionary = {}
var tile_set: TileSet  # Shared by the ground, path and object layers (EnvironmentTiles)
var heartwood: Heartwood  # The goal tree on the end cell
var _pond_corners: Array[Sprite2D] = []  # pond_inner overlays on a non-rectangular pond's inside corners
var dream_void: DreamVoid  # The starry void around the island
var omen_mist: OmenMist  # Low gold-violet mist while an Omen twists the block
var build_hatch: BuildHatch  # In build mode: a cold hatch on every unbuildable cell
var lighting: EnvironmentLighting  # Cold edges, warm Warden lights
var ambience: EnvironmentAmbience  # Edge fog and the act's particles
var ground_patches: GroundPatches  # Ground variation (environment_assets.md "Ground variation")
var tree_fade: TallObstacleFade  # Withered Trees fade their overhang over what's behind them
var gifts: MapGifts  # Heartwood's Gifts: terrain the act-break gifts leave (map_gifts.gd)
var _route_hold := 0  # hold_route() depth
var _route_dirty := false  # A block changed while held: redraw at release_route()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# A random map gets a concrete seed too, so a saved run can rebuild exactly this map.
	if map_seed == 0:
		map_seed = randi_range(1, 2147483646)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	layout = MapLayout.roll(rng, Vector2i(MAP_GRID.size), force_layout, force_short, force_feature)
	startPath = Vector2(layout.start)
	endPath = Vector2(layout.end)

	tile_set = EnvironmentTiles.create_tile_set()
	for layer: TileMapLayer in [ground_layer, path_layer, environment_object_layer]:
		layer.tile_set = tile_set
	# One y-sort for everything that stands on a cell (trees, rocks, Wardens, nightmares, the Heartwood):
	# 64×96 sprites overhang the cell above, so whatever is lower on screen draws in front. The sort key
	# is the cell centre; tall sprites put their bottom 64 px on their cell. The ground and path stay under
	# it all (z -1); the void, lighting, ambience and effects keep their own z_index.
	y_sort_enabled = true
	for sorted: Node2D in [environment_object_layer, get_node("%TowerContainer"), get_node("%EnemyContainer")]:
		sorted.y_sort_enabled = true
	ground_layer.z_index = -1
	ground_layer.light_mask |= Heartwood.GROUND_LIGHT_MASK  # The Heartwood's light lifts the grass only, never the path
	path_layer.z_index = -1
	ground_layer.initialize()
	# The start sits in the rim ring: the rim goes under its path (path_rim.png is transparent outside the
	# path), on the ground layer since the object layer draws over the path. The Heartwood is inland.
	ground_layer.set_cell(Vector2i(startPath), EnvironmentTiles.ISLAND_EDGE,
		Vector2i(EnvironmentTiles.rim_mask(Vector2i(startPath), Vector2i(MAP_GRID.size)), 0))
	unwalkable_cells = environment_object_layer.initialize(startPath, endPath)
	path_layer.initialize(get_array_board(), startPath, endPath)

	# Obstacles can sit on any open cell, so the route winds around them. Keep start/end clear.
	var skip := unwalkable_cells.duplicate()
	skip.append(startPath)
	skip.append(endPath)
	for cell in get_glade_cells():  # The Heartwood's glade: never an obstacle, ridge or feature
		if not skip.has(cell):
			skip.append(cell)
	environment_object_layer.layout = layout
	obstacles = environment_object_layer.generate_obstacles(rng, skip)
	for cell in obstacles:
		path_layer.set_cell_blocked(cell, true)
	for cell in environment_object_layer.pond_cells:  # Water: never walkable, buildable or cleared
		path_layer.set_cell_blocked(cell, true)
	_carve_route_if_blocked()
	_trim_route_if_long()  # No route extension any more: it refilled the open bowl (Room to maze)
	if obstacles.size() < environment_object_layer.target_obstacles_min:  # Carving took some: lone band ones back, off the route
		var on_route := {}
		for point in path_layer.find_path_from(startPath):
			on_route[(Vector2(FindPath.point_to_node(point)) / 2.0).floor()] = true
		for cell in environment_object_layer.top_up(rng, skip, on_route, obstacles):
			path_layer.set_cell_blocked(cell, true)
	min_route_length = int(absf(endPath.x - startPath.x) + absf(endPath.y - startPath.y)) + 4
	path_layer.prefer_route(_straightest_route())  # Fewest turns among the shortest routes

	path_layer.draw()
	ground_patches = GroundPatches.new()  # Ground variation: big soft patches over the grass, under the path
	ground_patches.build(self)
	ground_layer.add_child(ground_patches)
	var no_details := unwalkable_cells + path_layer.current_path + PackedVector2Array(obstacles.keys())
	no_details.append_array(PackedVector2Array(environment_object_layer.pond_cells))
	environment_object_layer.generate_details(rng, no_details, ground_patches.kind_at)
	_draw_pond_corners()

	heartwood = Heartwood.new()
	heartwood.position = MAP_GRID.calculate_map_position(endPath)
	heartwood.run_state = get_node_or_null("%RunState")
	heartwood.tower_container = get_node_or_null("%TowerContainer")
	heartwood.enemy_container = get_node_or_null("%EnemyContainer")
	add_child(heartwood)

	dream_void = DreamVoid.new()
	dream_void.bridge_end = environment_object_layer.bridge_end
	dream_void.map_seed = map_seed
	add_child(dream_void)
	move_child(dream_void, 0)  # Behind the tile layers

	omen_mist = OmenMist.new()
	omen_mist.map_generator = self
	add_child(omen_mist)  # After the ground and path: same z, drawn over them, under everything else

	build_hatch = BuildHatch.new()
	build_hatch.map_generator = self
	build_hatch.tower_container = get_node_or_null("%TowerContainer")
	build_hatch.tower_placer = get_node_or_null("%TowerPlacer")
	add_child(build_hatch)

	lighting = EnvironmentLighting.new()
	lighting.tower_container = get_node_or_null("%TowerContainer")
	add_child(lighting)
	ambience = EnvironmentAmbience.new()
	ambience.heartwood_position = heartwood.position
	add_child(ambience)
	tree_fade = TallObstacleFade.new()
	tree_fade.map = self
	tree_fade.tower_container = get_node_or_null("%TowerContainer")
	tree_fade.enemy_container = get_node_or_null("%EnemyContainer")
	add_child(tree_fade)
	gifts = MapGifts.new()
	gifts.name = "Gifts"
	gifts.map = self
	add_child(gifts)
	move_child(gifts, path_layer.get_index() + 1)  # Ground overlays just over the path

# A pond that isn't a rectangle gets pond_inner.png's inside corners over its tiles: one small sprite
# per corner, sorted with the pond cell and drawn just after it (a cell can need two).
func _draw_pond_corners() -> void:
	var sheet := (tile_set.get_source(EnvironmentTiles.POND_INNER) as TileSetAtlasSource).texture
	for corner: Array in environment_object_layer.pond_corners:
		var sprite := Sprite2D.new()
		sprite.name = "PondCorner"
		sprite.texture = sheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2(corner[1] * EnvironmentTiles.SIZE.x, 0), Vector2(EnvironmentTiles.SIZE))
		sprite.position = MAP_GRID.calculate_map_position(corner[0])
		add_child(sprite)
		_pond_corners.append(sprite)

# The 8 cells around the Heartwood (environment_assets.md "Inland Heartwood"): kept clear of obstacles,
# ridges and the feature, so the player can wall it in on some sides. Wardens may be built there.
func get_glade_cells() -> PackedVector2Array:
	var cells := PackedVector2Array()
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx != 0 or dy != 0:
				cells.append(endPath + Vector2(dx, dy))
	return cells

# Swaps the environment art to act `act`'s season (every sheet, and the Heartwood's).
func set_act(act: int) -> void:
	EnvironmentTiles.set_act(tile_set, act)
	for corner: Sprite2D in _pond_corners:  # The inside corners follow the season's pond sheet
		corner.texture = (tile_set.get_source(EnvironmentTiles.POND_INNER) as TileSetAtlasSource).texture
	heartwood.set_act(act)
	path_layer.set_act(act)  # The dual-grid path sheet
	ground_patches.set_act(act)
	gifts.set_act(act)
	ambience.act = act

# If obstacles cut the start off from the end, clears the fewest-obstacle route between them.
# Ridges are left intact (they create the zig-zag) unless there's no other way through.
func _carve_route_if_blocked() -> void:
	if not path_layer.find_path_from(startPath).is_empty():
		return
	# Keep ridges and the feature whole; else break the feature (it's scenery); ridges only as a last resort.
	var route := _find_carve_route(0)
	if route.is_empty():
		route = _find_carve_route(1)
	if route.is_empty():
		route = _find_carve_route(2)
	for cell in route:
		if obstacles.has(cell):
			_remove_obstacle(cell, false)  # Generation: no clearing mark

# Among the shortest start-to-end routes, the one with the fewest turns (ties left to the search order):
# a breadth-first pass gives each cell its distance, then each shortest-path layer keeps, per cell and
# heading, the fewest turns to get there. Same length as any shortest route, but no one-tile staircases
# where a couple of long runs would do.
func _straightest_route() -> PackedVector2Array:
	var size := Vector2i(MAP_GRID.size)
	var start := Vector2i(startPath)
	var goal := Vector2i(endPath)
	var steps: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var distance := {start: 0}
	var layers: Array = [[start]]
	while not layers[-1].is_empty() and not distance.has(goal):
		var next: Array[Vector2i] = []
		for cell: Vector2i in layers[-1]:
			for step in steps:
				var to := cell + step
				if to.x < 0 or to.y < 0 or to.x >= size.x or to.y >= size.y or distance.has(to) \
						or path_layer.is_cell_blocked(Vector2(to)):
					continue
				distance[to] = layers.size()
				next.append(to)
		layers.append(next)
	if not distance.has(goal):
		return PackedVector2Array()
	# best[[cell, heading]] = [turns, previous key]; headings index `steps`.
	var best := {}
	for heading in steps.size():
		best[[start, heading]] = [0, null]
	for layer in range(1, distance[goal] + 1):
		for cell: Vector2i in layers[layer]:
			for heading in steps.size():
				var from: Vector2i = cell - steps[heading]
				if distance.get(from, -1) != layer - 1:
					continue
				for before in steps.size():
					var previous: Array = best.get([from, before], [])
					if previous.is_empty():
						continue
					var turns: int = previous[0] + (1 if before != heading and from != start else 0)
					var here: Array = best.get([cell, heading], [])
					if here.is_empty() or turns < here[0]:
						best[[cell, heading]] = [turns, [from, before]]
	var key: Variant = null
	for heading in steps.size():
		var here: Array = best.get([goal, heading], [])
		if not here.is_empty() and (key == null or here[0] < best[key][0]):
			key = [goal, heading]
	var route := PackedVector2Array()
	while key != null:
		route.insert(0, Vector2(key[0]))
		key = best[key][1]
	return route

# A route much longer than usual (trees piling up along the ridges) is trimmed back under
# `max_route_length`, one cell at a time: a plain obstacle if one helps, else a ridge cell as a last
# resort. Each time it takes the cell that brings the route just under the cap (the least change),
# or failing that the one that shortens it most, so the zig-zag survives. Never the feature.
func _trim_route_if_long() -> void:
	for attempt in 8:
		var length := route_length(path_layer.find_path_from(startPath))
		if length <= max_route_length:
			return
		var cell := _best_trim(length, false)
		if cell == Vector2(-1, -1):
			cell = _best_trim(length, true)
		if cell == Vector2(-1, -1):
			return
		environment_object_layer.ridge_cells.erase(cell)  # A ridge cut back is a shorter ridge
		_remove_obstacle(cell, false)

func _best_trim(length: int, ridges: bool) -> Vector2:
	var under := Vector2(-1, -1)
	var under_length := 0
	var shortest := Vector2(-1, -1)
	var shortest_length := length
	for cell in obstacles:
		if environment_object_layer.feature_cells.has(cell) or environment_object_layer.ridge_cells.has(cell) != ridges:
			continue
		var new_length := route_length(get_path_if_cleared(cell))
		if new_length <= 0 or new_length >= length:
			continue
		if new_length <= max_route_length and new_length > under_length:
			under = cell
			under_length = new_length
		if new_length < shortest_length:
			shortest = cell
			shortest_length = new_length
	return under if under != Vector2(-1, -1) else shortest

# Cheapest start-to-end route where obstacles are passable but costly. `level` 0: ridges and the map's
# feature (a ruin, grove or log) are solid; 1: the feature may break (costly); 2: ridges may too (costlier).
func _find_carve_route(level: int) -> PackedVector2Array:
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(Vector2i.ZERO, Vector2i(MAP_GRID.size))
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	for cell in unwalkable_cells:
		if astar.is_in_boundsv(Vector2i(cell)):
			astar.set_point_solid(Vector2i(cell), true)
	for cell in environment_object_layer.pond_cells:
		astar.set_point_solid(Vector2i(cell), true)
	for cell in obstacles:
		if environment_object_layer.ridge_cells.has(cell):
			if level >= 2:
				astar.set_point_weight_scale(Vector2i(cell), CARVE_RIDGE_WEIGHT * 10.0)
			else:
				astar.set_point_solid(Vector2i(cell), true)
		elif environment_object_layer.feature_cells.has(cell):
			if level >= 1:
				astar.set_point_weight_scale(Vector2i(cell), CARVE_RIDGE_WEIGHT)
			else:
				astar.set_point_solid(Vector2i(cell), true)
		else:
			astar.set_point_weight_scale(Vector2i(cell), CARVE_OBSTACLE_WEIGHT)
	return astar.get_point_path(Vector2i(startPath), Vector2i(endPath))

# Removes the obstacle on `cell` (the whole log if it's one of the log's cells); `mark` leaves its
# clearing mark (tended stump, moved hollow) on each cell.
func _remove_obstacle(cell: Vector2, mark: bool = true) -> void:
	for at in get_obstacle_cells(cell):
		var data: ObstacleData = obstacles.get(at)
		obstacles.erase(at)
		if mark and data != null:
			environment_object_layer.mark_cleared(at, data)
		else:
			environment_object_layer.erase_cell(Vector2i(at))
		path_layer.set_cell_blocked(at, false)
	if environment_object_layer.log_cells.has(cell):
		environment_object_layer.log_cells.clear()  # Gone as a unit

# The cells of the obstacle on `cell`: all of the log's for a log cell, else just `cell`.
func get_obstacle_cells(cell: Vector2) -> Array[Vector2]:
	var cells: Array[Vector2] = []
	if environment_object_layer.log_cells.has(cell):
		for at in environment_object_layer.log_cells:
			if obstacles.has(at):
				cells.append(at)
		return cells
	cells.append(cell)
	return cells

func get_array_board() -> PackedVector2Array:
	var _map_array: PackedVector2Array
	for x in range(MAP_GRID.size.x):
		for y in range(MAP_GRID.size.y):
			if !unwalkable_cells.has(Vector2(x,y)):
				_map_array.append(Vector2(x,y))
	return _map_array


# --- Building -------------------------------------------------------------------------------------

# True if nothing occupies `cell` (inside the map, not border/tree/tower, not the start or end).
# Does not check whether blocking it would cut off the path — see get_path_if_blocked().
func is_buildable(cell: Vector2) -> bool:
	return MAP_GRID.is_within_bounds(cell) \
		and cell != startPath and cell != endPath \
		and not path_layer.is_cell_blocked(cell)

# Returns the start-to-end path that would exist if `cell` were blocked, without changing anything.
# Empty means blocking `cell` would leave enemies with no way through.
func get_path_if_blocked(cell: Vector2, drawn := false) -> PackedVector2Array:
	return get_path_if_blocked_cells([cell], drawn)

# True if blocking `cell` keeps the end reachable from the start and from every cell in `also_from`
# (e.g. cells enemies are currently walking toward).
func can_block(cell: Vector2, also_from: PackedVector2Array = PackedVector2Array()) -> bool:
	if not is_buildable(cell):
		return false
	var version := probe_begin()
	path_layer.set_cell_blocked(cell, true)
	var ok := not path_layer.find_path_from(startPath).is_empty()
	for from_cell in also_from:
		if not ok:
			break
		ok = not path_layer.find_path_from(from_cell).is_empty()
	path_layer.set_cell_blocked(cell, false)
	probe_end(version)
	return ok

# A probe (block, search, open again) leaves the grid exactly as it was, so it puts FindPath.version back too:
# the drawn route's tail stays valid (PathGenerator.route_tail), and the next placement check doesn't search
# again from all ~150 nightmares (that was ~9 ms on a serpentine after every hover).
func probe_begin() -> int:
	return path_layer.get_finder().version

func probe_end(version: int) -> void:
	path_layer.get_finder().version = version

# Permanently blocks `cell` (call can_block() first), redraws the path and notifies enemies.
func block_cell(cell: Vector2) -> void:
	path_layer.set_cell_blocked(cell, true)
	environment_object_layer.erase_cell(Vector2i(cell))  # Clear grass detail under the tower
	path_layer.draw()
	path_changed.emit()

# --- Several cells at once (the 2×2 Heartwood Sapling) ---

# The start-to-end path if all of `cells` were blocked (empty = no way through). Changes nothing.
func get_path_if_blocked_cells(cells: Array, drawn := false) -> PackedVector2Array:
	# Only the halves free now are closed and opened again: a whole cell may already hold a Warden's half, and
	# opening all 4 afterwards used to punch holes in walls.
	var halves: Array = []
	for c in cells:
		halves.append_array(FindPath.halves_of_cell(c))
	return get_path_if_blocked_halves(halves, drawn)

# True if every cell is buildable and blocking them all keeps the end reachable from the start and
# from every cell in `also_from`.
func can_block_cells(cells: Array, also_from: PackedVector2Array = PackedVector2Array()) -> bool:
	for c in cells:
		if not is_buildable(c):
			return false
	var version := probe_begin()
	for c in cells:
		path_layer.set_cell_blocked(c, true)
	var ok := not path_layer.find_path_from(startPath).is_empty()
	for from_cell in also_from:
		if not ok:
			break
		ok = not path_layer.find_path_from(from_cell).is_empty()
	for c in cells:
		path_layer.set_cell_blocked(c, false)
	probe_end(version)
	return ok

# Blocks all of `cells` at once (call can_block_cells() first); one redraw, one path_changed.
func block_cells(cells: Array) -> void:
	for c in cells:
		path_layer.set_cell_blocked(c, true)
		environment_object_layer.erase_cell(Vector2i(c))
	path_layer.draw()
	path_changed.emit()

# Opens a cell a Warden stood on (it was sold), redraws the path and notifies enemies.
# Opening a cell never cuts a route, so this is always allowed.
func unblock_cell(cell: Vector2) -> void:
	path_layer.set_cell_blocked(cell, false)
	path_layer.draw()
	path_changed.emit()


# --- Half cells (documentation/half_cells.md) ----------------------------------------------------------------
# Pathing runs on 32 px half cells (FindPath): a Warden is a 2×2 footprint at any half offset; a nightmare fits
# through one half cell (half_cells.md 04c10c33). Half cells are integer Vector2 on the (MAP_GRID.size × 2) grid;
# route points are half centres in full-cell units (x.25 / x.75). The full-cell API above still works: a full
# cell c is the halves {2c, 2c+1}².

var _refusal := &""  # Why the last can_block_halves() said no: &"occupied" or &"closes"

# A route's length in full cells (route points step by half a cell).
static func route_length(route: PackedVector2Array) -> int:
	return 0 if route.is_empty() else ceili((route.size() - 1) / 2.0) + 1

# The 4 half cells of a footprint whose top-left half cell is `origin`.
func halves_of(origin: Vector2) -> Array[Vector2]:
	return FindPath.halves_of(origin)

# The half cell a nightmare at route point `point` stands on (a whole cell: its 4).
func body_halves(point: Vector2) -> Array[Vector2]:
	if FindPath.is_whole_cell(point):
		return FindPath.halves_of_cell(point)
	var halves: Array[Vector2] = [Vector2(FindPath.point_to_node(point))]
	return halves

# A half cell's centre in pixels, and the half cell under a pixel.
func half_to_pixels(h: Vector2) -> Vector2:
	return h * MAP_GRID.cell_size / 2.0 + MAP_GRID.cell_size / 4.0

func pixels_to_half(p: Vector2) -> Vector2:
	return (p / (MAP_GRID.cell_size / 2.0)).floor()

# Nothing on half cell `h`: inside the map, not border, obstacle, pond or Warden, not the start's or the
# Heartwood's halves (the glade stays buildable).
func is_buildable_half(h: Vector2) -> bool:
	var cell := (h / 2.0).floor()
	return (MAP_GRID.is_within_bounds(cell) and cell != startPath and cell != endPath
		and not path_layer.is_half_blocked(h))

# True if every half is buildable and blocking them all keeps the Heartwood reachable from the start and from
# each route point in `also_from`. Otherwise block_refusal() says why.
func can_block_halves(halves: Array, also_from: PackedVector2Array = PackedVector2Array()) -> bool:
	_refusal = &""
	for h in halves:
		if not is_buildable_half(h):
			_refusal = &"occupied"
			return false
	var version := probe_begin()
	for h in halves:
		path_layer.set_half_blocked(h, true)
	var route := path_layer.find_path_from(startPath)
	var ok := not route.is_empty()
	if ok and not also_from.is_empty():  # Nightmares on the new route get there; search only for the others, once each
		var on_route := {}
		for point in route:
			on_route[point] = true
		for from_point in also_from:
			if on_route.has(from_point):
				continue
			on_route[from_point] = true  # Searched (and fine if we go on)
			if not path_layer.get_finder().reaches(from_point, endPath):  # One flood fill for all of them
				ok = false
				break
	if not ok:
		_refusal = &"closes"
	for h in halves:
		path_layer.set_half_blocked(h, false)
	probe_end(version)
	return ok

func block_refusal() -> StringName:
	return _refusal

# The start's route if `halves` were blocked (empty = no way through). Changes nothing. `drawn`: the route
# draw() would draw then (fewest turns, ~2 ms) for a preview the player sees; else plain A* (same length).
func get_path_if_blocked_halves(halves: Array, drawn := false) -> PackedVector2Array:
	var changed: Array = halves.filter(func(h: Vector2) -> bool: return not path_layer.is_half_blocked(h))
	var version := probe_begin()
	for h in changed:
		path_layer.set_half_blocked(h, true)
	var path := path_layer.find_drawn_route() if drawn else path_layer.find_path_from(startPath)
	for h in changed:
		path_layer.set_half_blocked(h, false)
	probe_end(version)
	return path

# The start's route if `halves` were opened (a Warden there gone), without changing anything.
func get_path_if_opened_halves(halves: Array, drawn := false) -> PackedVector2Array:
	var changed: Array = halves.filter(func(h: Vector2) -> bool: return path_layer.is_half_blocked(h))
	var version := probe_begin()
	for h in changed:
		path_layer.set_half_blocked(h, false)
	var path := path_layer.find_drawn_route() if drawn else path_layer.find_path_from(startPath)
	for h in changed:
		path_layer.set_half_blocked(h, true)
	probe_end(version)
	return path

# Blocks `halves` (call can_block_halves() first), redraws the route and notifies nightmares.
func block_halves(halves: Array) -> void:
	for h in halves:
		path_layer.set_half_blocked(h, true)
		environment_object_layer.erase_cell(Vector2i((h / 2.0).floor()))  # No grass detail under the Warden
	_route_changed()

# Opens `halves` again (a Warden sold). Opening never cuts a route.
func unblock_halves(halves: Array) -> void:
	for h in halves:
		path_layer.set_half_blocked(h, false)
	_route_changed()

# Several blocks in a row (a drag stroke of Wardens): between hold_route() and release_route() the halves
# change at once, but the route is redrawn and the nightmares re-routed only once, at the release.
# Validity checks (can_block_halves) search the live grid, so each Warden is still checked after the last.
func hold_route() -> void:
	_route_hold += 1

func release_route() -> void:
	_route_hold = maxi(_route_hold - 1, 0)
	if _route_hold == 0 and _route_dirty:
		_route_dirty = false
		path_layer.draw()
		path_changed.emit()

func _route_changed() -> void:
	if _route_hold > 0:
		_route_dirty = true
		return
	path_layer.draw()
	path_changed.emit()

# Shifting Mist (heartwood_gifts.md 0c552b28): nightmares come from `new_start`, a rim cell, from now on. The
# rim, mist and bridge move (EnvironmentObjectGenerator.move_start), the halves swap, the route is redrawn and
# path_changed re-routes everything walking. Spawns read startPath, so they follow.
func move_start(new_start: Vector2) -> void:
	var old := startPath
	if new_start == old:
		return
	environment_object_layer.move_start(Vector2i(old), Vector2i(new_start))
	unwalkable_cells = environment_object_layer.unwalkable_cells
	ground_layer.erase_cell(Vector2i(old))  # Rim cells have no ground under them; the start's rim sits on the ground layer
	ground_layer.set_cell(Vector2i(new_start), EnvironmentTiles.ISLAND_EDGE,
		Vector2i(EnvironmentTiles.rim_mask(Vector2i(new_start), Vector2i(MAP_GRID.size)), 0))
	path_layer.set_cell_blocked(old, true)
	path_layer.set_cell_blocked(new_start, false)
	startPath = new_start
	path_layer.cell_start_path = new_start
	if layout != null:
		layout.start = Vector2i(new_start)
	if dream_void != null:
		dream_void.move_bridge(environment_object_layer.bridge_end)
	path_layer.draw()
	path_changed.emit()

# --- Obstacles ------------------------------------------------------------------------------------

# The tree/rock on `cell`, or null.
func get_obstacle(cell: Vector2) -> ObstacleData:
	return obstacles.get(cell)

# The start-to-end path that would exist if the obstacle on `cell` were cleared, without changing
# anything. Clearing only ever opens routes, so this is never empty when a path exists now.
func get_path_if_cleared(cell: Vector2, drawn := false) -> PackedVector2Array:
	# Only the halves blocked now are opened and closed again: a whole cell may hold free halves (a half-offset
	# Warden straddles cells), and re-blocking all 4 used to wall off free ground (the run-breaking "sold a
	# Warden and the maze vanished": Second Path measured its Thornwalls this way).
	var halves: Array[Vector2] = []
	for at in get_obstacle_cells(cell):  # A log opens all its cells at once
		for h in FindPath.halves_of_cell(at):
			if path_layer.is_half_blocked(h):
				halves.append(h)
	return get_path_if_opened_halves(halves, drawn)

# Removes the obstacle on `cell` (no-op if there isn't one), redraws the path and notifies enemies.
func clear_obstacle(cell: Vector2) -> bool:
	var data := get_obstacle(cell)
	if data == null:
		return false
	_remove_obstacle(cell)
	path_layer.draw()
	obstacle_cleared.emit(cell, data)
	path_changed.emit()
	return true

# Puts obstacle `data` on `cell` mid-run (the Hollow Oak's thorn-saplings): blocks and draws it, and
# re-routes nightmares. Call can_block() first; it can then be cleared like any obstacle.
func place_obstacle(cell: Vector2, data: ObstacleData) -> void:
	if not data.tiles.is_empty():  # No tiles: something else draws it (the saplings' animation)
		environment_object_layer.set_cell(Vector2i(cell), data.source_id, data.tiles.pick_random())
	else:
		environment_object_layer.erase_cell(Vector2i(cell))  # No grass detail showing through
	obstacles[cell] = data
	path_layer.set_cell_blocked(cell, true)
	path_layer.draw()
	path_changed.emit()

# Removes an obstacle without the player clearing it (a sapling withering): no clearing mark, no
# obstacle_cleared. Re-routes nightmares.
func remove_obstacle(cell: Vector2) -> void:
	if not obstacles.has(cell):
		return
	_remove_obstacle(cell, false)
	path_layer.draw()
	path_changed.emit()

# Path from `cell` to the end, in cell coordinates. Used by enemies to re-route.
# True if a nightmare at route point `point` still has a way to the Heartwood (get_path_from would find one),
# without building the path: one flood fill per grid change, then a lookup. For checks over every walker.
func has_route_from(point: Vector2) -> bool:
	return path_layer.get_finder().reaches(point, endPath)

func get_path_from(cell: Vector2) -> PackedVector2Array:
	var tail := path_layer.route_tail(cell)  # On the current route: its tail, no search (every walker re-routes)
	if tail.is_empty():
		tail = path_layer.join_route(cell)  # Off it: down the distance field to the route, then its tail
	return tail if not tail.is_empty() else path_layer.find_path_from(cell)
