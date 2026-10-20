extends Node2D

# The map outline of a Dream card's distance word (distance words, owner 2026-10-19: "we don't know what's the
# measurement"). While a Dream or Calling evolution offer is open, the card the player hovers (mouse) or holds / looks
# at (touch) outlines on the map the cells its word covers around their own Wardens of the family it names: near
# (5×5) for Hammerfall around Firefly Wardens, touching (3×3) for Pass It Round around Sporelings, "within N cells",
# or the Warden's range: all joined into one faint region with one soft outline (sizes as the build ghost's card areas,
# BONUS_ON, half = (radius + 0.5) cells). A card with no distance word, or no family, shows nothing.
# Made by the Dream screen when it shows a card and freed when the offer closes. World space: under the HUD, so it
# reads best with "Peek at the map" (the last card shown stays outlined while peeking).

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const LINE := Palette.NEWLEAF  # TowerPlacer.BONUS_ON: a card's area around the build ghost
const FILL_ALPHA := 0.08  # Quieter than the board: the path stays readable under it
const LINE_ALPHA := 0.55
const EDGE_SOFT_ALPHA := 0.15
const HOME_ALPHA := 0.18  # Per glow ring (they stack toward the middle)
const GLOW_RINGS := 3
const TOUCH_CELLS := 1  # class_kit TOUCH_CELLS: the 8 around
const NEAR_CELLS := 2  # class_kit NEAR_CELLS: within 2 on both axes
const NOT_AROUND_WARDENS := ["heartwood", "start", "bend", "nightmare", "each other"]  # "within 3 cells of the start": another anchor

var card_id := ""  # The card outlined now ("" = none)
var _line := ""  # Its family's Warden line ("light", "water", "spore", "song" …)
var _squares: Array[float] = []  # Radii in cells (Chebyshev squares)
var _range := false  # Also each Warden's own range

func _init() -> void:
	z_index = 1  # Just over the ground and path (z -1), level with the board; the HUD is its own layer above
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

# One region, not a square per Warden (Main Merger 2026-10-19: a dozen dashed squares overlapped into a grid over the
# map): every Warden's squares and range join into one set of half cells (Wardens stand on half-cell steps), drawn as
# a faint fill and one soft outline along its outer edge only; each Warden it is measured from glows at its base.
func _draw() -> void:
	if _line == "" or (_squares.is_empty() and not _range):
		return
	var half := MAP_GRID.cell_size.x * 0.5
	var towers := _wardens()
	var covered := {}  # Vector2i half cell -> true
	for tower in towers:
		var centre := to_local(tower.global_position)
		for radius in _squares:
			var reach := (radius + 0.5) * half * 2.0
			for x in range(roundi((centre.x - reach) / half), roundi((centre.x + reach) / half)):
				for y in range(roundi((centre.y - reach) / half), roundi((centre.y + reach) / half)):
					covered[Vector2i(x, y)] = true
		if _range:
			var r: float = Tower.range_to_pixels(tower.get_range_cells())
			for x in range(floori((centre.x - r) / half), ceili((centre.x + r) / half)):
				for y in range(floori((centre.y - r) / half), ceili((centre.y + r) / half)):
					if (Vector2(x + 0.5, y + 0.5) * half).distance_to(centre) <= r:
						covered[Vector2i(x, y)] = true
	var edges := PackedVector2Array()
	var size := Vector2(half, half)
	for c: Vector2i in covered:
		var at := Vector2(c) * half
		draw_rect(Rect2(at, size), Color(LINE, FILL_ALPHA))
		if not covered.has(c + Vector2i.UP):
			edges.append_array([at, at + Vector2(half, 0)])
		if not covered.has(c + Vector2i.DOWN):
			edges.append_array([at + Vector2(0, half), at + size])
		if not covered.has(c + Vector2i.LEFT):
			edges.append_array([at, at + Vector2(0, half)])
		if not covered.has(c + Vector2i.RIGHT):
			edges.append_array([at + Vector2(half, 0), at + size])
	if not edges.is_empty():
		draw_multiline(edges, Color(LINE, EDGE_SOFT_ALPHA), 6.0)  # The soft halo of the outline
		draw_multiline(edges, Color(LINE, LINE_ALPHA), 2.0)
	for tower in towers:  # The Wardens it is measured from: a small glow at the base
		var base := to_local(tower.global_position) + Vector2(0, half * 0.5)
		for i in GLOW_RINGS:
			draw_circle(base, half * (0.75 - 0.2 * i), Color(LINE, HOME_ALPHA * (i + 1) / float(GLOW_RINGS)))
