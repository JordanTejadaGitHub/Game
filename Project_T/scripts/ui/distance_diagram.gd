extends VBoxContainer

# The distance picture in a word's tip (distance words, owner 2026-10-19: "still confused on cell, should have an
# image … because we don't know what's the measurement"). StatusLinks shows it under the glossary line of
# {touching}, {near}, {step} / {steps} and the word "cells": a 7×7 piece of map, a Warden on the centre cell, the 8
# cells touching it, the 5×5 near block (the same dashed square as the build ghost's card areas), and a stretch of
# path numbered in steps. The word the tip is about is outlined brightest. Code-drawn, palette colours only.
# The rules it pictures live in class_kit.gd (TOUCH_CELLS 1, NEAR_CELLS 2: both axes, so squares).

const SENTENCE := "A cell is the square one Warden stands on."
const CELL := 32.0  # Px per cell in the picture (tip text is 16 px: phone-readable at UI scale 50%)
const SIDE := 7  # Cells across and down
const NEAR := 2  # Near: within 2 cells on both axes (class_kit NEAR_CELLS)
const TOUCH := 1  # Touching: the 8 around (class_kit TOUCH_CELLS)
const PATH_ROW := 6  # The path's row: outside the near block, so every step is counted plainly
const LEGEND_H := 26.0
const LEGEND_SIZE := 14
const NUMBER_SIZE := 15

const GROUND := Color(Palette.NIGHT, 0.9)
const GRID_LINE := Color(Palette.SLATE, 0.9)
const NEAR_FILL := Color(Palette.MOSS, 0.55)  # Fainter than touching
const NEAR_LINE := Palette.NEWLEAF  # The build ghost's card-area colour (TowerPlacer.BONUS_ON)
const TOUCH_FILL := Color(Palette.SPRIG, 0.8)
const PATH_FILL := Palette.PATH
const PATH_NUMBER := Palette.ROOT
const WARDEN := Palette.GOLD
const WARDEN_CORE := Palette.HEARTLIGHT
const FOCUS_LINE := UiStyle.GOLD

var focus: StringName = &""  # &"touching", &"near", &"step" or &"cell": the part outlined brightest
var _grid := Control.new()
var _sentence := Label.new()

func _init() -> void:
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.custom_minimum_size = Vector2(CELL * SIDE, CELL * SIDE + LEGEND_H)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.draw.connect(_draw_grid)
	add_child(_grid)
	_sentence.text = SENTENCE
	UiStyle.tip_body(_sentence)
	_sentence.add_theme_color_override("font_color", UiStyle.INK_DIM)
	add_child(_sentence)

# Shows the picture for term `id` (the sentence is left out for "cell": its glossary line already says it).
func show_for(id: StringName) -> void:
	focus = id
	_sentence.visible = id != &"cell"
	_grid.queue_redraw()

func _cell_rect(x: int, y: int) -> Rect2:
	return Rect2(Vector2(x, y) * CELL, Vector2(CELL, CELL))

func _block(radius: int) -> Rect2:
	var centre := SIDE / 2
	return Rect2(Vector2(centre - radius, centre - radius) * CELL, Vector2(radius * 2 + 1, radius * 2 + 1) * CELL)

func _draw_grid() -> void:
	var centre := SIDE / 2
	for y in SIDE:
		for x in SIDE:
			var rect := _cell_rect(x, y)
			var away := maxi(absi(x - centre), absi(y - centre))  # Cells count as a square (both axes)
			var fill := GROUND
			if y == PATH_ROW:
				fill = PATH_FILL
			elif away == TOUCH:
				fill = TOUCH_FILL
			elif away <= NEAR and away > 0:
				fill = NEAR_FILL
			_grid.draw_rect(rect, fill)
			_grid.draw_rect(rect, GRID_LINE, false, 1.0)
	# The near block: the dashed square the build ghost draws for a card's radius
	var near := _block(NEAR)
	var corners := [near.position, Vector2(near.end.x, near.position.y), near.end, Vector2(near.position.x, near.end.y)]
	var near_width := 3.0 if focus == &"near" else 2.0
	for i in 4:
		_grid.draw_dashed_line(corners[i], corners[(i + 1) % 4], Color(NEAR_LINE, 1.0 if focus == &"near" else 0.7), near_width, 8.0)
	if focus == &"touching":
		_grid.draw_rect(_block(TOUCH), FOCUS_LINE, false, 3.0)
	# The Warden on its cell
	var home := _cell_rect(centre, centre)
	_grid.draw_circle(home.get_center(), CELL * 0.34, WARDEN)
	_grid.draw_circle(home.get_center(), CELL * 0.14, WARDEN_CORE)
	if focus == &"cell":
		_grid.draw_rect(home.grow(-1.0), FOCUS_LINE, false, 3.0)
	# The path, counted in steps
	var font := UiStyle.number_font()
	for x in SIDE:
		var rect := _cell_rect(x, PATH_ROW)
		var label := str(x + 1)
		var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE)
		_grid.draw_string(font, rect.get_center() + Vector2(-size.x / 2.0, size.y * 0.3), label, HORIZONTAL_ALIGNMENT_LEFT,
			-1, NUMBER_SIZE, PATH_NUMBER)
	if focus == &"step":
		_grid.draw_rect(Rect2(Vector2(0, PATH_ROW) * CELL, Vector2(SIDE, 1) * CELL).grow(-1.0), FOCUS_LINE, false, 3.0)
	_draw_legend()

# Under the grid: a swatch and a word for each colour.
func _draw_legend() -> void:
	var font := UiStyle.body_font()
	var rows := [[TOUCH_FILL, "Touching"], [NEAR_FILL, "Near"], [PATH_FILL, "Steps"], [WARDEN, "1 cell"]]
	var widths: Array[float] = []
	var total := 0.0
	for row in rows:
		var w: float = 14.0 + font.get_string_size(row[1], HORIZONTAL_ALIGNMENT_LEFT, -1, LEGEND_SIZE).x
		widths.append(w)
		total += w
	var gap := maxf((CELL * SIDE - total) / float(rows.size() - 1), 6.0)
	var x := 0.0
	var y := CELL * SIDE + LEGEND_H / 2.0 + 2.0
	for i in rows.size():
		_grid.draw_rect(Rect2(x, y - 5.0, 10.0, 10.0), rows[i][0])
		_grid.draw_string(font, Vector2(x + 14.0, y + LEGEND_SIZE * 0.35), rows[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1,
			LEGEND_SIZE, UiStyle.INK_DIM)
		x += widths[i] + gap
