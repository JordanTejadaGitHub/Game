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
	_check(rules.preview(map, attackers) == 2, "eight added defended cells earn two Dew")
	_check(rules.preview(map, []) == 0, "empty long corridors earn nothing")
	tower.tower_data.can_attack = false
	_check(rules.preview(map, attackers) == 0, "support walls do not qualify as attackers")
	tower.tower_data.can_attack = true
	tower.reach = 64.0
	_check(rules.preview(map, attackers) == 0, "covering only the original route earns nothing")
	tower.global_position = Vector2(640, 0)
	tower.reach = 128.0
	_check(rules.preview(map, attackers) == 1, "partial extension coverage earns proportionate reward")
	tower.reach = 100000.0
	_check(rules.preview(map, [tower, tower]) == 2, "overlapping attacker ranges count each cell once")
	map.route = _route(105)
	_check(rules.preview(map, attackers) == 20, "reward caps at twenty Dew")
	rules.sample(1, 1, map, attackers)
	_check(rules.claim(1) == 20 and rules.claim(1) == 0, "quick rest pays once")
	rules.sample(2, 1, map, attackers)
	_check(rules.claim(1) == 0, "quick rest and normal rest share block cap")
	rules.sample(6, 2, map, attackers)
	_check(rules.claim(2) == 20, "new block has independent allowance")
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
	shrink.observe(map, attackers)
	_check(shrink.claim(1) == 0, "removing then restoring defense cannot resurrect sampled reward")
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
	_check(rules.preview(map, attackers) == 0, "dead zones inside minimum attack range do not earn income")
	tower.minimum = 0.0
	var forecast = script.new()
	_check(forecast.projected(1, 1, 20) == 20, "opening quick-rest projection uses its one drift")
	_check(forecast.projected(2, 6, 7, 3) == 7, "projection supports configurable block length")
	_check(forecast.projected(2, 10, 7) == 7, "later block projection fills its five missing drifts")
	map.route = _route(5)
	forecast.capture_baseline(map)
	map.route = _route(105)
	forecast.sample(1, 1, map, attackers)
	_check(forecast.claim(1) == 20, "forecast fixture quick rest claims full allowance")
	_check(forecast.projected(1, 5, 20) == 0, "quick-rest payment removes projected ordinary rest income")
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