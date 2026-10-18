extends Node2D
# What the Sporeling, Dewdrop and Bellflower class scripts share (dream_council_review.md 20 "Shared rules"; the
# Firefly Jar's firefly_lights.gd is the model): who a card works for, the four distances, the route by steps, the
# free hit and the nap. Each class script extends this, sets FAMILY / LINE through _family() and _line(), and listens
# to damage events (on_damage) and a poll (on_poll). DreamState makes the three nodes in the world, beside
# FireflyLights. No class_name: DreamState preloads the class scripts.
# Every number is a paper starting value (Balancing tunes them after the owner's playtest).

const TOUCH_CELLS := 1.0  # Two Wardens touching: centres within 1 cell on both axes; two nightmares: within 1 cell
const PATH_TOUCH_CELLS := 1.25  # A Warden touches path: a route point within 1.25 cells of its centre on both axes
const NEAR_CELLS := 2.0  # Near: within 2 cells on both axes
const FREE_HIT_EVERY := 1.0  # One free hit per Warden a second, across every card
const NAP_SECONDS := 1.0  # The one nap rule: fixed 1 s, never on a sleeper, never bosses
const POLL := 0.1
const FREE_HIT_TAG := &"free_hit"
const FREE_META := &"ck_free_next"  # On a Warden: when it may give its next free hit
# What every lent card means by "a Reaction" (council 2026-10-15: one list for Reprise, Chain of Lanterns, Old Rain):
# the Reactions' burst damage tags, crowned ones included; never an Echo Hollow echo or a carried storm.
const REACTION_BURSTS: Array[StringName] = [&"thunderclap", &"ignite", &"shatter", &"pinned", &"lightning_rod",
	&"avalanche", &"starfall", &"fever_dream", &"drown", &"popped", &"tempest", &"mushrooming", &"smother"]

static func is_reaction_burst(event) -> bool:
	return event.tag in REACTION_BURSTS or (event.kind == &"reaction" and event.tag != &"echo" and event.tag != &"carried_storm")
# Damage tags the class cards deal with. Nothing tagged with one of these sets a class rule off again.
const CLASS_TAGS: Array[StringName] = [&"free_hit", &"fork", &"toll", &"spore_haze", &"swell", &"both_banks", &"breakwater",
	&"riptide", &"carried_ring", &"rounds", &"hanging_note", &"sleep_no_more", &"refrain", &"chorus_repeat", &"knell",
	&"in_time", &"reprise", &"rude_replay", &"da_capo"]  # (Bellflower repeats, 2026-10-15)

var dream_state: Node  # DreamState (untyped: DreamState preloads the class scripts)
var _hooked := false
var _poll_in := 0.0
var _route := PackedVector2Array()  # The route's points, start to Heartwood (half-cell steps: 2 points = 1 step)
var _route_px: Array = []  # Vector2: each point in px
var _index := {}  # Route point -> its index
var _route_serial := -1
var _board := -1

func _family() -> String:
	return ""

func _line() -> String:
	return ""

# The card rule ids this script acts on when the family was NOT the first pick (its lent cards).
func _lent_rules() -> Array:
	return []

func _ready() -> void:
	z_index = -1  # With the ground: under Wardens and nightmares
	if dream_state != null and dream_state.get("drift_director") != null:
		dream_state.drift_director.rest_started.connect(_rest_started.unbind(4))

func _rest_started() -> void:
	on_rest()

func on_rest() -> void:
	pass

# Every damage event while this class or one of its lent cards is on. `source`: the Warden credited, or null.
# `is_hit`: a Warden's own hit (never a tick, a bolt, a Reaction or anything a class card dealt). `tagged`: a class
# card or a Reaction dealt it: nothing but a dispel may be read from it.
func on_damage(_event, _source, _enemy, _is_hit: bool, _dispel: bool, _tagged: bool) -> void:
	pass

func on_poll() -> void:
	pass

func on_board() -> void:
	pass

# --- Who this is on for ---------------------------------------------------------------------------------------------

func class_on() -> bool:
	return dream_state != null and dream_state.calling == _family()

func rule(id: StringName) -> bool:
	return dream_state != null and dream_state.has_rule(id)

# A Calling evolution on the path (DreamState.calling_path; scripts/combat/calling_paths.gd). Only the Calling's own
# family ever has them, so it implies class_on().
func evo(id: StringName) -> bool:
	return dream_state != null and class_on() and dream_state.has_evolution(id)

# Credit an effect to its card or evolution (DreamState.note_card: callouts and the rest report).
func credit(id: StringName, at: Vector2 = Vector2.INF, source = null) -> void:  # source: the Warden (badge pop; visual feedback spec B5, owner 2026-10-18)
	if dream_state != null:
		dream_state.note_card(id, at, 1, source if is_instance_valid(source) and source is Node else null)

# --- Setup credit 2026-10-16 (scripts/run/setup_credit.gd; balance_simulation.md "Setup cards") -------------------------
const SETUP := preload("res://scripts/run/setup_credit.gd")

# The card id for a rule (or the evolution id itself).
func card_id(id: StringName) -> String:
	return SETUP.rule_card(dream_state, id)

# `id` added `stacks` of `status` to `enemy` quietly (add_quiet's return): the ledger.
func setup_quiet(enemy, id: StringName, status: StringName, stacks: int) -> void:
	if stacks > 0:
		SETUP.note(enemy, card_id(id), status, float(stacks), true)

# A Warden's non-native application made by card or evolution `id` (its stacks go in the ledger under `id`).
func setup_apply(id: StringName, tower, enemy, status: StringName, stacks: int, soothe: float) -> void:
	if not is_instance_valid(tower) or not living(enemy):
		return
	SETUP.begin(StringName(card_id(id)))
	tower._apply_one_status(enemy, status, stacks, soothe, false)
	SETUP.end()

func control(id: StringName, seconds: float) -> void:
	SETUP.control(dream_state, id, seconds)

func control_slow(id: StringName, amount: float, seconds: float) -> void:
	SETUP.control_slow(dream_state, id, amount, seconds)

func lent_on() -> bool:
	for id in _lent_rules():
		if rule(id):
			return true
	return false

# Whether any of this family's rules is on, cached against the run's rule map (DreamState._rule_map() hands back the
# same dictionary until the taken cards change) and the Calling: _on_damage asks it for every damage event, and
# the dozen has_rule calls behind it were ~1 ms a frame per class node on a busy field (Enemy Code perf, 2026-10-17).
var _active_map = null
var _active_calling := ""
var _active := false
var _active_key := Vector3i(-1, -1, -1)  # Frame x rules_stamp x stacks: repeat asks in a frame skip even _rule_map (perf, Main Merger 2026-10-17)

func active() -> bool:
	if dream_state == null:
		return false
	var key := Vector3i(Engine.get_process_frames(), dream_state.rules_stamp, dream_state.stacks.size())
	if key == _active_key and dream_state.calling == _active_calling:
		return _active
	_active_key = key
	var map: Dictionary = dream_state._rule_map()
	if not is_same(map, _active_map) or dream_state.calling != _active_calling:
		_active_map = map
		_active_calling = dream_state.calling
		_active = class_on() or lent_on() or _legacy_on()
	return _active

# The Calling's setup (mushrooms and doses, water and the ripple, the ring count, pips and Tolls) is the first pick's only
# (owner 2026-10-14, dream_council_review.md 25 "lent cards never give the Calling's abilities"): lent cards never switch
# it on and never read it. The one exception is an old save: a later owner already holding a card that was retired or
# moved to class-only keeps that card's old effect on Continue (_legacy_rules).
func place_on() -> bool:
	return class_on() or _legacy_on()

# Retired or moved card ids that needed the setup when a later owner could hold them (old saves only).
func _legacy_rules() -> Array:
	return []

func _legacy_on() -> bool:
	for id in _legacy_rules():
		if rule(id):
			return true
	return false

# A Warden's own status application was accepted on a nightmare (DreamState.class_status, from Tower._apply_one_status;
# never for carried or free applications). `stacks`: what it added.
func status_applied(_tower, _enemy, _status: StringName, _stacks: int) -> void:
	pass

func cell() -> float:
	return Tower.MAP_GRID.cell_size.x

func now() -> float:
	return dream_state._game_clock

func resting() -> bool:
	return dream_state.drift_director != null and dream_state.drift_director.resting

# --- Who a card works for -------------------------------------------------------------------------------------------

# A Warden of this family, any form.
func is_own(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.line == _line() and tower.tower_data.can_attack

# Any other Warden: every attacking Warden not of this family, Sprouts included.
func is_other(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.can_attack and tower.tower_data.line != _line() \
		and tower.tower_data.line != "wall"

# Another family's Warden: not this family, not a Sprout, not a wall.
func is_other_family(tower) -> bool:
	return is_other(tower) and tower.tower_data.get_id() != "sprout"

static func is_wall(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.line == "wall"

static func living(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.is_cleansed and enemy.health > 0

func towers() -> Array:
	return get_tree().get_nodes_in_group(Tower.GROUP).filter(_tower_ok)

func _tower_ok(tower) -> bool:
	return is_instance_valid(tower) and not tower.is_queued_for_deletion() and tower.tower_data != null

# This family's Wardens, cached for the frame (council 2026-10-15: every status landing asked for them several times).
var _own_cache: Array = []
var _own_frame := -1

func own_towers() -> Array:
	var frame := Engine.get_process_frames()
	if frame != _own_frame:
		_own_frame = frame
		_own_cache = towers().filter(is_own)
	return _own_cache.filter(_tower_ok)

func enemies() -> Array:
	return get_tree().get_nodes_in_group(Tower.ENEMY_GROUP).filter(living)

# The status a Warden's own attack adds ("" = none; never Rooted: no class card adds, counts or speeds it).
static func status_of(tower) -> StringName:
	if not (tower is Tower) or tower.attack_data == null:
		return &""
	return Tower.first_status(tower.attack_data)  # (A special's status too: the Sparkler's Charge; never Roots)

# --- Distances ------------------------------------------------------------------------------------------------------

func within(a: Vector2, b: Vector2, cells: float) -> bool:
	var reach := cells * cell() + 1.0
	return absf(a.x - b.x) <= reach and absf(a.y - b.y) <= reach

func touching(a, b) -> bool:
	return a != b and within(a.global_position, b.global_position, TOUCH_CELLS)

func near(a: Vector2, b: Vector2) -> bool:
	return within(a, b, NEAR_CELLS)

func touches_point(tower, at: Vector2) -> bool:
	return within(tower.global_position, at, PATH_TOUCH_CELLS)

# The strongest Warden passing `test` that is near `at` (2 cells), or null.
func strongest_near(at: Vector2, test: Callable, skip = null):
	var best = null
	var best_dps := -1.0
	for tower in towers():
		if tower == skip or not test.call(tower) or not near(tower.global_position, at):
			continue
		var dps: float = tower.get_damage() * tower.get_attacks_per_second()
		if dps > best_dps:
			best_dps = dps
			best = tower
	return best

func nightmares_touching(enemy, limit: int) -> Array:
	var at: Vector2 = enemy.global_position
	var reach := TOUCH_CELLS * cell()
	var found: Array = []
	for other in Tower.nightmares_near(get_tree(), at, reach):
		if other != enemy and living(other) and other.global_position.distance_to(at) <= reach:
			found.append(other)
	found.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	return found.slice(0, limit)

# --- The route ------------------------------------------------------------------------------------------------------

func _refresh_route() -> bool:
	var serial: int = dream_state.batch.route_serial
	if serial == _route_serial and not _route.is_empty():
		return false
	_route_serial = serial
	var map = dream_state.map_generator
	_route = map.get_path_from(map.startPath)
	_route_px.clear()
	_index.clear()
	for i in _route.size():
		_route_px.append(Tower.MAP_GRID.calculate_map_position(_route[i]))
		_index[_route[i]] = i
	return true

# A walking nightmare's place on the route (-1: a flyer, or off the route).
func index_of(enemy) -> int:
	if enemy.is_flying():
		return -1
	var i := int(_index.get(enemy.get_target_cell(), -1))
	if i >= 0 and enemy.global_position.distance_squared_to(_route_px[i]) <= cell() * cell():
		return i  # Its next step is on the route and close by: the usual case
	return nearest_point(enemy.global_position, 0.75)  # Placed, pushed or pulled off its usual step: where it stands

# The route point nearest `at`, if within `cells` of it (-1: none).
func nearest_point(at: Vector2, cells: float) -> int:
	var best := -1
	var best_d := (cells * cell()) ** 2
	for i in _route_px.size():
		var d: float = at.distance_squared_to(_route_px[i])
		if d <= best_d:
			best_d = d
			best = i
	return best

# The route indices a Warden touches (the path rule).
func points_touching(tower) -> Array:
	var found: Array = []
	for i in _route_px.size():
		if touches_point(tower, _route_px[i]):
			found.append(i)
	return found

# The route indices inside a Warden's reach.
func points_in_reach(tower) -> Array:
	var found: Array = []
	var reach: float = tower.get_range_pixels()
	for i in _route_px.size():
		if tower.global_position.distance_to(_route_px[i]) <= reach:
			found.append(i)
	return found

# --- Free hits and naps ---------------------------------------------------------------------------------------------

func second_of(tower) -> float:
	return tower.get_damage() * tower.get_attacks_per_second()

# The one free-hit rule: that nightmare only; the Warden's hit, never more than one second of its damage (x `scale`);
# its status once, as its own application; one per Warden a second across every card (extra ones are dropped). It is
# not a hit for anything else: its tag keeps it out of every count.
# `cap`: the most it may deal (Caught Wading: the Dewdrop's own hit).
func free_hit(tower, enemy, scale: float = 1.0, tag: StringName = FREE_HIT_TAG, cap: float = INF, own: StringName = &"") -> bool:
	if not (tower is Tower) or not is_instance_valid(tower) or not living(enemy) or tower.attack_data == null:
		return false
	if now() < float(tower.get_meta(FREE_META, -INF)):
		return false
	tower.set_meta(FREE_META, now() + FREE_HIT_EVERY)
	var amount: float = minf(minf(tower.get_damage(), second_of(tower)) * scale, cap)
	if amount <= 0.0:
		return false
	_line_fx(tower.global_position, enemy.global_position, 3.0)
	_own_begin(own, enemy)
	enemy.take_damage(amount, tower.tower_data.line, false, false, tower, tag)
	_own_end(own)
	var status := status_of(tower)
	if status != &"" and living(enemy):
		tower._apply_one_status(enemy, status, maxi(int(tower.attack_data.status_stacks), 1), tower.get_damage(), false)
	return true

# Damage a card deals in a Warden's name (never a hit for anything else: `tag` is one of CLASS_TAGS).
# `own` (setup credit 2026-10-16): the evolution or card id this damage is credited to as its own (DreamState.begin_own_hit).
func strike(tower, enemy, amount: float, tag: StringName, is_area: bool = false, own: StringName = &"") -> void:
	if amount <= 0.0 or not living(enemy):
		return
	var line: String = tower.tower_data.line if tower is Tower and is_instance_valid(tower) else _line()
	_own_begin(own, enemy)
	enemy.take_damage(amount, line, is_area, false, tower if is_instance_valid(tower) else null, tag)
	_own_end(own)

func _own_begin(own: StringName, enemy) -> void:
	if own != &"" and dream_state != null:
		dream_state.begin_own_hit(own, enemy)

func _own_end(own: StringName) -> void:
	if own != &"" and dream_state != null:
		dream_state.end_own_hit()

# The one nap rule: 1 s, never on a sleeper, never a boss. True when it fell asleep.
func nap(enemy) -> bool:
	if not living(enemy) or enemy.statuses.is_boss or enemy.statuses.is_asleep():
		return false
	return enemy.statuses.sleep(NAP_SECONDS) and enemy.statuses.is_asleep()

# A thin line between two points for a moment (free hits, carried stacks): the card's "what you see", in placeholder form.
func _line_fx(from: Vector2, to: Vector2, width: float, color: Color = Palette.HEARTLIGHT) -> void:
	var world := Reactions._world(self)
	if world != null:
		world.add_child(ChainBolt.new(PackedVector2Array([from, to]), color, width))

# --- The loop -------------------------------------------------------------------------------------------------------

# Perf (Enemy Code's probe6, 2026-10-17): the DamageLog dispatch per damage event cost ~0.15 ms a frame for each idle
# node, so it is connected only while a rule of this family is on (checked each frame from the cached rule map).
var _hooked_log: Object = null

# DreamState calls it when cards or the Calling change, so a hit in the same frame is heard.
func sync_hook() -> void:
	_sync_hook(active())

func _sync_hook(on: bool) -> void:
	var want: Object = DamageLog.instance if on else null
	if want == _hooked_log:
		return
	if _hooked_log != null and is_instance_valid(_hooked_log) and _hooked_log.damage_dealt.is_connected(_on_damage):
		_hooked_log.damage_dealt.disconnect(_on_damage)
	_hooked_log = want
	_hooked = want != null
	if want != null and not want.damage_dealt.is_connected(_on_damage):
		want.damage_dealt.connect(_on_damage)

func _process(delta: float) -> void:
	if dream_state == null:
		return
	_sync_hook(active())  # Listens to DamageLog only while this family's rules are on (perf)
	if not active():
		return
	if _refresh_route() or _board != int(dream_state.board_version):
		_board = int(dream_state.board_version)
		on_board()
	_poll_in -= delta
	if _poll_in <= 0.0:
		_poll_in = POLL
		on_poll()

func _on_damage(event) -> void:
	if dream_state == null or not active() or not is_instance_valid(event.enemy):
		return
	var tagged: bool = event.tag in CLASS_TAGS or event.kind == &"reaction"
	var source = event.source if is_instance_valid(event.source) and event.source is Tower else null
	var dispel: bool = event.enemy.health <= 0
	if (tagged or source == null) and not dispel:
		return
	var is_hit: bool = source != null and not tagged and event.kind == &"hit" and event.tag == &""
	on_damage(event, source, event.enemy, is_hit, dispel, tagged or source == null)
