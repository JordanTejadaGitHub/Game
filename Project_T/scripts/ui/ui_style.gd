@tool
class_name UiStyle

# The Moonlit Thread UI style (documentation/ui_style.md): colour tokens, the three fonts, the
# shared style boxes and the project theme built from them. `tools/ui_theme_generator.gd` saves
# make_theme() to assets/ui/ui_theme.tres (the project's gui/theme/custom); re-run it after
# changing anything here. Screens built in code use the helpers below (title(), caps(), number(),
# primary(), card()…) instead of hand-made StyleBoxFlats.

const THEME_PATH := "res://assets/ui/ui_theme.tres"

# Colours (ui_style.md "Colours"): Heartwood 32 (HeartwoodPalette, art_direction.md). Constants so
# other scripts can use them in their own consts; tests/test_ui_style.gd checks each one still equals
# its palette colour (PALETTE_NAMES).
const INK := Color("dce8f4")  # Moonlight: text (Moon-glass; was Heartlight)
const INK_DIM := Color("b4b0c8")  # Mist: labels, secondary text
const GOLD := Color("fcd47c")  # Glow: numbers, threads, links
const BUTTON_GOLD := Color("e9a83c")  # Gold: button outlines, primary fill and glow
const GOLD_TEXT := Color("fff4dc")  # Heartlight: text on primary buttons
const WHISPER := Color("dccdb2")  # Moonpath
const POOR := Color("b8662c")  # Ember: unaffordable (with the 50% fade; the palette has no red)
# Accessibility (UI/UX review 2026-10-26): Ember words were 4.5:1 on glass over Void and 3.3:1 over the path; this lighter
# Ember is 6.5:1 / 5.6:1. Words and numbers in the "short / lost" colour use it; frames and outlines keep POOR.
const POOR_TEXT := Color("d8845a")  # Accessibility
const FOG := Color("05050d")  # Void: panel fog
const CARD_BG := Color("24243c")  # Night: the lit middle of a card, over Void
const BOSS := Color("9a84e8")  # Wraithlight: bosses (the palette has no red; the nightmares' own cold glow)
const LIVE := Color("d4ec9c")  # Newleaf: live bonuses, rewards
const OFF := Color("8c8cac")  # Stone: a bonus that is off right now
const MOONLIGHT := Color("dce8f4")  # Moonlight: the pale disc under nightmare portraits
const MOON_MIST := Color("b4b0c8")  # Mist: the disc's outer ring
const SLATE := Color("5c5a78")  # Slate: a Warden slot you can't afford (its border)
const RARITY := [Color("b4b0c8"), Color("9cc46c"), Color("9cd4fc"), Color("e9a83c")]  # Mist, Sprig, Dewlight, Gold
const PALETTE_NAMES := {"INK": "Moonlight", "INK_DIM": "Mist", "GOLD": "Glow", "BUTTON_GOLD": "Gold",
	"GOLD_TEXT": "Heartlight", "WHISPER": "Moonpath", "POOR": "Ember", "FOG": "Void", "CARD_BG": "Night",
	"BOSS": "Wraithlight", "LIVE": "Newleaf", "OFF": "Stone",
	"MOONLIGHT": "Moonlight", "MOON_MIST": "Mist", "SLATE": "Slate"}
const RARITY_NAMES := ["Mist", "Sprig", "Dewlight", "Gold"]
const DISABLED_ALPHA := 0.45
const UNAFFORDABLE_ALPHA := 0.5

# Sizes at 1280×800 (ui_style.md gives them at 1920×1080; the UI scale setting multiplies all of them).
const BODY_SIZE := 16
const LABEL_SIZE := 14
const TITLE_SIZE := 24
const NUMBER_SIZE := 24
const CARD_NAME_SIZE := 24
const CHOICE_TITLE_SIZE := 32
const BUTTON_SIZE := 18
# One HUD scale (user, 2026-09-30: "the UI looks bigger than the tower bar"): every HUD control is
# HUD_BUTTON_H tall with HUD_TEXT_SIZE small caps (HudButton / HudPrimary), and the Warden bar slots
# are the same frame, HUD_SLOT big. The UI scale setting scales them all together.
const HUD_BUTTON_H := 48.0
const HUD_TEXT_SIZE := 16
const HUD_SLOT := Vector2(64, 78)  # A Warden bar slot: 48 px sprite + the cost
const HUD_SPRITE := 48
# Tooltips, hover panels and tap popups (screens_ui.md playtest fixes 2026-09-30: "too small"): body
# ≥16 px, names 18 px, ~1.35 line height, at most ~42 characters wide; scaled by the UI scale like
# everything else. Small caps only for labels, never sentences.
const TIP_SIZE := 16
const TIP_NAME_SIZE := 18
const TIP_LINE_SPACING := 4  # Extra px between lines: ~1.35 line height at 16 px
const TIP_WIDTH := 330.0  # ~42 characters of the body face at TIP_SIZE

const FONT_DIR := "res://assets/ui/fonts/"

# Resource glyphs (user via Main Merger 2026-10-06: every price or reward is the resource icon and the number,
# never "15 Dew"): private-use characters that the glyph font (tools/ui_glyph_font_generator.gd) draws as the
# icons.png art, a fallback of every theme face, so plain Labels, Buttons and tooltips show them. [char, icon id]
const DEW_GLYPH := ""
const DREAMLIGHT_GLYPH := ""
const SEEDS_GLYPH := ""
const GLYPHS := [[0xE000, "dew"], [0xE001, "dreamlight"], [0xE002, "seeds"]]
const GLYPH_FONT_PATH := "res://assets/ui/fonts/heartwood_glyphs.res"

# "15" with the Dew icon first; signed: "+30" / "-5" (the number keeps its own colour: GOLD, or POOR when short).
static func dew_amount(amount: int, signed: bool = false) -> String:
	return DEW_GLYPH + _signed(amount, signed)

static func dreamlight_amount(amount: int, signed: bool = false) -> String:
	return DREAMLIGHT_GLYPH + _signed(amount, signed)

static func seeds_amount(amount: int, signed: bool = false) -> String:
	return SEEDS_GLYPH + _signed(amount, signed)

static func _signed(amount: int, signed: bool) -> String:
	return ("+%d" % amount) if signed and amount >= 0 else str(amount)

static var _fonts := {}

# --- UI scale ----------------------------------------------------------------------------------

# The HUD is laid out for at least this much room (screens_ui.md: 1280×800 is the base, 16:9 needs
# 1280×720). The UI never scales past what leaves it this much, so it can't overlap itself.
# Phones lay out for PHONE_LAYOUT_MIN instead (layout_min(), below): LAYOUT_MIN is the PC and tablet base.
const LAYOUT_MIN := Vector2(1280.0, 720.0)
const UI_SHARE_MIN := 0.5  # The settings slider: 50% … 100% of the fitting scale
const UI_SHARE_MAX := 1.0
# The settings dropdown's choices (user, 2026-10-01: a dropdown, not a slider): [name, share].
const UI_SIZES := [["Small", 0.6], ["Medium", 0.75], ["Large", 0.9], ["Largest (fits the screen)", 1.0]]
# Phones: only two (user 2026-10-15, Mobile UI); smaller ones made text and buttons too small to read and hit.
# UI Asset's review 2026-10-17: on a phone neither size shrinks type. Both draw the UI at the full fitting scale; Standard
# only tightens the HUD's padding, gaps and panel widths for more map (phone_compact()), Large keeps the roomy spacing.
# User 2026-10-21 ("I used 2 different UI sizes but they seem the same"): Standard now also draws everything at
# PHONE_STANDARD_SCALE of the fitting scale, so the two read as two sizes; Large stays the full scale.
const PHONE_UI_SIZES := [["Standard (more map)", 0.9], ["Large (roomier)", 1.0]]
const PHONE_STANDARD_SCALE := 0.92  # 48 × 0.92 = 44.2 px: every button stays a 44 px tap (0.9 drew 43.2; UI review 2026-10-26)
static var _phone_compact := false

# Phones at Standard: HUD layouts read this for their tighter spacing (text sizes never change).
static func phone_compact() -> bool:
	return _phone_compact and is_phone()

# The size choices this device offers (the settings dropdown).
static func ui_sizes() -> Array:
	return PHONE_UI_SIZES if is_phone() else UI_SIZES

# A saved share on a phone snaps to the nearest of its two sizes (a PC-sized 0.6 becomes 0.9).
static func phone_share(share: float) -> float:
	return 1.0 if share >= 0.95 else PHONE_STANDARD_SCALE

static var _scale_share := 1.0

# Phones (mobile only; Mobile chat, mobile_plan.md "Phone layouts"): at the PC base a 48-unit button is ~4–5 mm on a
# phone. The phone base is smaller, so everything draws ~1.3× bigger: 1200×540 on a 20:9 phone, 1100×619 on 16:9.
# Every screen is checked at those (tests/test_phone_layout.gd). Tablets (short side ≥ TABLET_INCHES) keep the PC base.
const PHONE_LAYOUT_MIN := Vector2(1100.0, 540.0)
const TABLET_INCHES := 4.5
const PHONE_ASPECT := 1.85  # Long side over short side: at or past it, a phone

static func is_phone() -> bool:
	if not TouchBuild.mobile_controls():
		return false
	if not OS.has_feature("mobile"):
		return true  # `-- --mobile` / tests on a PC preview the phone base
	var dpi := DisplayServer.screen_get_dpi()
	var screen := DisplayServer.screen_get_size()
	var short_side := minf(screen.x, screen.y)
	# A phone's long screen (19.5:9 and the like) is a phone whatever DPI Android reports: at start-up it can report a
	# placeholder, which made a phone look like a tablet when the HUD was built (Mobile UI 2026-10-25: no Sell / Select /
	# Start, the Dream icons on the leaves). Tablets are 4:3 to 16:10.
	if short_side > 0.0 and maxf(screen.x, screen.y) / short_side >= PHONE_ASPECT:
		return true
	if dpi <= 72:
		return short_side <= 1200.0  # Some Android builds report 0 or 72: judge by pixels (UI Code)
	return short_side / float(dpi) < TABLET_INCHES

# The room the UI is laid out for on this device: LAYOUT_MIN, or PHONE_LAYOUT_MIN on a phone.
static func layout_min() -> Vector2:
	return PHONE_LAYOUT_MIN if is_phone() else LAYOUT_MIN

# A real phone's unsafe edges (notch, rounded corners) in view units: left / top in `position`, right / bottom in
# `size`. Empty anywhere else (PC, `--mobile` previews, headless).
static func safe_insets(view: Vector2) -> Rect2:
	var cut := _cutout_insets(view)
	if not cut.is_empty():
		return cut.corners
	if not OS.has_feature("mobile"):
		return Rect2()
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := DisplayServer.get_display_safe_area()
	var window := Vector2(DisplayServer.window_get_size())
	if screen.x <= 0.0 or safe.size.x <= 0 or window.x <= 0.0:
		return Rect2()
	# Only the unsafe edges inside the game's window (user 2026-10-18: "a lot of empty space on the left"): when Android
	# already keeps the window clear of the cutout (a black bar beside it, the window narrower than the screen), that
	# side needs no inset; counting it again pushed the whole HUD in and shrank it.
	var near := Vector2(safe.position)
	var far := screen - Vector2(safe.end)
	if window.x < screen.x - 1.0:
		near.x = 0.0
		far.x = 0.0
	if window.y < screen.y - 1.0:
		near.y = 0.0
		far.y = 0.0
	var k := view.x / window.x
	return Rect2(near * k, far * k)

# Phones with a punch-hole camera (user 2026-10-21: "the Wardens and Sell and Select are positioned differently": the
# whole HUD sat ~50 px in from the left because Android calls the whole camera strip unsafe). From the real cutout
# rects: a cutout reaching a side's top or bottom CORNER_BAND moves the HUD's corners (`corners`, as safe_insets); a
# hole in the middle of a side leaves the corners on the screen's edge and only `side` (left, right, view units, with
# HOLE_GAP) for what reaches the middle of that side: full-screen pages and a left-docked Warden drawer (hud.gd
# _fit_side_holes). {} when the device reports no cutouts (then the safe area as before).
const CORNER_BAND := 0.25  # Of the screen's height: a cutout inside the middle half is a mid-side hole
const HOLE_GAP := 8.0
static var test_cutouts: Array = []  # Captures and tests: cutout rects in window px (a phone reports them itself)

static func _cutout_insets(view: Vector2) -> Dictionary:
	var rects: Array = test_cutouts
	if rects.is_empty() and OS.has_feature("mobile"):
		rects = DisplayServer.get_display_cutouts()
	var window := Vector2(DisplayServer.window_get_size())
	if rects.is_empty() or window.x <= 0.0:
		return {}
	var screen := Vector2(DisplayServer.screen_get_size()) if test_cutouts.is_empty() else window
	var k := view.x / window.x
	var near := Vector2.ZERO
	var far := Vector2.ZERO
	var side := Vector2.ZERO
	for r: Rect2 in rects:
		var mid := r.position.y > screen.y * CORNER_BAND and r.end.y < screen.y * (1.0 - CORNER_BAND)
		if r.position.x < screen.x * 0.25 and window.x >= screen.x - 1.0:  # The left side (and the window reaches it)
			if mid:
				side.x = maxf(side.x, r.end.x * k + HOLE_GAP)
			else:
				near.x = maxf(near.x, r.end.x * k)
		elif r.end.x > screen.x * 0.75 and window.x >= screen.x - 1.0:
			if mid:
				side.y = maxf(side.y, (screen.x - r.position.x) * k + HOLE_GAP)
			else:
				far.x = maxf(far.x, (screen.x - r.position.x) * k)
		elif r.position.y < screen.y * 0.25 and window.y >= screen.y - 1.0:
			near.y = maxf(near.y, r.end.y * k)
		elif r.end.y > screen.y * 0.75 and window.y >= screen.y - 1.0:
			far.y = maxf(far.y, (screen.y - r.position.y) * k)
	return {"corners": Rect2(near, far), "side": side}

# The safe area's left and right insets in view units, from the device alone (a phone's camera side, rounded corners),
# whatever the cutout rects say: full-screen pages keep clear of them (hud.gd page_pad). Vector2.ZERO off phones.
static var test_safe_sides := Vector2.ZERO  # Captures and tests

static func safe_sides(view: Vector2) -> Vector2:
	if test_safe_sides != Vector2.ZERO:
		return test_safe_sides
	if not OS.has_feature("mobile"):
		return Vector2.ZERO
	var window := Vector2(DisplayServer.window_get_size())
	var safe := DisplayServer.get_display_safe_area()
	var screen := Vector2(DisplayServer.screen_get_size())
	if window.x <= 0.0 or safe.size.x <= 0 or window.x < screen.x - 1.0:
		return Vector2.ZERO  # Android already keeps the window clear (letterboxed)
	var k := view.x / window.x
	return Vector2(maxf(0.0, safe.position.x) * k, maxf(0.0, screen.x - safe.end.x) * k)

# The mid-side holes (left, right) in view units: Vector2.ZERO without any.
static func side_holes(view: Vector2) -> Vector2:
	var cut := _cutout_insets(view)
	return cut.side if not cut.is_empty() else Vector2.ZERO

# Fits a full-screen layer (the HUD) into the safe part of `view`: one uniform scale, centred in the safe rect, so
# nothing sits under a notch. Identity when nothing is unsafe.
static func safe_transform(view: Vector2, insets: Rect2) -> Transform2D:
	if insets.position == Vector2.ZERO and insets.size == Vector2.ZERO:
		return Transform2D.IDENTITY
	var room := view - insets.position - insets.size
	var s := minf(room.x / view.x, room.y / view.y)
	var origin := insets.position + (room - view * s) / 2.0
	return Transform2D(0.0, Vector2(s, s), 0.0, origin)

# The root's content scale for a window of `window_size` pixels: the largest scale that still leaves
# LAYOUT_MIN (1.5 at 1920×1080, 1 at 1280×800, 2 at 4K), times the player's `share` of it.
static func ui_scale_factor(window_size: Vector2, share: float) -> float:
	var fit := clampf(minf(window_size.x / LAYOUT_MIN.x, window_size.y / LAYOUT_MIN.y), 0.5, 4.0)
	return fit * clampf(share, UI_SHARE_MIN, UI_SHARE_MAX)

# Applies the "ui_scale" setting (a share, see above) to the window, and again whenever the window
# changes size. Only the UI grows: GameCameraNode divides its zoom by the factor, so the map keeps
# its size. Headless runs (tests) stay at 1 so layouts are checked at the sizes they set.
static func apply_ui_scale(root: Window, share: float) -> void:
	_phone_compact = is_phone() and phone_share(share) < 0.95
	_scale_share = phone_share(share) if is_phone() else share  # Phones: Standard draws smaller too (user 2026-10-21)
	if root == null:
		return
	install_text_filter(root.get_tree() if root.is_inside_tree() else Engine.get_main_loop() as SceneTree)
	if DisplayServer.get_name() == "headless":
		root.content_scale_factor = 1.0
		return
	_set_factor(root)  # Godot re-fits on every resize by itself
	install_cursor(root)

# The mouse cursor in the Moon-glass style (user 2026-10-21: "update the cursor to match the theme"): a pixel arrow in
# Moonlight with a lit Heartlight edge, a clean 2 px Mist stalk for its tail (art council 2026-10-24), a Glow glint at
# the tip and a crisp Void outline (reads on the path and the dark ground), drawn in whole art pixels at ×2, ×3 or ×4
# with the UI. The pointing hand gets the same arrow (no stray system hand over buttons). Phones and headless runs keep
# none. A new texture each time: Input holds it, nothing static.
const CURSOR := ["k...........", "kk..........", "kYk.........", "kWwk........", "kWwwk.......", "kWwwwk......",
	"kWwwwwk.....", "kWwwwwwk....", "kWwwwwwwk...", "kWwwwwwwwk..", "kWwwwwwwwwk.", "kWwwwkkkkkkk", "kWwwkGk.....",
	"kWwkkGGk....", "kWk.kGGk....", "kk...kGGk...", "k....kGGk...", "......kGGk..", ".......kk..."]
const CURSOR_INKS := {"k": Palette.VOID, "W": Palette.HEARTLIGHT, "w": Palette.MOONLIGHT, "G": Palette.MIST, "Y": Palette.GLOW}
static var _cursor_scale := 0
static func install_cursor(root: Window) -> void:
	if root == null or DisplayServer.get_name() == "headless" or TouchBuild.mobile_controls():
		return
	var px := clampi(roundi(2.0 * maxf(ui_factor(root), 1.0)), 2, 4)
	if px == _cursor_scale:
		return
	_cursor_scale = px
	var image := Image.create_empty(CURSOR[0].length() * px, CURSOR.size() * px, false, Image.FORMAT_RGBA8)
	for y in CURSOR.size():
		var row: String = CURSOR[y]
		for x in row.length():
			if CURSOR_INKS.has(row[x]):
				image.fill_rect(Rect2i(x * px, y * px, px, px), CURSOR_INKS[row[x]])
	var texture := ImageTexture.create_from_image(image)
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND]:
		Input.set_custom_mouse_cursor(texture, shape, Vector2.ZERO)  # The hotspot is the tip, top left

# Text draws with a linear filter, pixel art keeps the project's Nearest. At a fractional UI scale the
# glyphs (rasterized at the oversampled size) never match the screen exactly, and Nearest dropped thin
# strokes ("Poisc ned", "over t me", 2026-10-02). Every text control added to the tree gets
# TEXTURE_FILTER_LINEAR unless it chose a filter itself; Buttons only when they have no icon (an icon
# may be pixel art: set its filter where you set the icon). Existing controls are swept once.
static var _text_filter_tree: SceneTree = null
static func install_text_filter(tree: SceneTree) -> void:
	if tree == null or _text_filter_tree == tree:
		return
	_text_filter_tree = tree
	tree.node_added.connect(_linear_text)
	tree.node_added.connect(_watch_marks)
	tree.node_added.connect(_text_floor)  # PC too (UI review 2026-10-26: 12-13 px text on about 25 screens)
	if tree.root != null:
		for node in tree.root.find_children("*", "Control", true, false):
			_linear_text(node)

# Phones (Mobile UI council 2026-10-25: secondary text under 13 px, about 9 px at Standard): no text control draws
# smaller than PHONE_MIN_TEXT screen px at either UI size; a smaller size set on it is raised (checked after it's built).
const PHONE_MIN_TEXT := 15.0  # Was 13 (UI review 2026-10-26, owner "Fix": ~9.5 pt, under the 11 pt platform floor)
# PC (UI/UX review 2026-10-26): no text smaller than MIN_TEXT (LABEL_SIZE); the player's UI size still scales it.
const MIN_TEXT := LABEL_SIZE

static func _text_floor(node: Node) -> void:
	if node is Label or node is Button or node is RichTextLabel:
		_apply_text_floor.call_deferred(node)

static func _apply_text_floor(node: Control) -> void:
	if not is_instance_valid(node):
		return
	var key := &"normal_font_size" if node is RichTextLabel else &"font_size"
	var floor_px := ceili(PHONE_MIN_TEXT / maxf(_scale_share, 0.5)) if is_phone() else MIN_TEXT
	if node.get_theme_font_size(key) < floor_px:
		node.add_theme_font_size_override(key, floor_px)

static func _linear_text(node: Node) -> void:
	if not (node is Control) or (node as CanvasItem).texture_filter != CanvasItem.TEXTURE_FILTER_PARENT_NODE:
		return
	var is_text := node is Label or node is RichTextLabel or node is LineEdit or node is TextEdit
	if is_text or (node is Button and (node as Button).icon == null):
		(node as CanvasItem).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

# One Heartwood mark per group (the user, 2026-10-05: "redundant sprout"): a panel's thread mark or a
# divider's mark is dropped when a primary button (which has its own mark) sits right below it. Checked
# on the control's first draw, after layout, against the primary's real position.
const MARK_STACK_PANEL := 48.0  # A primary whose top is this close under a panel's top edge
const MARK_STACK_DIVIDER := 40.0  # ... or this close under a divider
const PRIMARY_VARIATIONS := [&"PrimaryButton", &"HudPrimary"]

static func _watch_marks(node: Node) -> void:
	if node is PanelContainer or node is Panel or node is TabContainer or node is HSeparator:
		# Two frames after it joins the tree: containers have placed their children by then (frame-based,
		# not `draw`, so it also runs headless).
		# One queue drained by a single process_frame callback: Godot treats bound copies of one callable
		# as the same connection, so a per-node connect dropped every node after the first in a frame.
		_mark_queue.append([node, 2])
		var tree := node.get_tree()
		if not tree.process_frame.is_connected(_drain_marks):
			tree.process_frame.connect(_drain_marks)

static var _mark_queue: Array = []  # [node, frames left]; plain node references, never resources

static func _drain_marks() -> void:
	var due: Array = []
	var waiting: Array = []
	for entry in _mark_queue:
		if not is_instance_valid(entry[0]):
			continue
		if entry[1] <= 1:
			due.append(entry[0])
		else:
			waiting.append([entry[0], entry[1] - 1])
	_mark_queue = waiting
	for node in due:
		if (node as Node).is_inside_tree():
			_unstack_mark(node)
	if _mark_queue.is_empty():
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.process_frame.is_connected(_drain_marks):
			tree.process_frame.disconnect(_drain_marks)

static func _unstack_mark(control: Control) -> void:
	if not is_instance_valid(control) or not control.is_inside_tree():
		return
	var is_panel := control is PanelContainer or control is Panel or control is TabContainer
	var box := control.get_theme_stylebox("panel" if is_panel else "separator")
	var panel_marked := box is MoonStyleBox and (box as MoonStyleBox).thread != MoonStyleBox.TopLine.NONE \
		and (box as MoonStyleBox).diamond
	var marked := panel_marked or (box is MoonDivider and (box as MoonDivider).mark)
	if not marked:
		return
	# One sprout per screen (ui_style.md, 2026-10-05: "too many redundant sprout icons"): a panel or divider
	# inside a panel that already draws a thread keeps a plain thread. Framed primary buttons keep theirs
	# (they aren't panels), and stand-alone HUD panels have no threaded ancestor.
	if _inside_threaded_panel(control):
		_drop_mark(control, box, is_panel)
		return
	var rect := control.get_global_rect()
	var line_y := rect.position.y if is_panel else rect.get_center().y
	var scope: Node = control if is_panel else control.get_parent()
	var reach := MARK_STACK_PANEL if is_panel else MARK_STACK_DIVIDER
	for button in scope.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and (button as Control).theme_type_variation in PRIMARY_VARIATIONS:
			var gap := (button as Control).get_global_rect().position.y - line_y
			if gap >= -1.0 and gap <= reach:
				_drop_mark(control, box, is_panel)
				return

static func _drop_mark(control: Control, box: StyleBox, is_panel: bool) -> void:
	var plain := box.duplicate() as StyleBox
	if plain is MoonStyleBox:
		(plain as MoonStyleBox).diamond = false
	else:
		(plain as MoonDivider).mark = false
	control.add_theme_stylebox_override("panel" if is_panel else "separator", plain)

static func _inside_threaded_panel(control: Control) -> bool:
	var up := control.get_parent()
	while up != null:
		if up is PanelContainer or up is Panel or up is TabContainer:
			var outer := (up as Control).get_theme_stylebox("panel")
			if outer is MoonStyleBox and (outer as MoonStyleBox).thread != MoonStyleBox.TopLine.NONE:
				return true
		up = up.get_parent()
	return false

# Godot's own canvas_items stretch does the fitting: base size LAYOUT_MIN with aspect "expand" scales
# by min(window / LAYOUT_MIN) (= ui_scale_factor's fit) and content_scale_factor = the share. Unlike a
# bare content_scale_factor (stretch "disabled"), this mode oversamples fonts: glyphs rasterize at
# their on-screen size instead of being scaled through the project's Nearest filter (jagged, strokes
# lost: "Seeds" read "Seecs", 2026-09-30).
static func _set_factor(root: Window) -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(layout_min())  # Phones: the smaller phone base
	root.content_scale_factor = clampf(_scale_share, UI_SHARE_MIN, UI_SHARE_MAX)

# The total scale everything is drawn at (the stretch times the share), for the camera.
static func ui_factor(root: Window) -> float:
	if root == null:
		return 1.0
	if root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS and root.content_scale_size.x > 0:
		var fit := minf(float(root.size.x) / root.content_scale_size.x, float(root.size.y) / root.content_scale_size.y)
		return fit * root.content_scale_factor
	return root.content_scale_factor if root.content_scale_factor > 0.0 else 1.0

# --- Fonts -------------------------------------------------------------------------------------

# The type (ui_style.md "Moon-glass" type table, UI Asset 25655e77; user 2026-10-21: "different text fonts everywhere"):
# TWO families, one job each, nothing else in the game.
# - Pixelify Sans SemiBold (display_font): screen and panel titles, Warden / card / nightmare names, toasts. Never numbers,
#   never button labels.
# - Vollkorn Regular (body_font): body, descriptions, tooltips, sub-lines (14 px at least, never bold); its italic for
#   whispers (whisper_font).
# - Vollkorn SC SemiBold (caps_font): every button label (primaries too), tab, label, chip and key hint.
# - Vollkorn Medium with lining + tabular figures (number_font): every number (counters, costs, stats, DPS, timers).
# Every UI face is a FontVariation with SPACE_EXTRA: with subpixel positioning off (even letters at fractional UI scales),
# a space's advance rounds down to 0–1 px at some scales and words ran together ("Asmall splash", 2026-10-02); one extra
# pixel keeps every word gap visible. Each falls back to the resource glyphs (DEW_GLYPH…), then the body face.
const SPACE_EXTRA := 1
const BODY_LINE_EXTRA := 3  # Px between lines of body text (16 px Vollkorn: ~1.4 line height)
static func body_font() -> Font:
	return _face("body", "Vollkorn-Variable.ttf", 400)

# Vollkorn Medium: what used to be the body's medium (RichTextLabel [b], world tags). The body itself is never bold.
static func body_medium_font() -> Font:
	return _face("body_medium", "Vollkorn-Variable.ttf", 500)

# A Vollkorn / Pixelify face: `weight` on the variable font (0 = a static file), optional lining + tabular figures, a
# little tracking for small caps.
static func _face(key: String, file: String, weight: int, figures := false, tracking := 0) -> Font:
	if not _fonts.has(key):
		if _fonts.is_empty():
			release_at_exit(func() -> void: _fonts.clear())
		var ts := TextServerManager.get_primary_interface()
		var font := FontVariation.new()
		font.base_font = _file(file)
		if weight > 0:
			font.variation_opentype = {ts.name_to_tag("wght"): weight}
		var features := {ts.name_to_tag("lnum"): 1}  # Lining figures everywhere (Vollkorn's default is old-style)
		if figures:
			features[ts.name_to_tag("tnum")] = 1
		font.opentype_features = features
		font.spacing_space = SPACE_EXTRA
		font.spacing_glyph = tracking
		var fallbacks: Array[Font] = []
		var glyphs := glyph_font()
		if glyphs != null:
			fallbacks.append(glyphs)  # The resource icons in "15 [Dew]" amounts
		if key != "body":
			fallbacks.append(body_font())  # Symbols a face lacks (✧, ⏎, accents…)
		font.fallbacks = fallbacks
		_fonts[key] = font
	return _fonts[key]

# `font` with the resource glyphs as its fallback (cached per font), for text drawn outside the theme: the world tags
# (WorldLabel.draw_tag) draw "+15" Dew popups and map prices with the engine's fallback font.
static func with_glyphs(font: Font) -> Font:
	var glyphs := glyph_font()
	if glyphs == null or font == null:
		return font
	var key := "glyphs:%d" % font.get_instance_id()
	if not _fonts.has(key):
		var variation := FontVariation.new()
		variation.base_font = font
		variation.fallbacks = [glyphs]
		if font is FontVariation:  # A wrapper drops its base's features: Vollkorn's old-style 1 read as a small-caps "I"
			var inner := font as FontVariation  # (UI council round 4, Remember's "Dreamlight ♦ I")
			variation.opentype_features = inner.opentype_features
			variation.variation_opentype = inner.variation_opentype
			variation.spacing_space = inner.spacing_space
			variation.spacing_glyph = inner.spacing_glyph
		_fonts[key] = variation
	return _fonts[key]

# The resource glyph font (DEW_GLYPH…), or null before tools/ui_glyph_font_generator.gd has made it.
static func glyph_font() -> Font:
	if not _fonts.has("glyphs"):
		if _fonts.is_empty():
			release_at_exit(func() -> void: _fonts.clear())
		_fonts["glyphs"] = load(GLYPH_FONT_PATH) if ResourceLoader.exists(GLYPH_FONT_PATH) else null
	return _fonts["glyphs"]

# Pixelify Sans SemiBold: titles and names. Never numbers (draw_display swaps in the number face), button labels or toasts.
static func display_font() -> Font:
	return _face("display", "PixelifySans-Variable.ttf", 600)

# Vollkorn Medium, lining + tabular figures: every number (Pixelify's digits blurred shut at HUD sizes: "the 2 looks too
# much like an 8", user 2026-10-20).
static func number_font() -> Font:
	return _face("number", "Vollkorn-Variable.ttf", 500, true)

# Vollkorn SC SemiBold: every button label, tab, label, chip and key hint (small caps, a little tracking).
static func caps_font() -> Font:
	return _face("caps", "VollkornSC-SemiBold.ttf", 0, true, 1)

# Vollkorn Italic: Heartwood whispers.
static func whisper_font() -> Font:
	return _face("whisper", "Vollkorn-Italic-Variable.ttf", 400)
# A static cache that holds engine objects (fonts, textures, resources with textures) must let go of them
# before the servers shut down at quit, or Godot can crash on exit (headless tests: PASS, then exit 139).
# Call this when the cache is first filled: `clear` runs once, when the root leaves the tree.
static func release_at_exit(clear: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.tree_exiting.connect(clear, CONNECT_ONE_SHOT)

static func _file(file: String) -> Font:
	if _fonts.is_empty():
		release_at_exit(func() -> void: _fonts.clear())
	if not _fonts.has(file):
		_fonts[file] = load(FONT_DIR + file)
	return _fonts[file]

# --- Style boxes -------------------------------------------------------------------------------

# Moon-glass (ui_style.md "Moon-glass", 2026-10-20): every main panel is the panel_main plate (Warden drawer, drift panel,
# Dream cards, pause rail, results), its rim sprout kept only on the one main panel per screen (the mark rules below).
static func panel(margin_x: float = 16.0, margin_y: float = 12.0) -> MoonStyleBox:
	var box := MoonStyleBox.new()
	box.frame = &"panel_main"
	_margins(box, margin_x, margin_y)
	return box

# A small plate (buttons, rows, slots, tags, toasts, tooltips): `frame` is its metal. Brass (hover, pressed, yours) keeps
# the soft gold glow; every plate casts a soft drop shadow except a pressed one. Never a sprout.
const PLATE_MIN_MARGIN := Vector2(7.0, 5.0)  # A plate's 4 px rim plus air
static func plate_box(margin_x: float = 14.0, margin_y: float = 6.0, frame: StringName = &"plate") -> MoonStyleBox:
	var box := MoonStyleBox.new()
	box.frame = frame
	box.thread = MoonStyleBox.TopLine.NONE
	box.glow = frame in MoonStyleBox.BRASS and frame != &"plate_pressed"
	box.drop_shadow = frame != &"plate_pressed"
	# Never inside the 4 px rim (Mobile UI 2026-10-21: chips at margin_y 1-2 drew their text on the rim, "every 10 s" clipped)
	_margins(box, maxf(margin_x, PLATE_MIN_MARGIN.x), maxf(margin_y, PLATE_MIN_MARGIN.y))
	if frame == &"plate_pressed":  # Pushed in: the content moves down 2 px
		box.content_margin_top += 2.0
		box.content_margin_bottom = maxf(box.content_margin_bottom - 2.0, 0.0)
	return box

# Tips (native tooltips, TapTip, status / term popups): a plate (its glass is ~86% Dread, so the text never fights what's
# under it; user: "I can barely read them once they're hovering over text").
const TIP_ALPHA := 0.95
static func tip_panel() -> MoonStyleBox:
	return plate_box(12.0, 8.0)

# One CanvasLayer above every panel, screen and HUD layer for tips (created once per tree).
const TIP_LAYER := 120
static func tip_layer(tree: SceneTree) -> CanvasLayer:
	var layer := tree.root.get_node_or_null("TipLayer") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "TipLayer"
		layer.layer = TIP_LAYER
		layer.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child(layer)  # At input time (a tip shown); install_tooltip_wrap makes it early, deferred
	return layer

# Lifts `tip` (a top-level Control) onto the tip layer while it shows; it's freed with `host`.
static func lift_tip(tip: Control, host: Node) -> void:
	if not tip.is_inside_tree() or host == null or not host.is_inside_tree():
		return
	var layer := tip_layer(tip.get_tree())
	if not layer.is_inside_tree() or tip.get_parent() == layer:
		return
	tip.reparent(layer, false)
	if not host.tree_exiting.is_connected(tip.queue_free):
		host.tree_exiting.connect(tip.queue_free)

# Where a tip goes: above-right of the pointer, flipped left / below at the screen edges, so it never
# covers the text under the pointer.
# A tip anchored to its control (story chat, user 2026-10-01: "the text is not placed over the hovered
# icon"): centred above `anchor` (a rect in viewport coordinates, see canvas_rect), flipped below when
# there's no room above, clamped on screen.
const TIP_GAP := 8.0
static func tip_beside(anchor: Rect2, tip_size: Vector2, screen: Vector2) -> Vector2:
	var at := Vector2(anchor.get_center().x - tip_size.x / 2.0, anchor.position.y - tip_size.y - TIP_GAP)
	if at.y < 4.0:
		at.y = anchor.end.y + TIP_GAP
	return Vector2(clampf(at.x, 4.0, maxf(screen.x - tip_size.x - 4.0, 4.0)), clampf(at.y, 4.0, maxf(screen.y - tip_size.y - 4.0, 4.0)))

# `control`'s rect in its viewport's coordinates (through CanvasLayers and the camera for world UI).
static func canvas_rect(control: Control) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	return Rect2(transform.origin, control.size * transform.get_scale())

static func tip_position(pointer: Vector2, tip_size: Vector2, screen: Vector2) -> Vector2:
	var at := pointer + Vector2(16.0, -tip_size.y - 12.0)
	if at.x + tip_size.x > screen.x - 4.0:
		at.x = pointer.x - tip_size.x - 16.0
	if at.y < 4.0:
		at.y = pointer.y + 24.0
	return Vector2(clampf(at.x, 4.0, maxf(screen.x - tip_size.x - 4.0, 4.0)), clampf(at.y, 4.0, maxf(screen.y - tip_size.y - 4.0, 4.0)))

# A panel whose thread and diamond take `colour` (a boss, a Kinship, a Crowned Reaction).
static func panel_in(colour: Color, margin_x: float = 10.0, margin_y: float = 10.0) -> MoonStyleBox:
	var box := panel(margin_x, margin_y)
	box.thread_color = colour
	box.accent = colour  # Moon-glass: a line in the colour across the top of the glass
	return box

# Fog only: no frame, no thread, a soft Void patch fading to nothing at its edges (owner 2026-10-24: "do the frameless";
# built on panel() it had silently become a framed plate). The whisper mist, the title menu backing, the Sell hint, the
# Omen tag, the Grove node panel and the FogPatch type.
static func fog_patch(margin_x: float = 12.0, margin_y: float = 6.0) -> MoonStyleBox:
	var box := panel(margin_x, margin_y)
	box.frame = &""  # MoonStyleBox draws its old soft fog
	box.thread = MoonStyleBox.TopLine.NONE
	box.center_alpha = 0.7
	box.edge_alpha = 0.0
	return box

# A Dream / family / Omen card: the main plate with its rarity (`colour`) across the top of the glass; hovered, the brass
# rim and its glow. Cards never carry the sprout (several to a screen).
# `legendary` (rarity 3): the Legendary frame (MoonStyleBox.legendary), clearly above a Rare, hovered or not.
static func card(colour: Color, hover: bool = false, legendary: bool = false) -> MoonStyleBox:
	var box := panel(18.0, 16.0)
	box.frame = &"panel_main_yours" if hover else &"panel_main"
	box.glow = hover
	box.thread = MoonStyleBox.TopLine.FULL
	box.thread_color = colour
	box.accent = colour
	box.diamond = false
	box.legendary = legendary
	return box

# An unpicked card (the others after a pick): the dim plate.
static func card_dim(colour: Color) -> MoonStyleBox:
	var box := card(colour)
	box.frame = &"plate_dim"
	box.accent = Color(colour, 0.5)
	return box

# A Warden bar slot (Moon-glass): a pewter plate; hovered or selected, brass (selected keeps the glow); short on Dew
# (slot_short), the dim plate.
static func slot(selected: bool, hover: bool = false, short: bool = false) -> MoonStyleBox:
	var frame := (&"plate_yours_hover" if hover else &"plate_yours") if selected else (&"plate_hover" if hover else (&"plate_dim" if short else &"plate"))
	return plate_box(4.0, 4.0, frame)

# Marks a Warden slot short on Dew without disabling it (a press still refuses with a shake): the dim plate in its
# resting and hovered states; false puts the theme's boxes back.
static func slot_short(button: Button, short: bool) -> void:
	for state in ["normal", "hover", "disabled"]:
		if short:
			button.add_theme_stylebox_override(state, slot(false, false, true))
		else:
			button.remove_theme_stylebox_override(state)

# The band under the Warden bar (calmer than other panels): Void .70 in the middle → .20 at the rim,
# the thread at .6 and no mark. For the PanelContainer behind %TowerBar.
static func bar_panel() -> MoonStyleBox:
	return plate_box(10.0, 6.0)  # Moon-glass: a plain plate, no sprout

# Nightmare portraits on dark UI sit on a pale moonlit disc with a thin cold rim (screens_ui.md
# "Readable on the night sky"): a dark nightmare never vanishes into the night sky. Boss faces rim it
# in BOSS.
static func moon_disc(rim: Color = OFF, hover: bool = false, margin: float = 4.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = MOONLIGHT.lightened(0.1) if hover else MOONLIGHT
	box.border_color = rim
	box.set_border_width_all(2 if rim == BOSS else 1)
	box.set_corner_radius_all(999)  # Clamped to half the size: a circle
	box.anti_aliasing = true
	box.set_content_margin_all(margin)
	return box

# The same disc drawn straight onto a canvas (custom-drawn portraits), `r` px from the centre.
static func draw_moon_disc(canvas: CanvasItem, centre: Vector2, r: float, rim: Color = OFF) -> void:
	canvas.draw_circle(centre, r, MOON_MIST)
	canvas.draw_circle(centre, r * 0.82, MOONLIGHT)  # Brighter towards the middle
	canvas.draw_arc(centre, r - 0.75, 0.0, TAU, 48, rim, 2.0 if rim == BOSS else 1.5, true)

# Puts `portrait` (a TextureRect or similar) on the moon disc; add the result where the portrait went.
static func on_moon_disc(portrait: Control, rim: Color = OFF) -> PanelContainer:
	var disc := PanelContainer.new()
	disc.add_theme_stylebox_override("panel", moon_disc(rim))
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE if portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE \
		else Control.MOUSE_FILTER_PASS
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	disc.add_child(portrait)
	return disc

# Gives a portrait Button the moon disc look in every state.
static func moon_disc_button(button: Button, rim: Color = OFF) -> void:
	for state in ["normal", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, moon_disc(rim, false, 1.0))
	for state in ["hover", "hover_pressed"]:
		button.add_theme_stylebox_override(state, moon_disc(rim, true, 1.0))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

# Buttons (Moon-glass): a pewter plate at rest, brass under the pointer or finger.
static func button_box(hover: bool = false) -> MoonStyleBox:
	return plate_box(14.0, 6.0, &"plate_hover" if hover else &"plate")

# The one primary per panel or choice (Take, Start drift, Resume, Apply): brass at rest with the soft gold glow, the
# glowing brass under the pointer (plate_yours_hover: Ember inside, a stronger outer glow, Heartlight text), and pressed lit from below, pushed down 2 px, no shadow.
const PRIMARY_GLOW := Color("b8662c")  # Ember (kept for old callers)
static func primary_box(hover: bool = false, pressed: bool = false) -> MoonStyleBox:
	return plate_box(14.0, 6.0, &"plate_pressed" if pressed else (&"plate_yours_hover" if hover else &"plate_yours"))

# Selected / switched on (a toggled button, the current speed, a switch's segment): brass with its glow. Godot's
# "pressed" style is both "toggled on" and "held"; held reads as the pushed-in brass (pressed_box).
const HOVER_FILL := Color(MOONLIGHT, 0.16)  # The soft highlight (rows, old callers)
static func selected_box() -> MoonStyleBox:
	return plate_box(14.0, 6.0, &"plate_yours")

static func pressed_box() -> MoonStyleBox:
	return plate_box(14.0, 6.0, &"plate_pressed")

static func hover_box(selected: bool = false) -> MoonStyleBox:
	return plate_box(14.0, 6.0, &"plate_pressed" if selected else &"plate_hover")

static func disabled_box() -> MoonStyleBox:
	return plate_box(14.0, 6.0, &"plate_dim")

# Destructive actions (Abandon, Delete): the small Ember-rimmed plate, set apart (UiStyle.danger).
static func danger_box(hover: bool = false) -> MoonStyleBox:
	var box := plate_box(12.0, 4.0, &"plate_danger")
	box.glow = hover
	return box

# Keyboard / controller focus: a thin Moonlight ring just outside the control.
static func focus_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = Color(MOONLIGHT, 0.6)
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.set_expand_margin_all(3)
	return box

# A HUD button's box: the same look, tighter padding.
static func _compact(box: StyleBox) -> StyleBox:
	var copy := box.duplicate() as StyleBox
	_margins(copy, 10.0, 4.0)
	return copy

static func _margins(box: StyleBox, x: float, y: float) -> void:
	box.content_margin_left = x
	box.content_margin_right = x
	box.content_margin_top = y
	box.content_margin_bottom = y

# --- Feeling the cards (dream_design.md, 2026-10-01) -------------------------------------------
# The look for the impact preview, the bloom, the toast and the credit lines; Roguelite Code makes
# the data, Main the behaviour. Calm and readable: one line, one pulse, gold for what the card does.

const IMPACT_SIZE := BODY_SIZE  # 16: ui_style.md body minimum

# The impact preview line on a Dream card ("On your board · +22% damage on 7 Wardens"): gold body
# text; `has_effect` false = the dim-ink "None of your Wardens yet" (a card for later is still fair).
static func impact_line(label: Control, has_effect: bool = true) -> void:
	_font(label, body_medium_font() if has_effect else body_font(), IMPACT_SIZE, GOLD if has_effect else INK_DIM)
	if label is Label:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

# The bloom on a Warden the taken card affects, at progress `t` (0 → 1 over ~0.6 s; callers stagger
# it): a soft ring in the rarity colour that grows and fades at the Warden's base, and the card's gem
# (with its glyph) rising a little above the Warden and fading out. Reduced motion: hold t at 0.35
# (one soft highlight, no movement).
const BLOOM_RING := Vector2(18.0, 34.0)  # Ring radius from → to, px
const BLOOM_RISE := 14.0
static func draw_bloom(canvas: CanvasItem, base: Vector2, t: float, rarity: int, glyph: StringName = &"",
		gem_height: float = 46.0) -> void:
	var colour := rarity_color(rarity)
	var fade := 1.0 - clampf(t, 0.0, 1.0)
	var ease := 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)  # Out-cubic: quick, then gentle
	var radius := lerpf(BLOOM_RING.x, BLOOM_RING.y, ease)
	canvas.draw_circle(base, radius, Color(colour, 0.12 * fade))
	canvas.draw_arc(base, radius, 0.0, TAU, 40, Color(colour, 0.85 * fade), 2.0, true)
	var gem_at := base + Vector2(0, -gem_height - BLOOM_RISE * ease)
	var gem_alpha := clampf(1.0 - (t - 0.6) / 0.4, 0.0, 1.0)  # Holds, then fades in the last 40%
	if gem_alpha > 0.0:
		canvas.draw_circle(gem_at, 15.0, Color(FOG, 0.6 * gem_alpha))  # A fog dot keeps it legible on bright map
		draw_gem(canvas, gem_at, 12.0, rarity, glyph)

# The toast after taking a card ("Cozy Corners · 6 Wardens +30%"): the display face, Ink, a Void outline.
static func impact_toast(label: Label) -> void:
	_font(label, display_font(), 22, INK)
	label.add_theme_color_override("font_outline_color", FOG)
	label.add_theme_constant_override("outline_size", 6)

# A credit line for the rest report / results (RichTextLabel bbcode): a dim title, then each
# entry's name in Ink and its number in Gold, joined by " · ". `entries` = [[name, value_text], …].
# e.g. credit_bbcode("Dreams this block", [["Lingering Spores", "+1,840"], ["Cozy Corners", "+920"]]).
static func credit_bbcode(title: String, entries: Array) -> String:
	var parts: Array[String] = []
	for entry in entries:
		parts.append("[color=#%s]%s[/color] [color=#%s]%s[/color]" % [INK.to_html(false), _bb(String(entry[0])),
			GOLD.to_html(false), _bb(String(entry[1]))])
	var head := "[font_size=%d][color=#%s]%s[/color][/font_size]" % [LABEL_SIZE + 1, INK_DIM.to_html(false), _bb(title)]
	return head + "  " + (" [color=#%s]·[/color] " % INK_DIM.to_html(false)).join(parts)

static func _bb(text: String) -> String:
	return text.replace("[", "[lb]")

# --- Helpers for screens built in code ---------------------------------------------------------

static func rarity_color(rarity: int) -> Color:
	return RARITY[clampi(rarity, 0, RARITY.size() - 1)]

# The rarity gem (screens_ui.md: shape AND colour): Common circle, Uncommon diamond, Rare hexagon,
# Legendary star, `r` px from the centre.
# With `glyph` (a dream_glyph id, UI Asset's assets/ui/dream_glyphs.png): the gem is dark (Night) with
# the rarity colour on its rim and shape, and the light glyph sits inside at ×2 (16 px; needs r ≥ 11).
static func draw_gem(canvas: CanvasItem, centre: Vector2, r: float, rarity: int, glyph: StringName = &"") -> void:
	var colour := rarity_color(rarity)
	var dark := Color(FOG, 0.9)
	var with_glyph := glyph != &""
	var fill := CARD_BG if with_glyph else colour
	var rim := colour if with_glyph else dark
	if rarity == 0:
		canvas.draw_circle(centre, r, rim if with_glyph else dark)
		canvas.draw_circle(centre, r - 2.0, fill)
	else:
		var corners: int = {1: 4, 2: 6}.get(rarity, 10)
		var points := PackedVector2Array()
		for i in corners:
			var radius := r if corners < 10 or i % 2 == 0 else r * 0.5  # Legendary: a star
			points.append(centre + Vector2.from_angle(TAU * i / corners - PI / 2.0) * radius)
		canvas.draw_colored_polygon(points, fill)
		points.append(points[0])
		canvas.draw_polyline(points, rim, 2.0, true)
	if with_glyph:
		# Straight from the sheet (held by _glyph_sheet): a temporary AtlasTexture made here was freed
		# before the frame rendered and drew as a white square (2026-10-01).
		var sheet := _glyph_sheet_texture()
		var region := dream_glyph_region(glyph)
		if sheet != null and region.has_area():
			var side := Vector2(16, 16) if r >= 11.0 else Vector2(8, 8)  # Whole-number scale only
			canvas.draw_texture_rect_region(sheet, Rect2((centre - side / 2.0).round(), side), region)

# Dream card glyphs (UI Asset, assets/ui/dream_glyphs.json): the first `priority` id any of the card's
# tags maps to, else `fallback`. Every gem caller uses this, so a card shows the same glyph everywhere.
const DREAM_GLYPHS := "res://assets/ui/dream_glyphs"
static var _glyph_data := {}  # The parsed JSON
static var _glyph_sheet: Texture2D = null  # Kept alive for draw calls; released at exit (release_at_exit)

static func dream_glyph(card: UpgradeData) -> StringName:
	var data := _glyphs()
	if data.is_empty() or card == null:
		return &""
	var tags: Dictionary = data.get("tags", {})
	var mapped := {}
	for tag in card.tags:
		if tags.has(tag):
			mapped[tags[tag]] = true
	for id in data.get("priority", []):
		if mapped.has(id):
			return StringName(id)
	return StringName(data.get("fallback", "generic"))

# The glyph's cell in assets/ui/dream_glyphs.png (an empty Rect2 for an unknown id).
static func dream_glyph_region(id: StringName) -> Rect2:
	var data := _glyphs()
	var icons: Dictionary = data.get("icons", {})
	if not icons.has(String(id)):
		return Rect2()
	var frame := int(data.get("frame_size", 8))
	return Rect2(int(icons[String(id)]) * frame, 0, frame, frame)

static func _glyph_sheet_texture() -> Texture2D:
	if _glyph_sheet == null and ResourceLoader.exists(DREAM_GLYPHS + ".png"):
		_glyph_sheet = load(DREAM_GLYPHS + ".png")
		release_at_exit(func() -> void: _glyph_sheet = null)
	return _glyph_sheet

# The glyph's 8×8 cell of the sheet (a new AtlasTexture: cache it on the caller's instance if drawn often).
static func dream_glyph_texture(id: StringName) -> Texture2D:
	var data := _glyphs()
	var icons: Dictionary = data.get("icons", {})
	if not icons.has(String(id)) or not ResourceLoader.exists(DREAM_GLYPHS + ".png"):
		return null
	var frame := int(data.get("frame_size", 8))
	var atlas := AtlasTexture.new()
	atlas.atlas = load(DREAM_GLYPHS + ".png")
	atlas.region = Rect2(int(icons[String(id)]) * frame, 0, frame, frame)
	return atlas

static func _glyphs() -> Dictionary:
	if _glyph_data.is_empty() and FileAccess.file_exists(DREAM_GLYPHS + ".json"):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DREAM_GLYPHS + ".json"))
		if parsed is Dictionary:
			_glyph_data = parsed
	return _glyph_data

# The display face at `font_size`, keeping the control's colour.
static func display(control: Control, font_size: int = TITLE_SIZE) -> void:
	control.add_theme_font_override("font", display_font())
	control.add_theme_font_size_override("font_size", font_size)

static func title(label: Control, font_size: int = TITLE_SIZE, colour: Color = INK) -> void:
	_font(label, display_font(), font_size, colour)

static func number(label: Control, font_size: int = NUMBER_SIZE, colour: Color = GOLD) -> void:
	_font(label, number_font(), font_size, colour)

# Lowercase small-caps label ("act 1 · forest's edge"); the text is lower-cased here.
# A tip's body text (Label or RichTextLabel): TIP_SIZE, the tip line height, wraps at TIP_WIDTH.
static func tip_body(label: Control, width: float = TIP_WIDTH) -> void:
	if label is RichTextLabel:
		label.add_theme_font_size_override("normal_font_size", TIP_SIZE)
		label.add_theme_font_size_override("bold_font_size", TIP_SIZE)
		label.add_theme_constant_override("line_separation", TIP_LINE_SPACING)
	else:
		label.add_theme_font_size_override("font_size", TIP_SIZE)
		label.add_theme_constant_override("line_spacing", TIP_LINE_SPACING)
	label.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
	label.custom_minimum_size.x = width

# A tip's name line (a status, a term, a nightmare): TIP_NAME_SIZE.
static func tip_name(label: Label, colour: Color = INK) -> void:
	label.add_theme_font_size_override("font_size", TIP_NAME_SIZE)
	label.add_theme_color_override("font_color", colour)

# Native tooltips (tooltip_text) wrap at TIP_WIDTH too: Godot's tooltip Label (theme type
# "TooltipLabel") never wraps by itself, so each one is caught as it's made and given a width.
# Installed once per SceneTree (the title and the HUD call it; the tree outlives scene changes).
static var _tooltip_tree: SceneTree = null
static func install_tooltip_wrap(tree: SceneTree) -> void:
	if tree == null or _tooltip_tree == tree:
		return
	_tooltip_tree = tree
	if tree.root.get_node_or_null("TipLayer") == null:  # The tip layer, ready before any tip shows
		var layer := CanvasLayer.new()
		layer.name = "TipLayer"
		layer.layer = TIP_LAYER
		layer.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child.call_deferred(layer)
	tree.node_added.connect(func(node: Node) -> void:
		if node is Label and node.theme_type_variation == &"TooltipLabel":
			_wrap_tooltip.call_deferred(node))

static func _wrap_tooltip(label: Label) -> void:
	if not is_instance_valid(label):
		return
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var widest := 0.0
	for line in label.text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	if widest > TIP_WIDTH:  # Short tips keep their natural width
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = TIP_WIDTH
	var panel := label.get_parent() as Window
	if panel == null:
		return
	panel.size = Vector2i(panel.get_contents_minimum_size())
	# Anchored to the hovered control: above it, flipped below, clamped (tip_beside); else by the pointer.
	# The tip is an embedded popup, so it lives in the root viewport's units, which the UI scale
	# (canvas_items stretch) makes different from window pixels: everything here is in viewport units.
	var window := panel.get_tree().root if panel.is_inside_tree() else null
	if window == null:
		return
	var screen := window.get_visible_rect().size
	var hovered := window.gui_get_hovered_control()
	if hovered != null:
		panel.position = Vector2i(tip_beside(canvas_rect(hovered), Vector2(panel.size), screen))
	else:
		panel.position = Vector2i(tip_position(window.get_mouse_position(), Vector2(panel.size), screen))

static func caps(label: Control, font_size: int = LABEL_SIZE, colour: Color = INK_DIM) -> void:
	_font(label, caps_font(), font_size, colour)
	if label is Label:
		label.text = label.text.to_lower()

# A short line that isn't a heading or a button (a Calling's name, a price, a status note, a chip's word): Vollkorn
# Medium, as written (user 2026-10-23: "too much text different fonts"; small caps stays for buttons, section headings
# and key hints).
static func plain(label: Control, font_size: int = LABEL_SIZE, colour: Color = INK_DIM) -> void:
	_font(label, body_medium_font(), font_size, colour)

# A wrapping label whose longest word always fits its width (Moon-glass's Pixelify names are wider than Cormorant was: the
# user saw "Undercurren / t", 2026-10-20): the font steps down from `max_size` to `min_size` until it does, again whenever
# the label resizes. Call fit_words_now after changing its text.
static func fit_words(label: Label, max_size: int, min_size: int = 16) -> void:
	label.set_meta(&"fit_words", [max_size, min_size])
	fit_words_now(label)

# Fits once the layout has settled (deferred), never from the label's own `resized` (user 2026-10-22: the game froze, then
# crashed, selecting a rank-V Driftspore: refitting inside a resize fed the containers' layout back into itself until the
# engine's stack ran out). Call it after changing the text; a label not laid out yet tries again next frame (a few times).
static func fit_words_now(label: Label) -> void:
	if is_instance_valid(label) and label.has_meta(&"fit_words"):
		label.set_meta(&"fit_words_tries", 0)
		_fit_words_later.call_deferred(label)

static func _fit_words_later(label: Label) -> void:
	if not is_instance_valid(label) or not label.has_meta(&"fit_words") or not label.is_inside_tree():
		return
	if label.size.x <= 0.0:
		var tries := int(label.get_meta(&"fit_words_tries", 0))
		if tries < 5:
			label.set_meta(&"fit_words_tries", tries + 1)
			var retry := _fit_words_later.bind(label)
			if not label.get_tree().process_frame.is_connected(retry):  # Fitted twice before it had a width: one retry
				label.get_tree().process_frame.connect(retry, CONNECT_ONE_SHOT)
		return
	_fit_words_to_width(label)

static func _fit_words_to_width(label: Label) -> void:
	var sizes: Array = label.get_meta(&"fit_words")
	var font := label.get_theme_font("font")
	var words := label.text.split(" ", false)
	var size := int(sizes[0])
	while size > int(sizes[1]):
		var widest := 0.0
		for word in words:
			widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
		if widest <= label.size.x:
			break
		size -= 1
	if label.get_theme_font_size("font_size") != size:
		label.add_theme_font_size_override("font_size", size)

static func whisper(label: Control, font_size: int = 20) -> void:
	_font(label, whisper_font(), font_size, WHISPER)

static func _font(control: Control, font: Font, font_size: int, colour: Color) -> void:
	var rich := control is RichTextLabel
	control.add_theme_font_override("normal_font" if rich else "font", font)
	control.add_theme_font_size_override("normal_font_size" if rich else "font_size", font_size)
	control.add_theme_color_override("default_color" if rich else "font_color", colour)

# The primary look (Start drift, Grow, Continue…).
static func primary(button: Button) -> void:
	button.theme_type_variation = &"PrimaryButton"

# A destructive action (Abandon, Delete): the small Ember-rimmed plate (Moon-glass); keep it set apart from the primary.
static func danger(button: Button) -> void:
	button.theme_type_variation = &"DangerButton"

# A mini plate, for actions that shouldn't compete with the primary (Sell, Close, Details ▸): the plate is 32 px, the touch
# target 48 (QUIET_INSET above and below).
const QUIET_INSET := 8.0
static func quiet(button: Button) -> void:
	button.theme_type_variation = &"QuietButton"
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, HUD_BUTTON_H)

# One row of a list (the Warden panel's grow options): text-only, left-aligned, 48 px tall.
const ROW_H := HUD_BUTTON_H  # 48: rows are tappable (platforms.md), and padding a 40 px row would overlap the next
static func row(button: Button) -> void:
	button.theme_type_variation = &"RowButton"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, ROW_H)

# A row of toggle buttons as one outlined group (DriftPanel's Auto / II / 1× / 2× / 3×): thin
# dividers, the active (pressed) one tinted with Glow text. Call after adding the buttons.
static func segmented(row: HBoxContainer) -> void:
	# Moon-glass: a row of small plates 2 px apart, pewter at rest, brass under the pointer, the chosen one brass with its
	# glow (plate_yours), dim when disabled.
	row.add_theme_constant_override("separation", 2)
	var frames := {"normal": &"plate", "hover": &"plate_hover", "pressed": &"plate_yours", "hover_pressed": &"plate_yours_hover",
		"disabled": &"plate_dim"}
	for button in row.get_children().filter(func(n: Node) -> bool: return n is Button):
		for state in frames:
			(button as Button).add_theme_stylebox_override(state, plate_box(8.0, 4.0, frames[state]))
		button.add_theme_color_override("font_color", INK_DIM)
		button.add_theme_color_override("font_hover_color", INK)
		for state in ["font_pressed_color", "font_hover_pressed_color"]:
			button.add_theme_color_override(state, GOLD)

# A hide / show handle and the Warden bar's scroll arrows (ui_style.md "Moon-glass" > Hide / show handles, UI Asset
# 83ed5944): the moon-glass plate filling `rect` (pewter, brass on hover, pushed in when pressed) and the HUD chevron at
# ×2 (chevron_hud_moon at rest, the gold chevron_hud on hover / press), turned to point along `along`. The art points
# right. Call from the button's draw; `rect` is the drawn handle inside its touch target.
const HANDLE_GAP := 8.0  # A handle stands this far outside its panel's edge (4 art px), never over it or its sprout
static func draw_handle(canvas: CanvasItem, rect: Rect2, along: Vector2, hovered: bool, pressed: bool) -> void:
	var frame := &"plate_pressed" if pressed else (&"plate_hover" if hovered else &"plate")
	var plate := MoonStyleBox.texture_for(frame)
	if plate != null:
		var m := minf(MoonStyleBox.frame_margin(frame), floorf(minf(rect.size.x, rect.size.y) / 2.0))  # A 28 px handle: corners meet
		RenderingServer.canvas_item_add_nine_patch(canvas.get_canvas_item(), rect, Rect2(Vector2.ZERO, plate.get_size()),
			plate.get_rid(), Vector2(m, m), Vector2(m, m))
	var glyph := IconInfo.hud_icon(&"chevron_hud" if hovered or pressed else &"chevron_hud_moon")
	if glyph == null:
		return
	var centre := rect.get_center().round() + (Vector2(0, 2) if pressed else Vector2.ZERO)
	canvas.draw_set_transform(centre, along.angle(), Vector2(2, 2))
	canvas.draw_texture(glyph, -(glyph.get_size() / 2.0).floor())
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Whether a button is drawing hovered / pressed (for custom-drawn buttons like the handles).
static func button_lit(button: BaseButton) -> bool:
	var mode := button.get_draw_mode()
	return mode == BaseButton.DRAW_HOVER or mode == BaseButton.DRAW_HOVER_PRESSED

static func button_down(button: BaseButton) -> bool:
	var mode := button.get_draw_mode()
	return mode == BaseButton.DRAW_PRESSED or mode == BaseButton.DRAW_HOVER_PRESSED

# A small key chip ("Q", "R", "⏎") for rows and buttons: Mist on a dim outline; inside a primary
# button it turns gold by itself, like the primary's text.
static func key_chip(text: String) -> Label:
	var chip := Label.new()
	chip.text = text
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.custom_minimum_size = Vector2(18, 18)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_font_override("font", caps_font())  # Key hints: Vollkorn SC
	chip.add_theme_font_size_override("font_size", 12)
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(2)
	_margins(frame, 4.0, 0.0)
	var paint := func() -> void:
		var on_primary := false
		var up := chip.get_parent()
		while up != null and not on_primary:
			on_primary = up is Button and (up as Button).theme_type_variation in [&"PrimaryButton", &"HudPrimary"]
			up = up.get_parent()
		var ink := GOLD if on_primary else INK_DIM
		chip.add_theme_color_override("font_color", ink)
		frame.border_color = Color(ink, 0.35)
		chip.add_theme_stylebox_override("normal", frame)
	chip.tree_entered.connect(paint)
	paint.call()
	# Touch controls have no keys (InputMode: phones, a touchscreen driving a PC, or the Touch setting): the chip
	# hides whenever it would show or draw, so it follows a switch mid-run too.
	if InputMode.touch():
		chip.visible = false
	chip.visibility_changed.connect(func() -> void:
		if chip.visible and InputMode.touch():
			chip.hide())
	chip.draw.connect(func() -> void:
		if InputMode.touch():
			chip.hide.call_deferred())
	return chip

# A key chip on a button's right edge, KEY_CHIP_GAP in from it, with the centred label kept clear of it (UI council round 3:
# "Face it" ran into its chip, "Face itEnter"). Every primary's key hint is this chip, never "(Enter)" in the label. The
# room the label + chip need is the button's meta "key_room" (0 under touch, where the chip hides); with `grow` the
# button's minimum width rises to it, else its owner reads the meta (DriftPanel's Start fits the speed row too).
const KEY_CHIP_GAP := 12.0
static func key_chip_on(button: Button, key: String, grow := true) -> Label:
	var chip := key_chip(key)
	chip.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	button.add_child(chip)
	var fit := func() -> void: _fit_key_chip(button, chip, grow)
	button.draw.connect(func() -> void: fit.call_deferred())  # Text changes redraw the button
	fit.call()
	return chip

static func _fit_key_chip(button: Button, chip: Label, grow: bool) -> void:
	if not is_instance_valid(button) or not is_instance_valid(chip):
		return
	var chip_size := chip.get_combined_minimum_size()
	chip.offset_left = -KEY_CHIP_GAP - chip_size.x
	chip.offset_right = -KEY_CHIP_GAP
	chip.offset_top = -chip_size.y / 2.0
	chip.offset_bottom = chip_size.y / 2.0
	var room := 0.0
	var shift := 0.0
	if chip.visible and not InputMode.touch():
		var font := button.get_theme_font("font")
		var text_w := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
		shift = chip_size.x + KEY_CHIP_GAP
		room = ceilf(text_w + shift + KEY_CHIP_GAP * 3.0)
	shift_label(button, shift)
	button.set_meta(&"key_room", room)
	if grow and button.custom_minimum_size.x < room:
		button.custom_minimum_size.x = room

# The label centres in the room left of the chip (UI council round 4: it sat centred on the whole button, off-centre
# beside the chip): every state's box gets `shift` more right content margin. Boxes the button had overridden before
# are kept as the base; the rest follow its theme variation (Start swaps HudPrimary / HudButton).
const KEY_STATES := [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]
static func shift_label(button: Button, shift: float) -> void:
	if not button.has_meta(&"key_base"):
		var base := {}
		for state in KEY_STATES:
			base[state] = button.get_theme_stylebox(state) if button.has_theme_stylebox_override(state) else null
		button.set_meta(&"key_base", base)
	if is_equal_approx(float(button.get_meta(&"key_shift", -1.0)), shift) \
			and button.get_meta(&"key_variation", &"") == button.theme_type_variation:
		return
	button.set_meta(&"key_shift", shift)
	button.set_meta(&"key_variation", button.theme_type_variation)
	var bases: Dictionary = button.get_meta(&"key_base")
	for state in KEY_STATES:
		var box: StyleBox = bases[state]
		if box == null:
			button.remove_theme_stylebox_override(state)
			box = button.get_theme_stylebox(state)
		if box == null or shift <= 0.0:
			if bases[state] != null:
				button.add_theme_stylebox_override(state, bases[state])
			continue
		var shifted := box.duplicate() as StyleBox
		shifted.content_margin_right = box.get_content_margin(SIDE_RIGHT) + shift
		button.add_theme_stylebox_override(state, shifted)

# Pixelify's 5 reads as S ("Boss in 2S", UI council round 3): text drawn in the display face sets its digits in the
# number face (Vollkorn Medium, ui_style.md type table). For _draw code; returns the width drawn.
static func draw_display(canvas: CanvasItem, at: Vector2, text: String, font_size: int, colour: Color,
		outline := 0, outline_colour := Color()) -> float:
	var runs := _digit_runs(text)
	for pass_outline in ([true, false] if outline > 0 else [false]):
		var x := at.x
		for run: Array in runs:
			var font: Font = number_font() if run[1] else display_font()
			if pass_outline:
				canvas.draw_string_outline(font, Vector2(x, at.y), run[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, outline_colour)
			else:
				canvas.draw_string(font, Vector2(x, at.y), run[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
			x += font.get_string_size(run[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return display_width(text, font_size)

static func display_width(text: String, font_size: int) -> float:
	var width := 0.0
	for run: Array in _digit_runs(text):
		var font: Font = number_font() if run[1] else display_font()
		width += font.get_string_size(run[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return width

# [[text, is_digits], …] in order.
static func _digit_runs(text: String) -> Array:
	var runs: Array = []
	for i in text.length():
		var digit := text[i] >= "0" and text[i] <= "9"
		if runs.is_empty() or runs[-1][1] != digit:
			runs.append([text[i], digit])
		else:
			runs[-1][0] += text[i]
	return runs

# A button label's keyboard hint (" (Enter)"), dropped under touch controls (InputMode): "Start drift 3" + key_suffix("Enter").
static func key_suffix(key: String) -> String:
	return "" if InputMode.touch() else " (%s)" % key

# A keyword chip (Dream cards' "Makes / Uses", owner 2026-10-16): the icon (KeywordIcons) on the left, the word always
# beside it. kind &"makes" = filled gold, dark word; &"uses" = gold outline over fog, gold word. `id` is a keyword
# (&"jump") or a status (&"poisoned" / &"spored"); `label` overrides the word. The chip takes no input: the row it sits
# in is the tap target (Mobile UI: one 48 px row, tapping opens the glossary line). Phones pass icon_size 20.
const CHIP_ICON := 16
const CHIP_TEXT_SIZE := 14
# `outline` (a card's rarity colour; screens_ui.md 844fa70a) makes the quiet card chip instead: no gold fill, a 1 px
# frame in that colour (Makes adds a faint wash of it), the word in INK_DIM, so the card's name and text read first.
static func chip(id: StringName, kind: StringName, label: String = "", icon_size: int = CHIP_ICON,
		font_size: int = CHIP_TEXT_SIZE, outline := Color(0, 0, 0, 0)) -> PanelContainer:
	var makes := kind == &"makes"
	var quiet := outline.a > 0.0
	var box := PanelContainer.new()
	box.name = "Chip_%s_%s" % [kind, id]
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.set_meta(&"keyword", id)
	box.set_meta(&"kind", kind)
	var frame := StyleBoxFlat.new()
	frame.bg_color = GOLD if makes else Color(FOG, 0.6)
	frame.border_color = GOLD
	if quiet:
		# Moon-glass (user 2026-10-20: the "Single target" tag "uses the old UI"): a mini pewter plate, too small for the
		# 9-slice (its corners need 32 px): dark glass, a 1 px pewter rim (Mist for Makes, Slate for Uses). The card's
		# rarity shows on its top line, not on its chips.
		frame.bg_color = Color(Palette.DREAD, 0.86)
		frame.border_color = Color(Palette.MIST, 0.6) if makes else Color(Palette.SLATE, 0.95)
		frame.shadow_color = Color(FOG, 0.35)
		frame.shadow_size = 3
		frame.shadow_offset = Vector2(0, 1)
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(1 if quiet else 2)
	_margins(frame, 4.0, 1.0)
	frame.content_margin_right = 6.0
	box.add_theme_stylebox_override("panel", frame)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)
	var icon := Control.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.draw.connect(func() -> void: KeywordIcons.draw(icon, id, icon.size / 2.0, icon_size))
	row.add_child(icon)
	var word := Label.new()
	word.name = "Word"
	word.text = label if label != "" else KeywordIcons.word(id)
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word.add_theme_font_override("font", body_medium_font())  # Chips: Vollkorn Medium, as written (user 2026-10-23: fewer small caps)
	word.add_theme_font_size_override("font_size", font_size)
	word.add_theme_color_override("font_color", INK if quiet else (FOG if makes else GOLD))  # Quiet: the label colour (UI council r7: INK_DIM was lost on the glass)
	row.add_child(word)
	return box

# Gives a Button the card look in `colour` (normal + hover + pressed).
static func card_button(button: Button, colour: Color, legendary: bool = false) -> void:
	var normal := card(colour, false, legendary)
	var hover := card(colour, true, legendary)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("hover_pressed", hover)

# --- The project theme -------------------------------------------------------------------------

static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = body_font()
	theme.default_font_size = BODY_SIZE

	for type in ["Label", "RichTextLabel", "LineEdit", "TextEdit", "PopupMenu", "TooltipLabel", "ItemList", "Tree"]:
		theme.set_color("font_color", type, INK)
	theme.set_color("default_color", "RichTextLabel", INK)
	theme.set_font("normal_font", "RichTextLabel", body_font())
	theme.set_font("bold_font", "RichTextLabel", body_medium_font())
	theme.set_font("italics_font", "RichTextLabel", whisper_font())
	theme.set_font("bold_italics_font", "RichTextLabel", whisper_font())

	# Panels are the main moon-glass plate; tooltips a small plate.
	for type in ["PanelContainer", "Panel", "PopupPanel", "TooltipPanel", "PopupMenu", "AcceptDialog"]:
		theme.set_stylebox("panel", type, tip_panel() if type == "TooltipPanel" else panel(16.0, 12.0))  # Tips: solid
	theme.set_font_size("font_size", "TooltipLabel", TIP_SIZE)
	theme.set_constant("line_spacing", "TooltipLabel", TIP_LINE_SPACING)
	theme.set_stylebox("separator", "HSeparator", MoonDivider.new())
	theme.set_constant("separation", "HSeparator", 9)
	# Body text at about 1.4 line height (ui_style.md type table): Vollkorn's own line is ~1.2 em, so a few px more.
	theme.set_constant("line_spacing", "Label", BODY_LINE_EXTRA)
	theme.set_constant("line_separation", "RichTextLabel", BODY_LINE_EXTRA)
	# Text: a soft dark shadow under every label (Moon-glass; smooth, never a pixel shadow).
	for type in ["Label", "RichTextLabel", "TooltipLabel"]:
		theme.set_color("font_shadow_color", type, Color(FOG, 0.55))
		theme.set_constant("shadow_offset_x", type, 0)
		theme.set_constant("shadow_offset_y", type, 1)
		theme.set_constant("shadow_outline_size", type, 3)

	# Buttons (and the button-like controls).
	for type in ["Button", "OptionButton", "MenuButton"]:
		_button_styles(theme, type, button_box(), hover_box(), pressed_box(), hover_box(true))
	theme.set_type_variation("DangerButton", "Button")
	_button_styles(theme, "DangerButton", danger_box(), danger_box(true), pressed_box(), pressed_box())
	theme.set_font_size("font_size", "DangerButton", BUTTON_SIZE - 2)
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		theme.set_color(state, "DangerButton", WHISPER)  # Moonpath on the Ember rim
	theme.set_type_variation("PrimaryButton", "Button")
	# The call to action keeps its gold look; hovering fills it, pressing darkens it.
	var primary_press := primary_box(false, true)
	var primary_hover := primary_box(true)
	_button_styles(theme, "PrimaryButton", primary_box(), primary_hover, primary_press, primary_press)
	theme.set_font("font", "PrimaryButton", caps_font())  # Every button label in Vollkorn SC, primaries too (type table)
	for state in ["font_color", "font_focus_color", "font_pressed_color"]:
		theme.set_color(state, "PrimaryButton", GOLD)  # Glow text in the display face
	for state in ["font_hover_color", "font_hover_pressed_color"]:
		theme.set_color(state, "PrimaryButton", GOLD_TEXT)
	# Check boxes / switches: no box, just the text (and the toggle's own icon).
	for type in ["CheckBox", "CheckButton"]:
		var empty := StyleBoxEmpty.new()
		_margins(empty, 6.0, 4.0)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			theme.set_stylebox(state, type, empty)
		_font_colours(theme, type)

	# Warden bar slot (the light pass, 2026-10-05: "calmer, more transparent"): a soft fog patch, the
	# glowing gold underline when selected, no frame (UiStyle.slot).
	theme.set_type_variation("WardenSlot", "Button")
	var slot_boxes := [slot(false), slot(false, true), slot(true), slot(true, true), slot(false, false, true)]
	for i in 5:
		theme.set_stylebox(["normal", "hover", "pressed", "hover_pressed", "disabled"][i], "WardenSlot", slot_boxes[i])
	theme.set_stylebox("focus", "WardenSlot", StyleBoxEmpty.new())
	theme.set_font("font", "WardenSlot", number_font())
	theme.set_font_size("font_size", "WardenSlot", 13)  # The cost: 12.5 px Glow at .8 (rounded to 13)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, "WardenSlot", Color(GOLD, 0.8))
	# Slot text (cost, hotkey, "Clear") keeps a 1 px Void shadow so it reads over the bright path.
	theme.set_color("font_shadow_color", "WardenSlot", Color(FOG, 0.8))
	theme.set_constant("shadow_offset_x", "WardenSlot", 1)
	theme.set_constant("shadow_offset_y", "WardenSlot", 1)

	# HUD buttons (top-right row, drift controls): compact, HUD_BUTTON_H tall, small caps at
	# HUD_TEXT_SIZE, the thin frame. HudPrimary is the same size in the call-to-action look (Start).
	theme.set_type_variation("HudButton", "Button")
	_button_styles(theme, "HudButton", _compact(button_box()), _compact(hover_box()), _compact(pressed_box()),
		_compact(hover_box(true)))
	theme.set_type_variation("HudPrimary", "Button")
	_button_styles(theme, "HudPrimary", _compact(primary_box()), _compact(primary_hover), _compact(primary_press),
		_compact(primary_press))
	for state in ["font_color", "font_focus_color", "font_pressed_color"]:
		theme.set_color(state, "HudPrimary", GOLD)
	for state in ["font_hover_color", "font_hover_pressed_color"]:
		theme.set_color(state, "HudPrimary", GOLD_TEXT)
	for type in ["HudButton", "HudPrimary"]:
		theme.set_font("font", type, caps_font())
		theme.set_font_size("font_size", type, HUD_TEXT_SIZE)
	theme.set_font("font", "HudPrimary", caps_font())  # Vollkorn SC, like every button
	theme.set_font_size("font_size", "HudPrimary", HUD_TEXT_SIZE + 2)

	# Quiet buttons (the light pass): text only, Mist, Heartlight on hover; the padding keeps the hit
	# area HUD_BUTTON_H tall (platforms.md touch). Sell, Close, Details ▸, Peek at the map.
	theme.set_type_variation("QuietButton", "Button")
	# Moon-glass (user 2026-10-20: "sell and close should have their own mini boxes"): a 32 px mini plate drawn inside
	# the 48 px touch target (inset), pewter at rest, brass under the pointer, pushed in when pressed.
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var frame: StringName = {"normal": &"plate", "hover": &"plate_hover", "pressed": &"plate_pressed",
			"hover_pressed": &"plate_pressed", "disabled": &"plate_dim"}[state]
		var mini := plate_box(10.0, 14.0, frame)
		mini.inset = Vector2(0.0, QUIET_INSET)
		theme.set_stylebox(state, "QuietButton", mini)
	theme.set_stylebox("focus", "QuietButton", focus_box())
	theme.set_font("font", "QuietButton", caps_font())
	theme.set_font_size("font_size", "QuietButton", 15)
	theme.set_color("font_color", "QuietButton", INK_DIM)
	for state in ["font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(state, "QuietButton", INK)
	theme.set_color("font_pressed_color", "QuietButton", GOLD)
	theme.set_color("font_disabled_color", "QuietButton", Color(INK_DIM, DISABLED_ALPHA))

	# Row buttons (the light pass: the Warden panel's grow options): no box, Heartlight text left-aligned,
	# a faint Night / Gold tint on hover; 48 px tall, a full touch target (platforms.md).
	theme.set_type_variation("RowButton", "Button")
	# Moon-glass: each row is a plate (pewter; brass under the finger, pushed in when pressed).
	var row_idle := plate_box(10.0, 14.0)
	var row_dim := plate_box(10.0, 14.0, &"plate_dim")
	var row_hover := plate_box(10.0, 14.0, &"plate_hover")
	var row_press := plate_box(10.0, 14.0, &"plate_pressed")
	theme.set_stylebox("normal", "RowButton", row_idle)
	theme.set_stylebox("disabled", "RowButton", row_dim)
	theme.set_stylebox("hover", "RowButton", row_hover)
	for state in ["pressed", "hover_pressed"]:
		theme.set_stylebox(state, "RowButton", row_press)
	theme.set_stylebox("focus", "RowButton", focus_box())
	theme.set_font("font", "RowButton", caps_font())  # A row is a button: its label in Vollkorn SC
	theme.set_font_size("font_size", "RowButton", 16)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		theme.set_color(state, "RowButton", INK)
	theme.set_color("font_disabled_color", "RowButton", Color(INK, DISABLED_ALPHA))

	# Tabs (the settings panel; Moon-glass): plates, the open tab in brass.
	var tab_selected := plate_box(14.0, 8.0, &"plate_yours")
	var tab_idle := plate_box(14.0, 8.0)
	var tab_hover := plate_box(14.0, 8.0, &"plate_hover")
	for type in ["TabContainer", "TabBar"]:
		theme.set_stylebox("tab_selected", type, tab_selected)
		theme.set_stylebox("tab_unselected", type, tab_idle)
		theme.set_stylebox("tab_hovered", type, tab_hover)
		theme.set_stylebox("tab_focus", type, StyleBoxEmpty.new())
		theme.set_font("font", type, caps_font())
		theme.set_font_size("font_size", type, 17)
		theme.set_color("font_selected_color", type, GOLD_TEXT)
		theme.set_color("font_hovered_color", type, INK)
		theme.set_color("font_unselected_color", type, INK_DIM)
	theme.set_stylebox("panel", "TabContainer", panel())

	# Bars.
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(FOG, 0.7)
	bar_bg.border_color = Color(GOLD, 0.3)
	bar_bg.set_border_width_all(1)
	bar_bg.set_corner_radius_all(2)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(GOLD, 0.85)
	bar_fill.set_corner_radius_all(2)
	theme.set_stylebox("background", "ProgressBar", bar_bg)
	theme.set_stylebox("fill", "ProgressBar", bar_fill)
	theme.set_color("font_color", "ProgressBar", INK)

	# Scroll bars: a faint fog track and a thin gold grabber (brighter under the pointer / finger).
	var track := StyleBoxFlat.new()
	track.bg_color = Color(FOG, 0.35)
	track.set_corner_radius_all(3)
	for type in ["VScrollBar", "HScrollBar"]:
		var vertical: bool = type == "VScrollBar"
		var thin := track.duplicate() as StyleBoxFlat
		# 6 px wide (or tall): content margins set the bar's thickness.
		if vertical:
			thin.content_margin_left = 3
			thin.content_margin_right = 3
		else:
			thin.content_margin_top = 3
			thin.content_margin_bottom = 3
		theme.set_stylebox("scroll", type, thin)
		theme.set_stylebox("scroll_focus", type, thin)
		for state: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
			var grab := StyleBoxFlat.new()
			grab.bg_color = Color(GOLD, {"grabber": 0.45, "grabber_highlight": 0.75, "grabber_pressed": 0.95}[state])
			grab.set_corner_radius_all(3)
			theme.set_stylebox(state, type, grab)
		for icon in ["increment", "increment_highlight", "increment_pressed", "decrement", "decrement_highlight",
				"decrement_pressed"]:
			theme.set_icon(icon, type, PlaceholderTexture2D.new())  # No arrow buttons
	# Text fields.
	theme.set_stylebox("normal", "LineEdit", button_box())
	theme.set_stylebox("focus", "LineEdit", button_box(true))

	# Type variations for labels.
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font("font", "TitleLabel", display_font())
	theme.set_font_size("font_size", "TitleLabel", TITLE_SIZE)
	theme.set_type_variation("NumberLabel", "Label")
	theme.set_font("font", "NumberLabel", number_font())
	theme.set_font_size("font_size", "NumberLabel", NUMBER_SIZE)
	theme.set_color("font_color", "NumberLabel", GOLD)
	theme.set_type_variation("CapsLabel", "Label")
	theme.set_font("font", "CapsLabel", caps_font())
	theme.set_font_size("font_size", "CapsLabel", LABEL_SIZE)
	theme.set_color("font_color", "CapsLabel", INK_DIM)
	theme.set_type_variation("WhisperLabel", "Label")
	theme.set_font("font", "WhisperLabel", whisper_font())
	theme.set_font_size("font_size", "WhisperLabel", 20)
	theme.set_color("font_color", "WhisperLabel", WHISPER)
	theme.set_color("font_shadow_color", "WhisperLabel", Color(FOG, 0.9))
	theme.set_type_variation("FogPatch", "PanelContainer")
	theme.set_stylebox("panel", "FogPatch", fog_patch())
	return theme

static func _button_styles(theme: Theme, type: String, normal: StyleBox, hover: StyleBox, pressed: StyleBox,
		hover_pressed: StyleBox) -> void:
	theme.set_stylebox("normal", type, normal)
	theme.set_stylebox("hover", type, hover)
	theme.set_stylebox("pressed", type, pressed)  # Toggled buttons (1×, Auto) take the primary look
	theme.set_stylebox("hover_pressed", type, hover_pressed)
	theme.set_stylebox("disabled", type, disabled_box())
	theme.set_stylebox("focus", type, focus_box())
	theme.set_font("font", type, caps_font())  # Every button label: Vollkorn SC SemiBold (ui_style.md type table)
	theme.set_font_size("font_size", type, BUTTON_SIZE)
	_font_colours(theme, type)
	theme.set_color("font_pressed_color", type, GOLD_TEXT)
	theme.set_color("font_hover_pressed_color", type, GOLD_TEXT)

static func _font_colours(theme: Theme, type: String) -> void:
	theme.set_color("font_color", type, INK)
	theme.set_color("font_hover_color", type, INK)
	theme.set_color("font_focus_color", type, INK)
	theme.set_color("font_pressed_color", type, INK)
	theme.set_color("font_hover_pressed_color", type, INK)
	theme.set_color("font_disabled_color", type, Color(INK, DISABLED_ALPHA))
	theme.set_color("icon_disabled_color", type, Color(1, 1, 1, DISABLED_ALPHA))
