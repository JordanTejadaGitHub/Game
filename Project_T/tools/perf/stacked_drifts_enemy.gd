extends "res://tools/perf/stacked_drifts.gd"

# Perf probe (Enemy Code): the stacked-drifts scenario (drifts 88-90 called back to back at 3x), timing
# the nightmare side as the field fills: re-routing everyone, take_damage, EnemyStatuses.tick, the
# spawner's frame, plus how many hits / path changes / nodes there are per frame. Headless or windowed.

var _hits := 0
var _reroutes := 0

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = MAP_SEED
	root.add_child(main)
	await process_frame
	map = main.get_node("%MapGenerator")
	spawner = main.get_node("%EnemyContainer")
	container = main.get_node("%TowerContainer")
	_fill_map()
	map.path_changed.connect(func(_a = null, _b = null) -> void: _reroutes += 1)
	if DamageLog.instance != null:
		DamageLog.instance.damage_dealt.connect(func(_e) -> void: _hits += 1)
	var director: DriftDirector = main.get_node("%DriftDirector")
	director.drifts_started = 87
	Engine.time_scale = 3.0
	for i in 3:
		director.start_next_drift()
		for f in 30:
			await process_frame
	for window in 6:  # 6 windows of 150 frames as the field fills
		_hits = 0
		var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var t := Time.get_ticks_usec()
		var reroutes_before := _reroutes
		var log_before := 0
		for f in 150:
			await process_frame
		var frame_ms := (Time.get_ticks_usec() - t) / 150000.0
		print("  window %d: %.1f ms/frame, %d nightmares, %d nodes (+%d), %.1f damage events/frame, %d path changes" % [
			window, frame_ms, spawner.get_enemies().size(), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - nodes_before,
			_hits / 150.0, _reroutes - reroutes_before])
	_world_census()
	_time_parts()
	Engine.time_scale = 1.0
	quit(0)

func _log_count() -> int:
	var log := DamageLog.instance
	if log == null:
		return 0
	for name in ["total_events", "event_count", "_event_count"]:
		if name in log:
			return int(log.get(name))
	return 0

# What the map holds besides tiles: node counts per script / class, biggest first.
func _world_census() -> void:
	var counts := {}
	var stack: Array[Node] = [main]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var script: Script = node.get_script()
		var key: String = script.resource_path.get_file() if script != null and script.resource_path != "" else node.get_class()
		counts[key] = int(counts.get(key, 0)) + 1
		stack.append_array(node.get_children())
	var keys := counts.keys()
	keys.sort_custom(func(a, b) -> bool: return counts[a] > counts[b])
	print("  nodes by kind: " + ", ".join(keys.slice(0, 12).map(func(k) -> String: return "%s %d" % [k, counts[k]])))

func _time_parts() -> void:
	var enemies: Array = spawner.get_enemies()
	var n := enemies.size()
	for e in enemies:
		e.set_process(false)
	var t := Time.get_ticks_usec()
	for rep in 10:
		for e in enemies:
			e._process(0.05)  # One 3x frame
	print("  every nightmare's _process: %.2f ms per frame (%d)" % [(Time.get_ticks_usec() - t) / 10000.0, n])
	var by_kind := {}  # {name: [usec, count]}
	for rep in 10:
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var t0 := Time.get_ticks_usec()
			e._process(0.05)
			var key: String = e.enemy_data.display_name
			var row: Array = by_kind.get(key, [0, 0])
			row[0] += Time.get_ticks_usec() - t0
			row[1] += 1
			by_kind[key] = row
	var kinds := by_kind.keys()
	kinds.sort_custom(func(a, b) -> bool: return by_kind[a][0] > by_kind[b][0])
	for key in kinds.slice(0, 10):
		print("    %-20s %5.2f ms/frame total, %5.1f us each, %d out" % [key, by_kind[key][0] / 10000.0,
			float(by_kind[key][0]) / by_kind[key][1], by_kind[key][1] / 10])
	t = Time.get_ticks_usec()
	spawner._on_path_changed()
	print("  re-route everyone (path_changed): %.2f ms for %d" % [(Time.get_ticks_usec() - t) / 1000.0, n])
	t = Time.get_ticks_usec()
	for e in enemies:
		e.statuses.tick(0.0)
	print("  EnemyStatuses.tick, all: %.2f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
	t = Time.get_ticks_usec()
	spawner._process(1.0 / 60.0)
	print("  spawner _process: %.2f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
	var tower: Tower = null
	for child in container.get_children():
		if child is Tower and child.tower_data.can_attack:
			tower = child
			break
	t = Time.get_ticks_usec()
	for e in enemies:
		e.take_damage(1.0, "spore", false, false, tower, &"")
	print("  take_damage x%d (a Warden hit each): %.3f ms each" % [n, (Time.get_ticks_usec() - t) / 1000.0 / maxi(n, 1)])
	t = Time.get_ticks_usec()
	for e in enemies:
		if tower != null:
			tower.hit(e)
	print("  Tower.hit x%d (with statuses, Reactions): %.3f ms each" % [n, (Time.get_ticks_usec() - t) / 1000.0 / maxi(n, 1)])
