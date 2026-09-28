extends SceneTree

# Headless test for the Omen hooks Tower Code reads (Roguelite Code's OmenDirector queries): Fog Bank
# (-1 range on every Warden, never below 1), Wilting (attack speed x0.85) and Frozen Ground (no planting,
# growing or nurturing during its drifts; rests are fine). Run:
#   godot --headless --path . --script res://tests/test_omen_hooks.gd --fixed-fps 60

const MAP_SEED := 42

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = MAP_SEED
	root.add_child(main)
	await process_frame
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var map = main.get_node("%MapGenerator")
	var run_state: RunState = main.get_node("%RunState")
	var by_id := {}
	for omen in omens.pool:
		by_id[omen.id] = omen
	run_state.dew = 100000
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	var tower := _build(placer, map, sprout)
	var cell := tower.cell
	var range_before := tower.get_range_cells()
	var speed_before := tower.get_attacks_per_second()

	director.drifts_started = 51
	omens.active_block = director.get_block(51)
	omens.active = by_id["fog_bank"]
	_check(is_equal_approx(tower.get_range_cells(), maxf(range_before - 1.0, 1.0)), "Fog Bank: -1 range (%.2f -> %.2f)" % [range_before, tower.get_range_cells()])
	omens.active = by_id["wilting"]
	_check(is_equal_approx(tower.get_attacks_per_second(), speed_before * 0.85), "Wilting: attack speed x0.85")
	_check(is_equal_approx(tower.get_range_cells(), range_before), "and range is back without Fog Bank")

	omens.active = by_id["frozen_ground"]
	director.resting = false
	_check(placer.frozen_ground(), "Frozen Ground is on during the drift")
	var count := placer.tower_container.get_child_count()
	placer.tower_data = sprout
	_check(_build(placer, map, sprout) == null and placer.tower_container.get_child_count() == count, "no planting")
	_check(not placer.nurture(tower), "no nurturing")
	var into: TowerData = null
	for form in sprout.evolves_to:
		into = form
		break
	main.get_node("%DreamState").unlock_everything = true
	_check(not placer.evolve(tower, into), "no growing")
	placer.set_build_mode(true)
	placer._hover_cell = cell + Vector2(0, 2)
	placer._refresh_hover()
	_check(not placer._hover_valid, "the ghost is refused")
	placer.begin_stroke(cell + Vector2(0, 2))
	_check(placer.get_stroke_plan().values().all(func(w: String) -> bool: return w.begins_with("Frozen Ground")), "a stroke plants nothing")
	placer.cancel_stroke()
	placer.set_build_mode(false)
	director.resting = true
	_check(not placer.frozen_ground() and placer.nurture(tower), "at the rest: fine again")

	print("omen hooks test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _build(placer: TowerPlacer, map, data: TowerData) -> Tower:
	var path: PackedVector2Array = map.get_path_from(map.startPath)
	var container: Node = placer.tower_container
	for i in range(6, path.size() - 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var c: Vector2 = path[i] + offset
			if path.has(c) or not map.can_block(c):
				continue
			placer.tower_data = data
			var n := container.get_child_count()
			if placer._try_build(c):
				var built: Tower = container.get_child(n)
				built.set_process(false)
				return built
			return null  # Refused (Frozen Ground): stop at the first valid cell
	return null
