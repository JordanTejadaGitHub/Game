extends Control

# Full-screen Dream offer: pick 1 of 3 cards, or let it pass for a little Dew. Pauses the game
# while open (restoring the previous pause state after). Built in code.

const CARD_SIZE := Vector2(250, 220)
const ENTWINED_COLOR := Color(0.45, 0.8, 0.4)  # Vine border
const DEEPENED_COLOR := Color(0.6, 0.85, 1.0)
const BITTERSWEET_COLOR := Color(0.72, 0.5, 0.68)  # Muted plum, for the cost line

@onready var dream_state: DreamState = %DreamState
@onready var game_speed: GameSpeed = %GameSpeed

var _was_paused := false
var _title := Label.new()
var _cards := HBoxContainer.new()
var _skip := Button.new()
var _reroll := Button.new()  # Second Thoughts (Memory Grove)
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(0.85, 0.8, 1.0))
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
	_skip.text = "Let it pass  (+%d Dew)" % dream_state.skip_dew if dream_state.skip_dew > 0 else "Let it pass"
	_skip.visible = dream_state.can_skip()  # Restless Dreams
	_reroll.text = "Dream again  (%d left)" % dream_state.rerolls_left
	_reroll.visible = dream_state.rerolls_left > 0
	for child in _cards.get_children():
		_cards.remove_child(child)  # Right away: a reroll rebuilds the row in the same frame
		child.queue_free()
	for card in cards:
		var column := VBoxContainer.new()
		column.add_child(_make_card(card))
		if dream_state.banishes_left > 0:  # Let Go (Memory Grove)
			var let_go := Button.new()
			let_go.text = "Let go  (%d left)" % dream_state.banishes_left
			let_go.tooltip_text = "This card won't come back this run; another takes its place."
			let_go.focus_mode = Control.FOCUS_NONE
			let_go.pressed.connect(dream_state.banish.bind(card))
			column.add_child(let_go)
		_cards.add_child(column)
	visible = true

func _make_card(card: UpgradeData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(dream_state.choose.bind(card))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.13, 0.2, 0.95)
	style.border_color = ENTWINED_COLOR if card.entwined else UpgradeData.rarity_color(card.rarity)
	style.set_border_width_all(5 if card.entwined else 3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.18, 0.2, 0.3, 0.98)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)

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
		rarity.text += "  ·  " + _roman(stack_count + 1)
	rarity.add_theme_color_override("font_color", UpgradeData.rarity_color(card.rarity))
	rarity.add_theme_font_size_override("font_size", 14)
	box.add_child(rarity)
	var name_label := Label.new()
	name_label.text = card.display_name
	name_label.add_theme_font_size_override("font_size", 22)
	box.add_child(name_label)
	if card.entwined:
		var names := card.requires.map(dream_state.get_display_name)
		_add_line(box, "Entwined  ·  %s" % " + ".join(names), ENTWINED_COLOR, 14)
	elif card.is_deepened():
		_add_line(box, "Deepened  ·  replaces %s" % dream_state.get_display_name(card.deepens), DEEPENED_COLOR, 14)
	elif card.is_bittersweet():
		_add_line(box, "Bittersweet", BITTERSWEET_COLOR, 14)
	var description := _add_line(box, card.description, Color(0.92, 0.92, 0.95), 16)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if card.cost_description != "":
		_add_line(box, card.cost_description, BITTERSWEET_COLOR, 15)
	for label in [rarity, name_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return button

func _add_line(box: VBoxContainer, text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return label

func _on_closed() -> void:
	# If another Dream is queued, offer_ready follows right away and shows (and pauses) again.
	visible = false
	game_speed.set_paused(_was_paused)

static func _roman(n: int) -> String:
	var numerals := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	return numerals[n - 1] if n <= numerals.size() else str(n)
