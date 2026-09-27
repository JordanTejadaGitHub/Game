extends Resource
class_name TowerData

@export var display_name: String = "Tower"  # Name shown in the UI
@export var cost: int = 10  # Dew cost to build (no economy yet)
@export var texture: Texture2D  # Tower sprite; leave empty to draw a placeholder block
@export var placeholder_color: Color = Color(0.55, 0.55, 0.6)  # Placeholder block colour when there's no texture

@export_group("Attack")
@export var attack_range: float = 2.5  # Reach in cells, measured from the tower's centre
@export var damage: int = 20  # Soothe dealt per hit
@export var attacks_per_second: float = 1.0
@export var projectile_speed: float = 400.0  # Pixels per second
@export var projectile_color: Color = Color(0.85, 0.6, 1.0)  # Placeholder puff colour
