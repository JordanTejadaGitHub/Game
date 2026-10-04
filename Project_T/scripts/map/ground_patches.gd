class_name GroundPatches
extends TileMapLayer

# Ground variation (environment_assets.md "Ground variation", Environment Discussion; art ground_patch.png,
# Environment Assets 4b338e5b): a few big soft patches on the forest floor so open ground isn't one flat colour.
# 3-5 patches of 6-20 whole cells (15-25% of the island's ground), each a kind anchored where it belongs (deep
# moss by ridges and rocks, worn earth on open ground, fern beds by trees and the pond, at most one act accent),
# never touching each other or the start; and always the glade ring under the Heartwood's glade.
# Drawn as a 64 px dual grid (ground_patch.png: row = kind, column = corner mask TL 1, TR 2, BR 4, BL 8, columns
# 16-18 more full tiles), 32 px up-left of the cell grid, a child of the ground layer: over the grass, under the
# path (which draws over patches; patches never wear away). Seeded from the map seed with its own rng, so a saved
# run rebuilds the same patches and the rest of generation is untouched. Built once; nothing per frame.

const SHEET := "ground_patch"
const TILE := Vector2i(64, 64)
const DEEP_MOSS := 0
const WORN_EARTH := 1
const FERN_BED := 2
const ACCENT := 3
const GLADE_RING := 4
const KIND_NAMES: Array[String] = ["deep moss", "worn earth", "fern bed", "act accent", "glade ring"]
const FULL_VARIANTS: Array[int] = [15, 16, 17, 18]
const PATCH_MIN := 6
const PATCH_MAX := 20
const COVERAGE := Vector2(0.15, 0.25)  # Share of the island's ground (rim excluded), the glade ring not counted
const SEED_SALT := 7919

var patches: Array = []  # [{kind: int, cells: Array[Vector2]}], the glade ring last
var kind_at := {}  # Whole cell -> kind
var _map: Node

# Lays the patches for `map` (call after its obstacles and feature, before the ground details).
func build(map: Node, act: int = 1) -> void:
	_map = map
	name = "GroundPatches"
	position = -Vector2(TILE) / 2.0
	tile_set = _tile_set(act)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map.map_seed, SEED_SALT])
	patches.clear()
	kind_at.clear()
	var glade: Array[Vector2] = []
	for cell in map.get_glade_cells():
		glade.append(cell)
	glade.append(map.endPath)
	_add(GLADE_RING, glade)
	var interior := (int(map.MAP_GRID.size.x) - 2) * (int(map.MAP_GRID.size.y) - 2)
	var count := rng.randi_range(3, 5)
	var total := roundi(rng.randf_range(COVERAGE.x, COVERAGE.y) * interior)
	var kinds: Array[int] = [DEEP_MOSS, WORN_EARTH, FERN_BED]
	var extra: Array[int] = [ACCENT, DEEP_MOSS, WORN_EARTH, FERN_BED]
	while kinds.size() < count:
		var kind: int = extra[rng.randi_range(0, extra.size() - 1)]
		if kind == ACCENT and kinds.has(ACCENT):
			continue  # At most one accent a map
		kinds.append(kind)
	var placed := 0
	for i in kinds.size():
		var left := kinds.size() - i
		var size := clampi(roundi(float(total - placed) / left * rng.randf_range(0.85, 1.15)), PATCH_MIN, PATCH_MAX)
		var cells := _grow(rng, kinds[i], size)
		if cells.size() >= PATCH_MIN:
			_add(kinds[i], cells)
			placed += cells.size()
	patches.push_back(patches.pop_front())  # The glade ring last
	_draw_tiles()

func set_act(act: int) -> void:
	(tile_set.get_source(0) as TileSetAtlasSource).texture = load(EnvironmentTiles.sheet_path(SHEET, act))

# Share of the island's ground (rim excluded) under patches, the glade ring not counted.
func coverage() -> float:
	var cells := 0
	for patch: Dictionary in patches:
		if patch.kind != GLADE_RING:
			cells += patch.cells.size()
	return float(cells) / ((_map.MAP_GRID.size.x - 2) * (_map.MAP_GRID.size.y - 2))

func kind_of(cell: Vector2) -> int:
	return kind_at.get(cell, -1)

# The dual tile's column for display tile `at` of `kind`: its corners are the 4 cells around its centre.
func mask_at(at: Vector2i, kind: int) -> int:
	return ((1 if kind_at.get(Vector2(at + Vector2i(-1, -1)), -1) == kind else 0)
		| (2 if kind_at.get(Vector2(at + Vector2i(0, -1)), -1) == kind else 0)
		| (4 if kind_at.get(Vector2(at), -1) == kind else 0)
		| (8 if kind_at.get(Vector2(at + Vector2i(-1, 0)), -1) == kind else 0))

func _add(kind: int, cells: Array[Vector2]) -> void:
	patches.append({"kind": kind, "cells": cells})
	for cell in cells:
		kind_at[cell] = kind

# A patch may take `cell`: inside the island, not the start or the pond, and not touching another patch.
func _free(cell: Vector2, own: Dictionary) -> bool:
	var size: Vector2 = _map.MAP_GRID.size
	if cell.x < 1 or cell.y < 1 or cell.x > size.x - 2 or cell.y > size.y - 2 or cell == _map.startPath:
		return false
	if _map.environment_object_layer.pond_cells.has(cell):
		return false
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var near := cell + Vector2(dx, dy)
			if kind_at.has(near) and not own.has(near):
				return false
	return true

# A soft blob of about `size` cells from an anchor that suits `kind`, grown so it stays round.
func _grow(rng: RandomNumberGenerator, kind: int, size: int) -> Array[Vector2]:
	var anchors := _anchors(kind)
	var cells: Array[Vector2] = []
	for attempt in 12:
		if anchors.is_empty():
			return cells
		var start: Vector2 = anchors[rng.randi_range(0, anchors.size() - 1)]
		var own := {start: true}
		cells = [start]
		while cells.size() < size:
			var frontier: Array[Vector2] = []
			var weights: Array[float] = []
			for cell in cells:
				for step: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
					var next := cell + step
					if own.has(next) or frontier.has(next) or not _free(next, own):
						continue
					var touching := 0
					for s2: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
						if own.has(next + s2):
							touching += 1
					frontier.append(next)
					weights.append(float(touching * touching))  # Favour filling in: round blobs, no tendrils
			if frontier.is_empty():
				break
			var pick := rng.rand_weighted(PackedFloat32Array(weights))
			own[frontier[pick]] = true
			cells.append(frontier[pick])
		if cells.size() >= PATCH_MIN:
			return cells
	return cells

# Free cells that suit `kind` (environment_assets.md's table), else any free cell.
func _anchors(kind: int) -> Array[Vector2]:
	var any: Array[Vector2] = []
	var suited: Array[Vector2] = []
	var obstacles: Dictionary = _map.obstacles
	var env = _map.environment_object_layer
	for x in range(1, int(_map.MAP_GRID.size.x) - 1):
		for y in range(1, int(_map.MAP_GRID.size.y) - 1):
			var cell := Vector2(x, y)
			if not _free(cell, {}):
				continue
			any.append(cell)
			var rocks := 0
			var trees := 0
			var near_obstacle := false
			var near_pond := false
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var near := cell + Vector2(dx, dy)
					var data: ObstacleData = obstacles.get(near)
					var close := absi(dx) <= 1 and absi(dy) <= 1
					if data != null:
						near_obstacle = true
						if close and (data.source_id == EnvironmentTiles.MOSSY_BOULDER or env.ridge_cells.has(near)):
							rocks += 1
						if close and data.source_id == EnvironmentTiles.WITHERED_TREE:
							trees += 1
					if env.pond_cells.has(near):
						near_pond = true
			match kind:
				DEEP_MOSS:
					if rocks >= 1:
						suited.append(cell)
				WORN_EARTH:
					if not near_obstacle:
						suited.append(cell)
				FERN_BED:
					if trees >= 2 or near_pond:
						suited.append(cell)
				_:
					suited.append(cell)
	return suited if not suited.is_empty() else any

func _tile_set(act: int) -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = TILE
	var source := TileSetAtlasSource.new()
	source.texture = load(EnvironmentTiles.sheet_path(SHEET, act))
	source.texture_region_size = TILE
	var grid := source.get_atlas_grid_size()
	for row in grid.y:
		for column in grid.x:
			source.create_tile(Vector2i(column, row))
	tiles.add_source(source, 0)
	return tiles

func _draw_tiles() -> void:
	clear()
	for patch: Dictionary in patches:
		var kind: int = patch.kind
		var done := {}
		for cell: Vector2 in patch.cells:  # Each patch cell is a corner of 4 display tiles
			for dy in 2:
				for dx in 2:
					var at := Vector2i(cell) + Vector2i(dx, dy)
					if done.has(at):
						continue
					done[at] = true
					var mask := mask_at(at, kind)
					if mask == 15:
						mask = FULL_VARIANTS[EnvironmentTiles.cell_variant(at, FULL_VARIANTS.size(), 11)]
					set_cell(at, 0, Vector2i(mask, kind))
