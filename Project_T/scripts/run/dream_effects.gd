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
	&"root_network": "_root_network", &"first_light": "_first_light", &"last_stand": "_last_stand",
	&"old_growth": "_old_growth", &"hunters_patience": "_hunters_patience", &"thinning_the_herd": "_thinning_the_herd",
	&"bitter_hedges": "_bitter_hedges",
	&"short_roots": "_short_roots", &"forests_edge": "_forests_edge", &"crowded_path": "_crowded_path",
	&"lone_hunter": "_lone_hunter", &"skyward_gaze": "_skyward_gaze", &"fresh_growth": "_fresh_growth",
	&"underdog": "_underdog", &"shelter_of_stones": "_shelter_of_stones", &"cliffside": "_cliffside",
	&"sudden_bloom": "_sudden_bloom", &"watchful_rest": "_watchful_rest", &"straightaway": "_straightaway",
	&"many_rings": "_many_rings", &"hedgerow": "_hedgerow", &"spinning_corners": "_spinning_corners",
	&"fresh_soil": "_fresh_soil", &"heartwoods_fury": "_heartwoods_fury", &"patchwork": "_patchwork",
	&"mixed_grove": "_mixed_grove", &"quick_step": "_quick_step", &"restless_roots": "_restless_roots", &"far_reach": "_far_reach", &"tended_stumps": "_tended_stumps", &"hollow_ground": "_hollow_ground", &"drumbeat": "_drumbeat",
	&"long_shadows": "_long_shadows", &"scarred_bark": "_scarred_bark", &"desperate_bloom": "_desperate_bloom",
	&"odd_one_out": "_odd_one_out", &"grand_tour": "_grand_tour",
	&"heart_of_the_maze": "_heart_of_the_maze",
	&"rain_on_glass": "_rain_on_glass",
	&"kind_canopy": "_kind_canopy", &"shared_light": "_shared_light", &"bramble_oath": "_bramble_oath",
	&"golden_harvest": "_golden_harvest",
}
const STAT_KEYS := {&"damage": "damage", &"attack_speed": "speed", &"range": "range", &"cost": "cost"}

# The rows that move with the field between board changes (nightmares in range, dispels this drift):
# rows_cached recomputes these on every call.
const LIVE_RULES: Array[StringName] = [&"crowded_path", &"thinning_the_herd", &"quick_step", &"scarred_bark", &"desperate_bloom",
	&"fresh_growth", &"old_growth"]  # Rows that read per-Warden or run state the row cache key doesn't cover

var ds: DreamState
var _board: Board = null
var _board_version := -1
var _row_cache := {}  # Tower instance id -> [key, rows]

func _init(dream_state: DreamState) -> void:
	ds = dream_state

# The other Wardens as a lookup (cells, counts). Built once per DreamState.board_version for real
# Wardens; a ghost or a hypothetical Warden gets its own small board. Ranks and data are read live
# from the nodes (tests and Nurture change ranks without a board change).
class Board:
	var entries: Array = []  # Spot dicts {data, cell, rank, node}
	var by_cell := {}  # Cell -> spot
	var attackers := 0
	var walls := 0
	var lines := {}  # Attacking Wardens' lines
	var kinds := {}  # Attacking Wardens' ids

	func _init(spots: Array) -> void:
		entries = spots
		for o in spots:
			by_cell[o.cell] = o
			var data: TowerData = DreamEffects._data(o)
			if data.can_attack:
				attackers += 1
				lines[data.line] = true
				kinds[data.get_id()] = true
			if data.line == "wall":
				walls += 1

	# Whether `spot` itself is on this board (a real Warden); a hypothetical one isn't.
	func holds(spot: Dictionary) -> bool:
		return spot.node != null and by_cell.has(spot.cell) and by_cell[spot.cell].node == spot.node

	# Other Wardens within `reach` cells (Chebyshev), never the spot's own cell.
	func near(spot: Dictionary, reach: int) -> Array:
		var out := []
		for dx in range(-reach, reach + 1):
			for dy in range(-reach, reach + 1):
				if dx != 0 or dy != 0:
					var o = by_cell.get(spot.cell + Vector2(dx, dy))
					if o != null:
						out.append(o)
		return out

	func touching(spot: Dictionary) -> Array:
		return near(spot, 1)

	# Attacking Wardens counting the spot itself.
	func attackers_with(spot: Dictionary) -> int:
		return attackers + (1 if spot.data.can_attack and not holds(spot) else 0)

	func walls_with(spot: Dictionary) -> int:
		return walls + (1 if spot.data.line == "wall" and not holds(spot) else 0)

static func _data(o: Dictionary) -> TowerData:
	return o.node.tower_data if o.node != null and is_instance_valid(o.node) else o.data

static func _rank(o: Dictionary) -> int:
	return o.node.rank if o.node != null and is_instance_valid(o.node) else o.rank

func _shared_board() -> Board:
	if _board == null or _board_version != ds.board_version:
		var spots := []
		for tower in ds._towers():
			spots.append(spot_for(tower))
		_board = Board.new(spots)
		_board_version = ds.board_version
	return _board

func _board_for(spot: Dictionary, ghost: Dictionary) -> Board:
	if ghost.is_empty() and (spot.node != null or not _shared_board().by_cell.has(spot.cell)):
		return _shared_board()
	return Board.new(_others(spot, ghost))  # A hypothetical spot replaces what stands on its cell

# A Warden spot: {data, cell, rank, node (the Tower, or null for a hypothetical one)}.
static func spot_for(tower: Tower) -> Dictionary:
	return {"data": tower.tower_data, "cell": tower.cell, "rank": tower.rank, "node": tower}

static func spot_at(data: TowerData, cell: Vector2, tower: Tower = null) -> Dictionary:
	return spot_for(tower) if tower != null else {"data": data, "cell": cell, "rank": 0, "node": null}

# Every card row for `spot`. `ghost` ({cell, data}) = pretend a Warden of that kind also stands there.
func rows(spot: Dictionary, ghost: Dictionary = {}) -> Array[Dictionary]:
	var board := _board_for(spot, ghost)
	var out: Array[Dictionary] = []
	for card in ds._taken_cards():
		var row := _row(spot, board, card)
		if not row.is_empty():
			out.append(row)
		for rule in card.extra_rules:  # A merged card also reports the rule it absorbed (pool trim)
			if REPORTERS.has(rule):
				var extra: Dictionary = call(REPORTERS[rule], spot, board, card)
				if not extra.is_empty():
					out.append(_finish(extra, card))
	return out

func _row(spot: Dictionary, board: Board, card: UpgradeData) -> Dictionary:
	var row: Dictionary
	if REPORTERS.has(card.rule_id):
		row = call(REPORTERS[card.rule_id], spot, board, card)
	else:
		row = _plain(spot, card)
	return {} if row.is_empty() else _finish(row, card)

# A Warden's rank changed (Nurture): only its own rows and the touching Wardens' rows read it
# (Kindred Roots, Court of the Eldest, Old Ones), so only those are refreshed, never the whole
# board (a group Nurture of 200 Sprouts would otherwise rebuild every Warden's rows in one frame).
var _near_rank := {}  # Tower instance id -> times a touching Warden's rank changed

func rank_changed(tower: Tower) -> void:
	var spot := spot_for(tower)
	for o in [spot] + _shared_board().touching(spot):
		if o.node == null or not is_instance_valid(o.node):
			continue
		var id: int = o.node.get_instance_id()
		_near_rank[id] = _near_rank.get(id, 0) + 1
		_soon(o.node)

# Rank-only rebuilds are spread out (a dense group Nurture marks every Warden): at most
# RANK_REBUILDS_PER_FRAME per frame; the rest keep their previous rows and look again within
# RANK_REBUILD_SPREAD s (only rank-reading rows lag; rank damage and speed are never cached).
const RANK_REBUILDS_PER_FRAME := 8
const RANK_REBUILD_SPREAD := 0.25
var _rebuild_frame := -1
var _rebuilds := 0

func _soon(tower: Node) -> void:
	if "_dream_cache_left" in tower:
		tower._dream_cache_left = minf(tower._dream_cache_left, randf_range(0.0, RANK_REBUILD_SPREAD))

# rows() for a planted Warden, cached until the board or the cards change (DreamState.board_version,
# the taken cards, its rank and form); the LIVE_RULES rows are recomputed on every call. For the
# per-frame stat reads (Tower) and the badge poll.
func rows_cached(tower: Tower, allow_stale: bool = true) -> Array[Dictionary]:
	var spot := spot_for(tower)
	var base := hash([ds.board_version, ds.stacks, tower.tower_data, tower.cell])
	var key := hash([base, tower.rank, _near_rank.get(tower.get_instance_id(), 0)])
	var id := tower.get_instance_id()
	var cached: Array = _row_cache.get(id, [])
	var out: Array[Dictionary] = []
	if cached.is_empty() or cached[0] != key:
		var frame := Engine.get_process_frames()
		if frame != _rebuild_frame:
			_rebuild_frame = frame
			_rebuilds = 0
		if allow_stale and cached.size() > 2 and cached[2] == base and _rebuilds >= RANK_REBUILDS_PER_FRAME:
			_soon(tower)  # Only a rank changed: the previous rows for now, rebuilt within a moment
			return _with_live(spot, cached[1])
		_rebuilds += 1
		out = rows(spot)
		if _row_cache.size() > 1024:
			_row_cache.clear()  # Forget sold Wardens now and then
		_row_cache[id] = [key, out, base]
		return out.duplicate()
	return _with_live(spot, cached[1])

func _with_live(spot: Dictionary, rows_in: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var board: Board = null
	for row in rows_in:
		if LIVE_RULES.has(row.card.rule_id):
			if board == null:
				board = _shared_board()
			var fresh := _row(spot, board, row.card)
			if not fresh.is_empty():
				out.append(fresh)
		else:
			out.append(row)
	return out

# rule_total over the cached rows (Tower's hot path).
func rule_total_cached(tower: Tower, key: String, allow_stale: bool = true) -> float:
	var total := 0.0
	for row in rows_cached(tower, allow_stale):
		if row.active and not row.plain:
			total += row.get(key, 0.0)
	return total

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
	var power := ds.resonance(card)  # Tag resonance scales the numbers, never the rule
	if power != 1.0:
		for key in ["damage", "speed", "range"]:
			full[key] = full[key] * power
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

func _cozy_corners(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var level := ds.rule_level(&"cozy_corners")
	var reach: int = DreamState.COZY_CORNERS_REACH[level]
	var on := ds.is_beside_bend(spot.cell, reach)
	return {"positional": true, "radius": float(reach), "active": on, "damage": DreamState.COZY_CORNERS_BONUS[level],
		"reason": "" if on else ("no bend in the path in the 8 cells around it" if reach == 1 else "no bend in the path within %d cells, diagonals included" % reach)}

func _hedge_maze(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	var level := ds.rule_level(&"hedge_maze")
	var walls := board.walls_with(spot)
	var bonus := minf(DreamState.HEDGE_BONUS_PER * (walls / DreamState.HEDGE_PER_WALLS[level]), DreamState.HEDGE_BONUS_MAX[level])
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d Thornwalls" % walls,
		"reason": "" if bonus > 0.0 else "needs %d Thornwalls" % DreamState.HEDGE_PER_WALLS[level]}

func _tended_forest(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var clears := ds.run_state.tended_cells.size()
	var bonus := minf(DreamState.TENDED_FOREST_PER_CLEAR * clears, DreamState.TENDED_FOREST_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d cleared" % clears,
		"reason": "" if bonus > 0.0 else "no obstacles cleared yet"}

func _kindred_roots(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	var level := ds.rule_level(&"kindred_roots")
	var ranks := 0
	for o in board.touching(spot):
		ranks += DreamEffects._rank(o)
	var bonus := minf(DreamState.KINDRED_PER_RANK[level] * ranks, DreamState.KINDRED_MAX[level])
	return {"positional": true, "radius": 1.0, "active": bonus > 0.0, "damage": bonus,
		"reason": "" if bonus > 0.0 else "no ranked Warden touching it"}

func _chosen_few(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	if spot.rank >= 5:
		return {"damage": DreamState.CHOSEN_FEW_BONUS}
	if spot.rank < 3:
		return {"damage": -DreamState.CHOSEN_FEW_PENALTY, "note": "below rank III"}
	return {"active": false, "damage": DreamState.CHOSEN_FEW_BONUS, "reason": "needs rank V"}

func _many_hands(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	var attackers := board.attackers_with(spot)
	var bonus := minf(0.01 * (attackers / DreamState.MANY_HANDS_PER), DreamState.MANY_HANDS_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d attacking Wardens" % attackers,
		"reason": "" if bonus > 0.0 else "needs %d attacking Wardens" % DreamState.MANY_HANDS_PER}

func _few_and_mighty(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	var attackers := board.attackers_with(spot)
	var bonus := DreamState.FEW_AND_MIGHTY_PER * maxi(DreamState.FEW_AND_MIGHTY_BELOW - attackers, 0)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d attacking Wardens" % attackers,
		"reason": "" if bonus > 0.0 else "%d attacking Wardens (needs fewer than %d)" % [attackers, DreamState.FEW_AND_MIGHTY_BELOW]}

func _canopy(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var steps := ds.canopy_steps_reached()
	return {"run_wide": true, "active": steps > 0, "damage": DreamState.CANOPY_BONUS * steps,
		"note": "%d attacking Wardens planted" % ds._attackers_planted,
		"reason": "" if steps > 0 else "plant %d attacking Wardens" % DreamState.CANOPY_STEPS[0]}

func _solitude(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var nearest: Dictionary = {}
	for o in board.near(spot, DreamState.NEARBY_CELLS):
		if DreamEffects._data(o).can_attack and (nearest.is_empty() or _cheb(o.cell, spot.cell) < _cheb(nearest.cell, spot.cell)):
			nearest = o
	var on := nearest.is_empty()
	return {"positional": true, "radius": float(DreamState.NEARBY_CELLS), "active": on,
		"damage": DreamState.SOLITUDE_BONUS, "range": DreamState.SOLITUDE_RANGE,
		"reason": "" if on else "%s is %s away (needs no attacking Warden within %d)" % [DreamEffects._data(nearest).display_name,
			_cells_word(_cheb(nearest.cell, spot.cell)), DreamState.NEARBY_CELLS]}

func _long_walk(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var bonus := DreamState.LONG_WALK_PER * (ds.path_length / DreamState.LONG_WALK_TILES)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d path tiles" % ds.path_length}

func _monoculture(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var lines := board.lines.duplicate()
	lines[spot.data.line] = true
	var on := lines.size() == 1
	return {"run_wide": true, "active": on, "damage": DreamState.MONOCULTURE_BONUS,
		"note": count_text(lines.size(), "Warden line"),
		"reason": "" if on else "%d Warden lines (needs one)" % lines.size()}

func _crossroads(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on := ds.crossroads_at(spot.cell)
	return {"positional": true, "radius": 1.0, "active": on, "damage": DreamState.CROSSROADS_BONUS,
		"reason": "" if on else "needs two path tiles %d+ steps apart beside it" % DreamState.CROSSROADS_STEPS}

func _menagerie(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var kinds := board.kinds.duplicate()
	kinds[spot.data.get_id()] = true
	return {"run_wide": true, "damage": minf(DreamState.MENAGERIE_PER * kinds.size(), DreamState.MENAGERIE_MAX),
		"note": count_text(kinds.size(), "kind") + " of Warden"}

func _restless_night(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var bonus := minf(DreamState.RESTLESS_PER * ds._early_calls, DreamState.RESTLESS_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d called early" % ds._early_calls,
		"reason": "" if bonus > 0.0 else "call a drift early this block"}

func _last_leaf(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var down := maxi(ds.run_state.max_leaves - ds.run_state.leaves, 0)
	var bonus := minf(DreamState.LAST_LEAF_PER * down, DreamState.LAST_LEAF_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d leaves down" % down,
		"reason": "" if bonus > 0.0 else "no leaves lost"}

func _wildwood(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var on: bool = ds.run_state.tended_cells.has(spot.cell)
	var bonus := minf(DreamState.WILDWOOD_BASE + DreamState.WILDWOOD_PER_CLEAR * ds.run_state.tended_cells.size(),
		DreamState.WILDWOOD_MAX)
	return {"positional": true, "active": on, "damage": bonus, "reason": "" if on else "not on a cleared cell"}

func _sprout_chorus(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if spot.data.get_id() != "sprout":
		return {}
	var sprouts := 0
	for o in board.near(spot, DreamState.NEARBY_CELLS):
		if DreamEffects._data(o).get_id() == "sprout":
			sprouts += 1
	var bonus := minf(DreamState.SPROUT_CHORUS_PER * sprouts, DreamState.SPROUT_CHORUS_MAX)
	return {"positional": true, "radius": float(DreamState.NEARBY_CELLS), "active": sprouts > 0, "speed": bonus,
		"note": "%d Sprouts near" % sprouts,
		"reason": "" if sprouts > 0 else "no other Sprout within %d" % DreamState.NEARBY_CELLS}

func _last_light(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var attackers := board.attackers_with(spot)
	var on := attackers <= DreamState.LAST_LIGHT_MAX
	return {"run_wide": true, "active": on, "speed": 1.0, "effect": "attacks twice as fast",
		"note": count_text(attackers, "attacking Warden"),
		"reason": "" if on else "%d attacking Wardens (needs %d or fewer)" % [attackers, DreamState.LAST_LIGHT_MAX]}

func _rootbound(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var touching := board.touching(spot).size()
	var on := touching >= DreamState.ROOTBOUND_TOUCHING
	return {"positional": true, "radius": 1.0, "active": on, "speed": 1.0, "effect": "attacks twice",
		"reason": "" if on else "touches %d Wardens (needs %d)" % [touching, DreamState.ROOTBOUND_TOUCHING]}

func _court(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if spot.node != null and ds.is_eldest(spot.node):
		return {}
	var eldest := ds.get_eldest()
	var on := eldest != null and board.touching(spot).any(func(o: Dictionary) -> bool: return o.node == eldest)
	return {"positional": true, "radius": 1.0, "active": on,
		"rank_share": DreamState.COURT_SHARE * eldest.rank if eldest != null else 0.0,
		"reason": "" if on else ("not touching the Eldest" if eldest != null else "no Eldest yet")}

func _old_ones(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if spot.rank <= 0:
		return {}
	var on: bool = spot.rank < DreamState.FREE_RANK_MAX and board.touching(spot).any(
		func(o: Dictionary) -> bool: return DreamEffects._rank(o) >= 5)
	return {"positional": true, "radius": 1.0, "active": on, "effect": "counts one rank higher",
		"reason": "" if on else "no rank V Warden touching it"}

func _reclaimed_earth(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if spot.node != null:
		return {}  # Only planting on a fertile cell
	var on: bool = ds.run_state.fertile_cells.has(spot.cell)
	var cost := ds.get_build_cost(spot.data)
	return {"positional": true, "active": on, "cost": roundi(cost * DreamState.FERTILE_DISCOUNT) - cost,
		"reason": "" if on else "not a fertile cell"}

# Generic Rares (dream_design.md "Generic Rares")
func _root_network(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if spot.data.get_id() != "sprout":
		return {}
	var level := ds.rule_level(&"root_network")
	# Flood fill from the spot through the board's Sprouts: sides only (II: diagonals too)
	var is_sprout := func(cell: Vector2) -> bool:
		var o = board.by_cell.get(cell)
		return o != null and cell != spot.cell and DreamEffects._data(o).get_id() == "sprout"
	var steps: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	if level > 0:
		steps.append_array([Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)])
	var network := {spot.cell: true}
	var frontier: Array[Vector2] = [spot.cell]
	while not frontier.is_empty():
		var cell: Vector2 = frontier.pop_back()
		for step in steps:
			var next: Vector2 = cell + step
			if not network.has(next) and is_sprout.call(next):
				network[next] = true
				frontier.append(next)
	var size := network.size()
	var on := size >= 2
	return {"positional": true, "radius": 1.0, "active": on,
		"damage": minf(DreamState.ROOT_NETWORK_PER[level] * size, DreamState.ROOT_NETWORK_MAX[level]),
		"note": "network of %d" % size,
		"reason": "" if on else ("no Sprout beside it" if level == 0 else "no Sprout around it")}

func _first_light(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	return {"effect": "first hit on each nightmare ×3"}

func _last_stand(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	return {"effect": "+%d%% damage to nightmares within %d cells of the Heartwood" % [
		roundi(DreamState.LAST_STAND_BONUS * 100), DreamState.LAST_STAND_CELLS]}

func _old_growth(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var stood := DreamState.drifts_stood(spot.node)
	var bonus := ds.get_old_growth_bonus(spot.node)
	var next: Array = []
	for step in DreamState.OLD_GROWTH_STEPS:
		if stood < step[0]:
			next = step
	return {"active": bonus > 0.0, "damage": bonus if bonus > 0.0 else DreamState.OLD_GROWTH_STEPS[-1][1],
		"note": "stood %d drifts" % stood + ("" if next.is_empty() else " (%d for +%d%%)" % [next[0], roundi(next[1] * 100)]),
		"reason": "" if bonus > 0.0 else "has stood %d of %d drifts" % [stood, DreamState.OLD_GROWTH_STEPS[-1][0]]}

func _hunters_patience(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	return {"effect": "+%d%% damage to Deeply Blighted nightmares, +%d%% to bosses" % [
		roundi(DreamState.HUNTERS_PATIENCE_ELITE * 100), roundi(DreamState.HUNTERS_PATIENCE_BOSS * 100)]}

func _thinning_the_herd(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var bonus := ds.get_herd_bonus(spot.node)
	return {"active": bonus > 0.0, "damage": bonus, "note": "+%d%% this drift" % roundi(bonus * 100),
		"reason": "" if bonus > 0.0 else "no nightmare dispelled in its range this drift"}

func _bitter_hedges(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	return {"effect": "nightmares passing Thornwalls take +%d%% per wall for %d s (up to +%d%%)" % [
		roundi(DreamState.BITTER_PER * 100), DreamState.BITTER_TIME, roundi(DreamState.BITTER_MAX * 100)]}

# Generic Commons / Uncommons and the second batch (dream_design.md 142–168)
func _short_roots(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on: bool = spot.data.attack_range <= DreamState.SHORT_ROOTS_RANGE
	return {"active": on, "damage": DreamState.SHORT_ROOTS_BONUS,
		"reason": "" if on else "range %.1f (needs 2 or less)" % spot.data.attack_range}

func _forests_edge(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var start: Vector2 = ds.map_generator.startPath
	var on := _cheb(spot.cell, start) <= DreamState.FORESTS_EDGE_CELLS
	return {"positional": true, "active": on, "damage": DreamState.FORESTS_EDGE_BONUS,
		"reason": "" if on else "more than %d cells from the start" % DreamState.FORESTS_EDGE_CELLS}

func _crowded_path(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var level := ds.rule_level(&"crowded_path")
	var count: int = ds.count_in_range(spot.node) if spot.node != null else 0
	var bonus := minf(DreamState.CROWDED_PER[level] * count, DreamState.CROWDED_MAX[level])
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d nightmares in range" % count,
		"reason": "" if bonus > 0.0 else "no nightmare in range"}

func _lone_hunter(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	return {"effect": "+%d%% damage to a nightmare with no other within 2 cells" % roundi(
		DreamState.LONE_HUNTER_BONUS[ds.rule_level(&"lone_hunter")] * 100)}

func _skyward_gaze(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	return {"effect": "+%d%% damage and +%d range against flying nightmares" % [
		roundi(DreamState.SKYWARD_BONUS * 100), roundi(DreamState.SKYWARD_RANGE)]}

func _fresh_growth(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var on: bool = ds.is_fresh(spot.node) if spot.node != null else not ds.drift_director.resting
	return {"active": on, "damage": DreamState.FRESH_GROWTH_BONUS[ds.rule_level(&"fresh_growth")],
		"reason": "" if on else "not planted or grown during this drift"}

func _underdog(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on := ds.is_underdog(spot.node)
	var level := ds.rule_level(&"underdog")
	return {"run_wide": true, "active": on, "damage": DreamState.UNDERDOG[level][1],
		"reason": "" if on else "not one of the %d that soothed least last block" % DreamState.UNDERDOG[level][0]}

func _shelter_of_stones(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var on := ds.touches_obstacle(spot.cell)
	return {"positional": true, "radius": 1.0, "active": on, "damage": DreamState.SHELTER_BONUS,
		"reason": "" if on else "no obstacle in the 8 cells around it"}

func _cliffside(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on := ds.is_on_cliff(spot.cell)
	return {"positional": true, "radius": 1.0, "active": on, "range": DreamState.CLIFFSIDE_RANGE, "damage": DreamState.CLIFFSIDE_BONUS,
		"reason": "" if on else "not touching the island's edge"}

func _sudden_bloom(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	return {"effect": "after growing, its next %d attacks deal ×2" % DreamState.SUDDEN_BLOOM_ATTACKS}

func _watchful_rest(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	return {"effect": "%d s with nothing in range: its next attack deals ×2" % roundi(
		DreamState.WATCHFUL_REST_TIME[ds.rule_level(&"watchful_rest")])}

func _straightaway(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var numbers: Array = DreamState.STRAIGHTAWAY[ds.rule_level(&"straightaway")]
	var on := ds.beside_straight(spot.cell)
	return {"positional": true, "radius": 1.0, "active": on, "damage": numbers[0], "range": numbers[1],
		"reason": "" if on else "no straight stretch of %d+ path tiles beside it" % DreamState.STRAIGHT_TILES}

func _heart_of_the_maze(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var heart := ds.get_heart_of_maze()
	var on: bool = spot.node != null and heart == spot.node
	return {"run_wide": true, "active": on, "damage": DreamState.HEART_OF_MAZE_BONUS,
		"reason": "" if on else "another Warden stands furthest from the rest"}

func _rain_on_glass(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if spot.data.line != "light":
		return {}
	return {"effect": "+%d%% damage to Soaked nightmares" % roundi(DreamState.RAIN_ON_GLASS_PER * ds.rule_stacks(&"rain_on_glass") * 100)}

# Seed cards (dream_design.md "Seed cards"): the "Now" effects that change a Warden's damage.
func _kind_canopy(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	var touching := board.touching(spot).size()
	var on := touching >= DreamState.KIND_CANOPY_TOUCHING
	return {"positional": true, "radius": 1.0, "active": on, "damage": DreamState.KIND_CANOPY_BONUS,
		"reason": "" if on else "touches %d Wardens (needs %d)" % [touching, DreamState.KIND_CANOPY_TOUCHING]}

func _shared_light(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	var touching := board.touching(spot).size()
	var bonus := minf(DreamState.SHARED_LIGHT_PER * touching, DreamState.SHARED_LIGHT_MAX)
	return {"positional": true, "radius": 1.0, "active": bonus > 0.0, "damage": bonus,
		"note": count_text(touching, "Warden") + " touching", "reason": "" if bonus > 0.0 else "no Warden touching it"}

func _bramble_oath(_spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	var tiles := ds.walls_added_tiles()
	var bonus := minf(DreamState.BRAMBLE_OATH_PER * (tiles / DreamState.BRAMBLE_OATH_TILES), DreamState.BRAMBLE_OATH_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "walls add %d path tiles" % tiles,
		"reason": "" if bonus > 0.0 else "your walls add fewer than 10 path tiles"}

func _golden_harvest(_spot: Dictionary, _board: Board, card: UpgradeData) -> Dictionary:
	var dew := ds.dew_harvested()
	var bonus := minf(DreamState.GOLDEN_HARVEST_PER * (dew / 100), DreamState.GOLDEN_HARVEST_MAX)
	var grown := ds.seed_grown(card)
	return {"run_wide": true, "active": grown and bonus > 0.0, "damage": bonus, "note": "%d Dew harvested" % dew,
		"reason": "" if grown and bonus > 0.0 else ("no catcher yet" if not grown else "harvest 100 Dew")}

# Drumbeat (card 248, Swift): touching 2+ other attacking Wardens (the 8 cells) = +30% attack speed. Live.
func _drumbeat(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var touching := board.touching(spot).filter(func(o: Dictionary) -> bool: return DreamEffects._data(o).can_attack).size()
	var on := touching >= DreamState.DRUMBEAT_TOUCHING
	return {"positional": true, "radius": 1.0, "active": on, "speed": DreamState.DRUMBEAT_SPEED,
		"note": count_text(touching, "attacking Warden") + " touching",
		"reason": "" if on else "touches %d attacking Wardens (needs %d)" % [touching, DreamState.DRUMBEAT_TOUCHING]}

# Clearing payoffs (cards 246–247): a Warden touching a tended stump, or planted in a moved hollow.
func _tended_stumps(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on := ds.touches_stump(spot.cell)
	return {"positional": true, "radius": 1.0, "active": on, "damage": DreamState.TENDED_STUMPS_BONUS[ds.rule_level(&"tended_stumps")],
		"reason": "" if on else "no tended stump touching it"}

func _hollow_ground(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on := ds.in_hollow(spot.cell)
	return {"positional": true, "radius": 0.0, "active": on, "range": DreamState.HOLLOW_GROUND_RANGE[ds.rule_level(&"hollow_ground")],
		"reason": "" if on else "not planted in a moved hollow"}

# Grove build branches (cards 238, 243): Restless Roots speeds slow Wardens; Far Reach lengthens area attackers.
func _restless_roots(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on: bool = spot.data.attacks_per_second < DreamState.RESTLESS_ROOTS_BELOW
	return {"active": on, "speed": DreamState.RESTLESS_ROOTS_SPEED,
		"reason": "" if on else "attacks %.2f times a second (needs under 1)" % spot.data.attacks_per_second}

func _far_reach(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on := DreamState.has_area_attack(spot.data)
	return {"active": on, "range": DreamState.FAR_REACH_RANGE[ds.rule_level(&"far_reach")],
		"reason": "" if on else "no area attack"}

# The live line a board-scaling card shows on its face in an offer (dream_design.md #75): "You have 7
# attacking Wardens · +40%", "Now: 12 cleared · +12%". "" for cards that don't scale with the board.
# Uses the card's reporter as if it were taken, on a planted attacker (or a hypothetical one).
#   Resonance is included (the card's own once taken, else what it would get now); a zero bonus reads
# "+0%", never "off"; cards whose value only exists during a drift show the last drift's averages at a
# rest ("" before drift 1). Counts use plurals ("1 Thornwall").
func preview_line(card: UpgradeData) -> String:
	if card == null:
		return ""
	var power: float = ds.resonance(card) if ds.has_card(card.id) else 1.0 + float(ds.resonance_preview(card).bonus)
	if STATE_LINES.has(card.rule_id):
		return _state_line(card.rule_id, power)
	if not REPORTERS.has(card.rule_id):
		return ""
	var spot := {}
	for tower in ds._towers():
		if tower.tower_data.can_attack:
			spot = spot_for(tower)
			break
	if spot.is_empty():
		spot = {"data": PREVIEW_ATTACKER, "cell": Vector2(-999, -999), "rank": 0, "node": null}
	var row: Dictionary = call(REPORTERS[card.rule_id], spot, _shared_board(), card)
	if row.is_empty() or not row.get("run_wide", false):
		return ""
	var value := "+0%"
	if row.get("active", false):
		if row.get("speed", 0.0) != 0.0 and row.get("damage", 0.0) == 0.0:
			value = "%+d%% speed" % roundi(row.speed * power * 100)
		else:
			value = "%+d%%" % roundi(row.get("damage", 0.0) * power * 100)
	var note: String = row.get("note", "")
	if note == "":
		return ""  # No number from the run to show (Heart of the Maze, Long Shadows…): no live line
	if note.ends_with("attacking Wardens") or note.ends_with("attacking Warden"):
		note = "You have %s" % count_text(ds.count_attackers(), "attacking Warden")
	else:
		note = "Now: " + note
	return "%s · %s" % [note, value]

# "1 Thornwall", "3 Thornwalls" (text_style.md plurals).
static func count_text(n: int, word: String, plural: String = "") -> String:
	return "%d %s" % [n, word if n == 1 else (plural if plural != "" else word + "s")]

# Cards whose live line comes from the run rather than a Warden's row.
const STATE_LINES: Array[StringName] = [&"winding_path", &"deep_well", &"canopy", &"old_growth", &"bitter_hedges",
	&"hedge_maze", &"crowded_path", &"lone_hunter", &"last_stand", &"quick_step"]

func _state_line(rule: StringName, power: float) -> String:
	match rule:
		&"winding_path":
			var tiles: int = ds.path_length
			return "Now: %s · +%d Dew per rest" % [count_text(tiles, "path tile"),
				roundi(tiles / DreamState.WINDING_PATH_TILES * power)]
		&"deep_well":
			return "Now: %d Dew banked · +%d Dew at the next rest" % [ds.run_state.dew, ds.deep_well_interest(power)]
		&"canopy":
			var planted: int = ds._attackers_planted
			var steps := ds.canopy_steps_reached()
			var line := "Now: %s planted · %+d%%" % [count_text(planted, "attacking Warden"),
				roundi(DreamState.CANOPY_BONUS * steps * power * 100)]
			if steps < DreamState.CANOPY_STEPS.size():
				line += " (%d for the next %+d%%)" % [DreamState.CANOPY_STEPS[steps], roundi(DreamState.CANOPY_BONUS * power * 100)]
			return line
		&"old_growth":
			var towers := ds._towers().filter(func(t: Tower) -> bool: return t.tower_data.can_attack)
			var five := towers.filter(func(t: Tower) -> bool: return DreamState.drifts_stood(t) >= DreamState.OLD_GROWTH_STEPS[-1][0]).size()
			var fifteen := towers.filter(func(t: Tower) -> bool: return DreamState.drifts_stood(t) >= DreamState.OLD_GROWTH_STEPS[0][0]).size()
			return "Now: %s stood %d+ drifts (%+d%%), %d stood %d+ (%+d%%)" % [count_text(five, "Warden"),
				DreamState.OLD_GROWTH_STEPS[-1][0], roundi(DreamState.OLD_GROWTH_STEPS[-1][1] * power * 100), fifteen,
				DreamState.OLD_GROWTH_STEPS[0][0], roundi(DreamState.OLD_GROWTH_STEPS[0][1] * power * 100)]
		&"bitter_hedges":
			var walls := ds.walls_beside_path()
			return "Now: %s beside the path · up to %+d%% for a nightmare passing them" % [count_text(walls, "Thornwall"),
				roundi(minf(DreamState.BITTER_PER * walls, DreamState.BITTER_MAX) * power * 100)]
		&"hedge_maze":
			var level := ds.rule_level(&"hedge_maze") if ds.has_rule(&"hedge_maze") else 0
			var per: int = DreamState.HEDGE_PER_WALLS[level]
			var walls := ds.count_wardens("thornwall")
			var bonus := minf(DreamState.HEDGE_BONUS_PER * (walls / per), DreamState.HEDGE_BONUS_MAX[level]) * power
			var next := (walls / per + 1) * per
			return "Now: %s · %+d%% (%d for the next %+d%%)" % [count_text(walls, "Thornwall"), roundi(bonus * 100), next,
				roundi(DreamState.HEDGE_BONUS_PER * power * 100)]
		&"crowded_path", &"lone_hunter", &"last_stand":
			return _drift_line(rule, power)
		&"quick_step":  # About calling drifts early: only during a block (user: it showed the attacker count)
			if ds.drift_director.resting:
				return ""
			var speed := DreamState.QUICK_STEP_SPEED * maxi(ds.rule_stacks(&"quick_step"), 1) * power if ds.quick_step_active() else 0.0
			return "Now: %d called early this block · %+d%% speed" % [ds._early_calls, roundi(speed * 100)]
	return ""

# During a drift: the value now; at a rest: last drift's averages ("" before the first drift).
func _drift_line(rule: StringName, power: float) -> String:
	var live := not ds.drift_director.resting
	var stats: Dictionary = ds.last_drift_stats
	if not live and stats.is_empty():
		return ""
	match rule:
		&"crowded_path":
			var level := ds.rule_level(&"crowded_path") if ds.has_rule(&"crowded_path") else 0
			var count: float
			if live:
				count = ds.average_in_range()
			else:
				count = float(stats.in_range)
			var bonus := minf(DreamState.CROWDED_PER[level] * count, DreamState.CROWDED_MAX[level]) * power
			if live:
				return "Now: %.1f nightmares in range on average · about %+d%%" % [count, roundi(bonus * 100)]
			return "Last drift: %.1f nightmares in range on average · about %+d%%" % [count, roundi(bonus * 100)]
		&"lone_hunter":
			var level := ds.rule_level(&"lone_hunter") if ds.has_rule(&"lone_hunter") else 0
			var share := float(stats.get("alone", 0.0))
			if live:
				var enemies: Array = ds.spawner.get_enemies()
				share = float(enemies.filter(func(e: Node2D) -> bool: return ds._is_alone(e)).size()) / maxf(enemies.size(), 1.0)
			return "%s: %d%% of nightmares alone · %+d%% on those" % ["Now" if live else "Last drift", roundi(share * 100),
				roundi(DreamState.LONE_HUNTER_BONUS[level] * power * 100)]
		&"last_stand":
			var share := float(stats.get("near", 0.0))
			if live:
				var enemies: Array = ds.spawner.get_enemies()
				share = float(enemies.filter(func(e: Node2D) -> bool: return ds.is_near_heartwood(e)).size()) / maxf(enemies.size(), 1.0)
			return "%s: %d%% of nightmares near the Heartwood · %+d%% on those" % ["Now" if live else "Last drift",
				roundi(share * 100), roundi(DreamState.LAST_STAND_BONUS * power * 100)]
	return ""

const PREVIEW_ATTACKER := preload("res://resource/tower/sprout.tres")


# --- Catalogue cards 204–226 (dream_design.md "New cards for the catalogue") ----------------------

func _many_rings(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if spot.data.get_id() != "sprout":
		return {}
	var ranks := DreamEffects._rank(spot) if not board.holds(spot) else 0
	for o in board.entries:
		ranks += DreamEffects._rank(o)
	var bonus := minf(DreamState.MANY_RINGS_PER * ranks, DreamState.MANY_RINGS_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d ranks" % ranks,
		"reason": "" if bonus > 0.0 else "no ranks on any Warden yet"}

func _hedgerow(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if spot.data.get_id() != "sprout":
		return {}
	var on := board.touching(spot).any(func(o: Dictionary) -> bool: return DreamEffects._data(o).line == "wall")
	return {"positional": true, "radius": 1.0, "active": on, "damage": DreamState.HEDGEROW_BONUS,
		"reason": "" if on else "no Thornwall touching it"}

func _spinning_corners(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not DreamState.SPINNING_WARDENS.has(spot.data.get_id()):
		return {}
	var on := ds.is_beside_bend(spot.cell, 1)
	return {"positional": true, "radius": 1.0, "active": on, "speed": DreamState.SPINNING_CORNERS_SPEED,
		"reason": "" if on else "no bend in the path in the 8 cells around it"}

func _fresh_soil(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if spot.data.get_id() != "sprout":
		return {}
	var on: bool = ds.run_state.tended_cells.has(spot.cell)
	return {"positional": true, "radius": 0.0, "active": on, "damage": DreamState.FRESH_SOIL_BONUS,
		"reason": "" if on else "not on a cleared cell"}

func _heartwoods_fury(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var heart: Vector2 = ds.map_generator.endPath
	var near := maxf(absf(spot.cell.x - heart.x), absf(spot.cell.y - heart.y)) <= DreamState.FURY_CELLS
	var down := maxi(ds.run_state.max_leaves - ds.run_state.leaves, 0)
	var bonus := minf(DreamState.FURY_PER * down, DreamState.FURY_MAX)
	var on := near and bonus > 0.0
	return {"positional": true, "radius": 0.0, "active": on, "damage": bonus, "note": "%d leaves down" % down,
		"reason": "" if on else ("more than %d cells from the Heartwood" % DreamState.FURY_CELLS if not near else "no leaves lost")}

func _patchwork(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var families := ds.count_owned_families()
	var bonus := minf(DreamState.PATCHWORK_PER * families, DreamState.PATCHWORK_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d families" % families}

func _mixed_grove(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var own := ds.family_of(spot.data.get_id())
	var others := {}
	for o in board.touching(spot):
		var family := ds.family_of(DreamEffects._data(o).get_id())
		if family != "" and family != own:
			others[family] = true
	var bonus := minf(DreamState.MIXED_GROVE_PER * others.size(), DreamState.MIXED_GROVE_MAX)
	return {"positional": true, "radius": 1.0, "active": bonus > 0.0, "damage": bonus,
		"reason": "" if bonus > 0.0 else "no Warden of another family touching it"}

func _quick_step(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on := ds.quick_step_active()
	return {"run_wide": true, "active": on, "speed": DreamState.QUICK_STEP_SPEED * ds.rule_stacks(&"quick_step"),
		"reason": "" if on else "call a drift early"}

func _long_shadows(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on: bool = spot.data.attack_range >= DreamState.LONG_SHADOWS_FROM
	return {"run_wide": true, "active": on, "range": DreamState.LONG_SHADOWS_RANGE,
		"reason": "" if on else "range under %d" % int(DreamState.LONG_SHADOWS_FROM)}

func _scarred_bark(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var level := ds.rule_level(&"scarred_bark")
	var lost: int = ds.run_state.leaves_lost
	var bonus := minf(DreamState.SCARRED_BARK_PER[level] * lost, DreamState.SCARRED_BARK_MAX[level])
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": "%d leaves lost" % lost,
		"reason": "" if bonus > 0.0 else "no leaves lost yet"}

func _desperate_bloom(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var on: bool = ds.run_state.leaves * 2 < ds.run_state.max_leaves
	return {"run_wide": true, "active": on, "speed": DreamState.DESPERATE_BLOOM_SPEED,
		"note": "%d of %d leaves" % [ds.run_state.leaves, ds.run_state.max_leaves],
		"reason": "" if on else "not below half your leaves"}

func _odd_one_out(spot: Dictionary, board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var id: String = spot.data.get_id()
	var same := board.entries.filter(func(o: Dictionary) -> bool: return DreamEffects._data(o).get_id() == id and o.node != spot.node).size()
	var on := same == 0
	return {"positional": true, "radius": 0.0, "active": on, "damage": DreamState.ODD_ONE_OUT_BONUS[ds.rule_level(&"odd_one_out")],
		"reason": "" if on else "%d more of its kind on the map" % same}

func _grand_tour(spot: Dictionary, _board: Board, _card: UpgradeData) -> Dictionary:
	if not spot.data.can_attack:
		return {}
	var statuses := ds.owned_statuses().size()
	var bonus := minf(DreamState.GRAND_TOUR_PER * statuses, DreamState.GRAND_TOUR_MAX)
	return {"run_wide": true, "active": bonus > 0.0, "damage": bonus, "note": count_text(statuses, "status", "statuses")}
