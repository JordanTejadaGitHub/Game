extends RefCounted
# Guaranteed maze income: only added route length AND added defended cells qualify.
# The generated baseline is immutable, and coverage compares both routes against
# the same live attackers so natural terrain and overlapping ranges cannot farm Dew.
const CELLS_PER_DEW := 4
const BLOCK_CAP := 20
var _baseline := PackedVector2Array()
var _blocks: Dictionary = {}

func capture_baseline(map) -> void:
	if _baseline.is_empty() and map != null:
		_baseline = map.get_path_from(map.startPath).duplicate()

func preview(map, attackers: Array) -> int:
	if map == null or _baseline.is_empty():
		return 0
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var added_length := maxi(0, int(map.route_length(route)) - int(map.route_length(_baseline)))
	if added_length == 0:
		return 0
	var added_covered := maxi(0, _covered(map, route, attackers) - _covered(map, _baseline, attackers))
	return mini(BLOCK_CAP, floori(float(mini(added_length, added_covered)) / CELLS_PER_DEW))

func _covered(map, route: PackedVector2Array, attackers: Array) -> int:
	var cells: Dictionary = {}
	for point in route:
		var cell := Vector2(floorf(point.x + 0.5), floorf(point.y + 0.5))
		if cells.has(cell):
			continue
		cells[cell] = false
		var at: Vector2 = map.MAP_GRID.calculate_map_position(cell)
		for tower in attackers:
			if not is_instance_valid(tower) or tower.tower_data == null or not tower.tower_data.can_attack:
				continue
			if tower is Node and tower.is_queued_for_deletion():
				continue
			var in_range: bool = tower._is_cell_in_range(cell) if tower.has_method("_is_cell_in_range") else tower.global_position.distance_to(at) <= tower.get_range_pixels()
			if in_range:
				cells[cell] = true
				break
	var count := 0
	for covered in cells.values():
		if covered:
			count += 1
	return count

func sample(drift: int, block: int, map, attackers: Array) -> void:
	if drift < 1 or block < 1:
		return
	var key := str(block)
	if not _blocks.has(key):
		_blocks[key] = {"samples": {}, "paid": 0}
	var samples: Dictionary = _blocks[key]["samples"]
	if not samples.has(str(drift)):
		samples[str(drift)] = preview(map, attackers)

# Observe after path/defense mutations and before claiming. Removing then rebuilding
# a corridor cannot restore the higher reward of an already sampled drift.
func observe(map, attackers: Array) -> void:
	var current := preview(map, attackers)
	for row in _blocks.values():
		var samples: Dictionary = row["samples"]
		for drift in samples:
			samples[drift] = mini(int(samples[drift]), current)

# Quick rest after drift 1 and the ordinary block rest share one cap/ledger.
# Samples remain after payment, so subsequent claims pay only an earned top-up.
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
	var earned := mini(BLOCK_CAP, floori(float(total) / samples.size()))
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
	var rate := clampi(current, 0, BLOCK_CAP)
	var total := 0
	for drift in range(first, last + 1):
		total += mini(int(samples.get(str(drift), rate)), rate)
	var earned := mini(BLOCK_CAP, floori(float(total) / (last - first + 1)))
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
					samples[str(drift)] = clampi(int(saved_samples[drift]), 0, BLOCK_CAP)
		_blocks[str(block)] = {"samples": samples, "paid": clampi(int(row.get("paid", 0)), 0, BLOCK_CAP)}