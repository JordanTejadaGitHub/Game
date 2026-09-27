extends TileMapLayer
class_name EnvironmentObjectGenerator

const TILE_MAP_LOCATION_DATA = preload("res://resource/map/tile_map_location_data.tres")
const MAP_GRID = preload("res://resource/map/map_grid.tres")
@export var noise_texture: NoiseTexture2D
@onready var path_tile_map_layer: PathGenerator = %PathTileMapLayer

var unwalkable_cells: PackedVector2Array

const grass_details: Array[Vector2i] = [
	TILE_MAP_LOCATION_DATA.tile_grass_detail1,
	TILE_MAP_LOCATION_DATA.tile_grass_detail2
]

const trees: Array[Vector2i] = [
	TILE_MAP_LOCATION_DATA.tile_tree1,
	TILE_MAP_LOCATION_DATA.tile_tree2,
	TILE_MAP_LOCATION_DATA.tile_tree3,
	TILE_MAP_LOCATION_DATA.tile_tree4,
	TILE_MAP_LOCATION_DATA.tile_red_tree1,
	TILE_MAP_LOCATION_DATA.tile_red_tree2,
	TILE_MAP_LOCATION_DATA.tile_red_tree3,
	TILE_MAP_LOCATION_DATA.tile_red_tree4,
]

func initialize(startPath: Vector2i, endPath: Vector2i) -> PackedVector2Array:
	_generate_border(startPath, endPath)
	_generate_outer_layer_of_rocks()
	return unwalkable_cells

func generate_details_and_trees(unwalkable_path: PackedVector2Array) -> void:
	var noise = noise_texture.noise
	var noise_val_array: Array[float]
	var noise_color = noise_texture.color_ramp
	unwalkable_cells = unwalkable_path
	
	#Get highest and lowest noise value
	for x in MAP_GRID.size.x:
		for y in MAP_GRID.size.y:
			var noise_val = noise.get_noise_2d(x,y)
			noise_val_array.append(noise_val)
	
	var noise_diff = -noise_val_array.min() + noise_val_array.max()
	var grass_detail_value = (noise_diff * noise_texture.color_ramp.offsets[1]) + noise_val_array.min()
	var empty_value = (noise_diff * noise_texture.color_ramp.offsets[2]) + noise_val_array.min()
	var noise_ind = 0
	#Set cell with object
	for x in MAP_GRID.size.x:
		for y in MAP_GRID.size.y:
			var cell_position = Vector2i(x,y)
			if unwalkable_cells.has(cell_position):
				pass
			#Set tree
			elif noise_val_array[noise_ind] >= noise_val_array.min() and noise_val_array[noise_ind] <= grass_detail_value:
				set_cell(cell_position, 2, trees.pick_random())
			#Set grass detail
			elif noise_val_array[noise_ind] >= grass_detail_value and noise_val_array[noise_ind] <= empty_value:
				set_cell(cell_position, 2, grass_details.pick_random())
			noise_ind += 1 

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
