extends Control

# Omen choice at a rest (after the Dream): 2 Omen cards (the twist + its reward) or Clear Skies.
# Pauses while open, like the Dream screen. Also shows the active Omen in a small tag under the
# toast, and toasts when one starts and when its reward is paid. Built in code.

const CARD_SIZE := Vector2(270, 200)
const OMEN_COLOR := UiStyle.BUTTON_GOLD  # Heartwood 32 "Gold"
const TWIST_COLOR := Color(1.0, 0.7, 0.6)
const REWARD_COLOR := Color(0.65, 0.9, 0.6)

@onready var omens: OmenDirector = %OmenDirector
@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed

var _was_paused := false
var _title := Label.new()
var _cards := HBoxContainer.new()
var _clear_skies := Button.new()
var _active_tag := Label.new()
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")
var _prompt := PanelContainer.new()  # "The wind carries an Omen. Face one for a reward?" (Ask first)

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
	_clear_skies.text = "Back to Clear Skies  (nothing changes)"
	_clear_skies.focus_mode = Control.FOCUS_NONE
	_clear_skies.pressed.connect(omens.choose.bind(null))
	var skip_row := CenterContainer.new()
	skip_row.add_child(_clear_skies)
	box.add_child(skip_row)
	peek = ChoicePeek.new(self, [dim, center], "Back to the Omens")
	box.add_child(peek.make_peek_button())
	visible = false

	# The active-Omen tag lives on the HUD, outside this (usually hidden) screen.
	_active_tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_active_tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_active_tag.offset_top = 64
	_active_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_active_tag.add_theme_color_override("font_color", OMEN_COLOR)
	_active_tag.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14))
	_active_tag.add_theme_constant_override("outline_size", 6)
	_active_tag.visible = false
	get_parent().add_child.call_deferred(_active_tag)

	_build_prompt()
	omens.prompt_ready.connect(_show_prompt)
	omens.prompt_closed.connect(func() -> void: _prompt.visible = false)
	omens.offer_ready.connect(_show_offer)
	omens.offer_closed.connect(_on_closed)
	omens.omen_started.connect(_on_omen_started)
	omens.omen_rewarded.connect(_on_omen_rewarded)

func _show_offer(offer: Array[OmenData], block: int) -> void:
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	var drifts := omens.get_block_range(block)
	_title.text = "The wind brings Omens for drifts %d–%d" % [drifts.x, drifts.y]
	if omens.forced:
		_title.text = "An Omen must be faced  ·  drifts %d–%d" % [drifts.x, drifts.y]
	_clear_skies.visible = not omens.forced
	for child in _cards.get_children():
		child.queue_free()
	var act := drift_director.get_act(drifts.y)
	for omen in offer:
		_cards.add_child(_make_card(omen, act))
	visible = true

func _make_card(omen: OmenData, act: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(omens.choose.bind(omen))
	UiStyle.card_button(button, OMEN_COLOR)  # Moonlit Thread card (ui_style.md)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	_add_line(box, omen.display_name, Color(0.95, 0.93, 0.9), 22)
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
	visible = false
	game_speed.set_paused(_was_paused)

func _on_omen_started(omen: OmenData, first_drift: int, last_drift: int) -> void:
	_active_tag.text = "Omen: %s (drifts %d–%d) · %s" % [omen.display_name, first_drift, last_drift,
		IconInfo.format(omen.description)]
	_active_tag.visible = true
	_toast("Omen chosen: %s" % omen.display_name)

func _on_omen_rewarded(omen: OmenData, summary: String) -> void:
	_active_tag.visible = false
	_toast("%s passes: %s" % [omen.display_name, summary])

func _toast(text: String) -> void:
	var hud := get_parent()
	if hud.has_method("show_toast"):
		hud.show_toast(text)

# --- Ask first (run_design.md "Omens") ----------------------------------------------------------------
# A small prompt beside Start instead of the cards: it doesn't pause or block building. Clear Skies is
# the default: its button, Esc, right-click or a tap outside; starting the next drift answers it too.

func _build_prompt() -> void:
	# Moonlit Thread (ui_style.md): a panel whose thread is the Omen's colour, the ask as a whisper-like
	# line, and Clear Skies (the default) in the primary look. Buttons are touch-sized.
	_prompt.add_theme_stylebox_override("panel", UiStyle.panel_in(OMEN_COLOR, 14.0, 12.0))
	_prompt.mouse_filter = Control.MOUSE_FILTER_STOP
	_prompt.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_prompt.add_child(box)
	var ask := Label.new()
	ask.text = "The wind carries an Omen.\nFace one for a reward?"
	UiStyle.whisper(ask, 19)
	ask.add_theme_color_override("font_color", OMEN_COLOR)
	box.add_child(ask)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var see := Button.new()
	see.text = "See the Omens"
	see.focus_mode = Control.FOCUS_NONE
	see.custom_minimum_size.y = 48
	see.pressed.connect(omens.see_omens)
	row.add_child(see)
	var clear := Button.new()
	clear.text = "Clear Skies"
	clear.focus_mode = Control.FOCUS_NONE
	clear.custom_minimum_size.y = 48
	UiStyle.primary(clear)  # The default, highlighted
	clear.pressed.connect(omens.choose.bind(null))
	row.add_child(clear)
	get_parent().add_child.call_deferred(_prompt)

func _show_prompt(_block: int) -> void:
	_prompt.visible = true
	_place_prompt.call_deferred()
	var drift_panel := get_parent().get_node_or_null("DriftPanel") as Control
	if drift_panel and not drift_panel.resized.is_connected(_on_drift_panel_resized):
		drift_panel.resized.connect(_on_drift_panel_resized)  # It grows at rests (Coming this block)

func _on_drift_panel_resized() -> void:
	if _prompt.visible:
		_place_prompt.call_deferred()

# Beside Start: just left of the DriftPanel, bottom-aligned with it.
func _place_prompt() -> void:
	var drift_panel := get_parent().get_node_or_null("DriftPanel") as Control
	var size := _prompt.get_combined_minimum_size()
	_prompt.size = size
	if drift_panel:
		var rect := drift_panel.get_global_rect()
		_prompt.global_position = Vector2(rect.position.x - size.x - 12, rect.end.y - size.y)
	else:
		var screen := get_viewport_rect().size
		_prompt.global_position = screen - size - Vector2(16, 16)

func _input(event: InputEvent) -> void:
	if not _prompt.visible or not omens.is_prompting():
		return
	var tapped: bool = event is InputEventMouseButton and event.pressed
	if event.is_action_pressed("ui_cancel") or (tapped and event.button_index == MOUSE_BUTTON_RIGHT) \
			or (tapped and event.button_index == MOUSE_BUTTON_LEFT and not _prompt.get_global_rect().has_point(event.position)) \
			or (event is InputEventScreenTouch and event.pressed and not _prompt.get_global_rect().has_point(event.position)):
		omens.choose(null)  # Clear Skies; the click itself still goes through (building isn't blocked)
