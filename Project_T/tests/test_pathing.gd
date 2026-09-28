extends SceneTree

# Headless re-routing test. Run from the project folder:
#   godot --headless --path . --script res://tests/test_pathing.gd --fixed-fps 60
#
# Blocking a cell on the route should only move the route locally when an equally short local
# detour exists (sticky tie-breaking), and routes must still always be the shortest possible.

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var blocks := 0
	var far := 0
	for map_seed in [1, 2, 3]:
		var main: Node = load("res://scenes/main.tscn").instantiate()
		main.get_node("%MapGenerator").map_seed = map_seed
		root.add_child(main)
		await process_frame
		var map = main.get_node("%MapGenerator")
		var finder: FindPath = map.path_layer._pathGenerator
		var old: PackedVector2Array = map.get_path_from(map.startPath)

		for i in range(2, old.size() - 2):
			var cell := old[i]
			if not map.is_buildable(cell):
				continue
			var sticky_path: PackedVector2Array = map.get_path_if_blocked(cell)
			# Same query without the preference: plain shortest path.
			finder.set_preferred_cells(PackedVector2Array())
			var plain_path: PackedVector2Array = map.get_path_if_blocked(cell)
			finder.set_preferred_cells(old)
			if sticky_path.is_empty():
				_check(plain_path.is_empty(), "seed %d %s: sticky finds a route when one exists" % [map_seed, cell])
				continue
			_check(sticky_path.size() == plain_path.size(),
				"seed %d %s: sticky route is still shortest (%d vs %d)" % [map_seed, cell, sticky_path.size(), plain_path.size()])
			blocks += 1
			if _drift(sticky_path, old) > 2:
				far += 1
		main.free()

	# Before sticky routes ~36% of blocks moved the route more than 2 cells away; after, ~11%.
	# What's left is genuine: the only equally short detour really is further away.
	var ratio := float(far) / blocks
	_check(ratio < 0.2, "most blocks re-route locally (%d of %d moved >2 cells away)" % [far, blocks])

	print("pathing test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# How far (in cells) `path` strays from `reference` at its furthest point.
func _drift(path: PackedVector2Array, reference: PackedVector2Array) -> int:
	var drift := 0
	for c in path:
		var nearest := 999
		for r in reference:
			nearest = mini(nearest, int(absf(c.x - r.x) + absf(c.y - r.y)))
		drift = maxi(drift, nearest)
	return drift

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
