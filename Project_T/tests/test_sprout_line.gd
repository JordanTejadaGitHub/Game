extends SceneTree

# The Sprout price counts only paid Sprouts still standing as Sprouts (Balancing 2026-10-21, owner run 07:22): growing one
# into a Warden or selling it takes it off the count, and the price steps only when the count crosses a step. Seedling
# Gift Sprouts never count.
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
	_check(placer.count_paid_sprouts() == 0, "grown, they leave the count (%d)" % placer.count_paid_sprouts())
	_check(placer.get_cost(sprout) == base, "growing them brings the price back to base (%d)" % placer.get_cost(sprout))

	# One more Sprout counts; selling grown Wardens doesn't change the count.
	var extra: Tower = null
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			var cell := Vector2(x, y)
			if extra == null and map.is_buildable(cell) and map.can_block(cell):
				placer.tower_data = sprout
				if placer._try_build(cell):
					extra = _tower_at(placer, cell)
	_check(placer.count_paid_sprouts() == 1 and placer.get_cost(sprout) == base, "one standing Sprout: 1 counted, base price (%d)" % placer.get_cost(sprout))
	seller.sell_tower(planted[0])
	await process_frame
	_check(placer.count_paid_sprouts() == 1, "selling a grown Warden leaves the Sprout count alone (%d)" % placer.count_paid_sprouts())
	seller.sell_tower(extra)
	await process_frame
	_check(placer.count_paid_sprouts() == 0 and placer.get_cost(sprout) == base, "selling the Sprout takes it off (%d)" % placer.count_paid_sprouts())

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
