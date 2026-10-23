extends SceneTree

var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
# What the HUD's maze forecast may read now: "+N% a drift" (or "+N%" when the row is tight), "" at 0.
func _maze_forms(director) -> Array:
	var percent: int = director.get_maze_pot_percent()
	if percent <= 0:
		return [""]
	var short := UiStyle.DEW_GLYPH + "+%d%%" % percent
	return [short, "%s a drift" % short]
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
		# The maze grows every drift's Dew pot (maze_economy.md 8353f6cc, a419102b): "+N% a drift" by the Dew counter
		_check(forecast.text in _maze_forms(director), "the HUD shows the maze's share of the pot (%s)" % forecast.text)
		var road: String = main.get_node("%PathLabel").tooltip_text
		_check(road.contains("every %d cells" % DriftDirector.MAZE_ECONOMY.POT_CELLS_PER_PERCENT) and road.contains("longer than the starting path")
			and road.contains("up to +%d%%" % roundi(DriftDirector.MAZE_ECONOMY.POT_SHARE_CAP * 100.0)), "road tooltip explains the maze's pot share and its cap")
	var reset: Dictionary = director.maze_economy.to_save()
	reset["blocks"] = {}
	director.maze_economy.load_save(reset)
	director.drifts_started = 4
	director.resting = false
	director._start_drift()
	director.set_process(false)
	if forecast != null:
		hud._update_maze_income()
		_check(forecast.text in _maze_forms(director), "the forecast follows the route (%s)" % forecast.text)
	var before := run.dew
	# The flat block-rest maze payout is retired (2026-10-22, a419102b): the maze grows every drift's Dew pot instead.
	var paid: Array = director._pay_rest_bonus()
	_check(director.maze_reward_last == 0 and run.dew - before == int(paid[0]), "a rest pays no separate maze bonus any more (Dew +%d, paid %d)" % [run.dew - before, int(paid[0])])
	var share: float = director.get_maze_pot_share()
	_check(share > 0.0 and is_equal_approx(share, director.maze_economy.pot_share(map)), "the longer route earns a share of every pot (+%d%%)" % roundi(share * 100.0))
	# Deep Sleep forfeits the maze share too.
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.stacks["deep_sleep"] = 1
	dreams.bump_board()
	_check(director.get_maze_pot_share() == 0.0, "Deep Sleep forfeits the maze's pot share")
	dreams.stacks.erase("deep_sleep")
	dreams.bump_board()
	main.queue_free()
	await process_frame
	print("maze economy integration: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
