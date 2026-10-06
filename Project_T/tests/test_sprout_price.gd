extends SceneTree

# Headless test for "Sprouts cost more, walls do the maze" (warden_stats.md): every 5 Sprouts on the map
# add +4 Dew to the next one's price (12 for the first 5, 16 at 5-9, …); selling or growing one lowers it;
# Seedling Gift Sprouts are free and don't count; a drag stroke prices each Sprout after the ones before it;
# Seedfall sets the start (its card) and the price rises +2 per 5. Run:
#   godot --headless --path . --script res://tests/test_sprout_price.gd --fixed-fps 60

const MAP_SEED := 42

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = MAP_SEED
	root.add_child(main)
	await process_frame
	var map = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var run_state: RunState = main.get_node("%RunState")
	var dreams: DreamState = main.get_node("%DreamState")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	dreams.unlock_everything = true
	run_state.dew = 10000
	# Sprouts are exempt from copies (+5% each, checked at the end): only the Sprout step prices them

	var planted: Array = []
	for i in 5:
		_check(placer.get_cost(sprout) == 12, "Sprout %d costs 12 (%d)" % [i + 1, placer.get_cost(sprout)])
		planted.append(_build(placer, map, sprout))
	_check(planted.all(func(t) -> bool: return t != null and t.invested_dew == 12), "the first five paid 12 each")
	_check(placer.get_cost(sprout) == 16, "with 5 on the map the next costs 16 (%d)" % placer.get_cost(sprout))
	seller.sell(planted[4].cell)
	_check(placer.get_cost(sprout) == 12, "selling one lowers it")
	planted[3].evolve(sprout.evolves_to[0], 0)
	_check(placer.count_paid_sprouts() == 3 and placer.get_cost(sprout) == 12, "a Sprout that grows no longer counts")

	# Seedling Gift: a charge plants one free, and it doesn't raise the price
	run_state.add_sprout_charges(1)
	var gift := _build(placer, map, sprout)
	_check(gift.invested_dew == 0 and gift.get_meta(&"gift_sprout", false), "a gift Sprout is free")
	_check(placer.count_paid_sprouts() == 3, "and doesn't count toward the price")
	_build(placer, map, sprout)  # A fourth paid Sprout

	# A drag stroke: each Sprout priced after the ones before it (4 on the map: 12, then 16, 16)
	var cells := _row_of_three(map, placer)
	if cells.size() == 3:
		placer.set_build_mode(true)
		placer.select_tower(sprout)
		placer.begin_stroke(cells[0])
		placer.extend_stroke(cells[2] * (2.0 if placer.half_placement() else 1.0))  # Strokes hold half origins (half cells)
		_check(placer.get_stroke_tag().contains("3 Sprouts · 44 Dew"), "a stroke of 3 costs 12 + 16 + 16 (%s)" % placer.get_stroke_tag())
		var dew := run_state.dew
		placer.plant_stroke()
		_check(dew - run_state.dew == 44, "and plants for exactly that (%d)" % (dew - run_state.dew))
		placer.set_build_mode(false)
	else:
		_check(false, "found 3 open cells in a row for the stroke")

	# Seedfall: its card sets the start, and the price rises +2 per 5 (half as fast)
	var start := 0
	for card in dreams.pool:
		if card.id == TowerPlacer.SEEDFALL_CARD:
			start = card.set_cost
			dreams.take(card)
	var per_step := TowerPlacer.SEEDFALL_SPROUTS_PER_STEP
	var paid := placer.count_paid_sprouts()  # 7 by now
	var expected := start + (paid / per_step * TowerPlacer.SEEDFALL_STEP_DEW if per_step > 0 else 0)
	_check(start > 0 and placer.get_cost(sprout) == expected, "Seedfall: Sprouts cost %d (%d with %d)" % [expected, placer.get_cost(sprout), paid])
	while placer.count_paid_sprouts() < 16:
		if _build(placer, map, sprout) == null:
			break
	paid = placer.count_paid_sprouts()
	expected = start + (paid / per_step * TowerPlacer.SEEDFALL_STEP_DEW if per_step > 0 else 0)
	_check(paid < 16 or placer.get_cost(sprout) == expected, "and %s with %d on the map (%d)" % [
		"never rise" if per_step == 0 else "rise +2 per %d" % per_step, paid, placer.get_cost(sprout)])

	# Copies (user via Balancing 2026-10-04): each planted Warden costs +5% per copy of its kind on the map;
	# walls and Sprouts are exempt, selling lowers it, a grown one counts under its new form.
	var step := placer.copy_cost_step
	_check(is_equal_approx(step, 0.08), "copies cost +8%% each (be7b5a94; %.2f)" % step)
	var spore: TowerData = load("res://resource/tower/sporeling.tres")
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	var base := dreams.get_build_cost(spore)
	var had := placer.count_copies(spore)  # The Sprout grown above became a Sporeling: it counts
	_check(had == 1, "a Sprout grown into a Sporeling counts as a Sporeling (%d)" % had)
	_check(placer.get_cost(spore) == roundi(base * (1.0 + step * had)), "the next Sporeling pays +8%% per copy (%d of base %d)" % [placer.get_cost(spore), base])
	var spores: Array = [_build(placer, map, spore), _build(placer, map, spore)]
	_check(spores.all(func(t) -> bool: return t != null), "two Sporelings planted")
	_check(spores[1].invested_dew == roundi(base * (1.0 + step * (had + 1))), "each paid after the ones before it (%d)" % spores[1].invested_dew)
	_check(placer.get_cost(spore) == roundi(base * (1.0 + step * (had + 2))), "the next costs more again (%d)" % placer.get_cost(spore))
	var wall_cost := placer.get_cost(wall)
	for i in 3:
		_build(placer, map, wall)
	_check(placer.get_cost(wall) == wall_cost, "Thornwalls never cost more for copies (%d)" % placer.get_cost(wall))
	seller.sell(spores[1].cell)
	_check(placer.get_cost(spore) == roundi(base * (1.0 + step * (had + 1))), "selling one lowers it (%d)" % placer.get_cost(spore))
	spores[0].evolve(spore.evolves_to[0], 0)
	_check(placer.get_cost(spore) == roundi(base * (1.0 + step * had)), "a grown one no longer counts as a Sporeling (%d)" % placer.get_cost(spore))

	# Sprout into a base (Balancing 2026-10-05): at least the base's planting price now minus what the Sprout cost,
	# so growing never undercuts planting the Nth copy; a gift Sprout pays the full price.
	for i in 6:
		_build(placer, map, spore)  # Several Sporelings: the copy step raises the planting price
	var bud := _build(placer, map, sprout)
	if bud != null:
		var plant_now := placer.get_cost(spore, bud.cell)
		var grow: Dictionary = bud.get_grow_cost(spore)
		var floor_price := maxi(dreams.get_evolve_cost(spore), plant_now - bud.plant_dew)
		_check(bud.plant_dew > 0 and grow.base == floor_price, "Sprout into Sporeling: max(%d, %d - %d) = %d (%s)" % [dreams.get_evolve_cost(spore), plant_now, bud.plant_dew, floor_price, grow])
		_check(grow.base + bud.plant_dew >= plant_now, "growing never undercuts planting (%d + %d >= %d)" % [grow.base, bud.plant_dew, plant_now])
		bud.plant_dew = 0  # As a gift Sprout
		_check(bud.get_grow_cost(spore).base == maxi(dreams.get_evolve_cost(spore), plant_now), "a free Sprout pays the full planting price")
	else:
		_check(false, "planted a Sprout to grow")

	print("sprout price test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

# Three open cells side by side, away from the route.
func _row_of_three(map, placer: TowerPlacer) -> Array:
	var route: PackedVector2Array = Tower.route_cells(map.get_path_from(map.startPath))  # Whole cells (half-cell routes)
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x - 2:
			var row := [Vector2(x, y), Vector2(x + 1, y), Vector2(x + 2, y)]
			if row.all(func(c) -> bool: return map.can_block(c) and not route.has(c) and not placer._cells_occupied([c])) \
					and map.can_block_cells(row):
				return row
	return []

func _build(placer: TowerPlacer, map, data: TowerData) -> Tower:
	var path: PackedVector2Array = Tower.route_cells(map.get_path_from(map.startPath))  # Whole cells (half-cell routes)
	var container: Node = placer.tower_container
	for i in range(6, path.size() - 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if path.has(cell) or not map.can_block(cell) or placer.settling_left([cell]) > 0.0:
				continue
			placer.tower_data = data
			var count := container.get_child_count()
			if placer._try_build(cell):
				var built: Tower = container.get_child(count)
				built.set_process(false)
				return built
	return null
