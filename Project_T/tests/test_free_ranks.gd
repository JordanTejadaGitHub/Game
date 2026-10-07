extends SceneTree

# Headless test for free ranks through growth (story chat, the user: "should upgrading into a Sparkler be cheaper
# since I had the first one free with Sunlit Rest?"): a rank that cost nothing (Sunlit Rest, First Care, Ancient
# Stump…) charges no rank difference when the Warden grows; a bought one still does. Tower.paid_ranks, saved.
#   godot --headless --path . --script res://tests/test_free_ranks.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_free_ranks_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	main.get_node("%DreamState").unlock_everything = true
	var sparkler: TowerData = load("res://resource/tower/sparkler.tres")

	var gifted := _plant(placer, Vector2(4, 2))
	gifted.nurture(0)  # A free rank (Sunlit Rest / First Care / the stump: nothing invested)
	var grow := gifted.get_grow_cost(sparkler)
	_check(gifted.rank == 1 and gifted.free_rank_count() == 1, "(setup) one free rank")
	_check(int(grow.ranks) == 0 and int(grow.total) == int(grow.base), "a jar with one free rank grows for the base cost alone (%s)" % [grow])

	var bought := _plant(placer, Vector2(6, 2))
	bought.nurture(bought.get_nurture_price())  # A rank paid for
	var paid := bought.get_grow_cost(sparkler)
	_check(bought.paid_ranks == [1] and int(paid.ranks) > 0, "a bought rank still pays its difference (%d)" % int(paid.ranks))
	_check(int(paid.total) > int(grow.total), "…so it costs more than the gifted one (%d vs %d)" % [int(paid.total), int(grow.total)])

	# The save keeps it: a free rank stays free after Continue.
	gifted.bank_rank()  # A granted rank waiting (Sunlit Rest)
	_check(gifted.get_nurture_cost() == 0 and gifted.get_next_rank_growth_extra(sparkler) == 0, "a banked rank: free to spend, free through growth")
	var saver: RunSaver = main.get_node("%RunSaver")
	saver.file_path = "user://test_free_ranks_save_%d.json" % OS.get_process_id()
	_check(saver.save_now(), "(setup) the save writes")
	var rows: Array = saver._read().get("towers", [])
	var row := {}
	for r in rows:
		if Vector2(r.cell[0], r.cell[1]) == gifted.cell and Vector2(r.get("half", [-1, -1])[0], r.get("half", [-1, -1])[1]) == gifted.half_cell:
			row = r
	_check(row.has("paid_ranks") and Array(row.paid_ranks).is_empty(), "the save keeps which ranks were paid (%s)" % [row.get("paid_ranks")])
	_check(int(row.get("banked_ranks", -1)) == 1, "…and the banked ranks (%s)" % [row.get("banked_ranks")])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saver.file_path))

	print("free ranks test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _plant(placer: TowerPlacer, at: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/firefly_jar.tres")
	tower.cell = at
	tower.position = Tower.MAP_GRID.calculate_map_position(at)
	placer.tower_container.add_child(tower)
	tower.set_process(false)
	return tower

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
