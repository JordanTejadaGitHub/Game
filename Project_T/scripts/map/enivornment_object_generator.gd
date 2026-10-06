extends TileMapLayer
class_name EnvironmentObjectGenerator

const MAP_GRID = preload("res://resource/map/map_grid.tres")
# Rings of healthy trees outside the border wall: dark silhouettes where the maze never goes.
const BRIDGE_CELLS := 3  # Rope bridge from the start out into the void (DreamVoid puts an islet at its end)
@export var noise_texture: NoiseTexture2D
@export var tree_obstacle: ObstacleData = preload("res://resource/obstacle/tree.tres")
@export var rock_obstacle: ObstacleData = preload("res://resource/obstacle/rock.tres")
@export var log_obstacle: ObstacleData = preload("res://resource/obstacle/fallen_log.tres")  # The log feature (one unit)
@export_group("Trees")
# Share of the noise range that becomes trees; each map rolls a value in this range.
@export_range(0.0, 0.6) var tree_density_min: float = 0.08
@export_range(0.0, 0.6) var tree_density_max: float = 0.16
# Each map scales the noise frequency by a random factor in this range: low = big groves, high = small copses.
@export var tree_cluster_scale_min: float = 1.1
@export var tree_cluster_scale_max: float = 1.8
@export_group("Rocks")
@export_range(0.0, 1.0) var rock_chance: float = 0.004  # Chance for any free cell to get a lone rock (rare: few scattered singles)
@export var rock_cluster_count_min: int = 0
@export var rock_cluster_count_max: int = 2
@export var rock_cluster_radius_min: float = 0.8  # In cells
@export var rock_cluster_radius_max: float = 1.6
@export_group("Room to maze")
# environment_assets.md "Room to maze": an open build bowl in the middle (the interior `frame_band` cells in
# from the rim) for the player's switchbacks. Groves, rock clusters, the feature and the spurs' roots go in the
# frame band around it; the bowl only gets a few lone "decision" obstacles. Ground patches and details stay.
@export var frame_band: int = 3  # Cells of frame between the rim and the bowl
@export var bowl_obstacles_min: int = 2  # Lone decision obstacles in the bowl
@export var bowl_obstacles_max: int = 4
@export var target_obstacles_min: int = 30  # The whole map: band groves are thinned or topped up into this
@export var target_obstacles_max: int = 40
@export_group("Ridges")
# Ridges are tapered spurs of rocks and trees reaching in from the frame, from alternating walls. They give
# the opening route its bend; clearing one of their cells opens a shortcut.
@export_range(0.3, 1.0) var bend_spur_cap: float = 0.75  # The bend spur reaches at most this share across
@export var ridge_count_min: int = 2
@export var ridge_count_max: int = 2  # As many as fit between the start and the inland Heartwood
@export_range(0.1, 1.0) var ridge_length_min: float = 0.25  # Fraction of the map's width
@export_range(0.1, 1.0) var ridge_length_max: float = 0.35
@export var ridge_min_spacing: int = 4  # Rows between ridge centres (and walls); ridges span ±1, so keep >= 4
@export_range(0.0, 1.0) var ridge_wander_chance: float = 0.3  # Per cell: step up/down a row (max 1 from its base)
# Ridges taper from the wall to the tip, all inside their band (base row ±1) so neighbours never touch:
# a thicket/outcrop root, a two-row middle, a one-row tip, then a few strays so they thin out.
@export_range(0.0, 1.0) var ridge_root_fraction: float = 0.3  # Share of the length at the wall that's up to 3 rows thick
@export_range(0.0, 1.0) var ridge_tip_fraction: float = 0.3  # Share of the length at the tip that's 1 row
@export_range(0.0, 1.0) var ridge_root_fill_chance: float = 0.6  # Root: chance for each of the other 2 band rows
@export_range(0.0, 1.0) var ridge_middle_fill_chance: float = 0.4  # Middle: chance for a second row
@export_range(0.0, 1.0) var ridge_gap_chance: float = 0.15  # Middle and tip: chance a cell is left open (a gap)
@export var blight_extra_ridges: int = 1  # Blight Level 9+: maps get a third spur (meta_design.md)
@export var min_obstacles: int = 12  # Floor per map, so the clearing Dream cards (need 8+) still show up
@export_group("Layouts")
@export var feature_clearance: int = 3  # Feature cells stay at least this far (chessboard) from start and end
const RUIN_STONES: Array[int] = [2, 3, 7]  # mossy_boulder.png: standing stone, cairn, ruined waystone
const BEND_ROOT := 2  # Cells of the bend spur's root (3 rows thick) at its wall
const RIDGE_END_GAP := 3  # Ridge rows keep this far from the start's row and the Heartwood's (its glade is ±1)
# Pond blob sizes (half the ponds; the rest are 3×3 with corners dropped or an L, with pond_inner.png
# drawing their inside corners).
const POND_SIZES: Array[Vector2i] = [Vector2i(2, 3), Vector2i(3, 2), Vector2i(2, 3), Vector2i(3, 2), Vector2i(3, 3), Vector2i(2, 2)]
const NEAR_ROUTE := 2  # A pond or ruin first tries to come this close (chessboard) to the opening route
const NEAR_ROUTE_TRIES := 120
const LOG_ACROSS_TRIES := 80  # A log first tries to lie across the opening route (it gets longer round it), so Tending it is a shortcut
@onready var path_tile_map_layer: PathGenerator = %PathTileMapLayer

var unwalkable_cells: PackedVector2Array
# Cells that belong to a ridge (set of Vector2 -> true), so route carving can avoid breaking them.
var ridge_cells: Dictionary = {}
var bridge_end: Vector2i  # The void cell just past the rope bridge's far end
var ridge_count := 0  # Ridges the last generate_obstacles() placed
var bend_reach := 0  # Cells the last bend spur reached from its wall

# Noise thresholds (set by generate_obstacles): below `_tree_level` = tree, below `_detail_level` =
# grass detail, above = bare grass. Tree level is rolled per map; detail level comes from the noise
# texture's colour ramp.
var _tree_level: float
var _detail_level: float
var _base_noise_frequency := -1.0  # The scene's noise frequency, before per-map scaling
var layout: MapLayout  # Set by MapGenerator before generate_obstacles()
var _start: Vector2i
var _end: Vector2i
var _axis_u := 0  # The ridge frame: ridges run along x (0) or y (1)
# The map's one feature (MapLayout.feature): pond cells block the route but aren't obstacles (never
# cleared); a ruin, grove or log are obstacles like any other.
var pond_cells: Array[Vector2] = []
var pond_corners: Array = []  # [cell (Vector2), pond_inner column (0 NE, 1 SE, 2 SW, 3 NW)] per inside corner
var feature_cells: Array[Vector2] = []
var log_cells: Array[Vector2] = []  # The log feature's cells: one obstacle, cleared as a unit (MapGenerator.get_obstacle_cells)
var feature_near_route := false  # The feature was placed by a near-the-route try (the route ran through the band)

func initialize(startPath: Vector2i, endPath: Vector2i) -> PackedVector2Array:
	_start = startPath
	_end = endPath
	_generate_border(startPath, endPath)
	_generate_cliffs()
	_generate_bridge(startPath)
	# Nightmare mist where drifts arrive. Nothing is ever built or cleared on the start cell.
	set_cell(startPath, EnvironmentTiles.EDGE_MIST, Vector2i.ZERO)
	return unwalkable_cells

# Places ridges, rock clusters, trees (clustered by noise) and lone rocks, skipping `skip_cells`.
# Everything is rolled from `rng`, so every seed gives a different forest.
# Returns {cell (Vector2): ObstacleData}.
func generate_obstacles(rng: RandomNumberGenerator, skip_cells: PackedVector2Array) -> Dictionary:
	var noise: FastNoiseLite = noise_texture.noise
	if _base_noise_frequency < 0.0:
		_base_noise_frequency = noise.frequency
	noise.seed = rng.randi()
	noise.frequency = _base_noise_frequency * rng.randf_range(tree_cluster_scale_min, tree_cluster_scale_max)
	var density := rng.randf_range(tree_density_min, tree_density_max)
	_compute_noise_levels(noise, density)

	var obstacles := {}
	_generate_ridges(rng, skip_cells, obstacles)
	var skip := skip_cells  # A copy: pond cells join it so nothing else lands on them
	_place_feature(rng, skip, obstacles)
	skip.append_array(PackedVector2Array(pond_cells))
	_generate_rock_clusters(rng, skip, obstacles)
	var scatter: Array[Vector2] = []  # Band groves and lone rocks: what thinning may take back
	for x in MAP_GRID.size.x:
		for y in MAP_GRID.size.y:
			var cell := Vector2(x, y)
			if skip.has(cell) or obstacles.has(cell) or not in_band(cell):
				continue
			if noise.get_noise_2d(x, y) <= _tree_level:
				_place_obstacle(rng, cell, tree_obstacle, obstacles)
				scatter.append(cell)
			elif rng.randf() < rock_chance:
				_place_obstacle(rng, cell, rock_obstacle, obstacles)
				scatter.append(cell)
	_place_bowl_obstacles(rng, skip, obstacles)
	scatter.clear()  # Thinning takes any band grove or cluster cell, never a spur or the feature
	for cell: Vector2 in obstacles:
		if in_band(cell) and not ridge_cells.has(cell) and not feature_cells.has(cell):
			scatter.append(cell)
	_thin_to_target(scatter, obstacles)
	_fill_to_minimum(rng, skip, obstacles)
	return obstacles

# True for a cell in the frame band: inside the rim, within `frame_band` cells of it.
func in_band(cell: Vector2) -> bool:
	var size := Vector2i(MAP_GRID.size)
	var c := Vector2i(cell)
	if c.x < 1 or c.y < 1 or c.x > size.x - 2 or c.y > size.y - 2:
		return false  # The rim (or off the map)
	return not in_bowl(cell)

# True for a cell in the open build bowl: `frame_band` cells or more in from the rim.
func in_bowl(cell: Vector2) -> bool:
	var size := Vector2i(MAP_GRID.size)
	var c := Vector2i(cell)
	return c.x >= 1 + frame_band and c.y >= 1 + frame_band and c.x <= size.x - 2 - frame_band and c.y <= size.y - 2 - frame_band

# A few lone "decision" obstacles in the open bowl, never touching another obstacle (8 around).
func _place_bowl_obstacles(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	var want := rng.randi_range(bowl_obstacles_min, bowl_obstacles_max)
	var placed := 0
	for attempt in 200:
		if placed >= want:
			return
		var cell := Vector2(rng.randi_range(1 + frame_band, int(MAP_GRID.size.x) - 2 - frame_band),
			rng.randi_range(1 + frame_band, int(MAP_GRID.size.y) - 2 - frame_band))
		if skip_cells.has(cell) or _touches_obstacle(cell, obstacles):
			continue
		_place_obstacle(rng, cell, tree_obstacle if rng.randf() < 0.5 else rock_obstacle, obstacles)
		placed += 1

func _touches_obstacle(cell: Vector2, obstacles: Dictionary) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if obstacles.has(cell + Vector2(dx, dy)):
				return true
	return false

# Over `target_obstacles_max`: takes back band scatter, the loneliest first (fewest obstacle neighbours), so
# the groves that stay keep their shape.
func _thin_to_target(scatter: Array[Vector2], obstacles: Dictionary) -> void:
	var excess := obstacles.size() - target_obstacles_max
	if excess <= 0:
		return
	var neighbours := func(cell: Vector2) -> int:
		var n := 0
		for step: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			if obstacles.has(cell + step):
				n += 1
		return n
	for i in excess:
		if scatter.is_empty():
			return
		var best := 0
		for j in scatter.size():
			if neighbours.call(scatter[j]) < neighbours.call(scatter[best]):
				best = j
		var cell: Vector2 = scatter[best]
		scatter.remove_at(best)
		obstacles.erase(cell)
		erase_cell(Vector2i(cell))

# Tops a sparse map up to `target_obstacles_min` with lone trees and rocks on free band cells (route carving
# still guarantees a way through).
func _fill_to_minimum(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	for attempt in 800:
		if obstacles.size() >= maxi(min_obstacles, target_obstacles_min):
			return
		var cell := Vector2(rng.randi_range(1, int(MAP_GRID.size.x) - 2), rng.randi_range(1, int(MAP_GRID.size.y) - 2))
		if in_band(cell) and not skip_cells.has(cell) and not obstacles.has(cell):
			_place_obstacle(rng, cell, tree_obstacle if rng.randf() < 0.5 else rock_obstacle, obstacles)

# Ridges are wobbly tapering lines of rocks and trees running in from a wall, laid out by the map's
# layout (MapLayout, environment_assets.md "Map layouts" / "Inland Heartwood"). They're generated in a
# frame where u runs along the ridge and v across it (`_cell(u, v)`): ridges run across the
# start → Heartwood direction. Each ridge has its own rock/tree mix. Diagonal wobbles still block:
# creatures only move up/down/left/right.
# Room to maze (environment_assets.md a5178f53), on rows between the start and the Heartwood: first the bend
# spur (the row nearest the start), a thin line just long enough to cut the start→Heartwood box, so the opening
# route bends round it at +4 or more (game_design.md "The forest (map)"); then short gap-free spurs (~35% across
# at most, from alternating walls; +1 at Blight 9, as many as fit). Roots sit in the frame band, tips reach into
# the bowl. Rows stay RIDGE_END_GAP from the start's and the Heartwood's rows, so no spur reaches the glade.
func _generate_ridges(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	_axis_u = layout.ridge_axis if layout != null else 0
	var u_inner := _u_size() - 2  # Cells between the walls the ridges hang from
	var count := rng.randi_range(ridge_count_min, ridge_count_max)
	if MetaRun.blight_level >= 9:
		count += blight_extra_ridges  # Blight Level 9: one extra ridge
	count += MetaRun.perk_extra_ridges()  # Sidegrade Clear Sight (Spire experiment): one extra ridge
	var a := _v_of(_start)
	var b := _v_of(_end)
	var rows := _pick_ridge_rows(rng, count, mini(a, b) + RIDGE_END_GAP, maxi(a, b) - RIDGE_END_GAP)
	if a > b:
		rows.reverse()  # The first ridge is the one nearest the start
	ridge_count = rows.size()
	if rows.is_empty():
		return
	# The bend spur (environment_assets.md a5178f53): from the wall that needs the shorter reach, just far enough
	# past the start→Heartwood box that every way round it costs +4 (its tip one cell past the box's far side).
	var lo_u := mini(_u_of(_start), _u_of(_end))
	var hi_u := maxi(_u_of(_start), _u_of(_end))
	var reach_low := hi_u + 1  # From the low wall: cells 1..hi_u + 1
	var reach_high := u_inner - lo_u + 2  # From the high wall: cells lo_u - 1..u_inner
	var from_low := reach_low <= reach_high
	var cap := roundi(u_inner * bend_spur_cap)
	bend_reach = mini(reach_low if from_low else reach_high, cap)
	_bend_spur(rng, rows[0], from_low, bend_reach, skip_cells, obstacles)
	for ridge in range(1, rows.size()):  # Any others: short spurs from alternating walls
		from_low = not from_low
		var length := maxi(frame_band + 1, roundi(u_inner * rng.randf_range(ridge_length_min, ridge_length_max)))
		_ridge(rng, rows[ridge], from_low, length, length, skip_cells, obstacles)  # Gap-free: a spur is short

# The bend spur: a straight, gap-free line of single obstacles `length` cells from its wall, with a 2-cell
# root (the rows either side filled in) in the frame. Clearable like any obstacle (a big shortcut later).
func _bend_spur(rng: RandomNumberGenerator, v: int, from_low: bool, length: int,
		skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	var u_inner := _u_size() - 2
	var rock_share := rng.randf()
	for i in length:
		var u := 1 + i if from_low else u_inner - i
		_place_ridge_cell(rng, _cell(u, v), rock_share, skip_cells, obstacles)
		if i < BEND_ROOT:
			for other in [v - 1, v + 1]:
				_place_ridge_cell(rng, _cell(u, other), rock_share, skip_cells, obstacles)

# One tapering ridge: from the low-u wall (or the high one) `length` cells along u, wandering inside
# its band (v_base ±1): a thicket/outcrop root, a two-row middle, a one-row tip, then a few strays.
# Gaps may open from `gaps_from` cells on (past the root); gaps_from >= length = gap-free.
func _ridge(rng: RandomNumberGenerator, v_base: int, from_low: bool, length: int, gaps_from: int,
		skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	var u_inner := _u_size() - 2
	var rock_share := rng.randf()
	var root_end := roundi(length * ridge_root_fraction)
	var tip_start := length - roundi(length * ridge_tip_fraction)
	var v := v_base
	for i in length:
		if rng.randf() < ridge_wander_chance:
			v = clampi(v + (1 if rng.randf() < 0.5 else -1), v_base - 1, v_base + 1)
		if i >= maxi(root_end, gaps_from) and rng.randf() < ridge_gap_chance:
			continue  # A gap: this cell of the ridge is left open
		var u := 1 + i if from_low else u_inner - i
		_place_ridge_cell(rng, _cell(u, v), rock_share, skip_cells, obstacles)
		if i < root_end:
			# Root: a thicket or outcrop across the whole band, not a solid block.
			for other in range(v_base - 1, v_base + 2):
				if other != v and rng.randf() < ridge_root_fill_chance:
					_place_ridge_cell(rng, _cell(u, other), rock_share, skip_cells, obstacles)
		elif i < tip_start and rng.randf() < ridge_middle_fill_chance:
			# Middle: one neighbouring row, kept inside the band.
			var side := 1 if rng.randf() < 0.5 else -1
			if absi(v + side - v_base) > 1:
				side = -side
			_place_ridge_cell(rng, _cell(u, v + side), rock_share, skip_cells, obstacles)
	# No strays past the tip: the bowl beyond stays open (Room to maze).

# The ridge frame: u along the ridges, v across them.
func _cell(u: int, v: int) -> Vector2:
	return Vector2(u, v) if _axis_u == 0 else Vector2(v, u)

func _u_of(cell: Vector2i) -> int:
	return cell.x if _axis_u == 0 else cell.y

func _v_of(cell: Vector2i) -> int:
	return cell.y if _axis_u == 0 else cell.x

func _u_size() -> int:
	return int(MAP_GRID.size.x if _axis_u == 0 else MAP_GRID.size.y)

func _v_size() -> int:
	return int(MAP_GRID.size.y if _axis_u == 0 else MAP_GRID.size.x)

func _place_ridge_cell(rng: RandomNumberGenerator, cell: Vector2, rock_share: float,
		skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	if skip_cells.has(cell) or not MAP_GRID.is_within_bounds(cell):
		return
	_place_obstacle(rng, cell, rock_obstacle if rng.randf() < rock_share else tree_obstacle, obstacles)
	ridge_cells[cell] = true

# Round-ish blobs of rocks, denser in the middle.
func _generate_rock_clusters(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	for cluster in rng.randi_range(rock_cluster_count_min, rock_cluster_count_max):
		var center := Vector2(rng.randi_range(1, int(MAP_GRID.size.x) - 2), rng.randi_range(1, int(MAP_GRID.size.y) - 2))
		for retry in 20:  # In the frame band
			if in_band(center):
				break
			center = Vector2(rng.randi_range(1, int(MAP_GRID.size.x) - 2), rng.randi_range(1, int(MAP_GRID.size.y) - 2))
		var radius := rng.randf_range(rock_cluster_radius_min, rock_cluster_radius_max)
		var reach := ceili(radius)
		for dx in range(-reach, reach + 1):
			for dy in range(-reach, reach + 1):
				var cell := center + Vector2(dx, dy)
				var distance := Vector2(dx, dy).length()
				if distance > radius or skip_cells.has(cell) or obstacles.has(cell) or not in_band(cell):
					continue
				if rng.randf() < 1.0 - distance / (radius + 1.0):
					_place_obstacle(rng, cell, rock_obstacle, obstacles)

# Up to `count` rows between `first` and `last`, sorted, each at least `ridge_min_spacing` apart.
func _pick_ridge_rows(rng: RandomNumberGenerator, count: int, first: int, last: int) -> Array[int]:
	var rows: Array[int] = []
	if last < first:
		return rows
	# As many as fit (a small map fits fewer), spread by random gaps: picking rows one at a time could
	# put the first in the middle and leave no room for a second.
	count = mini(count, (last - first) / ridge_min_spacing + 1)
	var slack := (last - first) - (count - 1) * ridge_min_spacing
	var offsets: Array[int] = []
	for i in count:
		offsets.append(rng.randi_range(0, slack))
	offsets.sort()
	for i in count:
		rows.append(first + i * ridge_min_spacing + offsets[i])
	return rows

func _place_obstacle(rng: RandomNumberGenerator, cell: Vector2, data: ObstacleData, obstacles: Dictionary) -> void:
	set_cell(Vector2i(cell), data.source_id, data.tiles[rng.randi_range(0, data.tiles.size() - 1)])
	obstacles[cell] = data

# Leaves the walkable mark of a cleared obstacle (tended stump, moved hollow) on `cell`.
func mark_cleared(cell: Vector2, data: ObstacleData) -> void:
	if data.cleared_source_id == EnvironmentTiles.LOG_FURROW:  # The furrow piece matching the log piece there
		set_cell(Vector2i(cell), data.cleared_source_id, get_cell_atlas_coords(Vector2i(cell)))
	elif data.cleared_source_id >= 0:
		set_cell(Vector2i(cell), data.cleared_source_id, data.cleared_tile)
	else:
		erase_cell(Vector2i(cell))

# Decorations the path wears away when it's drawn over them (ground details, clearing marks). Obstacles,
# the start's mist and the island's rim are never worn: obstacles are blocked, so no path lies on them.
const WORN_BY_PATH: Array[int] = [EnvironmentTiles.GROUND_DETAILS, EnvironmentTiles.TENDED_STUMP,
	EnvironmentTiles.MOVED_HOLLOW, EnvironmentTiles.LOG_FURROW]

# The path now runs over `cell`: erase any decoration there. It stays bare if the path moves away.
func wear_away(cell: Vector2i) -> void:
	if get_cell_source_id(cell) in WORN_BY_PATH:
		erase_cell(cell)


# Share of the cells in the noise's detail band that get a detail: one on every such cell lined the
# ground up into a dotted grid.
const DETAIL_SHARE := 0.3

# Sprinkles grass details (decoration only) on cells not in `skip_cells`. Call after generate_obstacles().
# Details follow the ground patches (`patch_kinds`: cell -> GroundPatches kind): ferns in fern beds (and a few
# more of them), pebbles on worn earth, fewer on deep moss. The rng draws are the same either way, so the
# rest of the map is untouched. ground_details.png: column % 4 = mushrooms, ferns, pebbles, leaf litter.
func generate_details(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, patch_kinds: Dictionary = {}) -> void:
	var noise: FastNoiseLite = noise_texture.noise
	var details := tile_set.get_source(EnvironmentTiles.GROUND_DETAILS) as TileSetAtlasSource
	var columns := details.get_atlas_grid_size().x
	for x in MAP_GRID.size.x:
		for y in MAP_GRID.size.y:
			var cell := Vector2(x, y)
			if skip_cells.has(cell):
				continue
			var value := noise.get_noise_2d(x, y)
			var kind: int = patch_kinds.get(cell, -1)
			var column := -1
			if value > _tree_level and value <= _detail_level and rng.randf() < DETAIL_SHARE:
				column = rng.randi_range(0, columns - 1)
			if kind == GroundPatches.FERN_BED and column < 0 and EnvironmentTiles.cell_variant(Vector2i(cell), 5, 3) < 2:
				column = EnvironmentTiles.cell_variant(Vector2i(cell), columns, 5)  # Fern beds: a few more
			if column < 0:
				continue
			match kind:
				GroundPatches.FERN_BED:
					column = column / 4 * 4 + 1  # Ferns
				GroundPatches.WORN_EARTH:
					column = column / 4 * 4 + 2  # Pebbles
				GroundPatches.DEEP_MOSS, GroundPatches.GLADE_RING:
					if EnvironmentTiles.cell_variant(Vector2i(cell), 3, 9) != 0:
						continue  # Velvety: fewer details
			set_cell(Vector2i(cell), EnvironmentTiles.GROUND_DETAILS, Vector2i(column, 0))

func _compute_noise_levels(noise: FastNoiseLite, tree_density: float) -> void:
	var lowest := INF
	var highest := -INF
	for x in MAP_GRID.size.x:
		for y in MAP_GRID.size.y:
			var value := noise.get_noise_2d(x, y)
			lowest = minf(lowest, value)
			highest = maxf(highest, value)
	var offsets := noise_texture.color_ramp.offsets
	_tree_level = lowest + (highest - lowest) * tree_density
	_detail_level = lowest + (highest - lowest) * maxf(offsets[2], tree_density)

# The map is an island of dream adrift in the void (environment_assets.md, "The dream's outer
# layer"): its border cells are the island's rim, each tile picked by which neighbours are island.
# The rim stays unwalkable; the start and end are open (the path draws them).
func _generate_border(startPath: Vector2i, endPath: Vector2i) -> void:
	var last := Vector2i(MAP_GRID.size) - Vector2i.ONE
	# island_edge.png has a variant per row (they all meet at the tile ends): a mix of them keeps the
	# rim from repeating one scallop round the island. Picked by a hash of the cell, so the rng is untouched.
	var variants := (tile_set.get_source(EnvironmentTiles.ISLAND_EDGE) as TileSetAtlasSource).get_atlas_grid_size().y
	for x in range(0, last.x + 1):
		for y in range(0, last.y + 1):
			var cell := Vector2i(x, y)
			if (x != 0 and y != 0 and x != last.x and y != last.y) or cell == startPath or cell == endPath:
				continue
			var variant := absi(hash(cell)) % maxi(variants, 1)
			set_cell(cell, EnvironmentTiles.ISLAND_EDGE, Vector2i(EnvironmentTiles.rim_mask(cell, last + Vector2i.ONE), variant))
			unwalkable_cells.append(Vector2(cell))

# Cliff faces hanging under the island's bottom row.
func _generate_cliffs() -> void:
	var size := Vector2i(MAP_GRID.size)
	for x in size.x:
		var cell := Vector2i(x, size.y)
		var column := (1 if x > 0 else 0) | (2 if x < size.x - 1 else 0)
		set_cell(cell, EnvironmentTiles.CLIFF, Vector2i(column, EnvironmentTiles.cell_variant(cell, 4)))

# A rope bridge from the start cell straight out into the void, where the nightmares cross over.
func _generate_bridge(startPath: Vector2i) -> void:
	var out := _outward(startPath)
	var tile := Vector2i(1, 0) if out.x == 0 else Vector2i(0, 0)  # North-south or east-west planks
	for i in range(1, BRIDGE_CELLS + 1):
		set_cell(startPath + out * i, EnvironmentTiles.ROPE_BRIDGE, tile)
	bridge_end = startPath + out * (BRIDGE_CELLS + 1)

# Shifting Mist (heartwood_gifts.md 0c552b28): the start moves to `new` on the rim. The old start turns back
# into rim (its bridge goes, the cliffs come back under the bottom row); the new one gets the mist and a bridge.
func move_start(old: Vector2i, new: Vector2i) -> void:
	var size := Vector2i(MAP_GRID.size)
	var out := _outward(old)
	for i in range(1, BRIDGE_CELLS + 1):
		var cell := old + out * i
		erase_cell(cell)
		if cell.y == size.y and cell.x >= 0 and cell.x < size.x:  # Under the bottom row: its cliff face again
			set_cell(cell, EnvironmentTiles.CLIFF, Vector2i((1 if cell.x > 0 else 0) | (2 if cell.x < size.x - 1 else 0), EnvironmentTiles.cell_variant(cell, 4)))
	var variants := (tile_set.get_source(EnvironmentTiles.ISLAND_EDGE) as TileSetAtlasSource).get_atlas_grid_size().y
	set_cell(old, EnvironmentTiles.ISLAND_EDGE, Vector2i(EnvironmentTiles.rim_mask(old, size), absi(hash(old)) % maxi(variants, 1)))
	unwalkable_cells.append(Vector2(old))
	var at := unwalkable_cells.find(Vector2(new))
	if at >= 0:
		unwalkable_cells.remove_at(at)
	_start = new
	_generate_bridge(new)
	set_cell(new, EnvironmentTiles.EDGE_MIST, Vector2i.ZERO)

# The direction off the island from an edge cell.
func _outward(cell: Vector2i) -> Vector2i:
	var last := Vector2i(MAP_GRID.size) - Vector2i.ONE
	if cell.y <= 0:
		return Vector2i.UP
	if cell.y >= last.y:
		return Vector2i.DOWN
	return Vector2i.LEFT if cell.x <= 0 else Vector2i.RIGHT
# --- The map's one feature (environment_assets.md "Map layouts") --------------------------------------

# Places MapLayout.feature somewhere free, at least `feature_clearance` cells from the start and end.
# Mostly scenery, with a small maze impact. Gives up quietly if nothing fits.
func _place_feature(rng: RandomNumberGenerator, skip: PackedVector2Array, obstacles: Dictionary) -> void:
	pond_cells.clear()
	feature_cells.clear()
	log_cells.clear()
	feature_near_route = false
	pond_corners.clear()
	if layout == null:
		return
	# A pond, ruin or log should shape the opening: the first tries must come within NEAR_ROUTE cells of the
	# route as the ridges leave it (a log: first across it, so the route bends round the log); then anywhere.
	# Room to maze: the feature sits in the frame band or straddles its inner edge, and only the route's band
	# stretch counts for "near the route" (a feature can't reach it where the route crosses the bowl).
	var shapes_route := layout.feature in [MapLayout.Feature.POND, MapLayout.Feature.RUIN, MapLayout.Feature.LOG]
	var route := _provisional_route() if shapes_route else {}
	for cell: Vector2i in route.keys():
		if not in_band(Vector2(cell)):
			route.erase(cell)
	if route.is_empty():
		shapes_route = false
	var base_length := _route_length([]) if layout.feature == MapLayout.Feature.LOG else 0
	var route_cells: Array = route.keys()
	for attempt in 400:  # The band leaves fewer spots
		var around := Vector2(-1, -1)  # The near tries start around a cell of the route's band stretch
		if shapes_route and attempt < NEAR_ROUTE_TRIES:
			around = Vector2(route_cells[rng.randi_range(0, route_cells.size() - 1)]) \
				+ Vector2(rng.randi_range(-3, 1), rng.randi_range(-3, 1))
		var cells := _feature_shape(rng, layout.feature, around)
		if cells.is_empty() or not cells.all(func(c: Vector2) -> bool: return _feature_cell_ok(c, skip, obstacles)):
			continue
		if not cells.any(in_band) or not cells.all(func(c: Vector2) -> bool: return not _deep_in_bowl(c)):
			continue
		if layout.feature == MapLayout.Feature.LOG and attempt < LOG_ACROSS_TRIES and _route_length(cells) <= base_length:
			continue
		if shapes_route and attempt < NEAR_ROUTE_TRIES and not _near(cells, route):
			continue
		if not _route_survives(cells):  # Never across the only way through (ponds can't be cleared at all)
			continue
		match layout.feature:
			MapLayout.Feature.POND:
				for cell in cells:  # One body of water: each cell's banks face the non-pond side
					var mask := ((1 if cells.has(cell + Vector2.UP) else 0) | (2 if cells.has(cell + Vector2.RIGHT) else 0)
						| (4 if cells.has(cell + Vector2.DOWN) else 0) | (8 if cells.has(cell + Vector2.LEFT) else 0))
					set_cell(Vector2i(cell), EnvironmentTiles.POND, Vector2i(mask, 0))
				pond_cells.assign(cells)
				_find_pond_corners(cells)
			MapLayout.Feature.RUIN:
				for cell in cells:  # Standing stones, cairns and ruined waystones
					_place_obstacle_tile(cell, rock_obstacle, Vector2i(RUIN_STONES[rng.randi_range(0, RUIN_STONES.size() - 1)], 0), obstacles)
			MapLayout.Feature.LOG:  # One obstacle over its cells: end and middle pieces, cleared as a unit
				for cell in cells:
					rng.randi_range(0, tree_obstacle.tiles.size() - 1)  # The draw the trees it replaced took: same maps
					_place_obstacle_tile(cell, log_obstacle, EnvironmentTiles.log_piece(cell, cells), obstacles)
				log_cells.assign(cells)
			_:
				for cell in cells:
					_place_obstacle(rng, cell, tree_obstacle, obstacles)
		feature_cells.assign(cells)
		feature_near_route = shapes_route and attempt < NEAR_ROUTE_TRIES
		return

# The feature's cells around a random spot, or from `around` when given (before checking they're free).
func _feature_shape(rng: RandomNumberGenerator, feature: MapLayout.Feature, around := Vector2(-1, -1)) -> Array[Vector2]:
	var at := Vector2(rng.randi_range(2, int(MAP_GRID.size.x) - 3), rng.randi_range(2, int(MAP_GRID.size.y) - 3))
	if around != Vector2(-1, -1):
		at = around
	var cells: Array[Vector2] = []
	match feature:
		MapLayout.Feature.POND:  # Organic: a blob, a 3×3 with 1-2 corners dropped, or an occasional L
			var shape := rng.randf()
			var size: Vector2i = POND_SIZES[rng.randi_range(0, POND_SIZES.size() - 1)] if shape < 0.5 else Vector2i(3, 3)
			var dropped := {}
			var corners: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 2), Vector2i(2, 2)]
			var first := corners[rng.randi_range(0, 3)]
			var second := corners[rng.randi_range(0, 3)]
			if shape >= 0.5 and shape < 0.9:
				dropped[first] = true
				if shape >= 0.75:
					dropped[second] = true  # Sometimes the same corner: then just one
			elif shape >= 0.9:  # An L: a 2×2 bite out of one corner
				var bite := Vector2i(mini(first.x, 1), mini(first.y, 1))
				for dx in 2:
					for dy in 2:
						dropped[bite + Vector2i(dx, dy)] = true
			for dx in size.x:
				for dy in size.y:
					if not dropped.has(Vector2i(dx, dy)):
						cells.append(at + Vector2(dx, dy))
		MapLayout.Feature.RUIN:  # A ring of stones 3 or 4 across, open on one side
			var side := rng.randi_range(3, 4)
			var gap_side := rng.randi_range(0, 3)
			var gap_at := rng.randi_range(1, side - 2)
			for dx in side:
				for dy in side:
					if dx != 0 and dy != 0 and dx != side - 1 and dy != side - 1:
						continue
					var gap: bool = [dy == 0 and dx == gap_at, dx == side - 1 and dy == gap_at,
						dy == side - 1 and dx == gap_at, dx == 0 and dy == gap_at][gap_side]
					if not gap:
						cells.append(at + Vector2(dx, dy))
		MapLayout.Feature.GROVE:  # A tight cluster of trees
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					if Vector2(dx, dy).length() <= 1.6 and rng.randf() < 0.85:
						cells.append(at + Vector2(dx, dy))
		MapLayout.Feature.LOG:  # A fallen log, 3-4 cells in a straight line
			var along := Vector2(1, 0) if rng.randf() < 0.5 else Vector2(0, 1)
			for i in rng.randi_range(3, 4):
				cells.append(at + along * i)
	return cells

# More than one cell into the bowl (its first ring is where a feature may straddle the band's inner edge).
func _deep_in_bowl(cell: Vector2) -> bool:
	return in_bowl(cell) and in_bowl(cell + Vector2(1, 0)) and in_bowl(cell + Vector2(-1, 0)) \
		and in_bowl(cell + Vector2(0, 1)) and in_bowl(cell + Vector2(0, -1))

func _feature_cell_ok(cell: Vector2, skip: PackedVector2Array, obstacles: Dictionary) -> bool:
	var far := maxi(absi(int(cell.x) - _start.x), absi(int(cell.y) - _start.y)) >= feature_clearance \
		and maxi(absi(int(cell.x) - _end.x), absi(int(cell.y) - _end.y)) >= feature_clearance
	return far and cell.x >= 1 and cell.y >= 1 and cell.x <= MAP_GRID.size.x - 2 and cell.y <= MAP_GRID.size.y - 2 \
		and not skip.has(cell) and not obstacles.has(cell)

# A feature must never cut the start from the end, even with every ridge standing: a pond can't be
# cleared at all, and carving through a ruin or grove would break it.
func _route_survives(pond: Array[Vector2]) -> bool:
	var blocked := {}
	for cell in unwalkable_cells:
		blocked[Vector2i(cell)] = true
	for cell in ridge_cells:
		blocked[Vector2i(cell)] = true
	for cell in pond:
		blocked[Vector2i(cell)] = true
	var seen := {_start: true}
	var queue: Array[Vector2i] = [_start]
	var size := Vector2i(MAP_GRID.size)
	while not queue.is_empty():
		var at: Vector2i = queue.pop_back()
		if at == _end:
			return true
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := at + step
			if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y or seen.has(next):
				continue
			if blocked.has(next) and next != _end:
				continue
			seen[next] = true
			queue.append(next)
	return false

# Steps from the start to the end past the rim, the ridges and `extra` (-1 = no way through).
func _route_length(extra: Array) -> int:
	var blocked := {}
	for cell in unwalkable_cells:
		blocked[Vector2i(cell)] = true
	for cell in ridge_cells:
		blocked[Vector2i(cell)] = true
	for cell in extra:
		blocked[Vector2i(cell)] = true
	var distance := {_start: 0}
	var queue: Array[Vector2i] = [_start]
	var size := Vector2i(MAP_GRID.size)
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		if at == _end:
			return distance[at]
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := at + step
			if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y or distance.has(next):
				continue
			if blocked.has(next) and next != _end:
				continue
			distance[next] = distance[at] + 1
			queue.append(next)
	return -1

func _place_obstacle_tile(cell: Vector2, data: ObstacleData, tile: Vector2i, obstacles: Dictionary) -> void:
	set_cell(Vector2i(cell), data.source_id, tile)
	obstacles[cell] = data

# The opening route as the ridges leave it (before trees and rocks): a shortest walk from the start to
# the end past the rim and the ridges. {cell (Vector2i): true}; empty if there's none yet.
func _provisional_route() -> Dictionary:
	var blocked := {}
	for cell in unwalkable_cells:
		blocked[Vector2i(cell)] = true
	for cell in ridge_cells:
		blocked[Vector2i(cell)] = true
	var came_from := {_start: _start}
	var queue: Array[Vector2i] = [_start]
	var size := Vector2i(MAP_GRID.size)
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		if at == _end:
			break
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := at + step
			if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y or came_from.has(next):
				continue
			if blocked.has(next) and next != _end:
				continue
			came_from[next] = at
			queue.append(next)
	var route := {}
	if not came_from.has(_end):
		return route
	var cell := _end
	while cell != _start:
		route[cell] = true
		cell = came_from[cell]
	route[_start] = true
	return route

# True if any of `cells` is within NEAR_ROUTE (chessboard) of the route.
func _near(cells: Array[Vector2], route: Dictionary) -> bool:
	for cell in cells:
		for dx in range(-NEAR_ROUTE, NEAR_ROUTE + 1):
			for dy in range(-NEAR_ROUTE, NEAR_ROUTE + 1):
				if route.has(Vector2i(cell) + Vector2i(dx, dy)):
					return true
	return false

# Inside corners of a pond that isn't a rectangle: a cell whose two neighbours on a corner's sides are
# pond but whose diagonal isn't gets that corner's pond_inner overlay (MapGenerator draws them).
func _find_pond_corners(cells: Array[Vector2]) -> void:
	var diagonals: Array[Vector2] = [Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]  # NE, SE, SW, NW
	for cell in cells:
		for column in diagonals.size():
			var d := diagonals[column]
			if cells.has(cell + Vector2(d.x, 0)) and cells.has(cell + Vector2(0, d.y)) and not cells.has(cell + d):
				pond_corners.append([cell, column])
