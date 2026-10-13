extends SceneTree
var failures := 0
class FakeGrid:
	extends RefCounted
	func calculate_map_position(cell: Vector2) -> Vector2:
		return cell * 64.0
class FakeMap:
	extends RefCounted
	var startPath := Vector2.ZERO
	var MAP_GRID := FakeGrid.new()
	var route := PackedVector2Array()
	func get_path_from(_cell: Vector2) -> PackedVector2Array:
		return route
	func route_length(points: PackedVector2Array) -> int:
		return 0 if points.is_empty() else ceili((points.size() - 1) / 2.0) + 1
class FakeTower:
	extends RefCounted
	var tower_data := TowerData.new()
	var global_position := Vector2.ZERO
	var reach := 100000.0
	var minimum := 0.0
	func _init() -> void:
		tower_data.can_attack = true
	func get_range_pixels() -> float:
		return reach
	func _is_cell_in_range(cell: Vector2) -> bool:
		var distance := global_position.distance_to(cell * 64.0)
		return distance <= reach and distance >= minimum
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	if not ResourceLoader.exists("res://scripts/run/maze_economy.gd"):
		_check(false, "maze economy helper exists")
		_finish()
		return
	var script = load("res://scripts/run/maze_economy.gd")
	var rules = script.new()
	var map := FakeMap.new()
	map.route = _route(5)
	rules.capture_baseline(map)
	var tower := FakeTower.new()
	var attackers := [tower]
	_check(rules.preview(map, attackers) == 0, "original generated route earns no reward")
	map.route = _route(8)
	_check(rules.preview(map, attackers) == 0, "three added cells round down")
	map.route = _route(13)
	_check(rules.preview(map, attackers) == 2, "eight added cells earn two Dew")
	_check(rules.preview(map, []) == 2 and rules.preview(map) == 2 and rules.added_cells(map) == 8, "an empty wall detour earns the bonus: path length only (maze_economy.md, 2026-10-11)")
	tower.tower_data.can_attack = false
	_check(rules.preview(map, attackers) == 2, "Warden coverage no longer matters: non-attackers")
	tower.tower_data.can_attack = true
	tower.reach = 64.0
	_check(rules.preview(map, attackers) == 2, "Warden coverage no longer matters: short reach")
	tower.global_position = Vector2(640, 0)
	tower.reach = 128.0
	_check(rules.preview(map, attackers) == 2, "Warden coverage no longer matters: partial reach")
	tower.reach = 100000.0
	_check(rules.preview(map, [tower, tower]) == 2, "more Wardens change nothing")
	map.route = _route(125)
	_check(rules.preview(map, attackers) == 30 and rules.added_cells(map) == 120, "a 120-cell extension pays 30: no cap (user 2026-10-12)")
	rules.sample(1, 1, map, attackers)
	_check(rules.claim(1) == 30 and rules.claim(1) == 0, "the drift-one rest pays what the route earned, once")
	rules.sample(2, 1, map, attackers)
	_check(rules.claim(1) == 0, "the block rest pays the block's amount minus what drift one already paid")
	rules.sample(6, 2, map, attackers)
	_check(rules.claim(2) == 30, "a new block pays afresh")
	var guarded = script.new()
	map.route = _route(5)
	guarded.capture_baseline(map)
	map.route = _route(13)
	guarded.sample(1, 1, map, attackers)
	guarded.sample(1, 1, map, attackers)
	map.route = _route(21)
	guarded.sample(2, 1, map, attackers)
	_check(guarded.claim(1) == 3, "drift samples are idempotent and average once")
	var shrink = script.new()
	map.route = _route(5)
	shrink.capture_baseline(map)
	map.route = _route(21)
	shrink.sample(1, 1, map, attackers)
	shrink.observe(map, [])
	_check(shrink.projected(1, 1, shrink.preview(map)) == 4, "removing Wardens costs nothing: the route is as long")
	map.route = _route(5)  # The walls come down mid-drift…
	shrink.observe(map)
	map.route = _route(21)  # …and go back up before the rest
	shrink.observe(map)
	_check(shrink.claim(1) == 0, "shortening then rebuilding the route cannot resurrect a sampled reward")
	map.route = _route(21)
	shrink.sample(2, 1, map, attackers)
	map.route = _route(9)
	shrink.observe(map, attackers)
	_check(shrink.claim(1) == 0, "route shortening reduces unpaid block average")
	var restored = script.new()
	restored.load_save(JSON.parse_string(JSON.stringify(rules.to_save())))
	map.route = _route(13)
	_check(restored.preview(map, attackers) == 2, "JSON save preserves original route")
	_check(restored.claim(1) == 0 and restored.claim(2) == 0, "JSON save preserves claimed payouts")
	restored.load_save({})
	_check(restored.preview(map, attackers) == 2, "legacy save retains captured baseline")
	var midpoint = script.new()
	map.route = _route(5)
	midpoint.capture_baseline(map)
	map.route = _route(13)
	midpoint.sample(1, 1, map, attackers)
	_check(midpoint.claim(1) == 2, "small quick-rest reward is paid")
	map.route = _route(29)
	midpoint.sample(2, 1, map, attackers)
	var resumed = script.new()
	resumed.load_save(JSON.parse_string(JSON.stringify(midpoint.to_save())))
	_check(resumed.claim(1) == 2 and resumed.claim(1) == 0, "resuming midblock pays only the averaged top-up")
	var fractional = script.new()
	map.route = _route(5)
	for i in map.route.size():
		map.route[i] += Vector2(-0.25, -0.25)
	fractional.capture_baseline(map)
	map.route = _route(13)
	for i in map.route.size():
		map.route[i] += Vector2(-0.25, -0.25)
	_check(fractional.preview(map, attackers) == 2, "quarter-coordinate half-cell routes count full cells correctly")
	fractional.capture_baseline(map)
	_check(fractional.preview(map, attackers) == 2, "repeated capture cannot replace initial baseline")
	map.route = PackedVector2Array()
	_check(fractional.preview(map, attackers) == 0, "missing route never earns a reward")
	map.route = _route(13)
	tower.minimum = 1000000.0
	_check(rules.preview(map, attackers) == 2, "attack ranges and dead zones do not matter")
	tower.minimum = 0.0
	var forecast = script.new()
	_check(forecast.projected(1, 1, 20) == 20, "opening quick-rest projection uses its one drift")
	_check(forecast.projected(2, 6, 7, 3) == 7, "projection supports configurable block length")
	_check(forecast.projected(2, 10, 7) == 7, "later block projection fills its five missing drifts")
	map.route = _route(5)
	forecast.capture_baseline(map)
	map.route = _route(105)
	forecast.sample(1, 1, map, attackers)
	_check(forecast.claim(1) == 25, "forecast fixture: the quick rest claims all a 100-cell extension earned")
	_check(forecast.projected(1, 5, 25) == 0, "quick-rest payment removes projected ordinary rest income")
	var mixed = script.new()
	map.route = _route(5)
	mixed.capture_baseline(map)
	map.route = _route(13)
	mixed.sample(1, 1, map, attackers)
	_check(mixed.projected(1, 5, 6) == 5, "forecast averages existing sample with missing drift estimates")
	_check(mixed.projected(1, 5, 0) == 0, "forecast lowers banked samples at the current rate")
	_check(mixed.claim(1) == 2, "forecast does not mutate sample or paid ledger")
	_check(mixed.projected(1, 5, 6) == 3, "forecast subtracts the already paid quick-rest portion")
	_check(mixed.projected(0, 0, 20) == 0, "invalid block projection is zero")
	_finish()
func _route(cells: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	for step in range((cells - 1) * 2 + 1):
		result.append(Vector2(step * 0.5, 0))
	return result
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _finish() -> void:
	print("Maze economy: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures else 0)