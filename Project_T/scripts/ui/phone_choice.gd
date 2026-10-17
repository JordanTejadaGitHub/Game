extends RefCounted

# Phones only (UiStyle.is_phone(); the PC never builds one): the one layout every choice screen shares, the Dream
# screen's (DreamScreen._build_phone_layout; user 2026-10-17: "The dream, omen, evolution, family pick don't match
# anymore"). A header row (the title and its small caps subtitle on the left, Peek at the map on the right: a small
# framed secondary button); the cards in equal columns across the width between MARGIN sides, each as tall as its
# content (a row shares its tallest's height), the row centred between the header and the bottom row (scrolling if one
# runs tall); the bottom row: the screen's own skip on the left, the whisper hint centred, Take on the right, the skip
# and Take the same width (the wider one's). One sprout per screen (UI owner's review 2026-10-17): the cards' threads
# run full width with no mark (card_thread); only Take carries it. A tap looks at a card (it lifts, the others dim to DIM_ALPHA); Take, or a second tap, takes it.
# Preloaded by OmenScreen, FamilyPickScreen and GiftScreen (no class_name). DreamScreen keeps the same numbers.

const MARGIN := 44.0  # DreamScreen.PHONE_MARGIN
const GAP := 12.0  # Between the cards
const LIFT := 1.04  # The looked card's scale (from its foot: it rises)
const DIM_ALPHA := 0.45  # The cards not looked at
const CHOICE_SIZE := Vector2(188, 56)  # Take and the skip: both real choices, the same size
const CARD_BUMP := 5  # DreamScreen.PHONE_CARD_BUMP
const TITLE_SIZE := 28
const SUBTITLE_SIZE := 15
const HINT_SIZE := 17
const CARD_MIN_H := 120.0  # A phone card's floor: cards size to their content (UI review: no empty fog under the text)
const CHOICE_MAX_SHARE := 0.34  # Take / the skip grow to their text up to this share of the view's width, then trim
const PEEK_TEXT := 15  # Peek at the map's text (a small utility)
const THREAD_ALPHA := 0.9  # The card's full-width thread
const CARD_PAD := Vector4(14, 12, 14, 12)  # Left, top, right, bottom inside a card (the Dream card's)
# Card text: the Dream card's sizes with the bump
const NAME_SIZE := UiStyle.CARD_NAME_SIZE + CARD_BUMP  # The card's name
const BODY_SIZE := 16 + CARD_BUMP  # Its effect
const SMALL_SIZE := 14 + CARD_BUMP  # Secondary lines
const KIND_SIZE := 15 + CARD_BUMP  # The small caps kind line
const LABEL_CAPS := 16  # The small caps line beside the gem (rarity, category)
const LOOK_HINT := "Tap a card to look at it"
const TAKE_HINT := "Take it, or tap another"
const LINK_TAP_MS := 350  # A card tap this soon after an underlined word's tap was for the word

var screen: Control
var margin: MarginContainer
var root: VBoxContainer
var header: HBoxContainer
var scroll: ScrollContainer
var bottom: HBoxContainer
var left: HBoxContainer  # The screen's skip / reroll (at least CHOICE_SIZE wide, so the hint stays centred)
var hint: Label
var take: Button
var cards: HBoxContainer
var looked: Button = null
var _link_tap_ms := -100000

func _init(for_screen: Control, title: Label, subtitle: Label, card_row: HBoxContainer) -> void:
	screen = for_screen
	cards = card_row
	margin = MarginContainer.new()
	margin.name = "PhoneLayout"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(MARGIN))
	margin.add_theme_constant_override("margin_right", int(MARGIN))
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	screen.add_child(margin)
	root = VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	header = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiStyle.title(title, TITLE_SIZE)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(title)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # A long title leaves it less room: it wraps, never pushes Peek off
	UiStyle.caps(subtitle, SUBTITLE_SIZE, UiStyle.INK_DIM)
	header.add_child(subtitle)
	scroll = ScrollContainer.new()
	scroll.name = "CardScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(scroll)
	cards.add_theme_constant_override("separation", int(GAP))
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Content height, centred between header and bottom row
	var pad := MarginContainer.new()  # Room above the cards for the looked one's lift (the scroll clips)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_child(cards)
	scroll.add_child(pad)
	bottom = HBoxContainer.new()
	bottom.name = "BottomRow"
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_theme_constant_override("separation", 12)
	root.add_child(bottom)
	left = HBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_theme_constant_override("separation", 12)
	left.custom_minimum_size.x = CHOICE_SIZE.x
	bottom.add_child(left)
	hint = Label.new()
	hint.name = "PhoneHint"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint.custom_minimum_size.x = 120
	hint.theme_type_variation = &"WhisperLabel"  # The whisper's dark shadow (FOG), no panel
	UiStyle.whisper(hint, HINT_SIZE)
	bottom.add_child(hint)
	take = Button.new()
	take.name = "TakeButton"
	take.focus_mode = Control.FOCUS_NONE
	UiStyle.primary(take)
	choice_button(take)
	take.pressed.connect(_take_looked)
	bottom.add_child(take)
	set_take("")

# Take's size and trim for a bottom row choice (the skip too: the same size, Take primary, the skip the framed button).
static func choice_button(button: Button) -> void:
	button.custom_minimum_size = CHOICE_SIZE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.clip_text = true  # A long name trims instead of widening one button past the other
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

# Peek at the map in the header's right corner: a small framed secondary button.
func add_peek(button: Control) -> void:
	peek_style(button)
	header.add_child(button)

# Peek's phone look (the Dream screen too): the plain framed button (not quiet), sized to its text, 48 tall.
static func peek_style(button: Control) -> void:
	button.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", PEEK_TEXT)

# A bottom-left button (the screen's skip): the same size as Take.
func add_left(button: Button) -> void:
	choice_button(button)
	left.add_child(button)
	fit_choices()

# Take and the skip the same width: the wider one's text, at least CHOICE_SIZE, at most CHOICE_MAX_SHARE of the view.
func fit_choices() -> void:
	var choices: Array = [take]
	for child in left.get_children():
		if child is Button and (child as Button).visible:
			choices.append(child)
	var width := match_widths(choices)
	if width > 0.0:
		left.custom_minimum_size.x = width  # The hint stays centred

# Sizes every Button in `buttons` to the widest one's text (the Dream screen's Let it pass and Take too). Returns the
# width, or 0 when one isn't in the tree yet (no theme to measure with).
static func match_widths(buttons: Array) -> float:
	var width := CHOICE_SIZE.x
	var cap := CHOICE_SIZE.x
	for button: Button in buttons:
		if not button.is_inside_tree():
			return 0.0
		cap = maxf(cap, floorf(button.get_viewport_rect().size.x * CHOICE_MAX_SHARE))
		width = maxf(width, text_width(button))
	width = minf(width, cap)
	for button: Button in buttons:
		button.custom_minimum_size.x = width
	return width

# The width `button` needs to show its text (and icon) untrimmed.
static func text_width(button: Button) -> float:
	var font := button.get_theme_font("font")
	var font_size := button.get_theme_font_size("font_size")
	var width := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x if font != null else 0.0
	var box := button.get_theme_stylebox("normal")
	if box != null:
		width += box.get_minimum_size().x
	if button.icon != null:
		width += button.icon.get_width() + button.get_theme_constant("h_separation")
	return ceilf(width + 6.0)

# One sprout per screen (UI review 2026-10-17): a phone choice card's thread runs its full width in `colour` with no
# mark (the Heartwood sprout is Take's alone); a clear `colour` keeps the card's own thread colour. Call it last, after
# ChoiceCard.solid and any other style tweak.
static func card_thread(button: Button, colour: Color = Color(0, 0, 0, 0)) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var style := button.get_theme_stylebox(state) as MoonStyleBox
		if style == null:
			continue
		if colour.a <= 0.0:
			colour = style.thread_color
		style = style.duplicate()
		style.thread = MoonStyleBox.TopLine.NONE
		style.diamond = false
		button.add_theme_stylebox_override(state, style)
	var line := ColorRect.new()
	line.name = "Thread"
	line.color = Color(colour, THREAD_ALPHA)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	line.offset_bottom = 1.0
	button.add_child(line)

# The width of each of `count` equal columns between the side margins (a little spare for a scroll bar).
func card_width(count: int) -> float:
	var room := screen.get_viewport_rect().size.x - 2.0 * MARGIN - GAP * (count - 1) - 16.0
	return floorf(room / maxf(count, 1.0))

# A card fills its column's width; its height is its content's (the row gives every card the tallest's height).
func fill(card: Control) -> void:
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL

# New cards: nothing looked at.
func reset() -> void:
	looked = null
	set_take("")

# A card's tap: true when the layout used it (it looked at the card, or the tap was on an underlined word), false
# when the card was already looked at and the screen should take it.
func tap(button: Button, take_text: String) -> bool:
	if Time.get_ticks_msec() - _link_tap_ms < LINK_TAP_MS:
		return true  # The tap was on an underlined word (its tip shows), not on the card
	if looked == button and is_instance_valid(button):
		return false
	look(button, take_text)
	return true

# Looks at `button`: it lifts, the others dim; Take names it.
func look(button: Button, take_text: String) -> void:
	looked = button
	for child in cards.get_children():
		var face := _face(child)
		if face == null:
			continue
		var on := face == button
		face.modulate = Color(1, 1, 1, 1.0 if on else DIM_ALPHA)  # multiplier
		_lift(face, on)
	set_take(take_text)

# Take reads `text` ("" = nothing looked at: dim, "Take"); the hint follows.
func set_take(text: String) -> void:
	var can := text != "" and looked != null and is_instance_valid(looked)
	take.disabled = not can
	take.modulate.a = 1.0 if can else 0.55  # multiplier: dim until there's something to take
	take.text = text if can else "Take"
	hint.text = TAKE_HINT if can else LOOK_HINT
	fit_choices()

# The card's underlined words: a tap shows the word's tip without looking at / taking the card.
func watch_links(card: Control) -> void:
	for label in card.find_children("*", "RichTextLabel", true, false):
		label.meta_clicked.connect(func(_meta: Variant) -> void: _link_tap_ms = Time.get_ticks_msec())

func _take_looked() -> void:
	if looked != null and is_instance_valid(looked) and not take.disabled:
		looked.pressed.emit()  # The card's own press: looked at already, so the screen takes it

func _face(child: Node) -> Button:
	if child is Button:
		return child
	for inner in child.get_children():
		if inner is Button:
			return inner
	return null

# The looked card rises a little from its foot; the others settle back. Reduced motion: no lift (the dim says it).
func _lift(face: Control, up: bool) -> void:
	if bool(Fx.setting("reduced_motion", false)):
		face.scale = Vector2.ONE
		return
	face.pivot_offset = Vector2(face.size.x / 2.0, face.size.y)
	UiTime.tween(face).tween_property(face, "scale", Vector2.ONE * (LIFT if up else 1.0), 0.16) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
