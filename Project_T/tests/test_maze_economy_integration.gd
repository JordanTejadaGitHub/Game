extends SceneTree

var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	paused = false
	var director: Node = main.get_node("%DriftDirector")
	if not director.has_method("get_maze_reward_preview"):
		_check(false, "director exposes live maze reward")
		main.queue_free()
		await process_frame
		quit(failures)
		return
	var map = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var run: RunState = main.get_node("%RunState")
	run.dew = 100000
	var initial: int = map.route_length(map.get_path_from(map.startPath))
	var attacker: Tower = placer.tower_scene.instantiate()
	attacker.tower_data = load("res://resource/tower/sprout.tres").duplicate()
	attacker.tower_data.attack_range = 200.0
	attacker.cell = Vector2(4, 4)
	attacker.position = Tower.MAP_GRID.calculate_map_position(attacker.cell)
	main.get_node("%TowerContainer").add_child(attacker)
	attacker.set_process(false)
	_check(director.get_maze_reward_preview() == 0, "generated route coverage pays no expansion reward")
	# Drift one's next rest must project only its already sampled reward.
	director.maze_economy.sample(1, 1, map, [attacker])
	director.drifts_started = 1
	director.resting = false
	placer.select_tower(load("res://resource/tower/thornwall.tres"))
	for i in 12:
		var best := Vector2(-1, -1)
		var longest: int = map.route_length(map.get_path_from(map.startPath))
		for cell in Tower.route_cells(map.get_path_from(map.startPath)):
			if not map.is_buildable(cell) or placer._cells_occupied([cell]):
				continue
			var route: PackedVector2Array = map.get_path_if_blocked(cell)
			var length: int = map.route_length(route)
			if not route.is_empty() and length > longest:
				best = cell
				longest = length
		if best.x < 0:
			break
		placer._try_build(best)
	var extended: int = map.route_length(map.get_path_from(map.startPath))
	_check(extended - initial >= 4, "actual walls create enough route extension")
	var expected: int = director.get_maze_reward_preview()
	_check(expected > 0 and expected == (extended - initial) / 4, "the longer route has a live reward by length alone, with no cap")
	_check(director.get_maze_reward_projection() == 0, "active drift-one projection excludes future drift-five income")
	var hud = main.get_node("HUD")
	var forecast = hud.get_node_or_null("MazeDewLabel") as Label
	_check(forecast != null, "HUD has a top-right maze Dew forecast")
	if forecast != null:
		hud._update_maze_income()
		_check(forecast.text == "%s at rest" % UiStyle.dew_amount(0, true), "HUD uses next-rest projection rather than raw route reward")
		_check(main.get_node("%PathLabel").tooltip_text.contains("every 4 cells") and main.get_node("%PathLabel").tooltip_text.contains("longer than the forest's path") and not main.get_node("%PathLabel").tooltip_text.contains("up to 20"), "road tooltip explains the maze reward rate, with no cap")
	var reset: Dictionary = director.maze_economy.to_save()
	reset["blocks"] = {}
	director.maze_economy.load_save(reset)
	director.drifts_started = 4
	director.resting = false
	director._start_drift()
	director.set_process(false)
	if forecast != null:
		hud._update_maze_income()
		_check(forecast.text == "%s at rest" % UiStyle.dew_amount(expected, true), "forecast follows the next-rest reward")
	var before := run.dew
	var base: int = director.get_rest_bonus(1) + director.perfect_block_bonus
	director._pay_rest_bonus()
	_check(director.maze_reward_last == expected and run.dew - before == base + expected, "actual rest pays the separate maze bonus")
	director._pay_rest_bonus()
	_check(director.maze_reward_last == 0, "repeating rest cannot duplicate maze payment")
	var saved: Dictionary = director.maze_economy.to_save()
	director.maze_economy.load_save(saved)
	_check(director.maze_economy.claim(1) == 0, "saved ledger cannot repay a claimed reward")
	# Universal income cannot bypass Deep Sleep's forfeited rest reward.
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.stacks["deep_sleep"] = 1
	director.maze_economy.sample(6, 2, map, [attacker])
	director.drifts_started = 10
	before = run.dew
	director._pay_rest_bonus()
	_check(director.maze_reward_last == 0 and run.dew == before, "Deep Sleep forfeits universal maze income")
	dreams.stacks.erase("deep_sleep")
	_check(director.maze_economy.claim(2) == 0, "forfeited income cannot be reclaimed")
	main.queue_free()
	await process_frame
	print("maze economy integration: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
