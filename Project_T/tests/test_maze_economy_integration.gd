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
	# The maze bonus is paid at block rests only (maze_economy.md 2026-10-12): the forecast is the block's rest from the
	# first drift on, and the short rest after drift 1 pays none of it.
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
	_check(expected > 0 and expected == (extended - initial) / 3, "the longer route has a live reward by length alone, with no cap")
	# Drift 1 was sampled before the walls went up (0), the other four drifts count at today's rate.
	var block_forecast: int = floori(expected * 4.0 / 5.0)
	_check(director.get_maze_reward_projection() == block_forecast, "during drift one the forecast is already the block rest's (%d, expected %d)" % [director.get_maze_reward_projection(), block_forecast])
	var dew_before_one: int = run.dew
	var paid_one: Array = director._pay_rest_bonus()  # The short rest after drift 1
	_check(director.maze_reward_last == 0 and run.dew - dew_before_one == int(paid_one[0]) and int(director.maze_economy.to_save().blocks["1"].paid) == 0,
		"the rest after drift 1 pays no maze bonus: the block's amount is still unclaimed")
	var hud = main.get_node("HUD")
	var forecast = hud.get_node_or_null("MazeDewLabel") as Label
	_check(forecast != null, "HUD has a top-right maze Dew forecast")
	if forecast != null:
		hud._update_maze_income()
		_check(forecast.text == "%s at rest" % UiStyle.dew_amount(director.get_maze_reward_projection(), true), "the HUD shows the block rest's forecast from the start")
		_check(main.get_node("%PathLabel").tooltip_text.contains("every %d cells" % DriftDirector.MAZE_ECONOMY.CELLS_PER_DEW) and main.get_node("%PathLabel").tooltip_text.contains("longer than the starting path") and not main.get_node("%PathLabel").tooltip_text.contains("up to 20"), "road tooltip explains the maze reward rate, with no cap")
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
	# The rest pays its whole bonus at once (DriftDirector computes the base: Dew x2 pass and Dream multipliers); the maze part
	# is what this checks, and that it is included in what was paid.
	var paid: Array = director._pay_rest_bonus()
	_check(director.maze_reward_last == expected and run.dew - before == int(paid[0]) and int(paid[0]) >= expected, "actual rest pays the separate maze bonus (maze %d of %d expected, Dew +%d, paid %d)" % [director.maze_reward_last, expected, run.dew - before, int(paid[0])])
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
