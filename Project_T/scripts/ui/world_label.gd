class_name WorldLabel

# Small text tags drawn in world space (hover costs, "+3 Dew" popups). Call from a CanvasItem's _draw().
# Zoomed in past 1×, world text keeps its screen size (the camera goes to 2.5×: text would balloon):
# draw_tag does it; other world text can use text_scale() / begin_screen_size() the same way.

const FONT_SIZE := 14
const BACKGROUND := Color(UiStyle.FOG, 0.75)
const AFFORDABLE_COLOR := UiStyle.INK
const UNAFFORDABLE_COLOR := UiStyle.POOR  # The palette has no red

# The scale world text is drawn at so it keeps its size on screen when zoomed in: UI-sized (the UI
# scale, UiStyle.apply_ui_scale) at a view zoom of 1× and closer; zoomed out it shrinks with the map.
# The view zoom is the camera's zoom × the UI factor (GameCameraNode keeps the map's size at any UI scale).
static func text_scale(canvas: CanvasItem) -> float:
	if not canvas.is_inside_tree():
		return 1.0
	# The camera and UI factor are looked up once per frame (every label on every nightmare / Warden
	# asks: the lookup per draw was a measurable cost); the zoom itself is read fresh.
	var frame := Engine.get_process_frames()
	if frame != _lookup_frame or not is_instance_valid(_camera):
		_lookup_frame = frame
		_camera = canvas.get_viewport().get_camera_2d()
		var root := canvas.get_tree().root
		_ui = UiStyle.ui_factor(root)  # The total UI scale (canvas_items stretch × the share)
	if _camera == null:
		return 1.0
	return _ui / maxf(_camera.zoom.x * _ui, 1.0)
static var _lookup_frame := -1
static var _camera: Camera2D = null
static var _ui := 1.0

# Draws what follows (until end_screen_size) scaled around `anchor` (world px) by text_scale.
static func begin_screen_size(canvas: CanvasItem, anchor: Vector2) -> void:
	var s := text_scale(canvas)
	canvas.draw_set_transform(anchor - anchor * s, 0.0, Vector2(s, s))

static func end_screen_size(canvas: CanvasItem) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Draws `text` on a dark tag, horizontally centred on `center_x`, with its baseline at `baseline_y`.
# Screen rects world labels keep clear of (an open panel, user: "24 DPS" showing through the see-through Warden
# panel): {key: Rect2 in the viewport's canvas space}. Plain data, so a static is safe.
static var covers := {}

static func set_cover(key: StringName, rect: Rect2, on: bool) -> void:
	if on:
		covers[key] = rect
	else:
		covers.erase(key)

# Whether `local_rect` (in `canvas`'s own space) lies under a cover: don't draw it.
static func covered(canvas: CanvasItem, local_rect: Rect2) -> bool:
	if covers.is_empty() or not canvas.is_inside_tree():
		return false
	var screen := canvas.get_global_transform_with_canvas() * local_rect
	for key in covers:
		if (covers[key] as Rect2).intersects(screen):
			return true
	return false

static func draw_tag(canvas: CanvasItem, center_x: float, baseline_y: float, text: String,
		color: Color = AFFORDABLE_COLOR) -> void:
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var origin := Vector2(center_x - size.x / 2, baseline_y)
	var s := text_scale(canvas)
	if covered(canvas, Rect2(Vector2(center_x, baseline_y) + Vector2(-size.x / 2 - 6, -size.y) * s, (size + Vector2(12, 6)) * s)):
		return  # Under an open panel
	begin_screen_size(canvas, Vector2(center_x, baseline_y))
	canvas.draw_rect(Rect2(origin + Vector2(-6, -size.y), size + Vector2(12, 6)), BACKGROUND)
	canvas.draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
	end_screen_size(canvas)

# Text colour for a price the player can / can't currently pay.
static func cost_color(affordable: bool) -> Color:
	return AFFORDABLE_COLOR if affordable else UNAFFORDABLE_COLOR
