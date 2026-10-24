extends Control

# Full-screen Dream offer: pick 1 of 3 cards, or let it pass for a little Dew. Pauses the game
# while open (restoring the previous pause state after). Built in code.

const CARD_SIZE := Vector2(250, 220)
const CARD_PADDING := 24.0  # The box's top + bottom offsets inside a card
const SECONDARY_SIZE := 12  # Entwined / Deepened / "Needs Dewdrop" lines
const SECONDARY_MIN_SIZE := 10
const SCREEN_MARGIN := 240.0  # Title, buttons and gaps around the cards
const PC_BUTTON_W := 220.0  # Reroll, Let it pass and Peek share this width (PC)
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
var _rerolled_in := -1  # The Dream (its drift) a reroll was used in: its last one stays shown, disabled, until it closes
var _let_go_in := -1  # Same for Let Go
var _dev_any := Button.new()  # "Dev: any card…" (dev runs of debug builds; demo_scope.md "Pick any card")
# Card details (owner 2026-10-21: "is hovering over the card the most intuitive? Should there be a button instead?"): the
# small print (card.tip, a Calling's DETAILS) unfolds inside every card at once, so the cards compare side by side. PC:
# the Details toggle or Shift, remembered in settings (card_details). Phones: the looked card shows its own. No card tip
# on hover any more; an underlined word still shows its meaning, above the card (meta tips_beside "above").
const DETAILS_SETTING := "card_details"
var _details := Button.new()
var _details_on := bool(HeartwoodMemory.get_settings().get(DETAILS_SETTING, false))
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")
var _diagram: CardDiagram = null  # The hovered placement card's map picture (dream_design.md "Placement cards show a diagram")
var _scene: CardScene = null  # The living mini-scene (pooled: one view, reused card to card)
var _held_for_diagram := false  # A long-press showed the diagram: that release doesn't take the card
# Phones (Mobile UI, platforms.md "tap a card once to preview, tap again to choose"; user 2026-10-07): the first tap
# on a card looks (diagram, the others dimmed, "Tap again to take" under it), the second takes it. PC: one click.
var _looked: Button = null
var arm: ChoiceArm  # Cards ignore input for a moment as the screen appears (clicks meant for the map)
const LONG_PRESS := 0.45
# Phone layout (UiStyle.is_phone(); mobile_ui_proto Dream.dc.html): header row (title + subtitle left, Peek right), the
# cards across the width, a bottom row of Let it pass · hint · Take. The tap looks (lifts it, dims the rest); the Take
# button (or a second tap) takes it. Tablets keep the centred layout and the "Tap again to take" line. PC: untouched.
const PHONE_MARGIN := 44.0  # Left and right of the header, cards and bottom row (the HUD layer already fits the safe area)
const PHONE_GAP := 12.0  # Between the cards
const PHONE_LIFT := 1.04  # The looked card's scale (from its foot: it rises)
const PHONE_DIM_ALPHA := 0.45  # The cards not looked at (the looked one keeps full alpha and its rarity thread; no blur)
const PHONE_CHOICE_SIZE := Vector2(188, 56)  # Take and Let it pass: both real choices, the same size
const LINK_TAP_MS := 350  # A card tap this soon after an underlined word's tap was for the word, not the card
const PhoneChoice := preload("res://scripts/ui/phone_choice.gd")  # The shared phone choice helpers (threads, widths, Peek)
var _phone := false
var _subtitle: Label = null  # "after drift 10, take one" (PC too since UI council round 3)
var _phone_hint: Label = null  # Phones: "Tap a card to look at it" / "Take it, or tap another"
var _take: Button = null  # Phones: "Take <card>"
var _phone_bottom: HBoxContainer = null  # Phones: the bottom row (Peek, Let it pass … · hint · Take)
var _phone_left: HBoxContainer = null
var _phone_right: HBoxContainer = null
var _looked_card: UpgradeData = null
var _link_tap_ms := -100000
const CardReach := preload("res://scripts/ui/card_reach_overlay.gd")  # (distance words, owner 2026-10-19)
var _reach: Node2D = null  # The hovered / held card's distance outline on the map; freed when the offer closes

func _ready() -> void:
	WorldLabel.cover_while_visible(self, &"dream_screen")  # No world tags (DPS, hover names) over a full-screen screen
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_phone = UiStyle.is_phone()
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.pressed.connect(dream_state.skip)
	_reroll.focus_mode = Control.FOCUS_NONE
	_reroll.pressed.connect(func() -> void:
		_rerolled_in = dream_state.current_offer_drift  # Before: the reroll shows the new offer at once
		dream_state.reroll())
	if TouchBuild.mobile_controls():  # Phones: 48 px tap targets (platforms.md; mobile only)
		_skip.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
		_reroll.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	_dev_any.text = "Dev: any card…"
	_dev_any.focus_mode = Control.FOCUS_NONE
	_dev_any.pressed.connect(func() -> void: DevCardPicker.open(self, dream_state, dream_state.choose_any))
	if _phone:
		_build_phone_layout(dim)
	else:
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(center)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 18)
		center.add_child(box)
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.title(_title, UiStyle.CHOICE_TITLE_SIZE)
		var heading := VBoxContainer.new()  # "A Dream" and, close under it, "after drift 5, take one" in small caps
		heading.add_theme_constant_override("separation", 2)
		heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(heading)
		heading.add_child(_title)
		_subtitle = Label.new()
		_subtitle.name = "Subtitle"
		_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.caps(_subtitle, 15, UiStyle.INK_DIM)
		heading.add_child(_subtitle)
		_cards.add_theme_constant_override("separation", 16)
		_cards.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(_cards)
		var skip_row := HBoxContainer.new()
		skip_row.alignment = BoxContainer.ALIGNMENT_CENTER
		skip_row.add_theme_constant_override("separation", 16)
		_details.text = "Details" + UiStyle.key_suffix("Shift")
		_details.name = "DetailsToggle"
		_details.toggle_mode = true
		_details.focus_mode = Control.FOCUS_NONE
		_details.tooltip_text = "Show every card's small print, side by side"
		_details.button_pressed = _details_on
		_details.toggled.connect(_set_details)
		skip_row.add_child(_details)
		skip_row.add_child(_reroll)
		skip_row.add_child(_skip)
		skip_row.add_child(_dev_any)
		box.add_child(skip_row)
		peek = ChoicePeek.new(self, [dim, center], "Back to the Dream")
		var peek_button := peek.make_peek_button()
		UiStyle.quiet(peek_button)  # A utility (button rule), as on every choice screen
		box.add_child(peek_button)
		# The stacked buttons share one size, edges lined up (UI council round 4: Let it pass and Peek differed)
		for button: Control in [_reroll, _skip, peek_button]:
			button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, PC_BUTTON_W), UiStyle.HUD_BUTTON_H)
		peek_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		# Glossary (the Codex over the screen) and Your Dreams ("Dreams this run" above it), as on phones (user
		# 2026-10-22: "should have a way to check Dreams and Codex while picking Dreams"); the choice waits underneath.
		var extras := HBoxContainer.new()
		extras.name = "Extras"
		extras.alignment = BoxContainer.ALIGNMENT_CENTER
		extras.add_theme_constant_override("separation", 12)
		extras.mouse_filter = Control.MOUSE_FILTER_IGNORE
		PhoneChoice.add_extras(self, extras)
		box.add_child(extras)
	arm = ChoiceArm.attach(self, _cards)

	visible = false
	dream_state.offer_ready.connect(_show_offer)
	dream_state.offer_closed.connect(_on_closed)
	dream_state.mystery_revealed.connect(_on_mystery_revealed)

# Phones only: header row, the cards across the width (scrolling if a card runs tall), the bottom thumb row.
func _build_phone_layout(dim: Control) -> void:
	var margin := MarginContainer.new()
	margin.name = "PhoneLayout"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(PHONE_MARGIN))
	margin.add_theme_constant_override("margin_right", int(PHONE_MARGIN))
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	# Header: "A Dream" + the small caps subtitle on the left, Peek at the map on the right
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	UiStyle.title(_title, 28)
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_title)
	_subtitle = Label.new()
	_subtitle.name = "Subtitle"
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Wraps rather than push Glossary / Your Dreams off
	UiStyle.caps(_subtitle, 15, UiStyle.INK_DIM)
	header.add_child(_subtitle)
	PhoneChoice.add_extras(self, header)  # Glossary and Your Dreams, top right (user 2026-10-18)
	# The cards: three (or more) equal columns filling the width and the height between header and bottom row
	var scroll := ScrollContainer.new()
	scroll.name = "CardScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(scroll)
	_cards.add_theme_constant_override("separation", int(PHONE_GAP))
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Content height (the tallest's), centred in the space
	var pad := MarginContainer.new()  # Room above the cards for the looked one's lift (the scroll clips)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_child(_cards)
	scroll.add_child(pad)
	# Bottom: Peek and Let it pass (left thumb) · the hint · Take (right thumb); reroll and dev beside Let it pass
	var bottom := HBoxContainer.new()
	bottom.name = "BottomRow"
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_theme_constant_override("separation", 12)
	root.add_child(bottom)
	_phone_bottom = bottom
	_phone_left = HBoxContainer.new()
	_phone_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone_left.add_theme_constant_override("separation", 12)
	bottom.add_child(_phone_left)
	peek = ChoicePeek.new(self, [dim, margin], "Back to the Dream")
	var peek_button := peek.make_peek_button()
	PhoneChoice.peek_style(peek_button)  # A small framed secondary button, bottom left (user 2026-10-18)
	_phone_left.add_child(peek_button)
	_phone_left.add_child(_skip)
	_phone_left.add_child(_reroll)
	_phone_left.add_child(_dev_any)
	_dev_any.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	_phone_hint = Label.new()
	_phone_hint.name = "PhoneHint"
	_phone_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phone_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_phone_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_phone_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_phone_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_phone_hint.custom_minimum_size.x = 120
	_phone_hint.theme_type_variation = &"WhisperLabel"  # The whisper's dark shadow (FOG), no panel
	UiStyle.whisper(_phone_hint, 17)  # The italic voice
	bottom.add_child(_phone_hint)
	_take = Button.new()
	_take.name = "TakeButton"
	_take.focus_mode = Control.FOCUS_NONE
	UiStyle.primary(_take)
	# Take and Let it pass are both real choices: the same size, Take primary, Let it pass the normal framed button
	for choice: Button in [_take, _skip]:
		choice.custom_minimum_size = PHONE_CHOICE_SIZE
		choice.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		choice.clip_text = true  # A long card name trims instead of widening one button past the other
		choice.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_take.pressed.connect(_take_looked)
	_phone_right = HBoxContainer.new()
	_phone_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone_right.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_child(_phone_right)
	_phone_right.add_child(_take)
	_update_phone_bar()

# Phones: the bottom row follows the looked card ("Take Lantern Glow", dim until a card is looked at).
func _update_phone_bar() -> void:
	if _take == null:
		return
	var can_take := _looked != null and is_instance_valid(_looked) and _looked_card != null
	_take.disabled = not can_take
	PhoneChoice.disabled_look(_take)
	_take.modulate.a = 1.0 if can_take else 0.45  # multiplier: the secondary frame at 45% until there's something to take
	_take.text = "Take %s" % _looked_card.display_name if can_take else "Take"
	_phone_hint.text = "Take it, or tap another" if can_take else "Tap a card to look at it"
	# Let it pass and Take the same width: the wider one's text (UI review: "Take Call of the Wild")
	PhoneChoice.match_widths([_take, _skip] if _skip.visible else [_take])
	PhoneChoice.balance(_phone_left, _phone_right, _phone_bottom)  # The hint stays centred between the two sides

func _take_looked() -> void:
	if _looked == null or not is_instance_valid(_looked) or _looked_card == null:
		return
	_pick(_looked_card, _looked.get_parent() as Control)

# Phones: an underlined word's tap shows its tip; the same tap reaching the card underneath must not look at / take it.
func _on_link_tapped(_meta: Variant) -> void:
	_link_tap_ms = Time.get_ticks_msec()

func _link_just_tapped() -> bool:
	return TouchBuild.mobile_controls() and Time.get_ticks_msec() - _link_tap_ms < LINK_TAP_MS

func _show_offer(cards: Array[UpgradeData], drift_number: int) -> void:
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	# "A Dream" with "after drift 10, take one" beside it, in small caps: PC too (UI council round 3: Pixelify's 5 read as
	# S in "A Dream, after drift 5"; the number is in Vollkorn SC now).
	_title.text = "A Dream"
	var take := "take one"
	if dream_state.has_rule(&"lucid_dreaming"):  # Take 2 of 4
		take = "take %d" % dream_state.picks_left if dream_state.picks_left > 1 else "take 1 more"
	_subtitle.text = ("after drift %d, %s" % [drift_number, take]).to_lower()  # Small caps (UiStyle.caps); no " · "
	_skip.text = "Let it pass, %s" % UiStyle.dew_amount(dream_state.skip_dew, true) if dream_state.skip_dew > 0 else "Let it pass"  # Light pass wording
	_skip.visible = dream_state.can_skip()  # Restless Dreams (and never on a Calling pick: can_skip)
	var growing: bool = dream_state.is_calling_offer()  # Calling evolutions (Roguelite Code 2026-10-16): no reroll or let-go
	if growing:
		_title.text = "Your Calling grows"
		if _phone:
			_subtitle.text = dream_state.calling_path_text().to_lower() if not dream_state.calling_path.is_empty() else "choose its style"
		else:
			_subtitle.text = "after drift %d" % drift_number
	_dev_any.visible = DreamState.dev_tools_on() and not CaptureDirector.capturing()  # Never in marketing captures
	# A run-long supply: "1 left this run"; the last one used leaves the button disabled for the rest of that Dream
	_reroll.text = dream_state.reroll_label()
	_reroll.tooltip_text = dream_state.reroll_tip()
	_reroll.disabled = dream_state.rerolls_left <= 0
	_reroll.visible = (dream_state.rerolls_left > 0 or _rerolled_in == drift_number) and not growing
	var show_let_go: bool = (dream_state.banishes_left > 0 or _let_go_in == drift_number) and not growing
	var gap := float(_cards.get_theme_constant("separation"))
	var room := get_viewport_rect().size.x - 2.0 * SIDE_MARGIN - gap * (cards.size() - 1)
	_card_width = minf(CARD_SIZE.x, floorf(room / maxf(cards.size(), 1.0)))
	if _phone:  # Equal columns across the width between the side margins (a little spare for a scroll bar)
		room = PhoneChoice.room_width(self) - 2.0 * PHONE_MARGIN - PHONE_GAP * (cards.size() - 1) - 16.0
		_card_width = floorf(room / maxf(cards.size(), 1.0))
	for child in _cards.get_children():
		_cards.remove_child(child)  # Right away: a reroll rebuilds the row in the same frame
		child.queue_free()
	for card in cards:
		var column := VBoxContainer.new()
		if _phone:
			column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(_make_card(card))
		if show_let_go:  # Let Go (Memory Grove)
			var let_go := Button.new()
			let_go.text = dream_state.banish_label()
			let_go.tooltip_text = dream_state.banish_tip()
			let_go.disabled = dream_state.banishes_left <= 0
			let_go.focus_mode = Control.FOCUS_NONE
			let_go.pressed.connect(func() -> void:
				_let_go_in = dream_state.current_offer_drift
				dream_state.banish(card))
			if _phone:
				let_go.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
			column.add_child(let_go)
		if TouchBuild.mobile_controls() and not _phone:  # Tablets; phones have the Take button and the bottom hint
			var hint := Label.new()
			hint.name = "TapHint"
			hint.text = " "  # Holds its line from the start, so the row never shifts
			hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UiStyle.plain(hint, 15, UiStyle.GOLD)
			column.add_child(hint)
		_cards.add_child(column)
	_show_reach(null)  # New cards (a reroll too): no outline until one is hovered (distance words, owner 2026-10-19)
	visible = true
	_picking = false
	_looked = null
	_looked_card = null
	_update_phone_bar()
	arm.arm(_reveal_time(cards))  # Every new set of cards, rerolls too, until the last has turned in
	_flip_in(_cards.get_children(), cards)  # One by one, each with its rarity flare

func _make_card(card: UpgradeData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(_card_width, PhoneChoice.CARD_MIN_H if _phone else CARD_SIZE.y)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		if _held_for_diagram:
			_held_for_diagram = false  # The long-press was to look, not to take
			return
		if _link_just_tapped():
			return  # Touch: the tap was on an underlined word (its tip shows), not on the card
		if TouchBuild.mobile_controls() and _looked != button:
			_look_at(card, button)  # Phones: the first tap looks
			return
		_pick(card, button.get_parent() as Control))  # The flight first, then it's taken
	button.mouse_entered.connect(_show_reach.bind(card))  # Its distance outline on the map: hover, or (touch) the hold
	button.button_down.connect(_show_reach.bind(card))  # (distance words, owner 2026-10-19)
	if CardDiagram.has_diagram(card):
		button.mouse_entered.connect(show_diagram.bind(card, button))
		button.mouse_exited.connect(_on_card_exit.bind(button))
		button.button_down.connect(func() -> void:  # Touch: a long-press shows it
			await UiTime.timer(self, LONG_PRESS).timeout
			if is_instance_valid(button) and button.button_pressed:
				_held_for_diagram = true
				show_diagram(card, button))
		button.button_up.connect(func() -> void:
			if not _held_for_diagram:
				return
			hide_diagram())
	# Moonlit Thread card (ui_style.md): solid fog, the top thread in the rarity colour (Entwined: the
	# vine green; Woven: glowing). A Calling evolution is not a Dream (owner 2026-10-22: "make the evolution path cards
	# different than the dream cards"): its family's colour everywhere the rarity colour would be, the Calling's leaf mark
	# for the gem, the path's steps, a wash of its colour in the glass and corner brackets (ChoiceCard.family_marks).
	var evolution := card.tags.has("calling_evolution")
	var accent: Color = _calling_colour() if evolution else (ENTWINED_COLOR if card.entwined else UpgradeData.rarity_color(card.rarity))
	UiStyle.card_button(button, accent, is_legendary(card))
	var label_colour: Color = accent if evolution else UpgradeData.rarity_color(card.rarity)  # Header, kind line, chips
	button.set_meta(&"tips_beside", &"above")  # A word's meaning opens above the card, never over its neighbours
	ChoiceCard.solid(button)  # Hides the HUD behind it (user screenshot); a Starlit back thins it again below
	if card.woven:
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			(button.get_theme_stylebox(state) as MoonStyleBox).underline = true  # A glowing line along the foot too
	if MetaRun.starlit_backs():
		_add_starlit_back(button, card)
	if _phone:  # One sprout per screen (UI review; Take's): the thread runs full width in the rarity colour, no mark
		PhoneChoice.card_thread(button, accent)
	if evolution:
		ChoiceCard.family_marks(button, accent)  # Under the text: added before the box (shared with the family pick)

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
	if evolution:  # The Calling's name ("Puddles"); its step is named beside the path's beads below
		rarity.text = dream_state.calling_title()
	var stack_count := dream_state.card_stacks(card.id)
	if card.max_stacks == 0 and stack_count > 0:
		rarity.text += (" " if _phone else " · ") + _roman(stack_count + 1)  # Phones: no " · " (UI review)
	UiStyle.caps(rarity, 16, label_colour)
	rarity.text = rarity.text.to_upper().left(1) + rarity.text.substr(1)  # Small caps with a capital
	# Wraps instead of widening the card (owner screenshot 2026-10-14: a long header pushed the body text past the edge)
	rarity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rarity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var gem_row := HBoxContainer.new()
	gem_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gem_row.add_theme_constant_override("separation", 8)
	var gem := Control.new()
	gem.custom_minimum_size = Vector2(28, 28)  # Room for the 16 px glyph inside the gem
	gem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var glyph := UiStyle.dream_glyph(card)  # The card's glyph inside its rarity gem (UI Asset)
	gem.draw.connect(func() -> void: UiStyle.draw_gem(gem, gem.size / 2.0, 13.0, card.rarity, glyph))
	gem_row.add_child(_calling_mark(accent) if evolution else gem)  # An evolution: its Calling's leaf mark, not a rarity gem
	gem_row.add_child(rarity)
	# No build-defining mark on the card (user 2026-10-07: "remove the build-around-it icon"); the tag stays in the data
	# for the act 2+ offer rule (dream_design.md de439ea8).
	box.add_child(gem_row)
	if evolution:
		box.add_child(_evolution_steps(accent, card))
	# "Calling: Spore Print" / "Sporeling family" on its own line under the rarity, wrapping at the card's width
	var kind: String = dream_state.card_kind_line(card) if dream_state.has_method("card_kind_line") else ""
	if kind != "":
		var kind_label := Label.new()
		kind_label.name = "KindLine"
		kind_label.text = kind
		kind_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		kind_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiStyle.caps(kind_label, _fs(15), label_colour)
		box.add_child(kind_label)
	var name_label := Label.new()
	name_label.text = card.display_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.title(name_label, _fs(UiStyle.CARD_NAME_SIZE))
	UiStyle.fit_words(name_label, _fs(UiStyle.CARD_NAME_SIZE), maxi(_fs(UiStyle.CARD_NAME_SIZE) - 8, 12))  # A long word never splits ("Undercurren / t"; UI Code 3bb3dc6b)
	box.add_child(name_label)
	if dream_state.opens_clearing(card):
		_add_opens_clearing(box)
	if card.rule_id == &"mystery_dream":  # Face-down (Strange Dreams): a big "?" under the name
		var mark := Label.new()
		mark.name = "MysteryMark"
		mark.text = "?"
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.display(mark, 40)
		mark.add_theme_color_override("font_color", UpgradeData.rarity_color(card.rarity))
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(mark)
	# The effect comes right after the name; it never shrinks.
	_add_linked_line(box, card.description, UiStyle.INK, _fs(16))
	# No impact or count preview on the card (user, screens_ui.md "Dream" ecbea61a: "don't want to be too direct in how
	# much the damage boost is… also how many it affects"): the pick shows it instead (the flight, the Wardens' pulse).
	if card.cost_description != "":
		_add_linked_line(box, card.cost_description, BITTERSWEET_COLOR, _fs(15))
	# Matchup cards: what they answer and the player's number (Roguelite Code, dream_council_review.md 24). (No Wager or
	# Price line since 2026-10-14: no card keeps a stake.)
	if dream_state != null and dream_state.has_method("answer_line"):
		var answer: String = dream_state.answer_line(card)
		if answer != "":
			_add_linked_line(box, answer, UiStyle.INK_DIM, _fs(14))
	if card.grows_text != "":  # Seed cards: the bigger effect once its Wardens are yours
		_add_linked_line(box, "Grows with %s: %s" % [_grows_with_names(card), card.grows_text], SEED_COLOR, _fs(14))
	# Secondary lines below, smaller and muted; they shrink first when a card runs out of room.
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	if _phone:
		_add_keyword_chips(box)  # The underlined words as tap-sized chips at the card's foot
	var secondary: Array[Label] = []
	if card.entwined:  # The vine border says it; no "Entwined" label (user: "still don't know what Entwined is")
		if card.woven:
			secondary.append(_add_line(box, "Woven: needs three Wardens", ENTWINED_COLOR, SECONDARY_SIZE))
	elif card.is_deepened():
		secondary.append(_add_line(box, "Upgrade: replaces %s" % dream_state.get_display_name(card.deepens), DEEPENED_COLOR, SECONDARY_SIZE))
	elif card.is_bittersweet():
		secondary.append(_add_line(box, "Bittersweet: has a cost", BITTERSWEET_COLOR, SECONDARY_SIZE))
	# No "Needs …" line (dream_design.md 2026-10-01, user: "can remove the Needs Water"): the card text names what it
	# uses; Dreams this run dims a card that isn't active yet and says why on hover (DreamState.not_active_reason).
	for label in secondary:
		label.modulate.a = 0.85  # Muted
	# Keyword chips (2026-10-16; Roguelite Code b4ff3d08) at the card's foot, one line, small, outlined in the rarity
	# colour (screens_ui.md 844fa70a: the name and text read first). One tap target (48 px on phones) showing their
	# glossary lines. A Calling evolution reads its path's chips.
	var chips: Array = DreamState.KEYWORDS.chips_for_calling(StringName(card.id)) if card.tags.has("calling_evolution") \
		else DreamState.KEYWORDS.chips_for_card(card)
	if card.tip != "":  # The small print (Sunlit Rest: which rank, who gets it), folded until Details (or a phone's look)
		var details := _add_linked_line(box, card.tip, UiStyle.INK_DIM, _fs(14))
		details.name = "CardDetails"
		details.visible = _details_on and not _phone
	var keyword_row := KeywordRow.make(chips, UiStyle.CHIP_ICON, label_colour, CARD_CHIP_TEXT)
	if keyword_row != null:
		box.add_child(keyword_row)
		_keep_card_hover(button, keyword_row, card)
	for label in [rarity, name_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL  # The row gives every card the tallest's height
	_fit_card(button, box, secondary)
	return button

# Details on / off: every card's small print unfolds or folds (PC), remembered for next time.
func _set_details(on: bool) -> void:
	_details_on = on
	var settings := HeartwoodMemory.get_settings()
	if bool(settings.get(DETAILS_SETTING, false)) != on:
		settings[DETAILS_SETTING] = on
		HeartwoodMemory.save_settings(settings)
	for column in _cards.get_children():
		var details := _card_box(column).find_child("CardDetails", true, false) as Control
		if details != null:
			details.visible = on and not _phone

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not visible or _phone or not key.pressed or key.echo or key.keycode != KEY_SHIFT:
		return
	_details.button_pressed = not _details.button_pressed  # Shift: the same toggle (its toggled signal does the rest)
	get_viewport().set_input_as_handled()

# --- Calling evolution cards (owner 2026-10-22: "make the evolution path cards different than the dream cards") ------
# Same moon-glass card, but nothing about it reads as a Dream: the Calling's family colour (Kinships.FAMILY_COLORS, the
# colour its vines and sparks already use) instead of a rarity, the Calling's leaf mark instead of the rarity gem, the
# header "<Calling>", the path's four steps and the step's name under it, and the family look the family pick shares
# (ChoiceCard.family_marks: a wash of the colour at the top of the glass and a bracket in each corner).
const EVOLUTION_STAGES := ["Style", "Follow-up", "Capstone", "Finale"]  # CallingPaths.DRIFTS order. Drift 75 (owner 2026-10-23): its line's Finale (tag "deepen") or a Cross over to the style's other follow-up (tag "cross_over")

func _calling_colour() -> Color:
	var line: String = String(DreamState.CALLINGS.LINES.get(dream_state.calling, ""))
	return Kinships.FAMILY_COLORS.get(line, UiStyle.GOLD)

func _evolution_step() -> int:
	return clampi(dream_state.calling_path.size(), 0, EVOLUTION_STAGES.size() - 1)

func _evolution_stage_name(card: UpgradeData = null) -> String:
	if card != null and card.tags.has("cross_over"):
		return "Cross over"
	return EVOLUTION_STAGES[_evolution_step()]

# The Calling's mark (owner 2026-10-22: "remove the Warden portrait, it should be something else"; chose the Calling
# glyph): the glyph its family's Dream cards use (UiStyle.dream_glyph on its line's tag: water, spore, light, song…), 2x,
# in a leaf, a shape no rarity gem has (circle, diamond, hexagon, star), with a short stalk at its lower tip.
const MARK_SIZE := 32.0  # The leaf's box in the header
const LEAF_HALF := Vector2(15.0, 10.0)  # Half its length (tip to tip, along the diagonal) and half its width

func _calling_mark(colour: Color) -> Control:
	var probe := UpgradeData.new()
	probe.tags = [String(DreamState.CALLINGS.LINES.get(dream_state.calling, ""))]
	var glyph := UiStyle.dream_glyph_texture(UiStyle.dream_glyph(probe))  # Held by the draw binding: never freed early
	var mark := Control.new()
	mark.name = "CallingMark"
	mark.custom_minimum_size = Vector2.ONE * MARK_SIZE
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.draw.connect(_draw_calling_mark.bind(mark, glyph, colour))
	return mark

func _draw_calling_mark(mark: Control, glyph: Texture2D, colour: Color) -> void:
	var centre := (mark.size / 2.0).round()
	# A leaf: two circle arcs meeting at pointed tips, its long axis on the diagonal (lower left to upper right)
	var l := LEAF_HALF.x
	var w := LEAF_HALF.y
	var c := (l * l - w * w) / (2.0 * w)
	var r := c + w
	var axis := Vector2(1, -1).normalized()
	var normal := Vector2(axis.y * -1.0, axis.x)
	var points := PackedVector2Array()
	for i in 17:
		var x := lerpf(-l, l, i / 16.0)
		points.append(centre + axis * x + normal * (sqrt(maxf(r * r - x * x, 0.0)) - c))
	for i in 17:
		var x := lerpf(l, -l, i / 16.0)
		points.append(centre + axis * x - normal * (sqrt(maxf(r * r - x * x, 0.0)) - c))
	var tip := centre - axis * l
	mark.draw_line(tip, tip - axis * 4.0 + Vector2(-1, 0), colour, 2.0)  # The stalk
	mark.draw_colored_polygon(points, UiStyle.CARD_BG)
	points.append(points[0])
	mark.draw_polyline(points, colour, 2.0, true)
	mark.draw_line(centre - axis * (l - 3.0), centre + axis * (l - 3.0), Color(colour, 0.3), 1.0)  # The midrib, faint
	if glyph != null:
		var side := glyph.get_size() * 2.0
		mark.draw_texture_rect(glyph, Rect2((centre - side / 2.0).round(), side), false)

# The path's four steps as beads on a line: taken ones filled, this one a bright ring, later ones hollow and dim; then
# this step's name ("Style", "Follow-up", "Capstone") beside them, so the header keeps to the Calling's name.
const STEPS_WIDTH := 80.0  # The beads' room: MARK_SIZE / 2 + 3 gaps of 18 + the last bead's ring

func _evolution_steps(colour: Color, card: UpgradeData = null) -> Control:
	var row := HBoxContainer.new()
	row.name = "EvolutionSteps"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	var steps := Control.new()
	steps.custom_minimum_size = Vector2(STEPS_WIDTH, 14)
	steps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	steps.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	steps.draw.connect(_draw_evolution_steps.bind(steps, colour))
	row.add_child(steps)
	var stage := Label.new()
	stage.text = _evolution_stage_name(card)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.caps(stage, _fs(14), UiStyle.INK_DIM)
	row.add_child(stage)
	return row

func _draw_evolution_steps(steps: Control, colour: Color) -> void:
	var count := EVOLUTION_STAGES.size()
	var gap := 18.0
	var y := floorf(steps.size.y / 2.0)
	var x0 := MARK_SIZE / 2.0
	var now := _evolution_step()
	steps.draw_line(Vector2(x0, y), Vector2(x0 + gap * (count - 1), y), Color(colour, 0.35), 2.0)
	for i in count:
		var at := Vector2(x0 + gap * i, y)
		if i < now:
			steps.draw_circle(at, 3.5, colour)
		elif i == now:
			steps.draw_circle(at, 5.0, UiStyle.CARD_BG)
			steps.draw_arc(at, 5.0, 0.0, TAU, 16, colour, 2.0, true)
			steps.draw_circle(at, 2.0, UiStyle.INK)
		else:
			steps.draw_circle(at, 3.5, UiStyle.CARD_BG)
			steps.draw_arc(at, 3.5, 0.0, TAU, 12, Color(colour, 0.45), 1.5, true)

# While clearing is locked, a clearing card leads with what it unlocks (dream_design.md "Clearing
# cards" / "Make the unlock obvious"): the Clear tool icon + "Unlocks clearing", what clearing is, a
# thin divider, then the card's own effect (one label: no corner tag, text_style.md 2026-10-01).
func _add_opens_clearing(box: VBoxContainer) -> void:
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
	UiStyle.plain(line, 16, UiStyle.GOLD)
	row.add_child(line)
	box.add_child(row)
	# (No OPENS_CLEARING_TEXT line: the card's own text says it; UI council 2026-10-22 saw the rule twice.)
	if _phone:  # Nested in a card: a plain fading Gold line, no sprout (UI Asset 2026-10-17)
		var fade := Control.new()
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade.custom_minimum_size.y = 6.0
		fade.draw.connect(_draw_fading_line.bind(fade))
		box.add_child(fade)
		return
	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(divider)

func _draw_fading_line(line: Control) -> void:
	var y := floorf(line.size.y / 2.0)
	line.draw_polyline_colors(PackedVector2Array([Vector2(0, y), Vector2(line.size.x / 2.0, y), Vector2(line.size.x, y)]),
		PackedColorArray([Color(UiStyle.GOLD, 0.0), Color(UiStyle.GOLD, 0.5), Color(UiStyle.GOLD, 0.0)]), 1.0)

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
	twinkle.ignore_time_scale = true  # Real time at any game speed
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
		# Phones: the content's height (UI review: no empty fog under the text); the row shares the tallest's height
		button.custom_minimum_size = Vector2(_card_width, maxf(PhoneChoice.CARD_MIN_H if _phone else CARD_SIZE.y, needed))
	box.minimum_size_changed.connect(fit)
	fit.call_deferred()

# Phones: card text a size class up (user 2026-10-16: "the text is too small compared" to the full-height cards).
const PHONE_CARD_BUMP := 5
const CARD_CHIP_TEXT := 12  # The foot chips' word, under the card text (phones too: the row stays 48 px to tap)
func _fs(size: int) -> int:
	return size + PHONE_CARD_BUMP if _phone else size

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
	label.text = StatusLinks.card_bbcode(text)  # Cards: basic words plain, statuses as icon + colour (owner 2026-10-22)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	if TouchBuild.mobile_controls():  # Touch: a tap on a word shows its tip without looking at / taking the card
		label.meta_clicked.connect(_on_link_tapped)
	box.add_child(label)
	return label

# Phones (user 2026-10-17: "hard to tap key words while in dream screen on cards"): the card's underlined words again as
# a row of chips at its foot, each a real tap target; a tap opens the same tip as the word. Nothing when it has none.
const CHIP_H := 40.0
var _link_pattern := RegEx.create_from_string("\\[url=([^\\]]+)\\](.*?)\\[/url\\]")
var _tag_pattern := RegEx.create_from_string("\\[[^\\]]*\\]")

func _add_keyword_chips(box: VBoxContainer) -> void:
	var row := HFlowContainer.new()
	row.name = "KeywordChips"
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var seen := {}
	for child in box.get_children():
		var label := child as RichTextLabel
		if label == null or not label.has_meta(&"status_popup"):
			continue
		for found in _link_pattern.search_all(label.text):
			var meta := found.get_string(1)
			if seen.has(meta):
				continue
			seen[meta] = true
			var chip := Button.new()
			chip.text = _tag_pattern.sub(found.get_string(2), "", true)
			chip.focus_mode = Control.FOCUS_NONE
			chip.custom_minimum_size = Vector2(0, CHIP_H)
			chip.add_theme_font_size_override("font_size", _fs(13))
			chip.pressed.connect(_tap_keyword.bind(meta, label, chip))
			row.add_child(chip)
	if row.get_child_count() > 0:
		box.add_child(row)
	else:
		row.free()

func _tap_keyword(meta: String, label: RichTextLabel, chip: Control) -> void:
	_on_link_tapped(meta)  # The card underneath doesn't look at / take itself
	var popup := label.get_meta(&"status_popup") as StatusLinks
	if popup != null and is_instance_valid(popup):
		popup._show_for(meta, chip, true)

# The diagram panel beside `button` (right of it, or left when there's no room), kept on screen.
# Cards with a living mini-scene (CardScene.LIVE_CARDS) play it in the one pooled view; reduced motion and the
# rest keep the still diagram.
func show_diagram(card: UpgradeData, button: Control) -> void:
	hide_diagram()
	var panel: Control
	if CardScene.can_show(card):
		if _scene == null or not is_instance_valid(_scene):
			_scene = CardScene.new()
			_scene.name = "CardScene"
			_scene.z_index = 10
			add_child(_scene)
		_scene.show_card(card)
		panel = _scene
	else:
		_diagram = CardDiagram.make(card)
		if _diagram == null:
			return
		_diagram.name = "CardDiagram"
		_diagram.z_index = 10
		add_child(_diagram)
		panel = _diagram
	await get_tree().process_frame
	if not is_instance_valid(panel) or not panel.visible or not is_instance_valid(button):
		return
	var card_rect := button.get_global_rect()
	var column := button.get_parent() as Control
	if column != null and column.get_parent() == _cards:  # Its laid-out rect, not the turning one (the flip scales it)
		card_rect = Rect2(_cards.global_position + column.position, column.size)
	var view := get_viewport_rect().size
	var size := panel.get_combined_minimum_size()
	var x := card_rect.end.x + 8.0
	if x + size.x > view.x - 8.0:
		x = card_rect.position.x - size.x - 8.0
	var y := clampf(card_rect.position.y + 24.0, 8.0, view.y - size.y - 8.0)
	panel.global_position = Vector2(maxf(x, 8.0), y)

# Phones: the first tap on a card. The others dim, its diagram shows, "Tap again to take" under it.
func _look_at(card: UpgradeData, button: Button) -> void:
	_looked = button
	_looked_card = card
	for column in _cards.get_children():
		var looked := button.get_parent() == column
		var face := _card_box(column)
		if face != null:
			var dim_alpha := PHONE_DIM_ALPHA if _phone else 0.55
			face.modulate = Color(1, 1, 1, 1.0 if looked else dim_alpha)  # multiplier
			if _phone:
				_lift(face, looked)
		var hint := column.get_node_or_null("TapHint") as Label
		if hint != null:
			hint.text = "Tap again to take" if looked else " "
		var details := face.find_child("CardDetails", true, false) as Control if face != null else null
		if details != null and _phone:
			details.visible = looked  # Phones: the looked card shows its small print (no hover anywhere)
	_update_phone_bar()
	_show_reach(card)  # (distance words, owner 2026-10-19)
	if CardDiagram.has_diagram(card):
		show_diagram(card, button)
	else:
		hide_diagram()

# Phones: the looked card rises a little from its foot; the others settle back. Reduced motion: no lift (the dim says it).
func _lift(face: Control, up: bool) -> void:
	if bool(Fx.setting("reduced_motion", false)):
		face.scale = Vector2.ONE
		return
	face.pivot_offset = Vector2(face.size.x / 2.0, face.size.y)
	var target := Vector2.ONE * (PHONE_LIFT if up else 1.0)
	UiTime.tween(face).tween_property(face, "scale", target, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# The pointer left the card: the diagram goes only when it is outside the card (on its chips it is still on the card).
func _on_card_exit(button: Control) -> void:
	if not is_instance_valid(button) or not button.get_global_rect().has_point(button.get_global_mouse_position()):
		hide_diagram()

# The card keeps its hover look, map outline and diagram while the pointer is on its keyword chips (owner 2026-10-20: "card
# doesnt glow or bugs out when i hover near the chips"): the chip row stops the mouse for its glossary tip, which took
# the hover from the card button. On the row the button wears its hover box as its normal one; leaving puts it back.
func _keep_card_hover(button: Button, row: Control, card: UpgradeData) -> void:
	var normal: StyleBox = button.get_theme_stylebox("normal")
	row.mouse_entered.connect(func() -> void:
		if not is_instance_valid(button) or button.disabled:
			return
		button.add_theme_stylebox_override("normal", button.get_theme_stylebox("hover"))
		_show_reach(card)
		if CardDiagram.has_diagram(card) and (_diagram == null or not is_instance_valid(_diagram)):
			show_diagram(card, button))
	row.mouse_exited.connect(_leave_chips.bind(button, normal))

func _leave_chips(button: Button, normal: StyleBox) -> void:
	if not is_instance_valid(button):
		return
	button.add_theme_stylebox_override("normal", normal)
	_on_card_exit(button)

func hide_diagram() -> void:
	if _diagram != null and is_instance_valid(_diagram):
		_diagram.queue_free()
	_diagram = null
	if _scene != null and is_instance_valid(_scene):
		_scene.stop()  # Pooled: kept, but nothing runs or draws

# Mystery Dream (Strange Dreams): the card it became, shown at once over the map for a moment (a tap dismisses it).
const REVEAL_TIME := 2.4

func _on_mystery_revealed(_mystery: UpgradeData, card: UpgradeData) -> void:
	var reveal := Control.new()
	reveal.name = "MysteryReveal"
	reveal.set_anchors_preset(Control.PRESET_FULL_RECT)
	reveal.process_mode = Node.PROCESS_MODE_ALWAYS
	reveal.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	var caption := Label.new()
	caption.text = "Your Mystery Dream became"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(caption, 18, UiStyle.GOLD)
	column.add_child(caption)
	var face := _make_card(card)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(face)
	reveal.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed or event is InputEventScreenTouch and event.pressed:
			reveal.queue_free())
	(get_parent() if get_parent() != null else self).add_child(reveal)
	var tween := UiTime.tween(reveal, false)
	tween.tween_interval(REVEAL_TIME)
	tween.tween_property(reveal, "modulate:a", 0.0, 0.4)
	tween.tween_callback(reveal.queue_free)

# --- The pick's feel (screens_ui.md "Dream", ecbea61a: "more impactful") ---------------------------------------
# The cards turn in one by one with a flare in their rarity colour; the picked card lifts and flies into the Dreams
# row with a warm swell while the others fade; then it's taken (CardBloom pulses what it touches). Reduced motion:
# fades only. Flare, lift ring and spark trail are UI Asset's art (DreamFx). Real time: the rest is paused.
signal card_flipped(card: UpgradeData)  # Each card as it turns in (Sound: a flip by rarity, d4aab969)
# A Legendary's own moment (owner 2026-10-21, dream_council_review.md 28), for SoundHooks (gameplay never calls Sound):
# offered = as it turns in, last, after the others; taken = as the pick starts its flight.
signal legendary_offered(card: UpgradeData)
signal legendary_taken(card: UpgradeData)
const LEGENDARY_PAUSE := 0.35  # The beat after the other cards before a Legendary turns in
const LEGENDARY_FLIP := 0.4  # …and its slower turn

static func is_legendary(card: UpgradeData) -> bool:
	return card != null and card.rarity == UpgradeData.Rarity.LEGENDARY
const FLIP_TIME := 0.22
const FLIP_STAGGER := 0.12
const FLY_TIME := 0.5

# Real seconds until the last card of `cards` has turned in (_flip_in's timing), plus a beat.
static func _reveal_time(cards: Array) -> float:
	var legendary := false
	for card in cards:
		legendary = legendary or is_legendary(card)
	var time := maxf(cards.size() - 1, 0) * FLIP_STAGGER + (LEGENDARY_PAUSE + LEGENDARY_FLIP if legendary else FLIP_TIME)
	return time + 0.1
var _picking := false

func _flip_in(columns: Array, cards: Array) -> void:
	var still := bool(Fx.setting("reduced_motion", false))
	await get_tree().process_frame  # Laid out: the turn pivots on each card's centre
	# A Legendary turns in last, after the others have landed (the others keep their order; owner 2026-10-21).
	var others := 0
	for i in columns.size():
		if not is_legendary(cards[i] if i < cards.size() else null):
			others += 1
	var turn := 0  # Among the other cards
	var late := 0  # Among the Legendaries
	for i in columns.size():
		if not is_instance_valid(columns[i]):
			continue  # A reroll rebuilt the row meanwhile
		var column := columns[i] as Control
		var card: UpgradeData = cards[i] if i < cards.size() else null
		var legendary := is_legendary(card)
		var slot := others + late if legendary else turn
		if legendary:
			late += 1
		else:
			turn += 1
		column.pivot_offset = column.size / 2.0
		var tween := UiTime.tween(column)
		if still:  # Reduced motion: no reveal, the frame says it (it still comes in last, fading like the rest)
			column.modulate.a = 0.0
			tween.tween_interval(slot * FLIP_STAGGER * 0.5)
			if card != null:
				tween.tween_callback(card_flipped.emit.bind(card))
			if legendary:
				tween.tween_callback(legendary_offered.emit.bind(card))
			tween.tween_property(column, "modulate:a", 1.0, 0.2)
			continue
		column.scale = Vector2(0.0, 1.0)
		tween.tween_interval(slot * FLIP_STAGGER + (LEGENDARY_PAUSE if legendary else 0.0))
		if card != null:
			tween.tween_callback(card_flipped.emit.bind(card))
		if legendary:
			tween.tween_callback(legendary_offered.emit.bind(card))
		tween.tween_property(column, "scale", Vector2.ONE, LEGENDARY_FLIP if legendary else FLIP_TIME) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if card != null:  # The flare as it lands: UI Asset's rarity 9-slice (DreamFx), around the card itself
			var box := _card_box(column)
			tween.tween_callback(func() -> void: DreamFx.flare(box, card))
		if legendary:  # Its short glow: a warm swell and a ring in Legendary gold
			tween.tween_callback(func() -> void: DreamFx.pulse(self, _card_box(column).get_global_rect().get_center(),
				UpgradeData.rarity_color(card.rarity)))
			tween.tween_property(column, "modulate", Color(1.3, 1.22, 1.05, 1.0), 0.18)  # multiplier: the swell
			tween.tween_property(column, "modulate", Color.WHITE, 0.4)

const DreamFx := preload("res://scripts/ui/dream_fx.gd")  # UI Asset's flare / pulse ring / spark art
const SPARK_EVERY := 0.05  # Seconds between trail sparks on the flight

# The card itself in a column (the Button; the column also holds the cue under it), else the column.
func _card_box(column: Control) -> Control:
	for child in column.get_children():
		if child is Button:
			return child
	return column

# A trail spark at the flying card's centre every SPARK_EVERY of the flight (`t` 0..1), shrinking with it.
func _trail(t: float, column: Control, colour: Color, state: Array) -> void:
	if not is_instance_valid(column) or t * FLY_TIME < state[0]:
		return
	state[0] += SPARK_EVERY
	DreamFx.spark(self, column.get_global_rect().get_center(), colour, 1.0 - t)

# Where the picked card flies: the HUD's Dreams row (top left).
func _dreams_row_point() -> Vector2:
	var row := get_parent().get_node_or_null("DreamsRow") as Control if get_parent() != null else null
	if row == null:
		return Vector2(40, 40)
	var rect := row.get_global_rect()
	return rect.position + Vector2(minf(rect.size.x, 24.0), 24.0)

func _pick(card: UpgradeData, column: Control) -> void:
	if _picking or LessonCard.covering(self):  # No pick while the "A Dream" Lesson explains the screen
		return
	if is_legendary(card):
		legendary_taken.emit(card)
	if column == null or not is_instance_valid(column) or not is_inside_tree():
		dream_state.choose(card)
		return
	_picking = true
	hide_diagram()
	var still := bool(Fx.setting("reduced_motion", false))
	for other in _cards.get_children():
		if other != column:
			UiTime.tween(other).tween_property(other, "modulate:a", 0.0, 0.2)
	var tween := UiTime.tween(column)
	if still:
		tween.tween_property(column, "modulate", Color(1.25, 1.2, 1.05, 0.0), 0.3)  # multiplier: a warm fade
	else:
		var from := column.global_position
		var glow := UpgradeData.rarity_color(card.rarity)
		DreamFx.pulse(self, _card_box(column).get_global_rect().get_center(), glow)  # The lift: a ring from the card
		column.pivot_offset = column.size / 2.0
		column.top_level = true  # Out of the row's layout: it flies
		column.global_position = from
		tween.set_parallel(true)
		tween.tween_property(column, "global_position", _dreams_row_point() - column.pivot_offset, FLY_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(column, "scale", Vector2(0.12, 0.12), FLY_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(column, "modulate", Color(1.35, 1.25, 1.05, 1.0), FLY_TIME * 0.4)  # multiplier: the swell
		tween.tween_method(_trail.bind(column, glow, [0.0]), 0.0, 1.0, FLY_TIME)  # The spark trail
		tween.chain().tween_property(column, "modulate:a", 0.0, 0.1)
	tween.chain().tween_callback(func() -> void:
		_picking = false
		dream_state.choose(card))

func _on_closed() -> void:
	hide_diagram()
	if _reach != null and is_instance_valid(_reach):  # (distance words, owner 2026-10-19)
		_reach.queue_free()
	_reach = null
	# If another Dream is queued, offer_ready follows right away and shows (and pauses) again.
	visible = false
	game_speed.set_paused(_was_paused)

# The card's distance word outlined on the map around the player's Wardens of its family (null clears; it stays for the
# last card shown, so "Peek at the map" still shows it). Made on first use, in the run's world (distance words, owner
# 2026-10-19).
func _show_reach(card: UpgradeData) -> void:
	if _reach == null or not is_instance_valid(_reach):
		if card == null:
			return
		var world: Node = owner if owner != null else get_tree().current_scene
		if world == null:
			return
		_reach = CardReach.new()
		_reach.name = "CardReachOverlay"
		world.add_child(_reach)
	_reach.call(&"show_card", card, dream_state.calling)

static func _roman(n: int) -> String:
	var numerals := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	return numerals[n - 1] if n <= numerals.size() else str(n)

# "Dewcatcher, Wellspring", or "the Rootling line" when a Seed names a whole line.
# "the Acorn line": a Seed card always names the family, never a Warden you may not have.
func _grows_with_names(card: UpgradeData) -> String:
	var id := card.grows_with[0] if not card.grows_with.is_empty() else ""
	return "the %s line" % dream_state.family_name_for(id)
