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

const RESIST_MULTIPLIER := 0.65
const WEAK_MULTIPLIER := 1.35

# Soothe multiplier for a hit from Warden family `line` (area or single-target).
func get_soothe_multiplier(line: String, is_area: bool) -> float:
	var multiplier := area_multiplier if is_area else single_target_multiplier
	if line in resists:
		multiplier *= RESIST_MULTIPLIER
	elif line in weak_to:
		multiplier *= WEAK_MULTIPLIER
	return multiplier
