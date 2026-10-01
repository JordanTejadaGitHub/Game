extends PanelContainer
class_name CardDiagram

# A placement card's map picture (dream_design.md "Placement cards show a diagram"): a 7×5 mini grid from
# the card's `diagram` text (legend on UpgradeData.diagram) and its one-line caption, in the Moonlit style.
# One shared view: the Dream offer shows it beside the hovered card; Dreams this run and the Codex can use
# CardDiagram.make(card) too. Built in code.

const CELL := 20.0
const COLS := 7
const ROWS := 5
const HIGHLIGHT := "+123456789*XQ"  # Characters outlined in gold

var card: UpgradeData
var _rows: PackedStringArray = []
var _grid := Control.new()

# The view for `card`, or null when the card has no diagram.
static func make(for_card: UpgradeData) -> CardDiagram:
	if for_card == null or for_card.diagram.strip_edges() == "":
		return null
	var view := CardDiagram.new()
	view.card = for_card
	return view

static func has_diagram(for_card: UpgradeData) -> bool:
	return for_card != null and for_card.diagram.strip_edges() != ""

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.panel_in(Palette.GOLD))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_rows = card.diagram.strip_edges().split("\n")
	_grid.custom_minimum_size = Vector2(COLS * CELL, ROWS * CELL)
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.draw.connect(_draw_grid)
	box.add_child(_grid)
	if card.diagram_caption != "":
		var caption := Label.new()
		caption.text = IconInfo.format(card.diagram_caption)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.custom_minimum_size = Vector2(COLS * CELL, 0)
		caption.add_theme_font_size_override("font_size", 15)
		caption.add_theme_color_override("font_color", UiStyle.INK)
		caption.name = "Caption"
		box.add_child(caption)

# The character at column `x`, row `y` ("." past the text).
func cell_at(x: int, y: int) -> String:
	if y >= _rows.size() or x >= _rows[y].length():
		return "."
	return _rows[y][x]

func _draw_grid() -> void:
	var font := UiStyle.number_font()
	for y in ROWS:
		for x in COLS:
			var c := cell_at(x, y)
			var rect := Rect2(Vector2(x, y) * CELL, Vector2(CELL, CELL))
			var inner := rect.grow(-1.0)
			var centre := rect.get_center()
			var is_path := c == "P" or c == "+" or c.is_valid_int()
			_grid.draw_rect(inner, Palette.PATH if is_path else Palette.DEEPMOSS)
			match c:
				"T", "X":
					_grid.draw_rect(inner.grow(-3.0), Palette.MOSS)
					_grid.draw_rect(inner.grow(-3.0), Palette.LEAF, false, 1.0)
				"O":
					_grid.draw_circle(centre, CELL * 0.33, Palette.STONE)
				"H":
					_grid.draw_circle(centre, CELL * 0.45, Color(Palette.GLOW, 0.35))
					_grid.draw_circle(centre, CELL * 0.3, Palette.GOLD)
				"S":
					_grid.draw_circle(centre, CELL * 0.32, Palette.MIST)
				"W", "Q":
					_grid.draw_circle(centre, CELL * 0.55, Color(Palette.GLOW, 0.25))  # It qualifies: it glows
					_grid.draw_circle(centre, CELL * 0.34, Palette.HEARTLIGHT)
				"a":
					_grid.draw_circle(centre, CELL * 0.3, Palette.MIST)
				"w":
					_grid.draw_circle(centre, CELL * 0.3, Palette.SLATE)  # Doesn't qualify: dimmed, crossed
					var d := CELL * 0.22
					_grid.draw_line(centre - Vector2(d, d), centre + Vector2(d, d), Palette.EMBER, 2.0, true)
					_grid.draw_line(centre + Vector2(-d, d), centre + Vector2(d, -d), Palette.EMBER, 2.0, true)
			if c == "Q":  # On a cleared cell: the stump mark under the outline
				_grid.draw_rect(inner, Color(Palette.DEADWOOD, 0.35), false, 2.0)
			if HIGHLIGHT.contains(c):
				_grid.draw_rect(inner, Palette.GOLD, false, 2.0)
			if c.is_valid_int():  # A numbered route step (Crossroads)
				var text := c
				var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
				_grid.draw_string(font, centre + Vector2(-size.x / 2.0, 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.ROOT)
