extends Resource
class_name TowerData

enum AttackKind { PROJECTILE, PULSE }

@export var display_name: String = "Tower"  # Name shown in the UI
@export var cost: int = 10  # Dew cost to build
@export var texture: Texture2D  # Tower sprite; leave empty to draw a placeholder block
@export var frame_count: int = 1  # Idle-loop frames laid out in one row of `texture`
@export var animation_fps: float = 6.0
@export var placeholder_color: Color = Color(0.55, 0.55, 0.6)  # Placeholder block colour when there's no texture

@export_group("Attack")
@export var can_attack: bool = true  # False for plain walls (Thornwall)
@export var attack_range: float = 2.5  # Reach in cells, measured from the tower's centre
@export var damage: int = 20  # Soothe dealt per hit
@export var attacks_per_second: float = 1.0
@export var projectile_speed: float = 400.0  # Pixels per second
@export var projectile_texture: Texture2D  # Row of frames drawn pointing right; empty = coloured puff
@export var projectile_frames: int = 4
@export var projectile_color: Color = Color(0.85, 0.6, 1.0)  # Placeholder puff colour

@export_group("Attack animation")
# PROJECTILE fires at the "first" target; PULSE soothes every creature in range at once.
@export var attack_kind: AttackKind = AttackKind.PROJECTILE
@export var attack_texture: Texture2D  # Row of frames (wind up, release, settle); empty = no animation
@export var attack_frame_count: int = 6
@export var attack_release_frame: int = 2  # Frame on which the shot / pulse happens
@export var attack_animation_fps: float = 12.0  # Sped up if needed to fit between attacks
# Where projectiles spawn (or the pulse's centre), in pixels from the tower's centre.
@export var attack_origin: Vector2 = Vector2.ZERO

# Region of `texture` holding idle frame `frame`.
func get_frame_rect(frame: int) -> Rect2:
	var size := Vector2(texture.get_width() / float(frame_count), texture.get_height())
	return Rect2(Vector2(size.x * frame, 0), size)
