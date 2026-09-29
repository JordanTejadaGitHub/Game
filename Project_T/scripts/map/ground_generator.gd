extends TileMapLayer
class_name GroundGenerator

const MAP_GRID = preload("res://resource/map/map_grid.tres")
# Share of cells per grass variant: 0 plain, 1 tufts, 2 flowers, 3 clover, 4 tufts, 5 pebbles, 6 tufts, 7 fallen twig (kept rare).
const GRASS_WEIGHTS: Array[float] = [0.3, 0.15, 0.08, 0.07, 0.14, 0.1, 0.12, 0.04]

# Creates the ground layer: grass inside the island's rim (the rim tiles carry their own grass, and the
# void shows around them)
func initialize() -> void:
	_generate_grass()

# Every variant tiles with every other, so each cell just rolls one.
func _generate_grass() -> void:
	for x in range(1, MAP_GRID.size.x - 1):
		for y in range(1, MAP_GRID.size.y - 1):
			var cell := Vector2i(x, y)
			set_cell(cell, EnvironmentTiles.GRASS, Vector2i(_grass_variant(cell), 0))

func _grass_variant(cell: Vector2i) -> int:
	var roll := EnvironmentTiles.cell_variant(cell, 1000) / 1000.0
	for i in GRASS_WEIGHTS.size():
		roll -= GRASS_WEIGHTS[i]
		if roll < 0.0:
			return i
	return 0
