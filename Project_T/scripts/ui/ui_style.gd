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

const FONT_DIR := "res://assets/ui/fonts/"

static var _fonts := {}

# --- Fonts -------------------------------------------------------------------------------------

# Alegreya Sans: card text, tooltips, panels.
static func body_font() -> Font:
	return _file("AlegreyaSans-Regular.ttf")

static func body_medium_font() -> Font:
	return _file("AlegreyaSans-Medium.ttf")

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
		font.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("lnum"): 1}
		font.fallbacks = [body_font()]
		_fonts["caps"] = font
	return _fonts["caps"]

# Cormorant Garamond Italic: Heartwood whispers.
static func whisper_font() -> Font:
	return _variation("whisper", "CormorantGaramond-Italic-Variable.ttf", 500, false)

static func _file(file: String) -> Font:
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
		font.fallbacks = [body_font()]  # Symbols Cormorant lacks (✧, ⏎…)
		_fonts[key] = font
	return _fonts[key]

# --- Style boxes -------------------------------------------------------------------------------

# Every panel, card and tooltip: fog + gold thread + diamond.
static func panel(margin_x: float = 16.0, margin_y: float = 12.0) -> MoonStyleBox:
	var box := MoonStyleBox.new()
	_margins(box, margin_x, margin_y)
	return box

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
static func slot(selected: bool, hover: bool = false) -> MoonStyleBox:
	var box := fog_patch(4.0, 4.0)
	box.center_alpha = 0.85 if hover or selected else 0.75
	box.underline = selected
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

# Primary and toggled buttons: gold at 16% fill, solid gold outline, a soft gold glow.
static func primary_box(hover: bool = false) -> StyleBoxFlat:
	var box := button_box()
	box.bg_color = Color(BUTTON_GOLD, 0.24 if hover else 0.16)
	box.border_color = GOLD if hover else BUTTON_GOLD
	box.shadow_color = Color(BUTTON_GOLD, 0.3)
	box.shadow_size = 8
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

static func _margins(box: StyleBox, x: float, y: float) -> void:
	box.content_margin_left = x
	box.content_margin_right = x
	box.content_margin_top = y
	box.content_margin_bottom = y

# --- Helpers for screens built in code ---------------------------------------------------------

static func rarity_color(rarity: int) -> Color:
	return RARITY[clampi(rarity, 0, RARITY.size() - 1)]

# The rarity gem (screens_ui.md: shape AND colour): Common circle, Uncommon diamond, Rare hexagon,
# Legendary star, `r` px from the centre.
static func draw_gem(canvas: CanvasItem, centre: Vector2, r: float, rarity: int) -> void:
	var colour := rarity_color(rarity)
	var dark := Color(FOG, 0.9)
	if rarity == 0:
		canvas.draw_circle(centre, r, dark)
		canvas.draw_circle(centre, r - 2.0, colour)
		return
	var corners: int = {1: 4, 2: 6}.get(rarity, 10)
	var points := PackedVector2Array()
	for i in corners:
		var radius := r if corners < 10 or i % 2 == 0 else r * 0.5  # Legendary: a star
		points.append(centre + Vector2.from_angle(TAU * i / corners - PI / 2.0) * radius)
	canvas.draw_colored_polygon(points, colour)
	points.append(points[0])
	canvas.draw_polyline(points, dark, 2.0, true)

# The display face at `font_size`, keeping the control's colour.
static func display(control: Control, font_size: int = TITLE_SIZE) -> void:
	control.add_theme_font_override("font", display_font())
	control.add_theme_font_size_override("font_size", font_size)

static func title(label: Control, font_size: int = TITLE_SIZE, colour: Color = INK) -> void:
	_font(label, display_font(), font_size, colour)

static func number(label: Control, font_size: int = NUMBER_SIZE, colour: Color = GOLD) -> void:
	_font(label, number_font(), font_size, colour)

# Lowercase small-caps label ("act 1 · forest's edge"); the text is lower-cased here.
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
		theme.set_stylebox("panel", type, panel(12.0 if type == "TooltipPanel" else 16.0, 8.0 if type == "TooltipPanel" else 12.0))
	theme.set_font_size("font_size", "TooltipLabel", 15)
	theme.set_stylebox("separator", "HSeparator", MoonDivider.new())
	theme.set_constant("separation", "HSeparator", 9)

	# Buttons (and the button-like controls).
	for type in ["Button", "OptionButton", "MenuButton"]:
		_button_styles(theme, type, button_box(), button_box(true), primary_box(), primary_box(true))
	theme.set_type_variation("PrimaryButton", "Button")
	_button_styles(theme, "PrimaryButton", primary_box(), primary_box(true), primary_box(true), primary_box(true))
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		theme.set_color(state, "PrimaryButton", GOLD_TEXT)
	# Check boxes / switches: no box, just the text (and the toggle's own icon).
	for type in ["CheckBox", "CheckButton"]:
		var empty := StyleBoxEmpty.new()
		_margins(empty, 6.0, 4.0)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			theme.set_stylebox(state, type, empty)
		_font_colours(theme, type)

	# Warden bar slot: a fog patch; selected = the glowing underline.
	theme.set_type_variation("WardenSlot", "Button")
	for state in ["normal", "disabled"]:
		theme.set_stylebox(state, "WardenSlot", slot(false))
	theme.set_stylebox("hover", "WardenSlot", slot(false, true))
	for state in ["pressed", "hover_pressed"]:
		theme.set_stylebox(state, "WardenSlot", slot(true))
	theme.set_stylebox("focus", "WardenSlot", StyleBoxEmpty.new())
	theme.set_font("font", "WardenSlot", number_font())
	theme.set_font_size("font_size", "WardenSlot", 16)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, "WardenSlot", GOLD)

	# Tabs (the settings panel).
	var tab_selected := StyleBoxFlat.new()
	tab_selected.bg_color = Color(GOLD, 0.08)
	tab_selected.border_color = GOLD
	tab_selected.border_width_bottom = 2
	_margins(tab_selected, 14.0, 8.0)
	var tab_idle := tab_selected.duplicate() as StyleBoxFlat
	tab_idle.bg_color = Color(0, 0, 0, 0)
	tab_idle.border_color = Color(GOLD, 0.0)
	var tab_hover := tab_idle.duplicate() as StyleBoxFlat
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
	theme.set_color("font_shadow_color", "WhisperLabel", Color(0, 0, 0, 0.9))
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
	theme.set_color("font_hover_color", type, Color.WHITE)
	theme.set_color("font_focus_color", type, INK)
	theme.set_color("font_pressed_color", type, INK)
	theme.set_color("font_hover_pressed_color", type, Color.WHITE)
	theme.set_color("font_disabled_color", type, Color(INK, DISABLED_ALPHA))
	theme.set_color("icon_disabled_color", type, Color(1, 1, 1, DISABLED_ALPHA))
