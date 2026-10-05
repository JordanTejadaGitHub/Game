extends SceneTree

# Balance probe (not a test; balance_simulation.md fd7e1b0e "Twig Walls"): static, no drifts. On each map the wall
# planner spends the same wall budget twice: as Thornwalls (2×2 halves) and as twig walls (one half each, 4× the
# count, TowerPlacer.force_twig, placed as straight bars: _plant_bar). Reports the route length (full cells) each way.
#   godot --headless --path . --script res://tools/balance_twig_route.gd -- [--maps=20] [--budgets=10,20,30] [--out=<file.csv>]
#
# The planner is the sim bot's half-grid wall search (balance_sim.gd _plant_half_wall): every origin within 3 halves
# of the route, the one adding the most route; the PAIR_FIRSTS best singles also try a second wall within PAIR_REACH
# halves, and the first of a better pair is built. Walls only; Dew is unlimited.

const PAIR_FIRSTS := 40
const PAIR_REACH := 2

var maps := 20
var budgets: Array[int] = [10, 20, 30]
var out_path := ""
var main: Node
var map
var placer: TowerPlacer

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		match arg.get_slice("=", 0):
			"--maps": maps = int(value)
			"--budgets": budgets.assign(Array(value.split(",")).map(func(v) -> int: return int(v)))
			"--out": out_path = value
	ProjectSettings.set_setting("game/demo", false)
	var rows: Array[String] = ["seed,budget,mode,walls,route_base,route"]
	for seed in range(1, maps + 1):
		for budget in budgets:
			for twig in [false, true]:
				await _open(seed)
				var base: int = map.route_length(map.get_path_from(map.startPath))
				placer.force_twig = twig
				var count: int = budget * 4 if twig else budget
				var built := 0
				while built < count:
					var placed := _plant_bar(count - built) if twig else (1 if _plant_wall() else 0)
					if placed == 0:
						break
					built += placed
				var route: int = map.route_length(map.get_path_from(map.startPath))
				var row := "%d,%d,%s,%d,%d,%d" % [seed, budget, "twig" if twig else "thornwall", built, base, route]
				rows.append(row)
				print("ROUTE " + row)
				await _close()
	if out_path != "":
		var file := FileAccess.open(out_path, FileAccess.WRITE)
		file.store_string("\n".join(rows) + "\n")
	quit(0)

func _open(seed: int) -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = seed
	root.add_child(main)
	await process_frame
	map = main.get_node("%MapGenerator")
	placer = main.get_node("%TowerPlacer")
	main.get_node("%RunState").dew = 100000000
	placer.tower_data = load("res://resource/tower/thornwall.tres")

func _close() -> void:
	main.queue_free()
	await process_frame
	await process_frame

# One wall: the origin (or the first of a pair) adding the most route. False when none adds any.
func _plant_wall() -> bool:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var origins := {}
	for point in route:
		for h in map.body_halves(point):
			for dy in range(-3, 3):
				for dx in range(-3, 3):
					origins[h + Vector2(dx, dy)] = true
	var best := Vector2(-1, -1)
	var best_growth := 0
	var singles: Array = []
	for origin in origins:
		var halves: Array[Vector2] = placer.origin_halves(origin)
		if not _open_halves(halves):
			continue
		var new_route: PackedVector2Array = map.get_path_if_blocked_halves(halves)
		if new_route.is_empty():
			continue
		var growth := new_route.size() - route.size()
		singles.append([growth, origin])
		if growth > best_growth and map.can_block_halves(halves):
			best_growth = growth
			best = origin
	singles.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var pair_first := Vector2(-1, -1)
	var pair_best := best_growth
	for entry in singles.slice(0, PAIR_FIRSTS):
		var first: Vector2 = entry[1]
		var first_halves: Array[Vector2] = placer.origin_halves(first)
		for dy in range(-PAIR_REACH - 1, PAIR_REACH + 2):
			for dx in range(-PAIR_REACH - 1, PAIR_REACH + 2):
				var second: Vector2 = first + Vector2(dx, dy)
				var second_halves: Array[Vector2] = placer.origin_halves(second)
				if second_halves.any(func(h: Vector2) -> bool: return first_halves.has(h)) or not _open_halves(second_halves):
					continue
				var both: Array = first_halves + second_halves
				var new_route: PackedVector2Array = map.get_path_if_blocked_halves(both)
				var growth := new_route.size() - route.size()
				if new_route.is_empty() or growth <= pair_best or not map.can_block_halves(both):
					continue
				pair_best = growth
				pair_first = first
	if pair_first != Vector2(-1, -1) and map.can_block_halves(placer.origin_halves(pair_first)):
		best = pair_first
	if best == Vector2(-1, -1):
		return false
	return placer._try_build_half(best)

# Twig walls: a lone half rarely diverts anyone (a nightmare fits through one half), so the planner places straight
# bars of BAR_LENGTHS halves (thin walls, at most a Thornwall's area each), the bar adding the most route per half.
# Returns the twigs placed (0 = no bar adds route). `left`: twigs still in the budget.
const BAR_LENGTHS := [4, 2]

func _plant_bar(left: int) -> int:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var starts := {}
	for point in route:
		for h in map.body_halves(point):
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					starts[h + Vector2(dx, dy)] = true
	var best: Array = []
	var best_rate := 0.0
	for start in starts:
		for length in BAR_LENGTHS:
			if length > left:
				continue
			for dir in [Vector2.RIGHT, Vector2.DOWN]:
				var bar: Array[Vector2] = []
				for i in length:
					bar.append(start + dir * i)
				if not _open_halves(bar):
					continue
				var new_route: PackedVector2Array = map.get_path_if_blocked_halves(bar)
				if new_route.is_empty():
					continue
				var rate: float = float(new_route.size() - route.size()) / length
				if rate > best_rate and map.can_block_halves(bar):
					best_rate = rate
					best = bar
	var placed := 0
	for h in best:
		if placer._try_build_half(h):
			placed += 1
	return placed

func _open_halves(halves: Array[Vector2]) -> bool:
	return halves.all(func(h: Vector2) -> bool: return map.is_buildable_half(h))
