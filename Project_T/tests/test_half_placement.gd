extends SceneTree

# Headless test for half-cell placement (experiment, documentation/half_cells.md; Tower Code's side): the ghost snaps to
# the nearest half-cell offset; a Warden planted at a half offset blocks its 2×2 halves, sits between whole cells and
# keeps a full `cell` under its centre; clicking any part of it picks it; selling opens its halves; a drag stroke plants
# Wardens a Warden's width apart; the run save keeps the half origin. Run from the project folder:
#   godot --headless --path . --script res://tests/test_half_placement.gd --fixed-fps 60

const HALF := 32.0

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var map: Node = main.get_node("%MapGenerator")
	main.get_node("%RunState").add_dew(5000)
	placer.select_tower(load("res://resource/tower/sprout.tres"))
	_check(placer.half_placement(), "a 1-cell Warden places on half cells")

	# Snapping: a point a quarter-cell off snaps to the half offset nearest it.
	_check(TowerPlacer.half_origin_at(Vector2(5 * 64 + 32, 6 * 64 + 32)) == Vector2(10, 12), "centred on a cell: its own halves")
	_check(TowerPlacer.half_origin_at(Vector2(6 * 64, 6 * 64 + 32)) == Vector2(11, 12), "on a cell edge: the half offset")

	var origin := _free_origin(map, true)
	_check(origin != Vector2(-1, -1), "found a free half-offset spot")
	if origin == Vector2(-1, -1):
		_finish(main)
		return
	_check(placer._try_build_half(origin), "a Warden plants at a half offset")
	var tower: Tower = seller.get_tower_at(Tower.half_home_cell(origin))
	_check(tower != null and tower.half_cell == origin, "it remembers its half origin")
	if tower == null:
		_finish(main)
		return
	_check(tower.position.is_equal_approx(Tower.half_centre(origin)), "it sits between whole cells (%s)" % tower.position)
	_check(tower.get_halves().all(func(h: Vector2) -> bool: return not map.is_buildable_half(h)), "its 4 halves are blocked")
	for corner in [Vector2(-20, -20), Vector2(20, -20), Vector2(-20, 20), Vector2(20, 20)]:
		_check(seller.get_tower_at_point(tower.position + corner) == tower, "any part of it picks it (%s)" % corner)

	# The run save keeps the origin.
	var saver = main.get_node_or_null("%RunSaver")
	if saver and saver.has_method("to_save"):
		var data: Dictionary = saver.to_save()
		var saved: Array = data.towers.filter(func(t) -> bool: return Vector2(t.cell[0], t.cell[1]) == tower.cell)
		_check(not saved.is_empty() and Vector2(saved[0].half[0], saved[0].half[1]) == origin, "the save keeps the half origin")

	_check(seller.sell(tower.cell), "it sells")
	await process_frame
	_check(map.halves_of(origin).all(func(h: Vector2) -> bool: return map.is_buildable_half(h)), "selling opens its halves")

	# A drag stroke: Wardens a Warden's width apart.
	var start := _free_origin(map, false, 3)
	if start != Vector2(-1, -1):
		placer.set_build_mode(true)
		placer.begin_stroke(start)
		placer.extend_stroke(start + Vector2(4, 0))  # +4 halves = 3 Wardens, a Warden's width apart
		var origins: Array = placer.get_stroke_cells()
		_check(origins == [start, start + Vector2(2, 0), start + Vector2(4, 0)], "the stroke steps a Warden's width (%s)" % [origins])
		var planted := placer.plant_stroke()
		_check(planted >= 1, "the stroke plants (%d)" % planted)

	_finish(main)

func _finish(main: Node) -> void:
	print("half placement test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

# A half origin whose 2×2 is buildable and off the current route (`odd`: at a half offset), with `run` free spots
# in a row to the right (2 halves apart).
func _free_origin(map: Node, odd: bool, run: int = 1) -> Vector2:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var route_halves := {}
	for p in route:
		for h in map.body_halves(p):
			route_halves[h] = true
	for y in range(4, 32):
		for x in range(4, 40):
			var o := Vector2(x, y)
			if odd and int(x) % 2 == 0:
				continue
			var ok := true
			for i in run:
				for h in map.halves_of(o + Vector2(2 * i, 0)):
					if not map.is_buildable_half(h) or route_halves.has(h):
						ok = false
			if ok:
				return o
	return Vector2(-1, -1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
