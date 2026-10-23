extends RefCounted
# Maze income, by path length only (maze_economy.md "Path length only", user 2026-10-11: "the maze bonus is
# confusing"): +1 Dew for every CELLS_PER_DEW cells the route is longer than the route the map generated (the
# baseline, saved with the run), with no upper limit (user 2026-10-12: the cap is gone; the map's size is the limit). Walls alone earn it: no "defended" test, no coverage or
# attacker comparison. The anti-farm guard stays: each drift snapshots the rate at its start and a shorter route
# (path_changed, and while nightmares walk) lowers the unpaid snapshots, so lengthening just before the rest or
# selling walls mid-block doesn't pay.
const CELLS_PER_DEW := 3  # Power budget (owner review 2026-10-16): was 2 (4 before the Dew x2 second pass, 2026-10-13)
# The maze grows the Dew pot (maze_economy.md 8353f6cc, user 2026-10-22; numbers balance_simulation.md "The maze grows
# the Dew pot: numbers"): every drift's pot, bosses' too, pays +POT_PERCENT for every POT_CELLS_PER_PERCENT added cells,
# up to POT_SHARE_CAP; Winding Path multiplies the share (DreamState.get_maze_multiplier), cap included. It replaces the
# flat block-rest payout above (DriftDirector no longer pays claim(); the ledger stays for old saves).
const POT_CELLS_PER_PERCENT := 2  # Balancing 2026-10-22: +1% per 2 added cells (kept, easy to read)
const POT_PERCENT := 0.01
const POT_SHARE_CAP := 0.20  # Balancing 2026-10-22: +20% at most (40 added cells; was +30%)

# The share of a drift's pot the route earns now (0.12 = +12%), x `multiplier` (Winding Path), cap included.
func pot_share(map, multiplier: float = 1.0) -> float:
	var share := floorf(float(added_cells(map)) / POT_CELLS_PER_PERCENT) * POT_PERCENT
	return minf(share, POT_SHARE_CAP) * multiplier
var _baseline := PackedVector2Array()
var _blocks: Dictionary = {}

func capture_baseline(map) -> void:
	if _baseline.is_empty() and map != null:
		_baseline = map.get_path_from(map.startPath).duplicate()

# Whole cells the route is longer than the generated one now (0 when it isn't).
func added_cells(map) -> int:
	if map == null or _baseline.is_empty():
		return 0
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	if map.has_method("has_waymark") and map.has_waymark():
		# Waymark (Legendary Dream; legfinal_td.md 2): the baseline is the stone's two-leg route on today's map with every
		# Warden's halves open, so the stone and the ground earn nothing, only the Wardens' maze; both counted in unique
		# cells, so a corridor walked out to the stone and back (or any cell walked twice) pays once.
		var base: PackedVector2Array = map.waymark_baseline_route()
		if base.is_empty():
			return 0
		return maxi(0, int(map.unique_route_length(route)) - int(map.unique_route_length(base)))
	return maxi(0, int(map.route_length(route)) - int(map.route_length(_baseline)))

# The Dew that route length earns now: +1 per CELLS_PER_DEW added cells, no upper limit. (`_unused`: callers used to pass
# the attacking Wardens for the old defended-cells rule; nothing reads it.)
func preview(map, _unused = null) -> int:
	return floori(float(added_cells(map)) / CELLS_PER_DEW)

func sample(drift: int, block: int, map, _unused = null) -> void:
	if drift < 1 or block < 1:
		return
	var key := str(block)
	if not _blocks.has(key):
		_blocks[key] = {"samples": {}, "paid": 0}
	var samples: Dictionary = _blocks[key]["samples"]
	if not samples.has(str(drift)):
		samples[str(drift)] = preview(map)

# Observe after path changes and before claiming. Shortening then rebuilding
# a corridor cannot restore the higher reward of an already sampled drift.
func observe(map, _unused = null) -> void:
	var current := preview(map)
	for row in _blocks.values():
		var samples: Dictionary = row["samples"]
		for drift in samples:
			samples[drift] = mini(int(samples[drift]), current)

# Quick rest after drift 1 and the ordinary block rest share one ledger: drift one pays what the route earned, and the
# block rest pays the block's amount minus what was already paid. Samples remain after payment (no double payment).
func claim(block: int) -> int:
	var key := str(block)
	if not _blocks.has(key):
		return 0
	var row: Dictionary = _blocks[key]
	var samples: Dictionary = row["samples"]
	if samples.is_empty():
		return 0
	var total := 0
	for amount in samples.values():
		total += int(amount)
	var earned := floori(float(total) / samples.size())
	var payout := maxi(0, earned - int(row["paid"]))
	row["paid"] = int(row["paid"]) + payout
	return payout

# Pure next-rest forecast. Existing samples cannot regain removed coverage; missing
# drifts are estimated at today's rate, then previously paid Dew is subtracted.
func projected(block: int, last_drift: int, current: int, block_size: int = 5) -> int:
	if block < 1 or block_size < 1:
		return 0
	var first := (block - 1) * block_size + 1
	var last := mini(last_drift, block * block_size)
	if last < first:
		return 0
	var row: Dictionary = _blocks.get(str(block), {})
	var samples: Dictionary = row.get("samples", {})
	var rate := maxi(current, 0)
	var total := 0
	for drift in range(first, last + 1):
		total += mini(int(samples.get(str(drift), rate)), rate)
	var earned := floori(float(total) / (last - first + 1))
	return maxi(0, earned - int(row.get("paid", 0)))

func to_save() -> Dictionary:
	var points: Array = []
	for point in _baseline:
		points.append([point.x, point.y])
	return {"baseline": points, "blocks": _blocks.duplicate(true)}

func load_save(data: Dictionary) -> void:
	# Old saves have no maze record: keep the generated map captured by the caller.
	if not data.has("baseline"):
		return
	var points := PackedVector2Array()
	for point in data.get("baseline", []):
		if point is Array and point.size() == 2:
			points.append(Vector2(float(point[0]), float(point[1])))
	if not points.is_empty():
		_baseline = points
	_blocks.clear()
	var saved = data.get("blocks", {})
	if not saved is Dictionary:
		return
	for block in saved:
		var row = saved[block]
		if not row is Dictionary or int(str(block)) < 1:
			continue
		var samples: Dictionary = {}
		var saved_samples = row.get("samples", {})
		if saved_samples is Dictionary:
			for drift in saved_samples:
				if int(str(drift)) > 0:
					samples[str(drift)] = maxi(int(saved_samples[drift]), 0)
		_blocks[str(block)] = {"samples": samples, "paid": maxi(int(row.get("paid", 0)), 0)}