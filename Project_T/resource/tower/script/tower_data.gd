extends Resource
class_name TowerData

# PROJECTILE fires at the "first" target (optionally splashing); PULSE soothes every creature in
# range at once; CHAIN is instant lightning that jumps between creatures; CLOUD leaves a lingering
# cloud on the target's path tile that soothes and applies its status to creatures inside.
enum AttackKind { PROJECTILE, PULSE, CHAIN, CLOUD }

const ATTACKS_JSON := "res://assets/towers/attacks.json"

@export var id: String = ""  # Unique id (Dream prerequisites, unlocks). Empty = the .tres file name
@export var display_name: String = "Tower"  # Name shown in the UI
@export_multiline var description: String = ""  # One line for the Warden panel
@export var cost: int = 10  # Dew cost to build
@export var texture: Texture2D  # Tower sprite; leave empty to draw a placeholder block
@export var frame_count: int = 1  # Idle-loop frames laid out in one row of `texture`
@export var animation_fps: float = 6.0
@export var placeholder_color: Color = Color(0.55, 0.55, 0.6)  # Placeholder block colour when there's no texture

@export_group("Evolution")
@export var line: String = ""  # sprout, wall, spore, light, water, stone, root, acorn (Dream tags)
@export var tier: int = 0  # 0 Sprout/Thornwall, 1 base, 2 branch, 3 final form
@export var buildable_directly: bool = true  # Branches and final forms only come from evolving
@export var evolve_cost: int = 0  # Dew to grow into this Warden from the one before it
# TowerData resources this can grow into. Typed as Resource because a script whose export is an
# array of its own class never gets freed (leaks at exit).
@export var evolves_to: Array[Resource] = []

@export_group("Attack")
@export var can_attack: bool = true
@export var attack_range: float = 2.5  # Reach in cells, measured from the tower's centre
@export var damage: int = 20  # Soothe dealt per hit
@export var attacks_per_second: float = 1.0
@export var splash_radius: float = 0.0  # Cells; > 0 = projectile soothes everything near where it lands
@export var projectile_speed: float = 400.0  # Pixels per second
@export var projectile_texture: Texture2D  # Row of frames drawn pointing right; empty = coloured puff
@export var projectile_frames: int = 4
@export var projectile_color: Color = Color(0.85, 0.6, 1.0)  # Placeholder puff colour

@export_group("Status")
@export var applies_status: StringName = &""  # damp, drowsy, spored, marked, static (EnemyStatuses)
@export var status_stacks: int = 1
@export var status_duration: float = 0.0  # 0 = the status's default
@export var status_max_stacks: int = 0  # 0 = the status's default (Driftspore: 12 Spored)

@export_group("Chain")
@export var chain_targets: int = 3  # Creatures hit per strike (the first plus jumps)
@export var chain_jump_range: float = 1.5  # Cells between jumps
@export var storm_every: int = 0  # Every Nth attack strikes every Damp creature in range (Thunderhead)

@export_group("Cloud")
@export var cloud_radius: float = 0.7  # Cells
@export var cloud_duration: float = 3.0
@export var cloud_fog: bool = false  # Mistveil fog: Spored ticks harder inside

@export_group("Attack animation")
@export var attack_kind: AttackKind = AttackKind.PROJECTILE
@export var attack_texture: Texture2D  # Row of frames (wind up, release, settle); empty = no animation
@export var attack_frame_count: int = 6
@export var attack_release_frame: int = 2  # Frame on which the shot / pulse happens
@export var attack_animation_fps: float = 12.0  # Sped up if needed to fit between attacks
# Where projectiles spawn (or the pulse's centre), in pixels from the tower's centre. Read from
# `attacks.json` (key `art_id`) when it has a point, so regenerated art stays aligned.
@export var attack_origin: Vector2 = Vector2.ZERO
@export var art_id: String = ""

var _origin_from_json = null  # Cached attacks.json point (Vector2), or false when it has none

func get_id() -> String:
	return id if id != "" else resource_path.get_file().get_basename()

func get_attack_origin() -> Vector2:
	if _origin_from_json == null:
		_origin_from_json = _read_attack_point(art_id if art_id != "" else get_id())
	return _origin_from_json if _origin_from_json is Vector2 else attack_origin

# Region of `texture` holding idle frame `frame`.
func get_frame_rect(frame: int) -> Rect2:
	var size := Vector2(texture.get_width() / float(frame_count), texture.get_height())
	return Rect2(Vector2(size.x * frame, 0), size)

# The attack point for `key` in attacks.json, relative to the frame centre, or false.
static func _read_attack_point(key: String):
	if not FileAccess.file_exists(ATTACKS_JSON):
		return false
	var json = JSON.parse_string(FileAccess.get_file_as_string(ATTACKS_JSON))
	if typeof(json) != TYPE_DICTIONARY or not json.get("wardens", {}).has(key):
		return false
	var point = json.wardens[key].get("point")
	if not (point is Array and point.size() == 2):
		return false
	var half: float = json.get("frame_size", 64) / 2.0
	return Vector2(point[0] - half, point[1] - half)
