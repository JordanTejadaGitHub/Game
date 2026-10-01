extends SceneTree

# Performance stress test (platforms.md "Performance budget / Revised"): every buildable cell filled
# with Wardens (the path kept open; a mix with many Sprouts), 150 nightmares spread along the route,
# Dreams that watch the map (Root Network, Sprout Surge, Heart of the Maze, Solitude, Thinning the
# Herd). Measures each frame's process time (headless: scripts, not rendering) and fails if p95 at 1x
# is over the scripts' share of a 60 fps frame (the user's budget, 2026-09-29); 3x is a stretch goal to
# revisit before release, measured and printed, never a failure. Run:
#   godot --headless --path . --script res://tests/test_perf_stress.gd --fixed-fps 60 [-- --breakdown]
# --breakdown repeats the measurement with one system switched off at a time (a differential profile:
# how many ms each one costs).

const MAP_SEED := 42
const NIGHTMARES := 150
const SPEED := 1.0  # The budget's speed
const STRETCH_SPEED := 3.0  # The stretch goal (printed only)
const WARMUP := 60
const FRAMES := 300
const BUDGET_MS := 16.6  # 60 fps
const SCRIPT_SHARE := 0.6  # Scripts may use this much of the frame (rendering needs the rest)
# The test passes at p95 <= PASS_MS at 1x: the ~10 ms target plus noise headroom (the user accepted ~10 ms,
# 2026-09-29). The 10 ms target itself (and 3x) is revisited before release.
const PASS_MS := 14.0  # User decision 2026-09-30: 14 ms for now (main measured 12.4); 10 ms stays the release target
const CARDS := ["root_network", "seedfall", "heart_of_the_maze", "solitude", "thinning_the_herd"]
const MIX := ["sprout", "sprout", "sprout", "sporeling", "firefly_jar", "dewdrop", "pebbling", "acorn", "rootling"]
const SYSTEMS := ["SoundHooks", "Kinships", "DreamMarks", "EnvironmentLighting", "EnvironmentAmbience", "HUD",
	"CombatCallouts", "ResistPips", "NightmareInfo", "BuffOverlay"]

var failures := 0
var main: Node
var spawner
var container: Node
var map
var result := {}  # The last measurement (members, not return values: awaited helpers stay simple)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = MAP_SEED
	root.add_child(main)
	await process_frame
	map = main.get_node("%MapGenerator")
	spawner = main.get_node("%EnemyContainer")
	container = main.get_node("%TowerContainer")
	_fill_map()
	_spawn_spread()
	await process_frame
	Engine.time_scale = SPEED
	await _measure("everything on")
	var base: Dictionary = result.duplicate()
	var budget := PASS_MS
	_check(base.p95 <= budget, "p95 frame %.2f ms at 1x within %.1f ms (target %.1f, revisited before release)" % [base.p95, budget, BUDGET_MS * SCRIPT_SHARE])
	if OS.get_cmdline_user_args().has("--breakdown"):
		var towers: Array = container.get_children().filter(func(t) -> bool: return t is Tower)
		_set_process(towers, false)
		await _measure("without the Wardens' _process")
		_set_process(towers, true)
		print("    -> Wardens: %.2f ms" % (base.p50 - result.p50))
		_set_process(spawner.get_children(), false)
		await _measure("without the nightmares' _process")
		_set_process(spawner.get_children(), true)
		print("    -> nightmares: %.2f ms" % (base.p50 - result.p50))
		for node_name in SYSTEMS:
			var node := main.find_child(node_name, true, false)
			if node == null:
				continue
			var mode := node.process_mode
			node.process_mode = Node.PROCESS_MODE_DISABLED
			await _measure("without " + node_name)
			node.process_mode = mode
			print("    -> %s: %.2f ms" % [node_name, base.p50 - result.p50])
	Engine.time_scale = STRETCH_SPEED
	await _measure("stretch goal: 3x (not a failure)")
	print("    -> 3x p95 %.2f ms %s the %.1f ms budget (revisit before release)" % [result.p95,
		"within" if result.p95 <= BUDGET_MS * SCRIPT_SHARE else "over", BUDGET_MS * SCRIPT_SHARE])
	await _measure_stacked()
	Engine.time_scale = 1.0
	print("perf stress test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# Late drifts called early back to back (platforms.md "Calling drifts early stacks them", the field cap):
# the dummies leave, drifts 88, 89, 90 start half a second apart at 3× with real nightmares (Reactions
# on), and the frame is measured as the field fills to the cap. Reported, not a failure yet (it's over
# budget while Tower / Enemy cut the interaction costs; tools/perf/stacked_drifts.gd has the probe).
const STACKED_BAR_MS := 16.0
func _measure_stacked() -> void:
	for enemy in spawner.get_children():
		enemy.queue_free()
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	director.drifts_started = 87
	Engine.time_scale = STRETCH_SPEED
	for i in 3:
		director.start_next_drift()
		for f in 30:
			await process_frame
	await _measure("stacked drifts 88-90, 3x (not a failure yet)")
	print("    -> stacked p95 %.2f ms %s the %.1f ms bar (field cap %s)" % [result.p95,
		"within" if result.p95 <= STACKED_BAR_MS else "over", STACKED_BAR_MS, str(spawner.get("max_field"))])

func _fill_map() -> void:
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var dreams: DreamState = main.get_node("%DreamState")
	var run_state: RunState = main.get_node("%RunState")
	dreams.unlock_everything = true
	run_state.dew = 10000000
	run_state.invulnerable = true
	for card in dreams.pool:
		if CARDS.has(card.id):
			dreams.take(card)
	var planted := 0
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			var cell := Vector2(x, y)
			if not map.is_buildable(cell) or not map.can_block(cell):
				continue
			placer.tower_data = load("res://resource/tower/%s.tres" % MIX[planted % MIX.size()])
			if placer._try_build(cell):
				planted += 1
	print("  %d Wardens planted, route %d tiles" % [planted, map.get_path_from(map.startPath).size()])

# 150 tough nightmares spread evenly along the route (a busy field, not one clump at the start).
func _spawn_spread() -> void:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	for i in NIGHTMARES:
		spawner.spawn_enemy(shade, 200.0)
		var enemy = spawner.get_child(spawner.get_child_count() - 1)
		var at := int(float(i) / NIGHTMARES * (route.size() - 2))
		enemy.position = Tower.MAP_GRID.calculate_map_position(route[at])
		enemy._path_index = at + 1
		enemy.unkillable = true  # The Target Dummy flags: the field stays busy for every measurement
		enemy.loops_route = true

# Frame times (ms) over FRAMES frames after WARMUP, into `result`.
func _measure(label: String) -> void:
	for i in WARMUP:
		await process_frame
	var times: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in FRAMES:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
	times.sort()
	result = {"p50": times[int(times.size() * 0.5)], "p95": times[int(times.size() * 0.95)],
		"p99": times[int(times.size() * 0.99)]}
	print("  %-36s p50 %6.2f  p95 %6.2f  p99 %6.2f ms  (%d nightmares)" % [label, result.p50, result.p95,
		result.p99, spawner.get_enemies().size()])

func _set_process(nodes: Array, on: bool) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.set_process(on)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
