extends SceneTree

# Headless test for run_design.md's "Opening rule": with the starting Dew, 5 Sprouts placed beside
# the route (no family yet) dispel drift 1 without losing a leaf, and a reasonable all-Sprout layout,
# topped up with the Dew earned, holds drifts 2 and 3 too. Plays for real at 1× on a few fixed maps.
#   godot --headless --path . --script res://tests/test_opening.gd --fixed-fps 60

const SEEDS := [1207, 4242, 90210]
const OPENING_SPROUTS := 5

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for map_seed in SEEDS:
		await _play_opening(map_seed)
	print("opening test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _play_opening(map_seed: int) -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = map_seed
	root.add_child(main)
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var family = main.get_node("%FamilyPickScreen")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	placer.tower_data = sprout

	# Drift 1 is plain: ×1 health, no extra nightmares.
	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	_check(is_equal_approx(director.get_health_scale(shade, 1), 1.0) and director.get_extra_nightmares(1) == 1.0,
		"drift 1 has no health growth or extra nightmares")

	for i in OPENING_SPROUTS:
		_check(_plant_best(main, sprout), "map %d: Sprout %d planted beside the route" % [map_seed, i + 1])
	# Sprouts get pricier as you plant (+3 Dew per 5 on the map: the first five are 10 each).
	var opening_price := 0
	for i in OPENING_SPROUTS:
		opening_price += sprout.cost + i / TowerPlacer.SPROUTS_PER_STEP * TowerPlacer.SPROUT_STEP_DEW
	_check(run_state.dew == run_state.starting_dew - opening_price and opening_price <= run_state.starting_dew,
		"5 Sprouts fit the starting Dew (%d of %d)" % [opening_price, run_state.starting_dew])

	# Drift 1
	director.start_next_drift()
	for frame in 60 * 90:
		if director.awaiting_family_pick or run_state.leaves_lost > 0:
			break
		await process_frame
	_check(director.awaiting_family_pick, "map %d: drift 1 finishes" % map_seed)
	_check(run_state.leaves_lost == 0, "map %d: drift 1 with 5 Sprouts leaks nothing (%d lost)" % [map_seed, run_state.leaves_lost])

	# Drifts 2 and 3: pick a family (but keep planting Sprouts), spend the Dew as it comes.
	if director.awaiting_family_pick and not family.offer.is_empty():
		family.choose(family.offer[0])
	director.start_next_drift()
	for frame in 60 * 150:
		if director.drifts_cleared >= 3 or run_state.leaves_lost > 0 or run_state.is_over:
			break
		if run_state.dew >= sprout.cost and frame % 30 == 0:
			_plant_best(main, sprout)
		await process_frame
	_check(director.drifts_cleared >= 3, "map %d: drifts 2 and 3 finish (%d cleared)" % [map_seed, director.drifts_cleared])
	_check(run_state.leaves_lost == 0, "map %d: drifts 2–3 with Sprouts leak nothing (%d lost)" % [map_seed, run_state.leaves_lost])

	main.queue_free()
	await process_frame

# Plants a Sprout on the free cell beside the route that covers the most route tiles, like a player
# would. Returns whether one was planted.
func _plant_best(main: Node, data: TowerData) -> bool:
	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var path: PackedVector2Array = Tower.route_cells(map_generator.get_path_from(map_generator.startPath))  # Whole cells (half-cell routes)
	var reach := data.attack_range
	var candidates: Array = []
	var seen := {}
	for cell in path:
		for x in range(-2, 3):
			for y in range(-2, 3):
				var candidate: Vector2 = cell + Vector2(x, y)
				if seen.has(candidate) or path.has(candidate):
					continue
				seen[candidate] = true
				if not map_generator.can_block(candidate):
					continue
				var covered := 0
				for tile in path:
					if tile.distance_to(candidate) <= reach:
						covered += 1
				candidates.append([covered, candidate])
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	placer.tower_data = data
	for pick in candidates:
		if placer._try_build(pick[1]):
			return true
	return false

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
