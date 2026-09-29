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
	var size := Vector2i(map.MAP_GRID.size)
	_check(ground.get_cell_source_id(Vector2i(0, 5)) == -1, "no grass square under the island's rim")
	_check(env.get_cell_source_id(Vector2i(0, 5)) == EnvironmentTiles.ISLAND_EDGE
		and env.get_cell_atlas_coords(Vector2i(0, 5)).x == 1 | 2 | 4, "the left rim: island to the N, E and S")
	_check(env.get_cell_atlas_coords(Vector2i(0, 0)).x == 2 | 4, "the top-left corner: island to the E and S")
	var tree_sheet := map.tile_set.get_source(EnvironmentTiles.WITHERED_TREE) as TileSetAtlasSource
	_check(tree_sheet.texture_region_size == Vector2i(64, 96) and tree_sheet.get_tiles_count() == 9
		and tree_sheet.get_tile_data(Vector2i(0, 8), 0).texture_origin == Vector2i(0, 16),
		"Withered Trees are 64x96, 9 kinds, bottom 64 px on their own cell")
	_check(env.get_cell_source_id(Vector2i(5, size.y)) == EnvironmentTiles.CLIFF
		and env.get_cell_atlas_coords(Vector2i(5, size.y)).x == 3, "a cliff hangs under the bottom row")
	_check(env.get_cell_source_id(Vector2i(map.startPath) + Vector2i.UP) == EnvironmentTiles.ROPE_BRIDGE,
		"a rope bridge leads out from the start")
	_check(map.dream_void.get_child(0) is Parallax2D and map.dream_void.z_index < 0, "the void sits behind the map")
	_check(env.get_cell_source_id(Vector2i(map.startPath)) == EnvironmentTiles.EDGE_MIST, "mist on the start cell")
	var trees := map.tile_set.get_source(EnvironmentTiles.WITHERED_TREE) as TileSetAtlasSource
	_check(trees.get_tile_animation_mode(Vector2i(0, 0)) == TileSetAtlasSource.TILE_ANIMATION_MODE_RANDOM_START_TIMES,
		"dead trees start their animation at random times")
	_check(trees.get_tile_animation_speed(Vector2i(0, 3)) != trees.get_tile_animation_speed(Vector2i(0, 4))
		and trees.get_tile_animation_frame_duration(Vector2i(0, 0), 0) != trees.get_tile_animation_frame_duration(Vector2i(0, 0), 1),
		"each dead-tree type animates at its own pace")
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

	# Clearing leaves the obstacle's mark (on a cell the route doesn't then take).
	for cell in map.obstacles.keys():
		var data: ObstacleData = map.obstacles[cell]
		if map.get_path_if_cleared(cell).has(cell):
			continue
		if map.clear_obstacle(cell):
			_check(env.get_cell_source_id(Vector2i(cell)) == data.cleared_source_id,
				"clearing a %s leaves its mark" % data.display_name)
			break

	# The path wears away decorations it's drawn over, and the cell stays bare if it moves away.
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var worn := Vector2i(route[route.size() / 2])
	env.set_cell(worn, EnvironmentTiles.GROUND_DETAILS, Vector2i.ZERO)
	path.call("draw")  # PathGenerator.draw(), not CanvasItem's draw signal
	_check(env.get_cell_source_id(worn) == -1, "the path wears away a ground detail under it")
	_check(env.get_cell_source_id(Vector2i(map.startPath)) == EnvironmentTiles.EDGE_MIST, "but not the start's mist")

	# The Heartwood blackens as leaves are lost.
	var heartwood: Heartwood = map.heartwood
	var run_state: RunState = main.get_node("%RunState")
	_check(heartwood.frame_coords.y == 0, "Heartwood starts whole")
	run_state.lose_leaves(run_state.max_leaves / 2)
	var lost := float(run_state.max_leaves / 2) / run_state.max_leaves  # Not exactly half with an odd count
	_check(heartwood.frame_coords.y == roundi(lost * (EnvironmentTiles.HEARTWOOD_STATES - 1)),
		"half the leaves lost = half-blackened (row %d)" % heartwood.frame_coords.y)

	# Act breaks swap every sheet to the new season.
	main.get_node("Seasons").set_act(2, false)
	var grass_source := map.tile_set.get_source(EnvironmentTiles.GRASS) as TileSetAtlasSource
	_check(grass_source.texture.resource_path.contains("deep_wood"), "act 2 uses the Deep Wood sheets")
	_check(heartwood.texture.resource_path.contains("deep_wood"), "and the Heartwood follows")
	_check(map.ambience.act == 2, "the ambience follows the act")
	_check(map.ambience.z_index + map.ambience.get_node("CloudShadows").z_index == EnvironmentAmbience.CLOUD_SHADOW_Z,
		"crossing cloud shadows sit over the Wardens, under the glows and effects")
	main.get_node("Seasons").set_act(1, false)
	run_state.regrow_leaves(run_state.max_leaves)

	# Lighting: a cold multiply over the map, a warm light on the Heartwood and on attacking Wardens.
	var lighting: EnvironmentLighting = map.lighting
	var vignette := lighting.get_child(0) as Sprite2D
	_check(vignette != null and (vignette.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_MUL,
		"the edges get a cold multiply")
	_check(heartwood.get_child(0) is PointLight2D and heartwood.get_child(1) is Sprite2D, "the Heartwood glows")
	var glowing_before := lighting.get_glowing_warden_count()
	var nodes_before := lighting.get_child_count()
	var sprout := _add_warden(main, "res://resource/tower/sprout.tres", Vector2(20, 18))
	var wall := _add_warden(main, "res://resource/tower/thornwall.tres", Vector2(22, 18))
	_add_warden(main, "res://resource/tower/sprout.tres", Vector2(12, 10))
	_check(lighting.get_glowing_warden_count() == glowing_before + 2, "attacking Wardens glow, walls don't")
	_check(lighting.get_child_count() == nodes_before and sprout.get_child_count() == 1,
		"Warden glows are drawn by one canvas item, not a light node each")
	wall.free()
	sprout.free()
	await process_frame
	_check(lighting.get_glowing_warden_count() == glowing_before + 1, "a sold Warden's glow goes with it")

	# Build mode: a cold hatch on every unbuildable cell (screens_ui.md: the edge must look unbuildable).
	var hatch: BuildHatch = map.build_hatch
	_check(not hatch.visible, "no hatch outside build mode")
	main.get_node("%TowerPlacer").build_mode_changed.emit(true)
	var hatched := hatch.get_hatched_cells()
	var an_obstacle: Vector2 = map.obstacles.keys()[0]
	_check(hatch.visible and hatched.has(Vector2(0, 5)) and hatched.has(map.startPath) and hatched.has(map.endPath)
		and hatched.has(an_obstacle), "build mode hatches the rim, the start, the end and obstacles")
	var open_cell := Vector2(-1, -1)
	_check(hatched.all(func(cell: Vector2) -> bool: return not map.is_buildable(cell)), "only unbuildable cells are hatched")
	for x in range(1, 22):
		if map.is_buildable(Vector2(x, 9)):
			open_cell = Vector2(x, 9)
			break
	_check(not hatched.has(open_cell) and not hatched.has(Vector2(12, 10)),
		"buildable cells and a Warden's own cell stay clear")
	main.get_node("%TowerPlacer").build_mode_changed.emit(false)
	_check(not hatch.visible, "leaving build mode hides the hatch")

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="):
			_render(main, [ground, path, env], arg.trim_prefix("--preview="))

	print("test_environment: %d failure(s)" % failures)
	main.free()
	quit(failures)

func _add_warden(main: Node, data_path: String, cell: Vector2) -> Tower:
	var tower: Tower = main.get_node("%TowerPlacer").tower_scene.instantiate()
	tower.tower_data = load(data_path)
	tower.cell = cell
	tower.position = main.get_node("%MapGenerator").MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(tower)
	return tower

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

# Flat render of the void, the map layers, the Heartwood and Wardens (headless has no renderer):
# frame 0 of every tile, `MARGIN` cells of void around the island, at half size.
const MARGIN := 5

func _render(main: Node, layers: Array, file: String) -> void:
	var map = main.get_node("%MapGenerator")
	var size := Vector2i(map.MAP_GRID.size) + Vector2i.ONE * MARGIN * 2
	var tile := EnvironmentTiles.SIZE
	var offset := tile * MARGIN  # World (0, 0) in the image
	var image := Image.create_empty(size.x * tile.x, size.y * tile.y, false, Image.FORMAT_RGBA8)
	for sheet in ["void_sky", "void_stars"]:
		var layer: Image = load(EnvironmentTiles.shared_path(sheet)).get_image()
		layer.convert(Image.FORMAT_RGBA8)
		for y in range(0, image.get_height(), layer.get_height()):
			for x in range(0, image.get_width(), layer.get_width()):
				image.blend_rect(layer, Rect2i(Vector2i.ZERO, layer.get_size()), Vector2i(x, y))
	for islet in map.dream_void.get_children():
		if islet is Sprite2D:
			var art: Image = islet.texture.get_image()
			art.convert(Image.FORMAT_RGBA8)
			var region := Rect2i(islet.region_rect)
			image.blend_rect(art, region, Vector2i(islet.position) - region.size / 2 + offset)
	var sheets := {}
	for layer: TileMapLayer in layers:
		var cells := layer.get_used_cells()
		cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y)  # Tall tiles overhang upward
		for cell in cells:
			var at := cell * tile + offset
			if at.x < 0 or at.y < 0 or at.x >= image.get_width() or at.y >= image.get_height():
				continue
			var source := layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
			if not sheets.has(source):
				sheets[source] = source.texture.get_image()
				sheets[source].convert(Image.FORMAT_RGBA8)
			var region := source.texture_region_size
			var coords := layer.get_cell_atlas_coords(cell)
			var origin := source.get_tile_data(coords, 0).texture_origin
			image.blend_rect(sheets[source], Rect2i(coords * region, region), at + (tile - region) / 2 - origin)
	var heartwood: Heartwood = map.heartwood
	var tree: Image = heartwood.texture.get_image()
	tree.convert(Image.FORMAT_RGBA8)
	var frame := Vector2i(EnvironmentTiles.HEARTWOOD_SIZE, EnvironmentTiles.HEARTWOOD_SIZE)
	var top_left := Vector2i(heartwood.position + heartwood.offset) - frame / 2 + offset
	image.blend_rect(tree, Rect2i(heartwood.frame_coords * frame, frame), top_left)
	for tower: Tower in main.get_node("%TowerContainer").get_children():
		var sprite: Image = tower.tower_data.texture.get_image()
		sprite.convert(Image.FORMAT_RGBA8)
		image.blend_rect(sprite, Rect2i(Vector2i.ZERO, tile), Vector2i(tower.position) - tile / 2 + offset)
	image.resize(image.get_width() / 2, image.get_height() / 2, Image.INTERPOLATE_NEAREST)
	_light_pass(image, map, offset, 2.0)
	image.save_png(file)
	print("preview saved to ", file)
# Rough stand-in for the renderer's lighting: the cold multiply, lifted by the Heartwood's light
# (which lights the multiply layer too), plus the additive glows. `scale` = world px per image px.
func _light_pass(image: Image, map: Node, margin: Vector2i, scale: float) -> void:
	var lighting: EnvironmentLighting = map.lighting
	var vignette := lighting.get_child(0) as Sprite2D
	var edge := vignette.texture as GradientTexture2D
	var cover := vignette.scale * 256.0
	var reach := edge.fill_to.x - 0.5
	var falloff := (EnvironmentLighting.light_texture() as GradientTexture2D).gradient
	var lights := []
	var glow := map.heartwood.get_child(1) as Sprite2D  # Additive, over the multiply
	var glow_radius := glow.scale.x * 128.0
	var heart_light := map.heartwood.get_child(0) as PointLight2D
	lights.append([heart_light.global_position, heart_light.color * heart_light.energy, heart_light.texture_scale * 128.0 * heart_light.scale.x])
	var glows := [[glow.global_position, glow.modulate * glow.modulate.a, glow_radius]]
	for tower: Tower in lighting._wardens:
		if lighting._wardens[tower]:
			glows.append([tower.global_position + Vector2(0, -2),
				Color(lighting.warden_glow_color, 1.0) * lighting.warden_glow_alpha, lighting.warden_glow_radius])
	for y in image.get_height():
		for x in image.get_width():
			var world := Vector2(x, y) * scale - Vector2(margin)
			var cold := edge.gradient.sample(((world - vignette.position) / cover).length() / reach)
			var warm := Color(0, 0, 0)
			for light: Array in lights:
				var d: float = world.distance_to(light[0]) / light[2]
				if d < 1.0:
					warm += light[1] * falloff.sample(d).a
			var lift := Color(1, 1, 1) + warm
			var c := image.get_pixel(x, y) * lift * cold * lift
			for added: Array in glows:
				var g: float = world.distance_to(added[0]) / added[2]
				if g < 1.0:
					c += added[1] * falloff.sample(g).a
			c.a = 1.0
			image.set_pixel(x, y, c.clamp())
