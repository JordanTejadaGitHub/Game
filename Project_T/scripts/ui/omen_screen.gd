extends Control

# The Omen screen at a rest (run_design.md "Commit blind, then the Omen is revealed"): a face-down
# "Face an Omen" card and Clear Skies (the default: nothing changes, no reward). Facing it flips to
# the drawn Omens (twist + reward) to pick one from; no going back. Esc / right-click = Clear Skies. Pauses and peeks like the Dream screen. Also shows the
# active Omen in a small tag under the toast, and toasts when one starts and when its reward is paid.
# Built in code.

const CARD_SIZE := Vector2(270, 200)
const OMEN_COLOR := UiStyle.BUTTON_GOLD  # Heartwood 32 "Gold"
const TWIST_COLOR := Color("9a84e8")  # Heartwood 32 "Wraithlight": the nightmares' side of the deal
const REWARD_COLOR := UiStyle.GOLD  # Heartwood 32 "Glow": the reward in gold (run_design.md)
const CLEAR_SKIES_COLOR := UiStyle.MOONLIGHT  # A calm moonlit card: Moonlight thread and title
const CLEAR_SKIES_GLOW := Color("3c3c5c")  # Dusk: a cooler, lighter middle than an Omen's Night

@onready var omens: OmenDirector = %OmenDirector
@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed

var _was_paused := false
var _title := Label.new()
var _cards := HBoxContainer.new()
var _active_tag := Label.new()
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.05, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.display(_title, 28)
	_title.add_theme_color_override("font_color", OMEN_COLOR)
	box.add_child(_title)
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
	peek = ChoicePeek.new(self, [dim, center], "Back to the Omens")
	box.add_child(peek.make_peek_button())
	visible = false

	# The active-Omen tag lives on the HUD, outside this (usually hidden) screen.
	_active_tag.name = "ActiveOmen"  # ComingStrip stacks under it (top centre)
	_active_tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_active_tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_active_tag.offset_top = 64
	_active_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_active_tag.add_theme_color_override("font_color", OMEN_COLOR)
	_active_tag.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14))
	_active_tag.add_theme_constant_override("outline_size", 6)
	_active_tag.visible = false
	get_parent().add_child.call_deferred(_active_tag)

	omens.offer_ready.connect(_show_offer)
	omens.offer_closed.connect(_on_closed)
	omens.omen_started.connect(_on_omen_started)
	omens.omen_rewarded.connect(_on_omen_rewarded)

# Commit blind (run_design.md "Commit blind, then the Omen is revealed"): a face-down "Face an Omen"
# card and Clear Skies. Facing it flips to the drawn Omens (2; Omen Reader 3): pick one, no going back.
# A forced Omen (Blight), or a save made after facing, shows the Omens at once.
func _show_offer(_offer: Array[OmenData], block: int) -> void:
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	_drifts = omens.get_block_range(block)
	_title.text = "The wind stirs  ·  drifts %d–%d" % [_drifts.x, _drifts.y]
	_clear_cards()
	visible = true
	if omens.forced or omens.faced:
		if omens.forced:
			_title.text = "An Omen must be faced  ·  drifts %d–%d" % [_drifts.x, _drifts.y]
		_reveal(omens.face(), null)
		return
	var back := _make_face_down_card()
	_cards.add_child(back)
	_cards.add_child(_make_clear_skies_card())

var _drifts := Vector2i.ZERO

func _clear_cards() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()

# The face-down card: a wind swirl and "An unknown twist for the next block. Survive it for a reward."
func _make_face_down_card() -> Button:
	var button := Button.new()
	button.name = "FaceAnOmen"
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	UiStyle.card_button(button, OMEN_COLOR)
	var box := _card_box(button)
	UiStyle.title(_add_line(box, "Face an Omen", UiStyle.INK, 22), UiStyle.CARD_NAME_SIZE)
	var swirl := Control.new()
	swirl.custom_minimum_size = Vector2(0, 64)
	swirl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	swirl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swirl.draw.connect(func() -> void: _draw_swirl(swirl))
	box.add_child(swirl)
	_add_line(box, "An unknown twist for the next block. Survive it for a reward.", UiStyle.INK, 15)
	button.pressed.connect(func() -> void: _reveal(omens.face(), button))
	return button

# Three nested wind arcs.
func _draw_swirl(canvas: Control) -> void:
	var centre := canvas.size / 2.0
	for i in 3:
		var r := 10.0 + i * 8.0
		canvas.draw_arc(centre, r, i * 1.2, i * 1.2 + PI * 1.4, 24, Color(OMEN_COLOR, 0.9 - i * 0.2), 3.0, true)

# Flips `from` (the face-down card; null = none) to the revealed Omens; Clear Skies goes.
func _reveal(offer: Array[OmenData], from: Button) -> void:
	if offer.is_empty():
		omens.choose(null)
		return
	var act := drift_director.get_act(_drifts.y)
	var fronts: Array[Button] = []
	for omen in offer:
		var front := _make_card(omen, act)
		front.name = "Omen_" + omen.id
		fronts.append(front)
	for child in _cards.get_children():
		if child != from:
			_cards.remove_child(child)
			child.queue_free()  # Clear Skies goes: no backing out
	if not omens.forced:
		_title.text = "Choose the Omen  ·  drifts %d–%d" % [_drifts.x, _drifts.y]
	if from != null and not HeartwoodMemory.get_settings().get("reduced_motion", false):  # The flip
		from.pivot_offset = from.size / 2.0
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(from, "scale:x", 0.0, 0.18)
		tween.tween_callback(func() -> void:
			_cards.remove_child(from)
			from.queue_free()
			for front in fronts:
				_cards.add_child(front)
				front.pivot_offset = CARD_SIZE / 2.0
				front.scale.x = 0.0
				front.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(front, "scale:x", 1.0, 0.18))
	else:
		if from != null:
			_cards.remove_child(from)
			from.queue_free()
		for front in fronts:
			_cards.add_child(front)

func _card_box(button: Button) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	return box

# A revealed Omen: the twist and its reward; a click picks it.
func _make_card(omen: OmenData, act: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(omens.choose.bind(omen))
	UiStyle.card_button(button, OMEN_COLOR)  # Moonlit Thread card (ui_style.md)
	var box := _card_box(button)
	UiStyle.title(_add_line(box, omen.display_name, UiStyle.INK, 22), UiStyle.CARD_NAME_SIZE)
	var twist := StatusLinks.make_label(omen.description, 16, TWIST_COLOR)  # Status words as links
	twist.mouse_filter = Control.MOUSE_FILTER_PASS  # A click still picks the Omen
	twist.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(twist)
	var reward := omens.describe_reward(omen, act)
	_add_line(box, "Reward: " + reward if reward != "" else "Double-edged: the twist is the reward", REWARD_COLOR, 15)
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
	_clear_cards()
	visible = false
	game_speed.set_paused(_was_paused)

func _on_omen_started(omen: OmenData, first_drift: int, last_drift: int) -> void:
	_active_tag.text = "Omen: %s (drifts %d–%d) · %s" % [omen.display_name, first_drift, last_drift,
		IconInfo.format(omen.description)]
	_active_tag.visible = true
	_toast("Omen faced: %s" % omen.display_name)

func _on_omen_rewarded(omen: OmenData, summary: String) -> void:
	_active_tag.visible = false
	_toast("%s passes: %s" % [omen.display_name, summary])

func _toast(text: String) -> void:
	var hud := get_parent()
	if hud.has_method("show_toast"):
		hud.show_toast(text)


# Esc / right-click = Clear Skies (not once faced, nor when an Omen must be faced: then pick one).
func _unhandled_input(event: InputEvent) -> void:
	if not visible or omens.forced or omens.faced or peek.peeking:
		return
	var right_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
	if event.is_action_pressed("ui_cancel") or right_click:
		omens.choose(null)
		get_viewport().set_input_as_handled()

# The third card: Clear Skies, the default (highlighted). "Nothing changes. No reward."
func _make_clear_skies_card() -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(omens.choose.bind(null))
	UiStyle.card_button(button, CLEAR_SKIES_COLOR)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var style := button.get_theme_stylebox(state) as MoonStyleBox
		style.glow_color = CLEAR_SKIES_GLOW.lightened(0.08) if state.begins_with("hover") else CLEAR_SKIES_GLOW
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	UiStyle.title(_add_line(box, "Clear Skies", CLEAR_SKIES_COLOR, 22), UiStyle.CARD_NAME_SIZE, CLEAR_SKIES_COLOR)
	var calm := _add_line(box, "Nothing changes. No reward.", UiStyle.WHISPER, 16)
	UiStyle.whisper(calm, 19)  # Calm: the whisper face
	calm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiStyle.caps(_add_line(box, "The default", UiStyle.INK_DIM, 13), 14)
	return button
