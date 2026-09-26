extends TileMapLayer
class_name GroundGenerator

const TILE_MAP_LOCATION_DATA = preload("res://resource/map/tile_map_location_data.tres")
const MAP_GRID = preload("res://resource/map/map_grid.tres")

# Creates the ground layer, including the playable area and the outer grass layer
func initialize() -> void:
	_generate_grass()

# Generate grass for both the playable area and the outer layer
func _generate_grass() -> void:
	for x in range(-2, MAP_GRID.size.x + 2):
		for y in range(-2, MAP_GRID.size.y + 2):
			var position = Vector2i(x, y)

			# Place grass tiles
			if x >= 0 and x < MAP_GRID.size.x and y >= 0 and y < MAP_GRID.size.y:
				# Inside playable area
				set_cell(position, 0, TILE_MAP_LOCATION_DATA.tile_grass)
			else:
				# Outside playable area
				set_cell(position, 0, TILE_MAP_LOCATION_DATA.tile_grass)
