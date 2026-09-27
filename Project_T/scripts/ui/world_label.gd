class_name WorldLabel

# Small text tags drawn in world space (hover costs, "+3 Dew" popups). Call from a CanvasItem's _draw().

const FONT_SIZE := 14
const BACKGROUND := Color(0.1, 0.1, 0.12, 0.75)
const AFFORDABLE_COLOR := Color.WHITE
const UNAFFORDABLE_COLOR := Color(1.0, 0.5, 0.45)

# Draws `text` on a dark tag, horizontally centred on `center_x`, with its baseline at `baseline_y`.
static func draw_tag(canvas: CanvasItem, center_x: float, baseline_y: float, text: String,
		color: Color = AFFORDABLE_COLOR) -> void:
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var origin := Vector2(center_x - size.x / 2, baseline_y)
	canvas.draw_rect(Rect2(origin + Vector2(-6, -size.y), size + Vector2(12, 6)), BACKGROUND)
	canvas.draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)

# Text colour for a price the player can / can't currently pay.
static func cost_color(affordable: bool) -> Color:
	return AFFORDABLE_COLOR if affordable else UNAFFORDABLE_COLOR
