extends SceneTree

# Headless test for "placed this rest = 100% refund" (run_design.md "Selling"): Dew spent on a Warden
# during the current rest (planting, growing, nurturing) comes back in full until Start; after it has
# stood through a drift the rest share (75%) applies, and during a drift half. Run:
#   godot --headless --path . --script res://tests/test_refund_rest.gd --fixed-fps 60

const MAP_SEED := 42

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = MAP_SEED
	root.add_child(main)
	await process_frame
	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")

	# --- Planted this rest: every Dew back ---
	var fresh := _build(placer, map_generator, sprout)
	_check(fresh.rest_dew == fresh.invested_dew and fresh.invested_dew > 0, "planting during a rest counts as placed this rest")
	_check(seller.get_refund(fresh) == fresh.invested_dew, "full refund (%d of %d)" % [seller.get_refund(fresh), fresh.invested_dew])
	_check(seller.is_placed_this_rest(fresh), "the Sell button says so")

	# --- A drift: it stands through it; then only the rest share, and half during the drift ---
	var old := _build(placer, map_generator, sprout)
	director.start_next_block()
	await process_frame
	_check(old.rest_dew == 0, "starting a drift ends 'placed this rest'")
	_check(seller.get_refund(old) == int(old.invested_dew * seller.drift_refund), "half during the drift")
	director.resting = true  # The next rest
	director.build_phase_changed.emit(true)
	_check(seller.get_refund(old) == int(old.invested_dew * seller.build_phase_refund), "75% at the next rest")
	_check(not seller.is_placed_this_rest(old), "no full-refund note for it")

	# --- Nurtured this rest: that rank's Dew comes back in full, the rest at 75% ---
	placer.run_state.dew = 10000
	var before := old.invested_dew
	_check(placer.nurture(old), "nurtured during the rest")
	var rank_cost := old.invested_dew - before
	_check(old.rest_dew == rank_cost, "only the rank counts as this rest's")
	_check(seller.get_refund(old) == rank_cost + int(before * seller.build_phase_refund),
		"refund = the rank in full + 75% of the rest (%d)" % seller.get_refund(old))

	print("refund rest test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _build(placer: TowerPlacer, map_generator, data: TowerData) -> Tower:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var container: Node = placer.tower_container
	placer.run_state.dew = 10000
	for i in range(6, path.size() - 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if path.has(cell) or not map_generator.can_block(cell):
				continue
			placer.tower_data = data
			var count := container.get_child_count()
			if placer._try_build(cell):
				var built: Tower = container.get_child(count)
				built.set_process(false)
				return built
	return null
