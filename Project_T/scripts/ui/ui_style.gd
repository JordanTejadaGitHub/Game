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
const INK := Color("fff4dc")  # Heartlight: text
const INK_DIM := Color("b4b0c8")  # Mist: labels, secondary text
const GOLD := Color("fcd47c")  # Glow: numbers, threads, links
const BUTTON_GOLD := Color("e9a83c")  # Gold: button outlines, primary fill and glow
const GOLD_TEXT := Color("fff4dc")  # Heartlight: text on primary buttons
const WHISPER := Color("dccdb2")  # Moonpath
const POOR := Color("b8662c")  # Ember: unaffordable (with the 50% fade; the palette has no red)
const FOG := Color("05050d")  # Void: panel fog
const CARD_BG := Color("24243c")  # Night: the lit middle of a card, over Void
const BOSS := Color("9a84e8")  # Wraithlight: bosses (the palette has no red; the nightmares' own cold glow)
const LIVE := Color("d4ec9c")  # Newleaf: live bonuses, rewards
const OFF := Color("8c8cac")  # Stone: a bonus that is off right now
const MOONLIGHT := Color("dce8f4")  # Moonlight: the pale disc under nightmare portraits
const MOON_MIST := Color("b4b0c8")  # Mist: the disc's outer ring
const RARITY := [Color("b4b0c8"), Color("9cc46c"), Color("9cd4fc"), Color("e9a83c")]  # Mist, Sprig, Dewlight, Gold
const PALETTE_NAMES := {"INK": "Heartlight", "INK_DIM": "Mist", "GOLD": "Glow", "BUTTON_GOLD": "Gold",
	"GOLD_TEXT": "Heartlight", "WHISPER": "Moonpath", "POOR": "Ember", "FOG": "Void", "CARD_BG": "Night",
	"BOSS": "Wraithlight", "LIVE": "Newleaf", "OFF": "Stone",
	"MOONLIGHT": "Moonlight", "MOON_MIST": "Mist"}
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

static var _fonts := {}

# --- UI scale ----------------------------------------------------------------------------------

# The HUD is laid out for at least this much room (screens_ui.md: 1280×800 is the base, 16:9 needs
# 1280×720). The UI never scales past what leaves it this much, so it can't overlap itself.
const LAYOUT_MIN := Vector2(1280.0, 720.0)
const UI_SHARE_MIN := 0.5  # The settings slider: 50% … 100% of the fitting scale
const UI_SHARE_MAX := 1.0
# The settings dropdown's choices (user, 2026-10-01: a dropdown, not a slider): [name, share].
const UI_SIZES := [["Small", 0.6], ["Medium", 0.75], ["Large", 0.9], ["Largest (fits the screen)", 1.0]]

static var _scale_share := 1.0

# The root's content scale for a window of `window_size` pixels: the largest scale that still leaves
# LAYOUT_MIN (1.5 at 1920×1080, 1 at 1280×800, 2 at 4K), times the player's `share` of it.
static func ui_scale_factor(window_size: Vector2, share: float) -> float:
	var fit := clampf(minf(window_size.x / LAYOUT_MIN.x, window_size.y / LAYOUT_MIN.y), 0.5, 4.0)
	return fit * clampf(share, UI_SHARE_MIN, UI_SHARE_MAX)

# Applies the "ui_scale" setting (a share, see above) to the window, and again whenever the window
# changes size. Only the UI grows: GameCameraNode divides its zoom by the factor, so the map keeps
# its size. Headless runs (tests) stay at 1 so layouts are checked at the sizes they set.
static func apply_ui_scale(root: Window, share: float) -> void:
	_scale_share = share
	if root == null:
		return
	install_text_filter(root.get_tree() if root.is_inside_tree() else Engine.get_main_loop() as SceneTree)
	if DisplayServer.get_name() == "headless":
		root.content_scale_factor = 1.0
		return
	_set_factor(root)  # Godot re-fits on every resize by itself

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
	if tree.root != null:
		for node in tree.root.find_children("*", "Control", true, false):
			_linear_text(node)

static func _linear_text(node: Node) -> void:
	if not (node is Control) or (node as CanvasItem).texture_filter != CanvasItem.TEXTURE_FILTER_PARENT_NODE:
		return
	var is_text := node is Label or node is RichTextLabel or node is LineEdit or node is TextEdit
	if is_text or (node is Button and (node as Button).icon == null):
		(node as CanvasItem).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

# Godot's own canvas_items stretch does the fitting: base size LAYOUT_MIN with aspect "expand" scales
# by min(window / LAYOUT_MIN) (= ui_scale_factor's fit) and content_scale_factor = the share. Unlike a
# bare content_scale_factor (stretch "disabled"), this mode oversamples fonts: glyphs rasterize at
# their on-screen size instead of being scaled through the project's Nearest filter (jagged, strokes
# lost: "Seeds" read "Seecs", 2026-09-30).
static func _set_factor(root: Window) -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(LAYOUT_MIN)
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

# Alegreya Sans: card text, tooltips, panels. Every UI face is a FontVariation with SPACE_EXTRA: with
# subpixel positioning off (even letters at fractional UI scales), a space's advance rounds down to
# 0–1 px at some scales and words ran together ("Asmall splash", 2026-10-02); one extra pixel keeps
# every word gap visible.
const SPACE_EXTRA := 1
static func body_font() -> Font:
	return _spaced("body", "AlegreyaSans-Regular.ttf")

static func body_medium_font() -> Font:
	return _spaced("body_medium", "AlegreyaSans-Medium.ttf")

static func _spaced(key: String, file: String) -> Font:
	if not _fonts.has(key):
		if _fonts.is_empty():
			release_at_exit(func() -> void: _fonts.clear())
		var font := FontVariation.new()
		font.base_font = _file(file)
		font.spacing_space = SPACE_EXTRA
		_fonts[key] = font
	return _fonts[key]

# Cormorant Garamond SemiBold: titles, card names, buttons. Every Cormorant face uses lining figures
# (its default old-style ones read small in "Drift 8" or "1×").
static func display_font() -> Font:
	return _variation("display", "CormorantGaramond-Variable.ttf", 600, false)

# Cormorant Garamond SemiBold with lining, tabular figures: big numbers.
static func number_font() -> Font:
	return _variation("number", "CormorantGaramond-Variable.ttf", 600, true)

# Cormorant SC Medium: labels (lowercase small caps, a little tracking).
static func caps_font() -> Font:
	if not _fonts.has("caps"):
		var font := FontVariation.new()
		font.base_font = _file("CormorantSC-Medium.ttf")
		font.spacing_glyph = 1
		font.spacing_space = SPACE_EXTRA
		font.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("lnum"): 1}
		font.fallbacks = [body_font()]
		_fonts["caps"] = font
	return _fonts["caps"]

# Cormorant Garamond Italic: Heartwood whispers.
static func whisper_font() -> Font:
	return _variation("whisper", "CormorantGaramond-Italic-Variable.ttf", 500, false)

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

static func _variation(key: String, file: String, weight: int, tabular: bool) -> Font:
	if not _fonts.has(key):
		var ts := TextServerManager.get_primary_interface()
		var font := FontVariation.new()
		font.base_font = _file(file)
		font.variation_opentype = {ts.name_to_tag("wght"): weight}
		var features := {ts.name_to_tag("lnum"): 1}
		if tabular:
			features[ts.name_to_tag("tnum")] = 1
		font.opentype_features = features
		font.spacing_space = SPACE_EXTRA
		font.fallbacks = [body_font()]  # Symbols Cormorant lacks (✧, ⏎…)
		_fonts[key] = font
	return _fonts[key]

# --- Style boxes -------------------------------------------------------------------------------

# Every panel, card and tooltip: fog + gold thread + diamond.
static func panel(margin_x: float = 16.0, margin_y: float = 12.0) -> MoonStyleBox:
	var box := MoonStyleBox.new()
	_margins(box, margin_x, margin_y)
	return box

# Tips (native tooltips, TapTip, status / term popups): solid fog, the gold thread, a soft shadow, so
# the text never fights what's under it (user: "I can barely read them once they're hovering over text").
const TIP_ALPHA := 0.95
static func tip_panel() -> MoonStyleBox:
	var box := panel(12.0, 8.0)
	box.center_alpha = TIP_ALPHA
	box.edge_alpha = TIP_ALPHA
	box.shadow_size = 10
	return box

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
	return box

# Fog only, no thread: the resources and Dreams rows at the screen edge, Warden bar slots.
static func fog_patch(margin_x: float = 12.0, margin_y: float = 6.0) -> MoonStyleBox:
	var box := panel(margin_x, margin_y)
	box.thread = MoonStyleBox.TopLine.NONE
	box.center_alpha = 0.7
	box.edge_alpha = 0.0
	return box

# A Dream / family / Omen card: more solid fog, 2 px radius, faint sides, the full-width thread in
# `colour` (the rarity).
static func card(colour: Color, hover: bool = false) -> MoonStyleBox:
	var box := panel(18.0, 16.0)
	box.fog_color = FOG  # Night in the middle fading to Void at the rim, ~90% (ui_style.md)
	box.glow_color = CARD_BG.lightened(0.08) if hover else CARD_BG
	box.center_alpha = 0.96
	box.edge_alpha = 0.9
	box.corner_radius = 2
	box.side_edges = true
	box.shadow_size = 16
	box.thread = MoonStyleBox.TopLine.FULL
	box.thread_color = colour
	return box

# A Warden bar slot: a fog patch, and the glowing gold underline when selected.
# The light pass (UI Asset's final tokens, 2026-10-05; the user: "calmer, more transparent"): no box, a
# fog tile of Void .35 → .08. Hovered: a 1 px Gold inset at .35. Selected: a darker tile (.55 → .20), a
# 1 px Gold inset at .6 and the 2 px Glow underline with its glow.
static func slot(selected: bool, hover: bool = false) -> MoonStyleBox:
	var box := fog_patch(4.0, 4.0)
	box.center_alpha = 0.55 if selected else 0.35
	box.edge_alpha = 0.2 if selected else 0.08
	box.corner_radius = 2
	if selected:
		box.frame_color = Color(BUTTON_GOLD, 0.6)
	elif hover:
		box.frame_color = Color(BUTTON_GOLD, 0.35)
	box.underline = selected
	return box

# The Warden bar's backing panel (calmer than other panels): Void .55 in the middle → .18 at the rim,
# the thread at .6 and no mark. For the PanelContainer behind %TowerBar.
static func bar_panel() -> MoonStyleBox:
	var box := panel(10.0, 6.0)
	box.center_alpha = 0.55
	box.edge_alpha = 0.18
	box.thread_color = Color(GOLD, 0.6)
	box.diamond = false
	return box

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

# Buttons: 1 px gold outline at 45%, dark fog fill, 2 px radius.
static func button_box(hover: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(FOG, 0.62 if hover else 0.55)
	box.border_color = Color(BUTTON_GOLD, 0.8 if hover else 0.45)
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	_margins(box, 14.0, 6.0)
	return box

# Primary buttons (the panel's main action, Continue, Start): at rest only a solid gold outline on the
# fog, never a fill (user, 2026-09-30: "still seems highlighted when I'm not hovering"); hovering fills
# the whole box with the soft highlight, like every button.
# The one primary per panel (the user, 2026-10-05: "Don't make the button solid gold"): the dark fog
# fill like every button, but a warm 1 px Gold frame topped by the full thread with the Heartwood mark,
# Glow text in the display face, and a soft Ember glow inside that brightens on hover. It stands out by
# frame, text and glow, never by a fill. A press darkens it and drops the glow.
const PRIMARY_GLOW := Color("b8662c")  # Ember
static func primary_box(hover: bool = false, pressed: bool = false) -> MoonStyleBox:
	var box := MoonStyleBox.new()
	box.fog_color = FOG
	box.edge_alpha = 0.7 if pressed else 0.55
	box.glow_color = PRIMARY_GLOW
	# The Ember glow over the fog: about 18% at rest, 34% on hover (centre = 1 - (1 - glow)(1 - edge)).
	var glow := 0.0 if pressed else (0.34 if hover else 0.18)
	box.center_alpha = 1.0 - (1.0 - glow) * (1.0 - box.edge_alpha)
	box.corner_radius = 2
	box.frame_color = GOLD if hover else Color(BUTTON_GOLD, 0.85)
	box.thread = MoonStyleBox.TopLine.GOLD
	box.thread_color = Color(GOLD, 0.9)
	_margins(box, 14.0, 6.0)
	return box

# Selected vs hovered (screens_ui.md, playtest 2026-09-30: "First" selected and a hovered button looked
# alike). A selected / active control (toggled button, open tab, current speed, a switch's segment)
# shows only a GOLD border and gold text, no fill; hover fills the whole box with a soft highlight;
# a press darkens it. Godot's "pressed" style is both "toggled on" and "held", so it's the gold border
# on a darker fog: selected reads as the border, a held press as the darkening.
const HOVER_FILL := Color(MOONLIGHT, 0.16)  # The soft highlight (moonlight over the fog)
static func selected_box() -> StyleBoxFlat:
	var box := button_box()
	box.bg_color = Color(FOG, 0.7)
	box.border_color = GOLD
	box.set_border_width_all(2)
	return box

static func hover_box(selected: bool = false) -> StyleBoxFlat:
	var box := selected_box() if selected else button_box(true)
	box.bg_color = Color(FOG, 0.55).blend(HOVER_FILL)
	return box

static func disabled_box() -> StyleBoxFlat:
	var box := button_box()
	box.bg_color.a *= DISABLED_ALPHA
	box.border_color.a *= DISABLED_ALPHA
	return box

# Keyboard / controller focus: a thin gold ring just outside the control.
static func focus_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = Color(GOLD, 0.75)
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.set_expand_margin_all(2)
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

# Text-only, for actions that shouldn't compete with the primary (Sell, Close, Details ▸).
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
	row.add_theme_constant_override("separation", 0)
	var buttons := row.get_children().filter(func(n: Node) -> bool: return n is Button)
	for i in buttons.size():
		var button: Button = buttons[i]
		var first := i == 0
		var last := i == buttons.size() - 1
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color(FOG, 0.55)
			if state.begins_with("hover"):
				box.bg_color = box.bg_color.blend(HOVER_FILL)
			if state.ends_with("pressed"):
				box.bg_color = box.bg_color.blend(Color(BUTTON_GOLD, 0.12))
			box.border_color = Color(BUTTON_GOLD, 0.35)
			box.border_width_top = 1
			box.border_width_bottom = 1
			box.border_width_left = 1  # The first one's outer edge, then the dividers
			box.border_width_right = 1 if last else 0
			box.corner_radius_top_left = 2 if first else 0
			box.corner_radius_bottom_left = 2 if first else 0
			box.corner_radius_top_right = 2 if last else 0
			box.corner_radius_bottom_right = 2 if last else 0
			_margins(box, 8.0, 4.0)
			if state == "disabled":
				box.border_color.a *= DISABLED_ALPHA
			button.add_theme_stylebox_override(state, box)
		button.add_theme_color_override("font_color", INK_DIM)
		button.add_theme_color_override("font_hover_color", INK)
		for state in ["font_pressed_color", "font_hover_pressed_color"]:
			button.add_theme_color_override(state, GOLD)

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
	chip.add_theme_font_override("font", body_medium_font())
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
	return chip

# Gives a Button the card look in `colour` (normal + hover + pressed).
static func card_button(button: Button, colour: Color) -> void:
	var normal := card(colour)
	var hover := card(colour, true)
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

	# Panels and tooltips carry the thread.
	for type in ["PanelContainer", "Panel", "PopupPanel", "TooltipPanel", "PopupMenu", "AcceptDialog"]:
		theme.set_stylebox("panel", type, tip_panel() if type == "TooltipPanel" else panel(16.0, 12.0))  # Tips: solid
	theme.set_font_size("font_size", "TooltipLabel", TIP_SIZE)
	theme.set_constant("line_spacing", "TooltipLabel", TIP_LINE_SPACING)
	theme.set_stylebox("separator", "HSeparator", MoonDivider.new())
	theme.set_constant("separation", "HSeparator", 9)

	# Buttons (and the button-like controls).
	for type in ["Button", "OptionButton", "MenuButton"]:
		_button_styles(theme, type, button_box(), hover_box(), selected_box(), hover_box(true))
	theme.set_type_variation("PrimaryButton", "Button")
	# The call to action keeps its gold look; hovering fills it, pressing darkens it.
	var primary_press := primary_box(false, true)
	var primary_hover := primary_box(true)
	_button_styles(theme, "PrimaryButton", primary_box(), primary_hover, primary_press, primary_hover)
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
	var slot_boxes := [slot(false), slot(false, true), slot(true), slot(true, true), slot(false)]
	for i in 5:
		theme.set_stylebox(["normal", "hover", "pressed", "hover_pressed", "disabled"][i], "WardenSlot", slot_boxes[i])
	theme.set_stylebox("focus", "WardenSlot", StyleBoxEmpty.new())
	theme.set_font("font", "WardenSlot", number_font())
	theme.set_font_size("font_size", "WardenSlot", 13)  # The cost: 12.5 px Glow at .8 (rounded to 13)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, "WardenSlot", Color(GOLD, 0.8))

	# HUD buttons (top-right row, drift controls): compact, HUD_BUTTON_H tall, small caps at
	# HUD_TEXT_SIZE, the thin frame. HudPrimary is the same size in the call-to-action look (Start).
	theme.set_type_variation("HudButton", "Button")
	_button_styles(theme, "HudButton", _compact(button_box()), _compact(hover_box()), _compact(selected_box()),
		_compact(hover_box(true)))
	theme.set_type_variation("HudPrimary", "Button")
	_button_styles(theme, "HudPrimary", _compact(primary_box()), _compact(primary_hover), _compact(primary_press),
		_compact(primary_hover))
	for state in ["font_color", "font_focus_color", "font_pressed_color"]:
		theme.set_color(state, "HudPrimary", GOLD)
	for state in ["font_hover_color", "font_hover_pressed_color"]:
		theme.set_color(state, "HudPrimary", GOLD_TEXT)
	for type in ["HudButton", "HudPrimary"]:
		theme.set_font("font", type, caps_font())
		theme.set_font_size("font_size", type, HUD_TEXT_SIZE)
	theme.set_font("font", "HudPrimary", display_font())  # The primary speaks in the display face
	theme.set_font_size("font_size", "HudPrimary", HUD_TEXT_SIZE + 2)

	# Quiet buttons (the light pass): text only, Mist, Heartlight on hover; the padding keeps the hit
	# area HUD_BUTTON_H tall (platforms.md touch). Sell, Close, Details ▸, Peek at the map.
	theme.set_type_variation("QuietButton", "Button")
	var quiet_box := StyleBoxEmpty.new()
	_margins(quiet_box, 8.0, 14.0)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		theme.set_stylebox(state, "QuietButton", quiet_box)
	theme.set_stylebox("focus", "QuietButton", focus_box())
	theme.set_font("font", "QuietButton", body_font())
	theme.set_font_size("font_size", "QuietButton", 15)
	theme.set_color("font_color", "QuietButton", INK_DIM)
	for state in ["font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(state, "QuietButton", INK)
	theme.set_color("font_pressed_color", "QuietButton", GOLD)
	theme.set_color("font_disabled_color", "QuietButton", Color(INK_DIM, DISABLED_ALPHA))

	# Row buttons (the light pass: the Warden panel's grow options): no box, Heartlight text left-aligned,
	# a faint Night / Gold tint on hover; 48 px tall, a full touch target (platforms.md).
	theme.set_type_variation("RowButton", "Button")
	var row_idle := StyleBoxEmpty.new()
	_margins(row_idle, 8.0, 14.0)
	var row_hover := StyleBoxFlat.new()
	row_hover.bg_color = Color(CARD_BG, 0.55).blend(Color(BUTTON_GOLD, 0.08))
	row_hover.set_corner_radius_all(2)
	_margins(row_hover, 8.0, 14.0)
	for state in ["normal", "disabled"]:
		theme.set_stylebox(state, "RowButton", row_idle)
	for state in ["hover", "pressed", "hover_pressed"]:
		theme.set_stylebox(state, "RowButton", row_hover)
	theme.set_stylebox("focus", "RowButton", focus_box())
	theme.set_font("font", "RowButton", body_font())
	theme.set_font_size("font_size", "RowButton", 16)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		theme.set_color(state, "RowButton", INK)
	theme.set_color("font_disabled_color", "RowButton", Color(INK, DISABLED_ALPHA))

	# Tabs (the settings panel).
	var tab_selected := StyleBoxFlat.new()
	tab_selected.bg_color = Color(GOLD, 0.08)
	tab_selected.border_color = GOLD
	tab_selected.border_width_bottom = 2
	_margins(tab_selected, 14.0, 8.0)
	var tab_idle := tab_selected.duplicate() as StyleBoxFlat
	tab_idle.bg_color = Color(0, 0, 0, 0)
	tab_idle.border_color = Color(GOLD, 0.0)
	# The open tab: the gold line only, no fill; a hovered tab fills with the soft highlight.
	tab_selected.bg_color = Color(0, 0, 0, 0)
	var tab_hover := tab_idle.duplicate() as StyleBoxFlat
	tab_hover.bg_color = HOVER_FILL
	tab_hover.border_color = Color(GOLD, 0.4)
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
	var field := button_box()
	field.bg_color = Color(FOG, 0.7)
	theme.set_stylebox("normal", "LineEdit", field)
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
	theme.set_font("font", type, display_font())
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
