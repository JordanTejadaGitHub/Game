extends Node2D

# The map outline of a Dream card's distance word (distance words, owner 2026-10-19: "we don't know what's the
# measurement"). While a Dream or Calling evolution offer is open, the card the player hovers (mouse) or holds / looks
# at (touch) outlines on the map the cells its word covers around their own Wardens of the family it names: near
# (5×5) for Hammerfall around Firefly Wardens, touching (3×3) for Pass It Round around Sporelings, "within N cells",
# or the Warden's range. The squares are the build ghost's card-area squares (TowerPlacer._draw_card_areas: dashed,
# BONUS_ON, half = (radius + 0.5) cells). A card with no distance word, or no family, shows nothing.
# Made by the Dream screen when it shows a card and freed when the offer closes. World space: under the HUD, so it
# reads best with "Peek at the map" (the last card shown stays outlined while peeking).

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const LINE := Palette.NEWLEAF  # TowerPlacer.BONUS_ON: a card's area around the build ghost
const FILL_ALPHA := 0.12
const LINE_ALPHA := 0.85
const HOME_ALPHA := 0.6
const TOUCH_CELLS := 1  # class_kit TOUCH_CELLS: the 8 around
const NEAR_CELLS := 2  # class_kit NEAR_CELLS: within 2 on both axes
const NOT_AROUND_WARDENS := ["heartwood", "start", "bend", "nightmare", "each other"]  # "within 3 cells of the start": another anchor

var card_id := ""  # The card outlined now ("" = none)
var _line := ""  # Its family's Warden line ("light", "water", "spore", "song" …)
var _squares: Array[float] = []  # Radii in cells (Chebyshev squares)
var _range := false  # Also each Warden's own range

func _init() -> void:
	z_index = 20  # Above the map, its Wardens and effects; the HUD is its own layer
	process_mode = Node.PROCESS_MODE_ALWAYS

# Outlines `card` (null clears). `calling_family`: the run's Calling family id, for evolutions without one of their own.
func show_card(card: UpgradeData, calling_family: String = "") -> void:
	card_id = card.id if card != null else ""
	_line = ""
	_squares.clear()
	_range = false
	if card != null:
		_line = family_line(card, calling_family)
		if _line != "":
			_read_reach(IconInfo.format(card.description).to_lower())
	queue_redraw()

# The Warden line of the family a card names: its first required Warden, else its Calling (class cards, evolutions).
static func family_line(card: UpgradeData, calling_family: String = "") -> String:
	var ids: Array[String] = []
	ids.append_array(card.requires)
	ids.append(card.calling)
	if card.tags.has("calling_evolution"):
		ids.append(calling_family)
	for id in ids:
		if id == "":
			continue
		var data := IconInfo.family_data(id)
		if data != null and data.line != "" and data.line != "wall":
			return data.line
	return ""

# The distance words in a card's text (formatted, lower case).
func _read_reach(text: String) -> void:
	if RegEx.create_from_string("\\btouch(?:ing|es)?\\b").search(text) != null:
		_squares.append(float(TOUCH_CELLS))
	if RegEx.create_from_string("\\bnear\\b").search(text) != null:
		_squares.append(float(NEAR_CELLS))
	for found in RegEx.create_from_string("within ([0-9]+(?:\\.[0-9]+)?)\\s+cells?(?: of (?:the |a |an )?([a-z ]+))?").search_all(text):
		var anchor := found.get_string(2)
		if NOT_AROUND_WARDENS.any(func(word: String) -> bool: return anchor.begins_with(word)):
			continue
		var cells := float(found.get_string(1))
		if not _squares.has(cells):
			_squares.append(cells)
	_range = RegEx.create_from_string("(?:'s|\\bits|\\btheir|\\bin) range\\b").search(text) != null

func _wardens() -> Array:
	var out: Array = []
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		if tower is Tower and not tower.is_queued_for_deletion() and tower.tower_data != null and tower.tower_data.line == _line:
			out.append(tower)
	return out

func _draw() -> void:
	if _line == "" or (_squares.is_empty() and not _range):
		return
	var cell := MAP_GRID.cell_size.x
	for tower in _wardens():
		var centre := to_local(tower.global_position)
		var home := cell * 0.5
		draw_rect(Rect2(centre - Vector2(home, home), Vector2(cell, cell)), Color(LINE, HOME_ALPHA), false, 2.0)
		for radius in _squares:
			var half := (radius + 0.5) * cell
			var rect := Rect2(centre - Vector2(half, half), Vector2(half, half) * 2.0)
			draw_rect(rect, Color(LINE, FILL_ALPHA))
			var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
			for i in 4:
				draw_dashed_line(corners[i], corners[(i + 1) % 4], Color(LINE, LINE_ALPHA), 2.0, 8.0)
		if _range:
			draw_arc(centre, Tower.range_to_pixels(tower.get_range_cells()), 0.0, TAU, 64, Color(LINE, LINE_ALPHA), 2.0)
