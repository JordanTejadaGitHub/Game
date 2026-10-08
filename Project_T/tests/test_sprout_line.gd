extends SceneTree

# The Sprout price counts paid Sprouts still on the map in any form (story chat; the user: "growing Sprouts shouldn't
# restart its interest cost"): growing one keeps its step, selling one (Sprout or grown) lowers it, and only when the
# count crosses a step. Seedling Gift Sprouts never count.
#   godot --headless --path . --script res://tests/test_sprout_line.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_sprout_line_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var map = main.get_node("%MapGenerator")
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = true
	main.get_node("%RunState").dew = 100000
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	var base := placer.get_cost(sprout)
	var per := placer.sprout_per_step()

	var planted: Array[Tower] = []
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			if planted.size() >= per:
				break
			var cell := Vector2(x, y)
			if not map.is_buildable(cell) or not map.can_block(cell):
				continue
			placer.tower_data = sprout
			if placer._try_build(cell):
				planted.append(_tower_at(placer, cell))
	_check(planted.size() == per, "%d Sprouts planted" % planted.size())
	var stepped := placer.get_cost(sprout)
	_check(stepped == base + placer.sprout_step_dew(), "%d Sprouts: the next costs a step more (%d → %d)" % [per, base, stepped])

	for tower in planted:
		placer.evolve(tower, sporeling)
	await process_frame
	_check(planted.all(func(t: Tower) -> bool: return t.tower_data == sporeling), "all %d grown into Sporelings" % per)
	_check(placer.count_paid_sprouts() == per, "grown, they still count (%d)" % placer.count_paid_sprouts())
	_check(placer.get_cost(sprout) == stepped, "growing doesn't reset the price (%d)" % placer.get_cost(sprout))

	# One more Sprout: still in the same step; selling a grown one doesn't cross back below it.
	var extra: Tower = null
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			var cell := Vector2(x, y)
			if extra == null and map.is_buildable(cell) and map.can_block(cell):
				placer.tower_data = sprout
				if placer._try_build(cell):
					extra = _tower_at(placer, cell)
	seller.sell_tower(planted[0])
	await process_frame
	_check(placer.count_paid_sprouts() == per and placer.get_cost(sprout) == stepped, "6 → 5: still a step up (%d)" % placer.get_cost(sprout))
	seller.sell_tower(planted[1])
	await process_frame
	_check(placer.get_cost(sprout) == base, "5 → 4 by selling a grown one: the step drops (%d)" % placer.get_cost(sprout))

	# The mark rides the run save.
	_check(bool(planted[2].get_meta(&"sprout_line", false)), "a grown Sprout carries the mark the run save keeps")
	print("sprout line test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _tower_at(placer: TowerPlacer, cell: Vector2) -> Tower:
	for tower in placer.tower_container.get_children():
		if tower is Tower and tower.cell == cell:
			return tower
	return null

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
