class_name WorldLabel

# Small text tags drawn in world space (hover costs, "+3 Dew" popups). Call from a CanvasItem's _draw().
# Zoomed in past 1×, world text keeps its screen size (the camera goes to 2.5×: text would balloon):
# draw_tag does it; other world text can use text_scale() / begin_screen_size() the same way.

const FONT_SIZE := 14
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

# Screen rects world labels keep clear of (an open panel, user: "24 DPS" showing through the see-through Warden
# panel): {key: Rect2 in the viewport's canvas space}. Plain data, so a static is safe.
static var covers := {}

static func set_cover(key: StringName, rect: Rect2, on: bool) -> void:
	if on:
		covers[key] = rect
	else:
		covers.erase(key)

# A full-screen screen (the pause menu, a choice screen, the results) hides every world label while it shows (user:
# a "Withered Tree" tag and the DPS tags over the pause menu): a cover over the whole screen, keyed by `key`.
const WHOLE_SCREEN := Rect2(-1.0e7, -1.0e7, 2.0e7, 2.0e7)

static func cover_while_visible(screen: Control, key: StringName) -> void:
	screen.visibility_changed.connect(func() -> void: set_cover(key, WHOLE_SCREEN, screen.is_visible_in_tree()))
	screen.tree_exiting.connect(func() -> void: set_cover(key, WHOLE_SCREEN, false))

# Whether `local_rect` (in `canvas`'s own space) lies under a cover: don't draw it.
static func covered(canvas: CanvasItem, local_rect: Rect2) -> bool:
	if covers.is_empty() or not canvas.is_inside_tree():
		return false
	var screen := canvas.get_global_transform_with_canvas() * local_rect
	for key in covers:
		if (covers[key] as Rect2).intersects(screen):
			return true
	return false

# The 1 px outline and the soft halo that replace the tag's box (user-approved "Warden labels" redo, 2026-10-12): a
# label reads over grass, path and Wardens without a rectangle.
const OUTLINE := Palette.DREAD
const OUTLINE_PX := 1
const HALO_PAD := Vector2(12.0, 5.0)  # The halo reaches this far past the text, screen px
static var _halo: GradientTexture2D = null

# Radial: Void 0.8 at the centre, 0.5 at 55%, nothing at the edge. Released at exit (a static texture otherwise crashes
# the exit).
static func _halo_texture() -> GradientTexture2D:
	if _halo == null:
		UiStyle.release_at_exit(func() -> void: _halo = null)
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		gradient.colors = PackedColorArray([Color(Palette.VOID, 0.8), Color(Palette.VOID, 0.5), Color(Palette.VOID, 0.0)])
		_halo = GradientTexture2D.new()
		_halo.gradient = gradient
		_halo.fill = GradientTexture2D.FILL_RADIAL
		_halo.fill_from = Vector2(0.5, 0.5)
		_halo.fill_to = Vector2(1.0, 0.5)
		_halo.width = 64
		_halo.height = 32
	return _halo

# The faint edgeless halo behind a label: `text_rect` is the text's own box (the halo pads it itself).
static func draw_halo(canvas: CanvasItem, text_rect: Rect2) -> void:
	canvas.draw_texture_rect(_halo_texture(), text_rect.grow_individual(HALO_PAD.x, HALO_PAD.y, HALO_PAD.x, HALO_PAD.y), false)

# A string with the 1 px Dread outline under it.
static func draw_outlined(canvas: CanvasItem, font: Font, at: Vector2, text: String, size: int, color: Color) -> void:
	canvas.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, OUTLINE_PX, Color(OUTLINE, color.a))
	canvas.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

# Draws `text` horizontally centred on `center_x`, with its baseline at `baseline_y`: no box, the body font at 14 px in
# the caller's colour, outlined, over the halo. `font` / `size` for a label in another face (the hovered Warden's name).
static func draw_tag(canvas: CanvasItem, center_x: float, baseline_y: float, text: String,
		color: Color = AFFORDABLE_COLOR, font: Font = null, size: int = FONT_SIZE) -> void:
	if font == null:
		font = UiStyle.with_glyphs(UiStyle.body_font())  # UiStyle.dew_amount's icon draws in world tags too
	var extent := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var origin := Vector2(center_x - extent.x / 2, baseline_y)
	var s := text_scale(canvas)
	if covered(canvas, Rect2(Vector2(center_x, baseline_y) + Vector2(-extent.x / 2 - 6, -extent.y) * s, (extent + Vector2(12, 6)) * s)):
		return  # Under an open panel
	begin_screen_size(canvas, Vector2(center_x, baseline_y))
	draw_halo(canvas, Rect2(origin + Vector2(0, -extent.y + 3.0), extent))
	draw_outlined(canvas, font, origin, text, size, color)
	end_screen_size(canvas)

# One placement for every word that pops over a spot in the world (user's screenshot 2026-10-13: "Chain ×3",
# "Starfall ×3" and "Pinned" drawn on top of each other): Reaction callouts and the chain badge (Fx) and the combat
# words (CombatCallouts) all ask here. A word that would land on a live one moves up a line, in a column; the same
# word again at the same spot takes the slot it already has (one label, not three). `at` is where the word's
# middle will be, in world px. Plain data, so a static is safe.
const CALLOUT_CLEAR := Vector2(130.0, 40.0)  # Two words closer than this stack: a line is one Reaction callout tall
const CALLOUT_LINES := 6
static var _callout_slots: Array = []  # [Vector2 at, int expires (msec), StringName key]

static func callout_slot(at: Vector2, key: StringName = &"", seconds: float = 1.0) -> Vector2:
	var now := Time.get_ticks_msec()
	_callout_slots = _callout_slots.filter(func(s: Array) -> bool: return int(s[1]) > now)
	var until := now + int(seconds * 1000.0)
	if key != &"":
		for slot in _callout_slots:
			var held: Vector2 = slot[0]
			if slot[2] == key and absf(held.x - at.x) < CALLOUT_CLEAR.x and absf(held.y - at.y) < CALLOUT_CLEAR.y * CALLOUT_LINES:
				slot[1] = until
				return held  # The same word, here already: its own slot again
	for line in CALLOUT_LINES:
		var taken := false
		for slot in _callout_slots:
			var held: Vector2 = slot[0]
			if absf(held.x - at.x) < CALLOUT_CLEAR.x and absf(held.y - at.y) < CALLOUT_CLEAR.y:
				taken = true
				break
		if not taken:
			break
		at.y -= CALLOUT_CLEAR.y  # Up a line
	_callout_slots.append([at, until, key])
	return at

# Text colour for a price the player can / can't currently pay.
static func cost_color(affordable: bool) -> Color:
	return AFFORDABLE_COLOR if affordable else UNAFFORDABLE_COLOR
