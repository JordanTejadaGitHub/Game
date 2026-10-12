class_name HelperCommons
extends RefCounted

# Helper Commons 286–303, Tower Code's combat hooks (dream_design.md ae90720e; numbers balance_simulation.md 6075f796;
# rule id = card id, Roguelite Code's data). Tower calls these; the run-wide lookups (the leader, the top-ranked
# Warden, the field count, Stung's block) are computed once a frame for every Warden.

const NARROW_WAY := 0.25  # Wardens beside a one-half-wide stretch of path
const WEARY_PER := 0.01  # Weary Feet: +1% per WEARY_TILES path tiles walked…
const WEARY_TILES := 4.0
const WEARY_MAX := 0.25  # …up to +25%
const WIDE_SWING_EVERY := 3  # Wide Swing: every 3rd area attack…
const WIDE_SWING := 0.75  # …hits 0.75 cells wider
const SCATTER_HITS := 3  # Scatter: an area attack hitting 3+…
const SCATTER_SLOW := 0.25  # …slows them 25%…
const SCATTER_TIME := 1.5  # …for 1.5 s
const RUSH_FIELD := 10  # Rush: while 10+ nightmares are on the field…
const RUSH := 0.20  # …all Wardens attack 20% faster
const FIRST_AMONG_EQUALS := 0.50  # The highest-rank Warden deals +50%
const GROWTH_RINGS := 0.15  # Each Nurture rank +0.25 range instead of +0.1 (this on top of Tower.RANK_RANGE)
const HOBBLE_SLOW := 0.30  # Hobble: a crit slows 30%…
const HOBBLE_TIME := 1.0  # …for 1 s
const HEAD_OF_THE_LINE := 0.25  # +25% on the nightmare furthest along
const STUNG_PER := 0.10  # Stung: +10% per leaf lost this block…
const STUNG_MAX := 0.30  # …up to +30%, until the rest
const FOREST_FLOOR := 0.20  # Wardens touching an obstacle
const TWIN_STRIKE := 0.20  # On a nightmare its kin hit in the last second
const TWIN_WINDOW := 1.0
const CLOSE_QUARTERS := 0.20  # Kin touching each other attack 20% faster
const PLACE_CHECK := 1.0  # Seconds between a Warden's place checks (Narrow Way, Forest Floor, Close Quarters)

# --- Groups ----------------------------------------------------------------------------------------------------

# "An area Warden" (Wide Swing / Scatter's Need): its attack covers an area (splash, pulse / spin, cloud, sweep).
static func is_area_attack(data: TowerData) -> bool:
	if data == null or not data.can_attack:
		return false
	return Tower.attack_shape(data) in [&"splash", &"area", &"cloud"] or data.attack_kind == TowerData.AttackKind.SWEEP

# --- Once a frame, for every Warden --------------------------------------------------------------------------------

static var _frame := -1
static var _leader: Node2D = null
static var _top: Tower = null
static var _field := 0
static var _stung := 0.0
static var _stung_block := -1
static var _stung_base := 0

static func _refresh(tower: Tower) -> void:
	var frame := Engine.get_process_frames()
	if frame == _frame:
		return
	_frame = frame
	var tree := tower.get_tree()
	_leader = null
	_field = 0
	var best := INF
	for e in tree.get_nodes_in_group(Tower.ENEMY_GROUP):
		if not is_instance_valid(e) or e.is_cleansed:
			continue
		_field += 1
		var left: float = e.get_remaining_distance()
		if left < best:
			best = left
			_leader = e
	_top = null
	for t in tree.get_nodes_in_group(Tower.GROUP):
		if t is Tower and t.rank > 0 and (_top == null or t.rank > _top.rank or (t.rank == _top.rank and t.invested_dew > _top.invested_dew)):
			_top = t
	_stung = 0.0
	var ds := tower._dream_state
	if ds != null and ds.drift_director != null and ds.run_state != null and not ds.drift_director.is_build_phase():
		var block: int = ds.drift_director.get_block(maxi(ds.drift_director.drifts_started, 1))
		if block != _stung_block:
			_stung_block = block
			_stung_base = ds.run_state.leaves_lost
		_stung = minf(STUNG_PER * (ds.run_state.leaves_lost - _stung_base), STUNG_MAX)
	elif ds != null and ds.run_state != null:
		_stung_block = -1  # A rest: the next block counts from its own start

# Perf (mobile pass): whether the run holds any of these cards, once a frame (most runs hold none: one check a hit).
const RULES: Array[StringName] = [&"weary_feet", &"head_of_the_line", &"first_among_equals", &"stung", &"narrow_way",
	&"forest_floor", &"twin_strike", &"hobble", &"rush", &"close_quarters"]
static var _any_frame := -1
static var _any_key := -1
static var _any := false

static func any_held(tower: Tower) -> bool:
	var ds := tower._dream_state
	if ds == null:
		return false
	var frame := Engine.get_process_frames()
	var key := ds.rules_stamp * 4099 + ds.stacks.size()  # A card taken mid-frame counts at once (tests do that)
	if frame != _any_frame or key != _any_key:
		_any_frame = frame
		_any_key = key
		_any = RULES.any(func(r: StringName) -> bool: return tower._has_rule(r))
	return _any

# --- Hit damage -----------------------------------------------------------------------------------------------------

static func hit_multiplier(tower: Tower, enemy: Node2D) -> float:
	if not any_held(tower):
		return 1.0
	var m := 1.0
	if tower._has_rule(&"weary_feet"):
		var tiles: float = float(enemy._path_index) * 0.5  # Route points are half a tile apart
		m *= 1.0 + minf(WEARY_PER * floorf(tiles / WEARY_TILES), WEARY_MAX)
	if tower._has_rule(&"head_of_the_line") or tower._has_rule(&"first_among_equals") or tower._has_rule(&"stung"):
		_refresh(tower)
		if enemy == _leader and tower._has_rule(&"head_of_the_line"):
			m *= 1.0 + HEAD_OF_THE_LINE
		if tower == _top and tower._has_rule(&"first_among_equals"):
			m *= 1.0 + FIRST_AMONG_EQUALS
		if _stung > 0.0 and tower._has_rule(&"stung"):
			m *= 1.0 + _stung
	if tower._has_rule(&"narrow_way") and place_flags(tower).narrow:
		m *= 1.0 + NARROW_WAY
	if tower._has_rule(&"forest_floor") and place_flags(tower).forest:
		m *= 1.0 + FOREST_FLOOR
	if tower._has_rule(&"twin_strike") and _kin_hit_recently(tower, enemy):
		m *= 1.0 + TWIN_STRIKE
	return m

static func _kin_hit_recently(tower: Tower, enemy: Node2D) -> bool:
	var partner := tower._kin_partner()
	if not is_instance_valid(partner) or not enemy.has_meta(&"kin_hits"):
		return false
	var theirs: Array = enemy.get_meta(&"kin_hits").get(partner.get_instance_id(), [])
	return not theirs.is_empty() and tower._kin._clock - float(theirs[0]) <= TWIN_WINDOW

# A crit's Hobble: the nightmare slowed 30% for 1 s.
static func after_crit(tower: Tower, enemy: Node2D) -> void:
	if any_held(tower) and is_instance_valid(enemy) and not enemy.is_cleansed and tower._has_rule(&"hobble"):
		slow(enemy, HOBBLE_SLOW, HOBBLE_TIME)

static func slow(enemy: Node2D, amount: float, seconds: float) -> void:
	var s: EnemyStatuses = enemy.statuses
	s.slow_amount = maxf(s.slow_amount if s.slow_time > 0.0 else 0.0, amount)
	s.slow_time = maxf(s.slow_time, seconds)

# --- Attack speed ----------------------------------------------------------------------------------------------------

static func speed_bonus(tower: Tower) -> float:
	if not any_held(tower):
		return 0.0
	var bonus := 0.0
	if tower._has_rule(&"rush"):
		_refresh(tower)
		if _field >= RUSH_FIELD:
			bonus += RUSH
	if tower._has_rule(&"close_quarters") and place_flags(tower).close_kin:
		bonus += CLOSE_QUARTERS
	return bonus

# --- Area attacks (Wide Swing, Scatter) ---------------------------------------------------------------------------------

# Called once per area attack (a pulse, a splash landing, a cloud dropped): the extra radius in cells for this one.
static func area_attack_extra(tower: Tower) -> float:
	if not tower._has_rule(&"wide_swing"):
		return 0.0
	var count := int(tower.get_meta(&"area_attacks", 0)) + 1
	tower.set_meta(&"area_attacks", count)
	return WIDE_SWING if count % WIDE_SWING_EVERY == 0 else 0.0

# Wide Petals (card_review_2026-10-12.md 10): pulses reach wider too. Splashes and clouds get it from
# DreamState.get_area_radius_add; a pulse adds this to the swing of each release.
static func pulse_extra(tower: Tower) -> float:
	return DreamState.WIDE_PETALS_RADIUS if tower._has_rule(&"wide_petals") else 0.0

# After an area attack hit `hit`: Scatter slows them when 3+ were hit.
static func area_attack_hit(tower: Tower, hit: Array) -> void:
	if hit.size() < SCATTER_HITS or not tower._has_rule(&"scatter"):
		return
	for e in hit:
		if is_instance_valid(e) and not e.is_cleansed:
			slow(e, SCATTER_SLOW, SCATTER_TIME)

# --- Where the Warden stands (cached PLACE_CHECK s) ---------------------------------------------------------------------

static func place_flags(tower: Tower) -> Dictionary:
	var cached: Dictionary = tower.get_meta(&"helper_place", {})
	if not cached.is_empty() and tower._anim_time < float(cached.until):
		return cached
	var flags := {"until": tower._anim_time + PLACE_CHECK, "narrow": false, "forest": false, "close_kin": false}
	var ds := tower._dream_state
	var map = ds.map_generator if ds != null else null
	if map != null:
		if tower._has_rule(&"narrow_way"):
			flags.narrow = _beside_narrow(tower, map)
		if tower._has_rule(&"forest_floor"):
			flags.forest = _touching_obstacle(tower, map)
	if tower._has_rule(&"close_quarters"):
		var partner := tower._kin_partner()
		flags.close_kin = is_instance_valid(partner) and _touching(tower.get_halves(), partner.get_halves())
	tower.set_meta(&"helper_place", flags)
	return flags

# A route half the path is only one half wide at: both halves across the route's direction there are blocked.
static func _beside_narrow(tower: Tower, map) -> bool:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var mine := tower.get_halves()
	for i in range(1, route.size() - 1):
		var here: Vector2 = map.pixels_to_half(Tower.MAP_GRID.calculate_map_position(route[i]))
		if not _touching([here], mine):
			continue
		var dir := (route[i + 1] - route[i - 1]).normalized()
		var across := Vector2(-dir.y, dir.x).round()
		if across == Vector2.ZERO:
			continue
		if map.path_layer.is_half_blocked(here + across) and map.path_layer.is_half_blocked(here - across):
			return true
	return false

static func _touching_obstacle(tower: Tower, map) -> bool:
	var mine := tower.get_halves()
	for key in map.obstacles:
		var o: Vector2 = Vector2(key) * 2.0  # An obstacle's key is its half origin / 2
		if _touching([o, o + Vector2(1, 0), o + Vector2(0, 1), o + Vector2(1, 1)], mine):
			return true
	return false

# Whether any half in `a` is on or beside (8 around) a half in `b`.
static func _touching(a: Array, b: Array) -> bool:
	for h in a:
		for k in b:
			if absf(h.x - k.x) <= 1.0 and absf(h.y - k.y) <= 1.0:
				return true
	return false
