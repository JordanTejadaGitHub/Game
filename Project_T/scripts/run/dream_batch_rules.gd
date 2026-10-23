extends RefCounted
# The run-shaping generic Dream cards (dream_council_review.md 22 to 24; the owner 2026-10-13: "a different job, but
# the generic cards should be good for every class"). DreamState holds one of these (`batch`) and calls in; Tower,
# Enemy, TowerPlacer, DriftDirector and OmenDirector ask DreamState. Every number is a starting point for Balancing
# and lives here, in one place.

# --- Numbers ------------------------------------------------------------------------------------------------------
const GROWTH_RINGS_MAX_RANK := 3  # The free rank never lifts a Warden past rank III (banked ranks count)
const GROWTH_RINGS_CONFIRM_SECONDS := 6.0  # A second plant within this long confirms giving the rank up
const REACH_RANK := 1  # Heartwood's Reach: the first Warden planted on each cleared cell arrives with this many free ranks
const SEEDFALL_PRICE := 10  # Seedfall: every Sprout costs this; the price never climbs
const WINDING_PATH_MULTIPLIER := 1.5  # Winding Path: the maze's share of every pot x1.5, cap included (+30%). Balancing 2026-10-22 (was x2 of the rest Dew)
# The six run-shaping redesigns (stake_redesign.md with dream_council_review.md 26's numbers, owner 2026-10-14): no
# card keeps a stake. Wager and Price lines are gone; Clipped Wings is not built (Dark Skies retires).
const CALL_OF_THE_WILD_PER_SECOND := 0.01  # Call of the Wild: a drift called early holds +1% Dew per second of arrival skipped…
const CALL_OF_THE_WILD_MAX := 0.30  # …up to +30%
const PRESS_ON_EVERY := 5  # Press On: every 5th drift you call early…
const PRESS_ON_LEAVES := 1  # …regrows this many leaves, at once
const NIPPED_BONUS := 0.20  # Nipped in the Bud (id held_breath): dispels before halfway along the route pay +20% Dew
const NIPPED_SHARE := 0.5
const HARD_WON_DISPELS := 40  # Hard-Won Rings (id clean_night): every 40 nightmares a Warden dispels… (owner playtest 2026-10-20: was 80, banked ~150 Dew of ranks by drift 45; a starting point for Balancing)
const HARD_WON_MAX_RANK := 5  # …give it a free rank, up to rank V (was IV)
const GAUNTLET_MULT := 1.20  # Gauntlet (id front_line): between two attacking Wardens, one on each side of the path (card pass 2026-10-16: x1.20 on the synergy side; was +30% plain)
const GAUNTLET_SIDE := Vector2(0.35, 1.4)  # Cells to the side of the path a Warden's centre may stand (the near and far edge)
const GAUNTLET_ALONG := 0.75  # …and at most this far along it
const FRESH_GROWTH_SPEED := 1.0  # Fresh Growth: +100% attack speed ("twice as fast")…
const FRESH_GROWTH_TIME := 8.0  # …for this long, on the Warden and every Warden touching it
const THORNY_LASH := 3.0  # Thorny Walls: the lash is this x the drift's health growth (DriftDirector.get_growth)…
const THORNY_CEILING := 0.25  # …and thorns never take more than this share of one nightmare's health
const THORNY_BOSS_CEILING := 0.10  # (bosses and Deeply Blighted nightmares)
const THORNY_TWIG_SHARE := 0.25  # A twig wall lashes for a quarter
const COZY_CORNERS_BONUS := 0.30  # Cozy Corners: the Warden on the inside of a bend
const PASSING_THREAD_MULT := 1.25  # Passing Thread: from a Warden's second stretch of route on (card pass 2026-10-16: x1.25, synergy side; was +50% plain)
const PASSING_THREAD_GAP := 3  # Route cells out of reach between two stretches for the later one to count as a new pass
const BEND_STRAIGHT_STEPS := 2  # A bend has one full cell (2 half-cell steps) of straight path on each side
const SNAG_SECONDS := 4.0  # Snag: a snagged flyer walks the maze this long
const SNAG_FLYERS_WITHIN := 10  # Snag is only offered while a flyer is due within this many drifts
const SNAG_REACH := 0.75  # Cells from a Thornwall's centre a flyer must pass within
const LONG_WAY_PER_BEND := 0.02  # Long Way Round: bosses and Deeply Blighted take this much more per bend behind them…
const LONG_WAY_MAX := 0.40  # …up to this
const DARK_SKIES_DEW := 50  # Dark Skies (retired 2026-10-14; an old save keeps it): every Omen seen through pays this much more
const HEELS_PER_CALL := 0.10  # Hot on Their Heels: per drift called early this block…
const HEELS_MAX := 0.40  # …up to this, until the rest
const FIRST_LIGHT_MULTIPLIER := 3.0  # First Light: each Warden's first damage to a nightmare (a hit, a tick, a cloud)
const LONG_WALK_MAX := 0.25  # The Long Walk's cap (unused since the card pass; kept in step: power budget 2026-10-16)
# The batch cards: always in a run's pool, like RUN_POOL_BASICS; never guaranteed, never weighted. Call of the Wild is
# retired (owner 2026-10-20: no card pays Dew for calling drifts early); its rule code stays for an old save.
const BATCH: Array[String] = ["growth_rings", "heartwoods_reach", "seedfall", "winding_path",
	"press_on", "fresh_growth", "held_breath", "thorny_walls", "cozy_corners", "passing_thread", "switchback"]

# --- State (saved with the run: to_save / load_save) ----------------------------------------------------------------
var rings_planted := false  # Growth Rings: something was planted since the last rest's start
var rings_result := ""  # "", "lost", or the Warden's name that got the rank: the rest report's line for the rest just begun
var leaves_mark := 0  # RunState.leaves_lost when the block began: leaves lost this block = leaves_lost - this
var press_on_calls := 0  # Press On: drifts called early so far (never resets; every 5th regrows a leaf)
var reach_cells := {}  # Heartwood's Reach: cleared cells whose free rank is used ("x,y" -> true)
var hard_won := {}  # Hard-Won Rings: a Warden's cell ("x,y") -> nightmares it dispelled (selling resets it)
var heels := 0  # Hot on Their Heels: early calls counted this block (cleared at the rest)
var _gauntlet := {}  # Gauntlet: route point -> true, between two attacking Wardens (rebuilt with the board or the route)
var _gauntlet_key := ""
# Not saved (a save is made at a rest, with nothing on the field):
var _rings_confirm_until := -1.0
var _rings_confirmed := false
var _first := {}  # First Light: "cell:nightmare id" -> true
var _snagged := {}  # Snag: wall instance id -> drift number
var route_serial := 0  # Bumped whenever the route changes (Passing Thread's stretches are cached per Warden)
var bend_points := {}  # Route point (grid, half-cell) -> true: the route's bends (see bend_indices)
var bend_inside := []  # Vector2 (px): the inside corner of each bend (Cozy Corners)
var bend_left := []  # float (px): each bend's distance from the Heartwood along the route (Long Way Round)
var route_px := 0.0  # The route's length in px
var _route_index := {}  # Route point -> its index on the route (Passing Thread; a Waymark: leg 1's index first)
var _route_index2 := {}  # Waymark: leg 2's points -> index (a corridor walked out to the stone and back is on both legs)
var _route_points := PackedVector2Array()  # The route in order (Passing Thread walks it: a point can come twice)

func to_save() -> Dictionary:
	return {"rings_planted": rings_planted, "leaves_mark": leaves_mark, "press_on_calls": press_on_calls,
		"reach_cells": reach_cells.keys(), "hard_won": hard_won.duplicate(), "heels": heels, "wild": wild.duplicate(true)}

func load_save(data: Dictionary) -> void:
	rings_planted = bool(data.get("rings_planted", false))
	leaves_mark = int(data.get("leaves_mark", 0))
	press_on_calls = int(data.get("press_on_calls", 0))
	reach_cells.clear()
	for key in data.get("reach_cells", []):
		reach_cells[String(key)] = true
	hard_won.clear()
	var saved_won = data.get("hard_won", {})
	if saved_won is Dictionary:
		for key in saved_won:
			hard_won[String(key)] = int(saved_won[key])
	heels = int(data.get("heels", 0))
	wild.clear()
	var saved_wild = data.get("wild", {})
	if saved_wild is Dictionary:
		for key in saved_wild:
			var entry = saved_wild[key]
			if entry is Array and entry.size() == 2:
				wild[String(key)] = [int(entry[0]), int(entry[1])]

# --- Shared rules -------------------------------------------------------------------------------------------------

# Leaves actually lost this block: a leak Hardened Bark absorbs is not a leaf lost (the rest's `perfect` flag is
# "nothing reached the Heartwood", which that leak breaks).
func leaves_lost(dreams: DreamState) -> int:
	return maxi(dreams.run_state.leaves_lost - leaves_mark, 0)

func clean_block(dreams: DreamState) -> bool:
	return leaves_lost(dreams) == 0

# The bends of a half-cell route: the indices of the points where it turns with at least one full cell of straight
# path before and after. A half-cell jog is not a bend. Every per-bend card reads this one list (Switchback, Corner
# Sign, Cozy Corners, Long Way Round).
static func bend_indices(path: PackedVector2Array) -> PackedInt32Array:
	var bends := PackedInt32Array()
	for i in range(BEND_STRAIGHT_STEPS, path.size() - BEND_STRAIGHT_STEPS):
		var before: Vector2 = path[i] - path[i - 1]
		var after: Vector2 = path[i + 1] - path[i]
		if before.is_equal_approx(after):
			continue
		var straight := true
		for k in range(1, BEND_STRAIGHT_STEPS):
			if not (path[i - k] - path[i - k - 1]).is_equal_approx(before) or not (path[i + k + 1] - path[i + k]).is_equal_approx(after):
				straight = false
		if straight:
			bends.append(i)
	return bends

# DreamState._update_bends calls this with the new route: the bend list and what each bend card needs from it.
func route_changed(dreams: DreamState, path: PackedVector2Array) -> void:
	route_serial += 1
	bend_points.clear()
	bend_inside.clear()
	bend_left.clear()
	_route_index.clear()
	_route_index2.clear()
	_route_points = path.duplicate()
	var split: int = dreams.map_generator.waymark_split(path) if dreams.map_generator.has_method("waymark_split") else -1
	var grid = dreams.map_generator.MAP_GRID
	var cell_px: float = grid.cell_size.x
	var left := PackedFloat32Array()
	left.resize(path.size())
	var total := 0.0
	for i in range(path.size() - 1, -1, -1):
		if i < path.size() - 1:
			total += path[i].distance_to(path[i + 1]) * cell_px
		left[i] = total
		_route_index[path[i]] = i  # (Walking back: a point on both legs keeps its leg-1 index)
		if split >= 0 and i >= split:
			_route_index2[path[i]] = i
	route_px = total
	for i in bend_indices(path):
		bend_points[path[i]] = true
		var before: Vector2 = (path[i] - path[i - 1]).normalized()
		var after: Vector2 = (path[i + 1] - path[i]).normalized()
		# The inside of the turn: one lane's width (half a cell) diagonally back and towards where the path goes
		bend_inside.append(grid.calculate_map_position(path[i] + (after - before) * 0.5))
		bend_left.append(left[i])

func is_bend_point(point: Vector2) -> bool:
	return bend_points.has(point)

func bend_count() -> int:
	return bend_left.size()

# A nightmare's share of its route walked, 0..1 (a flyer: of its own line).
func route_share(enemy: Node2D) -> float:
	var left: float = enemy.get_remaining_distance()
	var total := route_px
	if enemy.is_flying() or total <= 0.0:
		total = maxf(float(enemy.get_meta(&"batch_route_total", 0.0)), left)
		enemy.set_meta(&"batch_route_total", total)
	return clampf(1.0 - left / total, 0.0, 1.0) if total > 0.0 else 0.0

# Bends of the route behind a walking nightmare, read from where it stands (pull-backs and laps cannot farm it).
func bends_behind(enemy: Node2D) -> int:
	if enemy.is_flying():
		return 0
	var left: float = enemy.get_remaining_distance()
	var count := 0
	for at in bend_left:
		if float(at) > left:
			count += 1
	return count

# --- Rests --------------------------------------------------------------------------------------------------------

# The base rest bonus's multiplier (DriftDirector._pay_rest_bonus). No card stakes the rest bonus any more (Held
# Breath and A Clean Night became Nipped in the Bud and Hard-Won Rings, 2026-10-14).
func rest_bonus_multiplier(_dreams: DreamState) -> float:
	return 1.0

func maze_multiplier(dreams: DreamState) -> float:
	return WINDING_PATH_MULTIPLIER if dreams.has_rule(&"winding_path") else 1.0

# At each rest's start, before the block's counters reset: Growth Rings, Press On, A Clean Night. `excluded`: Wardens
# another free-rank card raised at this rest.
func rest(dreams: DreamState, _early_calls: int, excluded: Array) -> void:
	rings_result = ""
	if dreams.has_rule(&"growth_rings"):
		rings_result = "lost"
		if not rings_planted:
			var top := _rings_target(dreams, excluded)
			rings_result = "no Warden below rank III"
			if top != null:
				top.bank_rank()
				rings_result = top.tower_data.display_name
				dreams._credit("growth_rings", "dew", float(Tower.RANK_COSTS[mini(top.rank + top.banked_ranks - 1, Tower.RANK_COSTS.size() - 1)]))
				dreams.sunlit_granted.emit([top])
	# A new window and a new block
	rings_planted = false
	_rings_confirmed = false
	heels = 0
	leaves_mark = dreams.run_state.leaves_lost
	_snagged.clear()
	_first.clear()  # First Light: the field is clear at a rest (council full_review 2026-10-17)
	for tower in dreams._towers():
		tower.set_meta(&"batch_stood_at_rest", true)  # Fresh Growth: only Wardens standing at the last rest

# Growth Rings: the block's top Warden by damage among those that can still take a free rank up to III.
func _rings_target(dreams: DreamState, excluded: Array) -> Tower:
	var log := DamageLog.instance
	if log == null:
		return null
	for row in log.get_top_towers("block", 50):
		var tower: Tower = row.get("tower") as Tower
		if tower == null or not is_instance_valid(tower) or excluded.has(tower) or not tower.can_nurture():
			continue
		if DreamState.ranks_with_banked(tower) >= mini(GROWTH_RINGS_MAX_RANK, dreams.get_max_rank_for(tower)):
			continue
		return tower
	return null

# The rest report's lines for the rest just begun ("" = none).
func report_lines(dreams: DreamState) -> String:
	var text := ""
	if dreams.has_rule(&"growth_rings") and rings_result != "":
		text += "\nGrowth Rings: %s" % ("lost (you planted this block)" if rings_result == "lost" else
			(rings_result if rings_result.begins_with("no ") else "a free rank waits on %s" % rings_result))
	return text

# --- Planting -----------------------------------------------------------------------------------------------------

# Growth Rings: the first plant of a clean window asks once (TowerPlacer refuses that press and toasts; the next
# plant within GROWTH_RINGS_CONFIRM_SECONDS, or any plant after it this window, goes through).
func rings_blocks_plant(dreams: DreamState) -> bool:
	if not dreams.has_rule(&"growth_rings") or rings_planted or _rings_confirmed:
		return false
	if DisplayServer.get_name() == "headless":
		return false  # Sims and tests plant without a player to ask
	var now := Time.get_ticks_msec() / 1000.0  # Real time: building works while paused
	if now <= _rings_confirm_until:
		_rings_confirmed = true
		return false
	_rings_confirm_until = now + GROWTH_RINGS_CONFIRM_SECONDS
	var hud: Node = dreams.owner.get_node_or_null("HUD") if dreams.owner != null else null
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast("Growth Rings: planting gives up this block's free rank. Plant again to confirm.")
	return true

func rings_line(dreams: DreamState) -> String:
	return "Now: you planted this block, no free rank at the next rest" if rings_planted else "Now: nothing planted, a free rank at the next rest"

# Every plant (TowerPlacer.tower_built: free ones and ones made while paused too). Selling it does not undo this.
func planted(dreams: DreamState, tower: Tower) -> void:
	rings_planted = true
	tower.set_meta(&"batch_stood_at_rest", false)
	if not dreams.has_card("heartwoods_reach") or not tower.tower_data.can_attack:
		return
	# Heartwood's Reach: the first Warden on each cleared cell arrives at rank I. One rank per Warden, however many
	# cleared cells its footprint covers, and every covered cell is used up. A Thornwall never uses a cell up.
	var fresh := false
	for cell in tower.get_cells():
		var key := "%d,%d" % [roundi(cell.x), roundi(cell.y)]
		if dreams.run_state.tended_cells.has(cell) and not reach_cells.has(key):
			reach_cells[key] = true
			fresh = true
	if fresh and tower.can_nurture():
		tower.bank_rank(REACH_RANK)
		dreams._credit("heartwoods_reach", "dew", float(Tower.RANK_COSTS[0]))

# --- Calling early ------------------------------------------------------------------------------------------------

# A drift started. `early`: called with at least DriftDirector.call_early_min_seconds of arrival skipped.
func drift_started(dreams: DreamState, number: int, early: bool) -> void:
	# First Light is forgotten at rest() only: drifts flow into each other, so a nightmare still walking from the last
	# drift must not take a second "first" hit (council full_review 2026-10-17)
	if not early:
		return
	if dreams.has_rule(&"hot_on_their_heels"):  # No stake (owner 2026-10-19): a lost leaf no longer clears it
		heels += 1
		dreams.bump_board()
	if dreams.has_rule(&"press_on"):
		# Press On: every 5th drift called early regrows a leaf at once (the count carries over between blocks)
		press_on_calls += 1
		if press_on_calls % PRESS_ON_EVERY == 0:
			dreams.run_state.regrow_leaves(PRESS_ON_LEAVES)
			dreams._credit("press_on", "leaves", float(PRESS_ON_LEAVES))

# Call of the Wild: the share more Dew drift `number` holds when called early (+1% per second of the drift before it
# still to arrive, up to +30%). DreamState.get_dew_pot_multiplier asks, at the drift's start and for the forecast.
func wild_bonus(dreams: DreamState, number: int) -> float:
	if not dreams.has_rule(&"call_of_the_wild") or dreams.drift_director == null:
		return 0.0
	return minf(CALL_OF_THE_WILD_PER_SECOND * dreams.drift_director.arrival_left(number - 1), CALL_OF_THE_WILD_MAX)

# Nipped in the Bud: a nightmare dispelled before it is halfway along its route pays this share more (run_state's Dew).
func nipped_extra(dreams: DreamState, enemy: Node2D) -> float:
	if not dreams.has_rule(&"held_breath") or not is_instance_valid(enemy):
		return 0.0
	return NIPPED_BONUS if route_share(enemy) < NIPPED_SHARE else 0.0

# Hard-Won Rings: a nightmare's health reached 0 under `tower`'s damage (exact kills count). Every 80 give it a free
# rank, banked, up to rank IV. Counted by the Warden's cell: growing keeps it, selling resets it (DreamState).
func hard_won_dispel(dreams: DreamState, tower: Tower) -> void:
	if not dreams.has_rule(&"clean_night") or tower == null or not tower.tower_data.can_attack:
		return
	var key := "%d,%d" % [roundi(tower.cell.x * 2.0), roundi(tower.cell.y * 2.0)]
	var count := int(hard_won.get(key, 0)) + 1
	if count < HARD_WON_DISPELS:
		hard_won[key] = count
		return
	hard_won[key] = 0
	if tower.can_nurture() and DreamState.ranks_with_banked(tower) < mini(HARD_WON_MAX_RANK, dreams.get_max_rank_for(tower)):
		tower.bank_rank()
		dreams._credit("clean_night", "dew", float(Tower.RANK_COSTS[mini(tower.rank + tower.banked_ranks - 1, Tower.RANK_COSTS.size() - 1)]))
		dreams.sunlit_granted.emit([tower])
		dreams.note_card(&"clean_night", tower.global_position, 1, tower)  # The card's badge and cue on that Warden
		dreams.visuals.rank_earned(tower)  # "Rank earned!" and the rank art flash (owner 2026-10-20)

func hard_won_sold(tower: Tower) -> void:
	hard_won.erase("%d,%d" % [roundi(tower.cell.x * 2.0), roundi(tower.cell.y * 2.0)])

func hard_won_of(tower: Tower) -> int:
	return int(hard_won.get("%d,%d" % [roundi(tower.cell.x * 2.0), roundi(tower.cell.y * 2.0)], 0))

# Gauntlet: route points with an attacking Warden (not a Sprout or a wall) on each side of the path. Rebuilt when the
# board or the route changes.
func gauntlet_at(dreams: DreamState, enemy: Node2D) -> bool:
	if enemy.is_flying():
		return false
	var key := "%d:%d" % [int(dreams.board_version), route_serial]
	if key != _gauntlet_key:
		_gauntlet_key = key
		_build_gauntlet(dreams)
	return _gauntlet.has(enemy.get_target_cell())

func _build_gauntlet(dreams: DreamState) -> void:
	_gauntlet.clear()
	var grid = dreams.map_generator.MAP_GRID
	var cell_px: float = grid.cell_size.x
	var walls: Array = dreams._towers().filter(func(t: Tower) -> bool:
		return t.tower_data.can_attack and t.tower_data.line != "wall" and t.tower_data.get_id() != "sprout")
	if walls.size() < 2:
		return
	var path: PackedVector2Array = dreams.map_generator.get_path_from(dreams.map_generator.startPath)
	for i in path.size():
		var along: Vector2 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		if along == Vector2.ZERO:
			continue
		var side := Vector2(-along.y, along.x)
		var at: Vector2 = grid.calculate_map_position(path[i])
		var left := false
		var right := false
		for tower in walls:
			var away: Vector2 = (tower.global_position - at) / cell_px
			if absf(away.dot(along)) > GAUNTLET_ALONG:
				continue
			var across: float = away.dot(side)
			if across >= GAUNTLET_SIDE.x and across <= GAUNTLET_SIDE.y:
				left = true
			elif across <= -GAUNTLET_SIDE.x and across >= -GAUNTLET_SIDE.y:
				right = true
			if left and right:
				_gauntlet[path[i]] = true
				break

func gauntlet_count(dreams: DreamState) -> int:
	var key := "%d:%d" % [int(dreams.board_version), route_serial]
	if key != _gauntlet_key:
		_gauntlet_key = key
		_build_gauntlet(dreams)
	return _gauntlet.size()

func leaves_changed(_dreams: DreamState) -> void:
	pass  # Hot on Their Heels no longer clears on a lost leaf (owner 2026-10-19); kept for its callers

func heels_bonus(dreams: DreamState) -> float:
	return minf(HEELS_PER_CALL * heels, HEELS_MAX) if dreams.has_rule(&"hot_on_their_heels") else 0.0

# --- Growing during a drift ---------------------------------------------------------------------------------------

# Fresh Growth: a Warden grown or Nurtured during a drift, if it stood at the last rest: it and every Warden touching
# it attack twice as fast for 8 s. Each Warden can receive the burst once per drift.
func grown(dreams: DreamState, tower: Tower) -> void:
	if not dreams.has_rule(&"fresh_growth") or dreams.drift_director.resting or not is_instance_valid(tower):
		return
	if not tower.get_meta(&"batch_stood_at_rest", true):
		return  # Planted this block: selling, replanting and regrowing buys nothing
	var drift: int = dreams.drift_director.drifts_started
	var cell_px: float = tower.MAP_GRID.cell_size.x
	var any := false
	for other in dreams._towers():
		if not other.tower_data.can_attack or int(other.get_meta(&"batch_fresh_drift", -1)) == drift:
			continue
		var away: Vector2 = (other.global_position - tower.global_position).abs()
		if other != tower and maxf(away.x, away.y) > cell_px * 1.05:
			continue  # Touching: the 8 cells around it
		other.set_meta(&"batch_fresh_drift", drift)
		other.set_meta(&"batch_fresh_until", dreams._game_clock + FRESH_GROWTH_TIME)
		any = true
	if any:
		_fresh_until = maxf(_fresh_until, dreams._game_clock + FRESH_GROWTH_TIME)
		dreams.bump_board()

var _fresh_until := -1.0

func is_fresh(dreams: DreamState, tower: Tower) -> bool:
	return tower != null and float(tower.get_meta(&"batch_fresh_until", -1.0)) > dreams._game_clock

# DreamState._process: the bursts end (the Wardens' card rows are rebuilt once).
func tick(dreams: DreamState) -> void:
	if _fresh_until > 0.0 and dreams._game_clock >= _fresh_until:
		_fresh_until = -1.0
		dreams.bump_board()

# --- The maze cards -----------------------------------------------------------------------------------------------

# Cozy Corners: whether the Warden at `at` (px) covers the inside corner of a bend. One Warden per bend; two bends
# around one wall tip pay that Warden once.
func on_inside_corner(dreams: DreamState, at: Vector2) -> bool:
	var half: float = dreams.map_generator.MAP_GRID.cell_size.x * 0.5 + 1.0
	for corner in bend_inside:
		var away: Vector2 = (corner - at).abs()
		if maxf(away.x, away.y) <= half:
			return true
	return false

# Passing Thread: the stretches of route in a Warden's range, as [first index, last index] pairs in route order,
# joined when fewer than PASSING_THREAD_GAP cells of route lie between them. Cached on the Warden per route and range.
func thread_stretches(dreams: DreamState, tower: Tower) -> Array:
	var reach: float = tower.get_range_pixels()
	var key := [route_serial, roundi(reach), tower.global_position]
	if tower.get_meta(&"batch_thread_key", []) == key:
		return tower.get_meta(&"batch_thread", [])
	var grid = dreams.map_generator.MAP_GRID
	var points := _route_points  # In route order (Waymark: a corridor walked both ways is two stretches)
	var stretches := []
	var start := -1
	var last := -1
	for i in points.size():
		var inside: bool = grid.calculate_map_position(points[i]).distance_to(tower.global_position) <= reach
		if inside:
			if start < 0:
				start = i
			last = i
		elif start >= 0 and i - last > PASSING_THREAD_GAP * 2:  # Half-cell steps
			stretches.append([start, last])
			start = -1
	if start >= 0:
		stretches.append([start, last])
	tower.set_meta(&"batch_thread_key", key)
	tower.set_meta(&"batch_thread", stretches)
	return stretches

func _by_route_index(a: Vector2, b: Vector2) -> bool:
	return int(_route_index[a]) < int(_route_index[b])

# How many times the route passes `tower` (the build ghost and the Warden panel: "passes this Warden 3 times").
func thread_passes(dreams: DreamState, tower: Tower) -> int:
	return thread_stretches(dreams, tower).size()

# Whether `enemy` is on its second or later pass of `tower`: it stands on a later stretch than the first. Read from
# its place on the route, so a pull-back cannot farm it; a flyer on its straight line never passes twice.
func on_later_pass(dreams: DreamState, tower: Tower, enemy: Node2D) -> bool:
	if enemy.is_flying():
		return false
	var stretches := thread_stretches(dreams, tower)
	if stretches.size() < 2:
		return false
	var second: bool = not _route_index2.is_empty() and bool(enemy.get("passed_waymark"))
	var index: int = int((_route_index2 if second else _route_index).get(enemy.get_target_cell(), -1))
	return index >= int(stretches[1][0])

# --- Damage -------------------------------------------------------------------------------------------------------

# First Light's memory grew large in one block: forget only nightmares that are gone, so a living one is never "first"
# twice (council full_review 2026-10-17; was a full clear).
func _prune_first() -> void:
	for key in _first.keys():
		var id := String(key).get_slice(":", String(key).get_slice_count(":") - 1).to_int()
		if not is_instance_id_valid(id):
			_first.erase(key)

# Enemy.take_damage asks once per damage event: what the batch cards and the Rares multiply it by. `source` is the
# Warden credited (ticks and clouds keep their applier), so status damage counts like hits.
func damage_multiplier(dreams: DreamState, enemy: Node2D, source: Node, _tag: StringName) -> float:
	var multiplier := 1.0
	var tower := source as Tower
	if tower != null and tower.tower_data.can_attack:
		if dreams.has_rule(&"first_light"):
			# Keyed by the Warden's cell, not its node: selling and replanting mid-drift does not re-arm it
			var key := "%s:%d" % [tower.cell, enemy.get_instance_id()]
			if not _first.has(key):
				_first[key] = true
				multiplier *= FIRST_LIGHT_MULTIPLIER
				DamageLog.note_card_bonus("first_light", FIRST_LIGHT_MULTIPLIER)  # Card credit (Main Merger df7010bb)
				if _first.size() > 8192:
					_prune_first()
		var heels := 1.0 + heels_bonus(dreams)
		multiplier *= heels
		DamageLog.note_card_bonus("hot_on_their_heels", heels)
	if dreams.has_rule(&"long_way_round") and (enemy.enemy_data.is_boss or enemy.elite):
		var long_way := 1.0 + minf(LONG_WAY_PER_BEND * bends_behind(enemy), LONG_WAY_MAX)
		multiplier *= long_way
		DamageLog.note_card_bonus("long_way_round", long_way)
	return multiplier

# Card pass 2026-10-16 (player review 4.4): the maze-shape cards on the synergy side. They multiply after the plain
# clamp (DreamState.batch_damage_multiplier), so a maze built for them still runs away; smaller numbers than before.
func synergy_multiplier(dreams: DreamState, enemy: Node2D, source: Node) -> float:
	var multiplier := 1.0
	var tower := source as Tower
	if tower != null and tower.tower_data.can_attack and dreams.has_rule(&"passing_thread") and on_later_pass(dreams, tower, enemy):
		multiplier *= PASSING_THREAD_MULT
		DamageLog.note_card_bonus("passing_thread", PASSING_THREAD_MULT)
	if dreams.has_rule(&"front_line") and gauntlet_at(dreams, enemy):  # Gauntlet (id front_line)
		multiplier *= GAUNTLET_MULT
		DamageLog.note_card_bonus("front_line", GAUNTLET_MULT)
	return multiplier

func uses_damage_hook(dreams: DreamState) -> bool:
	return dreams.has_rule(&"first_light") or dreams.has_rule(&"passing_thread") or dreams.has_rule(&"hot_on_their_heels") \
		or dreams.has_rule(&"long_way_round") or dreams.has_rule(&"front_line")

# Thorny Walls: the damage of one lash on `enemy` (0 = this nightmare has taken its ceiling from thorns). 3 x the
# drift's health growth, never a share of health; a twig wall a quarter.
func thorny_lash(dreams: DreamState, wall: Tower, enemy: Node2D) -> float:
	var growth: float = dreams.drift_director.get_growth(maxi(dreams.drift_director.drifts_started, 1))
	var lash := THORNY_LASH * growth * (THORNY_TWIG_SHARE if wall.twig else 1.0)
	var heavy: bool = enemy.enemy_data.is_boss or enemy.elite
	var ceiling: float = float(enemy.max_health) * (THORNY_BOSS_CEILING if heavy else THORNY_CEILING)
	var taken := float(enemy.get_meta(&"batch_thorns", 0.0))
	lash = minf(lash, ceiling - taken)
	if lash <= 0.0:
		return 0.0
	enemy.set_meta(&"batch_thorns", taken + lash)
	return lash

func thorny_now(dreams: DreamState) -> float:
	return THORNY_LASH * dreams.drift_director.get_growth(maxi(dreams.drift_director.drifts_started, 1))

# Snag: a flyer crossing a Thornwall that touches an attacking Warden lands and walks the maze for 4 s. Once per
# flyer; each wall once a drift; never a boss (Enemy.ground refuses one). Tower's wall tick calls this.
func snag(dreams: DreamState, wall: Tower, drift: int) -> void:
	if int(_snagged.get(wall.get_instance_id(), -1)) == drift:  # Keyword chips 2026-10-16: any Thornwall (no attacker beside it)
		return
	var reach: float = wall.MAP_GRID.cell_size.x * SNAG_REACH
	for enemy in Tower.nightmares_near(wall.get_tree(), wall.global_position, reach):
		if not is_instance_valid(enemy) or enemy.is_cleansed or not enemy.is_flying() or enemy.enemy_data.is_boss:
			continue
		if enemy.get_meta(&"batch_snagged", false) or enemy.global_position.distance_to(wall.global_position) > reach:
			continue
		enemy.set_meta(&"batch_snagged", true)
		_snagged[wall.get_instance_id()] = drift
		enemy.ground(SNAG_SECONDS)
		dreams._credit(dreams.SETUP.rule_card(dreams, &"snag"), "control", SNAG_SECONDS)  # Setup credit 2026-10-16
		return

func _touches_attacker(dreams: DreamState, wall: Tower) -> bool:
	var cell_px: float = wall.MAP_GRID.cell_size.x
	for other in dreams._towers():
		if other == wall or not other.tower_data.can_attack:
			continue
		var away: Vector2 = (other.global_position - wall.global_position).abs()
		if maxf(away.x, away.y) <= cell_px * 1.05:
			return true
	return false

# Whether a flying nightmare (not a boss) arrives within the next `within` drifts.
func flyers_due(dreams: DreamState, within: int) -> bool:
	var director: DriftDirector = dreams.drift_director
	for number in range(director.drifts_started + 1, mini(director.drifts_started + within, director.drifts.size()) + 1):
		for group in director.drifts[number - 1].groups:
			for entry in group.entries:
				if entry.enemy != null and entry.enemy.trait_kind == EnemyData.Trait.FLYING and not entry.enemy.is_boss:
					return true
	return false

# Thornwalls a flyer's straight line from the start to the Heartwood crosses (any: no attacker needed, Snag's
# card: "Thornwalls under the flight line: 4").
func snag_walls(dreams: DreamState) -> int:
	var grid = dreams.map_generator.MAP_GRID
	var from: Vector2 = grid.calculate_map_position(dreams.map_generator.startPath)
	var to: Vector2 = grid.calculate_map_position(dreams.map_generator.endPath)
	var reach: float = grid.cell_size.x * SNAG_REACH
	var count := 0
	for tower in dreams._towers():
		if tower.tower_data.line != "wall":
			continue
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(tower.global_position, from, to)
		if nearest.distance_to(tower.global_position) <= reach:
			count += 1
	return count

# --- Card lines -----------------------------------------------------------------------------------------------------
# (The Wager and Price lines are gone, 2026-10-14: no card keeps a stake. Bittersweet cards keep cost_description.)

# What a matchup card answers and the player's own number (Snag, Long Way Round), or a card's live line ("" = none).
func answer_line(dreams: DreamState, card: UpgradeData) -> String:
	match card.rule_id:
		&"snag":
			return "Thornwalls under the flight line: %d." % snag_walls(dreams)
		&"long_way_round":
			var bends := bend_count()
			return "Your route: %d bends. Up to +%d%% by the Heartwood." % [bends, roundi(minf(LONG_WAY_PER_BEND * bends, LONG_WAY_MAX) * 100)]
		&"thorny_walls":
			return "Lash now: %d damage." % roundi(thorny_now(dreams))
		&"growth_rings":
			return rings_line(dreams)
		&"winding_path":  # The player's own number, in the HUD's words (the share already includes the card once held)
			var owned: bool = dreams.has_rule(&"winding_path")
			var now_share: float = dreams.drift_director.get_maze_pot_share()
			var base := now_share / WINDING_PATH_MULTIPLIER if owned else now_share
			return "Your maze now: +%d%% Dew a {drift}. With this: +%d%%." % [roundi(base * 100.0), roundi(base * WINDING_PATH_MULTIPLIER * 100.0)]
		&"front_line":
			return "Gauntlet path on your route now: %d steps." % gauntlet_count(dreams)
		&"press_on":
			return "Drifts called early so far: %d. The next leaf at %d." % [press_on_calls, (press_on_calls / PRESS_ON_EVERY + 1) * PRESS_ON_EVERY]
	return ""

# --- Wild Growth (Legendary; owner 2026-10-21, dream_council_review.md 28; legendaries_final.md 1.3) ----------------------
# Wardens grow for free from dispels: a Warden's count (by its cell, kept with the tier it was counted at, so it restarts
# after each growth) fills to WILD_NEEDS[tier]; then it is ripe and waits for the player to pick the form (the grow
# buttons, free; Dreamlight unlocks still apply; the rank difference is still charged). No Grow for Dew while it is held.
# A dispel counts for the Warden that landed it and at most WILD_HELPERS other Wardens with the dispel point in range,
# nearest first: any Warden but walls. Not Thornwalls, the Heartwood Sapling or Ascended forms (tier 3 and up never count).
const WILD_NEEDS: Array[int] = [20, 60, 150]  # Dispels from tier 0 (Sprout), 1 (family form), 2 (branch); starting points for Balancing
const WILD_HELPERS := 2
var wild := {}  # Cell key -> [count, tier it was counted at] (selling resets it; saved)

func _cell_key(tower: Tower) -> String:
	return "%d,%d" % [roundi(tower.cell.x * 2.0), roundi(tower.cell.y * 2.0)]

func wild_applies(tower) -> bool:
	return tower is Tower and is_instance_valid(tower) and tower.tower_data != null and tower.tower_data.line != "wall" \
		and not tower.tower_data.rooted and tower.tower_data.tier < WILD_NEEDS.size()

func wild_need(tower) -> int:
	return WILD_NEEDS[tower.tower_data.tier] if wild_applies(tower) else 0

func wild_of(tower) -> int:
	if not wild_applies(tower):
		return 0
	var entry: Array = wild.get(_cell_key(tower), [0, -1])
	return int(entry[0]) if int(entry[1]) == tower.tower_data.tier else 0

func wild_ripe(tower) -> bool:
	return wild_applies(tower) and wild_of(tower) >= wild_need(tower)

# A nightmare was dispelled at `at`; `killer` landed the blow (null: no Warden).
func wild_dispel(dreams: DreamState, killer, at: Vector2) -> void:
	var counted: Array = []
	if wild_applies(killer):
		counted.append(killer)
	var others: Array = []
	for tower in dreams.get_tree().get_nodes_in_group(Tower.GROUP):
		if tower != killer and wild_applies(tower) and tower.global_position.distance_to(at) <= tower.get_range_pixels():
			others.append(tower)
	others.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	counted.append_array(others.slice(0, WILD_HELPERS))
	for tower in counted:
		if wild_ripe(tower):
			continue  # Ripe: it waits for the player (no banking ahead)
		var count := wild_of(tower) + 1
		wild[_cell_key(tower)] = [count, tower.tower_data.tier]
		if count >= wild_need(tower):
			dreams.note_card(&"wild_growth", tower.global_position, 1, tower)
			var world: Node = Reactions._world(tower)
			if world != null:
				Fx.callout("Ready to grow!", Palette.NEWLEAF, tower.global_position + Vector2(0.0, -40.0), world, &"wild_ripe")

func wild_sold(tower: Tower) -> void:
	wild.erase(_cell_key(tower))

# The Walking Wood (Legendary): two Wardens swapped places (their old cells `a_cell`, `b_cell`); the counts kept by cell
# (Hard-Won Rings, Wild Growth) go with their Warden.
func swap_counts(a_cell: Vector2, b_cell: Vector2) -> void:
	var ka := "%d,%d" % [roundi(a_cell.x * 2.0), roundi(a_cell.y * 2.0)]
	var kb := "%d,%d" % [roundi(b_cell.x * 2.0), roundi(b_cell.y * 2.0)]
	for counts: Dictionary in [hard_won, wild]:
		var at_a = counts.get(ka)
		var at_b = counts.get(kb)
		counts.erase(ka)
		counts.erase(kb)
		if at_a != null:
			counts[kb] = at_a
		if at_b != null:
			counts[ka] = at_b
