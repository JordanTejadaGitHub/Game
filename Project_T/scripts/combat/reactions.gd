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

static var _data := {}


# --- Data -------------------------------------------------------------------------------------------

static func get_data(id: StringName) -> ReactionData:
	_load()
	return _data.get(id)

static func all() -> Array[ReactionData]:
	_load()
	var list: Array[ReactionData] = []
	for id in _data:
		list.append(_data[id])
	return list

static func _load() -> void:
	if not _data.is_empty():
		return
	for file in ResourceLoader.list_directory(DIR):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var data := load(DIR + file) as ReactionData
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
	var heavy: bool = tower.tower_data.line == "stone" or tower.attack_data.has_target_priority
	if s.is_held() and s.has(DAMP) and (result.crit or heavy):
		if _fire(enemy, &"shatter", [tower]) > 0:
			s.remove(HELD)
			result.multiplier = SHATTER_MULTIPLIER
			result.shatter = true
			result.tag = &"shatter"
	return result

# After a Shatter hit that dealt `dealt`: ice shards deal half of it to nightmares within 1 cell.
static func shatter_splash(enemy: Node2D, tower: Tower, dealt: float) -> void:
	var chain: int = enemy.statuses.chain_count if enemy.statuses.chain_time > 0.0 else 1
	for other in _others_within(enemy, 1.0):
		_touch(other, chain, [tower])
		other.take_damage(dealt * SHATTER_SPLASH, tower.tower_data.line, true, false, tower, &"shatter")

# A Static bolt worth `damage` goes off on `target` (a 5-stack bolt, or a Thunderclap arc). A Marked,
# charged nightmare within 3 cells takes it instead at ×2 (Lightning Rod). Returns who was struck.
static func strike_bolt(target: Node2D, damage: float, tower: Node, tag: StringName = &"static") -> Node2D:
	var rod := _find_rod(target)
	if rod == null:
		target.take_damage(damage, "light", false, false, tower, tag)
		return target
	_fire(rod, &"lightning_rod", [tower] if tower else [], true)
	rod.take_damage(damage * ROD_MULTIPLIER, "light", false, false, tower, &"lightning_rod")
	return rod

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
	var chain := _fire(enemy, &"thunderclap", _towers(tower, s.source(DAMP)))
	if chain <= 0:
		return
	var base := _applier_damage(tower, s.potency(STATIC))
	var potency := s.potency(STATIC)
	s.remove(STATIC)
	var dreams := _dreams(enemy)
	var level := 0
	if dreams and dreams.has_rule(&"rolling_thunder"):
		level = 1 + dreams.rule_level(&"rolling_thunder")
	var reach: float = THUNDERCLAP_REACH[level] * CELL
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

# 3+ Spored + any Static: every Spored stack goes off at once (×1.5 of what it had left) and a stack
# spreads to neighbours, who may Ignite in turn. Uses up the Spored.
static func _ignite(enemy: Node2D, source: Node) -> void:
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
	var neighbours := _others_within(enemy, IGNITE_REACH[level])
	enemy.take_damage(left * IGNITE_MULTIPLIER, line, true, false, spore_source, &"ignite")
	for other in neighbours:
		if is_instance_valid(other) and not other.is_cleansed:
			_touch(other, chain, _towers(spore_source))
			other.apply_status(SPORED, IGNITE_SPREAD[level], 0.0, potency, 0, line, spore_source)

# 3+ Spored + Damp: the Spored ticks +50% for 4 s and a spore cloud grows on the tile. Uses up Damp.
static func _mushrooming(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	var spore_source := s.source(SPORED)
	var chain := _fire(enemy, &"mushrooming", _towers(spore_source, _tower_of(source, s.source(DAMP))))
	if chain <= 0:
		return
	s.remove(DAMP)
	s.mushroom_time = MUSHROOM_TIME
	var cell: Vector2 = enemy.get_current_cell()
	var cloud := ReactionCloud.new(Tower.MAP_GRID.calculate_map_position(cell), MUSHROOM_CLOUD_RADIUS * CELL,
		MUSHROOM_CLOUD_TIME, s.potency(SPORED), s.spore_line(), spore_source, chain)
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
	if _fire(enemy, &"drown", _towers(_tower_of(source, s.source(DROWSY)), s.source(DAMP))) <= 0:
		return
	s.remove(DROWSY)
	s.drowned += 1
	var deep := 1 if level > 0 else 0
	if s.is_boss or HELD in s.immune:
		s.slow_time = DROWN_SLEEP[0]
		s.slow_amount = DROWN_BOSS_SLOW[deep]
	else:
		s.sleep_time = maxf(s.sleep_time, DROWN_SLEEP[deep])

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
				if s.is_boss or HELD in s.immune:
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
static func _fire(enemy: Node2D, id: StringName, towers: Array, ignore_cooldown: bool = false) -> int:
	var s: EnemyStatuses = enemy.statuses
	if s.is_on_cooldown(id):
		return 1 if ignore_cooldown else 0
	var data := get_data(id)
	var dreams := _dreams(enemy)
	var cooldown: float = data.cooldown if data else 1.5
	if dreams and dreams.has_rule(&"quick_reactions"):
		cooldown = minf(cooldown, QUICK_COOLDOWN)
	s.start_cooldown(id, cooldown)
	var chain := 1
	var all_towers := towers.duplicate()
	if s.chain_time > 0.0:
		chain = s.chain_count + 1
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
	var tracker := ReactionTracker.find(enemy)
	if tracker:
		tracker.record(id, enemy, chain, all_towers)
	if chain == DAWNBURST_CHAIN:
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
