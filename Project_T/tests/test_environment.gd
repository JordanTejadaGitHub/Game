extends SceneTree
# The environment art is wired in: every layer draws from EnvironmentTiles, clearing leaves a mark,
# the Heartwood shows leaves lost, and act breaks swap the season's sheets.
# Run:  Godot --headless --path . --script res://tests/test_environment.gd --fixed-fps 60
# Pass a path after `--` (e.g. `-- --preview=C:/tmp/map.png`) to also save a flat render of the map.

var failures := 0

func _init() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 1207
	root.add_child(main)
	await process_frame
	var map = main.get_node("%MapGenerator")
	var ground: TileMapLayer = main.get_node("%GroundTileMapLayer")
	var path: TileMapLayer = main.get_node("%PathTileMapLayer")
	var env: TileMapLayer = main.get_node("%EnvironmentObjectTileMapLayer")

	_check(ground.tile_set == map.tile_set and path.tile_set == map.tile_set and env.tile_set == map.tile_set,
		"all layers share the environment TileSet")
	_check(ground.get_cell_source_id(Vector2i(5, 5)) == EnvironmentTiles.GRASS, "ground is grass")
	_check(env.get_cell_source_id(Vector2i(0, 5)) == EnvironmentTiles.WALL, "border is the drystone wall")
	_check(env.get_cell_source_id(Vector2i(-1, 5)) in EnvironmentTiles.HEALTHY_TREES, "healthy trees outside the wall")
	_check(env.get_cell_source_id(Vector2i(map.startPath)) == EnvironmentTiles.EDGE_MIST, "mist on the start cell")
	for cell in path.get_used_cells():
		if path.get_cell_source_id(cell) != EnvironmentTiles.PATH:
			_check(false, "path cell %s uses the path sheet" % cell)
			break
	var start_mask: int = path.get_cell_atlas_coords(Vector2i(map.startPath)).x
	_check(start_mask & 1, "the start's path tile runs off the top edge (mask %d)" % start_mask)
	for cell in map.obstacles:
		var data: ObstacleData = map.obstacles[cell]
		if env.get_cell_source_id(Vector2i(cell)) != data.source_id:
			_check(false, "obstacle %s drawn from its sheet" % cell)
			break

	# Clearing leaves the obstacle's mark.
	for cell in map.obstacles.keys():
		var data: ObstacleData = map.obstacles[cell]
		if map.clear_obstacle(cell):
			_check(env.get_cell_source_id(Vector2i(cell)) == data.cleared_source_id,
				"clearing a %s leaves its mark" % data.display_name)
			break

	# The Heartwood blackens as leaves are lost.
	var heartwood: Heartwood = map.heartwood
	var run_state: RunState = main.get_node("%RunState")
	_check(heartwood.frame_coords.y == 0, "Heartwood starts whole")
	run_state.lose_leaves(run_state.max_leaves / 2)
	_check(heartwood.frame_coords.y == EnvironmentTiles.HEARTWOOD_STATES / 2,
		"half the leaves lost = half-blackened (row %d)" % heartwood.frame_coords.y)

	# Act breaks swap every sheet to the new season.
	main.get_node("Seasons").set_act(2, false)
	var grass_source := map.tile_set.get_source(EnvironmentTiles.GRASS) as TileSetAtlasSource
	_check(grass_source.texture.resource_path.contains("deep_wood"), "act 2 uses the Deep Wood sheets")
	_check(heartwood.texture.resource_path.contains("deep_wood"), "and the Heartwood follows")
	main.get_node("Seasons").set_act(1, false)

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="):
			_render(main, [ground, path, env], arg.trim_prefix("--preview="))

	print("test_environment: %d failure(s)" % failures)
	main.free()
	quit(failures)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

# Flat render of the map layers + the Heartwood (headless has no renderer): frame 0 of every tile.
func _render(main: Node, layers: Array, file: String) -> void:
	var size := Vector2i(main.get_node("%MapGenerator").MAP_GRID.size) + Vector2i(2, 2)
	var tile := EnvironmentTiles.SIZE
	var image := Image.create_empty(size.x * tile.x, size.y * tile.y, false, Image.FORMAT_RGBA8)
	var sheets := {}
	for layer: TileMapLayer in layers:
		for cell in layer.get_used_cells():
			var at := (cell + Vector2i.ONE) * tile
			if at.x < 0 or at.y < 0 or at.x >= image.get_width() or at.y >= image.get_height():
				continue
			var source := layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
			if not sheets.has(source):
				sheets[source] = source.texture.get_image()
				sheets[source].convert(Image.FORMAT_RGBA8)
			image.blend_rect(sheets[source], Rect2i(layer.get_cell_atlas_coords(cell) * tile, tile), at)
	var heartwood: Heartwood = main.get_node("%MapGenerator").heartwood
	var tree: Image = heartwood.texture.get_image()
	tree.convert(Image.FORMAT_RGBA8)
	var frame := Vector2i(EnvironmentTiles.HEARTWOOD_SIZE, EnvironmentTiles.HEARTWOOD_SIZE)
	var top_left := Vector2i(heartwood.position + heartwood.offset) - frame / 2 + tile
	image.blend_rect(tree, Rect2i(heartwood.frame_coords * frame, frame), top_left)
	image.save_png(file)
	print("preview saved to ", file)
