extends Control

# Full-screen Dream offer: pick 1 of 3 cards, or let it pass for a little Dew. Pauses the game
# while open (restoring the previous pause state after). Built in code.

const CARD_SIZE := Vector2(250, 220)
const CARD_PADDING := 24.0  # The box's top + bottom offsets inside a card
const SECONDARY_SIZE := 12  # Entwined / Deepened / "Needs Dewdrop" lines
const SECONDARY_MIN_SIZE := 10
const SCREEN_MARGIN := 240.0  # Title, buttons and gaps around the cards
const SIDE_MARGIN := 16.0  # Left and right of the card row when many cards (5) narrow it
const ENTWINED_COLOR := Palette.SPRIG  # Vine border
const DEEPENED_COLOR := Palette.DEWLIGHT
const BITTERSWEET_COLOR := UiStyle.POOR  # The cost line: Ember, the palette's "bad" colour
const SEED_COLOR := Color("d4ec9c")  # Heartwood 32 "Newleaf": what a Seed card grows into

@onready var dream_state: DreamState = %DreamState
@onready var game_speed: GameSpeed = %GameSpeed

var _was_paused := false
var _title := Label.new()
var _cards := HBoxContainer.new()
var _card_width := CARD_SIZE.x  # Narrower when 5 cards (Thick Blight + Wider Dreams) would pass the screen
var _skip := Button.new()
var _reroll := Button.new()  # Second Thoughts (Memory Grove)
var _dev_any := Button.new()  # "Dev: any card…" (dev runs of debug builds; demo_scope.md "Pick any card")
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")
var _diagram: CardDiagram = null  # The hovered placement card's map picture (dream_design.md "Placement cards show a diagram")
var _held_for_diagram := false  # A long-press showed the diagram: that release doesn't take the card
const LONG_PRESS := 0.45

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.title(_title, UiStyle.CHOICE_TITLE_SIZE)
	box.add_child(_title)
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.pressed.connect(dream_state.skip)
	_reroll.focus_mode = Control.FOCUS_NONE
	_reroll.pressed.connect(dream_state.reroll)
	var skip_row := HBoxContainer.new()
	skip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skip_row.add_theme_constant_override("separation", 16)
	skip_row.add_child(_reroll)
	skip_row.add_child(_skip)
	_dev_any.text = "Dev: any card…"
	_dev_any.focus_mode = Control.FOCUS_NONE
	_dev_any.pressed.connect(func() -> void: DevCardPicker.open(self, dream_state, dream_state.choose_any))
	skip_row.add_child(_dev_any)
	box.add_child(skip_row)
	peek = ChoicePeek.new(self, [dim, center], "Back to the Dream")
	box.add_child(peek.make_peek_button())

	visible = false
	dream_state.offer_ready.connect(_show_offer)
	dream_state.offer_closed.connect(_on_closed)

func _show_offer(cards: Array[UpgradeData], drift_number: int) -> void:
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	_title.text = "A Dream, after drift %d" % drift_number
	if dream_state.has_rule(&"lucid_dreaming"):  # Take 2 of 4
		_title.text += " · take %d" % dream_state.picks_left if dream_state.picks_left > 1 else " · take 1 more"
	_skip.text = "Let it pass · +%d Dew" % dream_state.skip_dew if dream_state.skip_dew > 0 else "Let it pass"
	_skip.visible = dream_state.can_skip()  # Restless Dreams
	_dev_any.visible = DreamState.dev_tools_on()
	_reroll.text = "Dream again · %d left" % dream_state.rerolls_left
	_reroll.visible = dream_state.rerolls_left > 0
	var gap := float(_cards.get_theme_constant("separation"))
	var room := get_viewport_rect().size.x - 2.0 * SIDE_MARGIN - gap * (cards.size() - 1)
	_card_width = minf(CARD_SIZE.x, floorf(room / maxf(cards.size(), 1.0)))
	for child in _cards.get_children():
		_cards.remove_child(child)  # Right away: a reroll rebuilds the row in the same frame
		child.queue_free()
	for card in cards:
		var column := VBoxContainer.new()
		column.add_child(_make_card(card))
		if dream_state.banishes_left > 0:  # Let Go (Memory Grove)
			var let_go := Button.new()
			let_go.text = "Let go · %d left" % dream_state.banishes_left
			let_go.tooltip_text = "This card won't come back this run; another takes its place."
			let_go.focus_mode = Control.FOCUS_NONE
			let_go.pressed.connect(dream_state.banish.bind(card))
			column.add_child(let_go)
		_cards.add_child(column)
	visible = true

func _make_card(card: UpgradeData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(_card_width, CARD_SIZE.y)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		if _held_for_diagram:
			_held_for_diagram = false  # The long-press was to look, not to take
			return
		dream_state.choose(card))
	if CardDiagram.has_diagram(card):
		button.mouse_entered.connect(show_diagram.bind(card, button))
		button.mouse_exited.connect(hide_diagram)
		button.button_down.connect(func() -> void:  # Touch: a long-press shows it
			await get_tree().create_timer(LONG_PRESS, true).timeout
			if is_instance_valid(button) and button.button_pressed:
				_held_for_diagram = true
				show_diagram(card, button))
		button.button_up.connect(func() -> void:
			if not _held_for_diagram:
				return
			hide_diagram())
	# Moonlit Thread card (ui_style.md): solid fog, the top thread in the rarity colour (Entwined: the
	# vine green; Woven: glowing).
	UiStyle.card_button(button, ENTWINED_COLOR if card.entwined else UpgradeData.rarity_color(card.rarity))
	if card.woven:
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			(button.get_theme_stylebox(state) as MoonStyleBox).underline = true  # A glowing line along the foot too
	if MetaRun.starlit_backs():
		_add_starlit_back(button, card)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var rarity := Label.new()
	rarity.text = UpgradeData.rarity_name(card.rarity)
	var stack_count := dream_state.card_stacks(card.id)
	if card.max_stacks == 0 and stack_count > 0:
		rarity.text += " · " + _roman(stack_count + 1)
	UiStyle.caps(rarity, 16, UpgradeData.rarity_color(card.rarity))
	rarity.text = rarity.text.to_upper().left(1) + rarity.text.substr(1)  # Small caps with a capital
	var gem_row := HBoxContainer.new()
	gem_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gem_row.add_theme_constant_override("separation", 8)
	var gem := Control.new()
	gem.custom_minimum_size = Vector2(18, 18)
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gem.draw.connect(func() -> void: UiStyle.draw_gem(gem, gem.size / 2.0, 8.0, card.rarity))
	gem_row.add_child(gem)
	gem_row.add_child(rarity)
	box.add_child(gem_row)
	var name_label := Label.new()
	name_label.text = card.display_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.title(name_label, UiStyle.CARD_NAME_SIZE)
	box.add_child(name_label)
	if dream_state.opens_clearing(card):
		_add_opens_clearing(button, box)
	# The effect comes right after the name; it never shrinks.
	_add_linked_line(box, card.description, UiStyle.INK, 16)
	var res := dream_state.resonance_preview(card)
	if res.bonus > 0.0:  # Tag resonance (dream_audit.md): "+20% from 2 spore cards"
		_add_line(box, DreamState.resonance_text(res.bonus, res.tag, res.count), UiStyle.GOLD, 14).name = "ResonanceLine"
	var live: String = dream_state.effects().preview_line(card)
	if live != "":  # Scaling cards: where you stand now (dream_design.md #75)
		_add_line(box, live, UiStyle.GOLD, 14).name = "LiveLine"
	if card.cost_description != "":
		_add_linked_line(box, card.cost_description, BITTERSWEET_COLOR, 15)
	if card.grows_text != "":  # Seed cards: the bigger effect once its Wardens are yours
		_add_linked_line(box, "🌱 Grows with %s: %s" % [_grows_with_names(card), card.grows_text], SEED_COLOR, 14)
	# Secondary lines below, smaller and muted; they shrink first when a card runs out of room.
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	var secondary: Array[Label] = []
	if card.entwined:  # The vine border says it; no "Entwined" label (user: "still don't know what Entwined is")
		if card.woven:
			secondary.append(_add_line(box, "Woven", ENTWINED_COLOR, SECONDARY_SIZE))
	elif card.is_deepened():
		secondary.append(_add_line(box, "Deepened · replaces %s" % dream_state.get_display_name(card.deepens), DEEPENED_COLOR, SECONDARY_SIZE))
	elif card.is_bittersweet():
		secondary.append(_add_line(box, "Bittersweet", BITTERSWEET_COLOR, SECONDARY_SIZE))
	if dream_state.is_half_dreamed(card):  # One muted line, no label (dream_design.md half-dreamed "Card face")
		_add_missing_row(box, card)  # "Needs Wind": the damage type, linked
	else:
		_add_needs_row(box, card)  # "Needs: Soaked + Charged" / "Nestling family": never a Warden's name
	if dream_state.calls_family_now(card) != "":  # A Seed card calls its family to the next pick (not one you own)
		secondary.append(_add_line(box, "Seed · calls %s to your next family pick" % dream_state.get_display_name(card.calls_family), SEED_COLOR, SECONDARY_SIZE))
	for label in secondary:
		label.modulate.a = 0.85  # Muted
	for label in [rarity, name_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL  # The row gives every card the tallest's height
	_fit_card(button, box, secondary)
	return button

# While clearing is locked, a clearing card leads with what it unlocks (dream_design.md "Clearing
# cards" / "Make the unlock obvious"): the Clear tool icon + "Unlocks clearing", what clearing is, a
# thin divider, then the card's own effect; and a gold "Opens clearing" tag in the corner.
func _add_opens_clearing(button: Button, box: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	var icon := TextureRect.new()
	var frame := AtlasTexture.new()
	frame.atlas = ClearToolButton.ICON_SHEET
	frame.region = Rect2(64, 0, 64, 64)  # The "available" frame
	icon.texture = frame
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var line := Label.new()
	line.text = DreamState.OPENS_CLEARING_LINE
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.caps(line, 16, UiStyle.GOLD)
	row.add_child(line)
	box.add_child(row)
	_add_line(box, DreamState.OPENS_CLEARING_TEXT, UiStyle.INK, 14)
	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(divider)
	var tag := Label.new()
	tag.name = "OpensClearingTag"
	tag.text = DreamState.OPENS_CLEARING_TAG
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.caps(tag, 12, UiStyle.GOLD)
	tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 10)
	tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	button.add_child(tag)

# A card grows to fit its content (a Button doesn't size to its children), at least CARD_SIZE tall.
# If that would pass the screen, the secondary lines shrink first, never the effect.
# Starlit card backs ("Dream of everything", meta_design.md; art: meta_assets.md "starlit_card.png"):
# a night-sky 9-slice frame drawn behind the card's own style, whose fog is thinned so the stars show.
# The thread, gem and Bittersweet line stay on top. Four twinkle frames cycle slowly.
const STARLIT_TEXTURE := preload("res://assets/meta/ui/starlit_card.png")
const STARLIT_FRAME := Vector2(250, 220)
const STARLIT_MARGIN := 28
const STARLIT_FRAMES := 4
const STARLIT_FPS := 3.5
const STARLIT_FOG_EDGE := 0.2
const STARLIT_FOG_CENTRE := 0.45

func _add_starlit_back(button: Button, _card: UpgradeData) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var style := button.get_theme_stylebox(state) as MoonStyleBox
		if style:
			style = style.duplicate()  # Only this card's fog thins
			style.edge_alpha = STARLIT_FOG_EDGE
			style.center_alpha = STARLIT_FOG_CENTRE
			button.add_theme_stylebox_override(state, style)
	var sky := NinePatchRect.new()
	sky.name = "StarlitBack"
	sky.texture = STARLIT_TEXTURE
	sky.region_rect = Rect2(Vector2.ZERO, STARLIT_FRAME)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		sky.set_patch_margin(side, STARLIT_MARGIN)
	sky.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	sky.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	sky.show_behind_parent = true
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(sky)
	var twinkle := Timer.new()
	twinkle.wait_time = 1.0 / STARLIT_FPS
	twinkle.autostart = true
	twinkle.process_mode = Node.PROCESS_MODE_ALWAYS  # The Dream screen pauses the game
	twinkle.timeout.connect(func() -> void:
		var frame := (int(sky.region_rect.position.x / STARLIT_FRAME.x) + 1) % STARLIT_FRAMES
		sky.region_rect = Rect2(Vector2(frame * STARLIT_FRAME.x, 0), STARLIT_FRAME))
	sky.add_child(twinkle)

func _fit_card(button: Button, box: Control, secondary: Array[Label]) -> void:
	var fit := func() -> void:
		if not is_instance_valid(button):
			return
		var needed := box.get_combined_minimum_size().y + CARD_PADDING
		if needed > get_viewport_rect().size.y - SCREEN_MARGIN:
			for label in secondary:
				if label.get_theme_font_size("font_size") > SECONDARY_MIN_SIZE:
					label.add_theme_font_size_override("font_size", SECONDARY_MIN_SIZE)  # Refits via minimum_size_changed
		button.custom_minimum_size = Vector2(_card_width, maxf(CARD_SIZE.y, needed))
	box.minimum_size_changed.connect(fit)
	fit.call_deferred()

func _add_line(box: VBoxContainer, text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return label

# Card text with its status words as links ({damp} tokens → today's names). The label passes clicks
# through, so a click still takes the card; hovering a status word (PC) shows its definition.
func _add_linked_line(box: VBoxContainer, text: String, color: Color, font_size: int) -> RichTextLabel:
	var label := StatusLinks.make_label(text, font_size, color)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(label)
	return label

# The diagram panel beside `button` (right of it, or left when there's no room), kept on screen.
func show_diagram(card: UpgradeData, button: Control) -> void:
	hide_diagram()
	_diagram = CardDiagram.make(card)
	if _diagram == null:
		return
	_diagram.name = "CardDiagram"
	_diagram.z_index = 10
	add_child(_diagram)
	await get_tree().process_frame
	if not is_instance_valid(_diagram) or not is_instance_valid(button):
		return
	var card_rect := button.get_global_rect()
	var view := get_viewport_rect().size
	var size := _diagram.get_combined_minimum_size()
	var x := card_rect.end.x + 8.0
	if x + size.x > view.x - 8.0:
		x = card_rect.position.x - size.x - 8.0
	var y := clampf(card_rect.position.y + 24.0, 8.0, view.y - size.y - 8.0)
	_diagram.global_position = Vector2(maxf(x, 8.0), y)

func hide_diagram() -> void:
	if _diagram != null and is_instance_valid(_diagram):
		_diagram.queue_free()
	_diagram = null

func _on_closed() -> void:
	hide_diagram()
	# If another Dream is queued, offer_ready follows right away and shows (and pauses) again.
	visible = false
	game_speed.set_paused(_was_paused)

static func _roman(n: int) -> String:
	var numerals := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	return numerals[n - 1] if n <= numerals.size() else str(n)

# "Dewcatcher, Wellspring", or "the Rootling line" when a Seed names a whole line.
# "the Acorn line": a Seed card always names the family, never a Warden you may not have.
func _grows_with_names(card: UpgradeData) -> String:
	var id := card.calls_family if card.calls_family != "" else (card.grows_with[0] if not card.grows_with.is_empty() else "")
	return "the %s line" % dream_state.family_name_for(id)

# The Needs row (dream_design.md "How Needs are shown on a card", 2026-09-30): only what's still missing.
# Missing families in the damage-type style ("Needs Water"); statuses none of your Wardens apply (icon +
# name); card ingredients not taken yet. Nothing missing = no line.
func _add_needs_row(box: VBoxContainer, card: UpgradeData) -> void:
	_add_missing_row(box, card)  # Families you don't own yet
	var parts := dream_state.needs_parts(card)
	var statuses: Array = parts.statuses.filter(func(s: Array) -> bool: return not s[1])
	var cards: Array = []
	for id in card.requires:
		if dream_state.family_name_for(id) == "" and not dream_state.has_card(id) and dream_state.get_display_name(id) != id:
			cards.append(dream_state.get_display_name(id))
	if statuses.is_empty() and cards.is_empty():
		return
	var row := HFlowContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("h_separation", 4)
	box.add_child(row)
	row.add_child(_needs_label("Needs", UiStyle.INK_DIM))
	for i in statuses.size():
		var status: StringName = statuses[i][0]
		if i > 0:
			row.add_child(_needs_label("+", UiStyle.INK_DIM))
		var icon := IconInfo.make_icon(status)
		if icon != null:
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
		row.add_child(_needs_label(IconInfo.status_name(status), UiStyle.INK_DIM))
	if not cards.is_empty():
		row.add_child(_needs_label((" + " if not statuses.is_empty() else "") + " + ".join(cards), UiStyle.INK_DIM))

# "Needs Wind" (NeedsRow, shared with "Dreams this run").
func _add_missing_row(box: VBoxContainer, card: UpgradeData) -> void:
	var row := NeedsRow.make(dream_state.missing_needs(card), SECONDARY_SIZE, UiStyle.INK_DIM)
	if row != null:
		row.modulate.a = 0.85
		box.add_child(row)

func _needs_label(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", SECONDARY_SIZE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
