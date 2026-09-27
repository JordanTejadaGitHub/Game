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

# Movement / boss trait (documentation/acts_1_2.md).
enum Trait { NONE, FLYING, ROLLING, TRAMPLE, LEAP }
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
