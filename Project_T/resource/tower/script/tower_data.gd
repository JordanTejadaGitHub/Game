extends Resource
class_name TowerData

# PROJECTILE fires at the "first" target (optionally splashing); PULSE soothes every creature in
# range at once; CHAIN is instant lightning that jumps between creatures; CLOUD leaves a lingering
# cloud on the target's path tile that soothes and applies its status to creatures inside.
# TRAP plants rings on path tiles that burst when stepped on (Fairy Ring); BEAM holds one target and
# ramps up (Sunpetal); COPY uses the strongest adjacent Warden's attack (Graftling); SWOOP sends a
# bird that flies back (Nestling line); SWEEP hits every nightmare on a stretch of path (Starling
# Murmuration); SPREAD copies statuses between nightmares (Gust); SPIN hits the 8 tiles around it
# (Pinwheel); PULL grabs a nightmare and drags it back (Pond Keeper); LIGHT lights path tiles and
# Marks nightmares on them (Rootlight); AURA never attacks but affects everything in range (White Stag).
enum AttackKind { PROJECTILE, PULSE, CHAIN, CLOUD, TRAP, BEAM, COPY, SWOOP, SWEEP, SPREAD, SPIN, PULL, LIGHT, AURA }
# Who a Warden shoots at. FIRST = furthest along the path. Snipers let the player choose.
enum TargetMode { FIRST, STRONGEST, BOSSES, FASTEST }

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

@export_group("Crits and targeting")
@export var crit_chance: float = 0.0  # 0.05 = 5% of hits deal crit_multiplier × damage
@export var crit_multiplier: float = 2.0
@export var crit_bonus_vs_held: float = 0.0  # Extra crit chance against Held nightmares (Hoarfrost)
@export var first_hit_crits: bool = false  # First hit on each nightmare always crits (Moonstone)
@export var target_mode: TargetMode = TargetMode.FIRST
@export var has_target_priority: bool = false  # Player can change target_mode (snipers)
@export var min_range: float = 0.0  # Cells; can't hit nightmares closer than this
# +X damage per cell of distance beyond `distance_bonus_from` cells, up to distance_bonus_max.
@export var distance_bonus_per_cell: float = 0.0
@export var distance_bonus_from: float = 3.0
@export var distance_bonus_max: float = 0.0
# Extra damage against these nightmares (EnemyData file names), and against sprinting ones.
@export var bonus_vs_enemies: Array[String] = []
@export var bonus_vs_sprinting: bool = false
@export var bonus_vs_multiplier: float = 1.0

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

@export_group("Pop")
# Puffball: when a hit leaves a nightmare with pop_at_stacks+ Spored, it pops: pop_damage_per_stack
# × stacks to it and every nightmare within pop_radius cells (area, never crits), its stacks are used
# up, and half of them drift on to up to pop_spread_targets nearby nightmares. 0 = never pops.
@export var pop_at_stacks: int = 0
@export var pop_damage_per_stack: float = 6.0
@export var pop_radius: float = 1.0
@export var pop_spread_targets: int = 3

@export_group("Freeze")
# Hits on nightmares with `freeze_needs` (empty = any) Hold them for freeze_duration s, at most
# once per freeze_cooldown s each (Frostfern, Hoarfrost).
@export var freeze_duration: float = 0.0
@export var freeze_needs: StringName = &"damp"
@export var freeze_cooldown: float = 4.0

@export_group("Trap")
@export var trap_max: int = 4  # Rings out at once
@export var trap_lifetime: float = 10.0  # Seconds; 0 = until stepped on
@export var trap_radius: float = 0.6  # Cells hit by a burst
@export var trap_texture: Texture2D  # Row of 16x16 frames
@export var trap_frames: int = 4

@export_group("Beam")
@export var beam_ramp_per_second: float = 0.25  # +25% damage per second on the same target
@export var beam_ramp_max: float = 4.0  # Damage multiplier cap
@export var beam_behind_share: float = 0.0  # Also hits the nightmare right behind at this share
@export var beam_color: Color = Color(1.0, 0.85, 0.35)

@export_group("Copy")
@export var copy_share: float = 0.6  # Graftling: copies the strongest neighbour's attack at 60%

@export_group("Birds")
@export var projectile_returns: bool = false  # The projectile flies back to the Warden (swoop)
@export var dew_mark: bool = false  # Nightmares it hits drop +1 Dew when dispelled (Magpie Perch)
@export var crit_dew: int = 0  # Dew per crit (Magpie's Hoard)
@export var crit_dew_per_drift: int = 0  # Cap on crit Dew per drift
@export var sweep_tiles: int = 5  # Starling Murmuration: path tiles per sweep

@export_group("Wind")
@export var push_back_tiles: float = 0.0  # Pulse hits push nightmares back this far (Whirligig)
@export var push_cooldown: float = 3.0  # Seconds before the same nightmare can be pushed again
@export var spread_targets: int = 2  # Gust: nightmares that get the copied statuses
@export var spread_radius: float = 1.5  # Cells from the most-afflicted nightmare
@export var spin_free_path_tiles: int = 2  # Pinwheel: +spin_bonus per adjacent path tile beyond this
@export var spin_bonus: float = 0.2
@export var spin_bonus_max: float = 1.0

@export_group("Pull")
@export var pull_boss_tiles: int = 2  # Pond Keeper: bosses only go back this many tiles

@export_group("Aura")
@export var aura_crit_bonus: float = 0.0  # Wardens in range get this much crit chance (White Stag)
@export var range_aura_bonus: float = 0.0  # Wardens within range_aura_radius get +range (Moon Moth)
@export var range_aura_radius: float = 3.0

@export_group("Memory")
# Memory Wardens (from bosses): one per run each, free, can't evolve.
@export var is_unique: bool = false

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
