extends SceneTree

# Headless test for Twig Walls (Dream card, dream_design.md c6fefe1b; Tower Code's side): while it's held a Thornwall
# planted takes the single half cell under the cursor and costs half (rounded up, at least 1); other Wardens are
# unaffected; it sells and saves as a one-half wall; walls planted before stay 2×2; a twig wall never grows (a Bramble
# needs a full footprint). TowerPlacer.force_twig stands in for the card. Run from the project folder:
#   godot --headless --path . --script res://tests/test_twig_walls.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	RunSaver.file_path = "user://test_twig_run_%d.json" % OS.get_process_id()
	HeartwoodMemory.file_path = "user://test_twig_heartwood_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var map: Node = main.get_node("%MapGenerator")
	var dreams: DreamState = main.get_node("%DreamState")
	var run_state: RunState = main.get_node("%RunState")
	dreams.unlock_everything = true
	run_state.add_dew(5000)
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")

	# A full wall before the card: 2×2.
	placer.select_tower(wall)
	var big_origin := _free_origin(map, 2)
	_check(placer._try_build_half(big_origin), "a Thornwall plants before the card")
	var big: Tower = _tower_with_half(placer, big_origin)
	_check(big != null and not big.twig and big.get_halves().size() == 4, "and takes 2×2 halves")
	var full_price := placer.get_cost(wall)

	# The card: one half, half the price.
	placer.force_twig = true
	_check(placer.twig_mode() and not placer.twig_mode(sprout), "twig mode is for Thornwalls only")
	_check(placer.get_cost(wall) == maxi(ceili(full_price / 2.0), 1), "half price, rounded up (%d of %d)" % [placer.get_cost(wall), full_price])
	_check(placer.origin_at(Vector2(5 * 64 + 40, 6 * 64 + 10)) == Vector2(11, 12), "the ghost snaps to the half under the cursor")
	var origin := _free_origin(map, 2)  # A free 2×2: the halves beside it are open ground
	var dew := run_state.dew
	_check(placer._try_build_half(origin), "a twig wall plants")
	var twig: Tower = _tower_with_half(placer, origin)
	_check(twig != null and twig.twig and twig.get_halves() == [origin], "it takes the one half (%s)" % [twig.get_halves() if twig else []])
	if twig == null:
		_finish(main)
		return
	_check(dew - run_state.dew == placer.get_cost(wall) and twig.invested_dew == dew - run_state.dew, "it pays half and counts it as invested")
	_check(not map.is_buildable_half(origin), "its half is blocked")
	for n in [origin + Vector2.RIGHT, origin + Vector2.DOWN]:
		_check(map.is_buildable_half(n) or _taken(placer, n), "the half beside it stays open (%s)" % n)
	_check(twig.position.is_equal_approx(Tower.twig_centre(origin)), "it sits in its half (%s)" % twig.position)
	_check(twig.sprite.texture != null and twig.sprite.texture.resource_path == Tower.TWIG_TEXTURE and twig.sprite.scale == Vector2.ONE, "drawn with its own 32 px art")
	_check(seller.get_tower_at_point(twig.position) == twig, "clicking it picks it")
	_check(not placer.evolve(twig, load("res://resource/tower/bramble.tres")), "a twig wall can't grow into a Bramble")
	_check(not big.twig, "walls planted before the card stay 2×2")

	# The save keeps which walls are twigs.
	var saver: RunSaver = main.get_node("%RunSaver")
	saver.save_now()
	var saved: Dictionary = saver._read()
	var rows: Array = saved.get("towers", []).filter(func(t) -> bool: return Vector2(t.half[0], t.half[1]) == origin)
	_check(not rows.is_empty() and bool(rows[0].get("twig", false)), "the save marks the twig wall")
	var big_rows: Array = saved.get("towers", []).filter(func(t) -> bool: return Vector2(t.half[0], t.half[1]) == big_origin)
	_check(not big_rows.is_empty() and not bool(big_rows[0].get("twig", true)), "and not the full wall")
	RunSaver.delete_save()

	# A drag stroke of twig walls steps one half at a time.
	var start := _free_origin(map, 1, 3)
	if start.x >= 0:
		placer.set_build_mode(true)
		placer.select_tower(wall)
		placer.begin_stroke_half(start)
		placer.extend_stroke(start + Vector2(2, 0))
		_check(placer.get_stroke_cells() == [start, start + Vector2(1, 0), start + Vector2(2, 0)], "a stroke steps one half (%s)" % [placer.get_stroke_cells()])
		placer.cancel_stroke()
		placer.set_build_mode(false)

	_check(seller.sell(twig.cell), "it sells")
	await process_frame
	_check(map.is_buildable_half(origin), "selling opens its half")
	placer.force_twig = false
	_finish(main)

func _finish(main: Node) -> void:
	print("twig walls test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _tower_with_half(placer: TowerPlacer, origin: Vector2) -> Tower:
	for t in placer.tower_container.get_children():
		if t is Tower and not t.is_queued_for_deletion() and t.half_cell == origin:
			return t
	return null

func _taken(placer: TowerPlacer, half: Vector2) -> bool:
	for t in placer.tower_container.get_children():
		if t is Tower and t.get_halves().has(half):
			return true
	return false

# A free origin away from the route: `size` halves square (2 = a 2×2), `run` of them side by side (one half apart).
func _free_origin(map: Node, size: int, run: int = 1) -> Vector2:
	var route_halves := {}
	for p in map.get_path_from(map.startPath):
		for h in map.body_halves(p):
			route_halves[h] = true
	for y in range(4, 32):
		for x in range(4, 40):
			var ok := true
			for dy in size:
				for dx in size + run - 1:
					var h := Vector2(x + dx, y + dy)
					if not map.is_buildable_half(h) or route_halves.has(h):
						ok = false
			if ok:
				return Vector2(x, y)
	return Vector2(-1, -1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
