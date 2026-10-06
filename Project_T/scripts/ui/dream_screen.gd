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
var _rerolled_in := -1  # The Dream (its drift) a reroll was used in: its last one stays shown, disabled, until it closes
var _let_go_in := -1  # Same for Let Go
var _dev_any := Button.new()  # "Dev: any card…" (dev runs of debug builds; demo_scope.md "Pick any card")
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")
var _diagram: CardDiagram = null  # The hovered placement card's map picture (dream_design.md "Placement cards show a diagram")
var _scene: CardScene = null  # The living mini-scene (pooled: one view, reused card to card)
var _held_for_diagram := false  # A long-press showed the diagram: that release doesn't take the card
var arm: ChoiceArm  # Cards ignore input for a moment as the screen appears (clicks meant for the map)
const LONG_PRESS := 0.45

func _ready() -> void:
	WorldLabel.cover_while_visible(self, &"dream_screen")  # No world tags (DPS, hover names) over a full-screen screen
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
	_reroll.pressed.connect(func() -> void:
		_rerolled_in = dream_state.current_offer_drift  # Before: the reroll shows the new offer at once
		dream_state.reroll())
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
	var peek_button := peek.make_peek_button()
	UiStyle.quiet(peek_button)  # A utility (button rule), as on every choice screen
	box.add_child(peek_button)
	arm = ChoiceArm.attach(self, _cards)

	visible = false
	dream_state.offer_ready.connect(_show_offer)
	dream_state.offer_closed.connect(_on_closed)
	dream_state.mystery_revealed.connect(_on_mystery_revealed)

func _show_offer(cards: Array[UpgradeData], drift_number: int) -> void:
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	_title.text = "A Dream, after drift %d" % drift_number
	if dream_state.has_rule(&"lucid_dreaming"):  # Take 2 of 4
		_title.text += " · take %d" % dream_state.picks_left if dream_state.picks_left > 1 else " · take 1 more"
	_skip.text = "Let it pass, +%d Dew" % dream_state.skip_dew if dream_state.skip_dew > 0 else "Let it pass"  # Light pass wording
	_skip.visible = dream_state.can_skip()  # Restless Dreams
	_dev_any.visible = DreamState.dev_tools_on() and not CaptureDirector.capturing()  # Never in marketing captures
	# A run-long supply: "1 left this run"; the last one used leaves the button disabled for the rest of that Dream
	_reroll.text = dream_state.reroll_label()
	_reroll.tooltip_text = dream_state.reroll_tip()
	_reroll.disabled = dream_state.rerolls_left <= 0
	_reroll.visible = dream_state.rerolls_left > 0 or _rerolled_in == drift_number
	var show_let_go: bool = dream_state.banishes_left > 0 or _let_go_in == drift_number
	var gap := float(_cards.get_theme_constant("separation"))
	var room := get_viewport_rect().size.x - 2.0 * SIDE_MARGIN - gap * (cards.size() - 1)
	_card_width = minf(CARD_SIZE.x, floorf(room / maxf(cards.size(), 1.0)))
	for child in _cards.get_children():
		_cards.remove_child(child)  # Right away: a reroll rebuilds the row in the same frame
		child.queue_free()
	for card in cards:
		var column := VBoxContainer.new()
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
			column.add_child(let_go)
		_cards.add_child(column)
	visible = true
	_picking = false
	arm.arm()  # Every new set of cards, rerolls too: a second click can't take a card it never saw
	_flip_in(_cards.get_children(), cards)  # One by one, each with its rarity flare

func _make_card(card: UpgradeData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(_card_width, CARD_SIZE.y)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		if _held_for_diagram:
			_held_for_diagram = false  # The long-press was to look, not to take
			return
		_pick(card, button.get_parent() as Control))  # The flight first, then it's taken
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
	if card.tip != "":  # The card's detail on hover (Sunlit Rest: which rank, who gets it)
		button.tooltip_text = IconInfo.format(card.tip)
	ChoiceCard.solid(button)  # Hides the HUD behind it (user screenshot); a Starlit back thins it again below
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
	gem.custom_minimum_size = Vector2(28, 28)  # Room for the 16 px glyph inside the gem
	gem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var glyph := UiStyle.dream_glyph(card)  # The card's glyph inside its rarity gem (UI Asset)
	gem.draw.connect(func() -> void: UiStyle.draw_gem(gem, gem.size / 2.0, 13.0, card.rarity, glyph))
	gem_row.add_child(gem)
	gem_row.add_child(rarity)
	if dream_state.is_defining(card) if dream_state.has_method("is_defining") else card.tags.has("defining"):  # Build-defining (tag or Legendary; dream_design.md de439ea8): a small mark, no numbers
		var corner := Control.new()
		corner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gem_row.add_child(corner)
		var arch := IconInfo.icon(&"defining")  # UI Asset's stone arch with a gold keystone (74a8baeb), at ×2
		var build: Control
		if arch != null:
			var icon := TextureRect.new()
			icon.texture = arch
			icon.custom_minimum_size = Vector2(32, 32)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			build = icon
		else:  # The word until the glyph is in the icon sheet
			var word := Label.new()
			word.text = "Build"
			UiStyle.caps(word, 13, UiStyle.GOLD)
			build = word
		build.name = "BuildMark"
		build.tooltip_text = "Build around it: changes what you plant next."
		build.mouse_filter = Control.MOUSE_FILTER_PASS  # Its own tip; a click still takes the card
		build.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		gem_row.add_child(build)
	box.add_child(gem_row)
	var name_label := Label.new()
	name_label.text = card.display_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.title(name_label, UiStyle.CARD_NAME_SIZE)
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
	_add_linked_line(box, card.description, UiStyle.INK, 16)
	# No impact or count preview on the card (user, screens_ui.md "Dream" ecbea61a: "don't want to be too direct in how
	# much the damage boost is… also how many it affects"): the pick shows it instead (the flight, the Wardens' pulse).
	if card.cost_description != "":
		_add_linked_line(box, card.cost_description, BITTERSWEET_COLOR, 15)
	if card.grows_text != "":  # Seed cards: the bigger effect once its Wardens are yours
		_add_linked_line(box, "Grows with %s: %s" % [_grows_with_names(card), card.grows_text], SEED_COLOR, 14)
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
	# No "Needs …" line (dream_design.md 2026-10-01, user: "can remove the Needs Water"): the card text names what it
	# uses; Dreams this run dims a card that isn't active yet and says why on hover (DreamState.not_active_reason).
	for label in secondary:
		label.modulate.a = 0.85  # Muted
	for label in [rarity, name_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL  # The row gives every card the tallest's height
	_fit_card(button, box, secondary)
	return button

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
	UiStyle.caps(line, 16, UiStyle.GOLD)
	row.add_child(line)
	box.add_child(row)
	_add_line(box, DreamState.OPENS_CLEARING_TEXT, UiStyle.INK, 14)
	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(divider)

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
	var tween := reveal.create_tween()
	tween.tween_interval(REVEAL_TIME)
	tween.tween_property(reveal, "modulate:a", 0.0, 0.4)
	tween.tween_callback(reveal.queue_free)

# --- The pick's feel (screens_ui.md "Dream", ecbea61a: "more impactful") ---------------------------------------
# The cards turn in one by one with a flare in their rarity colour; the picked card lifts and flies into the Dreams
# row with a warm swell while the others fade; then it's taken (CardBloom pulses what it touches). Reduced motion:
# fades only. Flare, lift ring and spark trail are UI Asset's art (DreamFx). Real time: the rest is paused.
signal card_flipped(card: UpgradeData)  # Each card as it turns in (Sound: a flip by rarity, d4aab969)
const FLIP_TIME := 0.22
const FLIP_STAGGER := 0.12
const FLY_TIME := 0.5
var _picking := false

func _flip_in(columns: Array, cards: Array) -> void:
	var still := bool(Fx.setting("reduced_motion", false))
	await get_tree().process_frame  # Laid out: the turn pivots on each card's centre
	for i in columns.size():
		if not is_instance_valid(columns[i]):
			continue  # A reroll rebuilt the row meanwhile
		var column := columns[i] as Control
		var card: UpgradeData = cards[i] if i < cards.size() else null
		column.pivot_offset = column.size / 2.0
		var tween := column.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if still:
			column.modulate.a = 0.0
			tween.tween_interval(i * FLIP_STAGGER * 0.5)
			if card != null:
				tween.tween_callback(card_flipped.emit.bind(card))
			tween.tween_property(column, "modulate:a", 1.0, 0.2)
			continue
		column.scale = Vector2(0.0, 1.0)
		tween.tween_interval(i * FLIP_STAGGER)
		if card != null:
			tween.tween_callback(card_flipped.emit.bind(card))
		tween.tween_property(column, "scale", Vector2.ONE, FLIP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if card != null:  # The flare as it lands: UI Asset's rarity 9-slice (DreamFx), around the card itself
			var box := _card_box(column)
			tween.tween_callback(func() -> void: DreamFx.flare(box, card))

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
	if _picking:
		return
	if column == null or not is_instance_valid(column) or not is_inside_tree():
		dream_state.choose(card)
		return
	_picking = true
	hide_diagram()
	var still := bool(Fx.setting("reduced_motion", false))
	for other in _cards.get_children():
		if other != column:
			other.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(other, "modulate:a", 0.0, 0.2)
	var tween := column.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
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
	# If another Dream is queued, offer_ready follows right away and shows (and pauses) again.
	visible = false
	game_speed.set_paused(_was_paused)

static func _roman(n: int) -> String:
	var numerals := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	return numerals[n - 1] if n <= numerals.size() else str(n)

# "Dewcatcher, Wellspring", or "the Rootling line" when a Seed names a whole line.
# "the Acorn line": a Seed card always names the family, never a Warden you may not have.
func _grows_with_names(card: UpgradeData) -> String:
	var id := card.grows_with[0] if not card.grows_with.is_empty() else ""
	return "the %s line" % dream_state.family_name_for(id)
