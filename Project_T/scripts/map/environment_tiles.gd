class_name EnvironmentTiles
extends RefCounted

# The environment art (assets/environment/<act folder>/, layouts in documentation/environment_assets.md)
# as one TileSet that every map layer shares: one atlas source per sheet, with fixed source ids.
# Every act folder has the same files, so the season changes by swapping each source's texture
# (set_act); tiles keep their source id and coords.

const SIZE := Vector2i(64, 64)
const FRAMES := 4  # Animated sheets: FRAMES columns per row, at FPS
const FPS := 4.0
const ROOT := "res://assets/environment/"
const ACT_FOLDERS: Array[String] = ["forest_edge", "deep_wood", "misty_hollow", "heartwood_glade"]

# Source ids.
const GRASS := 0  # 8 variants
const PATH := 1  # Column = neighbour mask (N=1, E=2, S=4, W=8)
const WITHERED_TREE := 3  # Animated, 9 dead trees (rows)
const TENDED_STUMP := 4
const MOSSY_BOULDER := 5  # 9 rocks
const MOVED_HOLLOW := 6
const EDGE_MIST := 7  # Animated overlay
const GROUND_DETAILS := 11  # Mushrooms, ferns, pebbles, leaf litter
const WAYSTONE := 12  # Special tiles (design plan §9): art only, no rules yet
const DEW_POOL := 13
const BLIGHT_PATCH := 14
const ISLAND_EDGE := 15  # The island's rim: column = neighbour mask of island cells (N=1, E=2, S=4, W=8)
const CLIFF := 16  # Under the bottom row: column bit 1 = cliff to the west, bit 2 = to the east; rows = variants
const ROPE_BRIDGE := 17  # Shared (dream/): column 0 = east-west, 1 = north-south
const PATH_RIM := 18  # path.png's art, transparent outside the path: for the start and goal, over the rim
# (Ids 2 and 8-10 were the drystone wall and healthy trees; the island and the void replaced them.)

const SHEETS := {
	GRASS: "grass", PATH: "path", WITHERED_TREE: "withered_tree",
	TENDED_STUMP: "tended_stump", MOSSY_BOULDER: "mossy_boulder", MOVED_HOLLOW: "moved_hollow",
	EDGE_MIST: "edge_mist", GROUND_DETAILS: "ground_details", WAYSTONE: "waystone",
	DEW_POOL: "dew_pool", BLIGHT_PATCH: "blight_patch", ISLAND_EDGE: "island_edge", CLIFF: "cliff", PATH_RIM: "path_rim",
}
# The dream's outer layer, the same in every act (assets/environment/dream/).
const DREAM_FOLDER := "dream"
const SHARED_SHEETS := {ROPE_BRIDGE: "rope_bridge"}
const ANIMATED: Array[int] = [WITHERED_TREE, EDGE_MIST, WAYSTONE, DEW_POOL, BLIGHT_PATCH]
# Sheets whose cells are bigger than a map cell (withered_tree.png: 96×128, overhanging the cell above and its sides).
const TALL := {WITHERED_TREE: Vector2i(96, 128)}
# Animated tiles start at a random point per cell (so a field of them never pulses in step), and
# each dead-tree type (row) runs at its own pace with uneven frame timing: one frame held, one quick.
const TREE_SPEEDS: Array[float] = [0.8, 0.95, 0.7, 0.85, 0.6, 1.1, 0.75, 0.9, 0.65]
const TREE_FRAME_WEIGHTS: Array[float] = [1.6, 0.8, 0.6, 1.0]  # Rotated by row

# The Heartwood (goal): 128x128 frames, FRAMES per row, row = leaves lost (0..HEARTWOOD_STATES-1).
const HEARTWOOD := "heartwood"
const HEARTWOOD_SIZE := 128
const HEARTWOOD_STATES := 21


static func sheet_path(sheet: String, act: int) -> String:
	return ROOT + ACT_FOLDERS[clampi(act, 1, ACT_FOLDERS.size()) - 1] + "/" + sheet + ".png"

static func shared_path(sheet: String) -> String:
	return ROOT + DREAM_FOLDER + "/" + sheet + ".png"

static func create_tile_set(act: int = 1) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = SIZE
	for id: int in SHEETS.keys() + SHARED_SHEETS.keys():
		var source := TileSetAtlasSource.new()
		source.texture = load(sheet_path(SHEETS[id], act) if SHEETS.has(id) else shared_path(SHARED_SHEETS[id]))
		var region: Vector2i = TALL.get(id, SIZE)
		source.texture_region_size = region
		var grid := source.get_atlas_grid_size()
		if id in ANIMATED:
			for row in grid.y:
				var coords := Vector2i(0, row)
				source.create_tile(coords)
				source.set_tile_animation_frames_count(coords, FRAMES)
				source.set_tile_animation_mode(coords, TileSetAtlasSource.TILE_ANIMATION_MODE_RANDOM_START_TIMES)
				for frame in FRAMES:
					var weight := TREE_FRAME_WEIGHTS[(frame + row) % FRAMES] if id == WITHERED_TREE else 1.0
					source.set_tile_animation_frame_duration(coords, frame, weight / FPS)
				if id == WITHERED_TREE:
					source.set_tile_animation_speed(coords, TREE_SPEEDS[row % TREE_SPEEDS.size()])
				_anchor_bottom(source, coords, region)
		else:
			for row in grid.y:
				for column in grid.x:
					source.create_tile(Vector2i(column, row))
					_anchor_bottom(source, Vector2i(column, row), region)
		tile_set.add_source(source, id)
	return tile_set

# A big tile (96×128) puts its bottom 64 px rows on its own cell, centred; the rest overhangs the cells around.
static func _anchor_bottom(source: TileSetAtlasSource, coords: Vector2i, region: Vector2i) -> void:
	if region.y > SIZE.y:
		source.get_tile_data(coords, 0).texture_origin = Vector2i(0, (region.y - SIZE.y) / 2)

# Swaps every sheet for act `act`'s season.
static func set_act(tile_set: TileSet, act: int) -> void:
	for id: int in SHEETS:
		(tile_set.get_source(id) as TileSetAtlasSource).texture = load(sheet_path(SHEETS[id], act))

# The island-edge rim tile for a border cell: which neighbours are island (N=1, E=2, S=4, W=8).
static func rim_mask(cell: Vector2i, map_size: Vector2i) -> int:
	var last := map_size - Vector2i.ONE
	return ((1 if cell.y > 0 else 0) | (2 if cell.x < last.x else 0) | (4 if cell.y < last.y else 0)
		| (8 if cell.x > 0 else 0))

# Path tile for a neighbour mask (N=1, E=2, S=4, W=8).
static func path_tile(mask: int) -> Vector2i:
	return Vector2i(mask, 0)

# A stable pseudo-random pick per cell, so redraws don't reshuffle variants.
static func cell_variant(cell: Vector2i, count: int, salt: int = 0) -> int:
	return posmod(hash(Vector3i(cell.x, cell.y, salt)), count)
