extends "res://tests/test_perf_stress.gd"

# Perf probe (Main Merger): late drifts called early back to back (platforms.md, the field cap). Drift
# 88, 89, 90 started one after another at 3×, the stress map's Wardens (with Reactions), measured as
# the field fills. Windowed or headless. Never writes saves (main.tscn isn't the current scene).

func _run() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		DisplayServer.window_set_size(Vector2i(1920, 1080))
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = MAP_SEED
	root.add_child(main)
	await process_frame
	map = main.get_node("%MapGenerator")
	spawner = main.get_node("%EnemyContainer")
	container = main.get_node("%TowerContainer")
	_fill_map()
	var director: DriftDirector = main.get_node("%DriftDirector")
	director.drifts_started = 87  # Resting before drift 88 (the block 86–90)
	Engine.time_scale = 3.0
	for i in 3:
		print("  start drift %d: %s" % [director.drifts_started + 1, director.start_next_drift()])
		for f in 30:  # Called early: half a second (real) apart
			await process_frame
	var times: Array[float] = []
	var most := 0
	var last := Time.get_ticks_usec()
	for i in 900:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		most = maxi(most, spawner.get_enemies().size())
	times.sort()
	print("  stacked drifts 88-90 at 3x: p50 %.2f  p95 %.2f  p99 %.2f ms, most nightmares on the field %d" % [
		times[450], times[855], times[891], most])
	Engine.time_scale = 1.0
	quit(0)
