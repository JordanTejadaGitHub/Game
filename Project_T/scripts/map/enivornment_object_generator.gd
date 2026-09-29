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
var _start_on_left := true

func initialize(startPath: Vector2i, endPath: Vector2i) -> PackedVector2Array:
	_start_on_left = startPath.x < MAP_GRID.size.x / 2
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
	_compute_noise_levels(noise, rng.randf_range(tree_density_min, tree_density_max))

	var obstacles := {}
	_generate_ridges(rng, skip_cells, obstacles)
	_generate_rock_clusters(rng, skip_cells, obstacles)
	for x in MAP_GRID.size.x:
		for y in MAP_GRID.size.y:
			var cell := Vector2(x, y)
			if skip_cells.has(cell) or obstacles.has(cell):
				continue
			if noise.get_noise_2d(x, y) <= _tree_level:
				_place_obstacle(rng, cell, tree_obstacle, obstacles)
			elif rng.randf() < rock_chance:
				_place_obstacle(rng, cell, rock_obstacle, obstacles)
	_fill_to_minimum(rng, skip_cells, obstacles)
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

# Wobbly ridges on well-spaced rows, each attached to the left or right wall (alternating, so the
# route has to zig-zag between their open ends). Each ridge has its own rock/tree mix. Diagonal
# wobbles still block: creatures only move up/down/left/right.
# The first ridge sits on the start's side: the route is pushed across, and the next ridge forces
# it back. Starting on the far side would let the route slip past both without doubling back.
# One bend is guaranteed (game_design.md "The forest (map)"): the second ridge has no gaps, the first
# only has gaps where the second lies below it, and the two always overlap. Any way down past the first
# then lands above the second's solid part and has to double back. Later ridges (Blight 9) gap freely.
func _generate_ridges(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	var inner_width := int(MAP_GRID.size.x) - 2  # Columns between the side walls
	var count := rng.randi_range(ridge_count_min, ridge_count_max)
	if MetaRun.blight_level >= 9:
		count += blight_extra_ridges  # Blight Level 9: one extra ridge
	var rows := _pick_ridge_rows(rng, count)
	ridge_count = rows.size()
	var lengths: Array[int] = []
	for ridge in rows.size():
		lengths.append(int(inner_width * rng.randf_range(ridge_length_min, ridge_length_max)))
	if rows.size() >= 2:
		lengths[0] = mini(maxi(lengths[0], inner_width + 1 - lengths[1]), inner_width - 1)  # Overlap
	var from_left := _start_on_left
	for ridge in rows.size():
		var base_row := rows[ridge]
		var length := lengths[ridge]
		var rock_share := rng.randf()
		# Columns (counted from this ridge's wall) where a gap may open: see the bend rule above.
		var gaps_from := length
		if ridge == 0 and rows.size() >= 2:
			gaps_from = inner_width - lengths[1]  # Where the second ridge lies below
		elif ridge >= 2:
			gaps_from = 0
		var root_end := roundi(length * ridge_root_fraction)
		var tip_start := length - roundi(length * ridge_tip_fraction)
		var row := base_row
		for i in length:
			if rng.randf() < ridge_wander_chance:
				row = clampi(row + (1 if rng.randf() < 0.5 else -1), base_row - 1, base_row + 1)
			if i >= maxi(root_end, gaps_from) and rng.randf() < ridge_gap_chance:
				continue  # A gap: this column of the ridge is left open
			var x := 1 + i if from_left else inner_width - i
			_place_ridge_cell(rng, Vector2(x, row), rock_share, skip_cells, obstacles)
			if i < root_end:
				# Root: a thicket or outcrop across the whole band, not a solid block.
				for other in range(base_row - 1, base_row + 2):
					if other != row and rng.randf() < ridge_root_fill_chance:
						_place_ridge_cell(rng, Vector2(x, other), rock_share, skip_cells, obstacles)
			elif i < tip_start and rng.randf() < ridge_middle_fill_chance:
				# Middle: one neighbouring row, kept inside the band.
				var side := 1 if rng.randf() < 0.5 else -1
				if absi(row + side - base_row) > 1:
					side = -side
				_place_ridge_cell(rng, Vector2(x, row + side), rock_share, skip_cells, obstacles)
		# Past the tip the ridge breaks up: strays with open columns between them. They aren't ridge cells:
		# every column before the first stray is open, so the route already passes the solid part (the
		# zig-zag holds), and carving may clear a stray rather than break a ridge.
		var i := length - 1
		for stray in rng.randi_range(ridge_stray_min, ridge_stray_max):
			i += rng.randi_range(ridge_stray_gap_min, ridge_stray_gap_max) + 1
			var x := 1 + i if from_left else inner_width - i
			var cell := Vector2(x, base_row + rng.randi_range(-1, 1))
			if x < 1 or x > inner_width or skip_cells.has(cell) or obstacles.has(cell):
				continue
			_place_obstacle(rng, cell, rock_obstacle if rng.randf() < rock_share else tree_obstacle, obstacles)
		from_left = not from_left

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
func _pick_ridge_rows(rng: RandomNumberGenerator, count: int) -> Array[int]:
	var first := ridge_min_spacing
	var last := int(MAP_GRID.size.y) - 1 - ridge_min_spacing
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


# Sprinkles grass details (decoration only) on cells not in `skip_cells`. Call after generate_obstacles().
func generate_details(rng: RandomNumberGenerator, skip_cells: PackedVector2Array) -> void:
	var noise: FastNoiseLite = noise_texture.noise
	for x in MAP_GRID.size.x:
		for y in MAP_GRID.size.y:
			var cell := Vector2(x, y)
			if skip_cells.has(cell):
				continue
			var value := noise.get_noise_2d(x, y)
			if value > _tree_level and value <= _detail_level:
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
			var mask := (1 if y > 0 else 0) | (2 if x < last.x else 0) | (4 if y < last.y else 0) | (8 if x > 0 else 0)
			set_cell(cell, EnvironmentTiles.ISLAND_EDGE, Vector2i(mask, 0))
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