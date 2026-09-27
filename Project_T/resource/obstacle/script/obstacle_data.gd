extends Resource
class_name ObstacleData

# Something on the map that blocks creatures and building until the player pays to clear it
# (trees, rocks). Drawn as a random tile from `tiles` on the EnvironmentObject layer.

@export var display_name: String = "Obstacle"  # Name shown when hovering it
@export var clear_verb: String = "Clear"  # Action shown in the hover label, e.g. "Tend", "Move"
@export var clear_cost: int = 5  # Dew cost to clear
@export var source_id: int = 0  # EnvironmentTiles source (sheet) the tiles are on
@export var tiles: Array[Vector2i] = []  # Atlas coords on that sheet; one is picked per cell
@export var cleared_source_id: int = -1  # Walkable mark left when the player clears it (-1 = none)
@export var cleared_tile: Vector2i = Vector2i.ZERO
