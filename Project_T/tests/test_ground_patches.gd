extends SceneTree
# Ground variation (environment_assets.md "Ground variation"; GroundPatches): 3-5 patches plus the glade ring,
# 15-25% of the ground, never touching each other or the start, every dual tile matching its corners, details
# following the patches, and the same patches again for the same seed (a resumed run rebuilds them).
# Run:  Godot --headless --path . --script res://tests/test_ground_patches.gd --fixed-fps 60

var failures := 0

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_ground_patches_%d.json" % OS.get_process_id()
	var coverages: Array[float] = []
	for seed_value in [1207, 1, 2, 3, 7, 10, 12, 24]:
		var main := await _make(seed_value)
		var map = main.get_node("%MapGenerator")
		var ground: GroundPatches = map.ground_patches
		var label := "seed %d" % seed_value
		var kinds: Array = ground.patches.map(func(p: Dictionary) -> int: return p.kind)
		var count := kinds.filter(func(k: int) -> bool: return k != GroundPatches.GLADE_RING).size()
		_check(count >= 3 and count <= 5, "%s: 3-5 patches (%d)" % [label, count])
		_check(kinds.count(GroundPatches.GLADE_RING) == 1 and kinds.count(GroundPatches.ACCENT) <= 1, "%s: one glade ring, at most one accent" % label)
		var ring: Array = ground.patches.filter(func(p: Dictionary) -> bool: return p.kind == GroundPatches.GLADE_RING)[0].cells
		_check(Array(map.get_glade_cells()).all(func(c: Vector2) -> bool: return ring.has(c)), "%s: the ring is under the glade" % label)
		coverages.append(ground.coverage())
		_check(ground.coverage() >= 0.13 and ground.coverage() <= 0.26, "%s: coverage %.0f%%" % [label, ground.coverage() * 100])
		_check(not ground.kind_at.has(map.startPath), "%s: never on the start" % label)
		var apart := true
		for cell: Vector2 in ground.kind_at:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var near: Vector2 = cell + Vector2(dx, dy)
					if ground.kind_at.has(near) and ground.patches.filter(func(p: Dictionary) -> bool: return p.cells.has(near))[0] \
							!= ground.patches.filter(func(p: Dictionary) -> bool: return p.cells.has(cell))[0]:
						apart = false
		_check(apart, "%s: patches never touch" % label)
		var masks_ok := true
		for at in ground.get_used_cells():
			var coords := ground.get_cell_atlas_coords(at)
			var want := ground.mask_at(at, coords.y)
			if want == 0 or (coords.x != want and not (want == 15 and coords.x >= 15)):
				masks_ok = false
		_check(masks_ok and ground.get_used_cells().size() > 0, "%s: every tile by its corners, row by kind" % label)
		var details_ok := true
		var env: TileMapLayer = map.environment_object_layer
		for cell: Vector2 in ground.kind_at:
			if env.get_cell_source_id(Vector2i(cell)) != EnvironmentTiles.GROUND_DETAILS:
				continue
			var column := env.get_cell_atlas_coords(Vector2i(cell)).x
			match ground.kind_of(cell):
				GroundPatches.FERN_BED:
					details_ok = details_ok and column % 4 == 1
				GroundPatches.WORN_EARTH:
					details_ok = details_ok and column % 4 == 2
		_check(details_ok, "%s: ferns in fern beds, pebbles on worn earth" % label)
		var kept: Dictionary = ground.kind_at.duplicate()
		main.free()
		var again := await _make(seed_value)
		_check(again.get_node("%MapGenerator").ground_patches.kind_at == kept, "%s: the same patches for the same seed" % label)
		again.free()
	var mean := 0.0
	for c in coverages:
		mean += c
	print("  ground patches: coverage %s (mean %.0f%%)" % [coverages.map(func(c: float) -> String: return "%.0f%%" % (c * 100)), mean / coverages.size() * 100])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("test_ground_patches: %d failure(s)" % failures)
	quit(failures)

func _make(seed_value: int) -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = seed_value
	root.add_child(main)
	await process_frame
	return main
