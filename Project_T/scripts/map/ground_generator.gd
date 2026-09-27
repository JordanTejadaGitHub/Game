extends TileMapLayer
class_name GroundGenerator

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const MARGIN := 10  # Grass beyond the map, under the outer forest
# Share of cells per grass variant (plain, tufts, flowers, clover), as on the concept page.
const GRASS_WEIGHTS: Array[float] = [0.5, 0.22, 0.16, 0.12]

# Creates the ground layer, including the playable area and the outer grass layer
func initialize() -> void:
	_generate_grass()

# Every variant tiles with every other, so each cell just rolls one.
func _generate_grass() -> void:
	for x in range(-MARGIN, MAP_GRID.size.x + MARGIN):
		for y in range(-MARGIN, MAP_GRID.size.y + MARGIN):
			var cell := Vector2i(x, y)
			set_cell(cell, EnvironmentTiles.GRASS, Vector2i(_grass_variant(cell), 0))

func _grass_variant(cell: Vector2i) -> int:
	var roll := EnvironmentTiles.cell_variant(cell, 1000) / 1000.0
	for i in GRASS_WEIGHTS.size():
		roll -= GRASS_WEIGHTS[i]
		if roll < 0.0:
			return i
	return 0
