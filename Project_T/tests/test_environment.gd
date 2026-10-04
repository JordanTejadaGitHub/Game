extends SceneTree
# The environment art is wired in: every layer draws from EnvironmentTiles, clearing leaves a mark,
# the Heartwood shows leaves lost, and act breaks swap the season's sheets.
# Run:  Godot --headless --path . --script res://tests/test_environment.gd --fixed-fps 60
# Pass a path after `--` (e.g. `-- --preview=C:/tmp/map.png`) to also save a flat render of the map,
# `-- --seed=N` to preview another map, `-- --layouts=<file.png>` for a sheet of ~12 layouts.

var failures := 0

func _init() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 1207
	for arg in OS.get_cmdline_user_args():  # `-- --seed=N` previews another map
		if arg.begins_with("--seed="):
			main.get_node("MapGenerator").map_seed = int(arg.trim_prefix("--seed="))
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
	var rim_cell := Vector2i(0, 1)  # A left-edge rim cell that isn't the start or the goal (layouts move them)
	while Vector2(rim_cell) == map.startPath or Vector2(rim_cell) == map.endPath:
		rim_cell.y += 1
	_check(ground.get_cell_source_id(rim_cell) == -1, "no grass square under the island's rim")
	_check(env.get_cell_source_id(rim_cell) == EnvironmentTiles.ISLAND_EDGE
		and env.get_cell_atlas_coords(rim_cell).x == 1 | 2 | 4, "the left rim: island to the N, E and S")
	_check(env.get_cell_atlas_coords(Vector2i(0, 0)).x == 2 | 4, "the top-left corner: island to the E and S")
	var tree_sheet := map.tile_set.get_source(EnvironmentTiles.WITHERED_TREE) as TileSetAtlasSource
	_check(tree_sheet.texture_region_size == Vector2i(96, 128) and tree_sheet.get_tiles_count() == 9
		and tree_sheet.get_tile_data(Vector2i(0, 8), 0).texture_origin == Vector2i(0, 32),
		"Withered Trees are 96x128, 9 kinds, bottom 64 px on their own cell")
	var cliffs := 0  # Under the bottom row, except where a rope bridge crosses out over them
	for x in range(1, size.x - 1):
		if env.get_cell_source_id(Vector2i(x, size.y)) == EnvironmentTiles.CLIFF and env.get_cell_atlas_coords(Vector2i(x, size.y)).x == 3:
			cliffs += 1
	_check(cliffs >= size.x - 3, "cliffs hang under the bottom row (%d)" % cliffs)
	var out: Vector2i = env._outward(Vector2i(map.startPath))
	_check(env.get_cell_source_id(Vector2i(map.startPath) + out) == EnvironmentTiles.ROPE_BRIDGE,
		"a rope bridge leads out from the start, off its edge")
	_check(map.dream_void.get_child(0) is Parallax2D and map.dream_void.z_index < 0, "the void sits behind the map")
	_check(env.get_cell_source_id(Vector2i(map.startPath)) == EnvironmentTiles.EDGE_MIST, "mist on the start cell")
	var trees := map.tile_set.get_source(EnvironmentTiles.WITHERED_TREE) as TileSetAtlasSource
	_check(trees.get_tile_animation_mode(Vector2i(0, 0)) == TileSetAtlasSource.TILE_ANIMATION_MODE_RANDOM_START_TIMES,
		"dead trees start their animation at random times")
	_check(trees.get_tile_animation_speed(Vector2i(0, 3)) != trees.get_tile_animation_speed(Vector2i(0, 4))
		and trees.get_tile_animation_frame_duration(Vector2i(0, 0), 0) != trees.get_tile_animation_frame_duration(Vector2i(0, 0), 1),
		"each dead-tree type animates at its own pace")
	for cell in path.get_used_cells():
		var on_rim: bool = Vector2(cell) == map.startPath
		if path.get_cell_source_id(cell) != (EnvironmentTiles.PATH_RIM if on_rim else EnvironmentTiles.PATH):
			_check(false, "path cell %s uses the path sheet" % cell)
			break
	var start_mask: int = path.get_cell_atlas_coords(Vector2i(map.startPath)).x
	_check(path.get_cell_source_id(Vector2i(map.startPath)) == EnvironmentTiles.PATH_RIM
		and ground.get_cell_source_id(Vector2i(map.startPath)) == EnvironmentTiles.ISLAND_EDGE,
		"the start draws rim-edge path over the rim, no grass")
	_check(map.path_layer.current_path.has(map.endPath)  # Half cells: the route is a soft fill, not tiles
		and ground.get_cell_source_id(Vector2i(map.endPath)) == EnvironmentTiles.GRASS, "the Heartwood stands inland, on grass")
	var out_bit: int = {Vector2i.UP: 1, Vector2i.RIGHT: 2, Vector2i.DOWN: 4, Vector2i.LEFT: 8}[out]
	_check(start_mask & out_bit, "the start's path tile runs off its edge (mask %d)" % start_mask)
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

	# Inland, the canopy covers the 3 cells behind the Heartwood: something there fades it.
	_check(not heartwood.is_something_behind(), "nothing behind the Heartwood at first")
	var behind := _add_warden(main, "res://resource/tower/sprout.tres", map.endPath + Vector2(0, -1))
	await process_frame  # The Heartwood rechecks its Wardens a frame after one joins
	_check(heartwood.is_something_behind(), "a Warden behind the Heartwood is seen")
	for i in 30:
		await process_frame
	_check(heartwood.self_modulate.a < 0.7, "the canopy fades over it (%.2f)" % heartwood.self_modulate.a)
	behind.free()
	for i in 30:
		await process_frame
	_check(heartwood.self_modulate.a > 0.9, "and comes back when it's gone (%.2f)" % heartwood.self_modulate.a)

	# Build mode: a cold hatch on every unbuildable cell (screens_ui.md: the edge must look unbuildable).
	var hatch: BuildHatch = map.build_hatch
	_check(not hatch.visible, "no hatch outside build mode")
	main.get_node("%TowerPlacer").build_mode_changed.emit(true)
	var hatched := hatch.get_hatched_cells()
	var an_obstacle: Vector2 = map.obstacles.keys()[0]
	_check(hatch.visible and hatched.has(Vector2(rim_cell)) and hatched.has(map.startPath) and hatched.has(map.endPath)
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
		if arg.begins_with("--layouts="):
			await _layout_sheet(arg.trim_prefix("--layouts="))

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
		if layer == map.path_layer:
			_blend_half_path(image, map, offset)
	_blend_pond_corners(image, map, offset)
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

# --- Layout sheet (`-- --layouts=<file.png>`) ---------------------------------------------------------
# ~12 seeds in one sheet, covering every layout and feature, each labelled and with its starting route.

const SHEET_SEED_LIST: Array[int] = [1, 2, 3, 4, 8, 9, 6, 7, 10, 12, 24, 27]  # The first sheet's seeds (453a65a9)
const SHEET_COLUMNS := 4
const SHEET_SCALE := 4  # Each map is drawn at 1/4 size (16 px per cell)
const LABEL_HEIGHT := 16
const ROUTE_COLOR := Color("fcd47c")  # Palette.GLOW
const FONT := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"], "D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
	"G": [".##", "#..", "#.#", "#.#", ".##"], "H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"], "J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"], "L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#.#", "###", "###", "#.#", "#.#"], "N": ["##.", "#.#", "#.#", "#.#", "#.#"],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."], "P": ["##.", "#.#", "##.", "#..", "#.."],
	"Q": [".#.", "#.#", "#.#", "##.", ".##"], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": [".##", "#..", ".#.", "..#", "##."], "T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"], "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"W": ["#.#", "#.#", "###", "###", "#.#"], "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."], "Z": ["###", "..#", ".#.", "#..", "###"],
	"0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["##.", "..#", ".#.", "#..", "###"], "3": ["##.", "..#", ".#.", "..#", "##."],
	"4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "##.", "..#", "##."],
	"6": [".##", "#..", "###", "#.#", "###"], "7": ["###", "..#", ".#.", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "##."],
	"-": ["...", "...", "###", "...", "..."], "(": [".#.", "#..", "#..", "#..", ".#."],
	")": [".#.", "..#", "..#", "..#", ".#."], ":": ["...", ".#.", "...", ".#.", "..."],
}

func _layout_sheet(file: String) -> void:
	var seeds: Array[int] = SHEET_SEED_LIST  # The same seeds every time, so sheets compare
	var cell := EnvironmentTiles.SIZE
	var map_px := Vector2i(Vector2(load("res://resource/map/map_grid.tres").size)) * cell / SHEET_SCALE
	var tile := map_px + Vector2i(0, LABEL_HEIGHT)
	var rows := ceili(float(seeds.size()) / SHEET_COLUMNS)
	var sheet := Image.create_empty(tile.x * SHEET_COLUMNS + 8 * (SHEET_COLUMNS + 1), tile.y * rows + 8 * (rows + 1),
		false, Image.FORMAT_RGBA8)
	sheet.fill(Color("05050d"))  # Palette.VOID
	for i in seeds.size():
		var main: Node = load("res://scenes/main.tscn").instantiate()
		main.get_node("MapGenerator").map_seed = seeds[i]
		root.add_child(main)
		await process_frame
		var map = main.get_node("%MapGenerator")
		var image := _flat_map(main)
		image.resize(map_px.x, map_px.y, Image.INTERPOLATE_BILINEAR)
		_draw_route(image, map.get_path_from(map.startPath), cell.x / SHEET_SCALE)
		var at := Vector2i(8 + (i % SHEET_COLUMNS) * (tile.x + 8), 8 + (i / SHEET_COLUMNS) * (tile.y + 8))
		sheet.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at + Vector2i(0, LABEL_HEIGHT))
		var label := "%d %s - %s" % [seeds[i], map.layout.get_kind_name(), map.layout.get_feature_name()]
		_draw_text(sheet, label.to_upper(), at + Vector2i(2, 3), 2, Color("dce8f4"))
		main.free()
	sheet.save_png(file)
	print("layout sheet saved to ", file, " (seeds ", seeds, ")")

# The map's tile layers, the Heartwood and its Wardens, flat (no lighting), one cell of void around.
func _flat_map(main: Node) -> Image:
	var map = main.get_node("%MapGenerator")
	var layers: Array = [main.get_node("%GroundTileMapLayer"), main.get_node("%PathTileMapLayer"),
		main.get_node("%EnvironmentObjectTileMapLayer")]
	var size := Vector2i(map.MAP_GRID.size)
	var tile := EnvironmentTiles.SIZE
	var image := Image.create_empty(size.x * tile.x, size.y * tile.y, false, Image.FORMAT_RGBA8)
	image.fill(Color("140f26"))  # Palette.DREAD: the void
	var sheets := {}
	for layer: TileMapLayer in layers:
		var cells := layer.get_used_cells()
		cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y)
		for cell in cells:
			if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
				continue
			var source := layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
			if not sheets.has(source):
				sheets[source] = source.texture.get_image()
				sheets[source].convert(Image.FORMAT_RGBA8)
			var region := source.texture_region_size
			var coords := layer.get_cell_atlas_coords(cell)
			var origin := source.get_tile_data(coords, 0).texture_origin
			image.blend_rect(sheets[source], Rect2i(coords * region, region), cell * tile + (tile - region) / 2 - origin)
		if layer == map.path_layer:
			_blend_half_path(image, map, Vector2i.ZERO)
	_blend_pond_corners(image, map, Vector2i.ZERO)
	var heartwood: Heartwood = map.heartwood
	var tree: Image = heartwood.texture.get_image()
	tree.convert(Image.FORMAT_RGBA8)
	var frame := Vector2i(EnvironmentTiles.HEARTWOOD_SIZE, EnvironmentTiles.HEARTWOOD_SIZE)
	image.blend_rect(tree, Rect2i(heartwood.frame_coords * frame, frame), Vector2i(heartwood.position + heartwood.offset) - frame / 2)
	return image

func _draw_route(image: Image, route: PackedVector2Array, cell: int) -> void:
	for i in route.size():
		var a := Vector2i(route[i]) * cell + Vector2i.ONE * (cell / 2)
		var b := Vector2i(route[mini(i + 1, route.size() - 1)]) * cell + Vector2i.ONE * (cell / 2)
		var r := Rect2i(Vector2i(mini(a.x, b.x), mini(a.y, b.y)) - Vector2i.ONE, (a - b).abs() + Vector2i(3, 3))
		image.fill_rect(r.intersection(Rect2i(Vector2i.ZERO, image.get_size())), ROUTE_COLOR)
	if not route.is_empty():  # Start: a square; the Heartwood: a ring round its cell
		var bounds := Rect2i(Vector2i.ZERO, image.get_size())
		var s := Vector2i(route[0]) * cell + Vector2i.ONE * (cell / 2)
		image.fill_rect(Rect2i(s - Vector2i(4, 4), Vector2i(9, 9)).intersection(bounds), Color("bc44dc"))  # Palette.ORCHID
		var h := Vector2i(route[route.size() - 1]) * cell + Vector2i.ONE * (cell / 2)
		for side in [Rect2i(h - Vector2i(10, 10), Vector2i(21, 3)), Rect2i(h + Vector2i(-10, 8), Vector2i(21, 3)),
				Rect2i(h - Vector2i(10, 10), Vector2i(3, 21)), Rect2i(h + Vector2i(8, -10), Vector2i(3, 21))]:
			image.fill_rect(side.intersection(bounds), Color("9cc46c"))  # Palette.SPRIG

func _draw_text(image: Image, text: String, at: Vector2i, scale: int, color: Color) -> void:
	var x := at.x
	for ch in text:
		var glyph: Array = FONT.get(ch, [])
		for row in glyph.size():
			for col in 3:
				if glyph[row][col] == "#":
					image.fill_rect(Rect2i(x + col * scale, at.y + row * scale, scale, scale), color)
		x += 4 * scale

# The pond's inside-corner sprites (MapGenerator._draw_pond_corners), drawn over the tiles.
func _blend_pond_corners(image: Image, map: Node, offset: Vector2i) -> void:
	for child in map.get_children():
		if child is Sprite2D and String(child.name).begins_with("PondCorner"):
			var art: Image = child.texture.get_image()
			art.convert(Image.FORMAT_RGBA8)
			var region := Rect2i(child.region_rect)
			image.blend_rect(art, region, Vector2i(child.position) - region.size / 2 + offset)

# Half cells (experiment/half-cells): the route is PathGenerator's soft fill, not tiles. Drawn the same way.
func _blend_half_path(image: Image, map: Node, offset: Vector2i) -> void:
	var size := Vector2(map.MAP_GRID.cell_size)
	for pass_index in 2:
		var grow := 3.0 if pass_index == 0 else -1.0
		var colour := Palette.LOAM if pass_index == 0 else Palette.PATH
		for point in map.path_layer.current_path:
			var rect := Rect2(map.MAP_GRID.calculate_map_position(point) - size / 2.0, size).grow(grow)
			image.fill_rect(Rect2i(Vector2i(rect.position) + offset, Vector2i(rect.size)).intersection(
				Rect2i(Vector2i.ZERO, image.get_size())), colour)
