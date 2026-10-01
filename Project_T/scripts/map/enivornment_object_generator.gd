extends TileMapLayer
class_name EnvironmentObjectGenerator

const MAP_GRID = preload("res://resource/map/map_grid.tres")
# Rings of healthy trees outside the border wall: dark silhouettes where the maze never goes.
const BRIDGE_CELLS := 3  # Rope bridge from the start out into the void (DreamVoid puts an islet at its end)
@export var noise_texture: NoiseTexture2D
@export var tree_obstacle: ObstacleData = preload("res://resource/obstacle/tree.tres")
@export var rock_obstacle: ObstacleData = preload("res://resource/obstacle/rock.tres")
@export_group("Trees")
# Share of the noise range that becomes trees; each map rolls a value in this range.
@export_range(0.0, 0.6) var tree_density_min: float = 0.13
@export_range(0.0, 0.6) var tree_density_max: float = 0.24
# Each map scales the noise frequency by a random factor in this range: low = big groves, high = small copses.
@export var tree_cluster_scale_min: float = 1.1
@export var tree_cluster_scale_max: float = 1.8
@export_group("Rocks")
@export_range(0.0, 1.0) var rock_chance: float = 0.004  # Chance for any free cell to get a lone rock (rare: few scattered singles)
@export var rock_cluster_count_min: int = 0
@export var rock_cluster_count_max: int = 2
@export var rock_cluster_radius_min: float = 0.8  # In cells
@export var rock_cluster_radius_max: float = 1.6
@export_group("Ridges")
# Ridges are wobbly lines of rocks and trees running in from the left or right wall. They make the
# starting route snake back and forth; clearing one of their cells opens a shortcut.
@export var ridge_count_min: int = 2
@export var ridge_count_max: int = 2  # The Wardens should build most of the maze, not the map
@export_range(0.1, 1.0) var ridge_length_min: float = 0.5  # Fraction of the map's width
@export_range(0.1, 1.0) var ridge_length_max: float = 0.7
@export var ridge_min_spacing: int = 4  # Rows between ridge centres (and walls); ridges span ±1, so keep >= 4
@export_range(0.0, 1.0) var ridge_wander_chance: float = 0.3  # Per cell: step up/down a row (max 1 from its base)
# Ridges taper from the wall to the tip, all inside their band (base row ±1) so neighbours never touch:
# a thicket/outcrop root, a two-row middle, a one-row tip, then a few strays so they thin out.
@export_range(0.0, 1.0) var ridge_root_fraction: float = 0.3  # Share of the length at the wall that's up to 3 rows thick
@export_range(0.0, 1.0) var ridge_tip_fraction: float = 0.3  # Share of the length at the tip that's 1 row
@export_range(0.0, 1.0) var ridge_root_fill_chance: float = 0.6  # Root: chance for each of the other 2 band rows
@export_range(0.0, 1.0) var ridge_middle_fill_chance: float = 0.4  # Middle: chance for a second row
@export_range(0.0, 1.0) var ridge_gap_chance: float = 0.15  # Middle and tip: chance a cell is left open (a gap)
@export var blight_extra_ridges: int = 1  # Blight Level 9+: maps get one extra ridge (meta_design.md)
@export var min_obstacles: int = 10  # Floor per map, so the clearing Dream cards (need 8+) still show up
@export var ridge_stray_min: int = 1  # Lone obstacles past the tip, in the band
@export var ridge_stray_max: int = 3
@export var ridge_stray_gap_min: int = 1  # Open columns before each stray
@export var ridge_stray_gap_max: int = 2
@export_group("Layouts")
@export_range(0.1, 1.0) var spine_length_min: float = 0.75  # INLET spine, fraction of the way across
@export_range(0.1, 1.0) var spine_length_max: float = 0.85
# SIDE layouts start mid-edge, so their ridges reach further across (more overlap = a longer zig-zag).
@export_range(0.1, 1.0) var side_ridge_length_min: float = 0.65
@export_range(0.1, 1.0) var side_ridge_length_max: float = 0.8
# SIDE along the short axis has three ridges across a wider span: a little shorter, and fewer trees.
@export_range(0.1, 1.0) var short_side_ridge_length_min: float = 0.65
@export_range(0.1, 1.0) var short_side_ridge_length_max: float = 0.8
@export_range(0.0, 1.0) var short_side_tree_scale: float = 0.35
@export var feature_clearance: int = 3  # Feature cells stay at least this far (chessboard) from start and end
const RUIN_STONES: Array[int] = [2, 3, 7]  # mossy_boulder.png: standing stone, cairn, ruined waystone
# A gap in the first ridge sits at least this far inside the second ridge's reach, so going through it
# still means doubling back that far. SIDE layouts (which start mid-edge) keep both ridges gap-free.
const BEND_DEPTH := 4
@onready var path_tile_map_layer: PathGenerator = %PathTileMapLayer

var unwalkable_cells: PackedVector2Array
# Cells that belong to a ridge (set of Vector2 -> true), so route carving can avoid breaking them.
var ridge_cells: Dictionary = {}
var bridge_end: Vector2i  # The void cell just past the rope bridge's far end
var ridge_count := 0  # Ridges the last generate_obstacles() placed

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
var feature_cells: Array[Vector2] = []

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
	if layout != null and layout.short_side:
		density *= short_side_tree_scale
	_compute_noise_levels(noise, density)

	var obstacles := {}
	_generate_ridges(rng, skip_cells, obstacles)
	var skip := skip_cells  # A copy: pond cells join it so nothing else lands on them
	_place_feature(rng, skip, obstacles)
	skip.append_array(PackedVector2Array(pond_cells))
	_generate_rock_clusters(rng, skip, obstacles)
	for x in MAP_GRID.size.x:
		for y in MAP_GRID.size.y:
			var cell := Vector2(x, y)
			if skip.has(cell) or obstacles.has(cell):
				continue
			if noise.get_noise_2d(x, y) <= _tree_level:
				_place_obstacle(rng, cell, tree_obstacle, obstacles)
			elif rng.randf() < rock_chance:
				_place_obstacle(rng, cell, rock_obstacle, obstacles)
	_fill_to_minimum(rng, skip, obstacles)
	return obstacles

# Tops a sparse map up to `min_obstacles` with lone trees and rocks on random free cells (route carving
# still guarantees a way through).
func _fill_to_minimum(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	for attempt in 500:
		if obstacles.size() >= min_obstacles:
			return
		var cell := Vector2(rng.randi_range(1, int(MAP_GRID.size.x) - 2), rng.randi_range(1, int(MAP_GRID.size.y) - 2))
		if not skip_cells.has(cell) and not obstacles.has(cell):
			_place_obstacle(rng, cell, tree_obstacle if rng.randf() < 0.5 else rock_obstacle, obstacles)

# Ridges are wobbly tapering lines of rocks and trees running in from a wall, laid out by the map's
# layout (MapLayout, environment_assets.md "Map layouts"). They're generated in a frame where u runs
# along the ridge and v across it (`_cell(u, v)`): ridges along x when the route mainly travels along y,
# and along y when it travels along x. Each ridge has its own rock/tree mix. Diagonal wobbles still
# block: creatures only move up/down/left/right.
# CORNER and SIDE: 2-3 ridges across the route, from alternating walls, the first on the start's side.
# One bend is guaranteed (game_design.md "The forest (map)"): the second ridge has no gaps, the first
# only has gaps well inside where the second lies past it (BEND_DEPTH; none at all in SIDE layouts), and
# the two always overlap, so any way past the first lands against the second's solid part and has to
# double back. Later ridges gap freely.
# INLET: a gap-free spine from the shared edge, between the start and the Heartwood (the U), plus 0-1
# more from the far wall. Blight Level 9 adds one more ridge in either case.
func _generate_ridges(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	_axis_u = layout.ridge_axis if layout != null else 0
	if layout != null and layout.kind == MapLayout.Kind.INLET:
		_inlet_ridges(rng, skip_cells, obstacles)
	else:
		_crossing_ridges(rng, skip_cells, obstacles)

func _crossing_ridges(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	var u_inner := _u_size() - 2  # Cells between the walls the ridges hang from
	var count := rng.randi_range(ridge_count_min, ridge_count_max)
	if layout != null and layout.short_side:
		count += 1  # Top ↔ bottom is the short way across: one more ridge keeps the route as long
	if MetaRun.blight_level >= 9:
		count += blight_extra_ridges  # Blight Level 9: one extra ridge
	var rows := _pick_ridge_rows(rng, count, _v_size())
	if _v_of(_start) > _v_size() / 2:
		rows.reverse()  # The first ridge is the one nearest the start
	ridge_count = rows.size()
	var lengths: Array[int] = []
	for ridge in rows.size():
		var span := Vector2(ridge_length_min, ridge_length_max)
		if layout != null and layout.kind == MapLayout.Kind.SIDE and layout.short_side:
			span = Vector2(short_side_ridge_length_min, short_side_ridge_length_max)
		elif layout != null and layout.kind == MapLayout.Kind.SIDE:
			span = Vector2(side_ridge_length_min, side_ridge_length_max)
		lengths.append(int(u_inner * rng.randf_range(span.x, span.y)))
	if rows.size() >= 2:
		lengths[0] = mini(maxi(lengths[0], u_inner + 1 - lengths[1]), u_inner - 1)  # Overlap
	var from_low := _u_of(_start) < _u_size() / 2
	for ridge in rows.size():
		# Cells (counted from this ridge's wall) where a gap may open: see the bend rule above.
		var gaps_from := lengths[ridge]
		if ridge == 0 and rows.size() >= 2 and not (layout != null and layout.kind == MapLayout.Kind.SIDE):
			gaps_from = u_inner - lengths[1] + BEND_DEPTH  # Well inside where the second ridge lies past it
		elif ridge >= 2:
			gaps_from = 0
		_ridge(rng, rows[ridge], from_low, lengths[ridge], gaps_from, skip_cells, obstacles)
		from_low = not from_low

func _inlet_ridges(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	var u_inner := _u_size() - 2
	var from_low := _u_of(_start) == 0  # The spine hangs from the shared edge
	var a := _v_of(_start)
	var b := _v_of(_end)
	var spine_v := clampi((a + b) / 2 + rng.randi_range(-1, 1), mini(a, b) + 3, maxi(a, b) - 3)
	var spine_length := int(u_inner * rng.randf_range(spine_length_min, spine_length_max))
	_ridge(rng, spine_v, from_low, spine_length, spine_length, skip_cells, obstacles)  # No gaps
	ridge_count = 1
	var extras := rng.randi_range(0, 1) + (blight_extra_ridges if MetaRun.blight_level >= 9 else 0)
	var halves: Array[int] = [a, b]
	if rng.randf() < 0.5:
		halves.reverse()
	for extra in mini(extras, 2):
		# From the far wall, halfway between the spine and the start or the Heartwood: the route has to
		# climb over its tip on the way round.
		var side: int = halves[extra]
		var v := (side + spine_v) / 2
		if absi(v - spine_v) < 3 or absi(v - side) < 2:
			continue
		# Capped so a passage of 2+ cells stays between its tip and the spine's: their bands can touch.
		var length := mini(int(u_inner * rng.randf_range(0.3, 0.5)), u_inner - spine_length - 2)
		if length < 3:
			continue
		_ridge(rng, v, not from_low, length, 0, skip_cells, obstacles)
		ridge_count += 1

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
	# Past the tip the ridge breaks up: strays with open cells between them. They aren't ridge cells:
	# everything just past the tip is open, so the route already passes the solid part, and carving may
	# clear a stray rather than break a ridge.
	var i := length - 1
	for stray in rng.randi_range(ridge_stray_min, ridge_stray_max):
		i += rng.randi_range(ridge_stray_gap_min, ridge_stray_gap_max) + 1
		var u := 1 + i if from_low else u_inner - i
		var cell := _cell(u, v_base + rng.randi_range(-1, 1))
		if u < 1 or u > u_inner or skip_cells.has(cell) or obstacles.has(cell):
			continue
		_place_obstacle(rng, cell, rock_obstacle if rng.randf() < rock_share else tree_obstacle, obstacles)

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
		var radius := rng.randf_range(rock_cluster_radius_min, rock_cluster_radius_max)
		var reach := ceili(radius)
		for dx in range(-reach, reach + 1):
			for dy in range(-reach, reach + 1):
				var cell := center + Vector2(dx, dy)
				var distance := Vector2(dx, dy).length()
				if distance > radius or skip_cells.has(cell) or obstacles.has(cell) \
						or not MAP_GRID.is_within_bounds(cell):
					continue
				if rng.randf() < 1.0 - distance / (radius + 1.0):
					_place_obstacle(rng, cell, rock_obstacle, obstacles)

# Up to `count` rows, sorted, each at least `ridge_min_spacing` from the others and the walls.
func _pick_ridge_rows(rng: RandomNumberGenerator, count: int, across: int) -> Array[int]:
	var first := ridge_min_spacing
	var last := across - 1 - ridge_min_spacing
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
	if data.cleared_source_id >= 0:
		set_cell(Vector2i(cell), data.cleared_source_id, data.cleared_tile)
	else:
		erase_cell(Vector2i(cell))

# Decorations the path wears away when it's drawn over them (ground details, clearing marks). Obstacles,
# the start's mist and the island's rim are never worn: obstacles are blocked, so no path lies on them.
const WORN_BY_PATH: Array[int] = [EnvironmentTiles.GROUND_DETAILS, EnvironmentTiles.TENDED_STUMP,
	EnvironmentTiles.MOVED_HOLLOW]

# The path now runs over `cell`: erase any decoration there. It stays bare if the path moves away.
func wear_away(cell: Vector2i) -> void:
	if get_cell_source_id(cell) in WORN_BY_PATH:
		erase_cell(cell)


# Share of the cells in the noise's detail band that get a detail: one on every such cell lined the
# ground up into a dotted grid.
const DETAIL_SHARE := 0.3

# Sprinkles grass details (decoration only) on cells not in `skip_cells`. Call after generate_obstacles().
func generate_details(rng: RandomNumberGenerator, skip_cells: PackedVector2Array) -> void:
	var noise: FastNoiseLite = noise_texture.noise
	for x in MAP_GRID.size.x:
		for y in MAP_GRID.size.y:
			var cell := Vector2(x, y)
			if skip_cells.has(cell):
				continue
			var value := noise.get_noise_2d(x, y)
			if value > _tree_level and value <= _detail_level and rng.randf() < DETAIL_SHARE:
				var details := tile_set.get_source(EnvironmentTiles.GROUND_DETAILS) as TileSetAtlasSource
				set_cell(Vector2i(cell), EnvironmentTiles.GROUND_DETAILS,
					Vector2i(rng.randi_range(0, details.get_atlas_grid_size().x - 1), 0))

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
	for x in range(0, last.x + 1):
		for y in range(0, last.y + 1):
			var cell := Vector2i(x, y)
			if (x != 0 and y != 0 and x != last.x and y != last.y) or cell == startPath or cell == endPath:
				continue
			set_cell(cell, EnvironmentTiles.ISLAND_EDGE, Vector2i(EnvironmentTiles.rim_mask(cell, last + Vector2i.ONE), 0))
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
	if layout == null:
		return
	for attempt in 80:
		var cells := _feature_shape(rng, layout.feature)
		if cells.is_empty() or not cells.all(func(c: Vector2) -> bool: return _feature_cell_ok(c, skip, obstacles)):
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
			MapLayout.Feature.RUIN:
				for cell in cells:  # Standing stones, cairns and ruined waystones
					_place_obstacle_tile(cell, rock_obstacle, Vector2i(RUIN_STONES[rng.randi_range(0, RUIN_STONES.size() - 1)], 0), obstacles)
			_:
				for cell in cells:
					_place_obstacle(rng, cell, tree_obstacle, obstacles)
		feature_cells.assign(cells)
		return

# The feature's cells around a random spot (before checking they're free).
func _feature_shape(rng: RandomNumberGenerator, feature: MapLayout.Feature) -> Array[Vector2]:
	var at := Vector2(rng.randi_range(2, int(MAP_GRID.size.x) - 3), rng.randi_range(2, int(MAP_GRID.size.y) - 3))
	var cells: Array[Vector2] = []
	match feature:
		MapLayout.Feature.POND:  # A 2×2 to 3×3 patch of water
			var side := rng.randi_range(2, 3)
			for dx in side:
				for dy in side:
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
		MapLayout.Feature.LOG:  # A short straight line of trees (a fallen log, until it has its own art)
			var along := Vector2(1, 0) if rng.randf() < 0.5 else Vector2(0, 1)
			for i in rng.randi_range(3, 4):
				cells.append(at + along * i)
	return cells

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

func _place_obstacle_tile(cell: Vector2, data: ObstacleData, tile: Vector2i, obstacles: Dictionary) -> void:
	set_cell(Vector2i(cell), data.source_id, tile)
	obstacles[cell] = data
