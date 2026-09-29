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

@export_group("Dossier")
# Boss dossier (screens_ui.md): the boss's title ("the gaunt king of the old wood"), one entry per
# ability {"name", "icon" (IconInfo id), "text", "when"} and 2–3 `tips` (no numbers, never a
# solution). Text and "when" put numbers in as {field} tokens read from this resource (see
# format_text), so they follow the data; status tokens like {damp} are left for IconInfo.format.
@export var title: String = ""
@export var whisper: String = ""  # The dossier header's line (story.md), e.g. "The Hollow Stag has found the dream."
@export var abilities: Array[Dictionary] = []
@export var tips: Array[String] = []
# New nightmare introduction (screens_ui.md): 1–2 plain lines on what it does ({field} tokens for
# numbers, as in abilities; read them with get_intro_lines) and one hint in the boss-tip voice.
@export var intro_lines: Array[String] = []
@export var hint: String = ""
# Trait icon for FLYING: &"through_walls" (Phantom, glides through them) or &"flying" (Moth Queen).
@export var flying_icon: StringName = &"through_walls"

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
# Statuses that don't take while it sprints (Night Hound: Held; ROLLING trait only).
@export var immune_while_sprinting: Array[StringName] = []
@export var status_duration_multipliers: Dictionary = {}

const RESIST_MULTIPLIER := 0.5
const WEAK_MULTIPLIER := 1.5
const BOSS_HELD_SHARE := 0.5  # Holds last half as long on bosses (Tower.ROOTED_BOSS_TIME, freezes)

# Everything the UI shows about how this nightmare takes damage and statuses (nightmare info, boss
# dossier, "Coming this block"):
#   resists / weak_to   Warden families (TowerData.line), ×RESIST_MULTIPLIER / ×WEAK_MULTIPLIER
#   immune              status ids that never take (shown crossed out)
#   conditional         {status id: "while sprinting"}: immune only at those times (crossed out + label)
#   shorter             {status id: duration share} for statuses that wear off faster (shown "½")
#   traits              trait icon ids: through_walls / flying, hidden, dread_shell, always_damp,
#                       ignores_slows, sprints, burrows, wanders, splits
#   single_target / area   attack-shape multipliers when not 1 (Whisper Swarm)
func get_defences() -> Dictionary:
	var shorter := status_duration_multipliers.duplicate()
	if is_boss and not &"held" in status_immune:
		shorter[&"held"] = BOSS_HELD_SHARE
	var traits: Array[StringName] = []
	match trait_kind:
		Trait.FLYING:
			traits.append(flying_icon)
		Trait.ROLLING:
			traits.append(&"sprints")
		Trait.BURROW:
			traits.append(&"burrows")
		Trait.WANDER:
			traits.append(&"wanders")
	if hidden:
		traits.append(&"hidden")
	if coat_total > 0:
		traits.append(&"dread_shell")
	if always_damp:
		traits.append(&"always_damp")
	if ignores_slows:
		traits.append(&"ignores_slows")
	if split_into != null and split_count > 0:
		traits.append(&"splits")
	var conditional := {}
	if trait_kind == Trait.ROLLING:
		for id in immune_while_sprinting:
			conditional[id] = "while sprinting"
	var result := {"resists": resists.duplicate(), "weak_to": weak_to.duplicate(),
		"immune": status_immune.duplicate(), "conditional": conditional, "shorter": shorter, "traits": traits}
	if single_target_multiplier != 1.0:
		result["single_target"] = single_target_multiplier
	if area_multiplier != 1.0:
		result["area"] = area_multiplier
	return result

# The nightmares this one brings with it (for "It brings"): [{"data": EnemyData, "count": int,
# "how": "follows" | "when dispelled" | "every N s" | "at 67% and 33% health"}]. Drift escorts
# (the boss drift's other arrivals) come from the drift data, not from here.
func get_summons() -> Array:
	var summons := []
	if followers != null and follower_count > 0:
		summons.append({"data": followers, "count": follower_count, "how": "follows"})
	if split_into != null and split_count > 0:
		summons.append({"data": split_into, "count": split_count, "how": "when dispelled"})
	if brood != null:
		summons.append({"data": brood, "count": 1, "how": format_text("every {brood_interval} s")})
	if grief_spawn != null and grief_count > 0:
		summons.append({"data": grief_spawn, "count": grief_count, "how": format_text("at {grief_at:list_pct} health")})
	return summons

# Ability text with this resource's numbers filled in: {field} → its value ({leap_tiles} → "3",
# {brood_interval} → "4"), {field:pct} → "50%", {field:plus_pct} → "+50%" (a multiplier),
# {field:list_pct} → "67% and 33%", {field:name} → a linked resource's display_name. Tokens that
# aren't fields of this resource (status tokens like {damp}) are left for IconInfo.format.
func format_text(text: String) -> String:
	if not text.contains("{"):
		return text
	var token := RegEx.create_from_string("\\{(\\w+)(?::(\\w+))?\\}")
	var fields := {}
	for property in get_property_list():
		fields[property.name] = true
	var result := text
	for found in token.search_all(text):
		var field := found.get_string(1)
		if not fields.has(field):
			continue
		result = result.replace(found.get_string(), _format_value(get(field), found.get_string(2)))
	return result

static func _format_value(value: Variant, style: String) -> String:
	match style:
		"pct":
			return "%d%%" % roundi(float(value) * 100.0)
		"plus_pct":
			return "+%d%%" % roundi((float(value) - 1.0) * 100.0)
		"list_pct":
			var parts: Array[String] = []
			for share in value:
				parts.append("%d%%" % roundi(float(share) * 100.0))
			return " and ".join(parts) if parts.size() <= 2 else ", ".join(parts)
		"name":
			return value.display_name if value is EnemyData or value is ObstacleData else str(value)
	if value is float:
		return str(roundi(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value
	return str(value)

# The intro card's lines with their numbers filled in (status tokens stay for IconInfo).
func get_intro_lines() -> Array[String]:
	var lines: Array[String] = []
	for line in intro_lines:
		lines.append(format_text(line))
	return lines

# An ability entry with its numbers filled in (see format_text); status tokens stay for IconInfo.
func get_ability(index: int) -> Dictionary:
	var ability: Dictionary = abilities[index].duplicate()
	ability["text"] = format_text(ability.get("text", ""))
	ability["when"] = format_text(ability.get("when", ""))
	return ability

# Soothe multiplier for a hit from Warden family `line` (area or single-target).
func get_soothe_multiplier(line: String, is_area: bool) -> float:
	var multiplier := area_multiplier if is_area else single_target_multiplier
	if line in resists:
		multiplier *= RESIST_MULTIPLIER
	elif line in weak_to:
		multiplier *= WEAK_MULTIPLIER
	return multiplier
