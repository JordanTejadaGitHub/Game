extends TileMapLayer
class_name EnvironmentObjectGenerator

const TILE_MAP_LOCATION_DATA = preload("res://resource/map/tile_map_location_data.tres")
const MAP_GRID = preload("res://resource/map/map_grid.tres")
const SOURCE_ID := 2
@export var noise_texture: NoiseTexture2D
@export var tree_obstacle: ObstacleData = preload("res://resource/obstacle/tree.tres")
@export var rock_obstacle: ObstacleData = preload("res://resource/obstacle/rock.tres")
@export_group("Trees")
# Share of the noise range that becomes trees; each map rolls a value in this range.
@export_range(0.0, 0.6) var tree_density_min: float = 0.14
@export_range(0.0, 0.6) var tree_density_max: float = 0.3
# Each map scales the noise frequency by a random factor in this range: low = big groves, high = small copses.
@export var tree_cluster_scale_min: float = 0.7
@export var tree_cluster_scale_max: float = 1.4
@export_group("Rocks")
@export_range(0.0, 1.0) var rock_chance: float = 0.02  # Chance for any free cell to get a lone rock
@export var rock_cluster_count_min: int = 2
@export var rock_cluster_count_max: int = 7
@export var rock_cluster_radius_min: float = 1.0  # In cells
@export var rock_cluster_radius_max: float = 2.5
@export_group("Ridges")
# Ridges are wobbly lines of rocks and trees running in from the left or right wall. They make the
# starting route snake back and forth; clearing one of their cells opens a shortcut.
@export var ridge_count_min: int = 2
@export var ridge_count_max: int = 5
@export_range(0.1, 1.0) var ridge_length_min: float = 0.55  # Fraction of the map's width (>0.5 so opposite ridges overlap)
@export_range(0.1, 1.0) var ridge_length_max: float = 0.85
@export var ridge_min_spacing: int = 5  # Rows between ridge centres (and walls); ridges span ±1, so keep >= 4
@export_range(0.0, 1.0) var ridge_wander_chance: float = 0.3  # Per cell: step up/down a row (max 1 from its base)
@export_range(0.0, 1.0) var ridge_thicken_chance: float = 0.2  # Per cell: add a second cell above/below
@onready var path_tile_map_layer: PathGenerator = %PathTileMapLayer

var unwalkable_cells: PackedVector2Array
# Cells that belong to a ridge (set of Vector2 -> true), so route carving can avoid breaking them.
var ridge_cells: Dictionary = {}

const grass_details: Array[Vector2i] = [
	TILE_MAP_LOCATION_DATA.tile_grass_detail1,
	TILE_MAP_LOCATION_DATA.tile_grass_detail2
]

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
	_generate_outer_layer_of_rocks()
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
	return obstacles

# Wobbly ridges on well-spaced rows, each attached to the left or right wall (alternating, so the
# route has to zig-zag between their open ends). Each ridge has its own rock/tree mix. Diagonal
# wobbles still block: creatures only move up/down/left/right.
# The first ridge sits on the start's side: the route is pushed across, and the next ridge forces
# it back. Starting on the far side would let the route slip past both without doubling back.
func _generate_ridges(rng: RandomNumberGenerator, skip_cells: PackedVector2Array, obstacles: Dictionary) -> void:
	var inner_width := int(MAP_GRID.size.x) - 2  # Columns between the side walls
	var rows := _pick_ridge_rows(rng, rng.randi_range(ridge_count_min, ridge_count_max))
	var from_left := _start_on_left
	for base_row in rows:
		var length := int(inner_width * rng.randf_range(ridge_length_min, ridge_length_max))
		var rock_share := rng.randf()
		var row := base_row
		for i in length:
			if rng.randf() < ridge_wander_chance:
				row = clampi(row + (1 if rng.randf() < 0.5 else -1), base_row - 1, base_row + 1)
			var x := 1 + i if from_left else inner_width - i
			_place_ridge_cell(rng, Vector2(x, row), rock_share, skip_cells, obstacles)
			if rng.randf() < ridge_thicken_chance:
				# Thicken within the ridge's band (base row ±1) so neighbouring ridges never touch.
				var side := 1 if rng.randf() < 0.5 else -1
				if absi(row + side - base_row) > 1:
					side = -side
				_place_ridge_cell(rng, Vector2(x, row + side), rock_share, skip_cells, obstacles)
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

# Up to `count` distinct rows, sorted, each at least `ridge_min_spacing` from the others and the walls.
func _pick_ridge_rows(rng: RandomNumberGenerator, count: int) -> Array[int]:
	var first := ridge_min_spacing
	var last := int(MAP_GRID.size.y) - 1 - ridge_min_spacing
	var rows: Array[int] = []
	for attempt in 200:
		if rows.size() >= count:
			break
		var row := rng.randi_range(first, last)
		var too_close := false
		for other in rows:
			if absi(other - row) < ridge_min_spacing:
				too_close = true
				break
		if not too_close:
			rows.append(row)
	rows.sort()
	return rows

func _place_obstacle(rng: RandomNumberGenerator, cell: Vector2, data: ObstacleData, obstacles: Dictionary) -> void:
	set_cell(Vector2i(cell), SOURCE_ID, data.tiles[rng.randi_range(0, data.tiles.size() - 1)])
	obstacles[cell] = data

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
				set_cell(Vector2i(cell), SOURCE_ID, grass_details[rng.randi_range(0, grass_details.size() - 1)])

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

func _generate_border(startPath: Vector2i, endPath: Vector2i) -> void:
	var corners = {
		"topRightCorner" = Vector2i(MAP_GRID.size.x - 1, 0),
		"topLeftCorner" = Vector2i(0,0),
		"bottomLeftCorner" = Vector2i(0,MAP_GRID.size.y - 1),
		"bottomRightCorner" = Vector2i(MAP_GRID.size.x - 1, MAP_GRID.size.y - 1)
	}
	
	for x in MAP_GRID.size.x:
		var topCell: Vector2i = Vector2i(x,0)
		var bottomCell: Vector2i = Vector2i(x, MAP_GRID.size.y - 1)
		
		if topCell != startPath and topCell != endPath:
			var tileType: Vector2i
			if topCell == corners.topLeftCorner:
				tileType = TILE_MAP_LOCATION_DATA.tile_corner_left_down_stone_border
			elif topCell == corners.topRightCorner:
				tileType = TILE_MAP_LOCATION_DATA.tile_corner_right_down_stone_border
			else:
				tileType = TILE_MAP_LOCATION_DATA.tile_top_middle_stone_border
			set_cell(topCell, 2, tileType)
			unwalkable_cells.append(topCell)
		if bottomCell != startPath and bottomCell != endPath:
			var tileType: Vector2i
			if bottomCell == corners.bottomLeftCorner:
				tileType = TILE_MAP_LOCATION_DATA.tile_corner_left_up_stone_border
			elif bottomCell == corners.bottomRightCorner:
				tileType = TILE_MAP_LOCATION_DATA.tile_corner_right_up_stone_border
			else:
				tileType = TILE_MAP_LOCATION_DATA.tile_bottom_middle_stone_border
			set_cell(bottomCell, 2, tileType)
			unwalkable_cells.append(bottomCell)
	
	for y in MAP_GRID.size.y:
		var leftCell: Vector2i = Vector2i(0,y)
		var rightCell: Vector2i = Vector2i(MAP_GRID.size.x - 1, y)
		
		if leftCell != startPath and leftCell != endPath and !corners.values().has(leftCell):
			var tileType = TILE_MAP_LOCATION_DATA.tile_left_middle_stone_border
			set_cell(leftCell, 2, tileType)
			unwalkable_cells.append(leftCell)
		if rightCell != startPath and rightCell != endPath and !corners.values().has(rightCell):
			var tileType = TILE_MAP_LOCATION_DATA.tile_right_middle_stone_border
			set_cell(rightCell, 2, tileType)
			unwalkable_cells.append(rightCell)

func _generate_outer_layer_of_rocks() -> void:
	var outer_corners = {
		"topRightCorner" = Vector2i(MAP_GRID.size.x, -1),
		"topLeftCorner" = Vector2i(-1, -1),
		"bottomLeftCorner" = Vector2i(-1, MAP_GRID.size.y),
		"bottomRightCorner" = Vector2i(MAP_GRID.size.x, MAP_GRID.size.y)
	}

	# Generate the top and bottom rows outside the map
	for x in range(-1, MAP_GRID.size.x + 1):
		var topCell: Vector2i = Vector2i(x, -1)
		var bottomCell: Vector2i = Vector2i(x, MAP_GRID.size.y)

		if topCell in outer_corners.values():
			pass  # Corners will be handled later
		else:
			var tileType: Vector2i = TILE_MAP_LOCATION_DATA.tile_top_middle_stone_border
			if x == -1:
				tileType = TILE_MAP_LOCATION_DATA.tile_top_left_stone_border
			elif x == MAP_GRID.size.x:
				tileType = TILE_MAP_LOCATION_DATA.tile_top_right_stone_border
			set_cell(topCell, 2, tileType)
			unwalkable_cells.append(topCell)

		if bottomCell in outer_corners.values():
			pass  # Corners will be handled later
		else:
			var tileType: Vector2i = TILE_MAP_LOCATION_DATA.tile_bottom_middle_stone_border
			if x == -1:
				tileType = TILE_MAP_LOCATION_DATA.tile_bottom_left_stone_border
			elif x == MAP_GRID.size.x:
				tileType = TILE_MAP_LOCATION_DATA.tile_bottom_right_stone_border
			set_cell(bottomCell, 2, tileType)
			unwalkable_cells.append(bottomCell)

	# Generate the left and right columns outside the map
	for y in range(-1, MAP_GRID.size.y + 1):
		var leftCell: Vector2i = Vector2i(-1, y)
		var rightCell: Vector2i = Vector2i(MAP_GRID.size.x, y)

		if leftCell in outer_corners.values():
			pass  # Corners will be handled later
		else:
			var tileType = TILE_MAP_LOCATION_DATA.tile_left_middle_stone_border
			if y == -1:
				tileType = TILE_MAP_LOCATION_DATA.tile_top_left_stone_border
			elif y == MAP_GRID.size.y:
				tileType = TILE_MAP_LOCATION_DATA.tile_bottom_left_stone_border
			set_cell(leftCell, 2, tileType)
			unwalkable_cells.append(leftCell)

		if rightCell in outer_corners.values():
			pass  # Corners will be handled later
		else:
			var tileType = TILE_MAP_LOCATION_DATA.tile_right_middle_stone_border
			if y == -1:
				tileType = TILE_MAP_LOCATION_DATA.tile_top_right_stone_border
			elif y == MAP_GRID.size.y:
				tileType = TILE_MAP_LOCATION_DATA.tile_bottom_right_stone_border
			set_cell(rightCell, 2, tileType)
			unwalkable_cells.append(rightCell)

	# Generate the corners
	set_cell(outer_corners["topLeftCorner"], 2, TILE_MAP_LOCATION_DATA.tile_corner_left_down_stone_border)
	set_cell(outer_corners["topRightCorner"], 2, TILE_MAP_LOCATION_DATA.tile_corner_right_down_stone_border)
	set_cell(outer_corners["bottomLeftCorner"], 2, TILE_MAP_LOCATION_DATA.tile_corner_left_up_stone_border)
	set_cell(outer_corners["bottomRightCorner"], 2, TILE_MAP_LOCATION_DATA.tile_corner_right_up_stone_border)

	unwalkable_cells.append_array(outer_corners.values())
