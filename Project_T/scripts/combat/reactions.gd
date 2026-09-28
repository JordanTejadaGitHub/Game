extends RefCounted
class_name Reactions

# Reactions (tower_design.md "Reactions: combos you can see"; numbers in dream_design.md "Reaction
# numbers"): when two statuses meet on one nightmare, a named event goes off. Enemy.apply_status calls
# on_status() after every status lands; Tower.hit calls before_hit() (Shatter, Pinned); Static bolts
# go through strike_bolt() (Lightning Rod). Reaction damage scales with the applier's damage, counts
# as its family, and never crits. Each type fires on a nightmare at most once per cooldown.
#
# Chains: a Reaction's output (damage, statuses, clouds) marks the nightmares it touches; a Reaction
# on a marked nightmare within CHAIN_WINDOW is the chain's next link. ReactionTracker counts them and
# tells the UI; the visuals are played through scripts/fx/fx.gd when it exists.

const DIR := "res://resource/reaction/"
const CELL := 64.0
const CHAIN_WINDOW := 1.0

const DAMP := &"damp"
const DROWSY := &"drowsy"
const SPORED := &"spored"
const MARKED := &"marked"
const STATIC := &"static"
const HELD := &"held"

const THUNDERCLAP_STATIC := 3
const THUNDERCLAP_STATIC_BOSS := 5
const THUNDERCLAP_DAMAGE := 4.0  # × the applier's damage, to the nightmare that discharges
const THUNDERCLAP_ARC_DAMAGE := 2.0  # × the applier's damage, to each wet nightmare it arcs to
const THUNDERCLAP_REACH: Array[float] = [2.5, 3.5, 4.5]  # Cells: base, Rolling Thunder, Rolling Thunder II
const THUNDERCLAP_ARC_STATIC: Array[int] = [1, 1, 2]
const IGNITE_MIN_SPORES := 3
const IGNITE_MULTIPLIER := 1.5  # × the Spored damage it had left
const IGNITE_SPREAD: Array[int] = [1, 2]  # Stacks: base, Wildfire Spores
const IGNITE_REACH: Array[float] = [1.0, 1.5]
const MUSHROOM_MIN_SPORES := 3
const MUSHROOM_TIME := 4.0
const MUSHROOM_CLOUD_RADIUS := 0.6  # Cells
const MUSHROOM_CLOUD_TIME := 4.0
const MUSHROOM_RAIN_TIME := 2.0  # Mushroom Rain: ×2 duration…
const MUSHROOM_RAIN_RADIUS := 1.5  # …and the 3×3 around its tile (cells from the centre, reaching the corners' middles)
const SHATTER_MULTIPLIER := 2.5
const SHATTER_SPLASH := 0.5  # Share of the hit the shards deal within 1 cell
const DROWN_SLEEP: Array[float] = [2.0, 3.0]  # Seconds: base, Deep Water
const DROWN_BOSS_SLOW: Array[float] = [0.3, 0.4]
const DROWN_TIMES: Array[int] = [1, 1, 2]  # Per nightmare: base, Deep Water, Deep Water II
const PINNED_MULTIPLIER := 3.0
const ROD_REACH := 3.0  # Cells
const ROD_MULTIPLIER := 2.0
const QUICK_COOLDOWN := 0.75  # Quick Reactions
const DAWNBURST_CHAIN := 10
const DAWNBREAK_SHARE := 0.10  # Of max health, to every nightmare within DAWNBREAK_REACH
const DAWNBREAK_BOSS_SHARE := 0.02
const DAWNBREAK_REACH := 4.0

# Crowned Reactions (tower_design.md "Crowned Reactions", dream_design.md "Crowned Reaction numbers"):
# a Reaction on a nightmare that already carries a third status is replaced by a bigger one. It
# shares the base Reaction's cooldown and counts as 2 chain links. [base, Woven card] pairs.
const CROWNED_LINKS := 2
const TEMPEST_LOCK := 2.0  # A nightmare hit by a Tempest can't start another for this long
const TEMPEST_EXTRA_REACH := 1.0  # Eye of the Tempest: cells
const STILL_POOL_TIME: Array[float] = [5.0, 8.0]  # Deep Stillness
const STILL_POOL_SLEEP: Array[float] = [1.0, 1.5]
const FEVER_SPORED := 3
const FEVER_DROWSY := 2
const FEVER_BOSS_DROWSY_CAP := 3
const FEVER_REACH: Array[float] = [1.0, 1.5]  # Fever Pitch
const STARFALL_REACH: Array[float] = [3.0, 5.0]  # Falling Stars
const STARFALL_BOLT := 2.0  # Each pulled bolt ×2, and a crit
const STARFALL_BOSS_BOLT := 1.5
const PRISM_STATIC: Array[int] = [2, 3]  # Prism Heart
const PRISM_REACH: Array[float] = [1.0, 1.5]
const NIGHTBLOOM_TIME: Array[float] = [4.0, 7.0]  # Endless Night
const NIGHTBLOOM_WIDTH: Array[float] = [1.0, 1.5]
const FAIRY_RING_TIME := 6.0
const FAIRY_RING_MAX := 8  # Ring of Rings: rings last until stepped on, at most this many
const STORM_FRONT_REACH := 1.0  # Cells added to a Reaction a Gust-copied status completed
const STORM_FRONT_SECONDS := 0.8  # How long the swirl shows
const CARRIED_SHARE := 0.5  # Carried Storm: a Samara seed repeats a Reaction it passes through at 50%
const CARRIED_WINDOW := 0.5  # Seconds after the Reaction
const CARRIED_REACH := 0.75  # Cells from the Reaction's spot
# The base Reaction each Crowned one replaces (the Codex, sounds and cooldowns use it).
const CROWNED_BASE := {&"tempest": &"thunderclap", &"still_pool": &"drown", &"fever_dream": &"smother",
	&"starfall": &"pinned", &"avalanche": &"shatter", &"prismstorm": &"shatter", &"nightbloom": &"mushrooming",
	&"fairy_circle": &"mushrooming"}

static var _data := {}


# --- Data -------------------------------------------------------------------------------------------

static func get_data(id: StringName) -> ReactionData:
	_load()
	return _data.get(id)

# The base Reactions (the Crowned ones are separate: crowned()).
static func all() -> Array[ReactionData]:
	_load()
	var list: Array[ReactionData] = []
	for id in _data:
		if not is_crowned(id):
			list.append(_data[id])
	return list

# The Crowned Reactions (resource/reaction/crowned/).
static func crowned() -> Array[ReactionData]:
	_load()
	var list: Array[ReactionData] = []
	for id in _data:
		if is_crowned(id):
			list.append(_data[id])
	return list

static func _load() -> void:
	if not _data.is_empty():
		return
	for dir in [DIR, DIR + "crowned/"]:
		for file in ResourceLoader.list_directory(dir):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var data := load(dir + file) as ReactionData
				if data != null:
					_data[data.id] = data


# --- Triggers ---------------------------------------------------------------------------------------

# A status just landed on `enemy` (applied by `source`, a Warden or null). Checks every Reaction.
static func on_status(enemy: Node2D, _id: StringName, source: Node) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	var static_needed := THUNDERCLAP_STATIC_BOSS if s.is_boss else THUNDERCLAP_STATIC
	if s.has(DAMP) and s.stacks(STATIC) >= static_needed:
		_thunderclap(enemy, source)
	if enemy.is_cleansed:
		return
	if s.stacks(SPORED) >= IGNITE_MIN_SPORES and s.has(STATIC):
		_ignite(enemy, source)
	if enemy.is_cleansed:
		return
	if s.stacks(SPORED) >= MUSHROOM_MIN_SPORES and s.has(DAMP):
		_mushrooming(enemy, source)
	if s.has(DAMP) and s.has(DROWSY) and s.stacks(DROWSY) >= s.get_max_stacks(DROWSY):
		_drown(enemy, source)
	if s.has(MARKED) and (s.is_held() or is_asleep(enemy) \
			or (s.has(DROWSY) and s.stacks(DROWSY) >= s.get_max_stacks(DROWSY))):
		_pinned(enemy, source)
	if s.is_held() and s.has(SPORED):
		_smother(enemy, source)

# --- Potency (tower_design.md "Potency: effect damage") ---------------------------------------------

# Damage tags that are effects, not hits: they scale with the source Warden's Potency (and Seeping),
# never with crit (except Nightshade). Shatter's own hit is a hit; its spreads are effects.
const EFFECT_TAGS: Array[StringName] = [&"spored", &"static", &"thunderclap", &"ignite", &"lightning_rod",
	&"popped", &"echo", &"carried_storm", &"avalanche", &"starfall", &"fever_dream", &"fog", &"cloud", &"harmony"]

static func is_effect(tag: StringName) -> bool:
	return tag in EFFECT_TAGS

# Effect damage × the source's Potency × Seeping (1 + 5% per status the nightmare carries).
static func effect_multiplier(enemy: Node2D, source: Tower) -> float:
	var multiplier := source.get_potency()
	var dreams := _dreams(enemy)
	if dreams and dreams.has_method("get_effect_bonus"):
		multiplier *= 1.0 + dreams.get_effect_bonus(enemy) + nightshade_bonus(enemy)  # Seeping + Nightshade add
	elif dreams:
		multiplier *= 1.0 + nightshade_bonus(enemy)
	return multiplier

# Nightshade (Legendary #112): effect damage +20% for every status the nightmare carries (one per
# status, not per stack; every status counts, the one dealing the damage too; no cap). Adds with
# Seeping. 0 without the card. Also shown on the nightmare's info card.
const NIGHTSHADE_PER_STATUS := 0.20

static func nightshade_bonus(enemy: Node2D) -> float:
	var dreams := _dreams(enemy)
	if dreams == null or not dreams.has_rule(&"nightshade"):
		return 0.0
	return NIGHTSHADE_PER_STATUS * enemy.statuses.active_ids().size()

static func is_crowned(id: StringName) -> bool:
	return CROWNED_BASE.has(id)

# Fever Dream: Smother just ended on a nightmare at full Drowsy. Its remaining Spored damage resolves
# at once, and adjacent nightmares get Spored + Drowsy (a sleep plague).
static func on_smother_ended(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	if not s.has(SPORED) or not s.has(DROWSY) or s.stacks(DROWSY) < s.get_max_stacks(DROWSY):
		return
	var spore_source := s.source(SPORED)
	var chain := _fire(enemy, &"fever_dream", _towers(spore_source, s.source(DROWSY)), false, CROWNED_LINKS)
	if chain <= 0:
		return
	var potency := s.potency(SPORED)
	var line := s.spore_line()
	var left := s.stacks(SPORED) * potency * s.time_left(SPORED)
	s.remove(SPORED)
	var dreams := _dreams(enemy)
	var level := 1 if dreams and dreams.has_rule(&"fever_pitch") else 0
	var neighbours := _others_within(enemy, FEVER_REACH[level] + _storm_front(enemy))
	enemy.take_damage(left, line, true, false, spore_source, &"fever_dream")
	for other in neighbours:
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		_touch(other, chain, _towers(spore_source))
		other.apply_status(SPORED, FEVER_SPORED, 0.0, potency, 0, line, spore_source)
		if is_instance_valid(other) and not other.is_cleansed:
			var cap := FEVER_BOSS_DROWSY_CAP if other.statuses.is_boss else 0
			other.apply_status(DROWSY, FEVER_DROWSY, 0.0, 0.0, cap, "song", s.source(DROWSY))

# True if `enemy` can't be Held right now: immune, or a Night Hound sprinting (Enemy.apply_status refuses
# HELD then). Drown, Still Pool and Carried Storm slow it instead.
static func cant_be_held(enemy: Node2D) -> bool:
	if HELD in enemy.statuses.immune:
		return true
	return enemy.rolling and HELD in enemy.enemy_data.immune_while_sprinting

static func is_asleep(enemy: Node2D) -> bool:
	return enemy.statuses.is_asleep()

# Heavy Eyelids: Drowsy cap +2 (Heavy Eyelids II: +3), bosses +1.
static func drowsy_cap_bonus(enemy: Node2D) -> int:
	var dreams := _dreams(enemy)
	if dreams == null or not dreams.has_rule(&"heavy_eyelids"):
		return 0
	if enemy.enemy_data.is_boss:
		return 1
	return 3 if dreams.rule_level(&"heavy_eyelids") > 0 else 2

# Before a Warden's hit: Pinned turns it into a ×3 crit, and Shatter (Held + Damp, hit by a crit or
# a heavy hitter) makes it ×2.5. Returns {"crit", "crit_multiplier", "multiplier", "shatter", "tag"}.
static func before_hit(enemy: Node2D, tower: Tower, is_crit: bool) -> Dictionary:
	var result := {"crit": is_crit, "crit_multiplier": tower.attack_data.crit_multiplier, "multiplier": 1.0,
		"shatter": false, "tag": &""}
	var s: EnemyStatuses = enemy.statuses
	if s.pinned:
		s.pinned = false
		result.crit = true
		result.crit_multiplier = maxf(PINNED_MULTIPLIER, tower.attack_data.crit_multiplier)
		result.tag = &"pinned"
		if s.has(STATIC):
			_starfall(enemy, tower)
	var heavy: bool = tower.tower_data.line == "stone" or tower.attack_data.has_target_priority
	if s.is_held() and s.has(DAMP) and (result.crit or heavy):
		# Crowned: a lob's Shatter becomes an Avalanche, a charged one a Prismstorm.
		var id := &"shatter"
		if tower.attack_data.lob:
			id = &"avalanche"
		elif s.has(STATIC):
			id = &"prismstorm"
		var crowned := id != &"shatter"
		if _fire(enemy, id, [tower], false, CROWNED_LINKS if crowned else 1, &"shatter") > 0:
			s.remove(HELD)
			result.multiplier = SHATTER_MULTIPLIER
			result.shatter = true
			result.tag = &"shatter"
			s.prism_pending = id == &"prismstorm"
			if id == &"avalanche" and not s.is_boss:
				_avalanche(enemy, tower)
	return result

# Starfall (Pinned + Static): Static bolts from nightmares within 3 cells (the Pinned one too) all fall
# into it at once, each ×2 and a crit, using up their Static.
static func _starfall(enemy: Node2D, tower: Tower) -> void:
	var s: EnemyStatuses = enemy.statuses
	var chain := _fire(enemy, &"starfall", _towers(tower, s.source(STATIC)), false, CROWNED_LINKS)
	if chain <= 0:
		return
	var dreams := _dreams(enemy)
	var level := 1 if dreams and dreams.has_rule(&"falling_stars") else 0
	var reach := (STARFALL_REACH[level] + _storm_front(enemy)) * CELL
	var multiplier := STARFALL_BOSS_BOLT if s.is_boss else STARFALL_BOLT
	var charged := _field(enemy).filter(func(e: Node2D) -> bool:
		return e.statuses.has(STATIC) and e.global_position.distance_to(enemy.global_position) <= reach)
	for other in charged:
		var bolt: float = other.statuses.potency(STATIC) * EnemyStatuses.STATIC_BOLT_MULTIPLIER * multiplier
		var applier := _tower_of(other.statuses.source(STATIC), tower)
		other.statuses.remove(STATIC)
		if other != enemy:
			_segment(&"thunderclap_arc", other.global_position, enemy.global_position, enemy, 0.3)
		if is_instance_valid(enemy) and not enemy.is_cleansed:
			enemy.take_damage(bolt, "light", false, true, applier, &"starfall")

# Avalanche (a lob's Shatter): every Damp + Held nightmare under the lob Shatters too (×2.5 of the
# lobber's hit). Mountain's Fall: rubble where each spread Shatter lands.
static func _avalanche(enemy: Node2D, tower: Tower) -> void:
	var reach := maxf(tower.get_splash_cells(), 1.0) * CELL
	var dreams := _dreams(enemy)
	var rubble: Array[Vector2] = []
	for other in _field(enemy):
		if other == enemy or other.global_position.distance_to(enemy.global_position) > reach:
			continue
		var o: EnemyStatuses = other.statuses
		if not (o.is_held() and o.has(DAMP)):
			continue
		o.remove(HELD)
		_touch(other, o.chain_count if o.chain_time > 0.0 else 1, [tower])
		_effect(&"shatter", other.global_position, enemy)
		other.take_damage(tower.get_damage() * SHATTER_MULTIPLIER, tower.tower_data.line, true, false, tower,
			&"avalanche")
		if is_instance_valid(other):
			rubble.append(Tower.MAP_GRID.calculate_grid_coordinates(other.global_position))
	if dreams and dreams.has_rule(&"mountains_fall") and not rubble.is_empty():
		var world := _world(enemy)
		if world:
			world.add_child(RubblePatch.new(rubble, 0.25, 3.0))

# After a Shatter hit that dealt `dealt`: ice shards deal half of it to nightmares within 1 cell.
static func shatter_splash(enemy: Node2D, tower: Tower, dealt: float) -> void:
	var chain: int = enemy.statuses.chain_count if enemy.statuses.chain_time > 0.0 else 1
	# Prismstorm: the shards carry lightning (2 Static each; Prism Heart: 3, and 0.5 cells further).
	var prism: bool = enemy.statuses.prism_pending
	enemy.statuses.prism_pending = false
	var dreams := _dreams(enemy)
	var level := 1 if prism and dreams and dreams.has_rule(&"prism_heart") else 0
	var reach := (PRISM_REACH[level] if prism else 1.0) + _storm_front(enemy)
	for other in _others_within(enemy, reach):
		_touch(other, chain, [tower])
		other.take_damage(dealt * SHATTER_SPLASH, tower.tower_data.line, true, false, tower, &"shatter")
		if prism and is_instance_valid(other) and not other.is_cleansed:
			other.apply_status(STATIC, PRISM_STATIC[level], 0.0, tower.get_damage(), 0, "light", tower)

# A Static bolt worth `damage` goes off on `target` (a 5-stack bolt, or a Thunderclap arc). A Marked,
# charged nightmare within 3 cells takes it instead at ×2 (Lightning Rod). Returns who was struck.
static func strike_bolt(target: Node2D, damage: float, tower: Node, tag: StringName = &"static") -> Node2D:
	var rod := _find_rod(target)
	if rod == null:
		var at := target.global_position
		target.take_damage(damage, "light", false, false, tower, tag)
		if tag == &"static":
			_static_field(target, at, damage, tower)
		return target
	_fire(rod, &"lightning_rod", [tower] if tower else [], true)
	rod.take_damage(damage * ROD_MULTIPLIER, "light", false, false, tower, &"lightning_rod")
	return rod

# Static Field: a Static bolt also hits nightmares within 1 tile of where it struck (II: 1.5 tiles,
# and they gain 1 Static, which can set off their own bolt).
static func _static_field(struck: Node2D, at: Vector2, damage: float, tower: Node) -> void:
	var dreams := _dreams(struck)
	if dreams == null or not dreams.has_rule(&"static_field"):
		return
	var deep := dreams.rule_level(&"static_field") > 0
	var reach := (1.5 if deep else 1.0) * CELL
	var potency := damage / EnemyStatuses.STATIC_BOLT_MULTIPLIER
	var nearby := _field(struck).filter(func(e: Node2D) -> bool:
		return e != struck and e.global_position.distance_to(at) <= reach)
	for other in nearby:
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		other.take_damage(damage, "light", true, false, tower, &"static")
		if deep and is_instance_valid(other) and not other.is_cleansed:
			other.apply_status(STATIC, 1, 0.0, potency, 0, "light", tower)

static func _find_rod(near: Node2D) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for other in _field(near):
		if not other.statuses.has(MARKED) or not other.statuses.has(STATIC):
			continue
		var distance: float = other.global_position.distance_to(near.global_position)
		if distance <= ROD_REACH * CELL and distance < best_distance:
			best_distance = distance
			best = other
	return best


# --- The Reactions ----------------------------------------------------------------------------------

# Damp + 3 Static: discharges for 4× the applier's damage and arcs to every Damp nightmare nearby for
# 2×, each arc adding Static (so wet crowds chain). Uses up the Static.
static func _thunderclap(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	var tower := _tower_of(source, s.source(STATIC))
	# Crowned: a Spored nightmare's Thunderclap is a Tempest (not again within 2 s of the last one).
	var tempest := s.has(SPORED) and s.tempest_time <= 0.0
	var chain := _fire(enemy, &"tempest" if tempest else &"thunderclap", _towers(tower, s.source(DAMP)), false,
		CROWNED_LINKS if tempest else 1, &"thunderclap")
	if chain <= 0:
		return
	if tempest:
		s.tempest_time = TEMPEST_LOCK
	var base := _applier_damage(tower, s.potency(STATIC))
	var potency := s.potency(STATIC)
	s.remove(STATIC)
	var dreams := _dreams(enemy)
	var level := 0
	if dreams and dreams.has_rule(&"rolling_thunder"):
		level = 1 + dreams.rule_level(&"rolling_thunder")
	var eye := tempest and dreams != null and dreams.has_rule(&"eye_of_the_tempest")
	var reach: float = (THUNDERCLAP_REACH[level] + _storm_front(enemy) + (TEMPEST_EXTRA_REACH if eye else 0.0)) * CELL
	if dreams and dreams.has_rule(&"conductive_soil") and tower:
		reach = maxf(reach, tower.get_range_pixels())  # The Storm Grid capstone
	var arcs: Array = []
	for other in _field(enemy):
		if other != enemy and other.statuses.has(DAMP) and other.global_position.distance_to(enemy.global_position) <= reach:
			arcs.append(other)
	enemy.take_damage(base * THUNDERCLAP_DAMAGE, _line(tower, "light"), false, false, tower, &"thunderclap")
	for other in arcs:
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		_segment(&"thunderclap_arc", enemy.global_position, other.global_position, enemy, 0.25)
		_touch(other, chain, _towers(tower))
		var struck := strike_bolt(other, base * THUNDERCLAP_ARC_DAMAGE, tower, &"thunderclap")
		if is_instance_valid(struck) and not struck.is_cleansed:
			struck.apply_status(STATIC, THUNDERCLAP_ARC_STATIC[level], 0.0, potency, 0, "light", tower)
		# Tempest: every arc also sets off Ignite on a Spored target (not bosses), whose spread spores
		# carry Static, so wet neighbours Thunderclap in turn.
		if tempest and is_instance_valid(other) and not other.is_cleansed and other.statuses.has(SPORED) \
				and not other.statuses.is_boss:
			other.statuses.tempest_time = TEMPEST_LOCK
			_ignite(other, tower, potency, 2 if eye else 0)

# 3+ Spored + any Static: every Spored stack goes off at once (×1.5 of what it had left) and a stack
# spreads to neighbours, who may Ignite in turn. Uses up the Spored.
static func _ignite(enemy: Node2D, source: Node, carry_static: float = 0.0, spread: int = 0) -> void:
	var s: EnemyStatuses = enemy.statuses
	var spore_source := s.source(SPORED)
	var chain := _fire(enemy, &"ignite", _towers(spore_source, _tower_of(source, s.source(STATIC))))
	if chain <= 0:
		return
	var potency := s.potency(SPORED)
	var line := s.spore_line()
	var left := s.stacks(SPORED) * potency * s.time_left(SPORED)
	s.remove(SPORED)
	var dreams := _dreams(enemy)
	var level := 1 if dreams and dreams.has_rule(&"wildfire_spores") else 0
	var neighbours := _others_within(enemy, IGNITE_REACH[level] + _storm_front(enemy))
	enemy.take_damage(left * IGNITE_MULTIPLIER, line, true, false, spore_source, &"ignite")
	var stacks: int = spread if spread > 0 else IGNITE_SPREAD[level]
	for other in neighbours:
		if is_instance_valid(other) and not other.is_cleansed:
			_touch(other, chain, _towers(spore_source))
			other.apply_status(SPORED, stacks, 0.0, potency, 0, line, spore_source)
			if carry_static > 0.0 and is_instance_valid(other) and not other.is_cleansed:
				other.apply_status(STATIC, 1, 0.0, carry_static, 0, "light", source)  # Tempest's spores carry Static

# 3+ Spored + Damp: the Spored ticks +50% for 4 s and a spore cloud grows on the tile. Uses up Damp.
static func _mushrooming(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	var spore_source := s.source(SPORED)
	# Crowned: on a Held nightmare it's a Fairy Circle, at full Drowsy a Nightbloom.
	var id := &"mushrooming"
	if s.is_held():
		id = &"fairy_circle"
	elif s.has(DROWSY) and s.stacks(DROWSY) >= s.get_max_stacks(DROWSY):
		id = &"nightbloom"
	var crowned := id != &"mushrooming"
	var chain := _fire(enemy, id, _towers(spore_source, _tower_of(source, s.source(DAMP))), false,
		CROWNED_LINKS if crowned else 1, &"mushrooming")
	if chain <= 0:
		return
	s.remove(DAMP)
	s.mushroom_time = MUSHROOM_TIME
	var cell: Vector2 = enemy.get_current_cell()
	var dreams := _dreams(enemy)
	var ground_parent := enemy.get_parent().get_parent()
	if id == &"fairy_circle":
		# Mushroom rings on the path tiles among the 8 around it, instead of the one cloud.
		var ring_of_rings := dreams != null and dreams.has_rule(&"ring_of_rings")
		var route: Array = _route_cells(enemy)
		var cells: Array[Vector2] = []
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var c := cell + Vector2(dx, dy)
				if c != cell and route.has(c) and cells.size() < FAIRY_RING_MAX:
					cells.append(c)
		var rings := CrownedGround.new(CrownedGround.Kind.FAIRY_RING, cells, FAIRY_RING_TIME)
		rings.until_stepped = ring_of_rings
		rings.potency = s.potency(SPORED)
		rings.line = s.spore_line()
		rings.source = spore_source
		rings.chain = chain
		ground_parent.add_child(rings)
		ground_parent.move_child(rings, enemy.get_parent().get_index())
		return
	if id == &"nightbloom":
		var level := 1 if dreams and dreams.has_rule(&"endless_night") else 0
		var bloom := CrownedGround.new(CrownedGround.Kind.NIGHTBLOOM, [], NIGHTBLOOM_TIME[level],
			Tower.MAP_GRID.calculate_map_position(cell),
			(MUSHROOM_CLOUD_RADIUS * NIGHTBLOOM_WIDTH[level] + _storm_front(enemy)) * CELL)
		ground_parent.add_child(bloom)
		ground_parent.move_child(bloom, enemy.get_parent().get_index())
	var wide := 1.0
	var time := MUSHROOM_CLOUD_TIME
	if id == &"nightbloom" and dreams and dreams.has_rule(&"endless_night"):
		wide = NIGHTBLOOM_WIDTH[1]
		time = NIGHTBLOOM_TIME[1]
	var radius := (MUSHROOM_CLOUD_RADIUS * wide + _storm_front(enemy)) * CELL
	if dreams and dreams.has_rule(&"mushroom_rain"):
		# Mushroom Rain (card 134): the cloud lasts twice as long and covers the 8 tiles around it too.
		time *= MUSHROOM_RAIN_TIME
		radius = maxf(radius, MUSHROOM_RAIN_RADIUS * CELL)
	var cloud := ReactionCloud.new(Tower.MAP_GRID.calculate_map_position(cell), radius, time, s.potency(SPORED),
		s.spore_line(), spore_source, chain)
	# In the world just before the nightmares' container, so it draws on the ground under them (the
	# container's children are all nightmares; nothing else may go in there).
	var container := enemy.get_parent()
	var world := container.get_parent()
	world.add_child(cloud)
	world.move_child(cloud, container.get_index())

# Damp + full Drowsy: falls asleep for 2 s, once per nightmare (bosses and nightmares that can't be
# held are slowed instead). Uses up the Drowsy.
static func _drown(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	var dreams := _dreams(enemy)
	var level := 0
	if dreams and dreams.has_rule(&"deep_water"):
		level = 1 + dreams.rule_level(&"deep_water")
	if s.drowned >= DROWN_TIMES[level]:
		return
	var applier := _tower_of(source, s.source(DROWSY))
	# Crowned: a Held nightmare's Drown is a Still Pool (it sinks, and a pool stays on its tile).
	var still := s.is_held()
	if _fire(enemy, &"still_pool" if still else &"drown", _towers(applier, s.source(DAMP)), false,
			CROWNED_LINKS if still else 1, &"drown") <= 0:
		return
	s.remove(DROWSY)
	s.drowned += 1
	if still:
		var deep_still := 1 if dreams and dreams.has_rule(&"deep_stillness") else 0
		var cells: Array[Vector2] = [enemy.get_current_cell()]
		var pool := CrownedGround.new(CrownedGround.Kind.STILL_POOL, cells, STILL_POOL_TIME[deep_still])
		pool.sleep_seconds = STILL_POOL_SLEEP[deep_still]
		var container := enemy.get_parent()
		container.get_parent().add_child(pool)
		container.get_parent().move_child(pool, container.get_index())
	var deep := 1 if level > 0 else 0
	if s.is_boss or cant_be_held(enemy):
		s.slow_time = DROWN_SLEEP[0]
		s.slow_amount = DROWN_BOSS_SLOW[deep]
	else:
		var was_asleep := s.is_asleep()
		s.sleep_time = maxf(s.sleep_time, DROWN_SLEEP[deep])
		if applier != null and not was_asleep:
			applier.put_to_sleep.emit(applier, enemy)  # Sound: the sleep drone

# Marked + (Held or asleep or full Drowsy): the next Warden hit is a guaranteed ×3 crit. Uses up Marked.
static func _pinned(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	if s.pinned:
		return
	if _fire(enemy, &"pinned", _towers(s.source(MARKED), _tower_of(source, s.source(HELD)))) <= 0:
		return
	s.remove(MARKED)
	s.pinned = true

# Held + Spored: Spored ticks 3× as fast while held (EnemyStatuses.tick). Only the event is here.
static func _smother(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	_fire(enemy, &"smother", _towers(s.source(SPORED), _tower_of(source, s.source(HELD))))


# --- Echoes (Echo Hollow) ---------------------------------------------------------------------------

# Rough strength of each Reaction's burst, × the applier's damage, for echoes (the originals scale
# with what the nightmare had built up, which an echo on an empty spot can't).
const ECHO_DAMAGE := {&"thunderclap": 4.0, &"ignite": 3.0, &"shatter": 2.5, &"lightning_rod": 6.0}
const ECHO_REACH := 1.0  # Cells around the spot

# Reaction `id` repeats at `spot` at `share` strength (Echo Hollow's echo, 1 s after the original).
# `echo_tower` is the Hollow, `applier` the Warden behind the original. With `as_chain_link`
# (Whispering Hollow) the echo is recorded as the chain's next link. `depth` = 1 for an echo, 2 for
# Encore's echo of an echo; the tracker's echo_depth tells Hollows not to echo echoes.
static func echo(id: StringName, spot: Vector2, share: float, echo_tower: Tower, applier: Tower, chain: int,
		as_chain_link: bool, depth: int = 1) -> void:
	if not is_instance_valid(echo_tower) or not echo_tower.is_inside_tree():
		return
	var tracker := ReactionTracker.find(echo_tower)
	var world := _world(echo_tower)
	var nearby := echo_tower.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP).filter(func(e: Node2D) -> bool:
		return e.global_position.distance_to(spot) <= ECHO_REACH * CELL)
	tracker.echo_depth = depth
	echo_tower.echoed.emit(echo_tower, id, spot)
	if world:
		Fx.play(&"echo", spot, world)  # Lilac rings, then the Reaction's own effect again
		Fx.reaction(id, spot, world, [echo_tower])
	var strength: float = ECHO_DAMAGE.get(id, 0.0) * (applier.get_damage() if is_instance_valid(applier) else echo_tower.get_damage())
	for enemy in nearby:
		if not is_instance_valid(enemy) or enemy.is_cleansed:
			continue
		var s: EnemyStatuses = enemy.statuses
		match id:
			&"drown":
				if s.is_boss or cant_be_held(enemy):
					s.slow_time = maxf(s.slow_time, DROWN_SLEEP[0] * share)
					s.slow_amount = maxf(s.slow_amount, DROWN_BOSS_SLOW[0])
				else:
					s.sleep_time = maxf(s.sleep_time, DROWN_SLEEP[0] * share)
			&"pinned":
				s.pinned = true
			_:
				if strength > 0.0:
					enemy.take_damage(strength * share, _line(applier, echo_tower.tower_data.line), true, false,
						echo_tower, &"echo")
	if id == &"mushrooming" and not nearby.is_empty():
		var first: Node2D = nearby[0]
		var cloud := ReactionCloud.new(spot, MUSHROOM_CLOUD_RADIUS * CELL, MUSHROOM_CLOUD_TIME * share,
			first.statuses.potency(SPORED), first.statuses.spore_line(), applier, chain)
		var container := first.get_parent()
		container.get_parent().add_child(cloud)
		container.get_parent().move_child(cloud, container.get_index())
	if as_chain_link and not nearby.is_empty() and tracker:
		var link: Node2D = nearby[0]
		link.statuses.mark_chain(chain + 1, [echo_tower], CHAIN_WINDOW)
		tracker.record(id, link, chain + 1, [echo_tower])
	tracker.echo_depth = 0


# --- Firing, chains and output ---------------------------------------------------------------------

# Fires Reaction `id` on `enemy` unless it's cooling down there. Returns its chain link (1 = not
# caused by another Reaction), or 0 if it didn't fire. `ignore_cooldown`: the rule still applies
# (Lightning Rod redirects every bolt) but only the first in a cooldown shows.
# `links`: chain links it counts as (Crowned Reactions: 2). `cooldown_id`: the cooldown it shares (a
# Crowned Reaction uses its base Reaction's).
static func _fire(enemy: Node2D, id: StringName, towers: Array, ignore_cooldown: bool = false, links: int = 1,
		cooldown_id: StringName = &"") -> int:
	var s: EnemyStatuses = enemy.statuses
	var key := cooldown_id if cooldown_id != &"" else id
	if s.is_on_cooldown(key):
		return 1 if ignore_cooldown else 0
	var data := get_data(key)
	var dreams := _dreams(enemy)
	var cooldown: float = data.cooldown if data else 1.5
	if dreams and dreams.has_rule(&"quick_reactions"):
		cooldown = minf(cooldown, QUICK_COOLDOWN)
	s.start_cooldown(key, cooldown)
	# Storm Front: a Reaction a Gust-copied status completed counts one more link.
	var storm_front := s.gust_time > 0.0
	if storm_front:
		links += 1
	var chain := links
	var all_towers := towers.duplicate()
	if s.chain_time > 0.0:
		chain = s.chain_count + links
		for t in s.chain_towers:
			if is_instance_valid(t) and not all_towers.has(t):
				all_towers.append(t)
	all_towers = all_towers.filter(func(t) -> bool: return is_instance_valid(t) and t is Tower)
	# Its own output marks this nightmare too, so a second Reaction here right away links on.
	s.mark_chain(chain, all_towers, CHAIN_WINDOW)
	# The effect, its callout, a light thread from each Warden that set it up, and a small shake.
	var world := _world(enemy)
	if world != null:
		var node := Fx.reaction(id, enemy.global_position, world,
			towers.filter(func(t) -> bool: return is_instance_valid(t) and t is Tower))
		if id == &"smother" and node != null:
			enemy.set_meta(&"smother_fx", node)  # Loops while held; the nightmare frees it after
		if storm_front:
			Fx.play(&"storm_front", enemy.global_position, world, 1.0, true, STORM_FRONT_SECONDS)  # A wind swirl (it loops: give it a life)
	var tracker := ReactionTracker.find(enemy)
	if tracker:
		tracker.record(id, enemy, chain, all_towers)
		tracker.note_spot(id, enemy.global_position, _tower_of(towers[0] if not towers.is_empty() else null, null))
	if chain - links < DAWNBURST_CHAIN and chain >= DAWNBURST_CHAIN:
		_dawnburst(enemy)
	return chain

# A Reaction's output reached `other`: a Reaction there soon counts as the chain's next link.
static func _touch(other: Node2D, chain: int, towers: Array) -> void:
	if is_instance_valid(other) and not other.is_cleansed:
		other.statuses.mark_chain(chain, towers, CHAIN_WINDOW)

# ×10 chain with the Dawnbreak Legendary: 10% of max health to every nightmare within 4 cells.
static func _dawnburst(enemy: Node2D) -> void:
	var dreams := _dreams(enemy)
	if dreams == null or not dreams.has_rule(&"dawnbreak"):
		return
	var at: Vector2 = enemy.global_position
	for other in _field(enemy):
		if other.global_position.distance_to(at) <= DAWNBREAK_REACH * CELL:
			var share := DAWNBREAK_BOSS_SHARE if other.enemy_data.is_boss else DAWNBREAK_SHARE
			other.take_damage(other.max_health * share, "", true, false, null, &"dawnbreak")


# --- Helpers ----------------------------------------------------------------------------------------

# Storm Front: +1 cell of reach for a Reaction a Gust-copied status completed on `enemy`.
static func _storm_front(enemy: Node2D) -> float:
	return STORM_FRONT_REACH if enemy.statuses.gust_time > 0.0 else 0.0

# The path tiles nightmares walk (Fairy Circle's rings grow only on those).
static func _route_cells(near: Node2D) -> Array:
	var dreams := _dreams(near)
	if dreams == null or dreams.map_generator == null:
		return []
	var map = dreams.map_generator
	return Array(map.get_path_from(map.startPath))

# Carried Storm: a Samara / Autumn Gale seed passing through the spot of Reaction `id` repeats it at
# 50% on a nightmare it hits after (damage Reactions as a burst, Drown as a short sleep, Pinned as a
# Pin). The seed's Warden gets the credit.
static func carry(id: StringName, enemy: Node2D, seed_tower: Tower, applier: Tower) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	var base: StringName = CROWNED_BASE.get(id, id)
	match base:
		&"drown":
			if s.is_boss or cant_be_held(enemy):
				s.slow_time = maxf(s.slow_time, DROWN_SLEEP[0] * CARRIED_SHARE)
				s.slow_amount = maxf(s.slow_amount, DROWN_BOSS_SLOW[0])
			else:
				s.sleep_time = maxf(s.sleep_time, DROWN_SLEEP[0] * CARRIED_SHARE)
		&"pinned":
			s.pinned = true
		_:
			var strength: float = ECHO_DAMAGE.get(base, 2.0)
			var damage := (applier.get_damage() if is_instance_valid(applier) else seed_tower.get_damage())
			enemy.take_damage(strength * damage * CARRIED_SHARE, _line(applier if is_instance_valid(applier) else seed_tower,
				seed_tower.tower_data.line), true, false, seed_tower, &"carried_storm")

static func _field(near: Node2D) -> Array:
	return near.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP)

static func _others_within(enemy: Node2D, cells: float) -> Array:
	return _field(enemy).filter(func(e: Node2D) -> bool:
		return e != enemy and e.global_position.distance_to(enemy.global_position) <= cells * CELL)

static func _tower_of(first, fallback) -> Tower:
	if is_instance_valid(first) and first is Tower:
		return first
	if is_instance_valid(fallback) and fallback is Tower:
		return fallback
	return null

static func _towers(a = null, b = null) -> Array:
	var list := []
	for t in [a, b]:
		if is_instance_valid(t) and t is Tower and not list.has(t):
			list.append(t)
	return list

static func _applier_damage(tower: Tower, fallback: float) -> float:
	return tower.get_damage() if tower != null else fallback

static func _line(tower: Tower, fallback: String) -> String:
	return tower.tower_data.line if tower != null else fallback

static func _dreams(near: Node) -> DreamState:
	return near.get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState if near.is_inside_tree() else null

# Visuals go through Fx (scripts/fx/fx.gd, the effects player). They're added to the world (the
# scene the nightmares are in), never to the nightmares' container.
static func _world(near: Node) -> Node:
	var tracker := ReactionTracker.find(near)
	return tracker.get_parent() if tracker else null

static func _effect(effect: StringName, at: Vector2, near: Node, scale: float = 1.0, seconds: float = 0.0) -> Node2D:
	var world := _world(near)
	if effect == &"" or world == null:
		return null
	return Fx.play(effect, at, world, scale, true, seconds)

static func _segment(effect: StringName, from: Vector2, to: Vector2, near: Node, seconds: float) -> void:
	var world := _world(near)
	if world != null:
		Fx.segment(effect, from, to, world, seconds)
