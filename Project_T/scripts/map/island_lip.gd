class_name IslandLip
extends Node2D

# The island's edge, drawn just outside the grid (environment_assets.md "Island edge outside the grid", user
# 2026-10-07 "B but on the bottom of the map have the hanging vines"). Every cell inside is ground; the void cells
# around the map carry the edge (Environment Assets 4bedb870, per act):
# - island_lip.png (64×64, static): columns 0 N side, 1 E side, 2 W side, 3 NE corner, 4 NW corner; 4 variant rows
#   picked by cell hash. On the void cells above the top row, beside the side columns and at the two top corners.
# - island_underside.png (64×128 cells, top-aligned on the void cell under the bottom row, vines reaching 64 px
#   further down): 4 sway-frame columns; rows 0-3 S side variants, 4 SW corner, 5 SE corner.
# Every piece shares one wobble that wraps every 64 px, so variants sit side by side. The rope bridge (object layer)
# draws over the lip at the start. z -1 and first among the ground layers: Warden rings and other ground effects
# (Main, z -1, later) and range previews draw over it; the void (z -10) stays behind. Without the sheets: a
# palette-colour placeholder of the same shapes.

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const LIP_COLUMNS := {&"n": 0, &"e": 1, &"w": 2, &"ne": 3, &"nw": 4}
const UNDER_ROWS := {&"sw": 4, &"se": 5}  # Rows 0-3: S side variants
const VARIANTS := 4
const FRAMES := 4

var act := 1
var _lip: Texture2D
var _under: Texture2D
var _cells: Vector2i
var _frame := 0
var _frame_time := 0.0

func _ready() -> void:
	z_index = -1
	_cells = Vector2i(MAP_GRID.size)
	_load()

func set_act(new_act: int) -> void:
	act = new_act
	_load()

func _load() -> void:
	var lip := EnvironmentTiles.sheet_path("island_lip", act)
	var under := EnvironmentTiles.sheet_path("island_underside", act)
	_lip = load(lip) if ResourceLoader.exists(lip) else null
	_under = load(under) if ResourceLoader.exists(under) else null
	queue_redraw()

func _process(delta: float) -> void:
	_frame_time = fmod(_frame_time + delta * EnvironmentTiles.FPS, FRAMES)
	if int(_frame_time) != _frame:
		_frame = int(_frame_time)
		queue_redraw()  # Only the vines sway

func _draw() -> void:
	var size := Vector2(MAP_GRID.cell_size)
	for x in range(-1, _cells.x + 1):  # The top: the N side, its corners
		var kind: StringName = &"nw" if x == -1 else (&"ne" if x == _cells.x else &"n")
		_lip_piece(Vector2i(x, -1), kind, size)
	for y in _cells.y:  # The W and E sides
		_lip_piece(Vector2i(-1, y), &"w", size)
		_lip_piece(Vector2i(_cells.x, y), &"e", size)
	for x in range(-1, _cells.x + 1):  # The underside, vines and all
		var cell := Vector2i(x, _cells.y)
		var row: int = UNDER_ROWS[&"sw"] if x == -1 else (UNDER_ROWS[&"se"] if x == _cells.x else EnvironmentTiles.cell_variant(cell, VARIANTS))
		var at := Vector2(cell) * size
		if _under != null:
			draw_texture_rect_region(_under, Rect2(at, Vector2(size.x, size.y * 2)), Rect2(Vector2(_frame * size.x, row * size.y * 2), Vector2(size.x, size.y * 2)))
		else:  # Placeholder: a short cliff, a few vines
			draw_rect(Rect2(at, Vector2(size.x, 16)), Palette.ROOT)
			draw_rect(Rect2(at + Vector2(0, 16), Vector2(size.x, 6)), Palette.DREAD)
			for v in 3:
				var vx := at.x + 10 + v * 20 + (x % 3) * 3
				draw_line(Vector2(vx, at.y + 18), Vector2(vx + sin(_frame + v + x) * 2.0, at.y + 30 + ((x * 7 + v * 13) % 40)), Palette.DEEPMOSS, 2.0)

func _lip_piece(cell: Vector2i, kind: StringName, size: Vector2) -> void:
	var at := Vector2(cell) * size
	if _lip != null:
		var row := EnvironmentTiles.cell_variant(cell, VARIANTS)
		draw_texture_rect_region(_lip, Rect2(at, size), Rect2(Vector2(LIP_COLUMNS[kind] * size.x, row * size.y), size))
		return
	# Placeholder: ~10 px of earth on the side of the cell nearest the map
	match kind:
		&"n":
			draw_rect(Rect2(at + Vector2(0, size.y - 10), Vector2(size.x, 10)), Palette.ROOT)
		&"e":
			draw_rect(Rect2(at, Vector2(10, size.y)), Palette.ROOT)
		&"w":
			draw_rect(Rect2(at + Vector2(size.x - 10, 0), Vector2(10, size.y)), Palette.ROOT)
		&"ne":
			draw_rect(Rect2(at + Vector2(0, size.y - 10), Vector2(10, 10)), Palette.ROOT)
		&"nw":
			draw_rect(Rect2(at + Vector2(size.x - 10, size.y - 10), Vector2(10, 10)), Palette.ROOT)
