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
	root.add_child(main)
	await process_frame
	var spawner = main.get_node("%EnemyContainer")
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.take(load("res://resource/dream/rooted_nightmares.tres"))
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = Tower.MAP_GRID.calculate_map_position(Vector2(6, 6))
	enemy.apply_status(EnemyStatuses.HELD, 1, 2.0)
	spawner._update_rooted_cells(dreams)
	_check(spawner._root_footprints == spawner._halves_under(enemy.get_route_point()), "footprint matches actual half-cell obstruction")
	enemy.statuses.tick(3.0)
	spawner._update_rooted_cells(dreams)
	_check(spawner._root_footprints.is_empty(), "footprint disappears when hold expires")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/samara.tres")
	tower.cell = Vector2(2, 2)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	var seed := SeedBoomerang.new(tower, Vector2(100, 100), Vector2.RIGHT, 128.0, 1.0)
	main.add_child(seed)
	seed.set_process(false)
	_check(seed._turn_cue == 0.0 and seed._signature_trail.is_empty(), "ordinary seed has no signature clutter")
	_check(seed._ricochet(), "turn succeeds with a target")
	_check(seed._turn_cue > 0.0 and is_zero_approx(seed._turn_in.dot(seed._turn_out)), "cue describes actual right-angle turn")
	_check(seed._points[-1].distance_to(seed._turn_corner) == 64.0, "feedback preserves half-length ricochet geometry")
	seed._process(0.1)
	_check(seed._turn_cue < 0.35 and seed._signature_trail.size() == 1, "cue expires while short trail tracks actual flight")
	main.queue_free()
	await process_frame
	print("signature geometry feedback: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(failures)
