extends SceneTree
var failures := 0
var main: Node
var dreams: DreamState
var placer: TowerPlacer
var spawner: Node
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	placer = main.get_node("%TowerPlacer")
	spawner = main.get_node("%EnemyContainer")
	dreams.unlock_everything = true
	for e in spawner.get_children(): e.queue_free()
	await process_frame
	if not ResourceLoader.exists("res://scripts/run/dream_growth_rules.gd"):
		_check(false, "growth cards implement rest, leak, wall and idle behavior")
		_finish()
		return
	var rules = load("res://scripts/run/dream_growth_rules.gd").new()
	_take("fresh_beginnings")
	var old := _plant("sporeling", Vector2(2, 2))
	var newest := _plant("sporeling", Vector2(4, 2))
	rules.planted(dreams, old)
	rules.planted(dreams, newest)
	rules.rest(dreams, [newest])
	_check(old.banked_ranks == 1 and newest.banked_ranks == 0, "Fresh Beginnings excludes Sunlit Rest recipients")
	rules.rest(dreams, [])
	_check(old.banked_ranks == 1, "Fresh Beginnings requires planting since the previous rest")
	var capped := _plant("sporeling", Vector2(6, 2))
	capped.rank = 4
	capped.banked_ranks = 1
	rules.planted(dreams, capped)
	rules.rest(dreams, [])
	_check(capped.banked_ranks == 1, "Fresh Beginnings counts banked ranks toward cap")
	_take("emergency_reserves")
	var dew: int = dreams.run_state.dew
	rules.actual_leak(dreams, 0)
	_check(dreams.run_state.dew == dew, "Emergency Reserves ignores prevented leaf loss")
	rules.actual_leak(dreams, 2)
	rules.actual_leak(dreams, 1)
	_check(dreams.run_state.dew == dew + 16, "Emergency Reserves pays once per block, not per leaf")
	var restored = load("res://scripts/run/dream_growth_rules.gd").new()
	restored.load_save(rules.to_save())
	restored.actual_leak(dreams, 1)
	_check(dreams.run_state.dew == dew + 16, "resuming cannot repeat the emergency payout")
	_take("hushed_hedge")
	var wall := _plant("thornwall", Vector2(8, 2))
	var e = _enemy()
	rules.wall(dreams, wall, e, 1)
	rules.wall(dreams, wall, e, 1)
	_check(e.statuses.stacks(EnemyStatuses.DROWSY) == 2, "Hushed Hedge only applies once per wall per drift")
	rules.wall(dreams, wall, e, 2)
	_check(e.statuses.stacks(EnemyStatuses.DROWSY) == 4, "Hushed Hedge resets each drift")
	_take("quiet_vigil")
	old.set_meta(&"unique_vigil_ready", true)
	rules.before_primary(old, e, false)
	_check(e.statuses.stacks(EnemyStatuses.MARKED) == 0, "Quiet Vigil ignores secondary effects")
	rules.before_primary(old, e, true)
	_check(e.statuses.stacks(EnemyStatuses.MARKED) == 3 and not e.statuses.is_exposed(), "Quiet Vigil builds three stacks without bypassing Exposed")
	rules.before_primary(old, e, true)
	_check(e.statuses.stacks(EnemyStatuses.MARKED) == 3, "Quiet Vigil consumes readiness only once")
	_finish()
func _take(id: String) -> void:
	var card := UpgradeData.new()
	card.id = id
	card.rule_id = StringName(id)
	card.kind = UpgradeData.Kind.RULE
	dreams.pool.append(card)
	dreams.take(card)
func _plant(id: String, cell: Vector2) -> Tower:
	var t: Tower = placer.tower_scene.instantiate()
	t.tower_data = load("res://resource/tower/%s.tres" % id)
	t.cell = cell
	t.position = Tower.MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(t)
	t.set_process(false)
	return t
func _enemy():
	var e = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	e.set_process(false)
	e.position = Vector2(1000, 1000)
	return e
func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _finish() -> void:
	print("Dream growth test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	quit(failures)