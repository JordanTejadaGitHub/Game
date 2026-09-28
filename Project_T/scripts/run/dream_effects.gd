extends RefCounted
class_name DreamEffects

# "Dream bonuses on Wardens" (screens_ui.md): for a Warden (planted, or a hypothetical one of some
# kind on some cell), every taken Dream card that touches it: whether it's on, what it gives, why
# not, and its area. DreamState's damage / attack speed / range bonuses are sums of these same rows,
# so what the panel and the build ghost show is what the Warden really does.
#
# How cards report: a rule card (rule_id) is listed in REPORTERS with its reporter method; plain stat
# cards (soothe / attack speed / range / potency bonuses, build costs) report from their own fields.
# A new rule card that changes a Warden's stats adds one reporter here and nothing else.
#
# A row: {card, id, name, active, reason ("" when on), effect (what it gives, "+30% damage"),
#   note (run-wide value, "24 attacking Wardens"), damage, speed, range, cost, rank_share (Court),
#   radius (cells; 0 = none), positional (depends on where it stands), run_wide (depends on the whole
#   board), plain (a stat card, already in DreamState._sum_stat)}.
# damage / speed / range / cost are what the card gives WHEN ON; only active rows count.

const REPORTERS := {
	&"cozy_corners": "_cozy_corners", &"hedge_maze": "_hedge_maze", &"tended_forest": "_tended_forest",
	&"kindred_roots": "_kindred_roots", &"chosen_few": "_chosen_few", &"many_hands": "_many_hands",
	&"few_and_mighty": "_few_and_mighty", &"canopy": "_canopy", &"solitude": "_solitude",
	&"the_long_walk": "_long_walk", &"monoculture": "_monoculture", &"crossroads": "_crossroads",
	&"menagerie": "_menagerie", &"restless_night": "_restless_night", &"last_leaf": "_last_leaf",
	&"wildwood_reclaimed": "_wildwood", &"sprout_chorus": "_sprout_chorus", &"last_light": "_last_light",
	&"rootbound": "_rootbound", &"court_of_the_eldest": "_court", &"old_ones": "_old_ones",
	&"reclaimed_earth": "_reclaimed_earth",
}
const STAT_KEYS := {&"damage": "damage", &"attack_speed": "speed", &"range": "range", &"cost": "cost"}

var ds: DreamState

func _init(dream_state: DreamState) -> void:
	ds = dream_state

# A Warden spot: {data, cell, rank, node (the Tower, or null for a hypothetical one)}.
static func spot_for(tower: Tower) -> Dictionary:
	return {"data": tower.tower_data, "cell": tower.cell, "rank": tower.rank, "node": tower}

static func spot_at(data: TowerData, cell: Vector2, tower: Tower = null) -> Dictionary:
	return spot_for(tower) if tower != null else {"data": data, "cell": cell, "rank": 0, "node": null}

# Every card row for `spot`. `ghost` ({cell, data}) = pretend a Warden of that kind also stands there.
func rows(spot: Dictionary, ghost: Dictionary = {}) -> Array[Dictionary]:
	var others := _others(spot, ghost)
	var out: Array[Dictionary] = []
	for card in ds._taken_cards():
		var row: Dictionary
		if REPORTERS.has(card.rule_id):
			row = call(REPORTERS[card.rule_id], spot, others, card)
		else:
			row = _plain(spot, card)
		if row.is_empty():
			continue
		out.append(_finish(row, card))
	return out

# The sum of `key` ("damage", "speed", "range", …) over active rule rows (plain stat cards excluded:
# DreamState adds those from the card fields).
func rule_total(spot: Dictionary, key: String, ghost: Dictionary = {}) -> float:
	var total := 0.0
	for row in rows(spot, ghost):
		if row.active and not row.plain:
			total += row.get(key, 0.0)
	return total

func _finish(row: Dictionary, card: UpgradeData) -> Dictionary:
	var full := {"card": card, "id": card.id, "name": card.display_name, "active": true, "reason": "",
		"note": "", "damage": 0.0, "speed": 0.0, "range": 0.0, "cost": 0, "rank_share": 0.0, "radius": 0.0,
		"positional": false, "run_wide": false, "plain": false}
	full.merge(row, true)
	full["conditional"] = full.positional or full.run_wide
	if not full.has("effect"):
		full["effect"] = _describe(full)
	return full

# "+30% damage, +0.5 range" from a row's numbers.
static func _describe(row: Dictionary) -> String:
	var parts: Array[String] = []
	if row.damage != 0.0:
		parts.append("%+d%% damage" % roundi(row.damage * 100))
	if row.speed != 0.0:
		parts.append("%+d%% attack speed" % roundi(row.speed * 100))
	if row.range != 0.0:
		parts.append("%+.1f range" % row.range)
	if row.cost != 0:
		parts.append("%+d Dew to plant" % row.cost)
	if row.rank_share != 0.0:
		parts.append("+%.1f ranks from the Eldest" % row.rank_share)
	return ", ".join(parts)


# --- Board helpers (work for hypothetical spots and ghosts) -------------------------------------------

func _others(spot: Dictionary, ghost: Dictionary) -> Array:
	var out := []
	for tower in ds._towers():
		if tower == spot.node or (spot.node == null and tower.cell == spot.cell):
			continue  # The spot itself, or the Warden a hypothetical one would replace
		if not ghost.is_empty() and tower.cell == ghost.cell:
			continue
		out.append(spot_for(tower))
	if not ghost.is_empty() and ghost.cell != spot.cell:
		out.append({"data": ghost.data, "cell": ghost.cell, "rank": 0, "node": null})
	return out

static func _cheb(a: Vector2, b: Vector2) -> float:
	return maxf(absf(a.x - b.x), absf(a.y - b.y))

static func _touching(spot: Dictionary, others: Array) -> Array:
	return others.filter(func(o: Dictionary) -> bool: return _cheb(o.cell, spot.cell) == 1.0)

static func _attackers(spot: Dictionary, others: Array) -> int:
	var count := 1 if spot.data.can_attack else 0
	for o in others:
		if o.data.can_attack:
			count += 1
	return count

static func _cells_word(n: float) -> String:
	return "%d cell%s" % [n, "" if n == 1 else "s"]


# --- Reporters: return {} when the card doesn't concern this Warden -----------------------------------

func _plain(spot: Dictionary, card: UpgradeData) -> Dictionary:
	var n: int = ds.stacks[card.id]
	var row := {"plain": true}
	if ds._applies_to(card, spot.data):
		row.damage = card.soothe_bonus * n
		row.speed = card.attack_speed_bonus * n
		row.range = card.range_bonus * n
	if card.set_cost_warden == spot.data.get_id():
		row.cost = card.set_cost - spot.data.cost  # This card alone (DreamState picks among several)
	elif card.plant_discount > 0.0:
		row.cost = -roundi(spot.data.cost * minf(card.plant_discount * n, 1.0))
	if row.get("damage", 0.0) == 0.0 and row.get("speed", 0.0) == 0.0 and row.get("range", 0.0) == 0.0 \
			and row.get("cost", 0) == 0 and card.potency_bonus == 0.0:
		return {}
	if card.potency_bonus != 0.0 and ds._applies_to(card, spot.data):
		row.effect = "%+d%% Potency" % roundi(card.potency_bonus * n * 100)
	return row

func _cozy_corners(spot: Dictionary, _others: Array, _card: UpgradeData) -> Dictionary:
	var level := ds.rule_level(&"cozy_corners")
	var reach: int = DreamState.COZY_CORNERS_REACH[level]
	var on := ds.is_beside_bend(spot.cell, reach)
	return {"positional": true, "radius": float(reach), "active": on, "damage": DreamState.COZY_CORNERS_BONUS[level],
		"reason": "" if on else "no bend in the path within %s" % _cells_word(reach)}

func _hedge_maze(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	var level := ds.rule_level(&"hedge_maze")
	var walls := 1 if spot.data.line == "wall" else 0
	for o in others:
		if o.data.line == "wall":
			walls += 1
	var bonus := minf(DreamState.HEDGE_BONUS_PER * (walls / DreamState.HEDGE_PER_WALLS[level]), DreamState.HEDGE_BONUS_MAX[level])
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d Thornwalls" % walls,
		"reason": "" if bonus > 0.0 else "needs %d Thornwalls" % DreamState.HEDGE_PER_WALLS[level]}

func _tended_forest(_spot: Dictionary, _others: Array, _card: UpgradeData) -> Dictionary:
	var clears := ds.run_state.tended_cells.size()
	var bonus := minf(DreamState.TENDED_FOREST_PER_CLEAR * clears, DreamState.TENDED_FOREST_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d cleared" % clears,
		"reason": "" if bonus > 0.0 else "no obstacles cleared yet"}

func _kindred_roots(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	var level := ds.rule_level(&"kindred_roots")
	var ranks := 0
	for o in _touching(spot, others):
		ranks += o.rank
	var bonus := minf(DreamState.KINDRED_PER_RANK[level] * ranks, DreamState.KINDRED_MAX[level])
	return {"positional": true, "radius": 1.0, "active": bonus > 0.0, "damage": bonus,
		"reason": "" if bonus > 0.0 else "no ranked Warden touching it"}

func _chosen_few(spot: Dictionary, _others: Array, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	if spot.rank >= 5:
		return {"damage": DreamState.CHOSEN_FEW_BONUS}
	if spot.rank < 3:
		return {"damage": -DreamState.CHOSEN_FEW_PENALTY, "note": "below rank III"}
	return {"active": false, "damage": DreamState.CHOSEN_FEW_BONUS, "reason": "needs rank V"}

func _many_hands(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	var attackers := _attackers(spot, others)
	var bonus := minf(0.01 * (attackers / DreamState.MANY_HANDS_PER), DreamState.MANY_HANDS_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d attacking Wardens" % attackers,
		"reason": "" if bonus > 0.0 else "needs %d attacking Wardens" % DreamState.MANY_HANDS_PER}

func _few_and_mighty(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	var attackers := _attackers(spot, others)
	var bonus := DreamState.FEW_AND_MIGHTY_PER * maxi(DreamState.FEW_AND_MIGHTY_BELOW - attackers, 0)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d attacking Wardens" % attackers,
		"reason": "" if bonus > 0.0 else "%d attacking Wardens (needs fewer than %d)" % [attackers, DreamState.FEW_AND_MIGHTY_BELOW]}

func _canopy(_spot: Dictionary, _others: Array, _card: UpgradeData) -> Dictionary:
	var steps := ds.canopy_steps_reached()
	return {"run_wide": true, "active": steps > 0, "damage": DreamState.CANOPY_BONUS * steps,
		"note": "%d attacking Wardens planted" % ds._attackers_planted,
		"reason": "" if steps > 0 else "plant %d attacking Wardens" % DreamState.CANOPY_STEPS[0]}

func _solitude(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var nearest: Dictionary = {}
	for o in others:
		if o.data.can_attack and _cheb(o.cell, spot.cell) <= DreamState.NEARBY_CELLS \
				and (nearest.is_empty() or _cheb(o.cell, spot.cell) < _cheb(nearest.cell, spot.cell)):
			nearest = o
	var on := nearest.is_empty()
	return {"positional": true, "radius": float(DreamState.NEARBY_CELLS), "active": on,
		"damage": DreamState.SOLITUDE_BONUS, "range": DreamState.SOLITUDE_RANGE,
		"reason": "" if on else "%s is %s away (needs no attacking Warden within %d)" % [nearest.data.display_name,
			_cells_word(_cheb(nearest.cell, spot.cell)), DreamState.NEARBY_CELLS]}

func _long_walk(_spot: Dictionary, _others: Array, _card: UpgradeData) -> Dictionary:
	var bonus := DreamState.LONG_WALK_PER * (ds.path_length / DreamState.LONG_WALK_TILES)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d path tiles" % ds.path_length}

func _monoculture(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var lines := {spot.data.line: true}
	for o in others:
		if o.data.can_attack:
			lines[o.data.line] = true
	var on := lines.size() == 1
	return {"run_wide": true, "active": on, "damage": DreamState.MONOCULTURE_BONUS,
		"reason": "" if on else "%d Warden lines (needs one)" % lines.size()}

func _crossroads(spot: Dictionary, _others: Array, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on := ds.crossroads_at(spot.cell)
	return {"positional": true, "radius": 1.0, "active": on, "damage": DreamState.CROSSROADS_BONUS,
		"reason": "" if on else "needs two path tiles %d+ steps apart beside it" % DreamState.CROSSROADS_STEPS}

func _menagerie(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var kinds := {spot.data.get_id(): true}
	for o in others:
		if o.data.can_attack:
			kinds[o.data.get_id()] = true
	return {"run_wide": true, "damage": minf(DreamState.MENAGERIE_PER * kinds.size(), DreamState.MENAGERIE_MAX),
		"note": "%d kinds" % kinds.size()}

func _restless_night(_spot: Dictionary, _others: Array, _card: UpgradeData) -> Dictionary:
	var bonus := minf(DreamState.RESTLESS_PER * ds._early_calls, DreamState.RESTLESS_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d called early" % ds._early_calls,
		"reason": "" if bonus > 0.0 else "call a drift early this block"}

func _last_leaf(_spot: Dictionary, _others: Array, _card: UpgradeData) -> Dictionary:
	var down := maxi(ds.run_state.max_leaves - ds.run_state.leaves, 0)
	var bonus := minf(DreamState.LAST_LEAF_PER * down, DreamState.LAST_LEAF_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d leaves down" % down,
		"reason": "" if bonus > 0.0 else "no leaves lost"}

func _wildwood(spot: Dictionary, _others: Array, _card: UpgradeData) -> Dictionary:
	var on: bool = ds.run_state.tended_cells.has(spot.cell)
	var bonus := minf(DreamState.WILDWOOD_BASE + DreamState.WILDWOOD_PER_CLEAR * ds.run_state.tended_cells.size(),
		DreamState.WILDWOOD_MAX)
	return {"positional": true, "active": on, "damage": bonus, "reason": "" if on else "not on a cleared cell"}

func _sprout_chorus(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	if spot.data.get_id() != "sprout":
		return {}
	var sprouts := 0
	for o in others:
		if o.data.get_id() == "sprout" and _cheb(o.cell, spot.cell) <= DreamState.NEARBY_CELLS:
			sprouts += 1
	var bonus := minf(DreamState.SPROUT_CHORUS_PER * sprouts, DreamState.SPROUT_CHORUS_MAX)
	return {"positional": true, "radius": float(DreamState.NEARBY_CELLS), "active": sprouts > 0, "speed": bonus,
		"note": "%d Sprouts near" % sprouts,
		"reason": "" if sprouts > 0 else "no other Sprout within %d" % DreamState.NEARBY_CELLS}

func _last_light(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var attackers := _attackers(spot, others)
	var on := attackers <= DreamState.LAST_LIGHT_MAX
	return {"run_wide": true, "active": on, "speed": 1.0, "effect": "attacks twice as fast",
		"reason": "" if on else "%d attacking Wardens (needs %d or fewer)" % [attackers, DreamState.LAST_LIGHT_MAX]}

func _rootbound(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var touching := _touching(spot, others).size()
	var on := touching >= DreamState.ROOTBOUND_TOUCHING
	return {"positional": true, "radius": 1.0, "active": on, "speed": 1.0, "effect": "attacks twice",
		"reason": "" if on else "touches %d Wardens (needs %d)" % [touching, DreamState.ROOTBOUND_TOUCHING]}

func _court(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	if spot.node != null and ds.is_eldest(spot.node):
		return {}
	var eldest := ds.get_eldest()
	var on := eldest != null and _touching(spot, others).any(func(o: Dictionary) -> bool: return o.node == eldest)
	return {"positional": true, "radius": 1.0, "active": on,
		"rank_share": DreamState.COURT_SHARE * eldest.rank if eldest != null else 0.0,
		"reason": "" if on else ("not touching the Eldest" if eldest != null else "no Eldest yet")}

func _old_ones(spot: Dictionary, others: Array, _card: UpgradeData) -> Dictionary:
	if spot.rank <= 0:
		return {}
	var on: bool = spot.rank < DreamState.FREE_RANK_MAX and _touching(spot, others).any(
		func(o: Dictionary) -> bool: return o.rank >= 5)
	return {"positional": true, "radius": 1.0, "active": on, "effect": "counts one rank higher",
		"reason": "" if on else "no rank V Warden touching it"}

func _reclaimed_earth(spot: Dictionary, _others: Array, _card: UpgradeData) -> Dictionary:
	if spot.node != null:
		return {}  # Only planting on a fertile cell
	var on: bool = ds.run_state.fertile_cells.has(spot.cell)
	var cost := ds.get_build_cost(spot.data)
	return {"positional": true, "active": on, "cost": roundi(cost * DreamState.FERTILE_DISCOUNT) - cost,
		"reason": "" if on else "not a fertile cell"}
