extends Resource
class_name ObstacleData

# Something on the map that blocks creatures and building until the player pays to clear it
# (trees, rocks). Drawn as a random tile from `tiles` on the EnvironmentObject layer.

@export var display_name: String = "Obstacle"  # Name shown when hovering it
@export var clear_verb: String = "Clear"  # Action shown in the hover label, e.g. "Chop", "Break"
@export var clear_cost: int = 5  # Dew cost to clear
@export var tiles: Array[Vector2i] = []  # Atlas coords on the environment tileset; one is picked per cell
