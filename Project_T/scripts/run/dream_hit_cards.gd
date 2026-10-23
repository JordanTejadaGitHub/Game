extends RefCounted
# Wardens keep up without Reactions (owner 2026-10-22; dream_council_review.md 30, council finals_*.md): the hit cards.
# They change a Warden's own DIRECT hit only, never a status, a tick, a cloud, a bolt, a jump or a Reaction: Tower calls
# them at the `dealt` stage of Tower._hit (after the statuses took their potency), never on a Pinned / Shatter hit
# (reaction tag) or an effect tick, and passes the pre-card `dealt` to the spills. Every multiplier is noted to DamageLog
# so the x4 card line (DreamState.card_cap_factor, CARD_CAP_ON) counts it. Preloaded as DreamState.HIT_CARDS, instance
# DreamState.hit_cards (no class_name); saved as "hit_cards".
#
# The hook is Tower Code's DreamState.hit_card_multiplier (Tower._hit, `dealt` stage) -> hit_multiplier here. What the
# cards add after a hit (Measured Blow, the Tallest Tree, Run Through) and killing blows (Trophies) come through the hit's own
# DamageLog event (DreamState._on_damage_dealt -> on_damage_event, trophy_dispel).

const FINISHING_BLOW := &"finishing_blow"
const BEARING_DOWN := &"bearing_down"
const OPEN_ROAD := &"open_road"
const CLEAN_STRIKE := &"clean_strike"
const NOWHERE_TO_RUN := &"nowhere_to_run"
const STANDING_TALL := &"standing_tall"
const TROPHIES := &"trophies"
const RUN_THROUGH := &"run_through"
const MEASURED_BLOW := &"measured_blow"
const TALLEST_TREE := &"the_tallest_tree"
const RULES: Array[StringName] = [FINISHING_BLOW, BEARING_DOWN, OPEN_ROAD, CLEAN_STRIKE, NOWHERE_TO_RUN, STANDING_TALL,
	TROPHIES, RUN_THROUGH, MEASURED_BLOW, TALLEST_TREE]

# Hits these never touch: area effects and copies that only look like hits (Clear Minds' list, council finals_td.md 1).
const SKIP_COMBOS: Array[StringName] = [&"cloud", &"fence", &"echo", &"great_ripple", &"spillover", &"flurry_copy",
	&"conducted", &"run_through", &"measured_blow", &"tallest_tree"]
const CLASS_KIT := preload("res://scripts/combat/class_kit.gd")  # (its CLASS_TAGS: a Calling row's hits are damage only, R1)
const CARRIED_TAG := &"run_through"  # Run Through's carried hits: damage only (DreamState.batch_damage_multiplier skips it)
const MEASURED_TAG := &"measured_blow"  # Measured Blow's added damage
const TALLEST_TAG := &"tallest_tree"  # The Tallest Tree's spent store
const DAMAGE_ONLY_TAGS: Array[StringName] = [CARRIED_TAG, MEASURED_TAG, TALLEST_TAG]  # No statuses, no per-hit cards

# Every number below is a starting point for Balancing (council section 30).
const FINISHING_BONUS := 0.40  # Finishing Blow: +40%…
const FINISHING_SHARE := 1.0 / 3.0  # …on nightmares below a third of their health…
const FINISHING_MIN_RANK := 2  # …from Wardens at rank II or higher
const BEARING_PER := 0.04  # Bearing Down: each attack in a row on the same nightmare +4%…
const BEARING_PER_RANK := 0.10  # …up to 10% for each rank the Warden holds (single-target, never beams)
const OPEN_ROAD_BONUS := 0.25  # Open Road: +25% on a nightmare walking a straight of…
const OPEN_ROAD_CELLS := 4  # …4 or more path cells
const CLEAN_BONUS := 0.25  # Clean Strike: +25% on a nightmare carrying no other family's status…
const CLEAN_FINAL_BONUS := 0.50  # …+50% from a final or Ascended form
const NOWHERE_PER_SECOND := 0.05  # Nowhere to Run: +5% for each second the nightmare has been in that Warden's range…
const NOWHERE_MAX := 0.40  # …up to +40% (branches, finals, Ascended)
const NOWHERE_GAP := 1.5  # A gap longer than this (or 1.5 attacks) between its hits = it left the range: the clock restarts
const STANDING_PER := 0.15  # Standing Tall: a final's direct hits +15% for each attacking base or branch Warden touching it…
const STANDING_MAX_COUNT := 3  # …up to 3 (+45%)
const TROPHY_KILLS := 10  # Trophies: 10 killing blows in one drift…
const TROPHY_BIG := 5  # …a Deeply Blighted nightmare or a boss counts 5…
const TROPHY_STEP := 0.04  # …+4% for the rest of the run, once a drift…
const TROPHY_MAX := 0.40  # …up to +40%
const RUN_THROUGH_SHARE := 0.5  # Run Through: a final's direct hit carries on at half…
const RUN_THROUGH_COUNT := 2  # …to the next 2 nightmares behind its target…
const RUN_THROUGH_CELLS := 2.0  # …within 2 cells along the path
const MEASURED_PER_RANK := 0.01  # Measured Blow: a Warden's first direct hit on a nightmare adds 1% of its max health per rank…
const MEASURED_MIN_RANK := 3  # …from rank III…
const MEASURED_CAP := 0.10  # …at most 10% of a nightmare's max health from this card in all; never bosses
const TALLEST_SHARE := 0.20  # The Tallest Tree: every other Warden's direct hit also stores a fifth of its damage…
const TALLEST_STORE_CAP := 40.0  # …up to 40 times the tree's bare hit…
const TALLEST_SPEND := 6.0  # …and each of the tree's attacks adds at most 6 times its own hit, never past a dispel

var dreams: Node  # DreamState (untyped: DreamState preloads this script)
var _stamp := -1
var _on := {}

# Saved (to_save): Trophies by cell, the Tallest Tree's cell and store.
var trophies := {}  # "x,y" (half-cell key) -> {"drift": n, "kills": k, "steps": s}
var tallest_cell := Vector2.INF
var tallest_store := 0.0

var _bearing := {}  # Tower instance id -> [target id, last attack count, attacks in a row]
var _nowhere := {}  # "x,y:enemy id" -> [first time, last time]
var _measured := {}  # "x,y:enemy id" -> true: that Warden's first hit on that nightmare was spent
var _standing := {}  # Tower instance id -> count, for _standing_board
var _standing_board := -1
var _straights := {}  # Route point -> length of the straight run (whole cells) it is on, for _straight_serial
var _straight_serial := -1
var _tallest_attack := -1  # The tree's attack count that last spent
var _ctx := []  # The hit hit_multiplier just saw: [tower, enemy, is_area, multiplier] (on_damage_event reads it once)

func _init(owner_dreams: Node = null) -> void:
	dreams = owner_dreams

func live() -> bool:
	if dreams == null:
		return false
	if _stamp != int(dreams.rules_stamp):
		_stamp = int(dreams.rules_stamp)
		_on.clear()
		for rule in RULES:
			if dreams.has_rule(rule):
				_on[rule] = true
	return not _on.is_empty()

func to_save() -> Dictionary:
	return {"trophies": trophies.duplicate(true), "tallest": [tallest_cell.x, tallest_cell.y] if tallest_cell != Vector2.INF else [],
		"store": tallest_store}

func load_save(data: Dictionary) -> void:
	trophies = Dictionary(data.get("trophies", {})).duplicate(true)
	var tallest: Array = data.get("tallest", [])
	tallest_cell = Vector2(float(tallest[0]), float(tallest[1])) if tallest.size() == 2 else Vector2.INF
	tallest_store = float(data.get("store", 0.0))

static func cell_key(cell: Vector2) -> String:
	return "%d,%d" % [roundi(cell.x * 2.0), roundi(cell.y * 2.0)]

static func is_court(tower) -> bool:  # An attacking Warden that isn't a Sprout or a wall
	return tower is Tower and is_instance_valid(tower) and tower.tower_data.can_attack and tower.tower_data.line != "wall" \
		and tower.tower_data.get_id() != "sprout"

func _skip(tower, combo: StringName) -> bool:
	return not is_court(tower) or combo in SKIP_COMBOS

# --- The multiplier at `dealt` ---------------------------------------------------------------------------------------

func hit_multiplier(tower, enemy, is_area: bool, combo: StringName) -> float:
	if not live() or _skip(tower, combo) or enemy == null or not is_instance_valid(enemy):
		return 1.0
	var m := 1.0
	var tier: int = tower.tower_data.tier
	if _on.has(FINISHING_BLOW) and tower.rank >= FINISHING_MIN_RANK and enemy.health < enemy.max_health * FINISHING_SHARE:
		m *= _note(FINISHING_BLOW, 1.0 + FINISHING_BONUS)
	if _on.has(BEARING_DOWN) and not is_area and tower.attack_data.attack_kind != TowerData.AttackKind.BEAM:
		var streak := _bearing_streak(tower, enemy)
		var add := minf(BEARING_PER * streak, BEARING_PER_RANK * tower.rank)
		if add > 0.0:
			m *= _note(BEARING_DOWN, 1.0 + add)
	if _on.has(OPEN_ROAD) and not enemy.is_flying() and _straight_cells(enemy) >= OPEN_ROAD_CELLS:
		m *= _note(OPEN_ROAD, 1.0 + OPEN_ROAD_BONUS)
	if _on.has(CLEAN_STRIKE) and _clean(tower, enemy):
		m *= _note(CLEAN_STRIKE, 1.0 + (CLEAN_FINAL_BONUS if tier >= 3 else CLEAN_BONUS))
	if _on.has(NOWHERE_TO_RUN) and tier >= 2:
		var seconds := _nowhere_seconds(tower, enemy)
		var add := minf(NOWHERE_PER_SECOND * seconds, NOWHERE_MAX)
		if add > 0.0:
			m *= _note(NOWHERE_TO_RUN, 1.0 + add)
	if _on.has(STANDING_TALL) and tier >= 3:
		var court := standing_count(tower)
		if court > 0:
			m *= _note(STANDING_TALL, 1.0 + STANDING_PER * court)
	if _on.has(TROPHIES):
		var trophy := trophy_bonus(tower)
		if trophy > 0.0:
			m *= _note(TROPHIES, 1.0 + trophy)
	_remember(tower, enemy, is_area, m)
	return m

# The same bonuses as hit_multiplier with no side effects (evo_shared_spec.md 4): no credit or cap notes, no _remember (no
# Measured Blow, Tallest spend or Run Through after), Bearing Down and Nowhere to Run only read. class_kit.calling_hit
# scales a Calling row's hit by it (its standing bonuses; R1: the hit never counts for these cards' own records).
func preview_multiplier(tower, enemy, is_area: bool) -> float:
	if not live() or _skip(tower, &"") or enemy == null or not is_instance_valid(enemy):
		return 1.0
	var m := 1.0
	var tier: int = tower.tower_data.tier
	if _on.has(FINISHING_BLOW) and tower.rank >= FINISHING_MIN_RANK and enemy.health < enemy.max_health * FINISHING_SHARE:
		m *= 1.0 + FINISHING_BONUS
	if _on.has(BEARING_DOWN) and not is_area and tower.attack_data.attack_kind != TowerData.AttackKind.BEAM:
		m *= 1.0 + minf(BEARING_PER * _bearing_peek(tower, enemy), BEARING_PER_RANK * tower.rank)
	if _on.has(OPEN_ROAD) and not enemy.is_flying() and _straight_cells(enemy) >= OPEN_ROAD_CELLS:
		m *= 1.0 + OPEN_ROAD_BONUS
	if _on.has(CLEAN_STRIKE) and _clean(tower, enemy):
		m *= 1.0 + (CLEAN_FINAL_BONUS if tier >= 3 else CLEAN_BONUS)
	if _on.has(NOWHERE_TO_RUN) and tier >= 2:
		m *= 1.0 + minf(NOWHERE_PER_SECOND * _nowhere_peek(tower, enemy), NOWHERE_MAX)
	if _on.has(STANDING_TALL) and tier >= 3:
		m *= 1.0 + STANDING_PER * standing_count(tower)
	if _on.has(TROPHIES):
		m *= 1.0 + trophy_bonus(tower)
	return m

func _bearing_peek(tower, enemy) -> int:
	var row: Array = _bearing.get(tower.get_instance_id(), [0, -1, 0])
	return int(row[2]) if int(row[0]) == enemy.get_instance_id() else 0

func _nowhere_peek(tower, enemy) -> float:
	var key := "%s:%d" % [cell_key(tower.cell), enemy.get_instance_id()]
	if not _nowhere.has(key):
		return 0.0
	var row: Array = _nowhere[key]
	var now: float = dreams._game_clock
	var gap := maxf(NOWHERE_GAP, 1.5 / maxf(tower.get_attacks_per_second(), 0.1))
	return 0.0 if now - float(row[1]) > gap else now - float(row[0])

func _note(rule: StringName, multiplier: float) -> float:
	DamageLog.note_card_bonus(String(rule), multiplier)
	return multiplier

# Bearing Down: attacks in a row on `enemy` (counted per attack: a beam's ticks or a double peck count once).
func _bearing_streak(tower, enemy) -> int:
	var id: int = tower.get_instance_id()
	var row: Array = _bearing.get(id, [0, -1, 0])
	var target: int = enemy.get_instance_id()
	if int(row[0]) != target:
		row = [target, tower._attack_count, 0]
	elif int(row[1]) != tower._attack_count:
		row = [target, tower._attack_count, int(row[2]) + 1]
	_bearing[id] = row
	if _bearing.size() > 512:
		_bearing.clear()
	return int(row[2])

# Nowhere to Run: seconds since this Warden's first hit on `enemy` without a gap (a gap = it left the range).
func _nowhere_seconds(tower, enemy) -> float:
	var now: float = dreams._game_clock
	var key := "%s:%d" % [cell_key(tower.cell), enemy.get_instance_id()]
	var row: Array = _nowhere.get(key, [now, now])
	var gap := maxf(NOWHERE_GAP, 1.5 / maxf(tower.get_attacks_per_second(), 0.1))
	if now - float(row[1]) > gap:
		row = [now, now]
	row[1] = now
	_nowhere[key] = row
	if _nowhere.size() > 4096:
		_prune(_nowhere)
	return now - float(row[0])

func _prune(map: Dictionary) -> void:
	for key in map.keys():
		var id := String(key).get_slice(":", 1).to_int()
		if not is_instance_id_valid(id):
			map.erase(key)

# Clean Strike: no status on `enemy` was put on by another family's Warden (walls and Sprouts never count).
func _clean(tower, enemy) -> bool:
	for id in enemy.statuses.active_ids():
		var who = enemy.statuses.source(id)
		if is_court(who) and who.tower_data.line != tower.tower_data.line:
			return false
	return true

# Standing Tall: attacking base or branch Wardens touching `tower` (not Sprouts or walls), up to STANDING_MAX_COUNT.
func standing_count(tower) -> int:
	if _standing_board != int(dreams.board_version):
		_standing_board = int(dreams.board_version)
		_standing.clear()
	var id: int = tower.get_instance_id()
	if not _standing.has(id):
		var count := 0
		for other in dreams._touching(tower):
			if is_court(other) and other.tower_data.tier >= 1 and other.tower_data.tier <= 2:
				count += 1
		_standing[id] = mini(count, STANDING_MAX_COUNT)
	return int(_standing[id])

# Open Road: the length in whole path cells of the straight `enemy` is walking (0: a bend, a flyer, off the route).
func _straight_cells(enemy) -> int:
	var batch = dreams.batch
	if _straight_serial != int(batch.route_serial):
		_straight_serial = int(batch.route_serial)
		_build_straights(batch._route_points)
	return int(_straights.get(enemy.get_target_cell(), 0))

func _build_straights(path: PackedVector2Array) -> void:
	_straights.clear()
	var i := 1
	while i < path.size():
		var step: Vector2 = path[i] - path[i - 1]
		var start := i - 1
		while i < path.size() and (path[i] - path[i - 1]).is_equal_approx(step):
			i += 1
		var cells := floori(path[start].distance_to(path[i - 1]))  # Route points are half a cell apart
		for k in range(start, i):
			_straights[path[k]] = maxi(int(_straights.get(path[k], 0)), cells)

# --- After the hit: Measured Blow, the Tallest Tree, Run Through -----------------------------------------------------
# Tower Code's hook (DreamState.hit_card_multiplier) only multiplies, so what these three add comes right after the hit:
# hit_multiplier remembers the hit (_ctx), and the hit's own DamageLog event (DreamState._on_damage_dealt, emitted inside
# take_damage) calls on_damage_event with what it really dealt. Their damage is its own hit, damage only (DAMAGE_ONLY_TAGS:
# no statuses, no per-hit cards), credited to the Warden that made it.
func _remember(tower, enemy, is_area: bool, multiplier: float) -> void:
	_ctx = [tower, enemy, is_area, multiplier]

func on_damage_event(event) -> void:
	if _ctx.is_empty() or event.source != _ctx[0] or event.enemy != _ctx[1] or event.tag in DAMAGE_ONLY_TAGS or event.tag in CLASS_KIT.CLASS_TAGS:
		return
	var tower = _ctx[0]
	var enemy = _ctx[1]
	var is_area: bool = _ctx[2]
	var before: float = event.amount / maxf(float(_ctx[3]), 0.001)  # The hit before these cards (for Run Through)
	_ctx = []  # Once: the extra damage below reports again
	if not is_instance_valid(tower) or not live():
		return
	var actual: float = event.amount
	if _on.has(TALLEST_TREE) and actual > 0.0 and not is_tallest(tower):
		var tree = tallest()
		if tree != null:
			var bare: float = tree.get_bare_damage() if tree.has_method("get_bare_damage") else tree.get_damage()
			tallest_store = minf(tallest_store + actual * TALLEST_SHARE, TALLEST_STORE_CAP * bare)
	if is_instance_valid(enemy) and not enemy.is_cleansed and enemy.health > 0:
		var extra := _measured_extra(tower, enemy)
		if extra > 0.0:
			enemy.take_damage(extra, tower.tower_data.line, false, false, tower, MEASURED_TAG)
			_credit(MEASURED_BLOW, extra, enemy)
	if is_instance_valid(enemy) and not enemy.is_cleansed and enemy.health > 0:
		var spend := _tallest_spend(tower, enemy)
		if spend > 0.0:
			enemy.take_damage(spend, tower.tower_data.line, false, false, tower, TALLEST_TAG)
			_credit(TALLEST_TREE, spend, enemy)
	if _on.has(RUN_THROUGH) and not is_area and tower.tower_data.tier >= 3 and is_instance_valid(enemy) and not enemy.is_flying() \
			and before > 0.0:
		_run_through(tower, enemy, before)

# Measured Blow: the first direct hit of this Warden (by cell) on `enemy`, from rank III, 1% of max health per rank; at most
# MEASURED_CAP of its max health from the card in all; never bosses or echoes.
func _measured_extra(tower, enemy) -> float:
	if not _on.has(MEASURED_BLOW) or tower.rank < MEASURED_MIN_RANK or enemy.enemy_data.is_boss or enemy.get("is_echo"):
		return 0.0
	var key := "%s:%d" % [cell_key(tower.cell), enemy.get_instance_id()]
	if _measured.has(key):
		return 0.0
	_measured[key] = true
	if _measured.size() > 4096:
		_prune(_measured)
	var given: float = float(enemy.get_meta(&"hc_measured", 0.0))
	var add := minf(enemy.max_health * MEASURED_PER_RANK * tower.rank, enemy.max_health * MEASURED_CAP - given)
	if add <= 0.0:
		return 0.0
	enemy.set_meta(&"hc_measured", given + add)
	return add

# The Tallest Tree's spend on this attack: once per attack, at most TALLEST_SPEND x its own hit, never past a dispel.
func _tallest_spend(tower, enemy) -> float:
	if not _on.has(TALLEST_TREE) or not is_tallest(tower) or tower._attack_count == _tallest_attack or tallest_store <= 0.0:
		return 0.0
	var hit: float = tower.get_bare_damage() if tower.has_method("get_bare_damage") else tower.get_damage()
	var spend := minf(minf(tallest_store, TALLEST_SPEND * hit), float(enemy.health))
	if spend <= 0.0:
		return 0.0
	_tallest_attack = tower._attack_count  # An area tree spends on one nightmare
	tallest_store -= spend
	return spend

func _credit(rule: StringName, amount: float, enemy) -> void:
	dreams._credit(String(rule), "damage", amount)
	dreams.note_card(rule, enemy.global_position)

# Run Through: the next nightmares behind the target on the path (further from the Heartwood, within
# RUN_THROUGH_CELLS of path), nearest first, each take RUN_THROUGH_SHARE of the hit: damage only, no statuses, no cards.
func _run_through(tower, enemy, dealt: float) -> void:
	var cell_px: float = Tower.MAP_GRID.cell_size.x
	var from: float = enemy.get_remaining_distance()
	var behind: Array = []
	for other in dreams.spawner.get_enemies():
		if other == enemy or not is_instance_valid(other) or other.is_cleansed or other.is_flying():
			continue
		var gap: float = other.get_remaining_distance() - from
		if gap > 0.0 and gap <= RUN_THROUGH_CELLS * cell_px:
			behind.append([gap, other])
	behind.sort_custom(func(a, b) -> bool: return float(a[0]) < float(b[0]))
	for row in behind.slice(0, RUN_THROUGH_COUNT):
		var other = row[1]
		other.take_damage(dealt * RUN_THROUGH_SHARE, tower.tower_data.line, false, false, tower, CARRIED_TAG)
		_credit(RUN_THROUGH, dealt * RUN_THROUGH_SHARE, other)

# --- Trophies (Proven folded in) ----------------------------------------------------------------------------------------

func trophy_bonus(tower) -> float:
	var row: Dictionary = trophies.get(cell_key(tower.cell), {})
	return minf(TROPHY_STEP * int(row.get("steps", 0)), TROPHY_MAX)

# A direct hit from `tower` took a nightmare's health to 0 (DreamState._on_damage_dealt).
func trophy_dispel(tower, enemy) -> void:
	if not live() or not _on.has(TROPHIES) or not is_court(tower):
		return
	var key := cell_key(tower.cell)
	var drift: int = dreams.drift_director.drifts_started if dreams.drift_director != null else 0
	var row: Dictionary = trophies.get(key, {"drift": drift, "kills": 0, "steps": 0, "paid": -1})
	if int(row.get("drift", -1)) != drift:
		row["drift"] = drift
		row["kills"] = 0
	var big: bool = enemy.elite or enemy.enemy_data.is_boss
	row["kills"] = int(row["kills"]) + (TROPHY_BIG if big else 1)
	if int(row["kills"]) >= TROPHY_KILLS and int(row.get("paid", -1)) != drift and TROPHY_STEP * int(row["steps"]) < TROPHY_MAX - 0.0001:
		row["steps"] = int(row["steps"]) + 1
		row["paid"] = drift  # Once a drift
		dreams.note_card(TROPHIES, tower.global_position, 1, tower)
	trophies[key] = row

# --- The Tallest Tree's choice ------------------------------------------------------------------------------------------

func tallest():
	if tallest_cell == Vector2.INF or dreams == null:
		return null
	for tower in dreams._towers():
		if tower.cell == tallest_cell:
			return tower
	return null

func is_tallest(tower) -> bool:
	return tallest_cell != Vector2.INF and tower.cell == tallest_cell

# Can `tower` be chosen now? Any attacking Warden; the first choice any time, a move only at a rest (the store empties).
func can_choose(tower) -> bool:
	if not live() or not _on.has(TALLEST_TREE) or not is_court(tower) or is_tallest(tower):
		return false
	return tallest() == null or dreams.drift_director == null or dreams.drift_director.is_resting()

func choose(tower) -> void:
	if not can_choose(tower):
		return
	if tallest() != null:
		tallest_store = 0.0  # A move empties it
	tallest_cell = tower.cell
	dreams.note_card(TALLEST_TREE, tower.global_position, 1, tower)

# Sold: the store is lost; choose again. Hit records kept by cell go too.
func sold(tower) -> void:
	trophies.erase(cell_key(tower.cell))
	if is_tallest(tower):
		tallest_cell = Vector2.INF
		tallest_store = 0.0

# The Walking Wood swapped two Wardens: what is kept by cell goes with its Warden.
func swap_cells(a_cell: Vector2, b_cell: Vector2) -> void:
	var ka := cell_key(a_cell)
	var kb := cell_key(b_cell)
	var at_a = trophies.get(ka)
	var at_b = trophies.get(kb)
	trophies.erase(ka)
	trophies.erase(kb)
	if at_a != null:
		trophies[kb] = at_a
	if at_b != null:
		trophies[ka] = at_b
	if tallest_cell == a_cell:
		tallest_cell = b_cell
	elif tallest_cell == b_cell:
		tallest_cell = a_cell

# The Warden panel's line for `tower` ("" = none).
func panel_line(tower) -> String:
	var parts: Array[String] = []
	if live() and _on.has(TROPHIES):
		var steps: int = int(trophies.get(cell_key(tower.cell), {}).get("steps", 0))
		parts.append("Trophies +%d%%" % roundi(minf(TROPHY_STEP * steps, TROPHY_MAX) * 100.0))
	if live() and _on.has(TALLEST_TREE) and is_tallest(tower):
		parts.append("The Tallest Tree: %d stored" % roundi(tallest_store))
	return " · ".join(parts)
