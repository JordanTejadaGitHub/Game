extends RefCounted
# Callings (documentation/dream_council_review.md, section 11): the family taken at the run's FIRST family
# pick is the run's class. It brings one built-in rule, kept all run; later families bring none.
# DreamState.calling holds the family root's id ("" = none: dev runs, old saves). Tower calls the hooks
# below; each returns at once unless its Calling is the run's. No class_name: Tower preloads this file.

# Family root id -> its line (a Calling covers the whole line: branches and final forms too).
const LINES := {"sporeling": "spore", "firefly_jar": "light", "dewdrop": "water", "bellflower": "song",
	"acorn": "acorn", "nestling": "wing", "pebbling": "stone", "rootling": "root", "whirligig": "wind"}
const NAMES := {"sporeling": "Take Root", "firefly_jar": "Lantern Light", "dewdrop": "Splashback",
	"bellflower": "Ringing", "acorn": "Volley", "nestling": "Perches", "pebbling": "Lodged Stone",
	"rootling": "Anvil", "whirligig": "Tailwind"}
const TEXTS := {
	"sporeling": "When {spored} on a nightmare is half full, it is {held} for 1.5 seconds. Once per nightmare.",
	"firefly_jar": "Nightmares in a Firefly Warden's glow are Lit. When any Warden dispels a Lit nightmare, by hit, poison or cloud, half its hit forks to the nearest Lit nightmare. Your Firefly cards make forks bigger, further and more often.",
	"dewdrop": "The first hit on a {damp} nightmare from another {family} also splashes the nightmares beside it.",
	"bellflower": "Each {warden:bellflower} pulse adds to every status a nightmare already has: a tenth of that status's {full} {stacks}.",
	"acorn": "Every 5th acorn, all Wardens next to the {warden:acorn} attack its target at once.",
	"nestling": "A {warden:nestling}'s bird can also swoop from any of your Wardens within 3 cells, and its hit adds that Warden's status.",
	"pebbling": "A {warden:pebbling}'s stone lodges in its target. The next hit from another kind of Warden knocks it into the nightmare behind.",
	"rootling": "Every Warden in range turns to a {held} nightmare, and their hits on it add twice as much status.",
	"whirligig": "Attacks that pass through a {warden:whirligig}'s range go further: shots fly on to a second nightmare, and pulses and splashes spread 1 cell wider.",
}

# Starting numbers (Balancing sets the final ones).
const TAKE_ROOT_SHARE := 0.5  # Of the Poisoned cap
const TAKE_ROOT_TIME := 1.5
const TAKE_ROOT_BOSS_TIME := 0.75
const SPLASHBACK_SHARE := 0.5  # Of the hit, to each nightmare beside it
const SPLASHBACK_CELLS := 1.0
const RINGING_SHARE := 0.1  # Of each status's cap, per pulse
const VOLLEY_EVERY := 5
const PERCH_CELLS := 3.0
const ANVIL_STACKS := 2
const TAILWIND_SHARE := 0.6  # Of the shot, to the second nightmare
const TAILWIND_CELLS := 2.0  # How far the shot flies on from where it landed
const TAILWIND_WIDER := 1.0  # Cells: pulses and splashes
const ZONE_REFRESH_FRAMES := 20  # The line's Wardens are listed again this often (planting, selling, growing)

const ROOTED_META := &"calling_rooted"
const SPLASHED_META := &"calling_splashed"
const PERCH_META := &"calling_perch"
const VOLLEY_META := &"calling_volley"

static var _zone_frame := -1
static var _zone_line := ""
static var _zone: Array = []  # The Calling line's Wardens on the map

static func title(family: String) -> String:
	return String(NAMES.get(family, ""))

static func text(family: String) -> String:
	return String(TEXTS.get(family, ""))

static func line_of(family: String) -> String:
	return String(LINES.get(family, ""))

# The run's Calling ("" = none).
static func of(tower) -> String:
	return tower._dream_state.calling if tower._dream_state != null else ""

static func _cell() -> float:
	return Tower.MAP_GRID.cell_size.x

# The Wardens of the Calling's line on the map (refreshed every ZONE_REFRESH_FRAMES frames, for all callers).
static func zone(tower, line: String) -> Array:
	var frame := Engine.get_process_frames()
	if line != _zone_line or frame - _zone_frame >= ZONE_REFRESH_FRAMES or frame < _zone_frame:
		_zone_line = line
		_zone_frame = frame
		_zone = []
		for other in tower.get_tree().get_nodes_in_group(Tower.GROUP):
			if is_instance_valid(other) and not other.is_queued_for_deletion() and other.tower_data != null \
					and other.tower_data.line == line:
				_zone.append(other)
	return _zone

# The nearest Warden of `line` whose reach covers `at` (not `skip`), or null.
static func zone_warden_at(tower, line: String, at: Vector2, skip = null):
	var best = null
	var best_distance := INF
	for other in zone(tower, line):
		if other == skip or not is_instance_valid(other) or other.is_queued_for_deletion():
			continue
		var distance: float = other.global_position.distance_to(at)
		if distance <= other.get_range_pixels() and distance < best_distance:
			best_distance = distance
			best = other
	return best

static func _living(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_cleansed and enemy.health > 0


# --- After a hit landed (Tower.hit) ---------------------------------------------------------------------

# `dealt` is the hit's damage before the nightmare's defences. `effect_tick`: a status tick or Reaction, never a hit.
static func after_hit(tower, enemy, dealt: float, is_area: bool, effect_tick: bool, combo: StringName) -> void:
	var calling := of(tower)
	if calling == "" or effect_tick or combo == &"splashback" or combo == &"tailwind":
		return
	match calling:
		"dewdrop":
			_splashback(tower, enemy, dealt)
		"bellflower":
			if is_area and tower.tower_data.line == "song" and tower.attack_data.attack_kind == TowerData.AttackKind.PULSE:
				_ringing(enemy)
		"nestling":
			_perch_status(tower, enemy)

# (Lantern Ring, the first Firefly Calling, is retired: its always-on Charged is gone. Lantern Light lives in
# scripts/combat/firefly_lights.gd, which listens to damage events itself: nothing here calls it.)

# Splashback: once per Soaking, another family's hit splashes onto the nightmares beside the Soaked one.
static func _splashback(tower, enemy, dealt: float) -> void:
	if tower.tower_data.line == "water" or dealt <= 0.0 or not is_instance_valid(enemy) \
			or not enemy.statuses.has(EnemyStatuses.DAMP):
		return
	var soaking: int = enemy.statuses.lifecycle_serial(EnemyStatuses.DAMP)
	if enemy.has_meta(SPLASHED_META) and int(enemy.get_meta(SPLASHED_META)) == soaking:
		return
	enemy.set_meta(SPLASHED_META, soaking)
	var at: Vector2 = enemy.global_position
	var reach := SPLASHBACK_CELLS * _cell()
	var any := false
	for other in Tower.nightmares_near(tower.get_tree(), at, reach):
		if other == enemy or not _living(other) or other.global_position.distance_to(at) > reach:
			continue
		other.take_damage(dealt * SPLASHBACK_SHARE, tower.tower_data.line, true, false, tower, &"splashback")
		any = true
	if any:
		Reactions._effect(&"landing_dust", at, tower, SPLASHBACK_CELLS)

# Ringing: a Bellflower-line pulse adds a tenth of the cap to every stacking status the nightmare carries,
# keeping each status's own applier (its credit and Potency).
static func _ringing(enemy) -> void:
	if not _living(enemy):
		return
	var statuses: EnemyStatuses = enemy.statuses
	for id in statuses.active_ids():
		if id == EnemyStatuses.HELD or not _living(enemy) or not statuses.has(id):
			continue
		var cap: int = statuses.get_max_stacks(id)
		if cap <= 1 or statuses.stacks(id) >= cap:
			continue
		var more := maxi(roundi(cap * RINGING_SHARE), 1)
		var source = statuses.source(id)
		var line: String = source.tower_data.line if is_instance_valid(source) and "tower_data" in source else ""
		enemy.apply_status(id, more, statuses.time_left(id), statuses.potency(id), 0, line, source)

# Perches: a bird that swooped from another Warden adds 1 stack of that Warden's status (never a "native" one).
static func _perch_status(tower, enemy) -> void:
	if tower.tower_data.line != "wing" or not tower.has_meta(PERCH_META) or not _living(enemy):
		return
	var perch = tower.get_meta(PERCH_META).get(enemy.get_instance_id())
	perch = perch.get_ref() if perch is WeakRef else null
	if is_instance_valid(perch) and perch.attack_data != null and perch.attack_data.applies_status != &"" \
			and perch.attack_data.applies_status != EnemyStatuses.HELD:
		perch._apply_one_status(enemy, perch.attack_data.applies_status, 1, perch.get_damage(), false)


# --- Take Root (Sporeling) ----------------------------------------------------------------------------

# After a Warden applied Poisoned: at half the cap the nightmare is Rooted, once (bosses half as long).
static func take_root(tower, enemy) -> void:
	if of(tower) != "sporeling" or not _living(enemy) or enemy.has_meta(ROOTED_META):
		return
	var statuses: EnemyStatuses = enemy.statuses
	if statuses.stacks(EnemyStatuses.SPORED) < statuses.get_max_stacks(EnemyStatuses.SPORED) * TAKE_ROOT_SHARE:
		return
	enemy.set_meta(ROOTED_META, true)
	tower.hold(enemy, TAKE_ROOT_BOSS_TIME if statuses.is_boss else TAKE_ROOT_TIME)


# --- Anvil (Rootling) ---------------------------------------------------------------------------------

# Aim: a Rooted nightmare in reach comes first, unless the player chose this Warden's target mode.
static func aims_at_rooted(tower, enemy) -> bool:
	return of(tower) == "rootling" and not tower.target_chosen and enemy.statuses.is_held()

# Stacks a status hit adds on `enemy` (double on a Rooted one).
static func anvil_stacks(tower, enemy, status: StringName, stacks: int) -> int:
	if stacks <= 0 or status == EnemyStatuses.HELD or of(tower) != "rootling" or not enemy.statuses.is_held():
		return stacks
	return stacks * ANVIL_STACKS


# --- Volley (Acorn) -----------------------------------------------------------------------------------

# An Acorn-line aura Warden released an attack of its own: every VOLLEY_EVERY-th, the Wardens in its aura
# attack at once (aiming Wardens at its target). A volley's forced attacks never count toward the next one.
static func volley_release(tower, target) -> void:
	if of(tower) != "acorn" or tower.tower_data.line != "acorn":
		return
	if tower.tower_data.aura_damage_bonus <= 0.0 and tower.tower_data.aura_speed_bonus <= 0.0:
		return  # Only the line's aura Wardens conduct (Acorn, Elder Stump, Grove Heart, Grandmother Oak)
	if tower.has_meta(VOLLEY_META) and bool(tower.get_meta(VOLLEY_META)):
		tower.set_meta(VOLLEY_META, false)  # This attack was itself part of a volley
		return
	var count := int(tower.get_meta(&"calling_volley_count", 0)) + 1
	tower.set_meta(&"calling_volley_count", count % VOLLEY_EVERY)
	if count < VOLLEY_EVERY:
		return
	var reach: float = tower.get_aura_reach() * _cell() + _cell() * 0.5
	for other in tower.get_tree().get_nodes_in_group(Tower.GROUP):
		if other == tower or not is_instance_valid(other) or other.is_queued_for_deletion() or other.tower_data == null \
				or not other.tower_data.can_attack or other.global_position.distance_to(tower.global_position) > reach:
			continue
		other.volley_now(target)
	Reactions._effect(&"landing_dust", tower.global_position, tower, tower.get_aura_reach())


# --- Perches (Nestling) -------------------------------------------------------------------------------

# Whether this Warden's birds use perches (projectile birds: the Nestling, Wren's Nest, Magpies, Starlings).
static func uses_perches(tower) -> bool:
	return of(tower) == "nestling" and tower.tower_data.line == "wing" and tower.attack_data != null \
		and tower.attack_data.attack_kind == TowerData.AttackKind.SWOOP

# The nightmares the bird can reach from its nest or from any Warden within PERCH_CELLS (its own range from
# each). Remembers which perch reaches each one (the nest itself first), for the launch spot and the status.
static func perch_targets(tower) -> Array[Node2D]:
	var result: Array[Node2D] = tower.get_enemies_in_range()
	var seen := {}
	for enemy in result:
		seen[enemy.get_instance_id()] = true
	var perches := {}
	var range_squared: float = tower.get_range_pixels() ** 2
	var near := PERCH_CELLS * _cell()
	for other in tower.get_tree().get_nodes_in_group(Tower.GROUP):
		if other == tower or not is_instance_valid(other) or other.is_queued_for_deletion() \
				or other.global_position.distance_to(tower.global_position) > near:
			continue
		for enemy in Tower.nightmares_near(tower.get_tree(), other.global_position, tower.get_range_pixels()):
			if not _living(enemy) or seen.has(enemy.get_instance_id()):
				continue
			if other.global_position.distance_squared_to(enemy.global_position) <= range_squared:
				seen[enemy.get_instance_id()] = true
				perches[enemy.get_instance_id()] = weakref(other)
				result.append(enemy)
	tower.set_meta(PERCH_META, perches)
	return result

# Where the bird launches from for `target`: its perch, or null for the nest.
static func perch_for(tower, target):
	if target == null or not tower.has_meta(PERCH_META):
		return null
	var perch = tower.get_meta(PERCH_META).get(target.get_instance_id())
	perch = perch.get_ref() if perch is WeakRef else null
	return perch if is_instance_valid(perch) else null


# --- Tailwind (Whirligig) -----------------------------------------------------------------------------

# Whether a shot from `from` to `to` passes through a wind Warden's reach (not the shooter's own).
static func shot_in_tailwind(tower, from: Vector2, to: Vector2) -> bool:
	if of(tower) != "whirligig":
		return false
	for wind in zone(tower, "wind"):
		if wind == tower or not is_instance_valid(wind) or wind.is_queued_for_deletion():
			continue
		var closest := Geometry2D.get_closest_point_to_segment(wind.global_position, from, to)
		if closest.distance_to(wind.global_position) <= wind.get_range_pixels():
			return true
	return false

# Cells a pulse or splash from `tower` spreads further (it stands inside another wind Warden's reach).
static func tailwind_wider(tower) -> float:
	if of(tower) != "whirligig":
		return 0.0
	return TAILWIND_WIDER if zone_warden_at(tower, "wind", tower.global_position, tower) != null else 0.0

# The second nightmare a wind-carried shot flies on to from `where` (never `first`), or null.
static func tailwind_next(tower, first, where: Vector2) -> Node2D:
	var reach := TAILWIND_CELLS * _cell()
	var best: Node2D = null
	var best_distance := INF
	for enemy in Tower.nightmares_near(tower.get_tree(), where, reach):
		if enemy == first or not _living(enemy):
			continue
		var distance: float = where.distance_to(enemy.global_position)
		if distance <= reach and distance < best_distance:
			best_distance = distance
			best = enemy
	return best
