class_name WorldLabel

# Small text tags drawn in world space (hover costs, "+3 Dew" popups). Call from a CanvasItem's _draw().
# Zoomed in past 1×, world text keeps its screen size (the camera goes to 2.5×: text would balloon):
# draw_tag does it; other world text can use text_scale() / begin_screen_size() the same way.

const FONT_SIZE := 14
const BACKGROUND := Color(0.1, 0.1, 0.12, 0.75)
const AFFORDABLE_COLOR := Color.WHITE
const UNAFFORDABLE_COLOR := Color(1.0, 0.5, 0.45)

# The scale world text is drawn at so it keeps its size on screen when zoomed in (1 at 1× and when
# zoomed out: tags don't grow as the map shrinks).
static func text_scale(canvas: CanvasItem) -> float:
	var camera := canvas.get_viewport().get_camera_2d() if canvas.is_inside_tree() else null
	return 1.0 / maxf(camera.zoom.x, 1.0) if camera != null else 1.0

# Draws what follows (until end_screen_size) scaled around `anchor` (world px) by text_scale.
static func begin_screen_size(canvas: CanvasItem, anchor: Vector2) -> void:
	var s := text_scale(canvas)
	canvas.draw_set_transform(anchor - anchor * s, 0.0, Vector2(s, s))

static func end_screen_size(canvas: CanvasItem) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Draws `text` on a dark tag, horizontally centred on `center_x`, with its baseline at `baseline_y`.
static func draw_tag(canvas: CanvasItem, center_x: float, baseline_y: float, text: String,
		color: Color = AFFORDABLE_COLOR) -> void:
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var origin := Vector2(center_x - size.x / 2, baseline_y)
	begin_screen_size(canvas, Vector2(center_x, baseline_y))
	canvas.draw_rect(Rect2(origin + Vector2(-6, -size.y), size + Vector2(12, 6)), BACKGROUND)
	canvas.draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
	end_screen_size(canvas)

# Text colour for a price the player can / can't currently pay.
static func cost_color(affordable: bool) -> Color:
	return AFFORDABLE_COLOR if affordable else UNAFFORDABLE_COLOR
