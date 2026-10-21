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
# User 2026-10-18 ("add a glossary and your dream in button in the top right and peek in the bottom left"): the header's
# right holds Glossary (the Codex on its Glossary tab, over the screen: CodexOverlay) and Your Dreams ("Dreams this run",
# drawn above the screen: HUD.open_dreams_over); Peek at the map opens the bottom row, before the skip. The bottom row's
# two sides are balanced (balance) so the whisper hint stays centred.

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
const GLOSSARY_TEXT := "Glossary"
const DREAMS_TEXT := "Your Dreams"
const OVER_Z := 30  # The Codex / Dreams page over a choice screen: above its card diagram / scene (z 10)
const HINT_MIN := 120.0  # The hint's least width (balance keeps the sides mirrored only while it fits)

var screen: Control
var margin: MarginContainer
var root: VBoxContainer
var header: HBoxContainer
var scroll: ScrollContainer
var bottom: HBoxContainer
var left: HBoxContainer  # Peek at the map, then the screen's skip / reroll (balanced with `right`)
var hint: Label
var right: HBoxContainer  # Take (balanced with `left`, so the hint stays centred)
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
	add_extras(screen, header)
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
	bottom.add_child(left)
	hint = Label.new()
	hint.name = "PhoneHint"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint.custom_minimum_size.x = HINT_MIN
	hint.theme_type_variation = &"WhisperLabel"  # The whisper's dark shadow (FOG), no panel
	UiStyle.whisper(hint, HINT_SIZE)
	bottom.add_child(hint)
	right = HBoxContainer.new()
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_child(right)
	take = Button.new()
	take.name = "TakeButton"
	take.focus_mode = Control.FOCUS_NONE
	UiStyle.primary(take)
	choice_button(take)
	take.pressed.connect(_take_looked)
	right.add_child(take)
	set_take("")

# Take's size and trim for a bottom row choice (the skip too: the same size, Take primary, the skip the framed button).
static func choice_button(button: Button) -> void:
	button.custom_minimum_size = CHOICE_SIZE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.clip_text = true  # A long name trims instead of widening one button past the other
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

# Peek at the map at the bottom row's left, before the skip: a small framed secondary button (user 2026-10-18).
func add_peek(button: Control) -> void:
	peek_style(button)
	button.set_meta(&"peek", true)
	left.add_child(button)
	left.move_child(button, 0)
	fit_choices()

# The Sapling's card holds its own choices: the bottom row keeps only Peek (`on` false), or shows them all again.
func set_choices_visible(on: bool) -> void:
	hint.visible = on
	right.visible = on
	for child in left.get_children():
		if child is Control and not child.has_meta(&"peek"):
			(child as Control).visible = on
	fit_choices()

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
# Peek keeps its own size; the two sides are then balanced so the hint stays centred.
func fit_choices() -> void:
	var choices: Array = [take]
	for child in left.get_children():
		if child is Button and (child as Button).visible and not child.has_meta(&"peek"):
			choices.append(child)
	match_widths(choices)
	balance(left, right, bottom)

# The bottom row's two sides as wide as the wider one, so the hint between them stays centred; when mirroring would
# squeeze the hint under HINT_MIN, each side keeps its own width.
static func balance(left_box: Control, right_box: Control, row: HBoxContainer) -> void:
	if not row.is_inside_tree():
		return
	left_box.custom_minimum_size.x = 0.0
	right_box.custom_minimum_size.x = 0.0
	var side := maxf(_row_width(left_box), _row_width(right_box))
	var gap := float(row.get_theme_constant("separation"))
	var room := row.get_viewport_rect().size.x - 2.0 * MARGIN
	if 2.0 * side + HINT_MIN + 2.0 * gap <= room:
		left_box.custom_minimum_size.x = side
		right_box.custom_minimum_size.x = side

# The width a side's visible children need side by side.
static func _row_width(box: Control) -> float:
	if not box.visible:
		return 0.0
	var width := 0.0
	var shown := 0
	for child in box.get_children():
		if child is Control and (child as Control).visible:
			width += (child as Control).get_combined_minimum_size().x
			shown += 1
	return width + float(box.get_theme_constant("separation")) * maxi(shown - 1, 0)

# --- Glossary and Your Dreams (the header's right; user 2026-10-18) ----------------------------------------------------
# Two framed secondary buttons, Peek's look. Glossary opens the Codex on its Glossary tab over the screen; Your Dreams
# opens the HUD's full-screen "Dreams this run" above it (hidden while the run has no Dreams and no Calling). Closing
# either returns to the screen, which stays open underneath; Android Back closes the top-most first.
static func add_extras(for_screen: Control, row: HBoxContainer) -> void:
	var glossary := Button.new()
	glossary.name = "GlossaryButton"
	glossary.text = GLOSSARY_TEXT
	glossary.focus_mode = Control.FOCUS_NONE
	peek_style(glossary)
	glossary.pressed.connect(func() -> void: open_glossary(for_screen))
	row.add_child(glossary)
	var dreams := Button.new()
	dreams.name = "YourDreamsButton"
	dreams.text = DREAMS_TEXT
	dreams.focus_mode = Control.FOCUS_NONE
	peek_style(dreams)
	dreams.pressed.connect(func() -> void: open_dreams(for_screen))
	row.add_child(dreams)
	for_screen.visibility_changed.connect(func() -> void: _on_screen_visibility(for_screen, dreams))
	dreams.visible = has_dreams(for_screen)

static func _on_screen_visibility(for_screen: Control, dreams: Button) -> void:
	if for_screen.visible:
		dreams.visible = has_dreams(for_screen)
	else:
		close_glossary(for_screen)
		close_dreams(for_screen)

# True once the run has a Calling or a Dream taken (Your Dreams has something to show).
static func has_dreams(node: Node) -> bool:
	if not node.is_inside_tree():
		return false
	var state := node.get_tree().get_first_node_in_group(&"dream_state") as DreamState
	if state == null:
		return false
	return state.calling != "" or not state.get_taken_cards().is_empty()

static func open_glossary(for_screen: Control) -> void:
	close_dreams(for_screen)
	var over := for_screen.get_node_or_null("ChoiceCodex") as CodexOverlay
	if over == null:
		over = CodexOverlay.new()
		over.name = "ChoiceCodex"
		for_screen.add_child(over)
	for_screen.move_child(over, for_screen.get_child_count() - 1)  # Above the screen's cards, diagram and Peek pill
	over.open_glossary()

static func close_glossary(for_screen: Control) -> void:
	var over := for_screen.get_node_or_null("ChoiceCodex") as CodexOverlay
	if over != null and over.visible:
		over.close()

static func glossary_open(for_screen: Control) -> bool:
	var over := for_screen.get_node_or_null("ChoiceCodex") as CodexOverlay
	return over != null and over.visible

static func open_dreams(for_screen: Control) -> void:
	close_glossary(for_screen)
	var hud := for_screen.get_parent()
	if hud != null and hud.has_method("open_dreams_over"):
		hud.call("open_dreams_over", for_screen)

static func close_dreams(for_screen: Control) -> void:
	var hud := for_screen.get_parent()
	if hud != null and hud.has_method("close_dreams_over"):
		hud.call("close_dreams_over", for_screen)

# The Codex over a phone choice screen: a solid pane (the phone pause menu's Codex page) on a dim that takes every tap;
# its ✕ or Android Back closes it, and the screen underneath is as it was.
class CodexOverlay extends Control:
	const PAD := 16
	var codex: CodexPanel

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS  # The choice screen keeps the game paused
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		z_index = 30  # PhoneChoice.OVER_Z: above the Dream diagram / gift scene (z 10)
		visible = false
		var dim := ColorRect.new()
		dim.color = Color(UiStyle.FOG, 0.85)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
			margin.add_theme_constant_override(side, PAD)
		add_child(margin)
		var pane := PanelContainer.new()
		pane.name = "Pane"
		var fill := UiStyle.panel()
		fill.center_alpha = UiStyle.TIP_ALPHA  # Solid, as the pause menu's pane
		fill.edge_alpha = UiStyle.TIP_ALPHA
		pane.add_theme_stylebox_override("panel", fill)
		margin.add_child(pane)
		codex = CodexPanel.new()
		codex.embedded = true
		pane.add_child(codex)
		codex.add_theme_stylebox_override("panel", StyleBoxEmpty.new())  # The pane draws the frame
		codex.visibility_changed.connect(_on_codex_visibility)

	func open_glossary() -> void:
		visible = true
		codex.open(&"glossary")

	func close() -> void:
		codex.visible = false
		visible = false

	func _on_codex_visibility() -> void:
		if not codex.visible:
			visible = false  # Its ✕: back to the choice screen

	# Android Back (open_menu) closes the Codex first, before the pause menu would open over the screen.
	func _input(event: InputEvent) -> void:
		if is_visible_in_tree() and InputMap.has_action("open_menu") and event.is_action_pressed("open_menu"):
			close()
			get_viewport().set_input_as_handled()

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
		if style.frame != &"":
			style.accent = Color(colour, THREAD_ALPHA)  # Moon-glass: the line sits inside the rim (no extra ColorRect)
		button.add_theme_stylebox_override(state, style)
	var framed := button.get_theme_stylebox("normal") is MoonStyleBox and (button.get_theme_stylebox("normal") as MoonStyleBox).frame != &""
	if framed:
		return
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

# A disabled Take draws as the normal secondary button (frame and ink text); the caller dims it to 45% (UI Asset
# 2026-10-17: the disabled primary was almost invisible, the player couldn't see where Take would be).
static func disabled_look(button: Button) -> void:
	if button.has_theme_stylebox_override("disabled"):
		return
	button.add_theme_stylebox_override("disabled", button.get_theme_stylebox("normal", &"Button"))
	button.add_theme_color_override("font_disabled_color", UiStyle.INK)

# Take reads `text` ("" = nothing looked at: dim, "Take"); the hint follows.
func set_take(text: String) -> void:
	var can := text != "" and looked != null and is_instance_valid(looked)
	take.disabled = not can
	disabled_look(take)
	take.modulate.a = 1.0 if can else 0.45  # multiplier: the secondary frame at 45% until there's something to take
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
