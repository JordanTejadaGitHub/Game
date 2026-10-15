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
const LIVE_WIRE_SHARE := 0.5  # Nothing Wasted's Live Wire part: half the hit, per dispel (owner 2026-10-13: never more than the Calling)
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
# Lent, 2026-10-14 (lent_noplace_sporeling_firefly.md with dream_council_review.md 26's fixes)
const SPARKS_FLY := &"sparks_fly"
const SPARKS_EVERY_HIT := 3  # Sparks Fly: every 3rd hit a Warden lands on a nightmare…
const SPARKS_WINDOW := 2.0  # …a Firefly Warden hit in the last 2 s…
const SPARKS_SHARE := 0.5  # …jumps on at half
const FLASHOVER := &"flashover"
const FLASHOVER_SHARE := 0.5  # Flashover: an area attack on 2+ nightmares jumps half to the nearest one it missed
const FLASHOVER_MIN := 2
const SPARKLERS := ["sparkler", "starburst"]  # Firefly area forms: they count for Flashover beside another Firefly Warden
const THUNDERSTRUCK := &"thunderstruck"
const THUNDER_SHARE := 0.25  # Thunderstruck: a heavy hit on a Charged nightmare fans a quarter to every Charged one near it…
const THUNDER_MAX := 6  # …up to this many
const BRUSHFIRE := &"brushfire"
const BRUSH_SHARE := 0.5  # Brushfire: half a Charged nightmare's damage over time, each second
const BRUSH_EVERY := 1.0
const BRUSH_TAGS: Array[StringName] = [&"spored", &"cloud", &"fog"]  # Damage over time (not bolts, Reactions or jumps)
const GATHERING_STORM := &"gathering_storm"
const GATHER_STEP := 0.25  # Gathering Storm: each jump a nightmare takes makes the next 25% stronger…
const GATHER_MAX := 2.0  # …up to double…
const GATHER_RESET := 2.0  # …reset after 2 s without one
const CHAIN_REACTIONS: Array[StringName] = [&"thunderclap", &"ignite", &"lightning_rod", &"tempest"]  # Reactions that spend Charged
const SPARKS_META := &"ff_sparks"  # On a nightmare: {Warden id: hits counted}
const FF_HIT_META := &"ff_firefly_hit"  # On a nightmare: [time, WeakRef]: the last Firefly Warden hit (Sparks Fly)
const SPARKS_FRAME_META := &"ff_sparks_frame"  # On a Warden: the frame its last hit was counted (an area attack counts once)
const GATHER_META := &"ff_gather"  # On a nightmare: [jumps, last time] (Gathering Storm)
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
var _flashes := {}  # Flashover: Warden id -> {frame, source: WeakRef, hits: Array, base}: one attack's hits, struck next frame
var _brush := {}  # Brushfire: nightmare id -> {enemy: WeakRef, source: WeakRef, amount}: this second's damage over time
var _brush_in := BRUSH_EVERY
var _heavy_now := false  # This event is a new heavy attack (worked out once per event: _new_heavy_attack has a clock)
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

# Lent cards never give the Calling's setup (owner 2026-10-14, dream_council_review.md 25-26): Lit, the glow, lights and
# gold path are the first pick's only. The lent cards work from Firefly Wardens, where Wardens stand, their attacks and
# Charged; they never read Lit (no sources_at, nearest_lit or is_lit in a lent path).
const LENT_RULES: Array[StringName] = [HAMMERFALL, KNOCK_ON, THUNDERSTRUCK, CHAIN_OF_LANTERNS, NOTHING_WASTED, LENT_CROSSFIRE,
	SPARKS_FLY, FLASHOVER, BRUSHFIRE, GATHERING_STORM, LENT_LIVE_WIRE, LIKE_TO_LIKE]  # (Live Wire, Like to Like: retired; old saves)

func _lent_on() -> bool:
	for id in LENT_RULES:
		if _rule(id):
			return true
	return false

# Cards retired or moved to class-only that worked in the light when a later owner could hold them: an old save holding
# one keeps the lights on Continue (the "keep a retired card's effect" convention).
const LEGACY_LIT: Array[StringName] = [SPOTLIGHT, SIGNAL_FIRES]

# Whether the lights are worked out: the Firefly start (or an old save's legacy card).
func _lit_on() -> bool:
	if class_on():
		return true
	for id in LEGACY_LIT:
		if _rule(id):
			return true
	return false

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

# Any other attacking Warden: not this family, not a wall; Sprouts count.
static func is_other(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.can_attack and tower.tower_data.line != LINE \
		and tower.tower_data.line != "wall"

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
	var on := _lit_on()
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
	if not _flashes.is_empty():
		_flash_over()
	if not _brush.is_empty() and not get_tree().paused:
		_brush_in -= delta
		if _brush_in <= 0.0:
			_brush_in = BRUSH_EVERY
			_brush_fire()
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
	if not _lit_on():
		for tower in jars:
			_sources.append({"tower": tower, "sprout": false, "light": _sources.size()})  # Lent cards only ask "near a Firefly Warden"
		return
	var allowed := jars.size() if _rule(LIT_SPROUTS) else 0
	while sprouts.size() > allowed:
		sprouts.pop_back().remove_meta(LIT_SPROUT_META)  # One glowing Sprout per Firefly Warden: a sold Jar frees the newest pick
	var touch := SPROUT_TOUCH * _cell()
	var parent: Array = []  # Union-find over the Jars: glows sharing a path cell are one light
	for i in jars.size():
		parent.append(i)
	var cells_of: Array = []
	var path: Dictionary = dream_state._path_index
	for i in jars.size():
		var mine: Array = []
		var reach := glow_reach(jars[i])
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
	var names := {}  # Union-find root -> the light's stable id: the smallest cell code among its Jars
	for i in jars.size():
		var root := _find(parent, i)
		names[root] = mini(int(names.get(root, 1 << 30)), _cell_code(jars[i]))
	for i in jars.size():
		var light := int(names[_find(parent, i)])
		_sources.append({"tower": jars[i], "sprout": false, "light": light})
		for cell in cells_of[i]:
			_note(cell, light, true)
	for j in sprouts.size():
		var light := -1 - _cell_code(sprouts[j])  # Always its own light (negative ids), and never gold path
		_sources.append({"tower": sprouts[j], "sprout": true, "light": light})
		for cell in path:
			var at: Vector2 = Tower.MAP_GRID.calculate_map_position(cell)
			if absf(at.x - sprouts[j].global_position.x) <= touch and absf(at.y - sprouts[j].global_position.y) <= touch:
				_note(cell, light, false)
	for cell in _glow:
		_max_lit_step = maxi(_max_lit_step, int(path.get(cell, -1)))
	queue_redraw()  # Twice a second at most: the glow follows planting, selling, growing and new cards

# A Warden's cell as one number (half cells count): stable while it stands there.
func _cell_code(tower) -> int:
	return roundi(tower.cell.x * 2.0) * 1000 + roundi(tower.cell.y * 2.0)

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

# How far a Firefly Warden's glow reaches: its attack range as it is now (ranks, forms and cards that add range grow
# it; owner 2026-10-14: "it doesn't grow when range grows"), never less than GLOW_CELLS.
func glow_reach(tower) -> float:
	return maxf(GLOW_CELLS * _cell(), tower.get_range_pixels())

# The sources lighting `at` (by distance, so flyers count).
func sources_at(at: Vector2) -> Array:
	var out: Array = []
	var touch := SPROUT_TOUCH * _cell()
	for source in _sources:
		var tower = source.tower
		if not is_instance_valid(tower):
			continue
		if source.sprout:
			if absf(at.x - tower.global_position.x) <= touch and absf(at.y - tower.global_position.y) <= touch:
				out.append(source)
		elif tower.global_position.distance_to(at) <= glow_reach(tower):
			out.append(source)
	return out

func is_lit(enemy) -> bool:
	return _lit_on() and is_instance_valid(enemy) and not sources_at(enemy.global_position).is_empty()

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
	if dream_state == null or event.tag == FORK_TAG or not is_instance_valid(event.enemy):
		return  # A fork triggers nothing
	if event.kind == &"reaction":
		if _rule(CHAIN_OF_LANTERNS) and event.tag in CHAIN_REACTIONS:
			_chain_more(event)  # A Reaction that spends Charged (by its tag: Thunderclap and Ignite remove Charged first)
		return  # A Reaction's own lightning gets nothing else added
	var on := _lit_on()
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
	# One clock for every heavy rule on this event (a second call would read the clock this one just set)
	_heavy_now = is_hit and (is_heavy(source) or source.tower_data.get_id() == "sprout") \
		and (_rule(SPOTLIGHT) or _rule(HAMMERFALL) or _rule(THUNDERSTRUCK)) and _new_heavy_attack(source)
	if on:
		_class_rules(id, event, source, enemy, dispel, is_hit, is_bolt)
	if lent:
		_lent_rules(id, event, source, enemy, dispel, is_hit, is_bolt)

# Chain of Lanterns on a Reaction that spends Charged: half of it jumps to the 2 nearest other nightmares near it.
func _chain_more(event) -> void:
	var enemy = event.enemy
	var source = event.source if is_instance_valid(event.source) and event.source is Tower else null
	var id := _next_event()
	for target in _near_enemies(enemy.global_position, [enemy]).slice(0, CHAIN_TARGETS):
		_fork(id, source, enemy.global_position, target, event.base * CHAIN_SHARE, _lent_cap(source, null), {"final": true})

# The most a lent card's jump may deal (never "no cap" for another family: brightness() is never asked with no light).
# A Firefly Warden's own jumps stay uncapped, as the Calling's are; another family's are capped at 3 s of the Firefly
# Warden `jar` (the one near it, or the one that Charged the nightmare), or of a base Firefly Jar when there is none.
func _lent_cap(source, jar) -> float:
	if is_instance_valid(source) and is_firefly(source):
		return INF
	if is_instance_valid(jar) and is_firefly(jar):
		return jar.get_damage() * jar.get_attacks_per_second() * BRIGHTNESS_SECONDS
	return _base_jar_dps * BRIGHTNESS_SECONDS

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
	var cap := brightness(source, sources)  # Never an empty list here: the nightmare is Lit
	if dispel:
		var size := _hit_size(source, is_hit, is_bolt)
		var jars := jars_at(sources)
		# Lantern Light; on gold path Where Lights Meet replaces it: one fork per Firefly Warden lighting it.
		var count := mini(jars, MEET_MAX) if jars >= 2 and _rule(WHERE_LIGHTS_MEET) else 1
		var targets := nearest_lit(at, [enemy], count)
		if class_on():  # The Calling's own payoff: the first pick only
			for target in targets:
				_fork(id, source, at, target, size * CALLING_SHARE, cap)
			if targets.is_empty():
				_wait(lights, source, size * CALLING_SHARE, cap)
		if _rule(SIGNAL_FIRES):
			_signal(id, source, at, enemy, lights, size * SIGNAL_SHARE, cap)
		if _rule(LAST_SPARK) and enemy.statuses.has(EnemyStatuses.STATIC):
			var charge: float = enemy.statuses.stored_bolt_damage()
			var spark_to := nearest_lit(at, [enemy])
			if charge > 0.0 and not spark_to.is_empty():
				_fork(_next_event(), enemy.statuses.source(EnemyStatuses.STATIC), at, spark_to[0], charge, INF, {"final": true})
	if is_bolt:
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
		if _heavy_now and is_heavy(source) and _rule(SPOTLIGHT):  # (Spotlight: retired 2026-10-14; an old save keeps it)
			for light in lights:
				if front_in(light) != enemy:
					continue
				var others: Array = _enemies().filter(func(e) -> bool:
					return e != enemy and lights_of(sources_at(e.global_position)).has(light))
				var fan: Array = others.slice(0, SPOTLIGHT_MAX)
				for other in fan:  # The cap covers the whole fan (council, new_lent_td.md)
					_fork(id, source, at, other, minf(event.base * SPOTLIGHT_SHARE, cap / maxf(fan.size(), 1.0)), cap, {"heavy": true})
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
					_fork(id, source, at, targets[0], event.base * AMBUSH_SHARE, cap)

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
	var at: Vector2 = enemy.global_position
	var now := _now()
	if is_bolt:
		# Chain of Lanterns: a bolt also jumps half to the 2 nearest other nightmares near it
		if _rule(CHAIN_OF_LANTERNS):
			var cap_bolt := _lent_cap(source, enemy.statuses.source(EnemyStatuses.STATIC))
			for target in _near_enemies(at, [enemy]).slice(0, CHAIN_TARGETS):
				_fork(id, source, at, target, event.base * CHAIN_SHARE, cap_bolt)
		return
	if is_firefly(source) and event.kind == &"hit" and _rule(SPARKS_FLY):
		enemy.set_meta(FF_HIT_META, [now, weakref(source)])  # Sparks Fly: hit by a Firefly Warden (any form) just now
	if _rule(BRUSHFIRE) and event.tag in BRUSH_TAGS and enemy.statuses.has(EnemyStatuses.STATIC):
		_brush_add(event, source, enemy)
	if is_hit:
		if _rule(LENT_CROSSFIRE):
			_crossfire(id, event, source, enemy, at, now)
		if _rule(NOTHING_WASTED):
			_nothing_wasted(id, event, source, enemy, at)
		if _rule(FLASHOVER):
			_flash_note(event, source, enemy)
		if _rule(SPARKS_FLY) and is_other(source):
			_sparks_fly(id, event, source, enemy, at, now)
	if _heavy_now:
		# Hammerfall: another family's heavy Warden, or a Sprout, near a Firefly Warden jumps half of each attack
		if _rule(HAMMERFALL) and (is_other_family(source) and is_heavy(source) or source.tower_data.get_id() == "sprout"):
			var jar = firefly_near(source)
			var targets := _near_enemies(at, [enemy]) if jar != null else []
			if not targets.is_empty():
				_fork(id, source, at, targets[0], event.base * HAMMER_SHARE, _lent_cap(source, jar), {"heavy": is_heavy(source)})
		# Thunderstruck: another family's heavy Warden's hit on a Charged nightmare fans a quarter to every Charged one near it
		if _rule(THUNDERSTRUCK) and is_other_family(source) and is_heavy(source) and enemy.statuses.has(EnemyStatuses.STATIC):
			var cap_fan := _lent_cap(source, enemy.statuses.source(EnemyStatuses.STATIC))
			var fan: Array = _near_enemies(at, [enemy]).filter(func(e) -> bool: return e.statuses.has(EnemyStatuses.STATIC)).slice(0, THUNDER_MAX)
			for other in fan:  # The cap covers the whole fan
				_fork(id, source, at, other, minf(event.base * THUNDER_SHARE, cap_fan / maxf(fan.size(), 1.0)), cap_fan, {"heavy": true})
	# Live Wire and Like to Like: retired (2026-10-13 / earlier); an old save keeps them
	if not is_other_family(source):
		return
	var jar = firefly_near(source)
	if jar == null:
		return
	var cap: float = jar.get_damage() * jar.get_attacks_per_second() * BRIGHTNESS_SECONDS
	if dispel and _rule(LENT_LIVE_WIRE) and not (class_on() and is_lit(enemy)):  # On a Firefly start it replaces the Calling's jump, never adds one
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

# Nothing Wasted: the damage a nightmare's shell (the blight coat) soaks up from a hit, by a Firefly Warden or a Warden
# near one, jumps to the nearest nightmare near it without a shell. (Resistances are gone, enemy_design.md ed6f573b:
# it read the resisted part before.)
func _nothing_wasted(id: int, event, source, enemy, at: Vector2) -> void:
	if event.coat_soaked <= 0.0:
		return
	var jar = source if is_firefly(source) else firefly_near(source)
	if jar == null:
		return
	for other in _near_enemies(at, [enemy]):
		if float(other.coat) <= 0.0:
			_fork(id, source, at, other, event.coat_soaked, _lent_cap(source, jar))
			return

# Sparks Fly: every 3rd hit a Warden (not a Firefly Warden; Sprouts count) lands on a nightmare a Firefly Warden hit in
# the last 2 s jumps on at half. Counted per Warden and nightmare; an area attack counts once.
func _sparks_fly(id: int, event, source, enemy, at: Vector2, now: float) -> void:
	var lit: Array = enemy.get_meta(FF_HIT_META, [])
	if lit.is_empty() or now - float(lit[0]) > SPARKS_WINDOW:
		return
	if int(source.get_meta(SPARKS_FRAME_META, -1)) == Engine.get_process_frames():
		return
	source.set_meta(SPARKS_FRAME_META, Engine.get_process_frames())
	var counts: Dictionary = enemy.get_meta(SPARKS_META, {})
	var n := int(counts.get(source.get_instance_id(), 0)) + 1
	counts[source.get_instance_id()] = n % SPARKS_EVERY_HIT
	enemy.set_meta(SPARKS_META, counts)
	if n < SPARKS_EVERY_HIT:
		return
	var targets := _near_enemies(at, [enemy])
	if not targets.is_empty():
		_fork(id, source, at, targets[0], event.base * SPARKS_SHARE, _lent_cap(source, lit[1].get_ref()))

# Flashover: one attack's hits are gathered by Warden and frame; the next frame, an area attack that hit 2 or more
# jumps half (of the largest hit) to the nearest nightmare it missed. Another family's Warden near a Firefly Warden;
# Sparkler and Starburst near another Firefly Warden.
func _flash_note(event, source, enemy) -> void:
	var sid: int = source.get_instance_id()
	var frame := Engine.get_process_frames()
	var entry: Dictionary = _flashes.get(sid, {})
	if entry.is_empty() or int(entry.frame) != frame:
		if not entry.is_empty():
			return  # The last attack's hits are still waiting (struck next frame)
		if is_firefly(source) and not SPARKLERS.has(source.tower_data.get_id()):
			return
		if not is_other(source) and not is_firefly(source):
			return
		entry = {"frame": frame, "source": weakref(source), "hits": [], "base": 0.0}
		_flashes[sid] = entry
	entry.hits.append(weakref(enemy))
	entry.base = maxf(float(entry.base), event.base)

func _flash_over() -> void:
	var frame := Engine.get_process_frames()
	for sid in _flashes.keys():
		var entry: Dictionary = _flashes[sid]
		if int(entry.frame) >= frame:
			continue
		_flashes.erase(sid)
		var source = entry.source.get_ref()
		if not is_instance_valid(source) or entry.hits.size() < FLASHOVER_MIN:
			continue
		var jar = firefly_near(source)
		if jar == null:
			continue
		var hit: Array = []
		var centre := Vector2.ZERO
		for ref in entry.hits:
			var e = ref.get_ref()
			if is_instance_valid(e):
				hit.append(e)
				centre += e.global_position
		if hit.is_empty():
			continue
		centre /= hit.size()
		var targets := _near_enemies(centre, hit)
		if not targets.is_empty():
			_fork(_next_event(), source, centre, targets[0], float(entry.base) * FLASHOVER_SHARE, _lent_cap(source, jar), {"final": true})

# Brushfire: a Charged nightmare's damage over time this second, by its source.
func _brush_add(event, source, enemy) -> void:
	var key: int = enemy.get_instance_id()
	var entry: Dictionary = _brush.get(key, {"enemy": weakref(enemy), "source": weakref(source), "amount": 0.0})
	entry.amount = float(entry.amount) + event.amount
	_brush[key] = entry

func _brush_fire() -> void:
	var entries := _brush.values()
	_brush.clear()
	for entry in entries:
		var enemy = entry.enemy.get_ref()
		var source = entry.source.get_ref()
		if not _living(enemy) or not is_instance_valid(source) or not enemy.statuses.has(EnemyStatuses.STATIC):
			continue
		var targets := _near_enemies(enemy.global_position, [enemy])
		if not targets.is_empty():
			var cap := _lent_cap(source, enemy.statuses.source(EnemyStatuses.STATIC))
			if is_firefly(source):
				cap = _lent_cap(null, source)  # Damage over time is never a Firefly hit: always capped
			_fork(_next_event(), source, enemy.global_position, targets[0], float(entry.amount) * BRUSH_SHARE, cap, {"final": true})

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
	if _rule(GATHERING_STORM):
		# Gathering Storm: each jump a nightmare takes makes the next one on it 25% stronger, up to double; re-capped, so
		# another family's jump still never passes its brightness
		var now := _now()
		var gather: Array = target.get_meta(GATHER_META, [0, -INF])
		var taken := int(gather[0]) if now - float(gather[1]) <= GATHER_RESET else 0
		amount = minf(amount * minf(1.0 + GATHER_STEP * taken, GATHER_MAX), float(request.cap))
		target.set_meta(GATHER_META, [taken + 1, now])
	if target.enemy_data != null and target.enemy_data.is_boss:
		amount *= BOSS_SHARE
	var at: Vector2 = target.global_position
	var bolt := ChainBolt.new(PackedVector2Array([request.from, at]), Palette.GOLD, 4.0)
	Reactions._world(self).add_child(bolt)
	forks_thrown += 1
	target.take_damage(amount, source.tower_data.line if source is Tower else LINE, false, false, source, FORK_TAG)
	# A nightmare dispelled by a fork gives no fork. Knock-On is the one exception: a heavy Warden's fork, one more hop.
	if request.get("heavy", false) and not request.get("final", false) and _rule(KNOCK_ON) and not _living(target):
		var next := _near_enemies(at, [target]).slice(0, 1)
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
	if not _resting():
		return "choose at a rest"  # Never mid-drift: a light moved to chase a pack (dream_council_review.md 26, fix 12)
	if sprout.get_meta(LIT_SPROUT_META, false):
		return ""
	var jars := 0
	var lit := 0
	for tower in _towers():
		if is_firefly(tower):
			jars += 1
			if tower.global_position.distance_to(sprout.global_position) <= glow_reach(tower):
				return "already inside a Firefly Warden's glow"
		elif tower.get_meta(LIT_SPROUT_META, false):
			lit += 1
	if lit >= jars:
		return "one glowing Sprout for each Firefly Warden"
	return ""

func _resting() -> bool:
	return dream_state == null or dream_state.get("drift_director") == null or dream_state.drift_director.resting

func set_lit_sprout(sprout, on: bool) -> bool:
	if on and lit_sprout_blocker(sprout) != "":
		return false
	if not on and not _resting():
		return false  # Chosen at a rest only, either way
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

# The glow is a soft band along the path's own line (user 2026-10-13, "fix the lit area": it was a flat square per lit
# cell, centred on whole cells while the path is a half-cell lane, so pale squares with gaps sat on the grass beside
# it). Each lit stretch of the route is three nested round-jointed lines (GLOW_BANDS: wide and dim to narrow and
# bright), so it fades out in three steps with no grid. Gold path is its own stretch, joined end to end.
# One group, one cap (user, the same day, a 102-Warden maze at drift 35: "large and bright, several cells wide ...
# stepped blocks ... the main thing on screen"): the first version added every band and every stretch on top of the
# others, 80 px wide, so close lanes merged into bright slabs. Now the lines are opaque inside one CanvasGroup (a
# brighter band covers a dimmer one, lanes side by side just meet) and the group is added to the map once at
# GLOW_CAP: nowhere is brighter than one lit path's centre, however the maze winds. The bands hug the path's ribbon
# (~40 px) with a few pixels of soft edge.
const GLOW_BANDS: Array[float] = [52.0, 40.0, 26.0]  # px wide, widest first
const GLOW_SHARES: Array[float] = [0.25, 0.5, 0.75]  # Each band's share of GLOW_CAP: a lit path's centre adds 0.75 × the cap
const GOLD_SHARES: Array[float] = [0.35, 0.7, 1.0]  # Gold path: the full cap at its centre
const GLOW_CAP := 0.55  # The most light the glow ever adds (the group's alpha). Owner 2026-10-14 "too faint": was 0.34 (a lit centre ~0.22, now ~0.41)
const GLOW_SHADER := "shader_type canvas_item;\nrender_mode unshaded, blend_add;\nuniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;\nvoid fragment() {\n\tvec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);\n\tif (c.a > 0.0001) {\n\t\tc.rgb /= c.a;\n\t}\n\tCOLOR *= c;\n}\n"
var _glow_lines: Array[Line2D] = []
var _glow_group: CanvasGroup  # Every glow line, flattened, then added to the map once (kept on this node, never static)

func _draw() -> void:
	_lay_glow.call_deferred()  # Lines are nodes: laid after the draw, whenever anything here asked for a redraw
	if not _lit_on():
		return
	for light in _sparks:
		var spot := _light_spot(int(light))
		for i in _sparks[light].size():
			draw_circle(to_local(spot) + Vector2(-10 + 10 * i, -14), 3.0, Color(Palette.HEARTLIGHT, 0.9))

func _exit_tree() -> void:
	if is_instance_valid(_glow_group):
		_glow_group.queue_free()
	_glow_group = null
	_glow_lines.clear()

func _lay_glow() -> void:
	for line in _glow_lines:
		if is_instance_valid(line):
			line.queue_free()
	_glow_lines.clear()
	if not _lit_on() or _glow.is_empty() or dream_state.get("map_generator") == null:
		if is_instance_valid(_glow_group):
			_glow_group.visible = false
		return
	var map: Node2D = dream_state.map_generator
	if not is_instance_valid(_glow_group):
		_glow_group = CanvasGroup.new()
		_glow_group.name = "FireflyGlow"
		_glow_group.fit_margin = 32.0
		_glow_group.clear_margin = 32.0
		var shader := Shader.new()
		shader.code = GLOW_SHADER
		var material := ShaderMaterial.new()
		material.shader = shader
		_glow_group.material = material
		_glow_group.self_modulate = Color(1, 1, 1, GLOW_CAP)  # multiplier: the cap on the added light
		map.path_layer.add_child(_glow_group)  # On the path layer: over the path's ribbon, under everything else
	_glow_group.visible = true
	var ground: Node2D = _glow_group
	var runs: Array = []  # [points, bright, joins_before, joins_after] per lit stretch
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var gold := _rule(WHERE_LIGHTS_MEET)
	var states := PackedInt32Array()  # Per route point: 0 dark, 1 glow, 2 gold path
	for point in route:
		var state := 0
		for cell in dream_state.route_cells(point):
			if _glow.has(cell):
				state = maxi(state, 2 if gold and int(_glow[cell].jars) >= 2 else 1)
		states.append(state)
	var from := 0
	while from < route.size():
		if states[from] == 0:
			from += 1
			continue
		var to := from
		while to + 1 < route.size() and states[to + 1] == states[from]:
			to += 1
		# Where the glow goes on as gold (or the other way), the stretches share the point between them: no gap, no cap
		var joins_before := from > 0 and states[from - 1] != 0
		var joins_after := to + 1 < route.size() and states[to + 1] != 0
		var points := PackedVector2Array()
		for i in range(from, mini(to + 1 if joins_after else to, route.size() - 1) + 1):
			points.append(ground.to_local(map.to_global(Tower.MAP_GRID.calculate_map_position(route[i]))))
		if points.size() == 1:
			points.append(points[0] + Vector2(0.5, 0.0))  # One lit point: a round spot
		runs.append([points, states[from] == 2, joins_before, joins_after])
		from = to + 1
	# Band by band over every stretch, dimmest first: a lane's bright centre is never covered by its neighbour's edge
	for band in GLOW_BANDS.size():
		for run: Array in runs:
			var share: float = GOLD_SHARES[band] if run[1] else GLOW_SHARES[band]
			var base: Color = Palette.GOLD if run[1] else Palette.GLOW
			var line := Line2D.new()
			line.points = run[0]
			line.width = GLOW_BANDS[band]
			line.default_color = Color(base.r * share, base.g * share, base.b * share, 1.0)  # multiplier: the band's share of the light (opaque in the group)
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			line.begin_cap_mode = Line2D.LINE_CAP_NONE if run[2] else Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_NONE if run[3] else Line2D.LINE_CAP_ROUND
			line.round_precision = 6
			line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ground.add_child(line)
			_glow_lines.append(line)

func _light_spot(light: int) -> Vector2:
	for source in _sources:
		if int(source.light) == light and is_instance_valid(source.tower):
			return source.tower.global_position
	return Vector2.ZERO
