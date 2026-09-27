extends Resource
class_name TowerData

@export var display_name: String = "Tower"  # Name shown in the UI
@export var cost: int = 10  # Gold cost to build (no economy yet)
@export var texture: Texture2D  # Tower sprite; leave empty to draw a placeholder block
@export var placeholder_color: Color = Color(0.55, 0.55, 0.6)  # Placeholder block colour when there's no texture
