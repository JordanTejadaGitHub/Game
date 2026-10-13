extends Node2D
# Firefly Jar class prototype (documentation/dream_council_review.md section 20; the spec is
# D:\Projects\logs\dream_council\v4_sporeling_firefly.md sections 0 and 11-20; owner direction 2026-10-12).
#
# The family's thing: "damage spreads to other nightmares". The word on the cards is FORK: a damage-only strike that
# adds no status and that nothing triggers from (tag FORK_TAG: every hook here ignores its own forks).
#   Glow       the path within GLOW_CELLS of a Firefly Warden (any light-line form)
#   Lit        a nightmare standing in any glow, flyers too; Lit nightmares can't hide
#   A light    one Firefly Warden's glow; glows sharing a path cell are one light; a lit Sprout is its own light
#   Gold path  path inside two or more Firefly Wardens' glows
# One node per run, made by DreamState (group GROUP). It listens to DamageLog.damage_dealt, so no Warden or nightmare
# code calls it. Forks are queued and struck at the end of the frame: one per nightmare per event (the largest wins),
# at most EVENT_MAX per event, bosses take half. No class_name: DreamState preloads this file.
#
# Every number is a starting point from Balancing's queue. They all live here.

const GROUP := &"firefly_lights"
const FAMILY := "firefly_jar"  # DreamState.calling on a Firefly start
const LINE := "light"  # A Firefly Warden: any form of this line
const FORK_TAG := &"fork"

const GLOW_CELLS := 3.0  # Glow: path within this many cells of a Firefly Warden
const SPROUT_TOUCH := 1.25  # A lit Sprout's light: the path touching it (the path rule, both axes)
const NEAR_CELLS := 2.0  # "near": within 2 cells on both axes (lent cards)
const CALLING_SHARE := 0.5  # Lantern Light: half the dispelling Warden's hit
const BRIGHTNESS_SECONDS := 3.0  # Another family's fork is capped at this many seconds of the lighting Firefly Warden
const BOSS_SHARE := 0.5  # Bosses take half of any fork
const EVENT_MAX := 6  # Forks one event can throw
const MEET_MAX := 4  # Where Lights Meet: one fork per Firefly Warden lighting the gold path, up to this
const CHAIN_TARGETS := 2  # Chain of Lanterns
const CHAIN_SHARE := 0.5
const HAMMER_SHARE := 0.5  # Hammerfall
const SPOTLIGHT_SHARE := 0.25  # Spotlight
const SPOTLIGHT_MAX := 6
const NEXT_LIGHT_STEPS := 8  # The next light ahead is at most this many steps along the path
const SIGNAL_SHARE := 0.5  # Signal Fires
const SIGNAL_EVERY := 1.0  # ...once for each light each second
const LANTERNWAY_LIGHTS := 3  # Lanternway
const LANTERNWAY_SHARE := 0.5
const AMBUSH_SHARE := 0.5  # Ambush
const SPARK_MAX := 3  # Waiting Spark: sparks that can wait in one light
const SPARK_TIME := 5.0
const LIVE_WIRE_SHARE := 1.0  # Lent: the full hit, per dispel
const CROSSFIRE_WINDOW := 1.0  # Lent
const CROSSFIRE_TARGETS := 2
const CROSSFIRE_SHARE := 0.5
const CROSSFIRE_WAIT := 3.0
const LIKE_SHARE := 0.5  # Lent: Like to Like
const LIKE_TICK_EVERY := 1.0  # ...ticks and clouds fork once a second per nightmare
const HEAVY_ATTACK_SHARE := 0.8  # A heavy Warden's next hit counts as a new attack after this share of its attack time

# Rule ids of the class cards (UpgradeData.calling = FAMILY) and the lent cards.
const WHERE_LIGHTS_MEET := &"where_lights_meet"
const CHAIN_OF_LANTERNS := &"chain_of_lanterns"
const LAST_SPARK := &"last_spark"
const HAMMERFALL := &"hammerfall"
const KNOCK_ON := &"knock_on"
const SPOTLIGHT := &"spotlight"
const LIT_SPROUTS := &"lit_sprouts"  # Fireflies in the Grass
const SIGNAL_FIRES := &"signal_fires"
const LANTERNWAY := &"lanternway"
const NOTHING_WASTED := &"nothing_wasted"
const AMBUSH := &"ambush"
const WAITING_SPARK := &"waiting_spark"
const LENT_LIVE_WIRE := &"lent_live_wire"
const LENT_CROSSFIRE := &"lent_crossfire"
const LIKE_TO_LIKE := &"like_to_like"
const GUIDING_LIGHT := &"guiding_light"  # A general card (needs Lanternmoth), reworked to fork: Firefly spreads damage, never statuses
const GUIDING_SHARE := 0.5
const GUIDING_CELLS: Array[float] = [1.0, 2.0]  # II

const LIT_SPROUT_META := &"lit_sprout"  # On a Sprout the player chose to glow
const GROUPS_META := &"ff_lights"  # On a nightmare: the lights it stands in (Array of light ids)
const AMBUSH_META := &"ff_ambushed"  # On a nightmare: {light id: true}
const CROSS_META := &"ff_crossfire"  # On a nightmare: the last qualifying hit, for Crossfire
const LIKE_META := &"ff_like_next"  # On a nightmare: when its ticks may fork again (Like to Like)
const HEAVY_META := &"ff_heavy_next"  # On a Warden: when its next hit counts as a new attack

const POLL := 0.1  # Seconds between looks at who is Lit
const REBUILD := 0.5  # Seconds between rebuilds of the light map when nothing told us it changed

var dream_state: Node  # DreamState (untyped: DreamState preloads this script)
var _hooked := false
var _sources: Array = []  # [{tower, sprout: bool, light: int}]
var _glow := {}  # Route cell -> {jars: int, lights: Array}
var _max_lit_step := -1
var _board := -1
var _rebuild_in := 0.0
var _poll_in := 0.0
var _queue: Array = []  # Fork requests waiting for the end of the frame
var _event := 0
var _sparks := {}  # Light id -> Array of {amount, source, until, cap}
var _signal_next := {}  # Light id -> clock
var _base_jar_dps := 0.0
var forks_thrown := 0  # This run (tests and the owner's eye)
var saved_sprouts: Array = []  # From the run save (DreamState.load_save); applied once the Wardens are back

func _ready() -> void:
	add_to_group(GROUP)
	z_index = -1  # With the ground: the glow lies on the path, under Wardens and nightmares
	var jar: TowerData = load("res://resource/tower/firefly_jar.tres")
	if jar != null:
		_base_jar_dps = jar.damage * jar.attacks_per_second
	if dream_state != null and dream_state.get("drift_director") != null:
		dream_state.drift_director.rest_started.connect(_on_rest.unbind(4))

func _on_rest() -> void:
	_sparks.clear()  # Waiting sparks go out when a rest starts
	queue_redraw()

# --- Who this is on for -----------------------------------------------------------------------------------------

func class_on() -> bool:
	return dream_state != null and dream_state.calling == FAMILY

func _rule(id: StringName) -> bool:
	return dream_state != null and dream_state.has_rule(id)

func _lent_on() -> bool:
	return _rule(LENT_LIVE_WIRE) or _rule(LENT_CROSSFIRE) or _rule(LIKE_TO_LIKE)

func _cell() -> float:
	return Tower.MAP_GRID.cell_size.x

func _now() -> float:
	return dream_state._game_clock

static func is_firefly(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.line == LINE and tower.tower_data.can_attack

# "Another family's Warden": not this family, not a Sprout, not a wall.
static func is_other_family(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.can_attack and tower.tower_data.line != LINE \
		and tower.tower_data.line != "wall" and tower.tower_data.get_id() != "sprout"

static func is_heavy(tower) -> bool:
	if not (tower is Tower) or tower.attack_data == null:
		return false
	return bool(tower.attack_data.get("heavy"))  # attack_data: a Graftling follows the form it copies

static func _living(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.is_cleansed and enemy.health > 0

# --- The light map ----------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if dream_state == null:
		return
	if not _hooked and DamageLog.instance != null:
		DamageLog.instance.damage_dealt.connect(_on_damage)
		_hooked = true
	var on := class_on()
	if not on and not _lent_on():
		if not _sources.is_empty() or not _glow.is_empty():
			_sources.clear()
			_glow.clear()
			queue_redraw()
		_flush()  # Guiding Light forks on any start
		return
	_rebuild_in -= delta
	if _rebuild_in <= 0.0 or _board != int(dream_state.board_version):
		_rebuild()
	if on:
		_poll_in -= delta
		if _poll_in <= 0.0:
			_poll_in = POLL
			_poll()
	_flush()

func _towers() -> Array:
	return get_tree().get_nodes_in_group(Tower.GROUP).filter(_tower_ok)

func _tower_ok(tower) -> bool:
	return is_instance_valid(tower) and not tower.is_queued_for_deletion() and tower.tower_data != null

func _rebuild() -> void:
	_rebuild_in = REBUILD
	if not saved_sprouts.is_empty() and not _towers().is_empty():
		var cells := saved_sprouts
		saved_sprouts = []
		load_save(cells)
	_board = int(dream_state.board_version)
	_sources.clear()
	_glow.clear()
	_max_lit_step = -1
	var jars: Array = []
	var sprouts: Array = []
	for tower in _towers():
		if is_firefly(tower):
			jars.append(tower)
		elif tower.tower_data.get_id() == "sprout" and tower.get_meta(LIT_SPROUT_META, false):
			sprouts.append(tower)
	if not class_on():
		for tower in jars:
			_sources.append({"tower": tower, "sprout": false, "light": _sources.size()})  # Lent cards only ask "near a Firefly Warden"
		return
	var allowed := jars.size() if _rule(LIT_SPROUTS) else 0
	while sprouts.size() > allowed:
		sprouts.pop_back().remove_meta(LIT_SPROUT_META)  # One glowing Sprout per Firefly Warden: a sold Jar frees the newest pick
	var reach := GLOW_CELLS * _cell()
	var touch := SPROUT_TOUCH * _cell()
	var parent: Array = []  # Union-find over the Jars: glows sharing a path cell are one light
	for i in jars.size():
		parent.append(i)
	var cells_of: Array = []
	var path: Dictionary = dream_state._path_index
	for i in jars.size():
		var mine: Array = []
		for cell in path:
			if jars[i].global_position.distance_to(Tower.MAP_GRID.calculate_map_position(cell)) <= reach:
				mine.append(cell)
		cells_of.append(mine)
	var owner_of := {}  # Route cell -> the first Jar lighting it
	for i in jars.size():
		for cell in cells_of[i]:
			if owner_of.has(cell):
				var a := _find(parent, i)
				var b := _find(parent, int(owner_of[cell]))
				if a != b:
					parent[a] = b
			else:
				owner_of[cell] = i
	for i in jars.size():
		var light := _find(parent, i)
		_sources.append({"tower": jars[i], "sprout": false, "light": light})
		for cell in cells_of[i]:
			_note(cell, light, true)
	for j in sprouts.size():
		var light := jars.size() + j  # Always its own light, and never gold path
		_sources.append({"tower": sprouts[j], "sprout": true, "light": light})
		for cell in path:
			var at: Vector2 = Tower.MAP_GRID.calculate_map_position(cell)
			if absf(at.x - sprouts[j].global_position.x) <= touch and absf(at.y - sprouts[j].global_position.y) <= touch:
				_note(cell, light, false)
	for cell in _glow:
		_max_lit_step = maxi(_max_lit_step, int(path.get(cell, -1)))
	queue_redraw()  # Twice a second at most: the glow follows planting, selling, growing and new cards

func _find(parent: Array, i: int) -> int:
	while int(parent[i]) != i:
		i = int(parent[i])
	return i

func _note(cell: Vector2, light: int, jar: bool) -> void:
	var entry: Dictionary = _glow.get(cell, {"jars": 0, "lights": []})
	if jar:
		entry.jars += 1
	if not entry.lights.has(light):
		entry.lights.append(light)
	_glow[cell] = entry

# The sources lighting `at` (by distance, so flyers count).
func sources_at(at: Vector2) -> Array:
	var out: Array = []
	var reach := GLOW_CELLS * _cell()
	var touch := SPROUT_TOUCH * _cell()
	for source in _sources:
		var tower = source.tower
		if not is_instance_valid(tower):
			continue
		if source.sprout:
			if absf(at.x - tower.global_position.x) <= touch and absf(at.y - tower.global_position.y) <= touch:
				out.append(source)
		elif tower.global_position.distance_to(at) <= reach:
			out.append(source)
	return out

func is_lit(enemy) -> bool:
	return class_on() and is_instance_valid(enemy) and not sources_at(enemy.global_position).is_empty()

func lights_of(sources: Array) -> Array:
	var out: Array = []
	for source in sources:
		if not out.has(source.light):
			out.append(source.light)
	return out

# Firefly Wardens lighting this spot (gold path = two or more).
func jars_at(sources: Array) -> int:
	var count := 0
	for source in sources:
		if not source.sprout:
			count += 1
	return count

# The most another family's fork can be, started on a nightmare lit by `sources` (INF: uncapped).
func brightness(source_tower, sources: Array) -> float:
	if is_firefly(source_tower):
		return INF  # Firefly Wardens' own hits and bolts are never capped
	var best := 0.0
	for source in sources:
		var tower = source.tower
		if not is_instance_valid(tower):
			continue
		best = maxf(best, _base_jar_dps if source.sprout else tower.get_damage() * tower.get_attacks_per_second())
	return best * BRIGHTNESS_SECONDS if best > 0.0 else INF

func _enemies() -> Array:
	return get_tree().get_nodes_in_group(Tower.ENEMY_GROUP).filter(_living)

# The nearest Lit nightmares to `at`, nearest first (not those in `skip`).
func nearest_lit(at: Vector2, skip: Array, count: int = 1) -> Array:
	var found: Array = []
	for enemy in _enemies():
		if skip.has(enemy) or sources_at(enemy.global_position).is_empty():
			continue
		found.append(enemy)
	found.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	return found.slice(0, count)

func _step_of(enemy) -> int:
	return int(dream_state._path_index.get(enemy.get_current_cell(), -1))

# The front (furthest along the path) living nightmare standing in light `light`, or null.
func front_in(light: int, skip: Array = []):
	var best = null
	var best_step := -INF
	for enemy in _enemies():
		if skip.has(enemy) or not lights_of(sources_at(enemy.global_position)).has(light):
			continue
		var step := float(_step_of(enemy))
		if step > best_step:
			best_step = step
			best = enemy
	return best

# The next light ahead of path step `step`, not one of `from`: walk forward at most NEXT_LIGHT_STEPS. -1 = none.
func next_light(step: int, from: Array) -> Array:
	if step < 0:
		return [-1, -1]
	var by_step := {}
	for cell in _glow:
		var s := int(dream_state._path_index.get(cell, -1))
		if s > step and s <= step + NEXT_LIGHT_STEPS:
			by_step[s] = _glow[cell].lights
	for s in range(step + 1, step + NEXT_LIGHT_STEPS + 1):
		for light in by_step.get(s, []):
			if not from.has(light):
				return [light, s]
	return [-1, -1]

# --- Who is Lit, each POLL: reveals, entries (Ambush, Waiting Spark), leaving the last light (Last Spark) ----------

func _poll() -> void:
	var now := _now()
	for light in _sparks.keys():
		var waiting: Array = _sparks[light].filter(func(s: Dictionary) -> bool: return s.until > now)
		if waiting.is_empty():
			_sparks.erase(light)
			queue_redraw()
		else:
			_sparks[light] = waiting
	var container: Node = dream_state.spawner
	if container == null:
		return
	for enemy in container.get_children():
		if not _living(enemy) or not enemy.has_method("get_current_cell"):
			continue
		var lights: Array = lights_of(sources_at(enemy.global_position))
		var before: Array = enemy.get_meta(GROUPS_META, [])
		if not lights.is_empty() and enemy.has_method("is_hidden") and enemy.is_hidden():
			enemy.reveal_for(POLL * 3.0)  # Lit nightmares can't hide
		if lights == before:
			continue
		enemy.set_meta(GROUPS_META, lights)
		for light in lights:
			if not before.has(light):
				_entered(enemy, light)
		if lights.is_empty() and not before.is_empty() and _step_of(enemy) >= _max_lit_step:
			_left_last_light(enemy)

# Waiting Spark: every spark waiting in a light strikes the next nightmare to enter it.
func _entered(enemy, light: int) -> void:
	if not _sparks.has(light):
		return
	var id := _next_event()
	for spark in _sparks[light]:
		var source = spark.source.get_ref()
		_strike({"event": id, "source": source, "from": enemy.global_position + Vector2(0, -24), "target": enemy,
			"amount": spark.amount, "cap": spark.cap, "waited": true, "final": true})  # A spark never waits twice
	_sparks.erase(light)
	queue_redraw()

# Last Spark: a Charged nightmare walking out of its last light throws its charge back into the light.
func _left_last_light(enemy) -> void:
	if not _rule(LAST_SPARK) or not enemy.statuses.has(EnemyStatuses.STATIC):
		return
	var charge: float = enemy.statuses.stored_bolt_damage()
	var source = enemy.statuses.source(EnemyStatuses.STATIC)
	enemy.statuses.remove(EnemyStatuses.STATIC)  # On walking out its Charged ends
	var targets := nearest_lit(enemy.global_position, [enemy])
	if charge > 0.0 and not targets.is_empty():
		_fork(_next_event(), source, enemy.global_position, targets[0], charge, INF, {"final": true})

# --- Damage events ----------------------------------------------------------------------------------------------

func _next_event() -> int:
	_event += 1
	return _event

func _on_damage(event) -> void:
	if dream_state == null or event.tag == FORK_TAG or event.kind == &"reaction" or not is_instance_valid(event.enemy):
		return  # A fork triggers nothing; a Reaction's own lightning gets nothing added
	var on := class_on()
	var lent := _lent_on()
	var guiding := _rule(GUIDING_LIGHT)
	if not on and not lent and not guiding:
		return
	var source = event.source if is_instance_valid(event.source) and event.source is Tower else null
	if source == null:
		return
	var id := _next_event()  # One event for every rule this hit sets off: one fork per nightmare, the largest wins
	if guiding and event.kind == &"hit" and event.tag == &"":
		_guiding_light(id, event, source)
	if not on and not lent:
		return
	var enemy = event.enemy
	var dispel: bool = enemy.health <= 0
	var is_bolt: bool = event.kind == &"bolt"
	var is_hit: bool = event.kind == &"hit" and event.tag == &""
	if on:
		_class_rules(id, event, source, enemy, dispel, is_hit, is_bolt)
	if lent:
		_lent_rules(id, event, source, enemy, dispel, is_hit, is_bolt)

# Guiding Light (owner ruling 2026-10-12, dream_council_review.md 21): a hit on a fully Exposed nightmare forks to the
# nightmares within 1 cell of it (II: 2 cells), for half. It no longer spreads Exposed stacks.
func _guiding_light(id: int, event, source) -> void:
	var enemy = event.enemy
	if not enemy.statuses.is_exposed():
		return  # Full Exposed: 10 stacks, 20 with Brimming
	var at: Vector2 = enemy.global_position
	var reach: float = GUIDING_CELLS[mini(dream_state.rule_level(GUIDING_LIGHT), GUIDING_CELLS.size() - 1)] * _cell()
	for other in _enemies():
		if other != enemy and other.global_position.distance_to(at) <= reach:
			_fork(id, source, at, other, event.base * GUIDING_SHARE, INF, {"final": true})

# The size a dispel's fork starts from: that Warden's hit, or one second of its damage for a tick, cloud or trail.
func _hit_size(source, is_hit: bool, is_bolt: bool) -> float:
	var hit: float = source.get_damage()
	if is_hit or is_bolt:
		return hit  # A bolt that dispels forks from the Warden's hit, not the bolt
	return hit * source.get_attacks_per_second()

func _class_rules(id: int, event, source, enemy, dispel: bool, is_hit: bool, is_bolt: bool) -> void:
	var at: Vector2 = enemy.global_position
	var sources := sources_at(at)
	if sources.is_empty():
		return  # Class cards follow the light: the nightmare that was hit must be Lit
	var lights := lights_of(sources)
	var cap := brightness(source, sources)
	var heavy := false
	if is_hit and (is_heavy(source) or (source.tower_data.get_id() == "sprout" and _rule(HAMMERFALL))):
		heavy = _new_heavy_attack(source)  # One fork per attack, from the first nightmare it hits
	var knock: bool = heavy and is_heavy(source)  # Knock-On: real heavy Wardens only, never a Sprout
	if dispel:
		var size := _hit_size(source, is_hit, is_bolt)
		var jars := jars_at(sources)
		# Lantern Light; on gold path Where Lights Meet replaces it: one fork per Firefly Warden lighting it.
		var count := mini(jars, MEET_MAX) if jars >= 2 and _rule(WHERE_LIGHTS_MEET) else 1
		var targets := nearest_lit(at, [enemy], count)
		for target in targets:
			_fork(id, source, at, target, size * CALLING_SHARE, cap, {"heavy": knock})
		if targets.is_empty():
			_wait(lights, source, size * CALLING_SHARE, cap)
		if _rule(NOTHING_WASTED) and (is_hit or is_bolt) and event.overkill > 0.0 and not targets.is_empty():
			_fork(id, source, at, targets[0], minf(event.overkill, event.amount), cap, {"heavy": knock})  # The larger of the two lands
		if _rule(SIGNAL_FIRES):
			_signal(id, source, at, enemy, lights, size * SIGNAL_SHARE, cap)
		if _rule(LAST_SPARK) and enemy.statuses.has(EnemyStatuses.STATIC):
			var charge: float = enemy.statuses.stored_bolt_damage()
			var spark_to := nearest_lit(at, [enemy])
			if charge > 0.0 and not spark_to.is_empty():
				_fork(_next_event(), enemy.statuses.source(EnemyStatuses.STATIC), at, spark_to[0], charge, INF, {"final": true})
	if is_bolt:
		if _rule(CHAIN_OF_LANTERNS):
			for target in nearest_lit(at, [enemy], CHAIN_TARGETS):
				_fork(id, source, at, target, event.base * CHAIN_SHARE, cap)
		if _rule(LANTERNWAY):
			var step := _step_of(enemy)
			var seen := lights.duplicate()
			var from := at
			for i in LANTERNWAY_LIGHTS:
				var next := next_light(step, seen)
				if int(next[0]) < 0:
					break
				seen.append(next[0])
				step = int(next[1])
				var front = front_in(int(next[0]))
				if front != null:
					_fork(id, source, from, front, event.base * LANTERNWAY_SHARE, cap)
					from = front.global_position
	if is_hit:
		if heavy and _rule(HAMMERFALL):
			var targets := nearest_lit(at, [enemy])
			if not targets.is_empty():
				_fork(id, source, at, targets[0], event.base * HAMMER_SHARE, cap, {"heavy": knock})
		if heavy and is_heavy(source) and _rule(SPOTLIGHT):
			for light in lights:
				if front_in(light) != enemy:
					continue
				var others: Array = _enemies().filter(func(e) -> bool:
					return e != enemy and lights_of(sources_at(e.global_position)).has(light))
				for other in others.slice(0, SPOTLIGHT_MAX):
					_fork(id, source, at, other, event.base * SPOTLIGHT_SHARE, cap, {"heavy": true})
				break
		if _rule(AMBUSH):
			var ambushed: Dictionary = enemy.get_meta(AMBUSH_META, {})
			var fresh := false
			for light in lights:
				if not ambushed.has(light):
					ambushed[light] = true
					fresh = true
			if fresh:
				enemy.set_meta(AMBUSH_META, ambushed)
				var targets := nearest_lit(at, [enemy])
				if not targets.is_empty():
					_fork(id, source, at, targets[0], event.base * AMBUSH_SHARE, cap, {"heavy": knock})

# One fork per heavy attack: the first hit after most of its attack time has passed starts a new one.
func _new_heavy_attack(source) -> bool:
	var now := _now()
	if now < float(source.get_meta(HEAVY_META, -INF)):
		return false
	source.set_meta(HEAVY_META, now + HEAVY_ATTACK_SHARE / maxf(source.get_attacks_per_second(), 0.05))
	return true

# Signal Fires: a dispel in one light also forks to the front nightmare in the next light ahead, once per light a second.
func _signal(id: int, source, at: Vector2, enemy, lights: Array, amount: float, cap: float) -> void:
	var now := _now()
	for light in lights:
		if now < float(_signal_next.get(light, -INF)):
			return
	var next := next_light(_step_of(enemy), lights)
	if int(next[0]) < 0:
		return
	var front = front_in(int(next[0]))
	if front == null:
		return
	for light in lights:
		_signal_next[light] = now + SIGNAL_EVERY
	_fork(id, source, at, front, amount, cap)

# Waiting Spark: a fork with nowhere to go waits in its light.
func _wait(lights: Array, source, amount: float, cap: float) -> void:
	if not _rule(WAITING_SPARK) or lights.is_empty() or amount <= 0.0:
		return
	var light: int = lights[0]
	var waiting: Array = _sparks.get(light, [])
	if waiting.size() >= SPARK_MAX:
		return
	waiting.append({"amount": amount, "source": weakref(source), "until": _now() + SPARK_TIME, "cap": cap})
	_sparks[light] = waiting
	queue_redraw()

# --- The lent cards: "near a Firefly Warden", no Lit and no lights ------------------------------------------------

# The strongest Firefly Warden near `tower` (within NEAR_CELLS on both axes), or null.
func firefly_near(tower):
	var near := NEAR_CELLS * _cell()
	var best = null
	var best_dps := -1.0
	for source in _sources:
		var jar = source.tower
		if source.sprout or not is_instance_valid(jar) or jar == tower:
			continue
		if absf(jar.global_position.x - tower.global_position.x) > near or absf(jar.global_position.y - tower.global_position.y) > near:
			continue
		var dps: float = jar.get_damage() * jar.get_attacks_per_second()
		if dps > best_dps:
			best_dps = dps
			best = jar
	return best

func _near_enemies(at: Vector2, skip: Array) -> Array:
	var near := NEAR_CELLS * _cell()
	var found: Array = _enemies().filter(func(e) -> bool:
		return not skip.has(e) and absf(e.global_position.x - at.x) <= near and absf(e.global_position.y - at.y) <= near)
	found.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	return found

func _lent_rules(id: int, event, source, enemy, dispel: bool, is_hit: bool, is_bolt: bool) -> void:
	if is_bolt:
		return  # Bolts never fork from a lent card
	var at: Vector2 = enemy.global_position
	var now := _now()
	if _rule(LENT_CROSSFIRE) and is_hit:
		_crossfire(id, event, source, enemy, at, now)
	if not is_other_family(source):
		return
	var jar = firefly_near(source)
	if jar == null:
		return
	var cap: float = jar.get_damage() * jar.get_attacks_per_second() * BRIGHTNESS_SECONDS
	if dispel and _rule(LENT_LIVE_WIRE):
		var targets := _near_enemies(at, [enemy])
		if not targets.is_empty():
			_fork(id, source, at, targets[0], _hit_size(source, is_hit, false) * LIVE_WIRE_SHARE, cap)
			return  # One fork per hit across the three lent cards
	if _rule(LIKE_TO_LIKE) and enemy.statuses.has(EnemyStatuses.STATIC):
		var amount: float = event.base
		if not is_hit:
			if now < float(enemy.get_meta(LIKE_META, -INF)):
				return
			enemy.set_meta(LIKE_META, now + LIKE_TICK_EVERY)
			amount = source.get_damage() * source.get_attacks_per_second()  # That second's damage
		elif not _new_like_hit(source, now):
			return  # A pulse or splash forks once
		for other in _near_enemies(at, [enemy]):
			if other.statuses.has(EnemyStatuses.STATIC):
				_fork(id, source, at, other, amount * LIKE_SHARE, cap)
				break

func _new_like_hit(source, now: float) -> bool:
	if int(source.get_meta(&"ff_like_frame", -1)) == Engine.get_process_frames():
		return false
	source.set_meta(&"ff_like_frame", Engine.get_process_frames())
	return true

# Crossfire, reworked: a Firefly Warden and another family's Warden near it hit one nightmare within a second.
func _crossfire(id: int, event, source, enemy, at: Vector2, now: float) -> void:
	var firefly := is_firefly(source)
	if not firefly and not is_other_family(source):
		return
	var last: Dictionary = enemy.get_meta(CROSS_META, {})
	if now < float(last.get("wait", -INF)):
		return
	var other = last.get("source").get_ref() if last.has("source") else null
	if is_instance_valid(other) and other != source and now - float(last.at) <= CROSSFIRE_WINDOW and is_firefly(other) != firefly:
		var jar = source if firefly else other
		var partner = other if firefly else source
		var near := NEAR_CELLS * _cell()
		if absf(jar.global_position.x - partner.global_position.x) <= near and absf(jar.global_position.y - partner.global_position.y) <= near:
			var step := _step_of(enemy)
			var behind: Array = _enemies().filter(func(e) -> bool: return e != enemy and _step_of(e) >= 0 and _step_of(e) <= step)
			behind.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
			var amount: float = minf(event.base, float(last.base)) * CROSSFIRE_SHARE
			var cap: float = jar.get_damage() * jar.get_attacks_per_second() * BRIGHTNESS_SECONDS
			for target in behind.slice(0, CROSSFIRE_TARGETS):
				_fork(id, partner, at, target, amount, cap)
			enemy.set_meta(CROSS_META, {"wait": now + CROSSFIRE_WAIT})
			return
	enemy.set_meta(CROSS_META, {"source": weakref(source), "at": now, "base": event.base})  # Stored before defences

# --- Forks ------------------------------------------------------------------------------------------------------

# Queues a fork of `amount` from `from` to `target` for event `id`. `cap`: brightness (INF = none).
func _fork(id: int, source, from: Vector2, target, amount: float, cap: float, opts: Dictionary = {}) -> void:
	if amount <= 0.0 or not _living(target):
		return
	_queue.append({"event": id, "source": source, "from": from, "target": target, "amount": minf(amount, cap), "cap": cap,
		"heavy": opts.get("heavy", false), "final": opts.get("final", false)})

# One fork per nightmare per event (the largest wins), at most EVENT_MAX per event.
func _flush() -> void:
	if _queue.is_empty():
		return
	var queue := _queue
	_queue = []
	var by_event := {}
	for request in queue:
		var per_target: Dictionary = by_event.get_or_add(request.event, {})
		var key: int = request.target.get_instance_id() if is_instance_valid(request.target) else 0
		if not per_target.has(key) or per_target[key].amount < request.amount:
			per_target[key] = request
	for id in by_event:
		var requests: Array = by_event[id].values()
		requests.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.amount > b.amount)
		for request in requests.slice(0, EVENT_MAX):
			_strike(request)

func _strike(request: Dictionary) -> void:
	var target = request.target
	if not _living(target):
		return
	var source = request.source if is_instance_valid(request.source) else null
	var amount: float = request.amount
	if target.enemy_data != null and target.enemy_data.is_boss:
		amount *= BOSS_SHARE
	var at: Vector2 = target.global_position
	var bolt := ChainBolt.new(PackedVector2Array([request.from, at]), Palette.GOLD, 4.0)
	Reactions._world(self).add_child(bolt)
	forks_thrown += 1
	target.take_damage(amount, source.tower_data.line if source is Tower else LINE, false, false, source, FORK_TAG)
	# A nightmare dispelled by a fork gives no fork. Knock-On is the one exception: a heavy Warden's fork, one more hop.
	if request.get("heavy", false) and not request.get("final", false) and _rule(KNOCK_ON) and not _living(target):
		var next := nearest_lit(at, [target])
		if not next.is_empty():
			var hop := request.duplicate()
			hop.from = at
			hop.target = next[0]
			hop.final = true  # The second fork never forks again and takes no leftover
			_strike(hop)

# --- Fireflies in the Grass: the Sprouts the player chose to glow (the Warden panel's button) ---------------------

# "" = this Sprout can be made to glow now; else why not.
func lit_sprout_blocker(sprout) -> String:
	if not class_on() or not _rule(LIT_SPROUTS):
		return "needs Fireflies in the Grass"
	if not (sprout is Tower) or sprout.tower_data.get_id() != "sprout":
		return "only a Sprout can glow"
	if sprout.get_meta(LIT_SPROUT_META, false):
		return ""
	var jars := 0
	var lit := 0
	for tower in _towers():
		if is_firefly(tower):
			jars += 1
			if tower.global_position.distance_to(sprout.global_position) <= GLOW_CELLS * _cell():
				return "already inside a Firefly Warden's glow"
		elif tower.get_meta(LIT_SPROUT_META, false):
			lit += 1
	if lit >= jars:
		return "one glowing Sprout for each Firefly Warden"
	return ""

func set_lit_sprout(sprout, on: bool) -> bool:
	if on and lit_sprout_blocker(sprout) != "":
		return false
	if on:
		sprout.set_meta(LIT_SPROUT_META, true)
	elif sprout.has_meta(LIT_SPROUT_META):
		sprout.remove_meta(LIT_SPROUT_META)
	_rebuild()
	return true

# Saved with the run (DreamState.to_save): the cells of the glowing Sprouts.
func to_save() -> Array:
	var cells: Array = []
	for tower in _towers():
		if tower.get_meta(LIT_SPROUT_META, false):
			cells.append([tower.cell.x, tower.cell.y])
	return cells

func load_save(cells: Array) -> void:
	for tower in _towers():
		for saved in cells:
			if saved is Array and saved.size() == 2 and tower.cell.is_equal_approx(Vector2(saved[0], saved[1])) \
					and tower.tower_data.get_id() == "sprout":
				tower.set_meta(LIT_SPROUT_META, true)
	_rebuild_in = 0.0

# --- Drawing: the glow on the path, gold where two Firefly Wardens' glows cross, and waiting sparks ----------------

func _draw() -> void:
	if not class_on():
		return
	var half := Vector2(Tower.MAP_GRID.cell_size) / 2.0
	var gold := _rule(WHERE_LIGHTS_MEET)
	for cell in _glow:
		var at: Vector2 = to_local(Tower.MAP_GRID.calculate_map_position(cell))
		var bright: bool = gold and int(_glow[cell].jars) >= 2
		draw_rect(Rect2(at - half * 0.8, half * 1.6), Color(Palette.GOLD if bright else Palette.GLOW, 0.30 if bright else 0.14))
	for light in _sparks:
		var spot := _light_spot(int(light))
		for i in _sparks[light].size():
			draw_circle(to_local(spot) + Vector2(-10 + 10 * i, -14), 3.0, Color(Palette.HEARTLIGHT, 0.9))

func _light_spot(light: int) -> Vector2:
	for source in _sources:
		if int(source.light) == light and is_instance_valid(source.tower):
			return source.tower.global_position
	return Vector2.ZERO
