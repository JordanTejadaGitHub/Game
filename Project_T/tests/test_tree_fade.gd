extends SceneTree
# Withered Trees fade their overhang (the top 64 rows, over the cell above) while a Warden, a nightmare, the
# hovered / selected cell or the build ghost is in that cell, and come back once it's clear (TallObstacleFade,
# story chat; the same rule as tall Wardens and the Heartwood's canopy).
# Run:  Godot --headless --path . --script res://tests/test_tree_fade.gd --fixed-fps 60

var failures := 0

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_tree_fade_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 1207
	root.add_child(main)
	await process_frame
	var map = main.get_node("%MapGenerator")
	var env: TileMapLayer = map.environment_object_layer
	var fade: TallObstacleFade = map.tree_fade
	_check(fade != null, "the map has a tree fade")

	var trees := env.get_used_cells_by_id(EnvironmentTiles.WITHERED_TREE)
	var source := map.tile_set.get_source(EnvironmentTiles.WITHERED_TREE) as TileSetAtlasSource
	_check(source.get_alternative_tiles_count(Vector2i(0, 0)) == EnvironmentTiles.FADE_STEPS + 1, "each tree has its fade steps")
	var last: ShaderMaterial = source.get_tile_data(Vector2i(0, 0), EnvironmentTiles.FADE_STEPS).material
	_check(last != null and is_equal_approx(float(last.get_shader_parameter(&"top_alpha")), EnvironmentTiles.FADE_ALPHA)
		and is_equal_approx(float(last.get_shader_parameter(&"top_share")), 0.5), "the last step: the top half at 45%")

	# Two trees with open ground above them.
	var open: Array[Vector2i] = []
	for tree in trees:
		var above := Vector2(tree + Vector2i.UP)
		if map.is_buildable(above) and not map.get_glade_cells().has(above) and not map.get_path_if_blocked(above).is_empty():
			open.append(tree)
	_check(open.size() >= 2, "trees with open ground above (%d)" % open.size())
	var tree := open[0]
	_check(env.get_cell_alternative_tile(tree) == 0, "a tree starts whole")

	# A Warden above: the tree fades; sold: it comes back.
	var warden: Tower = main.get_node("%TowerPlacer").tower_scene.instantiate()
	warden.tower_data = load("res://resource/tower/sprout.tres")
	warden.cell = Vector2(tree + Vector2i.UP)
	warden.position = map.MAP_GRID.calculate_map_position(warden.cell)
	main.get_node("%TowerContainer").add_child(warden)
	await _frames(20)
	_check(env.get_cell_alternative_tile(tree) == EnvironmentTiles.FADE_STEPS, "a Warden above: the overhang fades (%d)" % env.get_cell_alternative_tile(tree))
	var atlas_before := env.get_cell_atlas_coords(tree)
	_check(env.get_cell_source_id(tree) == EnvironmentTiles.WITHERED_TREE and atlas_before == env.get_cell_atlas_coords(tree), "still the same tree")
	warden.free()
	await _frames(20)
	_check(env.get_cell_alternative_tile(tree) == 0, "the Warden gone: the tree is whole again")

	# A nightmare above another tree.
	var other := open[1]
	var shade: Node2D = main.get_node("%EnemyContainer").spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	shade.set_physics_process(false)
	shade.set_process(false)
	shade.position = map.MAP_GRID.calculate_map_position(Vector2(other + Vector2i.UP))
	await _frames(20)
	_check(env.get_cell_alternative_tile(other) == EnvironmentTiles.FADE_STEPS, "a nightmare above: the overhang fades")
	shade.free()
	await _frames(20)
	_check(env.get_cell_alternative_tile(other) == 0, "the nightmare gone: whole again")

	# The hovered cell (the seller's) above a tree.
	var seller: TowerSeller = main.get_node("%TowerSeller")
	seller.set_process(false)  # Its own update would put the hover back under the (headless) mouse
	seller._hover_cell = Vector2(tree + Vector2i.UP)
	await _frames(20)
	_check(env.get_cell_alternative_tile(tree) == EnvironmentTiles.FADE_STEPS, "the hovered cell above: the overhang fades")
	seller._hover_cell = TowerSeller.NO_CELL
	await _frames(20)
	_check(env.get_cell_alternative_tile(tree) == 0, "hover gone: whole again")

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("test_tree_fade: %d failure(s)" % failures)
	quit(failures)

func _frames(n: int) -> void:
	for i in n:
		await process_frame
