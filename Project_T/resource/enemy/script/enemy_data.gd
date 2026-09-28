extends Resource
class_name EnemyData

@export var display_name: String = "Creature"
@export var health: int  # The health of the enemy (at drift 1; grows each drift unless `is_boss`)
@export var speed: float  # The movement speed of the enemy, in pixels per second (64 px = 1 cell)
@export var sprite_frames: SpriteFrames  # The animation to play for the enemy's movement
@export var dew_reward: int = 3  # Dew dropped when this creature is cleansed
@export var leaf_cost: int = 1  # Leaves lost when it reaches the Heartwood (big 2, bosses 5)
@export var is_boss: bool = false  # Bosses have fixed health: no per-drift growth
@export var sprite_scale: float = 1.0  # Drawn bigger/smaller (e.g. bosses, Puffcaplets)
@export var tint: Color = Color.WHITE  # Placeholder recolour until a creature has its own art
@export var trait_text: String = ""  # One line for the hover panel, e.g. "Sprints down long straight corridors."
@export var cleanse_line: String = ""  # Shown when cleansed (bosses), e.g. "The Old Stag remembers the way home."

# Movement / boss trait (documentation/acts_1_2.md, acts_3_4.md).
enum Trait { NONE, FLYING, ROLLING, TRAMPLE, LEAP, BURROW, WANDER }
@export var trait_kind: Trait = Trait.NONE

@export_group("Trait")
# ROLLING (Hedgehog): after `roll_after_tiles` straight tiles, moves at `roll_speed` until a turn.
@export var roll_after_tiles: int = 3
@export var roll_speed: float = 192.0  # px/s (3 cells/s)
# TRAMPLE (Old Stag): every `trample_interval` s knocks down an adjacent Thornwall (for good),
# up to `trample_max` per trip. At half health it's startled: ×`charge_speed_multiplier` for
# `charge_time` s (once).
@export var trample_interval: float = 10.0
@export var trample_max: int = 3
@export var charge_speed_multiplier: float = 1.5
@export var charge_time: float = 4.0
# LEAP (Great Toad): every `leap_interval` s (`leap_interval_hurt` below half health) leaps
# `leap_tiles` ahead along its path; creatures within `leap_splash_radius` cells of the landing get Damp.
@export var leap_interval: float = 6.0
@export var leap_interval_hurt: float = 4.0
@export var leap_tiles: int = 3
@export var leap_splash_radius: float = 1.0
# BURROW (Gravecrawler): sinks under a Warden or wall next to it and surfaces on the other side, up
# to `burrow_max` times per trip, when that's at least `burrow_min_saving` cells shorter.
@export var burrow_max: int = 1
@export var burrow_min_saving: int = 2
# WANDER (Sleepwalker): at a cell beside a dead-end pocket, `wander_chance` to walk into it (up to
# `wander_depth` cells) and back, then at least `wander_cooldown_cells` cells before the next one.
@export var wander_chance: float = 0.35
@export var wander_depth: int = 4
@export var wander_cooldown_cells: int = 5
# FLYING: weaves up to this many cells either side of its straight line (Moth Queen; 0 = straight).
@export var flight_weave: float = 0.0

@export_group("Presence")
# Hidden in fog (Lurker): untargetable unless a Warden is within 1.5 cells, a Marking Warden has
# it in range, or a Will-o'-Wisp is near.
@export var hidden: bool = false
@export var reveal_radius: float = 0.0  # Cells; reveals hidden nightmares near it (Will-o'-Wisp)
@export var wake_radius: float = 0.0  # Cells; clears Drowsy from nightmares near it (Watcher)
@export var mend_radius: float = 0.0  # Cells; heals other nightmares near it (Weeper)
@export var mend_rate: float = 0.0  # Share of their max health per second
@export var ash_trail_time: float = 0.0  # Seconds its trail burns; clears Spored from nightmares on it (Ash Crawler)
@export var always_damp: bool = false  # Drowned One
@export var ignores_slows: bool = false  # Drowned One: Damp / Drowsy / auras never slow it
@export var steals_dew: int = 0  # Dew taken when it reaches the Heartwood (Dream Thief)

@export_group("Boss")
# Moth Queen: every `brood_interval` s drops a `brood` onto the nearest path cell. At half health,
# Eclipse: every nightmare (not bosses) is hidden for `eclipse_time` s unless revealed.
@export var brood: EnemyData
@export var brood_interval: float = 4.0
@export var eclipse_time: float = 0.0
# Hollow Oak: every `sapling_interval` s plants `sapling` on an empty cell beside the path ahead.
# Saplings are obstacles (never closing the path) that wither when the Oak is dispelled.
@export var sapling: ObstacleData
@export var sapling_interval: float = 8.0
@export var sapling_frames: SpriteFrames  # The sapling's "grow" / "idle" / "wither" animation
# Grief: at each health share in `grief_at`, stops `grief_pause` s and `grief_count` `grief_spawn`
# rise in a ring around it.
@export var grief_spawn: EnemyData
@export var grief_count: int = 0
@export var grief_at: Array[float] = []
@export var grief_pause: float = 2.0
# From this Blight Level, the first dispel doesn't count: it rises at half health, saplings twice as
# fast (0 = never).
@export var rises_from_blight: int = 0

@export_group("Followers")
# Mother Duck: spawns `follower_count` `followers` right behind her in single file. If she's
# cleansed first, they get lost and slow to `lost_speed`.
@export var followers: EnemyData
@export var follower_count: int = 0
@export var follower_spacing: float = 0.35  # Seconds between each follower setting off
@export var lost_speed: float = 45.0  # px/s (0.7 cells/s)

@export_group("Split")
# When cleansed, this many `split_into` creatures pop out and keep walking (e.g. Puffcap).
@export var split_into: EnemyData
@export var split_count: int = 0

# See documentation/enemy_design.md, "Resistances". Never makes a creature immune to soothe.
@export_group("Resistances")
# Warden families (TowerData.line: spore, stone, water, light, root). Sprout, wall and acorn are
# neutral and never resisted.
@export var resists: Array[String] = []
@export var weak_to: Array[String] = []
# Attack shape (Bee Swarm): single-target = projectile without splash, chain, Static bolt;
# area = splash, pulse, cloud, Spored.
@export var single_target_multiplier: float = 1.0
@export var area_multiplier: float = 1.0
# Blight coat (Badger): each hit loses `coat_per_hit` soothe (min 1) until the coat has soaked up
# `coat_total`, then it crumbles for good. Both scale with the creature's health_scale.
@export var coat_per_hit: int = 0
@export var coat_total: int = 0
@export var cracked_frames: SpriteFrames  # Swapped in once the coat breaks (Shellbound's cracked shell)
# Statuses that don't take (e.g. &"held", &"drowsy"), and {status id: duration multiplier}.
@export var status_immune: Array[StringName] = []
@export var status_duration_multipliers: Dictionary = {}

const RESIST_MULTIPLIER := 0.5
const WEAK_MULTIPLIER := 1.5

# Soothe multiplier for a hit from Warden family `line` (area or single-target).
func get_soothe_multiplier(line: String, is_area: bool) -> float:
	var multiplier := area_multiplier if is_area else single_target_multiplier
	if line in resists:
		multiplier *= RESIST_MULTIPLIER
	elif line in weak_to:
		multiplier *= WEAK_MULTIPLIER
	return multiplier
