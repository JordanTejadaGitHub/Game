extends SceneTree

# Headless test for "Sprouts get pricier as you plant" (warden_stats.md, card 69): every 5 Sprouts on
# the map add +3 Dew to the next one's price (10 for the first 5, 13 at 5-9, …); selling or growing one
# lowers it; Seedling Gift Sprouts are free and don't count; a drag stroke prices each Sprout after the
# ones before it; Seedfall starts at 6 and rises half as fast (+3 per 10). Run:
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

	var planted: Array = []
	for i in 5:
		_check(placer.get_cost(sprout) == 10, "Sprout %d costs 10 (%d)" % [i + 1, placer.get_cost(sprout)])
		planted.append(_build(placer, map, sprout))
	_check(planted.all(func(t) -> bool: return t != null and t.invested_dew == 10), "the first five paid 10 each")
	_check(placer.get_cost(sprout) == 13, "with 5 on the map the next costs 13 (%d)" % placer.get_cost(sprout))
	seller.sell(planted[4].cell)
	_check(placer.get_cost(sprout) == 10, "selling one lowers it")
	planted[3].evolve(sprout.evolves_to[0], 0)
	_check(placer.count_paid_sprouts() == 3 and placer.get_cost(sprout) == 10, "a Sprout that grows no longer counts")

	# Seedling Gift: a charge plants one free, and it doesn't raise the price
	run_state.add_sprout_charges(1)
	var gift := _build(placer, map, sprout)
	_check(gift.invested_dew == 0 and gift.get_meta(&"gift_sprout", false), "a gift Sprout is free")
	_check(placer.count_paid_sprouts() == 3, "and doesn't count toward the price")
	_build(placer, map, sprout)  # A fourth paid Sprout

	# A drag stroke: each Sprout priced after the ones before it (4 on the map: 10, then 13, 13)
	var cells := _row_of_three(map, placer)
	if cells.size() == 3:
		placer.set_build_mode(true)
		placer.select_tower(sprout)
		placer.begin_stroke(cells[0])
		placer.extend_stroke(cells[2])
		_check(placer.get_stroke_tag().contains("3 Sprouts · 36 Dew"), "a stroke of 3 costs 10 + 13 + 13 (%s)" % placer.get_stroke_tag())
		var dew := run_state.dew
		placer.plant_stroke()
		_check(dew - run_state.dew == 36, "and plants for exactly that (%d)" % (dew - run_state.dew))
		placer.set_build_mode(false)
	else:
		_check(false, "found 3 open cells in a row for the stroke")

	# Seedfall: starts at 6 and rises half as fast (+3 per 10 Sprouts on the map)
	for card in dreams.pool:
		if card.id == TowerPlacer.SEEDFALL_CARD:
			dreams.take(card)
	var paid := placer.count_paid_sprouts()  # 7 by now
	_check(placer.get_cost(sprout) == 6 + paid / 10 * 3, "Seedfall: Sprouts start at 6 (%d with %d)" % [placer.get_cost(sprout), paid])
	while placer.count_paid_sprouts() < 10:
		if _build(placer, map, sprout) == null:
			break
	_check(placer.count_paid_sprouts() < 10 or placer.get_cost(sprout) == 9, "and rise +3 at 10 Sprouts, half as fast (%d)" % placer.get_cost(sprout))

	print("sprout price test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

# Three open cells side by side, away from the route.
func _row_of_three(map, placer: TowerPlacer) -> Array:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x - 2:
			var row := [Vector2(x, y), Vector2(x + 1, y), Vector2(x + 2, y)]
			if row.all(func(c) -> bool: return map.can_block(c) and not route.has(c) and not placer._cells_occupied([c])) \
					and map.can_block_cells(row):
				return row
	return []

func _build(placer: TowerPlacer, map, data: TowerData) -> Tower:
	var path: PackedVector2Array = map.get_path_from(map.startPath)
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
