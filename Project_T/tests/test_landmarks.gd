extends SceneTree
# Map landmarks (environment_assets.md "Landmarks"; scripts/map/map_landmark.gd): about 1 map in 3, from the map seed;
# in the bowl, MIN_GAP cells from the start and the Heartwood, off the glade and the opening route's head; the Old
# Waystone is a buildable one-cell site, the Dew Pool 2 walkable cells nobody can build on; neither moves the route.
# Run:  Godot --headless --path . --script res://tests/test_landmarks.gd --fixed-fps 60

const LANDMARK := preload("res://scripts/map/map_landmark.gd")
const SEEDS := [1207, 1, 2, 3, 4, 6, 7, 8, 9, 10]

var failures := 0

func _init() -> void:
	for map_seed in SEEDS:
		var plain := await _route_with(map_seed, LANDMARK.Kind.NONE)
		for kind in [LANDMARK.Kind.WAYSTONE, LANDMARK.Kind.DEW_POOL]:
			var main := await _make(map_seed, kind)
			var map = main.get_node("%MapGenerator")
			var cells: Array[Vector2] = map.landmark_cells()
			if cells.is_empty():
				_check(false, "seed %d: no room for a %s" % [map_seed, LANDMARK.NAMES[kind]])
				main.free()
				continue
			_check(map.landmark_kind() == kind and cells.size() == (1 if kind == LANDMARK.Kind.WAYSTONE else 2),
				"seed %d: %s on %s" % [map_seed, LANDMARK.NAMES[kind], cells])
			for cell in cells:
				_check(map.environment_object_layer.in_bowl(cell), "seed %d: %s in the bowl" % [map_seed, cell])
				_check(not map.get_glade_cells().has(cell) and not map.obstacles.has(cell), "seed %d: open ground" % map_seed)
				for at: Vector2 in [map.startPath, map.endPath]:
					_check(maxf(absf(cell.x - at.x), absf(cell.y - at.y)) >= LANDMARK.MIN_GAP,
						"seed %d: %s keeps %d cells from %s" % [map_seed, cell, LANDMARK.MIN_GAP, at])
				_check(map.is_buildable(cell) == (kind == LANDMARK.Kind.WAYSTONE),
					"seed %d: the Waystone is built on, the Dew Pool never" % map_seed)
				_check(map.is_waystone(cell) == (kind == LANDMARK.Kind.WAYSTONE) and map.is_dew_pool(cell) == (kind == LANDMARK.Kind.DEW_POOL),
					"seed %d: is_waystone / is_dew_pool" % map_seed)
			_check(map.get_path_from(map.startPath) == plain, "seed %d: a %s never moves the route" % [map_seed, LANDMARK.NAMES[kind]])
			main.free()
	# The roll: about 1 map in 3 over 60 seeds, and the same seed always rolls the same.
	var rolled := 0
	for map_seed in range(100, 160):
		var main := await _make(map_seed, -1)
		var kind: int = main.get_node("%MapGenerator").landmark_kind()
		rolled += 1 if kind != LANDMARK.Kind.NONE else 0
		main.free()
		if map_seed < 104:
			var again := await _make(map_seed, -1)
			_check(again.get_node("%MapGenerator").landmark_kind() == kind, "seed %d rolls the same landmark again" % map_seed)
			again.free()
	print("landmarks on %d of 60 maps" % rolled)
	_check(rolled >= 10 and rolled <= 32, "about 1 map in 3 has a landmark (%d of 60)" % rolled)
	print("test_landmarks: %d failure(s)" % failures)
	quit(failures)

func _make(map_seed: int, kind: int) -> Node:
	LANDMARK.force_kind = kind
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = map_seed
	root.add_child(main)
	await process_frame
	LANDMARK.force_kind = -1
	return main

func _route_with(map_seed: int, kind: int) -> PackedVector2Array:
	var main := await _make(map_seed, kind)
	var map = main.get_node("%MapGenerator")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	main.free()
	return route

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
